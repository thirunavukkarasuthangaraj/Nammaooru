import 'package:intl/intl.dart';

class AppHelpers {
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy hh:mm a').format(dateTime);
  }

  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static double calculatePercentageChange(double current, double previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  static String formatPercentage(double percentage) {
    return '${percentage >= 0 ? '+' : ''}${percentage.toStringAsFixed(1)}%';
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
  }

  static String generateOrderId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    return 'ORD$timestamp';
  }

  static String getOrderStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return '0xFF4CAF50'; // Green
      case 'PENDING':
        return '0xFFFF9800'; // Orange
      case 'CANCELLED':
        return '0xFFF44336'; // Red
      case 'COMPLETED':
        return '0xFF2196F3'; // Blue
      default:
        return '0xFF9E9E9E'; // Grey
    }
  }

  static String getProductStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return '0xFF4CAF50'; // Green
      case 'INACTIVE':
        return '0xFFF44336'; // Red
      case 'OUT_OF_STOCK':
        return '0xFFFF9800'; // Orange
      default:
        return '0xFF9E9E9E'; // Grey
    }
  }
}