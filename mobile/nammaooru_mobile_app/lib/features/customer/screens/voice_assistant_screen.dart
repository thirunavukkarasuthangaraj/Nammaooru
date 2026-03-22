import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/models/cart_model.dart';
import '../../../shared/models/product_model.dart';
import '../../../services/voice_assistant_service.dart';
import '../orders/checkout_screen.dart';

class VoiceAssistantScreen extends StatefulWidget {
  final int? shopId;
  final String? shopName;

  const VoiceAssistantScreen({super.key, this.shopId, this.shopName});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  final VoiceAssistantService _service = VoiceAssistantService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _service.shopId = widget.shopId;
    _service.shopName = widget.shopName;

    // Connect service callbacks
    _service.onStateChanged = () {
      if (mounted) setState(() {});
    };
    _service.onMessage = (_) {
      if (mounted) {
        setState(() {});
        _scrollToBottom();
      }
    };

    // Connect cart callbacks and start session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectCart();
      _service.startSession().then((_) {
        // Start auto-listen after greeting finishes
        if (mounted) _scheduleAutoListen();
      });
    });
  }

  void _connectCart() {
    final cart = context.read<CartProvider>();

    _service.onAddToCart = (product, {int quantity = 1}) async {
      try {
        final now = DateTime.now();
        final productModel = ProductModel(
          id: product['id']?.toString() ?? '0',
          name: product['name']?.toString() ?? '',
          nameTamil: product['nameTamil']?.toString(),
          description: '',
          price: double.tryParse(product['price']?.toString() ?? '0') ?? 0,
          category: product['category']?.toString() ?? '',
          shopId: product['shopId']?.toString() ?? '',
          shopDatabaseId: product['shopDatabaseId'] as int? ?? widget.shopId,
          shopName: product['shopName']?.toString() ?? widget.shopName ?? '',
          images: product['image']?.toString().isNotEmpty == true
              ? [product['image'].toString()]
              : [],
          stockQuantity: product['stockQuantity'] as int? ?? 999,
          unit: product['baseUnit']?.toString() ?? 'piece',
          createdAt: now,
          updatedAt: now,
        );
        // If cart has items from a different shop, clear it first
        // (voice assistant is for a specific shop — stale cart from another shop)
        if (!cart.isFromSameShop(productModel)) {
          debugPrint('Voice agent: cart has different shop, clearing');
          cart.clearCart();
        }

        final result = await cart.addToCart(productModel, quantity: quantity);
        return result;
      } catch (e) {
        debugPrint('Cart add error: $e');
        return false;
      }
    };

    _service.onRemoveFromCart = (productName) {
      try {
        final lower = productName.toLowerCase();
        final items = cart.items;
        for (final item in items) {
          if ((item.product.name.toLowerCase()).contains(lower)) {
            cart.removeFromCart(item.product.id);
            return true;
          }
        }
        return false;
      } catch (e) {
        return false;
      }
    };

    _service.onGetCartTotal = () => cart.subtotal;
    _service.onGetCartCount = () => cart.itemCount;
    _service.onGetCartItems = () => cart.items.map((item) => <String, dynamic>{
      'name': item.product.name,
      'quantity': item.quantity,
      'price': item.product.price,
    }).toList();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    _service.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Mic interaction ──

  Future<void> _onMicTap() async {
    HapticFeedback.mediumImpact();

    if (_isRecording) {
      // Stop recording → process
      _stopRecordingUI();
      await _service.stopAndProcess();
      // Auto-listen after processing
      _scheduleAutoListen();
    } else {
      // Start recording
      final started = await _service.startManualRecording();
      if (started && mounted) {
        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
        });
        _pulseController.repeat(reverse: true);
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (mounted) setState(() => _recordingSeconds++);
        });
      }
    }
  }

  void _stopRecordingUI() {
    _recordingTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    if (mounted) setState(() => _isRecording = false);
  }

  void _scheduleAutoListen() {
    if (_service.isStopped || _service.isAutoListenExhausted) return;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _service.isStopped) return;
      if (_service.state == AgentState.listening && !_service.isAutoListenExhausted) {
        _service.autoListenAndProcess().then((_) {
          if (mounted && !_service.isStopped && !_service.isAutoListenExhausted) {
            _scheduleAutoListen();
          }
        });
      }
    });
  }

  // ── Text input ──

  void _onSendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _textFocusNode.unfocus();
    _service.processTextInput(text).then((_) => _scheduleAutoListen());
  }

  // ── Product card tap ──

  void _onProductTap(Map<String, dynamic> product) {
    _stopRecordingUI();
    _service.tapProduct(product).then((_) => _scheduleAutoListen());
  }

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCartTotalBar(),
          Expanded(child: _buildMessageList()),
          _buildStatusBar(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final cartCount = context.watch<CartProvider>().itemCount;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Shopping Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          if (widget.shopName != null)
            Text(widget.shopName!, style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
      backgroundColor: VillageTheme.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (cartCount > 0)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => _showCartSheet(),
              ),
              Positioned(
                right: 6, top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text('$cartCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _service.stopSession();
            context.pop();
          },
        ),
      ],
    );
  }

  // ── Cart Bottom Sheet ──

  void _showCartSheet() async {
    // Pause voice session while cart is open
    await _service.pause();
    _stopRecordingUI();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CartBottomSheet(
        onCheckout: () {
          Navigator.pop(ctx); // close sheet
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
          );
        },
      ),
    );

    // Resume voice after sheet is closed
    if (mounted && !_service.isStopped) {
      await _service.resumeSession();
      _scheduleAutoListen();
    }
  }

  // ── Cart Total Bar ──

  Widget _buildCartTotalBar() {
    final cart = context.watch<CartProvider>();
    final count = cart.itemCount;
    final total = cart.subtotal;
    if (count == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showCartSheet(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: VillageTheme.primaryGreen,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$count item${count > 1 ? 's' : ''}',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('Total: ₹${total.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Message List ──

  Widget _buildMessageList() {
    if (_service.messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Starting assistant...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _service.messages.length,
      itemBuilder: (context, i) => _buildMessage(_service.messages[i]),
    );
  }

  Widget _buildMessage(AgentMessage msg) {
    if (msg.isBot) return _buildBotMessage(msg);
    return _buildUserMessage(msg);
  }

  Widget _buildUserMessage(AgentMessage msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: VillageTheme.primaryGreen,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: const Radius.circular(4),
          ),
        ),
        child: Text(msg.text,
          style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
    );
  }

  Widget _buildBotMessage(AgentMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, right: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg.text, style: const TextStyle(fontSize: 15, height: 1.4)),
                if (msg.subText != null) ...[
                  const SizedBox(height: 4),
                  Text(msg.subText!, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),

          // Added product confirmation
          if (msg.addedProduct != null) ...[
            const SizedBox(height: 6),
            _buildAddedCard(msg.addedProduct!),
          ],

          // Product option cards
          if (msg.products != null && msg.products!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildProductCards(msg.products!),
          ],
        ],
      ),
    );
  }

  // ── Product Cards (horizontal scroll) ──

  Widget _buildProductCards(List<Map<String, dynamic>> products) {
    return Column(
      children: products.asMap().entries.map((e) => _buildProductCard(e.value, e.key)).toList(),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final name = product['name']?.toString() ?? '';
    final nameTamil = product['nameTamil']?.toString() ?? '';
    final price = product['price']?.toString() ?? '0';
    final weight = product['weightDisplay']?.toString() ?? '';
    final image = product['image']?.toString() ?? '';
    final productId = product['id']?.toString() ?? '';

    final cart = context.watch<CartProvider>();
    final cartItem = cart.items.where((i) => i.product.id == productId).firstOrNull;
    final inCartQty = cartItem?.quantity ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: inCartQty > 0
              ? VillageTheme.primaryGreen.withOpacity(0.6)
              : VillageTheme.primaryGreen.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 3, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          // Number badge + Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 52, height: 52,
                  child: image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ImageUrlHelper.getFullImageUrl(image),
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Colors.grey[100]),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[100],
                            child: Icon(Icons.shopping_bag, color: Colors.grey[400], size: 24),
                          ),
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: Icon(Icons.shopping_bag, color: Colors.grey[400], size: 24),
                        ),
                ),
              ),
              Positioned(
                top: 0, left: 0,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: VillageTheme.primaryGreen,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text('${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (nameTamil.isNotEmpty)
                  Text(
                    nameTamil,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                if (weight.isNotEmpty)
                  Text(weight,
                    style: TextStyle(fontSize: 11, color: Colors.orange[700], fontWeight: FontWeight.w500)),
                Text('₹$price',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: VillageTheme.primaryGreen)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Quantity controls or Add button
          if (inCartQty > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildQtyBtn(
                  icon: Icons.remove,
                  onTap: () {
                    final c = context.read<CartProvider>();
                    if (inCartQty <= 1) {
                      c.removeFromCart(productId);
                    } else {
                      c.updateQuantity(productId, inCartQty - 1);
                    }
                    if (mounted) setState(() {});
                  },
                ),
                Container(
                  width: 28,
                  alignment: Alignment.center,
                  child: Text('$inCartQty',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                        color: VillageTheme.primaryGreen)),
                ),
                _buildQtyBtn(
                  icon: Icons.add,
                  onTap: () {
                    final c = context.read<CartProvider>();
                    c.updateQuantity(productId, inCartQty + 1);
                    if (mounted) setState(() {});
                  },
                ),
              ],
            )
          else
            GestureDetector(
              onTap: () => _onProductTap(product),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: VillageTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: VillageTheme.primaryGreen,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildAddedCard(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? '';
    final price = product['price']?.toString() ?? '0';
    final weight = product['weightDisplay']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${weight.isNotEmpty ? "$name $weight" : name} - ₹$price',
              style: TextStyle(fontSize: 13, color: Colors.green[800], fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Bar (listening/processing/speaking indicator) ──

  Widget _buildStatusBar() {
    final state = _service.state;
    if (state == AgentState.idle) return const SizedBox.shrink();

    String label;
    IconData icon;
    Color color;

    switch (state) {
      case AgentState.listening:
        label = _isRecording ? 'Recording... ${_recordingSeconds}s' : 'Listening...';
        icon = Icons.mic;
        color = _isRecording ? Colors.red : Colors.orange;
      case AgentState.processing:
        label = 'Thinking...';
        icon = Icons.psychology;
        color = Colors.blue;
      case AgentState.speaking:
        label = 'Speaking...';
        icon = Icons.volume_up;
        color = VillageTheme.primaryGreen;
      case AgentState.idle:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: color.withOpacity(0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state == AgentState.processing)
            SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color))
          else
            Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Bottom Bar (text input + mic button) ──

  Widget _buildBottomBar() {
    final isActive = _service.state != AgentState.idle;

    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 8, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          // Text input
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _textFocusNode,
              enabled: isActive,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _onSendText(),
              decoration: InputDecoration(
                hintText: 'Type product name...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 6),

          // Send text button (visible when text field has content)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _textController,
            builder: (context, value, _) {
              if (value.text.trim().isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(Icons.send, color: VillageTheme.primaryGreen),
                onPressed: _onSendText,
              );
            },
          ),

          // Mic button
          _buildMicButton(isActive),
        ],
      ),
    );
  }

  Widget _buildMicButton(bool isActive) {
    return GestureDetector(
      onTap: isActive ? _onMicTap : null,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final scale = _isRecording ? 1.0 + _pulseController.value * 0.2 : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording
                    ? Colors.red
                    : isActive
                        ? VillageTheme.primaryGreen
                        : Colors.grey[300],
                boxShadow: _isRecording
                    ? [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)]
                    : null,
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 26,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Cart Bottom Sheet
// ═══════════════════════════════════════════════════════

class _CartBottomSheet extends StatelessWidget {
  final VoidCallback onCheckout;
  const _CartBottomSheet({required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle + header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                decoration: BoxDecoration(
                  color: VillageTheme.primaryGreen,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text('Cart',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Cart items
              Expanded(
                child: Consumer<CartProvider>(
                  builder: (context, cart, _) {
                    if (cart.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Cart is empty', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (_, i) => _CartSheetItem(item: cart.items[i], cart: cart),
                    );
                  },
                ),
              ),
              // Bottom: total + checkout
              Consumer<CartProvider>(
                builder: (context, cart, _) {
                  if (cart.isEmpty) return const SizedBox.shrink();
                  return Container(
                    padding: EdgeInsets.only(
                      left: 16, right: 16, top: 12,
                      bottom: MediaQuery.of(context).padding.bottom + 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${cart.itemCount} items',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text('₹${cart.subtotal.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                                  color: VillageTheme.primaryGreen)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onCheckout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VillageTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Proceed to Checkout',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CartSheetItem extends StatelessWidget {
  final CartItem item;
  final CartProvider cart;
  const _CartSheetItem({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    final image = item.product.images.isNotEmpty ? item.product.images.first : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56, height: 56,
              child: image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ImageUrlHelper.getFullImageUrl(image),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: Colors.grey[100],
                          child: Icon(Icons.shopping_bag, color: Colors.grey[400])),
                    )
                  : Container(color: Colors.grey[100],
                      child: Icon(Icons.shopping_bag, color: Colors.grey[400])),
            ),
          ),
          const SizedBox(width: 12),
          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('₹${Helpers.formatCurrency(item.product.effectivePrice)}',
                  style: TextStyle(fontSize: 13, color: VillageTheme.primaryGreen,
                      fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Qty controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qtyBtn(
                icon: item.quantity <= 1 ? Icons.delete_outline : Icons.remove,
                color: item.quantity <= 1 ? Colors.red[400]! : VillageTheme.primaryGreen,
                onTap: () => item.quantity <= 1
                    ? cart.removeFromCart(item.product.id)
                    : cart.decreaseQuantity(item.product.id),
              ),
              Container(
                width: 32,
                alignment: Alignment.center,
                child: Text('${item.quantity}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              _qtyBtn(
                icon: Icons.add,
                color: VillageTheme.primaryGreen,
                onTap: () => cart.increaseQuantity(item.product.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
