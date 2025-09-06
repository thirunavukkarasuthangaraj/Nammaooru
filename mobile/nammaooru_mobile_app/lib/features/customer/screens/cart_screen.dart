import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../core/localization/app_localizations.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: VillageTheme.lightBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🛒 ',
              style: TextStyle(fontSize: 28),
            ),
            Text(
              loc?.cart ?? 'வண்டி / Cart',
              style: VillageTheme.headingMedium.copyWith(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: VillageTheme.primaryGreen,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white, size: VillageTheme.iconLarge),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.itemCount == 0) {
            return _buildEmptyCart(context);
          }
          return _buildCartWithItems(context, cart);
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VillageTheme.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: VillageTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(VillageTheme.cardRadius * 2),
              ),
              child: Center(
                child: Text(
                  '🛒',
                  style: TextStyle(fontSize: 80),
                ),
              ),
            ),
            SizedBox(height: VillageTheme.spacingL),
            Text(
              'வண்டி காலி உள்ளது\nCart is Empty',
              style: VillageTheme.headingMedium.copyWith(
                color: VillageTheme.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: VillageTheme.spacingM),
            Text(
              'பொருட்களை சேர்க்கவும்\nAdd some items to get started',
              style: VillageTheme.bodyMedium.copyWith(
                color: VillageTheme.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: VillageTheme.spacingXL),
            VillageWidgets.bigButton(
              text: 'கடைகளுக்கு செல்லுங்கள் / Go Shopping',
              icon: Icons.store,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartWithItems(BuildContext context, CartProvider cart) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: cart.cartItems.length,
            itemBuilder: (context, index) {
              final item = cart.cartItems[index];
              return _buildCartItem(context, item, cart);
            },
          ),
        ),
        _buildCartSummary(context, cart),
      ],
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, CartProvider cart) {
    return Container(
      margin: EdgeInsets.only(bottom: VillageTheme.spacingM),
      decoration: VillageTheme.elevatedCardDecoration,
      child: Padding(
        padding: EdgeInsets.all(VillageTheme.spacingM),
        child: Column(
          children: [
            Row(
              children: [
                // Large Product Image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(VillageTheme.cardRadius),
                    color: VillageTheme.surfaceColor,
                    boxShadow: VillageTheme.cardShadow,
                  ),
                  child: item.image.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(VillageTheme.cardRadius),
                          child: Image.network(
                            item.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text('📦', style: TextStyle(fontSize: 40)),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text('📦', style: TextStyle(fontSize: 40)),
                        ),
                ),
                SizedBox(width: VillageTheme.spacingM),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: VillageTheme.headingSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: VillageTheme.spacingXS),
                      Row(
                        children: [
                          Text('🏪 ', style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              item.shopName,
                              style: VillageTheme.bodySmall.copyWith(
                                color: VillageTheme.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: VillageTheme.spacingS),
                      Row(
                        children: [
                          Text('💰 ', style: TextStyle(fontSize: 18)),
                          Text(
                            '₹${item.price.toStringAsFixed(2)}',
                            style: VillageTheme.headingSmall.copyWith(
                              color: VillageTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: VillageTheme.spacingM),
            // Quantity Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quantity Controls
                Container(
                  decoration: BoxDecoration(
                    color: VillageTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
                    border: Border.all(color: VillageTheme.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: () => cart.removeSingleItem(item.id),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Text(
                          '${item.quantity}',
                          style: VillageTheme.headingSmall.copyWith(
                            color: VillageTheme.primaryGreen,
                          ),
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onPressed: () => cart.addItem(
                          item.id,
                          item.name,
                          item.price,
                          item.image,
                          item.shopId,
                          item.shopName,
                        ),
                      ),
                    ],
                  ),
                ),
                // Remove Button
                Container(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _showRemoveDialog(context, cart, item),
                    icon: Icon(Icons.delete_outline, size: VillageTheme.iconMedium),
                    label: Text(
                      'நீக்கு / Remove',
                      style: VillageTheme.bodyMedium.copyWith(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VillageTheme.errorRed,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: VillageTheme.spacingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
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
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: VillageTheme.primaryGreen,
        borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
        boxShadow: VillageTheme.buttonShadow,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: VillageTheme.iconMedium),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartProvider cart) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(VillageTheme.spacingL),
      decoration: BoxDecoration(
        color: VillageTheme.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(VillageTheme.cardRadius * 2),
          topRight: Radius.circular(VillageTheme.cardRadius * 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Summary Header with Emoji
            Container(
              padding: EdgeInsets.all(VillageTheme.spacingM),
              decoration: BoxDecoration(
                gradient: VillageTheme.primaryGradient,
                borderRadius: BorderRadius.circular(VillageTheme.cardRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('📝 ', style: TextStyle(fontSize: 20)),
                          Text(
                            'மொத்த பொருட்கள் / Total Items',
                            style: VillageTheme.bodyMedium.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      SizedBox(height: VillageTheme.spacingXS),
                      Text(
                        '${cart.totalQuantity} பொருட்கள் / Items',
                        style: VillageTheme.headingSmall.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text('💰 ', style: TextStyle(fontSize: 20)),
                          Text(
                            'மொத்த தொகை / Total',
                            style: VillageTheme.bodyMedium.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      SizedBox(height: VillageTheme.spacingXS),
                      Text(
                        '₹${cart.totalAmount.toStringAsFixed(2)}',
                        style: VillageTheme.headingLarge.copyWith(
                          color: Colors.white,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: VillageTheme.spacingM),
            // Checkout Button
            VillageWidgets.bigButton(
              text: 'பணம் செலுத்த / Proceed to Checkout',
              icon: Icons.payment,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CheckoutScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, CartProvider cart, CartItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VillageTheme.cardRadius),
          ),
          title: Row(
            children: [
              Text('🗑️ ', style: TextStyle(fontSize: 24)),
              Text(
                'பொருளை நீக்கு / Remove Item',
                style: VillageTheme.headingSmall,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(VillageTheme.spacingM),
                decoration: BoxDecoration(
                  color: VillageTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
                ),
                child: Row(
                  children: [
                    Text('📦 ', style: TextStyle(fontSize: 20)),
                    Expanded(
                      child: Text(
                        item.name,
                        style: VillageTheme.bodyLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: VillageTheme.spacingM),
              Text(
                'இந்த பொருளை வண்டியிலிருந்து நீக்க வேண்டுமா?\nRemove this item from cart?',
                style: VillageTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Container(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: VillageTheme.secondaryButtonStyle,
                      child: Text(
                        'रद्द / Cancel',
                        style: VillageTheme.buttonText.copyWith(
                          color: VillageTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: VillageTheme.spacingS),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        cart.removeItem(item.id);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Text('✅ ', style: TextStyle(fontSize: 16)),
                                Expanded(
                                  child: Text(
                                    '${item.name} वण्डियिलिरुन्दु नीक्कप्पट्टदु / removed from cart',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: VillageTheme.successGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VillageTheme.errorRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
                        ),
                      ),
                      child: Text(
                        'नीक्कु / Remove',
                        style: VillageTheme.buttonText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}