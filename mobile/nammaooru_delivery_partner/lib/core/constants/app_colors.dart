import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Based on HTML mockup
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF45a049);
  static const Color primaryLight = Color(0xFF81C784);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF2196F3);
  static const Color accent = Color(0xFFFF9800);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFf44336);
  static const Color info = Color(0xFF2196F3);
  
  // Neutral Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF333333);
  static const Color onBackground = Color(0xFF212121);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  
  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);
  
  // Online/Offline Status
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFFf44336);
  
  // Order Status Colors
  static const Color orderNew = Color(0xFFFF9800);
  static const Color orderAccepted = Color(0xFF4CAF50);
  static const Color orderPickedUp = Color(0xFF2196F3);
  static const Color orderDelivered = Color(0xFF4CAF50);
  static const Color orderCancelled = Color(0xFFf44336);
  
  // Earnings Colors
  static const Color earningsPositive = Color(0xFF4CAF50);
  static const Color earningsNeutral = Color(0xFF757575);
  
  // Rating Colors
  static const Color ratingStar = Color(0xFFFF9800);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient earningsGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Transparency variations
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  static Color surfaceWithOpacity(double opacity) => surface.withOpacity(opacity);
  static Color blackWithOpacity(double opacity) => Colors.black.withOpacity(opacity);
  static Color whiteWithOpacity(double opacity) => Colors.white.withOpacity(opacity);
}