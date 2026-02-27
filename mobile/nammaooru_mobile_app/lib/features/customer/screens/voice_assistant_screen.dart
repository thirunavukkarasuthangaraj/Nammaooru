import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/models/product_model.dart';
import '../../../services/voice_assistant_service.dart';
import '../../../services/smart_order_service.dart';
import '../../../core/localization/language_provider.dart';

class VoiceAssistantScreen extends StatefulWidget {
  final int? shopId;
  final String? shopName;

  const VoiceAssistantScreen({super.key, this.shopId, this.shopName});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  final VoiceAssistantService _service = VoiceAssistantService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _service.shopId = widget.shopId;
    _service.shopName = widget.shopName;
    _service.onStateChanged = _onStateChanged;
    _service.onMessage = (_) => _onStateChanged();
    _service.onAddToCart = _onAddToCart;
    _service.onGetCartTotal = () {
      final cart = Provider.of<CartProvider>(context, listen: false);
      return cart.total;
    };
    _service.onGetCartCount = () {
      final cart = Provider.of<CartProvider>(context, listen: false);
      return cart.itemCount;
    };
    _service.onRemoveFromCart = (String productName) {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final lowerName = productName.toLowerCase();
      // Find matching item by name (fuzzy)
      final match = cart.items.where((item) {
        final name = item.product.name.toLowerCase();
        final nameTamil = (item.product.nameTamil ?? '').toLowerCase();
        return name.contains(lowerName) || lowerName.contains(name) ||
               nameTamil.contains(lowerName) || lowerName.contains(nameTamil);
      }).toList();
      if (match.isNotEmpty) {
        cart.removeFromCart(match.first.product.id);
        if (mounted) setState(() {});
        return true;
      }
      return false;
    };
    _service.onGetCartItems = () {
      final cart = Provider.of<CartProvider>(context, listen: false);
      return cart.items.map((item) => <String, dynamic>{
          'id': item.product.id,
          'name': item.product.name,
          'nameTamil': item.product.nameTamil ?? '',
          'price': item.product.price,
          'quantity': item.quantity,
      }).toList();
    };

    // Start the conversation immediately
    Future.microtask(() => _service.startSession());
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
      // Stop recording if session ended
      if (_service.state == AssistantState.idle || _service.isStopped) {
        if (_isRecording) {
          _recordingTimer?.cancel();
          _pulseController.stop();
          _isRecording = false;
          _recordingSeconds = 0;
        }
      }
      // Update recording state from service
      final nowRecording = _service.isRecordingManually;
      if (nowRecording && !_isRecording) {
        _isRecording = true;
        _pulseController.repeat(reverse: true);
      } else if (!nowRecording && _isRecording && _service.state != AssistantState.listening) {
        _isRecording = false;
        _pulseController.stop();
      }
      // Auto-listen: when state becomes listening/awaitingChoice, auto-start recording
      if (_service.state == AssistantState.listening ||
          _service.state == AssistantState.awaitingChoice) {
        if (!_service.isRecordingManually) {
          Future.microtask(() => _service.autoListenAndProcess());
        }
      }
      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void deactivate() {
    // Stop voice/TTS IMMEDIATELY when navigating away
    _service.stopSession();
    super.deactivate();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _service.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  /// Called by service when user confirms "yes, add"
  Future<bool> _onAddToCart(Map<String, dynamic> product, {int quantity = 1}) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final productModel = _toProductModel(product);
    final success = await cart.addToCart(productModel, quantity: quantity);
    if (success && mounted) {
      setState(() {});
    } else if (!success && mounted) {
      // Out of stock or failed — force refresh product cache NOW
      await _service.refreshProducts();
      setState(() {});
    }
    return success;
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

  // Track quantity per product card: key = "itemHash_matchIndex"
  final Map<String, int> _quantities = {};

  String _qtyKey(ParsedItem item, int matchIdx) =>
      '${item.hashCode}_$matchIdx';

  int _getQty(ParsedItem item, int matchIdx) =>
      _quantities[_qtyKey(item, matchIdx)] ?? 1;

  void _setQty(ParsedItem item, int matchIdx, int qty) {
    setState(() {
      _quantities[_qtyKey(item, matchIdx)] = qty.clamp(1, 99);
    });
  }

  Future<void> _addToCart(ParsedItem item, Map<String, dynamic> product, {int? matchIdx}) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final productModel = _toProductModel(product);
    final qty = matchIdx != null ? _getQty(item, matchIdx) : 1;
    final success = await cart.addToCart(productModel, quantity: qty);

    if (success && mounted) {
      setState(() {
        item.selectedMatch = product;
        item.isAdded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product['name']} x$qty added to cart'),
          backgroundColor: VillageTheme.primaryGreen,
          duration: const Duration(seconds: 1),
        ),
      );
    } else if (!success && mounted) {
      // Out of stock — refresh and notify
      await _service.refreshProducts();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product['name']} — Out of stock! / Stock இல்லை!'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _endSession() async {
    await _service.stopSession();
    if (mounted) {
      final cart = Provider.of<CartProvider>(context, listen: false);
      if (cart.itemCount > 0) {
        context.go('/customer/cart');
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  /// Show cart bottom sheet with qty controls
  void _showCartSheet() {
    // Pause assistant while viewing cart
    _service.pause();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final cart = Provider.of<CartProvider>(context, listen: false);
            final items = cart.items;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_cart, color: Color(0xFF6C63FF), size: 22),
                        const SizedBox(width: 8),
                        Text('Cart (${items.length} items)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('Total: Rs.${cart.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold,
                                color: VillageTheme.primaryGreen)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Cart items list
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Cart is empty / கார்ட் காலி',
                          style: TextStyle(color: Colors.grey, fontSize: 15)),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final cartItem = items[i];
                          final product = cartItem.product;
                          final imageUrl = product.images.isNotEmpty ? product.images.first : '';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                // Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: ImageUrlHelper.getFullImageUrl(imageUrl),
                                          width: 48, height: 48,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                            width: 48, height: 48,
                                            color: Colors.grey[100],
                                            child: const Icon(Icons.shopping_bag, size: 20, color: Colors.grey),
                                          ),
                                          errorWidget: (_, __, ___) => Container(
                                            width: 48, height: 48,
                                            color: Colors.grey[100],
                                            child: const Icon(Icons.shopping_bag, size: 20, color: Colors.grey),
                                          ),
                                        )
                                      : Container(
                                          width: 48, height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.shopping_bag, size: 20, color: Colors.grey),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                // Name + price
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(product.nameTamil?.isNotEmpty == true
                                              ? product.nameTamil! : product.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600, fontSize: 14),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text('Rs.${product.price.toStringAsFixed(0)} each',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    ],
                                  ),
                                ),
                                // Qty controls: - [qty] +
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _sheetQtyBtn(Icons.remove, () {
                                        cart.decreaseQuantity(product.id);
                                        setSheetState(() {});
                                        setState(() {});
                                      }),
                                      Container(
                                        width: 30,
                                        alignment: Alignment.center,
                                        child: Text('${cartItem.quantity}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 14)),
                                      ),
                                      _sheetQtyBtn(Icons.add, () {
                                        cart.increaseQuantity(product.id);
                                        setSheetState(() {});
                                        setState(() {});
                                      }),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Price total
                                Text('Rs.${cartItem.totalPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 14,
                                        color: VillageTheme.primaryGreen)),
                                // Delete
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                                  onPressed: () {
                                    cart.removeFromCart(product.id);
                                    setSheetState(() {});
                                    setState(() {});
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  // Checkout button
                  if (items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push('/customer/cart');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VillageTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Proceed to Checkout (Rs.${cart.total.toStringAsFixed(0)})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28, height: 28,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assistant, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.shopName != null
                    ? 'Talk & Order - ${widget.shopName}'
                    : 'Talk & Order / பேசி ஆர்டர் செய்',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => cart.itemCount > 0
                ? Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart),
                        onPressed: _showCartSheet,
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
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _service.messages.length +
                  (_service.state != AssistantState.idle ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _service.messages.length) {
                  return _buildMessage(_service.messages[index]);
                }
                // State indicator at the bottom
                return _buildStateIndicator();
              },
            ),
          ),

          // Bottom bar with state + end button
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildMessage(AssistantMessage msg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chat bubble
        _buildChatBubble(msg),
        // Numbered option cards (2-3 choices for user to pick)
        if (msg.isOptionsList && msg.optionProducts != null)
          _buildOptionCards(msg.optionProducts!),
        // Best match card (single product auto-added)
        if (msg.bestMatch != null)
          _buildProductSection(msg.bestMatch!),
        // Product list (not-found items)
        if (msg.products != null && msg.products!.isNotEmpty)
          ...msg.products!.map(_buildProductSection),
      ],
    );
  }

  /// Build numbered option cards (tappable during awaitingChoice)
  Widget _buildOptionCards(List<Map<String, dynamic>> options) {
    final isChoiceActive = _service.state == AssistantState.awaitingChoice ||
        _service.state == AssistantState.presentingOptions;

    return Column(
      children: options.asMap().entries.map((entry) {
        final idx = entry.key;
        final product = entry.value;
        final name = product['name'] ?? '';
        final nameTamil = product['nameTamil'] ?? '';
        final price = product['price']?.toString() ?? '0';
        final imageUrl = product['image']?.toString() ?? '';
        final weightDisplay = product['weightDisplay']?.toString() ?? '';

        final isTamil =
            Provider.of<LanguageProvider>(context, listen: false)
                    .currentLanguage ==
                'ta';
        final primaryName =
            isTamil && nameTamil.isNotEmpty ? nameTamil : name;
        final secondaryName =
            isTamil && nameTamil.isNotEmpty ? name : nameTamil;

        return GestureDetector(
          onTap: isChoiceActive
              ? () => _service.interruptWithChoice(idx)
              : null,
          child: Card(
            margin: const EdgeInsets.only(left: 40, bottom: 6, right: 4),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isChoiceActive
                  ? BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.4), width: 1)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // Number badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text('${idx + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                  const SizedBox(width: 10),
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ImageUrlHelper.getFullImageUrl(imageUrl),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _imagePlaceholder(size: 48),
                            errorWidget: (_, __, ___) => _imagePlaceholder(size: 48),
                          )
                        : _imagePlaceholder(size: 48),
                  ),
                  const SizedBox(width: 10),
                  // Name + price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(primaryName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (secondaryName.isNotEmpty)
                          Text(secondaryName,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        Row(
                          children: [
                            Text('Rs.$price',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: VillageTheme.primaryGreen,
                                  fontSize: 15,
                                )),
                            if (weightDisplay.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Text(weightDisplay,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade800)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Tap hint arrow
                  if (isChoiceActive)
                    Icon(Icons.touch_app, size: 20, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _imagePlaceholder({double size = 56}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(size == 56 ? 10 : 8),
      ),
      child: Icon(Icons.shopping_bag, size: size * 0.43, color: Colors.grey),
    );
  }

  Widget _buildChatBubble(AssistantMessage msg) {
    final isBot = msg.isBot;

    // Cart summary — special green banner
    if (msg.isCartUpdate) {
      return Container(
        margin: const EdgeInsets.only(left: 40, right: 4, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg.text,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      );
    }

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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8B7FFF)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.assistant, size: 18, color: Colors.white),
            ),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : const Color(0xFF6C63FF),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isBot ? 4 : 16),
                  bottomRight: Radius.circular(isBot ? 16 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isBot ? VillageTheme.primaryText : Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  // English subtitle for bot messages
                  if (isBot && msg.subText != null && msg.subText!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        msg.subText!,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!isBot) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildProductSection(ParsedItem item) {
    if (item.matches.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(left: 40, bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, size: 18, color: Colors.red.shade400),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '"${item.name}" — கிடைக்கவில்லை',
                style: TextStyle(fontSize: 13, color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      );
    }

    // If already added, show compact "Added" confirmation with View Cart
    if (item.isAdded) {
      final addedProduct = item.selectedMatch ?? item.matches.first;
      final addedName = addedProduct['nameTamil']?.toString().isNotEmpty == true
          ? addedProduct['nameTamil']
          : addedProduct['name'] ?? '';
      return Container(
        margin: const EdgeInsets.only(left: 40, bottom: 6, right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: VillageTheme.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: VillageTheme.primaryGreen.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: VillageTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('$addedName — Added',
                  style: const TextStyle(
                      color: VillageTheme.primaryGreen,
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            // View Cart shortcut
            GestureDetector(
              onTap: _showCartSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: VillageTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('View Cart', style: TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: item.matches.asMap().entries.map((entry) {
        final idx = entry.key;
        final product = entry.value;
        final isBest = idx == 0;
        final name = product['name'] ?? '';
        final nameTamil = product['nameTamil'] ?? '';
        final price = product['price']?.toString() ?? '0';
        final imageUrl = product['image']?.toString() ?? '';
        final weightDisplay = product['weightDisplay']?.toString() ?? '';
        final qty = _getQty(item, idx);

        final isTamil =
            Provider.of<LanguageProvider>(context, listen: false)
                    .currentLanguage ==
                'ta';
        final primaryName =
            isTamil && nameTamil.isNotEmpty ? nameTamil : name;
        final secondaryName =
            isTamil && nameTamil.isNotEmpty ? name : nameTamil;

        // Show "Low Price" badge on the first item (sorted by price, cheapest first)
        final isLowPrice = isBest && item.matches.length > 1;

        return Card(
          margin: const EdgeInsets.only(left: 40, bottom: 6, right: 4),
          elevation: isBest ? 2 : 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isBest
                ? const BorderSide(color: Color(0xFF6C63FF), width: 1.5)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: ImageUrlHelper.getFullImageUrl(imageUrl),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _imagePlaceholder(size: 56),
                              errorWidget: (_, __, ___) => _imagePlaceholder(size: 56),
                            )
                          : _imagePlaceholder(size: 56),
                    ),
                    const SizedBox(width: 10),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badges row: Low Price + Best Match
                          Row(
                            children: [
                              if (isLowPrice)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 2, right: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: VillageTheme.primaryGreen,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Low Price',
                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              if (isBest)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C63FF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Best Match',
                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          Text(primaryName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (secondaryName.isNotEmpty)
                            Text(secondaryName,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          // Price + weight/gram info
                          Row(
                            children: [
                              Text('Rs.$price',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: VillageTheme.primaryGreen,
                                    fontSize: 16,
                                  )),
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
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade800)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quantity selector + Add button row
                Row(
                  children: [
                    // Qty selector: - [qty] +
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _qtyButton(Icons.remove, () {
                            if (qty > 1) _setQty(item, idx, qty - 1);
                          }),
                          Container(
                            width: 36,
                            alignment: Alignment.center,
                            child: Text('$qty',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          _qtyButton(Icons.add, () {
                            _setQty(item, idx, qty + 1);
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // ADD button
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: () => _addToCart(item, product, matchIdx: idx),
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: Text('ADD${qty > 1 ? ' x$qty' : ''}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBest
                                ? const Color(0xFF6C63FF)
                                : Colors.grey[200],
                            foregroundColor: isBest ? Colors.white : Colors.black87,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: const Color(0xFF6C63FF)),
      ),
    );
  }

  // _imagePlaceholder is now defined above with optional size parameter

  Widget _buildStateIndicator() {
    final state = _service.state;

    // Auto-listening state — show animated mic
    if (_isRecording) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Column(
            children: [
              _buildAnimatedMic(color: const Color(0xFF6C63FF)),
              const SizedBox(height: 8),
              const Text('Listening... / கேட்கிறேன்...',
                  style: TextStyle(color: Color(0xFF6C63FF), fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Speak now / இப்போ பேசுங்க',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ),
      );
    }

    IconData icon;
    String label;
    Color color;

    switch (state) {
      case AssistantState.listening:
        // Auto-listening — preparing to record
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6C63FF).withOpacity(0.15),
                  ),
                  child: const Icon(Icons.mic, color: Color(0xFF6C63FF), size: 28),
                ),
                const SizedBox(height: 8),
                const Text('Preparing to listen... / தயாராகிறது...',
                    style: TextStyle(color: Color(0xFF6C63FF), fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('Or type below / அல்லது type செய்யுங்க',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
        );
      case AssistantState.awaitingChoice:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withOpacity(0.15),
                  ),
                  child: Icon(Icons.mic, color: Colors.orange[600], size: 28),
                ),
                const SizedBox(height: 8),
                Text('Say the number, or tap a card',
                    style: TextStyle(color: Colors.orange[700], fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('எண் சொல்லுங்க, அல்லது card தட்டுங்க',
                    style: TextStyle(color: Colors.orange[400], fontSize: 12)),
              ],
            ),
          ),
        );
      case AssistantState.presentingOptions:
        icon = Icons.volume_up;
        label = 'Reading options... / விருப்பங்கள்...';
        color = const Color(0xFFFF6B6B);
      case AssistantState.searching:
        icon = Icons.search;
        label = 'Searching... / தேடுகிறேன்...';
        color = VillageTheme.primaryGreen;
      case AssistantState.addingToCart:
        icon = Icons.add_shopping_cart;
        label = 'Adding to cart... / சேர்க்கிறேன்...';
        color = VillageTheme.primaryGreen;
      case AssistantState.greeting:
        icon = Icons.volume_up;
        label = 'Speaking... / பேசுகிறேன்...';
        color = const Color(0xFFFF6B6B);
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
              ),
              child: state == AssistantState.searching
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(color: color, fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMic({Color? color}) {
    final micColor = color ?? const Color(0xFF6C63FF);
    final gradientEnd = color != null
        ? color.withOpacity(0.8)
        : const Color(0xFF8B7FFF);
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final scale = 1.0 + 0.15 * _pulseController.value;
        final opacity = 0.3 + 0.4 * (1 - _pulseController.value);
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring
            Container(
              width: 80 * scale,
              height: 80 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: micColor.withOpacity(opacity * 0.3),
              ),
            ),
            // Middle ring
            Container(
              width: 64 * scale,
              height: 64 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: micColor.withOpacity(opacity * 0.5),
              ),
            ),
            // Inner mic circle
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [micColor, gradientEnd],
                ),
                boxShadow: [
                  BoxShadow(
                    color: micColor.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 28),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Stop recording if active — user chose to type instead
    if (_isRecording) {
      _recordingTimer?.cancel();
      _pulseController.stop();
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
      await _service.cancelRecording();
    }

    // Stop TTS if playing
    await _service.ttsService.stop();

    _textController.clear();
    _textFocusNode.unfocus();

    await _service.processTextInput(text);

    if (mounted) setState(() {});
  }

  Widget _buildBottomBar() {
    final state = _service.state;
    final isActive = state != AssistantState.idle;

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
      child: Row(
        children: [
          // Text input — always visible
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _textFocusNode,
              decoration: InputDecoration(
                hintText: _service.state == AssistantState.awaitingChoice
                    ? 'Type number (1, 2, 3) or product name...'
                    : 'Type product name... / பொருள் பெயர்',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitText(),
              onTap: () {
                // Stop TTS when user taps text field
                _service.ttsService.stop();
                // Stop recording if active — user chose to type
                if (_isRecording) {
                  _recordingTimer?.cancel();
                  _pulseController.stop();
                  setState(() {
                    _isRecording = false;
                    _recordingSeconds = 0;
                  });
                  _service.cancelRecording();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // Send button (text)
          Container(
            height: 40,
            width: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF6C63FF),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, size: 18, color: Colors.white),
              onPressed: _submitText,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 8),
          // End/Cart button
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: _endSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive
                    ? const Color(0xFFFF6B6B)
                    : VillageTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: Text(
                isActive ? 'End' : 'Cart',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
