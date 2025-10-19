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
  final int stock;
  final String? category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({
    Key? key,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.stock,
    this.category,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool lowStock = stock < 10;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.roundedLarge,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.roundedLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusLarge),
                      topRight: Radius.circular(AppTheme.radiusLarge),
                    ),
                    image: imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageUrl == null
                      ? const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: AppTheme.textHint,
                          ),
                        )
                      : null,
                ),
                // Stock Badge
                Positioned(
                  top: AppTheme.space8,
                  right: AppTheme.space8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space8,
                      vertical: AppTheme.space4,
                    ),
                    decoration: BoxDecoration(
                      color: lowStock ? AppTheme.error : AppTheme.success,
                      borderRadius: AppTheme.roundedSmall,
                    ),
                    child: Text(
                      'Stock: $stock',
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (category != null)
                          Text(
                            category!.toUpperCase(),
                            style: AppTheme.overline.copyWith(
                              color: AppTheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          name,
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '₹${price.toStringAsFixed(2)}',
                            style: AppTheme.h6.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onEdit != null)
                              InkWell(
                                onTap: onEdit,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary.withOpacity(0.1),
                                    borderRadius: AppTheme.roundedSmall,
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ),
                            if (onDelete != null) ...[
                              const SizedBox(width: AppTheme.space4),
                              InkWell(
                                onTap: onDelete,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withOpacity(0.1),
                                    borderRadius: AppTheme.roundedSmall,
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: AppTheme.error,
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
