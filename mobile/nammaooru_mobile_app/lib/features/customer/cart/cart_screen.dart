import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/common_buttons.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/models/cart_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../services/shop_api_service.dart';
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
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (!didPop) {
              // Handle device back button - go to dashboard
              context.go('/customer/dashboard');
            }
          },
          child: Scaffold(
            backgroundColor: VillageTheme.lightBackground,
            appBar: CustomAppBar(
              title: context.loc?.translate('shopping_cart') ?? 'Shopping Cart',
              backgroundColor: VillageTheme.primaryGreen,
              foregroundColor: Colors.white,
              onBackPressed: () {
                // When coming from dashboard (bottom nav), go back to dashboard
                context.go('/customer/dashboard');
              },
            ),
            body: cartProvider.isEmpty
                ? _buildEmptyCart()
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildItemsList(cartProvider),
                              const SizedBox(height: 12),
                              // Promo code section removed
                              // _buildPromoCodeSection(cartProvider),
                              // const SizedBox(height: 12),
                              _buildOrderSummary(cartProvider),
                            ],
                          ),
                        ),
                      ),
                      _buildBottomBar(cartProvider),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            context.loc?.translate('cart_empty') ?? 'Your cart is empty',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            context.loc?.translate('add_products_to_start') ?? 'Add some products to get started',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(CartProvider cartProvider) {
    final itemsByShop = cartProvider.getItemsByShop();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: itemsByShop.entries.map((entry) {
        final shopId = entry.key;
        final items = entry.value;
        final shopName = items.first.product.shopName;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
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
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shopName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: VillageTheme.primaryGreen,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      Helpers.formatCurrency(cartProvider.getShopSubtotal(shopId)),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: VillageTheme.primaryGreen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.product.images.isNotEmpty
                  ? ImageUrlHelper.getFullImageUrl(item.product.images.first)
                  : 'https://via.placeholder.com/85x85',
              width: 85,
              height: 85,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 85,
                height: 85,
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 30),
              ),
              errorWidget: (context, url, error) => Container(
                width: 85,
                height: 85,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                final isTamil = languageProvider.currentLanguage == 'ta';
                final hasTamilName = item.product.nameTamil != null && item.product.nameTamil!.isNotEmpty;
                // Show ONLY the selected language name
                final displayName = isTamil && hasTamilName ? item.product.nameTamil! : item.product.name;

                return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.product.unit.isNotEmpty && item.product.unit != 'piece') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade200, width: 0.5),
                        ),
                        child: Text(
                          item.product.unit,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      Helpers.formatCurrency(item.product.effectivePrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: VillageTheme.primaryGreen,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.product.hasDiscount) ...[
                      const SizedBox(width: 6),
                      Text(
                        Helpers.formatCurrency(item.product.price),
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.black54,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              cartProvider.decreaseQuantity(item.product.id);
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(7),
                                  bottomLeft: Radius.circular(7),
                                ),
                              ),
                              child: const Icon(
                                Icons.remove,
                                size: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 28,
                            alignment: Alignment.center,
                            child: Text(
                              item.quantity.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: item.quantity < item.product.stockQuantity
                                ? () {
                                    cartProvider.increaseQuantity(item.product.id);
                                  }
                                : null,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: item.quantity < item.product.stockQuantity
                                    ? VillageTheme.primaryGreen
                                    : Colors.grey.shade200,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(7),
                                  bottomRight: Radius.circular(7),
                                ),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 14,
                                color: item.quantity < item.product.stockQuantity
                                    ? Colors.white
                                    : Colors.black26,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _showRemoveDialog(item, cartProvider);
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                if (item.quantity > item.product.stockQuantity)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Only ${item.product.stockQuantity} available',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection(CartProvider cartProvider) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Promo Code',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            if (cartProvider.appliedPromoCode != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Promo "${cartProvider.appliedPromoCode}" applied',
                        style: const TextStyle(color: Colors.green, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        cartProvider.removePromoCode();
                        _promoController.clear();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Remove', style: TextStyle(fontSize: 11)),
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
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Enter promo code',
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.local_offer, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isApplyingPromo ? null : _applyPromoCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VillageTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isApplyingPromo
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Apply', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.loc?.translate('order_summary') ?? 'Order Summary',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            _buildSummaryRow(
              '${context.loc?.translate('subtotal') ?? 'Subtotal'} (${cartProvider.itemCount} ${context.loc?.translate('items') ?? 'items'})',
              Helpers.formatCurrency(cartProvider.subtotal),
            ),

            _buildSummaryRow(
              context.loc?.translate('delivery_fee') ?? 'Delivery Fee',
              cartProvider.deliveryFee > 0
                  ? Helpers.formatCurrency(cartProvider.deliveryFee)
                  : context.loc?.translate('free') ?? 'FREE',
              valueColor: cartProvider.deliveryFee > 0 ? null : Colors.green,
            ),

            _buildSummaryRow(
              context.loc?.translate('tax') ?? 'Tax',
              Helpers.formatCurrency(cartProvider.taxAmount),
            ),

            // Promo discount removed
            // if (cartProvider.promoDiscount > 0)
            //   _buildSummaryRow(
            //     'Promo Discount',
            //     '-${Helpers.formatCurrency(cartProvider.promoDiscount)}',
            //     valueColor: Colors.green,
            //   ),

            const Divider(thickness: 1, height: 16),

            _buildSummaryRow(
              context.loc?.translate('total') ?? 'Total',
              Helpers.formatCurrency(cartProvider.total),
              isTotal: true,
            ),

            // Minimum order warning
            if (cartProvider.subtotal < 100)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Add ₹${(100 - cartProvider.subtotal).toStringAsFixed(2)} more to meet minimum order of ₹100',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            if (cartProvider.deliveryFee > 0 && cartProvider.amountForFreeDelivery > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Add ₹${cartProvider.amountForFreeDelivery.toStringAsFixed(0)} more for free delivery',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 13 : 11,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 14 : 11,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? (isTotal ? AppColors.primary : Colors.black87),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CartProvider cartProvider) {
    final canCheckout = cartProvider.canCheckout();
    final issues = cartProvider.getCheckoutIssues();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
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
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.loc?.translate('unable_to_checkout') ?? 'Unable to checkout:',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ...issues.map((issue) => Text(
                          '• $issue',
                          style: const TextStyle(color: Colors.red, fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )).toList(),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.loc?.translate('total_amount') ?? 'Total Amount',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        Helpers.formatCurrency(cartProvider.total),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: VillageTheme.primaryGreen,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: canCheckout ? _proceedToCheckout : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VillageTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.loc?.translate('proceed_to_checkout') ?? 'Proceed to Checkout',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Remove Item', style: TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        content: Text(
          'Remove ${item.product.name} from cart?',
          style: const TextStyle(fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () {
              cartProvider.removeFromCart(item.product.id);
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _applyPromoCode() async {
    if (_promoController.text.trim().isEmpty) return;

    // Check if user is logged in
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Please login to apply promo codes'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Login'),
            ),
          ],
        ),
      );

      if (shouldLogin == true) {
        // Navigate to login and return to cart after login
        final loggedIn = await context.push('/login');
        if (loggedIn == true) {
          // User logged in successfully, try applying promo code again
          _applyPromoCode();
        }
      }
      return;
    }

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

  Future<void> _proceedToCheckout() async {
    // Check if user is logged in
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      // Show login dialog
      final shouldLogin = await _showLoginPrompt();
      if (shouldLogin != true) return;

      // Navigate to login screen
      if (mounted) {
        context.go('/login');
      }
      return;
    }

    // Check if shop is open before proceeding
    if (cartProvider.items.isNotEmpty) {
      final shopDatabaseId = cartProvider.items.first.product.shopDatabaseId;
      if (shopDatabaseId != null) {
        try {
          final shopDetails = await ShopApiService().getShopById(
            shopDatabaseId is int ? shopDatabaseId : int.parse(shopDatabaseId.toString())
          );
          final isShopOpen = shopDetails['data']?['isOpenNow'] ?? shopDetails['data']?['isActive'] ?? false;

          if (!isShopOpen && mounted) {
            final shopName = shopDetails['data']?['name'] ?? 'The shop';
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Row(
                  children: [
                    Icon(Icons.store_outlined, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Text(
                      context.loc?.translate('shop_closed') ?? 'Shop Closed',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                content: Text(
                  '$shopName is currently closed and not accepting orders. Please try again during business hours.',
                  style: const TextStyle(fontSize: 13),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VillageTheme.primaryGreen,
                    ),
                    child: const Text('OK', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            return;
          }
        } catch (e) {
          debugPrint('⚠️ Could not verify shop status: $e');
          // Continue if we can't verify - backend will validate
        }
      }
    }

    // User is logged in and shop is open, proceed to checkout
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CheckoutScreen(),
      ),
    );
  }

  Future<bool?> _showLoginPrompt() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.login, color: VillageTheme.primaryGreen, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Login Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You need to login or create an account to place an order.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VillageTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: VillageTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: VillageTheme.primaryGreen, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Your cart items will be saved',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: VillageTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Login / Sign Up', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
