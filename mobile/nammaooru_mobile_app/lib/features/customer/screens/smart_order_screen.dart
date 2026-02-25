import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/models/product_model.dart';
import '../../../services/smart_order_service.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SmartOrderScreen extends StatefulWidget {
  final int? shopId;
  final String? shopName;

  const SmartOrderScreen({super.key, this.shopId, this.shopName});

  @override
  State<SmartOrderScreen> createState() => _SmartOrderScreenState();
}

class _SmartOrderScreenState extends State<SmartOrderScreen>
    with TickerProviderStateMixin {
  final SmartOrderService _service = SmartOrderService();
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  SmartOrderResult? _result;
  bool _isProcessing = false;
  bool _isListening = false;
  String _statusMessage = '';

  // Conversation history for display
  final List<_ChatMessage> _messages = [];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // Set shop context if provided
    _service.shopId = widget.shopId;
    _service.shopName = widget.shopName;
    _service.ttsService.initialize();

    final shopLabel = widget.shopName != null
        ? ' (${widget.shopName})'
        : '';
    _addBotMessage('வணக்கம்! என்ன வேணும்?$shopLabel\nHello! What do you need?');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _service.dispose();
    super.dispose();
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

  // ── Voice Order ──
  Future<void> _startVoiceOrder() async {
    setState(() {
      _isProcessing = true;
      _isListening = true;

      _statusMessage = 'Listening... speak in Tamil';
    });
    _pulseController.repeat();

    _addBotMessage('கேட்கிறேன்... தமிழில் சொல்லுங்கள்\nListening... speak in Tamil');

    final result = await _service.processVoiceOrder();
    _pulseController.stop();

    if (result == null) {
      setState(() {
        _isProcessing = false;
        _isListening = false;
        _statusMessage = '';
      });
      _addBotMessage('குரல் கிடைக்கவில்லை. மீண்டும் முயற்சிக்கவும்.\nCould not hear. Try again.');
      return;
    }

    _addUserMessage(result.rawInput);
    _handleResult(result);
  }

  // ── Photo Order ──
  Future<void> _startPhotoOrder() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final XFile? xFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (xFile == null) return;

    setState(() {
      _isProcessing = true;

      _statusMessage = 'Reading your list...';
    });

    _addUserMessage('[Photo of shopping list]');
    _addBotMessage('படத்தை படிக்கிறேன்...\nReading your list...');

    final result = await _service.processPhotoOrder(File(xFile.path));

    if (result == null) {
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      _addBotMessage('படத்தை படிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.\nCould not read image. Try again.');
      return;
    }

    _handleResult(result);
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
      _isListening = false;
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

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: VillageTheme.primaryGreen),
                title: const Text('Camera / கேமரா'),
                subtitle: const Text('Take photo of your list'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: VillageTheme.skyBlue),
                title: const Text('Gallery / கேலரி'),
                subtitle: const Text('Pick from gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
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
      _service.speak('$added பொருட்கள் கார்ட்டில் சேர்க்கப்பட்டன');

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

                // Results
                if (_result != null) ...[
                  const SizedBox(height: 8),
                  _buildResultsCard(),
                ],
              ],
            ),
          ),

          // Input area at bottom
          _buildInputArea(),
        ],
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
          if (_isListening)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VillageTheme.primaryGreen
                      .withOpacity(0.2 + 0.3 * _pulseController.value),
                ),
                child: const Icon(Icons.mic, color: VillageTheme.primaryGreen, size: 30),
              ),
            )
          else
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

  Widget _buildResultsCard() {
    if (_result == null) return const SizedBox.shrink();

    final hasAddableItems = _result!.items
        .any((i) => i.matches.isNotEmpty && !i.isAdded);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.receipt_long,
                    color: VillageTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Found Items (${_result!.matchedCount}/${_result!.items.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Item list
            ..._result!.items.map(_buildItemRow),

            // Add all button
            if (hasAddableItems) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addAllToCart,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add All to Cart / அனைத்தும் சேர்'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VillageTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            // Voice: add more items
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _isProcessing ? null : _startVoiceOrder,
                icon: const Icon(Icons.mic, size: 18),
                label: const Text('Add more items / மேலும் சேர்'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(ParsedItem item) {
    final hasMatches = item.matches.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item name with status icon
          Row(
            children: [
              Icon(
                hasMatches
                    ? (item.isAdded ? Icons.check_circle : Icons.search)
                    : Icons.cancel,
                size: 18,
                color: hasMatches
                    ? (item.isAdded
                        ? VillageTheme.primaryGreen
                        : VillageTheme.skyBlue)
                    : VillageTheme.errorRed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: hasMatches
                        ? VillageTheme.primaryText
                        : VillageTheme.errorRed,
                    decoration:
                        item.isAdded ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (item.isAdded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: VillageTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Added',
                      style: TextStyle(
                          color: VillageTheme.primaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),

          // Product matches
          if (hasMatches && !item.isAdded)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 4),
              child: Column(
                children: item.matches
                    .take(3)
                    .map((product) => _buildProductMatch(item, product))
                    .toList(),
              ),
            ),

          if (!hasMatches)
            const Padding(
              padding: EdgeInsets.only(left: 26, top: 2),
              child: Text(
                'No match found / கிடைக்கவில்லை',
                style: TextStyle(
                    color: VillageTheme.errorRed, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductMatch(ParsedItem item, Map<String, dynamic> product) {
    final name = product['name'] ?? '';
    final nameTamil = product['nameTamil'] ?? '';
    final price = product['price']?.toString() ?? '0';
    final imageUrl = product['image']?.toString() ?? '';

    return InkWell(
      onTap: () => _addSingleToCart(item, product),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ImageUrlHelper.getFullImageUrl(imageUrl),
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 36,
                        height: 36,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 16, color: Colors.grey),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 36,
                        height: 36,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 16, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 36,
                      height: 36,
                      color: Colors.grey[200],
                      child: const Icon(Icons.shopping_bag,
                          size: 16, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameTamil.isNotEmpty ? '$name ($nameTamil)' : name,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '₹$price',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: VillageTheme.primaryGreen,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: VillageTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add,
                  size: 16, color: VillageTheme.primaryGreen),
            ),
          ],
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
          // 3 mode buttons
          Row(
            children: [
              // Voice button
              _buildModeButton(
                icon: _isListening ? Icons.mic : Icons.mic_none,
                label: 'Voice',
                tamilLabel: 'குரல்',
                color: VillageTheme.primaryGreen,
                onTap: _isProcessing ? null : _startVoiceOrder,
                isActive: _isListening,
              ),
              const SizedBox(width: 8),
              // Photo button
              _buildModeButton(
                icon: Icons.camera_alt,
                label: 'Photo',
                tamilLabel: 'படம்',
                color: VillageTheme.skyBlue,
                onTap: _isProcessing ? null : _startPhotoOrder,
              ),
              const SizedBox(width: 8),
              // Text input
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: VillageTheme.inputBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Type here / இங்கே எழுதுங்கள்',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16),
                          ),
                          style: const TextStyle(fontSize: 14),
                          onSubmitted: (_) => _submitTextOrder(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send,
                            color: VillageTheme.primaryGreen),
                        onPressed: _isProcessing ? null : _submitTextOrder,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required String tamilLabel,
    required Color color,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : color.withOpacity(0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isActive ? Colors.white : color),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isBot;

  _ChatMessage({required this.text, required this.isBot});
}
