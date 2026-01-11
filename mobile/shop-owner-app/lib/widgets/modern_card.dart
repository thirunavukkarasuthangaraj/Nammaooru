import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Modern Card Components
///
/// Includes:
/// - StatCard - For dashboard statistics
/// - ProductCard - For product listings
/// - OrderCard - For order listings
/// - InfoCard - For general information display

/// Stat Card for Dashboard
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool useGradient;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppTheme.primary,
    this.subtitle,
    this.onTap,
    this.useGradient = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.roundedLarge,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.roundedLarge,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: BoxDecoration(
            borderRadius: AppTheme.roundedLarge,
            gradient: useGradient
                ? LinearGradient(
                    colors: [
                      color.withOpacity(0.05),
                      color.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallCard = constraints.maxWidth < 150;
                final valueFontSize = isSmallCard ? 15.0 : 18.0;
                final titleFontSize = isSmallCard ? 10.0 : 11.0;
                final subtitleFontSize = isSmallCard ? 8.0 : 9.0;
                final iconSize = isSmallCard ? 16.0 : 18.0;

                return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(icon, color: color, size: iconSize),
                      if (onTap != null)
                        Icon(Icons.arrow_forward_ios, size: 10, color: AppTheme.textHint),
                    ],
                  ),
                  SizedBox(height: isSmallCard ? 3 : 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallCard ? 1 : 2),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                      ),
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: isSmallCard ? 1 : 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Product Card for Product Listings
class ProductCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double price;
  final double? originalPrice;
  final int stock;
  final String? category;
  final String? unit;
  final double? weight;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({
    Key? key,
    required this.name,
    this.imageUrl,
    required this.price,
    this.originalPrice,
    required this.stock,
    this.category,
    this.unit,
    this.weight,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool lowStock = stock < 10;
    final bool hasDiscount = originalPrice != null && originalPrice! > price;
    final double discountPercentage = hasDiscount
        ? ((originalPrice! - price) / originalPrice!) * 100
        : 0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.grey[50]!,
                          Colors.grey[100]!,
                        ],
                      ),
                    ),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 56,
                                color: Colors.grey[300],
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 56,
                              color: Colors.grey[300],
                            ),
                          ),
                  ),
                ),
                // Discount Badge
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red[700]!, Colors.red[500]!],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${discountPercentage.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                // Stock Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: lowStock ? Colors.orange[600] : Colors.green[600],
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: (lowStock ? Colors.orange : Colors.green).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          lowStock ? Icons.warning_amber_rounded : Icons.check_circle,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$stock',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Weight/Unit Info - More Prominent
                  if (weight != null && unit != null && unit!.isNotEmpty)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.scale_outlined,
                                size: 14,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${weight!.toStringAsFixed(weight! % 1 == 0 ? 0 : 1)} ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[900],
                                ),
                              ),
                              Text(
                                unit!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),

                  // Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Price Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasDiscount) ...[
                              Text(
                                '₹${originalPrice!.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  decoration: TextDecoration.lineThrough,
                                  decorationThickness: 2,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              '₹${price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: hasDiscount ? Colors.green[700] : AppTheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action Buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onEdit != null)
                            Material(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: onEdit,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ),
                          if (onDelete != null) ...[
                            const SizedBox(width: 6),
                            Material(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: onDelete,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Order Card for Order Listings
class OrderCard extends StatelessWidget {
  final String orderNumber;
  final String customerName;
  final double totalAmount;
  final String status;
  final DateTime orderDate;
  final int itemCount;
  final List<dynamic>? items; // Add items parameter
  final String? deliveryType; // Add delivery type
  final bool isLoading; // Add loading state
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onStartPreparing;
  final VoidCallback? onMarkReady;
  final VoidCallback? onOutForDelivery;
  final VoidCallback? onMarkDelivered;
  final VoidCallback? onHandoverSelfPickup; // For SELF_PICKUP orders at READY_FOR_PICKUP
  final VoidCallback? onVerifyPickupOTP; // For HOME_DELIVERY orders at READY_FOR_PICKUP
  final VoidCallback? onRetryDriverSearch; // For retrying driver search when no driver found
  final VoidCallback? onAddItem; // For adding items to PENDING/CONFIRMED/PREPARING orders
  final DateTime? driverSearchStartedAt; // When driver search started
  final bool? driverSearchCompleted; // Whether driver search completed

  const OrderCard({
    Key? key,
    required this.orderNumber,
    required this.customerName,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    required this.itemCount,
    this.items, // Add items parameter
    this.deliveryType, // Add delivery type
    this.isLoading = false, // Default to false
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onStartPreparing,
    this.onMarkReady,
    this.onOutForDelivery,
    this.onMarkDelivered,
    this.onHandoverSelfPickup,
    this.onVerifyPickupOTP,
    this.onRetryDriverSearch,
    this.onAddItem,
    this.driverSearchStartedAt,
    this.driverSearchCompleted,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (status.toLowerCase().replaceAll('_', '')) {
      case 'pending':
        return AppTheme.warning;
      case 'accepted':
      case 'preparing':
      case 'confirmed':
        return AppTheme.info;
      case 'ready':
      case 'readyforpickup':
      case 'delivered':
        return AppTheme.success;
      case 'cancelled':
      case 'rejected':
        return AppTheme.error;
      case 'returningtoshop':
      case 'returnedtoshop':
        return Colors.deepOrange;  // Highlight returned orders
      case 'outfordelivery':
        return Colors.indigo;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (status.toLowerCase().replaceAll('_', '')) {
      case 'pending':
        return Icons.pending_outlined;
      case 'accepted':
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant_outlined;
      case 'ready':
      case 'readyforpickup':
        return Icons.done_all;
      case 'delivered':
        return Icons.verified;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;
      case 'returningtoshop':
        return Icons.local_shipping;
      case 'returnedtoshop':
        return Icons.inventory_2;  // Box icon for returned
      case 'outfordelivery':
        return Icons.delivery_dining;
      default:
        return Icons.info_outline;
    }
  }

  String _getShortStatus(String status) {
    final statusLower = status.toLowerCase().replaceAll('_', ' ');
    switch (statusLower) {
      case 'ready for pickup':
        return 'READY';
      case 'out for delivery':
        return 'DELIVERY';
      case 'pending':
        return 'PENDING';
      case 'accepted':
      case 'confirmed':
        return 'CONFIRMED';
      case 'preparing':
        return 'PREPARING';
      case 'ready':
        return 'READY';
      case 'delivered':
        return 'DELIVERED';
      case 'cancelled':
        return 'CANCELLED';
      case 'rejected':
        return 'REJECTED';
      case 'returning to shop':
        return 'RETURNING';
      case 'returned to shop':
        return 'RETURNED TO SHOP';
      default:
        return status.toUpperCase().substring(0, status.length > 12 ? 12 : status.length);
    }
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space8,
        ),
        decoration: BoxDecoration(
          color: isLoading ? backgroundColor.withOpacity(0.6) : backgroundColor,
          borderRadius: AppTheme.roundedSmall,
        ),
        child: isLoading
            ? SizedBox(
                width: 60,
                height: 16,
                child: Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final statusLower = status.toLowerCase().replaceAll('_', ' ');

    switch (statusLower) {
      case 'pending':
        if (onAccept != null || onReject != null || onAddItem != null) {
          return Wrap(
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: [
              if (onAddItem != null)
                _buildActionButton(
                  label: '+ Add',
                  onPressed: onAddItem!,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  textColor: Colors.blue,
                ),
              if (onReject != null)
                _buildActionButton(
                  label: 'Reject',
                  onPressed: onReject!,
                  backgroundColor: AppTheme.error.withOpacity(0.1),
                  textColor: AppTheme.error,
                ),
              if (onAccept != null)
                _buildActionButton(
                  label: 'Accept',
                  onPressed: onAccept!,
                  backgroundColor: AppTheme.success,
                  textColor: AppTheme.textWhite,
                ),
            ],
          );
        }
        break;

      case 'confirmed':
      case 'accepted':
        return Wrap(
          spacing: AppTheme.space8,
          runSpacing: AppTheme.space8,
          children: [
            if (onAddItem != null)
              _buildActionButton(
                label: '+ Add',
                onPressed: onAddItem!,
                backgroundColor: Colors.blue.withOpacity(0.1),
                textColor: Colors.blue,
              ),
            if (onStartPreparing != null)
              _buildActionButton(
                label: 'Start Preparing',
                onPressed: onStartPreparing!,
                backgroundColor: AppTheme.info,
                textColor: AppTheme.textWhite,
              ),
          ],
        );

      case 'preparing':
        // At PREPARING status, shop owners can ONLY mark as READY_FOR_PICKUP
        // For HOME_DELIVERY: This triggers auto-assignment to delivery partner
        // For SELF_PICKUP: Customer will come to pick up
        // Shop owners should NOT be able to skip to OUT_FOR_DELIVERY
        final isSelfPickup = deliveryType?.toUpperCase() == 'SELF_PICKUP';
        return Wrap(
          spacing: AppTheme.space8,
          runSpacing: AppTheme.space8,
          children: [
            if (onAddItem != null)
              _buildActionButton(
                label: '+ Add',
                onPressed: onAddItem!,
                backgroundColor: Colors.blue.withOpacity(0.1),
                textColor: Colors.blue,
              ),
            if (onMarkReady != null)
              _buildActionButton(
                label: isSelfPickup ? 'Ready for Pickup' : 'Ready',
                onPressed: onMarkReady!,
                backgroundColor: AppTheme.success,
                textColor: AppTheme.textWhite,
              ),
          ],
        );

      case 'ready':
        // At READY status (after driver search timeout), show buttons
        // For HOME_DELIVERY: Show "Find Driver" and "Cancel" buttons
        // For SELF_PICKUP: Show "Handover" button
        final isSelfPickupReady = deliveryType?.toUpperCase() == 'SELF_PICKUP';

        if (isSelfPickupReady && onHandoverSelfPickup != null) {
          return _buildActionButton(
            label: 'Handover',
            onPressed: onHandoverSelfPickup!,
            backgroundColor: AppTheme.success,
            textColor: AppTheme.textWhite,
          );
        } else if (!isSelfPickupReady) {
          // HOME_DELIVERY at READY: Show "Find Driver" and "Cancel" buttons
          return Row(
            children: [
              if (onReject != null)
                _buildActionButton(
                  label: 'Cancel',
                  onPressed: onReject!,
                  backgroundColor: AppTheme.error.withOpacity(0.1),
                  textColor: AppTheme.error,
                ),
              if (onReject != null && onMarkReady != null)
                const SizedBox(width: 8),
              if (onMarkReady != null)
                _buildActionButton(
                  label: 'Find Driver',
                  onPressed: onMarkReady!,
                  backgroundColor: Colors.orange,
                  textColor: AppTheme.textWhite,
                ),
            ],
          );
        }
        break;

      case 'ready for pickup':
        final isSelfPickup = deliveryType?.toUpperCase() == 'SELF_PICKUP';

        if (isSelfPickup && onHandoverSelfPickup != null) {
          // SELF_PICKUP: Show "Handover to Customer" button
          return _buildActionButton(
            label: 'Handover',
            onPressed: onHandoverSelfPickup!,
            backgroundColor: AppTheme.success,
            textColor: AppTheme.textWhite,
          );
        } else if (!isSelfPickup && onVerifyPickupOTP != null) {
          // HOME_DELIVERY with driver assigned: Show "Verify Pickup OTP" button
          return _buildActionButton(
            label: 'Verify OTP',
            onPressed: onVerifyPickupOTP!,
            backgroundColor: Colors.orange,
            textColor: AppTheme.textWhite,
          );
        } else if (!isSelfPickup) {
          // HOME_DELIVERY without driver: Show timer countdown with Find Driver button
          return DriverSearchTimerWidget(
            driverSearchStartedAt: driverSearchStartedAt,
            driverSearchCompleted: driverSearchCompleted ?? false,
            onRetryDriverSearch: onRetryDriverSearch,
          );
        }
        break;

      case 'out for delivery':
        // OUT_FOR_DELIVERY orders can only be delivered by the driver
        // Shop owners should NOT have a button to mark as delivered
        // This prevents bypassing the driver delivery flow
        break;

      case 'delivered':
      case 'cancelled':
      case 'rejected':
        // No action buttons for completed/cancelled orders
        break;
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.roundedLarge,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.roundedLarge,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '#$orderNumber',
                                style: AppTheme.h6.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            // Delivery type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (deliveryType?.toUpperCase() == 'SELF_PICKUP')
                                    ? AppTheme.info.withOpacity(0.1)
                                    : AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: (deliveryType?.toUpperCase() == 'SELF_PICKUP')
                                      ? AppTheme.info
                                      : AppTheme.primary,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (deliveryType?.toUpperCase() == 'SELF_PICKUP')
                                        ? Icons.storefront
                                        : Icons.delivery_dining,
                                    size: 12,
                                    color: (deliveryType?.toUpperCase() == 'SELF_PICKUP')
                                        ? AppTheme.info
                                        : AppTheme.primary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    (deliveryType?.toUpperCase() == 'SELF_PICKUP')
                                        ? 'PICKUP'
                                        : 'DELIVERY',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: (deliveryType?.toUpperCase() == 'SELF_PICKUP')
                                          ? AppTheme.info
                                          : AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          customerName,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: AppTheme.roundedMedium,
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(),
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Text(
                      status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              // Product Images Preview
              if (items != null && items!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...items!.take(1).map((item) {
                      final productName = item['productName'] ?? '';
                      final productImage = item['productImageUrl'] ?? item['productImage'] ?? '';
                      final quantity = item['quantity'] ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.space8),
                        padding: const EdgeInsets.all(AppTheme.space8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withOpacity(0.5),
                          borderRadius: AppTheme.roundedSmall,
                          border: Border.all(
                            color: AppTheme.borderLight,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Product Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: productImage.isNotEmpty
                                  ? Image.network(
                                      productImage.startsWith('http')
                                          ? productImage
                                          : 'http://localhost:8080$productImage',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [AppTheme.primary.withOpacity(0.7), AppTheme.primary],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Text(
                                            productName.isNotEmpty ? productName[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [AppTheme.primary.withOpacity(0.7), AppTheme.primary],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: Text(
                                          productName.isNotEmpty ? productName[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: AppTheme.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Qty: $quantity',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    if (items!.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(left: AppTheme.space8),
                        child: Text(
                          '+${items!.length - 1} more item${items!.length - 1 > 1 ? 's' : ''}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textHint,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              const Divider(height: AppTheme.space24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: AppTheme.space4),
                      Text(
                        '$itemCount items',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: AppTheme.space4),
                      Text(
                        _formatDate(orderDate),
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '₹${totalAmount.toStringAsFixed(2)}',
                      style: AppTheme.h5.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  // Status-specific action buttons
                  _buildActionButtons(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Server sends UTC time, convert to IST (UTC+5:30)
    final istDate = date.add(const Duration(hours: 5, minutes: 30));
    final now = DateTime.now();
    final difference = now.difference(istDate);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${istDate.day}/${istDate.month}/${istDate.year}';
    }
  }
}

/// Info Card for General Information
class InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? child;
  final Color? color;
  final VoidCallback? onTap;

  const InfoCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    this.child,
    this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.roundedLarge,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.roundedLarge,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space8),
                      decoration: BoxDecoration(
                        color: (color ?? AppTheme.primary).withOpacity(0.1),
                        borderRadius: AppTheme.roundedSmall,
                      ),
                      child: Icon(
                        icon,
                        color: color ?? AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.h6.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppTheme.space4),
                          Text(
                            subtitle!,
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.textHint,
                    ),
                ],
              ),
              if (child != null) ...[
                const SizedBox(height: AppTheme.space16),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget to show driver search countdown timer with Find Driver button
class DriverSearchTimerWidget extends StatefulWidget {
  final DateTime? driverSearchStartedAt;
  final bool driverSearchCompleted;
  final VoidCallback? onRetryDriverSearch;

  const DriverSearchTimerWidget({
    Key? key,
    this.driverSearchStartedAt,
    this.driverSearchCompleted = false,
    this.onRetryDriverSearch,
  }) : super(key: key);

  @override
  State<DriverSearchTimerWidget> createState() => _DriverSearchTimerWidgetState();
}

class _DriverSearchTimerWidgetState extends State<DriverSearchTimerWidget> {
  Timer? _timer;
  int _remainingSeconds = 0;
  static const int _searchDurationSeconds = 120; // 2 minutes

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  @override
  void didUpdateWidget(DriverSearchTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.driverSearchStartedAt != oldWidget.driverSearchStartedAt) {
      _calculateRemainingTime();
    }
  }

  void _calculateRemainingTime() {
    if (widget.driverSearchStartedAt != null && !widget.driverSearchCompleted) {
      final elapsed = DateTime.now().difference(widget.driverSearchStartedAt!).inSeconds;
      _remainingSeconds = (_searchDurationSeconds - elapsed).clamp(0, _searchDurationSeconds);
    } else {
      _remainingSeconds = 0;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _remainingSeconds > 0 && !widget.driverSearchCompleted;

    if (isSearching) {
      // Timer running - show countdown with disabled button
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Searching...  ${_formatTime(_remainingSeconds)}',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Timer completed - show enabled Find Driver button
      return ElevatedButton.icon(
        onPressed: widget.onRetryDriverSearch,
        icon: const Icon(Icons.search, size: 18),
        label: const Text('Find Driver'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}
