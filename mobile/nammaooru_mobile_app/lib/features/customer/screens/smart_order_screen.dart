import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/models/product_model.dart';
import '../../../services/smart_order_service.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/localization/language_provider.dart';

class SmartOrderScreen extends StatefulWidget {
  final int? shopId;
  final String? shopName;

  const SmartOrderScreen({super.key, this.shopId, this.shopName});

  @override
  State<SmartOrderScreen> createState() => _SmartOrderScreenState();
}

class _SmartOrderScreenState extends State<SmartOrderScreen> {
  final SmartOrderService _service = SmartOrderService();
  final TextEditingController _textController = TextEditingController();

  SmartOrderResult? _result;
  bool _isProcessing = false;
  String _statusMessage = '';
  // Conversation history for display
  final List<_ChatMessage> _messages = [];

  // Real-time search suggestions
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounceTimer;

  // Live voice-to-text with real-time suggestions
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _currentLocale = 'en-IN'; // Toggle between en-IN and ta-IN

  @override
  void initState() {
    super.initState();
    // Set shop context if provided
    _service.shopId = widget.shopId;
    _service.shopName = widget.shopName;
    _service.ttsService.initialize();
    // Load Gemini AI keys from backend (for photo reading)
    _service.loadAiConfig();
    // Voice assistant always enabled (admin can disable via backend later)

    final shopLabel = widget.shopName != null
        ? ' (${widget.shopName})'
        : '';
    _addBotMessage('வணக்கம்! என்ன வேணும்?$shopLabel\nHello! What do you need?');
  }


  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_speech.isListening) _speech.stop();
    _textController.dispose();
    _service.dispose();
    super.dispose();
  }

  /// Debounced search suggestions as user types or speaks
  /// Uses offline ProductSearchEngine — no internet needed
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final results = await _service.getSuggestions(query.trim());
      if (mounted) {
        setState(() => _suggestions = results);
      }
    });
  }

  // ── Live Voice Input with real-time suggestions ──

  /// Start listening — shows partial speech in text field, triggers suggestions live
  Future<void> _startListening() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (error) {
        debugPrint('Speech error: ${error.errorMsg}');
        if (mounted) setState(() => _isListening = false);
      },
    );

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone not available'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    _lastFinalText = '';

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final text = result.recognizedWords;
        _textController.text = text;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
        // Trigger real-time suggestions as words come in
        _onSearchChanged(text);

        // When speech is final → check if we got good results
        if (result.finalResult) {
          _lastFinalText = text;
          _handleFinalSpeech(text);
        }
      },
      localeId: _currentLocale,
      listenMode: stt.ListenMode.confirmation,
      partialResults: true,
      cancelOnError: false,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 30),
    );
  }

  String _lastFinalText = '';
  bool _isRetrying = false;

  /// After speech finishes → send directly to Gemini AI search.
  /// Gemini understands intent even when STT gives wrong words.
  Future<void> _handleFinalSpeech(String text) async {
    setState(() => _isListening = false);
    if (text.trim().isEmpty) return;

    // ALWAYS use Gemini AI for voice — it understands intent
    final results = await _service.aiSearchProducts(text.trim());
    if (results.isNotEmpty && mounted) {
      setState(() => _suggestions = results);
      return;
    }

    // AI failed → retry with other language
    if (!_isRetrying) {
      _isRetrying = true;
      final otherLocale = _currentLocale == 'en-IN' ? 'ta-IN' : 'en-IN';
      final langName = otherLocale == 'ta-IN' ? 'Tamil' : 'English';

      if (mounted) {
        setState(() => _isListening = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retrying in $langName...'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.orange,
          ),
        );
      }

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final retryText = result.recognizedWords;
          _textController.text = retryText;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: retryText.length),
          );
          _onSearchChanged(retryText);
          if (result.finalResult) {
            setState(() => _isListening = false);
            _isRetrying = false;
            // Also send retry to Gemini AI
            _service.aiSearchProducts(retryText.trim()).then((aiResults) {
              if (aiResults.isNotEmpty && mounted) {
                setState(() => _suggestions = aiResults);
              }
            });
          }
        },
        localeId: otherLocale,
        listenMode: stt.ListenMode.confirmation,
        partialResults: true,
        cancelOnError: false,
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 15),
      );
    }
  }

  /// Stop listening
  Future<void> _stopListening() async {
    await _speech.stop();
    _isRetrying = false;
    setState(() => _isListening = false);
  }

  /// Switch language — EN or TA
  void _setLocale(String locale) {
    setState(() => _currentLocale = locale);
    if (_isListening) {
      _stopListening().then((_) => _startListening());
    }
  }

  /// Toggle EN↔TA locale on long press
  void _toggleLocale() {
    _setLocale(_currentLocale == 'en-IN' ? 'ta-IN' : 'en-IN');
  }

  /// Add a suggested product directly to cart
  Future<void> _addSuggestionToCart(Map<String, dynamic> product) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final productModel = _toProductModel(product);
    final success = await cart.addToCart(productModel);

    if (success && mounted) {
      final name = product['name'] ?? '';
      final weight = product['weightDisplay']?.toString() ?? '';
      final weightLabel = weight.isNotEmpty ? ' $weight' : '';
      setState(() => _suggestions = []);
      _textController.clear();
      _addBotMessage('$name$weightLabel கார்ட்டில் சேர்க்கப்பட்டது!\n$name$weightLabel added to cart!');
      _service.speak('$name$weightLabel சேர்க்கப்பட்டது. வேற add பண்ணவா?');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name$weightLabel added to cart'),
          backgroundColor: VillageTheme.primaryGreen,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isBot: true));
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isBot: false));
    });
  }

  // ── Text Order ──
  Future<void> _submitTextOrder() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _isProcessing = true;

      _statusMessage = 'Searching products...';
    });

    _addUserMessage(text);

    final result = await _service.processTextOrder(text);

    if (result == null) {
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      _addBotMessage('பொருட்கள் கிடைக்கவில்லை.\nNo products found.');
      return;
    }

    _handleResult(result);
  }

  void _handleResult(SmartOrderResult result) {
    setState(() {
      _result = result;
      _isProcessing = false;
      _statusMessage = '';
    });

    final matched = result.matchedCount;
    final total = result.items.length;

    if (matched == 0) {
      _addBotMessage(
          'பொருட்கள் கிடைக்கவில்லை. வேறு முயற்சிக்கவும்.\n'
          'No products found. Try different words.');
    } else if (matched == total) {
      _addBotMessage(
          '$matched பொருட்கள் கிடைத்தன! கீழே பாருங்கள்.\n'
          'Found all $matched items! See below.');
    } else {
      _addBotMessage(
          '$total இல் $matched பொருட்கள் கிடைத்தன.\n'
          'Found $matched of $total items.');
    }
  }

  ProductModel _toProductModel(Map<String, dynamic> data) {
    return ProductModel(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      nameTamil: data['nameTamil']?.toString(),
      description: data['name']?.toString() ?? '',
      price: double.tryParse(data['price']?.toString() ?? '0') ?? 0.0,
      category: '',
      shopId: data['shopId']?.toString() ?? '',
      shopDatabaseId: data['shopDatabaseId'] is int
          ? data['shopDatabaseId']
          : int.tryParse(data['shopDatabaseId']?.toString() ?? ''),
      shopName: data['shopName']?.toString() ?? '',
      images: data['image'] != null && data['image'].toString().isNotEmpty
          ? [data['image'].toString()]
          : [],
      stockQuantity: 999,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _addAllToCart() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    int added = 0;

    if (_result == null) return;

    for (final item in _result!.items) {
      if (item.matches.isNotEmpty && !item.isAdded) {
        final productData = item.selectedMatch ?? item.matches.first;
        final productModel = _toProductModel(productData);
        final success = await cart.addToCart(productModel);
        if (success) {
          item.isAdded = true;
          added++;
        }
      }
    }

    setState(() {});

    if (added > 0) {
      _addBotMessage(
          '$added பொருட்கள் கார்ட்டில் சேர்க்கப்பட்டன!\n'
          '$added items added to cart!');
      // Speak items added + cart total
      final cartTotal = cart.total.toStringAsFixed(0);
      final cartCount = cart.itemCount;
      await _service.speak(
          '$added பொருட்கள் கார்ட்டில் சேர்க்கப்பட்டன. '
          'கார்ட்டில் $cartCount பொருட்கள், Total ₹$cartTotal');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$added items added to cart'),
            backgroundColor: VillageTheme.primaryGreen,
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () => context.push('/customer/cart'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _addSingleToCart(ParsedItem item, Map<String, dynamic> productData) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final productModel = _toProductModel(productData);
    final success = await cart.addToCart(productModel);

    if (success) {
      setState(() {
        item.selectedMatch = productData;
        item.isAdded = true;
      });

      _service.speak('${productData['name']} சேர்க்கப்பட்டது');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${productData['name']} added to cart'),
            backgroundColor: VillageTheme.primaryGreen,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _clearResults() {
    setState(() {
      _result = null;
      _messages.clear();
    });
    _addBotMessage('வணக்கம்! என்ன வேணும்?\nHello! What do you need?');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VillageTheme.lightBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.shopName != null
                    ? 'AI Order - ${widget.shopName}'
                    : 'AI Order / AI ஆர்டர்',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: VillageTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'New Order',
              onPressed: _clearResults,
            ),
          Consumer<CartProvider>(
            builder: (_, cart, __) => cart.itemCount > 0
                ? Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart),
                        onPressed: () => context.push('/customer/cart'),
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Conversation messages
                ..._messages.map(_buildChatBubble),

                // Processing indicator
                if (_isProcessing) _buildProcessingIndicator(),

                // Results — proper product list
                if (_result != null) ...[
                  const SizedBox(height: 8),
                  ..._result!.items.map(_buildItemSection),
                  if (_result!.items.any((i) => i.matches.isNotEmpty && !i.isAdded)) ...[
                    const SizedBox(height: 12),
                    _buildAddAllButton(),
                  ],
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: _clearResults,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add more items / மேலும் சேர்'),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Real-time suggestions
          if (_suggestions.isNotEmpty) _buildSuggestionsList(),

          // Input area at bottom
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final isTamil = Provider.of<LanguageProvider>(context, listen: false)
            .currentLanguage ==
        'ta';

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
        itemBuilder: (_, i) {
          final product = _suggestions[i];
          final name = product['name'] ?? '';
          final nameTamil = product['nameTamil'] ?? '';
          final price = product['price']?.toString() ?? '0';
          final imageUrl = product['image']?.toString() ?? '';
          final weightDisplay = product['weightDisplay']?.toString() ?? '';
          final primaryName = isTamil && nameTamil.isNotEmpty ? nameTamil : name;
          final secondaryName = isTamil && nameTamil.isNotEmpty ? name : nameTamil;

          return InkWell(
            onTap: () => _addSuggestionToCart(product),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Small product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ImageUrlHelper.getFullImageUrl(imageUrl),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 40, height: 40,
                              color: Colors.grey[100],
                              child: const Icon(Icons.shopping_bag, size: 18, color: Colors.grey),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 40, height: 40,
                              color: Colors.grey[100],
                              child: const Icon(Icons.shopping_bag, size: 18, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shopping_bag, size: 18, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: 10),
                  // Name + Tamil name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(primaryName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (secondaryName.isNotEmpty)
                          Text(secondaryName,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  // Price + weight
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹$price',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: VillageTheme.primaryGreen,
                              fontSize: 14)),
                      if (weightDisplay.isNotEmpty)
                        Text(weightDisplay,
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Quick add button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: VillageTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('+ ADD',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatBubble(_ChatMessage msg) {
    final isBot = msg.isBot;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: VillageTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy,
                  size: 18, color: VillageTheme.primaryGreen),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : VillageTheme.primaryGreen,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isBot ? 4 : 16),
                  bottomRight: Radius.circular(isBot ? 16 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isBot ? VillageTheme.primaryText : Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (!isBot) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: VillageTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _statusMessage,
            style: const TextStyle(
              color: VillageTheme.modernGray,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Section header for each parsed item keyword + product cards below it
  Widget _buildItemSection(ParsedItem item) {
    final hasMatches = item.matches.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Keyword header bar
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hasMatches
                ? VillageTheme.primaryGreen.withOpacity(0.08)
                : VillageTheme.errorRed.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasMatches
                  ? VillageTheme.primaryGreen.withOpacity(0.2)
                  : VillageTheme.errorRed.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasMatches
                    ? (item.isAdded ? Icons.check_circle : Icons.search)
                    : Icons.cancel,
                size: 20,
                color: hasMatches
                    ? (item.isAdded
                        ? VillageTheme.primaryGreen
                        : VillageTheme.skyBlue)
                    : VillageTheme.errorRed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"${item.name}"',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: hasMatches
                        ? VillageTheme.primaryText
                        : VillageTheme.errorRed,
                  ),
                ),
              ),
              if (item.isAdded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: VillageTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Added',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (hasMatches)
                Text(
                  '${item.matches.length} found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
            ],
          ),
        ),

        // Product cards — large format like search engine
        if (hasMatches && !item.isAdded)
          ...item.matches
              .map((product) => _buildProductCard(item, product)),

        // No match message
        if (!hasMatches)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: VillageTheme.errorRed.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: VillageTheme.errorRed, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No matching product found\nபொருள் கிடைக்கவில்லை',
                    style: TextStyle(
                        color: VillageTheme.errorRed, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Individual product card — large image, name, Tamil name, price, ADD button
  Widget _buildProductCard(
      ParsedItem item, Map<String, dynamic> product) {
    final name = product['name'] ?? '';
    final nameTamil = product['nameTamil'] ?? '';
    final price = product['price']?.toString() ?? '0';
    final imageUrl = product['image']?.toString() ?? '';
    final weightDisplay = product['weightDisplay']?.toString() ?? '';

    // Respect language toggle — show Tamil first when Tamil is selected
    final isTamil = Provider.of<LanguageProvider>(context, listen: false)
            .currentLanguage ==
        'ta';
    final primaryName =
        isTamil && nameTamil.isNotEmpty ? nameTamil : name;
    final secondaryName =
        isTamil && nameTamil.isNotEmpty ? name : nameTamil;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Product image — 72×72
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ImageUrlHelper.getFullImageUrl(imageUrl),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.image,
                            size: 28, color: Colors.grey),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.image,
                            size: 28, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_bag,
                          size: 28, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),

            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (secondaryName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      secondaryName,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '₹$price',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: VillageTheme.primaryGreen,
                          fontSize: 18,
                        ),
                      ),
                      if (weightDisplay.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(weightDisplay,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ADD button
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () => _addSingleToCart(item, product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VillageTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text('ADD',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Add All to Cart — full-width green button
  Widget _buildAddAllButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _addAllToCart,
        icon: const Icon(Icons.add_shopping_cart, size: 22),
        label: const Text(
          'Add All to Cart / அனைத்தும் சேர்',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: VillageTheme.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Listening indicator
          if (_isListening)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, size: 16, color: Colors.red.shade400),
                  const SizedBox(width: 6),
                  Text(
                    _currentLocale == 'ta-IN'
                        ? 'Listening Tamil... / தமிழில் பேசுங்கள்...'
                        : 'Listening English... / ஆங்கிலத்தில் பேசுங்கள்...',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // Mic button — tap to speak, long press to toggle EN/TA
              GestureDetector(
                onTap: _isProcessing ? null : () {
                  if (_isListening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                },
                onLongPress: _toggleLocale,
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isListening
                          ? [Colors.red, Colors.red.shade300]
                          : [const Color(0xFF6C63FF), const Color(0xFF8B7FFF)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.red : const Color(0xFF6C63FF))
                            .withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        size: 20,
                        color: Colors.white,
                      ),
                      Text(
                        _currentLocale == 'ta-IN' ? 'TA' : 'EN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Search text input
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isListening
                        ? Colors.red.shade50
                        : VillageTheme.inputBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isListening ? Colors.red.shade300 : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: _isListening
                                ? 'Speaking...'
                                : 'Type or speak / தட்டச்சு அல்லது பேசு',
                            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: _onSearchChanged,
                          onSubmitted: (_) {
                            if (_isListening) _stopListening();
                            setState(() => _suggestions = []);
                            _submitTextOrder();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send,
                            color: VillageTheme.primaryGreen),
                        onPressed: _isProcessing ? null : () {
                          if (_isListening) _stopListening();
                          setState(() => _suggestions = []);
                          _submitTextOrder();
                        },
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // AI Assistant button (compact)
              GestureDetector(
                onTap: _isProcessing ? null : () {
                  if (_isListening) _stopListening();
                  context.push('/customer/voice-assistant', extra: {
                    'shopId': widget.shopId,
                    'shopName': widget.shopName,
                  });
                },
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: VillageTheme.primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: VillageTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.assistant, size: 22, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _ChatMessage {
  final String text;
  final bool isBot;

  _ChatMessage({required this.text, required this.isBot});
}
