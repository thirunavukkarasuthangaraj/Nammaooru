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
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const OrderCard({
    Key? key,
    required this.orderNumber,
    required this.customerName,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    required this.itemCount,
    this.onTap,
    this.onAccept,
    this.onReject,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warning;
      case 'accepted':
      case 'preparing':
        return AppTheme.info;
      case 'ready':
      case 'delivered':
        return AppTheme.success;
      case 'cancelled':
      case 'rejected':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_outlined;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant_outlined;
      case 'ready':
        return Icons.done_all;
      case 'delivered':
        return Icons.verified;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
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
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#$orderNumber',
                          style: AppTheme.h6.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  const SizedBox(width: AppTheme.space8),
                  Flexible(
                    child: Container(
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
                          const SizedBox(width: AppTheme.space4),
                          Flexible(
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                  if (status.toLowerCase() == 'pending' &&
                      (onAccept != null || onReject != null))
                    Row(
                      children: [
                        if (onReject != null)
                          InkWell(
                            onTap: onReject,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space12,
                                vertical: AppTheme.space8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.1),
                                borderRadius: AppTheme.roundedSmall,
                              ),
                              child: const Text(
                                'Reject',
                                style: TextStyle(
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        if (onAccept != null) ...[
                          const SizedBox(width: AppTheme.space8),
                          InkWell(
                            onTap: onAccept,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space12,
                                vertical: AppTheme.space8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.success,
                                borderRadius: AppTheme.roundedSmall,
                              ),
                              child: const Text(
                                'Accept',
                                style: TextStyle(
                                  color: AppTheme.textWhite,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
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
          padding: const EdgeInsets.all(AppTheme.space16),
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
