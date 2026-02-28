import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'voice_search_service.dart';
import 'gemini_voice_service.dart';
import 'tts_service.dart';
import 'smart_order_service.dart' show ParsedItem;
import 'product_search_engine.dart';
import '../core/api/api_client.dart';

enum AssistantState {
  idle,
  greeting,
  listening,
  searching,
  presentingOptions,
  awaitingChoice,
  addingToCart,
  ending,
}

class PendingOptions {
  final List<Map<String, dynamic>> products; // the 2-3 options shown
  final String searchQuery; // what user originally asked
  int attempts; // voice attempts in choice mode

  PendingOptions({required this.products, required this.searchQuery, this.attempts = 0});
}

class AssistantMessage {
  final String text;
  final String? subText; // English translation
  final bool isBot;
  final List<ParsedItem>? products;
  final ParsedItem? bestMatch;
  final bool isCartUpdate; // special cart summary message
  final bool isOptionsList; // UI shows numbered cards for this message
  final List<Map<String, dynamic>>? optionProducts; // products for option cards

  AssistantMessage({
    required this.text,
    required this.isBot,
    this.subText,
    this.products,
    this.bestMatch,
    this.isCartUpdate = false,
    this.isOptionsList = false,
    this.optionProducts,
  });
}

typedef AddToCartCallback = Future<bool> Function(Map<String, dynamic> product, {int quantity});
typedef RemoveFromCartCallback = bool Function(String productName);
typedef GetCartTotalCallback = double Function();
typedef GetCartCountCallback = int Function();
typedef GetCartItemsCallback = List<Map<String, dynamic>> Function();

/// Interactive voice assistant — like a friendly Tamil shopkeeper
class VoiceAssistantService {
  final VoiceSearchService _voiceService = VoiceSearchService();
  final GeminiVoiceService _geminiVoice = GeminiVoiceService();
  final TtsService _ttsService = TtsService();
  final _rand = Random();

  /// Use Gemini audio transcription (true) or device STT (false)
  bool useGeminiVoice = true;

  int? shopId;
  String? shopName;
  int _itemsAddedThisSession = 0;

  // Local product cache — loaded once, searched locally (₹0, no Gemini)
  List<Map<String, dynamic>> _cachedProducts = [];
  bool _productsLoaded = false;
  DateTime? _cacheLoadedAt;
  static const _cacheExpiry = Duration(minutes: 5);

  // Offline intelligent search engine (inverted index, transliteration, phonetic, fuzzy)
  final ProductSearchEngine _searchEngine = ProductSearchEngine();

  AssistantState _state = AssistantState.idle;
  AssistantState get state => _state;

  // Current pending options when user is choosing between products
  PendingOptions? _pendingOptions;
  PendingOptions? get pendingOptions => _pendingOptions;

  final List<AssistantMessage> messages = [];

  VoidCallback? onStateChanged;
  void Function(AssistantMessage)? onMessage;
  AddToCartCallback? onAddToCart;
  RemoveFromCartCallback? onRemoveFromCart;
  GetCartTotalCallback? onGetCartTotal;
  GetCartCountCallback? onGetCartCount;
  GetCartItemsCallback? onGetCartItems;

  VoiceSearchService get voiceService => _voiceService;
  TtsService get ttsService => _ttsService;
  GeminiVoiceService get geminiVoice => _geminiVoice;

  /// Whether Gemini is currently recording audio (for UI state)
  bool get isRecordingManually => _geminiVoice.isRecording;

  /// Whether auto-listen has exhausted its retry limit
  bool get isAutoListenExhausted => _failedListenAttempts >= _maxFailedAttempts;

  /// Whether auto-listen is currently active (device STT listening)
  bool get isAutoListening => _isAutoListening;

  /// Auto-listen: automatically start recording after TTS finishes
  bool _isAutoListening = false;
  int _failedListenAttempts = 0;
  static const _maxFailedAttempts = 2;

  /// Start manual recording (user tapped mic button)
  Future<bool> startManualRecording() async {
    if (useGeminiVoice) {
      final started = await _geminiVoice.startRecording();
      if (!started) {
        debugPrint('VoiceAssistant: Failed to start manual recording');
      }
      return started;
    }
    return false;
  }

  /// Auto-listen using device STT (speech_to_text).
  /// Device STT activates mic reliably. Even if Tamil text is poor,
  /// the AI search pipeline corrects it.
  Future<void> autoListenAndProcess() async {
    if (_stopped || _isAutoListening) return;
    if (_state != AssistantState.listening && _state != AssistantState.awaitingChoice) return;

    // Stop auto-listening after too many failed attempts
    if (_failedListenAttempts >= _maxFailedAttempts) {
      debugPrint('VoiceAssistant: Too many failed attempts ($_failedListenAttempts), waiting for text input');
      return;
    }

    _isAutoListening = true;
    debugPrint('VoiceAssistant: Auto-listen via device STT (attempt ${_failedListenAttempts + 1})...');

    // Explicitly stop TTS to release audio focus
    await _ttsService.stop();

    // Wait for TTS audio to fully stop
    await Future.delayed(const Duration(milliseconds: 1000));
    if (_stopped) { _isAutoListening = false; return; }

    // Use device speech-to-text (reliable mic activation)
    onStateChanged?.call(); // Show "Listening..." UI
    final text = await _voiceService.listen();

    if (_stopped) { _isAutoListening = false; return; }
    _isAutoListening = false;

    if (text == null || text.trim().isEmpty) {
      _failedListenAttempts++;
      debugPrint('VoiceAssistant: STT returned empty (attempt $_failedListenAttempts/$_maxFailedAttempts)');
      if (_failedListenAttempts >= _maxFailedAttempts) {
        _addBot(
          'குரல் வரல. Type செய்யுங்க.',
          sub: 'Couldn\'t hear you. Please type the product name below.',
        );
      } else {
        _addBot(
          'குரல் வரல. மீண்டும் சொல்லுங்க.',
          sub: 'Couldn\'t hear. Please say again.',
        );
      }
      _setState(AssistantState.listening);
      return;
    }

    // Success — reset failed counter
    _failedListenAttempts = 0;
    debugPrint('VoiceAssistant: STT heard: "$text"');

    // Add user message and process
    await processTextInput(text);
  }

  /// Stop recording and process result
  Future<void> stopAndProcess() async {
    if (_stopped) return;

    if (_state == AssistantState.awaitingChoice && _pendingOptions != null) {
      // Choice mode — send audio + options to Gemini
      _setState(AssistantState.searching);
      final result = await _geminiVoice.stopAndUnderstandChoice(_pendingOptions!.products);
      if (_stopped) return;

      if (result != null) {
        await _handleChoice(result);
      } else {
        _pendingOptions!.attempts++;
        if (_pendingOptions!.attempts >= 2) {
          await _addProductToCart(_pendingOptions!.products.first, 1);
          _pendingOptions = null;
        } else {
          final msg = 'புரியல. எண் சொல்லுங்க அல்லது type செய்யுங்க.';
          _addBot(msg, sub: 'Didn\'t understand. Say the number or type below.');
          _setState(AssistantState.awaitingChoice);
        }
      }
    } else {
      // Listening mode — transcribe audio
      _setState(AssistantState.searching);
      final text = await _geminiVoice.stopAndTranscribe();
      if (_stopped) return;

      if (text == null || text.trim().isEmpty) {
        _failedListenAttempts++;
        debugPrint('VoiceAssistant: Transcription empty (attempt $_failedListenAttempts/$_maxFailedAttempts)');
        if (_failedListenAttempts >= _maxFailedAttempts) {
          _addBot(
            'குரல் வரல. Type செய்யுங்க.',
            sub: 'Couldn\'t hear you. Please type the product name below.',
          );
        } else {
          _addBot(
            'குரல் வரல. மீண்டும் சொல்லுங்க.',
            sub: 'Couldn\'t hear. Please say again.',
          );
        }
        _setState(AssistantState.listening);
        return;
      }

      // Success — reset failed counter
      _failedListenAttempts = 0;
      await processTextInput(text);
    }
  }

  /// Cancel an ongoing recording without processing
  Future<void> cancelRecording() async {
    _isAutoListening = false;
    if (_geminiVoice.isRecording) await _geminiVoice.stopRecording();
    await _voiceService.stopListening();
  }

  /// Return to listening state after processing (if session still active)
  void _returnToListening() {
    if (!_stopped && _state != AssistantState.idle &&
        _state != AssistantState.ending &&
        _state != AssistantState.awaitingChoice) {
      _setState(AssistantState.listening);
    }
  }

  // ── End words ──
  static final Set<String> _endWords = {
    'போதும்', 'நிறுத்து', 'முடிந்தது',
    'சரி போதும்', 'அவ்வளவுதான்', 'வேற ஒன்னும் வேண்டாம்',
    'done', 'enough', 'stop', 'that\'s all', 'finish',
    'no more', 'thats all', 'thank you', 'thanks', 'bye',
  };

  // ── Remove words ──
  static final Set<String> _removeWords = {
    'remove', 'delete', 'cancel', 'நீக்கு', 'எடு', 'எடுங்க',
    'நீக்குங்க', 'வேண்டாம்', 'கார்ட்டிலிருந்து நீக்கு',
  };

  /// Check if text is a remove command, returns the product name to remove
  String? _extractRemoveTarget(String text) {
    final lower = text.trim().toLowerCase();
    for (final word in _removeWords) {
      if (lower.startsWith(word)) {
        final target = lower.replaceFirst(word, '').trim();
        return target.isNotEmpty ? target : null;
      }
      if (lower.contains(word)) {
        final target = lower.replaceAll(word, '').trim();
        return target.isNotEmpty ? target : null;
      }
    }
    return null;
  }

  bool _isRemoveCommand(String text) {
    final lower = text.trim().toLowerCase();
    for (final word in _removeWords) {
      if (lower.startsWith(word) || lower.contains(word)) return true;
    }
    return false;
  }

  // ── Varied responses for personality ──
  List<String> get _greetings => [
    'வணக்கம்! என்ன வேணும் சொல்லுங்க',
    'வாங்க! என்ன பொருள் வேணும்?',
    'வணக்கம்! சொல்லுங்க, என்ன தரணும்?',
  ];

  List<String> get _notFoundResponses => [
    'அது கிடைக்கல. வேற சொல்லுங்க.',
    'இல்ல, அது stock-ல இல்ல. வேற?',
    'கிடைக்கவில்லை. வேற முயற்சிக்கவும்.',
  ];

  List<String> get _addedResponses => [
    'சேர்த்தாச்சு!',
    'போட்டாச்சு!',
    'கார்ட்டில் சேர்த்தேன்!',
    'ஓகே, சேர்த்துட்டேன்!',
  ];

  List<String> get _byeResponses => [
    'நன்றி! ஆர்டர் தயார். கார்ட் பாருங்க.',
    'ஓகே! கார்ட்டில் பாருங்க. நன்றி!',
    'சரி, நன்றி! மீண்டும் வாங்க.',
  ];

  String _pick(List<String> list) => list[_rand.nextInt(list.length)];

  bool _isEndCommand(String text) {
    final lower = text.trim().toLowerCase();
    if (lower == 'no' || lower == 'இல்லை' || lower == 'வேண்டாம்') return false;
    for (final word in _endWords) {
      if (lower == word || lower.contains(word)) return true;
    }
    return false;
  }

  Future<void> initialize() async {
    await _ttsService.initialize();
  }

  bool _stopped = false;

  bool get isStopped => _stopped;

  /// Start conversation
  Future<void> startSession() async {
    await initialize();
    messages.clear();
    _itemsAddedThisSession = 0;
    _failedListenAttempts = 0;
    _stopped = false;
    _setState(AssistantState.greeting);

    // Initialize speech recognition early (request mic permission)
    _voiceService.initialize();

    // Load products in background while greeting plays
    final productFuture = _loadProducts();

    final shopLabel = shopName != null ? ' $shopName-ல' : '';
    final greeting = '${_pick(_greetings)}$shopLabel';
    _addBot(greeting, sub: 'Hello! What do you need?');
    await _speak(greeting);
    if (_stopped) return;

    // Make sure products are loaded before searching
    await productFuture;

    _setState(AssistantState.listening);
  }

  /// Resume after pause (preserves messages)
  Future<void> resumeSession() async {
    if (_stopped) {
      _stopped = false;
      final msg = 'சரி, தொடருங்க. என்ன வேணும்?';
      _addBot(msg, sub: 'OK, continue. What do you need?');
      await _speak(msg);
      if (_stopped) return;
      _setState(AssistantState.listening);
    }
  }

  /// Process a typed text input (for when voice doesn't work)
  /// If in awaitingChoice state, try to parse as option number or treat as new search
  Future<void> processTextInput(String text) async {
    if (text.trim().isEmpty) return;
    _stopped = false;
    _failedListenAttempts = 0; // Reset — user is actively engaged

    _addUser(text);

    if (_isEndCommand(text)) {
      _pendingOptions = null;
      await _endConversation();
      return;
    }

    if (_isRemoveCommand(text)) {
      _pendingOptions = null;
      await _handleRemove(text);
      return;
    }

    // If awaiting choice, try to parse as option number
    if (_state == AssistantState.awaitingChoice && _pendingOptions != null) {
      final lower = text.trim().toLowerCase();
      // Try direct number: "1", "2", "3"
      final num = int.tryParse(lower);
      if (num != null && num >= 1 && num <= _pendingOptions!.products.length) {
        final product = _pendingOptions!.products[num - 1];
        _pendingOptions = null;
        await _addProductToCart(product, 1);
        return;
      }
      // Try number words
      for (final entry in _numberWords.entries) {
        if (lower == entry.key && entry.value >= 1 && entry.value <= (_pendingOptions?.products.length ?? 0)) {
          final product = _pendingOptions!.products[entry.value - 1];
          _pendingOptions = null;
          await _addProductToCart(product, 1);
          return;
        }
      }
      // Not a number — treat as new search
      _pendingOptions = null;
    }

    // Search → 0/1/many flow
    await _handleProductSearch(text);
  }

  // Main loop removed — tap-to-talk is now event-driven via
  // startManualRecording() + stopAndProcess() from the UI

  /// Product search with 0/1/many branching:
  /// 0 results → "not found"
  /// 1 result → auto-add to cart
  /// 2+ results → show top 3 options, enter awaitingChoice
  Future<void> _handleProductSearch(String text) async {
    _setState(AssistantState.searching);

    // Parse quantity from speech: "2 onion" → qty=2, "onion" → qty=1
    final qty = _parseQuantity(text);

    final items = await _searchProducts(text);
    if (_stopped) return;

    for (final item in items) {
      if (_stopped) return;

      // ── 0 results: not found ──
      if (item.matches.isEmpty) {
        final notFound = _pick(_notFoundResponses);
        _addBot('"${item.name}" — $notFound', sub: '"${item.name}" not found', products: [item]);
        await _speak('${item.name} $notFound');
        if (_stopped) return;
        continue;
      }

      // Sort by price — cheapest first
      item.matches.sort((a, b) {
        final pa = double.tryParse(a['price']?.toString() ?? '0') ?? 0;
        final pb = double.tryParse(b['price']?.toString() ?? '0') ?? 0;
        return pa.compareTo(pb);
      });

      // ── 1 result: auto-add ──
      if (item.matches.length == 1) {
        await _addProductToCart(item.matches.first, qty);
        if (_stopped) return;
        continue;
      }

      // ── 2+ results: present top 3 options ──
      final topOptions = item.matches.toList();
      await _presentOptions(topOptions, item.name);
      return; // _presentOptions sets state to awaitingChoice
    }
    _returnToListening();
  }

  /// Show 2-3 options to user with TTS reading them out
  Future<void> _presentOptions(List<Map<String, dynamic>> options, String searchQuery) async {
    _setState(AssistantState.presentingOptions);

    // Build TTS text: "1: Garlic 100g ₹20, 2: Garlic 250g ₹45. எது வேணும்?"
    final buffer = StringBuffer();
    final bufferEn = StringBuffer();
    for (int i = 0; i < options.length; i++) {
      final p = options[i];
      final name = p['nameTamil']?.toString().isNotEmpty == true ? p['nameTamil'] : p['name'] ?? '';
      final nameEn = p['name'] ?? '';
      final price = p['price']?.toString() ?? '0';
      final weight = p['weightDisplay']?.toString() ?? '';
      final weightLabel = weight.isNotEmpty ? ' $weight' : '';
      buffer.write('${i + 1}: $name$weightLabel ₹$price');
      bufferEn.write('${i + 1}: $nameEn$weightLabel Rs.$price');
      if (i < options.length - 1) {
        buffer.write(', ');
        bufferEn.write(', ');
      }
    }
    buffer.write('. எது வேணும்?');
    bufferEn.write('. Which one?');

    // Store pending options
    _pendingOptions = PendingOptions(products: options, searchQuery: searchQuery);

    // Add message with option cards
    _addBot(
      buffer.toString(),
      sub: bufferEn.toString(),
      isOptionsList: true,
      optionProducts: options,
    );

    await _speak(buffer.toString());
    if (_stopped) return;

    _setState(AssistantState.awaitingChoice);
  }

  /// Add a single product to cart with TTS confirmation
  Future<void> _addProductToCart(Map<String, dynamic> product, int qty) async {
    final name = product['nameTamil']?.toString().isNotEmpty == true
        ? product['nameTamil'] : product['name'] ?? '';
    final price = product['price']?.toString() ?? '';
    final weight = product['weightDisplay']?.toString() ?? '';
    final weightLabel = weight.isNotEmpty ? ' $weight' : '';
    final qtyLabel = qty > 1 ? ' x$qty' : '';

    _setState(AssistantState.addingToCart);
    bool added = false;
    if (onAddToCart != null) {
      added = await onAddToCart!(product, quantity: qty);
    }

    if (added) {
      _itemsAddedThisSession++;

      final addMsg = '$name$weightLabel$qtyLabel ₹$price ${_pick(_addedResponses)} சொல்லுங்க.';
      final item = ParsedItem(name: name.toString(), matches: [product]);
      item.isAdded = true;
      item.selectedMatch = product;
      _addBot(addMsg, sub: '$name$weightLabel$qtyLabel Rs.$price added! Say next item or "done".', bestMatch: item);
      await _speak('$name$qtyLabel சேர்த்தேன். சொல்லுங்க');

      _refreshCacheIfNeeded();
    } else {
      _addBot('$name stock இல்லை!', sub: '$name out of stock!');
      await _speak('$name இல்லை. வேற சொல்லுங்க');
      await refreshProducts();
    }
    _returnToListening();
  }

  /// Handle Gemini's structured choice response
  Future<void> _handleChoice(Map<String, dynamic> choiceResult) async {
    final action = choiceResult['action']?.toString() ?? '';

    switch (action) {
      case 'select':
        // User picked an option by number
        final index = (choiceResult['index'] is int)
            ? choiceResult['index'] as int
            : int.tryParse(choiceResult['index']?.toString() ?? '') ?? 0;

        if (_pendingOptions != null && index >= 1 && index <= _pendingOptions!.products.length) {
          final product = _pendingOptions!.products[index - 1];
          _pendingOptions = null;
          await _addProductToCart(product, 1);
        } else {
          // Invalid index — treat as failed attempt
          _pendingOptions?.attempts = (_pendingOptions?.attempts ?? 0) + 1;
          final retry = 'சரியான எண் சொல்லுங்க.';
          _addBot(retry, sub: 'Please say a valid number.');
          await _speak(retry);
        }

      case 'search':
        // User asked for a different product
        final query = choiceResult['query']?.toString() ?? '';
        _pendingOptions = null;
        if (query.isNotEmpty) {
          _addUser(query);
          await _handleProductSearch(query);
        }

      case 'done':
        _pendingOptions = null;
        await _endConversation();

      case 'remove':
        final query = choiceResult['query']?.toString() ?? '';
        _pendingOptions = null;
        if (query.isNotEmpty) {
          await _handleRemove('remove $query');
        }

      default:
        // Unknown action — treat as failed
        _pendingOptions?.attempts = (_pendingOptions?.attempts ?? 0) + 1;
    }
  }

  /// Called when user TAPS a product card during awaitingChoice
  void interruptWithChoice(int index) async {
    if (_pendingOptions == null) return;
    if (index < 0 || index >= _pendingOptions!.products.length) return;

    // Stop any ongoing recording/TTS
    await _ttsService.stop();
    if (_geminiVoice.isRecording) await _geminiVoice.stopRecording();

    final product = _pendingOptions!.products[index];
    _pendingOptions = null;

    await _addProductToCart(product, 1);
  }

  // ── Number words (Tamil + English) ──
  static final Map<String, int> _numberWords = {
    'ஒன்று': 1, 'ஒரு': 1, 'ஒண்ணு': 1, 'one': 1, '1': 1,
    'இரண்டு': 2, 'ரெண்டு': 2, 'two': 2, '2': 2,
    'மூன்று': 3, 'மூணு': 3, 'three': 3, '3': 3,
    'நான்கு': 4, 'நாலு': 4, 'four': 4, '4': 4,
    'ஐந்து': 5, 'அஞ்சு': 5, 'five': 5, '5': 5,
    'ஆறு': 6, 'six': 6, '6': 6,
    'ஏழு': 7, 'seven': 7, '7': 7,
    'எட்டு': 8, 'eight': 8, '8': 8,
    'ஒன்பது': 9, 'nine': 9, '9': 9,
    'பத்து': 10, 'ten': 10, '10': 10,
    'அரை': 1, 'half': 1, // half = 1 unit for simplicity
  };

  /// Parse quantity from text like "2", "இரண்டு", "three", "2 kg"
  int _parseQuantity(String text) {
    final lower = text.trim().toLowerCase();
    // Direct number match
    for (final entry in _numberWords.entries) {
      if (lower == entry.key || lower.startsWith('${entry.key} ') ||
          lower.contains(entry.key)) {
        return entry.value;
      }
    }
    // Try parsing digits from the text
    final digitMatch = RegExp(r'(\d+)').firstMatch(lower);
    if (digitMatch != null) {
      return int.tryParse(digitMatch.group(1)!) ?? 1;
    }
    return 1;
  }

  /// Handle remove from cart command
  Future<void> _handleRemove(String text) async {
    final target = _extractRemoveTarget(text);

    if (target == null || target.isEmpty) {
      // No specific product mentioned — show cart items
      final items = onGetCartItems?.call() ?? [];
      if (items.isEmpty) {
        _addBot('கார்ட் காலியா இருக்கு.', sub: 'Cart is empty.');
        await _speak('கார்ட் காலியா இருக்கு');
        return;
      }
      final names = items.map((i) => i['name'] ?? '').join(', ');
      _addBot('கார்ட்டில்: $names\nஎதை நீக்கணும்?',
          sub: 'In cart: $names. Which one to remove?');
      await _speak('எதை நீக்கணும்? சொல்லுங்க');
      return;
    }

    // Try to remove the item
    final removed = onRemoveFromCart?.call(target) ?? false;
    if (removed) {
      _addBot('$target நீக்கிட்டேன்!', sub: '$target removed from cart');
      await _speak('$target நீக்கிட்டேன்');
      await _showCartSummary();
    } else {
      _addBot('$target கார்ட்டில் இல்லை.', sub: '$target not found in cart');
      await _speak('$target கார்ட்டில் இல்லை');
    }
    _returnToListening();
  }

  Future<void> _showCartSummary() async {
    final count = onGetCartCount?.call() ?? _itemsAddedThisSession;
    final total = onGetCartTotal?.call() ?? 0.0;
    if (total > 0) {
      _addBot(
        '🛒 $count items, Total: ₹${total.toStringAsFixed(0)}',
        sub: '$count items in cart, Total: Rs.${total.toStringAsFixed(0)}',
        isCartUpdate: true,
      );
      // Speak cart total so user hears it
      await _speak('கார்ட்டில் $count பொருட்கள், Total ₹${total.toStringAsFixed(0)}');
    }
  }

  Future<void> _endConversation() async {
    _setState(AssistantState.ending);
    final count = onGetCartCount?.call() ?? _itemsAddedThisSession;
    final total = onGetCartTotal?.call() ?? 0.0;

    String bye;
    if (count > 0 && total > 0) {
      bye = '$count பொருட்கள், Total ₹${total.toStringAsFixed(0)}. ${_pick(_byeResponses)}';
    } else if (_itemsAddedThisSession > 0) {
      bye = '$_itemsAddedThisSession பொருட்கள் சேர்த்தாச்சு. ${_pick(_byeResponses)}';
    } else {
      bye = _pick(_byeResponses);
    }

    _addBot(bye, sub: 'Thank you! Check your cart.');
    await _speak(bye);
    _setState(AssistantState.idle);
  }

  Future<void> _speak(String text) async {
    await _ttsService.speak(text);
    await _waitForTtsComplete();
  }

  // ── Quantity words to strip before searching ──
  static final Set<String> _quantityWords = {
    'ஒரு', 'இரண்டு', 'மூன்று', 'நான்கு', 'ஐந்து',
    'ஆறு', 'ஏழு', 'எட்டு', 'ஒன்பது', 'பத்து',
    'அரை', 'ஒன்றரை', 'இரண்டரை',
    'கிலோ', 'கிராம்', 'லிட்டர்', 'மில்லி', 'பாக்கெட்', 'டஜன்',
    'கேஜி', 'லிட்', 'பாக்', 'கொடுங்க', 'வேணும்', 'தாங்க',
    'kg', 'kilo', 'gram', 'grams', 'liter', 'litre', 'ml',
    'packet', 'pack', 'dozen', 'half', 'quarter',
    'one', 'two', 'three', 'four', 'five',
    'give', 'want', 'need', 'please', 'get',
  };

  /// Clean query: strip quantity/filler words, keep product terms together
  /// "ஒரு கிலோ basmati rice கொடுங்க" → "basmati rice"
  /// "rice and dal" → ["rice", "dal"]
  String _cleanQuery(String text) {
    return text.split(' ')
        .where((w) => w.trim().isNotEmpty)
        .where((w) =>
            !_quantityWords.contains(w.toLowerCase()) &&
            !RegExp(r'^\d+\.?\d*$').hasMatch(w))
        .where((w) => w.length > 1)
        .join(' ')
        .trim();
  }

  /// Split multi-product query by separators, keep each product phrase intact
  /// "rice and dal" → ["rice", "dal"]
  /// "basmati rice, coconut oil" → ["basmati rice", "coconut oil"]
  /// "basmati rice" → ["basmati rice"] (NOT split into 2 words)
  List<String> _smartSplit(String text) {
    var normalized = text
        .replaceAll('மற்றும்', ',')
        .replaceAll(' and ', ',')
        .replaceAll('  ', ' ');

    return normalized
        .split(RegExp(r'[,\n]+'))
        .map((s) => _cleanQuery(s))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // ── Load & Cache Products ──
  // Fetch ALL shop products ONCE, search locally (₹0, no Gemini)

  Future<void> _loadProducts({bool force = false}) async {
    if (shopId == null) return;

    // Use cache if loaded and not expired
    if (_productsLoaded && !force && _cacheLoadedAt != null) {
      final age = DateTime.now().difference(_cacheLoadedAt!);
      if (age < _cacheExpiry) return; // Still fresh
      debugPrint('VoiceAssistant: Cache expired (${age.inMinutes}m), refreshing...');
    }

    try {
      debugPrint('VoiceAssistant: Loading all products for shop $shopId...');
      final response = await ApiClient.get(
        '/customer/shops/$shopId/products',
        queryParameters: {'page': '0', 'size': '2000', 'sortBy': 'name', 'sortDir': 'asc'},
      );
      final data = response.data;
      if (data != null && data['statusCode'] == '0000') {
        final List<dynamic> products = data['data']?['content'] ?? [];
        _cachedProducts = products.map<Map<String, dynamic>>((p) {
          final name = p['displayName']?.toString() ?? p['customName']?.toString() ?? '';
          final nameTamil = p['nameTamil']?.toString() ?? '';
          final category = (p['categoryName'] ?? p['category'] ?? '').toString();
          final tags = (p['tags'] ?? '').toString();
          final baseWeight = p['baseWeight'];
          final baseUnit = (p['baseUnit'] ?? '').toString();
          // Build weight display string: "500g", "1kg", "2 litre"
          String weightDisplay = '';
          if (baseWeight != null && baseUnit.isNotEmpty) {
            final w = double.tryParse(baseWeight.toString()) ?? 0;
            if (w > 0) {
              weightDisplay = w == w.roundToDouble()
                  ? '${w.toInt()}$baseUnit'
                  : '${w.toString()}$baseUnit';
            }
          }
          return {
            'id': p['id']?.toString() ?? '',
            'name': name,
            'nameTamil': nameTamil,
            'category': category,
            'tags': tags,
            'price': p['price']?.toString() ?? '0',
            'image': _extractImage(p),
            'shopId': p['shopId']?.toString() ?? shopId.toString(),
            'shopDatabaseId': shopId,
            'shopName': shopName ?? '',
            'stockQuantity': p['stockQuantity'] ?? 999,
            'baseWeight': baseWeight?.toString() ?? '',
            'baseUnit': baseUnit,
            'weightDisplay': weightDisplay,
          };
        }).toList();

        // Build offline search indices (inverted index, tags, transliteration, phonetic, fuzzy)
        _searchEngine.indexProducts(_cachedProducts);

        _productsLoaded = true;
        _cacheLoadedAt = DateTime.now();
        debugPrint('VoiceAssistant: Cached & indexed ${_cachedProducts.length} products');
      }
    } catch (e) {
      debugPrint('VoiceAssistant: Failed to load products: $e');
    }
  }

  /// Refresh cache if expired (called after add-to-cart to get updated stock)
  Future<void> _refreshCacheIfNeeded() async {
    if (_cacheLoadedAt == null) return;
    final age = DateTime.now().difference(_cacheLoadedAt!);
    if (age >= _cacheExpiry) {
      await _loadProducts(force: true);
    }
  }

  /// Force refresh products NOW (called when add-to-cart fails due to stock)
  Future<void> refreshProducts() async {
    debugPrint('VoiceAssistant: Force refreshing products (stock update)...');
    await _loadProducts(force: true);
  }

  // Phonetic and transliteration now handled by ProductSearchEngine

  // ── Local Search using ProductSearchEngine (offline ML) ──
  // Uses inverted index, tags, transliteration, phonetic, fuzzy matching
  // No hardcoded aliases needed — all intelligence from product tags data

  List<Map<String, dynamic>> _localSearch(String query) {
    if (!_searchEngine.isIndexed) return [];
    final q = query.toLowerCase().trim();
    if (q.isEmpty || q.length < 2) return [];

    // Step 1: Normal search (direct match, tags, phonetic, fuzzy)
    var results = _searchEngine.search(q, limit: 10);
    if (results.isNotEmpty) return results;

    // Step 2: STT correction — handles misrecognized words
    // e.g., "only on" → joins to "onlyon" → fuzzy matches "onion"
    // e.g., "to motto" → joins to "tomotto" → fuzzy matches "tomato"
    results = _searchEngine.sttCorrectionSearch(q, limit: 10);
    if (results.isNotEmpty) {
      debugPrint('VoiceAssistant: STT correction found ${results.length} results for "$q"');
    }
    return results;
  }

  // ── Search ──
  // GEMINI AI SEARCH FIRST (understands intent despite wrong STT words)
  // Offline local search as fallback

  Future<List<ParsedItem>> _searchProducts(String query) async {
    final raw = query.trim();
    debugPrint('VoiceAssistant: raw query="$raw"');

    if (shopId == null) return [ParsedItem(name: raw, matches: [])];

    // ═══════════════════════════════════════════════════════════
    // STEP 1: GEMINI AI SEARCH (backend) — understands intent
    //   Even if STT gives "only on", Gemini knows you mean "onion"
    //   Uses tags (English + Tamil + category + brand) for matching
    // ═══════════════════════════════════════════════════════════
    final cleaned = _cleanQuery(raw);
    final searchTerm = cleaned.isNotEmpty ? cleaned : raw;

    // Split into terms for multi-product queries: "rice and dal" → ["rice", "dal"]
    final terms = _smartSplit(raw);
    if (terms.length > 1) {
      // Multiple products — search each via Gemini AI
      List<ParsedItem> items = [];
      for (final term in terms) {
        final matches = await _aiSearch(term);
        items.add(ParsedItem(name: term, matches: matches));
      }
      // If AI found results for any term, return
      if (items.any((i) => i.matches.isNotEmpty)) return items;
    }

    // Single product search via Gemini AI
    var matches = await _aiSearch(searchTerm);
    if (matches.isNotEmpty) {
      return [ParsedItem(name: searchTerm, matches: matches)];
    }

    // Also try with raw query if cleaned was different
    if (searchTerm != raw) {
      matches = await _aiSearch(raw);
      if (matches.isNotEmpty) {
        return [ParsedItem(name: raw, matches: matches)];
      }
    }

    // ═══════════════════════════════════════════════════════════
    // STEP 2: OFFLINE LOCAL SEARCH (fallback if no internet/API fails)
    //   Uses ProductSearchEngine: tags, transliteration, phonetic, fuzzy
    // ═══════════════════════════════════════════════════════════
    debugPrint('VoiceAssistant: AI search failed, trying offline...');
    if (_productsLoaded) {
      matches = _localSearch(searchTerm);
      if (matches.isNotEmpty) {
        return [ParsedItem(name: searchTerm, matches: matches)];
      }

      // Try each word individually
      final words = searchTerm.split(RegExp(r'\s+'))
          .where((w) => w.length >= 3).toList();
      for (final word in words) {
        matches = _localSearch(word);
        if (matches.isNotEmpty) {
          return [ParsedItem(name: word, matches: matches)];
        }
      }
    } else {
      await _loadProducts(force: true);
      if (_productsLoaded) {
        matches = _localSearch(searchTerm);
        if (matches.isNotEmpty) {
          return [ParsedItem(name: searchTerm, matches: matches)];
        }
      }
    }

    // ═══════════════════════════════════════════════════════════
    // STEP 3: GOOGLE TRANSLATE fallback (free, ₹0)
    // ═══════════════════════════════════════════════════════════
    debugPrint('VoiceAssistant: Trying Google Translate...');
    final enTranslation = await _googleTranslate(searchTerm, to: 'en');
    if (enTranslation != null && enTranslation != searchTerm.toLowerCase()) {
      // Try AI search with translated text
      matches = await _aiSearch(enTranslation);
      if (matches.isNotEmpty) {
        return [ParsedItem(name: searchTerm, matches: matches)];
      }
      // Try local search with translated text
      matches = _localSearch(enTranslation);
      if (matches.isNotEmpty) {
        return [ParsedItem(name: searchTerm, matches: matches)];
      }
    }

    return [ParsedItem(name: searchTerm, matches: [])];
  }

  /// Call backend AI search (Gemini) — understands intent despite STT errors
  Future<List<Map<String, dynamic>>> _aiSearch(String query) async {
    if (shopId == null) return [];
    try {
      debugPrint('VoiceAssistant: AI search shopId=$shopId query="$query"');
      final response = await ApiClient.get(
        '/shops/$shopId/products/ai-search',
        queryParameters: {'query': query},
      );
      final data = response.data;
      if (data == null || data['statusCode'] != '0000') return [];

      final List<dynamic> products = data['data']?['matchedProducts'] ?? [];
      debugPrint('VoiceAssistant: AI found ${products.length} products');

      return products.map<Map<String, dynamic>>((p) {
        final baseWeight = p['baseWeight'];
        final baseUnit = (p['baseUnit'] ?? '').toString();
        String weightDisplay = '';
        if (baseWeight != null && baseUnit.isNotEmpty) {
          final w = double.tryParse(baseWeight.toString()) ?? 0;
          if (w > 0) {
            weightDisplay = w == w.roundToDouble()
                ? '${w.toInt()}$baseUnit'
                : '${w.toString()}$baseUnit';
          }
        }
        return {
          'id': p['id']?.toString() ?? '',
          'name': p['displayName'] ?? p['name']?.toString() ?? '',
          'nameTamil': p['nameTamil']?.toString() ?? '',
          'price': p['price']?.toString() ?? '0',
          'image': _extractImage(p),
          'shopId': p['shopId']?.toString() ?? shopId.toString(),
          'shopDatabaseId': shopId,
          'shopName': shopName ?? '',
          'stockQuantity': p['stockQuantity'] ?? 999,
          'baseWeight': baseWeight?.toString() ?? '',
          'baseUnit': baseUnit,
          'weightDisplay': weightDisplay,
        };
      }).toList();
    } catch (e) {
      debugPrint('VoiceAssistant: AI search error: $e');
      return [];
    }
  }

  // ── Free Google Translate (no API key, ₹0) ──
  // Used ONLY as last resort when local search fails
  Future<String?> _googleTranslate(String text, {String from = 'auto', String to = 'en'}) async {
    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single'
        '?client=gtx&sl=$from&tl=$to&dt=t&q=${Uri.encodeComponent(text)}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translated = data[0][0][0]?.toString() ?? '';
        debugPrint('VoiceAssistant: Translate "$text" ($from→$to) = "$translated"');
        return translated.isNotEmpty ? translated.toLowerCase() : null;
      }
    } catch (e) {
      debugPrint('VoiceAssistant: Google Translate error: $e');
    }
    return null;
  }

  // Tamil-to-Latin transliteration now handled by ProductSearchEngine.tamilToLatin()

  String _extractImage(dynamic p) {
    if (p['primaryImageUrl'] != null) return p['primaryImageUrl'].toString();
    if (p['images'] != null && p['images'] is List && (p['images'] as List).isNotEmpty) {
      final img = (p['images'] as List).first;
      if (img is String) return img;
      if (img is Map) return img['imageUrl']?.toString() ?? '';
    }
    // Fallback to master product image
    if (p['masterProduct'] != null && p['masterProduct']['primaryImageUrl'] != null) {
      return p['masterProduct']['primaryImageUrl'].toString();
    }
    return '';
  }

  Future<void> _waitForTtsComplete() async {
    // TTS speak() now blocks until complete (awaitSpeakCompletion=true)
    // Just add a small gap before microphone starts so device audio settles
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _setState(AssistantState newState) {
    _state = newState;
    onStateChanged?.call();
  }

  void _addBot(String text, {String? sub, List<ParsedItem>? products,
      ParsedItem? bestMatch, bool isCartUpdate = false,
      bool isOptionsList = false, List<Map<String, dynamic>>? optionProducts}) {
    final msg = AssistantMessage(
      text: text, isBot: true, subText: sub,
      products: products, bestMatch: bestMatch, isCartUpdate: isCartUpdate,
      isOptionsList: isOptionsList, optionProducts: optionProducts,
    );
    messages.add(msg);
    onMessage?.call(msg);
  }

  void _addUser(String text) {
    final msg = AssistantMessage(text: text, isBot: false);
    messages.add(msg);
    onMessage?.call(msg);
  }

  Future<void> stopSession() async {
    _stopped = true;
    _pendingOptions = null;
    _setState(AssistantState.idle);
    await _voiceService.stopListening();
    if (_geminiVoice.isRecording) await _geminiVoice.stopRecording();
    await _ttsService.stop();
  }

  /// Pause: stop listening/speaking but keep messages
  Future<void> pause() async {
    _stopped = true;
    await _voiceService.stopListening();
    if (_geminiVoice.isRecording) await _geminiVoice.stopRecording();
    await _ttsService.stop();
  }

  void dispose() {
    _stopped = true;
    onStateChanged = null;
    onMessage = null;
    onAddToCart = null;
    onRemoveFromCart = null;
    onGetCartTotal = null;
    onGetCartCount = null;
    onGetCartItems = null;
    stopSession();
    _ttsService.dispose();
    _geminiVoice.dispose();
  }
}
