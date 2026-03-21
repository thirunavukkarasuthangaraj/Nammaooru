import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'gemini_voice_service.dart';
import 'tts_service.dart';
import 'product_search_engine.dart';
import 'gemini_conversation_service.dart';
import '../core/api/api_client.dart';

// ── Simple state: what the assistant is doing right now ──
enum AgentState { idle, listening, processing, speaking }

// ── A single chat message (bot or user) ──
class AgentMessage {
  final String text;
  final String? subText;
  final bool isBot;
  final List<Map<String, dynamic>>? products; // product option cards
  final Map<String, dynamic>? addedProduct; // product just added (green check)
  final bool isCartSummary;

  AgentMessage({
    required this.text,
    required this.isBot,
    this.subText,
    this.products,
    this.addedProduct,
    this.isCartSummary = false,
  });
}

// ── Callbacks for cart operations (set by screen via Provider) ──
typedef AddToCartCallback = Future<bool> Function(
    Map<String, dynamic> product,
    {int quantity});
typedef RemoveFromCartCallback = bool Function(String productName);
typedef GetCartTotalCallback = double Function();
typedef GetCartCountCallback = int Function();
typedef GetCartItemsCallback = List<Map<String, dynamic>> Function();

/// Voice Assistant — Gemini AI Agent
///
/// Gemini drives the ENTIRE conversation via function calling.
/// No hardcoded state machine. Natural, interactive, like a real shopkeeper.
///
/// Flow: Audio → Transcribe → Gemini chat → Function call → Execute → Respond → TTS
class VoiceAssistantService {
  // ── Services ──
  final GeminiVoiceService _recorder = GeminiVoiceService();
  final TtsService _tts = TtsService();
  final GeminiConversationService _gemini = GeminiConversationService();
  final ProductSearchEngine _searchEngine = ProductSearchEngine();
  // Device STT — primary voice capture (more reliable than record package on Android)
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttInitialized = false;
  String _sttText = '';
  bool _sttListening = false;

  // ── Shop context ──
  int? shopId;
  String? shopName;

  // ── Product cache (loaded once, searched locally as fallback) ──
  List<Map<String, dynamic>> _cachedProducts = [];
  bool _productsLoaded = false;

  // ── State ──
  AgentState _state = AgentState.idle;
  AgentState get state => _state;
  bool _stopped = false;
  bool get isStopped => _stopped;
  bool _geminiReady = false;

  // ── Messages (chat history for UI) ──
  final List<AgentMessage> messages = [];

  // ── Gemini context tracking ──
  List<Map<String, dynamic>>? _lastSearchResults;
  Map<String, dynamic>? _lastAddedProduct;
  bool _sessionEnding = false;

  // ── Auto-listen ──
  bool _isAutoListening = false;
  int _silentAttempts = 0;
  static const _maxSilentAttempts = 3;
  bool get isAutoListening => _isAutoListening || _recorder.isRecording;
  bool get isAutoListenExhausted => _silentAttempts >= _maxSilentAttempts;

  // ── Callbacks ──
  VoidCallback? onStateChanged;
  void Function(AgentMessage)? onMessage;
  AddToCartCallback? onAddToCart;
  RemoveFromCartCallback? onRemoveFromCart;
  GetCartTotalCallback? onGetCartTotal;
  GetCartCountCallback? onGetCartCount;
  GetCartItemsCallback? onGetCartItems;

  // ── Public getters for UI ──
  GeminiVoiceService get geminiVoice => _recorder;
  TtsService get ttsService => _tts;
  bool get isRecordingManually => _sttListening || _stt.isListening;

  // ═══════════════════════════════════════════════════════
  //  SESSION MANAGEMENT
  // ═══════════════════════════════════════════════════════

  Future<void> startSession() async {
    messages.clear();
    _stopped = false;
    _silentAttempts = 0;
    _lastSearchResults = null;
    _lastAddedProduct = null;
    _sessionEnding = false;
    _geminiReady = false;

    // Show greeting INSTANTLY (no API call, no waiting)
    final shopLabel = shopName != null ? ' $shopName-ல' : '';
    final greetTamil = 'வணக்கம்!$shopLabel என்ன வேணும் சொல்லுங்க';
    const greetEn = 'Hello! What do you need?';
    _addBot(greetTamil, sub: greetEn);
    _setState(AgentState.speaking);

    // Init TTS + load products + init Gemini in parallel (background)
    unawaited(_loadProducts());
    unawaited(_initGemini());
    await _tts.initialize();
    if (_stopped) return;

    // Speak greeting while products/Gemini load in background
    await _tts.speak(greetTamil);
    await Future.delayed(const Duration(milliseconds: 300));

    // Inject greeting into Gemini history so it has context
    _gemini.injectModelMessage(
      '$greetTamil | $greetEn',
    );

    if (!_stopped) _setState(AgentState.listening);
  }

  /// Helper to fire-and-forget a future (suppresses lint)
  static void unawaited(Future<void> future) {
    future.catchError((e) => debugPrint('Agent: background error: $e'));
  }

  Future<void> stopSession() async {
    _stopped = true;
    _isAutoListening = false;
    _lastSearchResults = null;
    _lastAddedProduct = null;
    _sessionEnding = false;
    _setState(AgentState.idle);
    if (_recorder.isRecording) await _recorder.stopRecording();
    await _tts.stop();
  }

  Future<void> pause() async {
    _stopped = true;
    _isAutoListening = false;
    if (_recorder.isRecording) await _recorder.stopRecording();
    await _tts.stop();
  }

  Future<void> resumeSession() async {
    if (!_stopped) return;
    _stopped = false;
    _silentAttempts = 0;
    final msg = 'சரி, தொடருங்க. என்ன வேணும்?';
    _addBot(msg, sub: 'OK, continue. What do you need?');
    await _speak(msg);
    if (!_stopped) _setState(AgentState.listening);
  }

  void resetAndListen() {
    _silentAttempts = 0;
    _stopped = false;
    _setState(AgentState.listening);
  }

  // ═══════════════════════════════════════════════════════
  //  INPUT: Recording + Transcription
  // ═══════════════════════════════════════════════════════

  /// Initialize device STT (called once)
  Future<bool> _initStt() async {
    if (_sttInitialized) return true;
    _sttInitialized = await _stt.initialize(
      onError: (e) => debugPrint('Agent STT error: ${e.errorMsg}'),
      onStatus: (s) => debugPrint('Agent STT status: $s'),
    );
    return _sttInitialized;
  }

  /// Start listening via device STT (user tapped mic)
  Future<bool> startManualRecording() async {
    final ready = await _initStt();
    if (!ready) return false;
    _sttText = '';
    _sttListening = true;
    await _stt.listen(
      onResult: (r) {
        if (r.recognizedWords.isNotEmpty) _sttText = r.recognizedWords;
      },
      localeId: 'ta-IN',
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
      pauseFor: const Duration(seconds: 30), // user taps stop manually
      listenFor: const Duration(seconds: 60),
    );
    debugPrint('Agent: STT manual listen started');
    return true;
  }

  /// Stop STT → pass recognized text to Gemini
  Future<void> stopAndProcess() async {
    if (_stopped) return;

    if (_sttListening) {
      if (_stt.isListening) await _stt.stop();
      _sttListening = false;
      await Future.delayed(const Duration(milliseconds: 300)); // let final result settle
    }

    _setState(AgentState.processing);
    final text = _sttText.trim();
    _sttText = '';

    if (text.isEmpty) {
      debugPrint('Agent: STT returned empty');
      _setState(AgentState.listening);
      return;
    }

    _silentAttempts = 0;
    debugPrint('Agent: STT captured: "$text"');
    await processTextInput(text);
  }

  /// Auto-listen: device STT → process → repeat
  Future<void> autoListenAndProcess() async {
    if (_stopped || _isAutoListening) return;
    if (_state != AgentState.listening) return;

    _isAutoListening = true;
    debugPrint('Agent: Auto-listen starting...');

    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 400));
    if (_stopped) { _isAutoListening = false; return; }

    final ready = await _initStt();
    if (!ready) {
      _isAutoListening = false;
      _silentAttempts++;
      return;
    }

    _sttText = '';
    onStateChanged?.call();

    // Listen for up to 7 seconds
    await _stt.listen(
      onResult: (r) {
        if (r.recognizedWords.isNotEmpty) _sttText = r.recognizedWords;
        if (r.finalResult && _sttText.isNotEmpty) {
          debugPrint('Agent: STT final: "$_sttText"');
        }
      },
      localeId: 'ta-IN',
      listenMode: stt.ListenMode.search,
      partialResults: true,
      cancelOnError: false,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 7),
    );

    // Wait for STT to finish
    for (int i = 0; i < 25 && _stt.isListening && !_stopped; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (_stt.isListening) await _stt.stop();

    _isAutoListening = false;
    if (_stopped) return;

    final text = _sttText.trim();
    _sttText = '';

    if (text.isEmpty) {
      _silentAttempts++;
      debugPrint('Agent: STT empty attempt $_silentAttempts/$_maxSilentAttempts');
      _setState(AgentState.listening);
      return;
    }

    _silentAttempts = 0;
    _setState(AgentState.processing);
    onStateChanged?.call();
    await processTextInput(text);
  }

  /// Cancel recording without processing
  Future<void> cancelRecording() async {
    _isAutoListening = false;
    _sttListening = false;
    if (_stt.isListening) await _stt.stop();
    if (_recorder.isRecording) await _recorder.stopRecording();
  }

  // ═══════════════════════════════════════════════════════
  //  CORE: Text → Gemini → Execute → Respond
  // ═══════════════════════════════════════════════════════

  /// Process any text input (from voice transcription or typed text)
  Future<void> processTextInput(String text) async {
    if (text.trim().isEmpty) return;
    _stopped = false;
    _silentAttempts = 0;

    _addUser(text);
    _setState(AgentState.processing);
    _lastSearchResults = null;
    _lastAddedProduct = null;
    _sessionEnding = false;

    // Wait briefly for Gemini to be ready (background init from startSession)
    if (!_geminiReady) {
      for (int i = 0; i < 10 && !_geminiReady && !_stopped; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    if (!_geminiReady) {
      debugPrint('Agent: Gemini not ready, using local fallback');
      await _localFallback(text);
      return;
    }

    try {
      // Send to Gemini with timeout
      var response = await _gemini.chat(text).timeout(
        const Duration(seconds: 12),
        onTimeout: () => ConversationResponse.error('Timeout'),
      );
      if (_stopped) return;

      // Handle chained function calls (Gemini may call multiple functions)
      int maxCalls = 5;
      while (response.isFunctionCall && !_stopped && maxCalls-- > 0) {
        debugPrint('Agent: Gemini calls ${response.functionName}(${response.args})');
        final result = await _executeFunction(
          response.functionName!,
          response.args ?? {},
        );
        if (_stopped) return;

        response = await _gemini.sendFunctionResult(
          response.functionName!,
          response.args ?? {},
          result,
        ).timeout(
          const Duration(seconds: 12),
          onTimeout: () => ConversationResponse.error('Timeout'),
        );
        if (_stopped) return;
      }

      // Handle final text response
      if (response.isText) {
        await _handleGeminiText(response.text!);
      } else if (response.isError) {
        debugPrint('Agent: Gemini error: ${response.error}');
        await _localFallback(text);
      }
    } catch (e) {
      debugPrint('Agent: processTextInput error: $e');
      await _localFallback(text);
    }
  }

  /// User tapped a product card — add directly + sync Gemini context
  Future<void> tapProduct(Map<String, dynamic> product) async {
    // Stop any ongoing recording/speaking
    _stopped = true;
    _isAutoListening = false;
    await _tts.stop();
    if (_recorder.isRecording) await _recorder.stopRecording();
    await Future.delayed(const Duration(milliseconds: 200));

    _stopped = false;
    _silentAttempts = 0;
    _setState(AgentState.processing);

    // Add to cart directly (fast, no Gemini round-trip)
    bool added = false;
    if (onAddToCart != null) {
      added = await onAddToCart!(product, quantity: 1);
    }

    final name = product['name']?.toString() ?? '';
    final price = product['price']?.toString() ?? '0';
    final weight = product['weightDisplay']?.toString() ?? '';
    final weightLabel = weight.isNotEmpty ? ' $weight' : '';

    if (added) {
      final cartTotal = onGetCartTotal?.call() ?? 0.0;
      final totalStr = cartTotal > 0 ? ' Total: ₹${cartTotal.toStringAsFixed(0)}' : '';

      // Inject into Gemini history so it knows what happened
      _gemini.injectFunctionExecution(
        'add_to_cart',
        {'product_id': product['id']?.toString() ?? '', 'product_name': name, 'quantity': 1},
        {'success': true, 'product': name, 'price': price, 'cartTotal': cartTotal},
      );
      _gemini.injectModelMessage(
        '$name$weightLabel சேர்த்தாச்சு!$totalStr வேற என்ன வேணும்? | '
        '$name$weightLabel added!$totalStr What else?',
      );

      _addBot(
        '$name$weightLabel ₹$price சேர்த்தாச்சு!$totalStr வேற என்ன வேணும்?',
        sub: '$name$weightLabel Rs.$price added!$totalStr What else?',
        addedProduct: product,
      );
      await _speak('$name சேர்த்தாச்சு! வேற என்ன வேணும்?');
    } else {
      _addBot('$name stock இல்லை!', sub: '$name out of stock!');
      await _speak('$name stock இல்லை, வேற சொல்லுங்க');
    }

    if (!_stopped) _setState(AgentState.listening);
  }

  // ═══════════════════════════════════════════════════════
  //  GEMINI INITIALIZATION
  // ═══════════════════════════════════════════════════════

  Future<void> _initGemini() async {
    try {
      await _gemini.ensureApiKeys();

      final shopLabel = shopName ?? 'Shop';
      _gemini.configure(
        systemPrompt: _buildSystemPrompt(shopLabel),
        tools: _buildToolDeclarations(),
      );
      _gemini.clearHistory();
      _geminiReady = true;
      debugPrint('Agent: Gemini ready');
    } catch (e) {
      debugPrint('Agent: Gemini init failed: $e');
      _geminiReady = false;
    }
  }

  String _buildSystemPrompt(String shopLabel) {
    return '''You are NammaOoru's AI shopping assistant at "$shopLabel". You help customers order groceries through natural Tamil voice conversation.

HOW TO RESPOND:
- Always respond as: "Tamil text | English translation"
- Keep responses SHORT: 1-2 sentences maximum
- Be warm, friendly, natural — like a real Tamil shopkeeper
- Use casual Tamil: "வேணும்", "சொல்லுங்க", "போட்டாச்சு"

CONVERSATION FLOW:
1. Customer says a product name → call search_products with corrected name
2. Search returns results → list them numbered: "1. Name Weight ₹Price, 2. Name Weight ₹Price. எது வேணும்? | Which one?"
3. Customer says a number (1, 2, 3) → call add_to_cart with that product's ID from the last search
4. After adding → confirm and ask: "வேற என்ன வேணும்? | What else do you need?"
5. Customer says done/போதும்/bye/enough → call end_session
6. Customer says remove/நீக்கு + product name → call remove_from_cart
7. Customer says cart/கார்ட்/what's in cart → call get_cart
8. Customer asks about price/cost → search and tell them
9. Customer is unsure → ask helpful questions: "அரிசியா? எந்த brand? | Rice? Which brand?"

VOICE RECOGNITION INTELLIGENCE:
Speech-to-text makes many mistakes. You MUST understand the intent:
- "only on" / "onli on" / "union" = onion (வெங்காயம்)
- "to motto" / "tomotto" / "tamoto" = tomato (தக்காளி)
- "arise" / "arisi" / "race" = rice (அரிசி)
- "flower" / "collar flower" = cauliflower
- "should gar" / "sugar" = sugar (சர்க்கரை)
- "doll" / "dal" = dal/lentils (பருப்பு)
- "pot auto" / "potato" = potato (உருளைக்கிழங்கு)
- "coco not" = coconut (தேங்காய்)
- Numbers in Tamil: ஒன்று=1, இரண்டு=2, மூன்று=3, நான்கு=4, ஐந்து=5
- Ordinals in Tamil: முதலாவது/ஒன்னாவது=1, இரண்டாவது/ரெண்டாவது=2, மூன்றாவது=3
- "இரண்டாவது நம்பர்" = option 2, "மூன்றாவது நம்பர்" = option 3

CONTEXT AWARENESS:
- If you just showed numbered options and customer says "1" or "first one" or "ஒன்று" → they're selecting option 1
- If customer says "yes"/"ஆமா"/"சரி" after you suggested something → proceed with that
- If customer says "no"/"வேண்டாம்"/"இல்லை" → ask what they want instead
- Remember what was discussed — "that one" refers to the product being talked about
- If customer asks for multiple items ("rice and dal") → search for each one at a time

RULES:
- ALWAYS call search_products before suggesting any product — NEVER invent products or prices
- After adding to cart, ALWAYS ask what else they need
- If not found: "கிடைக்கவில்லை, வேற சொல்லுங்க | Not available, try something else"
- Products have different weights (100g, 250g, 500g, 1kg) — show all variants
- Be patient if customer repeats or corrects themselves''';
  }

  List<Map<String, dynamic>> _buildToolDeclarations() {
    return [
      {
        'name': 'search_products',
        'description': 'Search for products in the shop. Call this whenever customer mentions a product name or asks about availability/price.',
        'parameters': {
          'type': 'OBJECT',
          'properties': {
            'query': {
              'type': 'STRING',
              'description': 'Product name or search keyword (e.g., "rice", "tomato", "oil"). Fix voice recognition errors before searching.',
            },
          },
          'required': ['query'],
        },
      },
      {
        'name': 'add_to_cart',
        'description': 'Add a product to cart. Use product_id from the most recent search results.',
        'parameters': {
          'type': 'OBJECT',
          'properties': {
            'product_id': {
              'type': 'STRING',
              'description': 'Product ID from search results',
            },
            'product_name': {
              'type': 'STRING',
              'description': 'Product name for confirmation',
            },
            'quantity': {
              'type': 'NUMBER',
              'description': 'Quantity (default 1)',
            },
          },
          'required': ['product_id', 'product_name'],
        },
      },
      {
        'name': 'remove_from_cart',
        'description': 'Remove a product from cart by name',
        'parameters': {
          'type': 'OBJECT',
          'properties': {
            'product_name': {
              'type': 'STRING',
              'description': 'Product name to remove',
            },
          },
          'required': ['product_name'],
        },
      },
      {
        'name': 'get_cart',
        'description': 'Show current cart contents and total',
        'parameters': {
          'type': 'OBJECT',
          'properties': {},
        },
      },
      {
        'name': 'end_session',
        'description': 'End shopping session when customer says done/bye/போதும்/enough',
        'parameters': {
          'type': 'OBJECT',
          'properties': {},
        },
      },
    ];
  }

  // ═══════════════════════════════════════════════════════
  //  GEMINI RESPONSE HANDLING
  // ═══════════════════════════════════════════════════════

  /// Parse and display Gemini's text response (with product cards if applicable)
  Future<void> _handleGeminiText(String text) async {
    // Parse "Tamil | English" format
    String tamil = text;
    String? english;
    if (text.contains('|')) {
      final idx = text.indexOf('|');
      tamil = text.substring(0, idx).trim();
      english = text.substring(idx + 1).trim();
    }

    if (_lastAddedProduct != null) {
      // Product was just added — show with green checkmark
      final product = _lastAddedProduct!;
      _addBot(tamil, sub: english, addedProduct: product);
      _lastAddedProduct = null;
      await _speak(tamil);
      if (!_stopped) _setState(AgentState.listening);
    } else if (_lastSearchResults != null && _lastSearchResults!.isNotEmpty) {
      // Search results — show product option cards
      _addBot(tamil, sub: english, products: _lastSearchResults);
      _lastSearchResults = null;
      await _speak(tamil);
      if (!_stopped) _setState(AgentState.listening);
    } else if (_sessionEnding) {
      // Session ending
      _addBot(tamil, sub: english);
      await _speak(tamil);
      _sessionEnding = false;
      _setState(AgentState.idle);
    } else {
      // Normal text response
      _addBot(tamil, sub: english);
      await _speak(tamil);
      if (!_stopped) _setState(AgentState.listening);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  FUNCTION EXECUTION
  // ═══════════════════════════════════════════════════════

  Future<Map<String, dynamic>> _executeFunction(
    String name,
    Map<String, dynamic> args,
  ) async {
    switch (name) {
      case 'search_products':
        return await _execSearch(args);
      case 'add_to_cart':
        return await _execAddToCart(args);
      case 'remove_from_cart':
        return _execRemoveFromCart(args);
      case 'get_cart':
        return _execGetCart();
      case 'end_session':
        return _execEndSession();
      default:
        return {'error': 'Unknown function: $name'};
    }
  }

  Future<Map<String, dynamic>> _execSearch(Map<String, dynamic> args) async {
    final query = args['query']?.toString() ?? '';
    if (query.isEmpty) return {'products': [], 'count': 0};

    // Try local search FIRST (instant, indexed in memory), then AI fallback
    var matches = _localSearch(query);
    if (matches.isEmpty) {
      matches = await _aiSearch(query);
    }

    // Store for UI product cards
    _lastSearchResults = matches.take(8).toList();

    // Return structured data for Gemini to describe
    final productList = _lastSearchResults!.asMap().entries.map((e) {
      final p = e.value;
      return <String, dynamic>{
        'index': e.key + 1,
        'id': p['id']?.toString() ?? '',
        'name': p['name']?.toString() ?? '',
        'nameTamil': p['nameTamil']?.toString() ?? '',
        'price': p['price']?.toString() ?? '0',
        'weight': p['weightDisplay']?.toString() ?? '',
      };
    }).toList();

    debugPrint('Agent: Search "$query" → ${productList.length} results');
    return {'products': productList, 'count': productList.length, 'query': query};
  }

  Future<Map<String, dynamic>> _execAddToCart(Map<String, dynamic> args) async {
    final productId = args['product_id']?.toString() ?? '';
    final productName = args['product_name']?.toString() ?? '';
    final qty = (args['quantity'] is num)
        ? (args['quantity'] as num).toInt()
        : int.tryParse(args['quantity']?.toString() ?? '1') ?? 1;

    // Find the product in our data
    final product = _findProduct(productId, productName);
    if (product == null) {
      return {'success': false, 'message': '$productName not found in results'};
    }

    bool added = false;
    if (onAddToCart != null) {
      added = await onAddToCart!(product, quantity: qty);
    }

    if (added) {
      _lastAddedProduct = product;
      return {
        'success': true,
        'product': product['name']?.toString() ?? productName,
        'quantity': qty,
        'price': product['price']?.toString() ?? '0',
        'weight': product['weightDisplay']?.toString() ?? '',
        'cartCount': onGetCartCount?.call() ?? 0,
        'cartTotal': onGetCartTotal?.call() ?? 0.0,
      };
    } else {
      return {'success': false, 'message': '$productName out of stock'};
    }
  }

  Map<String, dynamic> _execRemoveFromCart(Map<String, dynamic> args) {
    final name = args['product_name']?.toString() ?? '';
    final removed = onRemoveFromCart?.call(name) ?? false;
    return {
      'success': removed,
      'message': removed ? '$name removed' : '$name not in cart',
      'cartCount': onGetCartCount?.call() ?? 0,
      'cartTotal': onGetCartTotal?.call() ?? 0.0,
    };
  }

  Map<String, dynamic> _execGetCart() {
    final items = onGetCartItems?.call() ?? [];
    return {
      'items': items.map((i) => <String, dynamic>{
        'name': i['name'],
        'quantity': i['quantity'],
        'price': i['price'],
      }).toList(),
      'count': onGetCartCount?.call() ?? 0,
      'total': onGetCartTotal?.call() ?? 0.0,
    };
  }

  Map<String, dynamic> _execEndSession() {
    _sessionEnding = true;
    return {
      'message': 'Session ending',
      'cartCount': onGetCartCount?.call() ?? 0,
      'cartTotal': onGetCartTotal?.call() ?? 0.0,
    };
  }

  // ═══════════════════════════════════════════════════════
  //  PRODUCT SEARCH
  // ═══════════════════════════════════════════════════════

  /// Find product by ID (check search results, then cache)
  Map<String, dynamic>? _findProduct(String id, String name) {
    // Check last search results first
    if (_lastSearchResults != null) {
      for (final p in _lastSearchResults!) {
        if (p['id']?.toString() == id) return p;
      }
    }
    // Check full cache
    for (final p in _cachedProducts) {
      if (p['id']?.toString() == id) return p;
    }
    // Try by name
    if (name.isNotEmpty) {
      final lower = name.toLowerCase();
      for (final p in _cachedProducts) {
        if ((p['name']?.toString().toLowerCase() ?? '').contains(lower)) return p;
      }
    }
    return null;
  }

  /// Backend AI search (Gemini-powered, understands intent)
  Future<List<Map<String, dynamic>>> _aiSearch(String query) async {
    if (shopId == null) return [];
    try {
      final response = await ApiClient.get(
        '/shops/$shopId/products/ai-search',
        queryParameters: {'query': query},
      );
      final data = response.data;
      if (data == null || data['statusCode'] != '0000') return [];

      final List<dynamic> products = data['data']?['matchedProducts'] ?? [];
      return products.map<Map<String, dynamic>>((p) => _mapProduct(p)).toList();
    } catch (e) {
      debugPrint('Agent: AI search error: $e');
      return [];
    }
  }

  /// Offline local search (inverted index, fuzzy, phonetic)
  List<Map<String, dynamic>> _localSearch(String query) {
    if (!_searchEngine.isIndexed) return [];
    final q = query.toLowerCase().trim();
    if (q.length < 2) return [];

    var results = _searchEngine.search(q, limit: 10);
    if (results.isEmpty) {
      results = _searchEngine.sttCorrectionSearch(q, limit: 10);
    }
    return results;
  }

  // ═══════════════════════════════════════════════════════
  //  PRODUCT CACHE
  // ═══════════════════════════════════════════════════════

  Future<void> _loadProducts() async {
    if (shopId == null || _productsLoaded) return;
    try {
      final response = await ApiClient.get(
        '/customer/shops/$shopId/products',
        queryParameters: {'page': '0', 'size': '2000', 'sortBy': 'name', 'sortDir': 'asc'},
      );
      final data = response.data;
      if (data != null && data['statusCode'] == '0000') {
        final List<dynamic> products = data['data']?['content'] ?? [];
        _cachedProducts = products.map<Map<String, dynamic>>((p) => _mapProduct(p)).toList();
        _searchEngine.indexProducts(_cachedProducts);
        _productsLoaded = true;
        debugPrint('Agent: Cached ${_cachedProducts.length} products');
      }
    } catch (e) {
      debugPrint('Agent: Product load error: $e');
    }
  }

  /// Force refresh products
  Future<void> refreshProducts() async {
    _productsLoaded = false;
    await _loadProducts();
  }

  /// Map raw product API response to our standard format
  Map<String, dynamic> _mapProduct(dynamic p) {
    final name = (p['displayName'] ?? p['customName'] ?? p['name'] ?? '').toString();
    final nameTamil = (p['nameTamil'] ?? '').toString();
    final category = (p['categoryName'] ?? p['category'] ?? '').toString();
    final tags = (p['tags'] ?? '').toString();
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
  }

  String _extractImage(dynamic p) {
    if (p['primaryImageUrl'] != null) return p['primaryImageUrl'].toString();
    if (p['images'] != null && p['images'] is List && (p['images'] as List).isNotEmpty) {
      final img = (p['images'] as List).first;
      if (img is String) return img;
      if (img is Map) return img['imageUrl']?.toString() ?? '';
    }
    if (p['masterProduct'] != null && p['masterProduct']['primaryImageUrl'] != null) {
      return p['masterProduct']['primaryImageUrl'].toString();
    }
    return '';
  }

  // ═══════════════════════════════════════════════════════
  //  AUDIO TRANSCRIPTION (Backend Whisper → Gemini API)
  // ═══════════════════════════════════════════════════════

  Future<String?> _transcribe(String audioPath) async {
    try {
      // On web, GeminiVoiceService uses Web Speech API — no file to check
      if (kIsWeb || audioPath == '__web__') {
        final text = await _recorder.transcribeAudio(audioPath);
        debugPrint('Agent: Web STT transcription: "$text"');
        return text;
      }

      final file = File(audioPath);
      if (!file.existsSync()) return null;

      final fileSize = file.lengthSync();
      if (fileSize < 3000) {
        debugPrint('Agent: Audio too small (${fileSize}B), no speech');
        return null;
      }

      // Method 1: Backend transcription (Whisper/Gemini)
      try {
        final text = await _recorder.transcribeAudio(audioPath);
        if (text != null && text.trim().isNotEmpty) {
          debugPrint('Agent: Backend transcribed: "$text"');
          return text;
        }
      } catch (e) {
        debugPrint('Agent: Backend transcription error: $e');
      }

      // Method 2: Gemini API direct
      try {
        await _gemini.ensureApiKeys();
        if (!file.existsSync()) return null;
        final bytes = await file.readAsBytes();
        final base64Audio = base64Encode(bytes);
        final text = await _gemini.transcribeAudio(base64Audio);
        if (text != null && text.trim().isNotEmpty) {
          debugPrint('Agent: Gemini transcribed: "$text"');
          return text;
        }
      } catch (e) {
        debugPrint('Agent: Gemini transcription error: $e');
      }

      return null;
    } finally {
      try {
        final f = File(audioPath);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
  }

  // ═══════════════════════════════════════════════════════
  //  LOCAL FALLBACK (when Gemini is unavailable)
  // ═══════════════════════════════════════════════════════

  Future<void> _localFallback(String text) async {
    final lower = text.trim().toLowerCase();

    // End commands
    if (_isEndWord(lower)) {
      final count = onGetCartCount?.call() ?? 0;
      final total = onGetCartTotal?.call() ?? 0.0;
      final bye = count > 0
          ? '$count items, ₹${total.toStringAsFixed(0)}. நன்றி!'
          : 'நன்றி! மீண்டும் வாங்க.';
      _addBot(bye, sub: 'Thank you!');
      await _speak(bye);
      _setState(AgentState.idle);
      return;
    }

    // Search products locally
    _setState(AgentState.processing);
    var matches = await _aiSearch(text);
    if (matches.isEmpty) matches = _localSearch(text);

    if (matches.isEmpty) {
      _addBot('கிடைக்கவில்லை, வேற சொல்லுங்க', sub: 'Not found, try something else');
      await _speak('கிடைக்கவில்லை, வேற சொல்லுங்க');
    } else {
      _lastSearchResults = matches.take(8).toList();
      final names = _lastSearchResults!
          .asMap()
          .entries
          .map((e) => '${e.key + 1}. ${e.value['name']} ₹${e.value['price']}')
          .join(', ');
      _addBot('$names. எது வேணும்?', sub: '$names. Which one?', products: _lastSearchResults);
      await _speak('${_lastSearchResults!.length} products found. எது வேணும்?');
    }

    if (!_stopped) _setState(AgentState.listening);
  }

  static final _endWords = {'போதும்', 'நிறுத்து', 'முடிந்தது', 'done', 'enough', 'stop',
    'that\'s all', 'finish', 'bye', 'thanks', 'thank you', 'no more'};

  bool _isEndWord(String text) => _endWords.any((w) => text == w || text.contains(w));

  // ═══════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════

  Future<void> _speak(String text) async {
    _setState(AgentState.speaking);
    await _tts.speak(text);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  void _setState(AgentState s) {
    _state = s;
    onStateChanged?.call();
  }

  void _addBot(String text, {String? sub, List<Map<String, dynamic>>? products,
      Map<String, dynamic>? addedProduct, bool isCartSummary = false}) {
    final msg = AgentMessage(
      text: text, isBot: true, subText: sub,
      products: products, addedProduct: addedProduct, isCartSummary: isCartSummary,
    );
    messages.add(msg);
    onMessage?.call(msg);
  }

  void _addUser(String text) {
    final msg = AgentMessage(text: text, isBot: false);
    messages.add(msg);
    onMessage?.call(msg);
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
    _tts.dispose();
    _recorder.dispose();
    _gemini.dispose();
  }
}
