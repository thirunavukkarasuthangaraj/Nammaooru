import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/common_buttons.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/models/cart_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/helpers.dart';
import '../orders/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _isApplyingPromo = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Shopping Cart',
        backgroundColor: VillageTheme.primaryGreen,
        foregroundColor: Colors.white,
        showBackButton: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildItemsList(cartProvider),
                      const SizedBox(height: 20),
                      _buildPromoCodeSection(cartProvider),
                      const SizedBox(height: 20),
                      _buildOrderSummary(cartProvider),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return const Center(
      child: EmptyStateWidget(
        title: 'Your cart is empty',
        message: 'Add some products to get started',
        icon: Icons.shopping_cart_outlined,
        action: null,
      ),
    );
  }

  Widget _buildItemsList(CartProvider cartProvider) {
    final itemsByShop = cartProvider.getItemsByShop();

    return Column(
      children: itemsByShop.entries.map((entry) {
        final shopId = entry.key;
        final items = entry.value;
        final shopName = items.first.product.shopName;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.store,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shopName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: VillageTheme.primaryGreen,
                        ),
                      ),
                    ),
                    Text(
                      Helpers.formatCurrency(cartProvider.getShopSubtotal(shopId)),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: VillageTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              ...items.map((item) => _buildCartItem(item, cartProvider)).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Builder(
              builder: (context) {
                String imageUrl;
                if (item.product.images.isNotEmpty) {
                  final rawUrl = item.product.images.first;
                  imageUrl = rawUrl.startsWith('http') 
                      ? rawUrl 
                      : 'http://localhost:8082$rawUrl';
                  print('Cart Product: ${item.product.name}, Image URL: $rawUrl -> $imageUrl');
                } else {
                  imageUrl = 'https://via.placeholder.com/80x80';
                }
                
                return Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      Helpers.formatCurrency(item.product.effectivePrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: VillageTheme.primaryGreen,
                        fontSize: 16,
                      ),
                    ),
                    if (item.product.hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text(
                        Helpers.formatCurrency(item.product.price),
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              cartProvider.decreaseQuantity(item.product.id);
                            },
                            icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.quantity.toString(),
                              style: const TextStyle(
                                color: const Color(0xFF4CAF50),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: item.quantity < item.product.stockQuantity
                                ? () {
                                    cartProvider.increaseQuantity(item.product.id);
                                  }
                                : null,
                            icon: Icon(
                              Icons.add, 
                              color: item.quantity < item.product.stockQuantity ? Colors.white : Colors.grey, 
                              size: 18
                            ),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        _showRemoveDialog(item, cartProvider);
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                if (item.quantity > item.product.stockQuantity)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Only ${item.product.stockQuantity} available',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Promo Code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          if (cartProvider.appliedPromoCode != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Promo code "${cartProvider.appliedPromoCode}" applied',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      cartProvider.removePromoCode();
                      _promoController.clear();
                    },
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: const InputDecoration(
                      hintText: 'Enter promo code',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isApplyingPromo ? null : _applyPromoCode,
                  child: _isApplyingPromo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Apply'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSummaryRow(
            'Subtotal (${cartProvider.itemCount} items)',
            Helpers.formatCurrency(cartProvider.subtotal),
          ),
          
          _buildSummaryRow(
            'Delivery Fee',
            cartProvider.deliveryFee > 0 
                ? Helpers.formatCurrency(cartProvider.deliveryFee)
                : 'FREE',
            valueColor: cartProvider.deliveryFee > 0 ? null : Colors.green,
          ),
          
          _buildSummaryRow(
            'Tax',
            Helpers.formatCurrency(cartProvider.taxAmount),
          ),
          
          if (cartProvider.promoDiscount > 0)
            _buildSummaryRow(
              'Promo Discount',
              '-${Helpers.formatCurrency(cartProvider.promoDiscount)}',
              valueColor: Colors.green,
            ),
          
          const Divider(thickness: 1),
          
          _buildSummaryRow(
            'Total',
            Helpers.formatCurrency(cartProvider.total),
            isTotal: true,
          ),
          
          if (cartProvider.deliveryFee > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Add ₹${(500 - cartProvider.subtotal).toStringAsFixed(0)} more for free delivery',
                style: const TextStyle(
                  color: const Color(0xFF4CAF50),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? (isTotal ? AppColors.primary : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CartProvider cartProvider) {
    final canCheckout = cartProvider.canCheckout();
    final issues = cartProvider.getCheckoutIssues();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!canCheckout && issues.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unable to checkout:',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ...issues.map((issue) => Text(
                          '• $issue',
                          style: const TextStyle(color: Colors.red),
                        )).toList(),
                  ],
                ),
              ),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        Helpers.formatCurrency(cartProvider.total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: VillageTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    text: 'Proceed to Checkout',
                    onPressed: canCheckout ? _proceedToCheckout : null,
                    icon: Icons.shopping_cart_checkout,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(CartItem item, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove ${item.product.name} from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cartProvider.removeFromCart(item.product.id);
              Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyPromoCode() async {
    if (_promoController.text.trim().isEmpty) return;

    setState(() => _isApplyingPromo = true);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final success = await cartProvider.applyPromoCode(_promoController.text.trim());

    setState(() => _isApplyingPromo = false);

    if (success) {
      Helpers.showSnackBar(context, 'Promo code applied successfully!');
    } else {
      Helpers.showSnackBar(context, 'Invalid promo code', isError: true);
    }
  }

  void _proceedToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CheckoutScreen(),
      ),
    );
  }
}