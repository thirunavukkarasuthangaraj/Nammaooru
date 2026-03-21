import 'package:flutter/material.dart';

class AppColors {
  // Modern food delivery app colors - Green theme
  static const Color primary = Color(0xFF4CAF50); // Green primary
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFF81C784);
  static const Color secondary = Color(0xFFFC8019); // Swiggy orange
  static const Color accent = Color(0xFF00AC4F); // Green for success/healthy
  
  // Backgrounds
  static const Color background = Color(0xFFFCFCFC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F8F8);
  
  // Status colors
  static const Color error = Color(0xFFDC3545);
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF636366);
  static const Color textTertiary = Color(0xFF8E8E93);
  static const Color textHint = Color(0xFFC7C7CC);
  
  // Border and divider colors
  static const Color divider = Color(0xFFE5E5EA);
  static const Color border = Color(0xFFE5E5EA);
  static const Color shadow = Color(0x14000000);
  
  // Food delivery specific colors
  static const Color foodPrimary = Color(0xFFE23744); // Main red
  static const Color foodSecondary = Color(0xFFFC8019); // Orange
  static const Color veg = Color(0xFF00AC4F); // Green for veg
  static const Color nonVeg = Color(0xFFE23744); // Red for non-veg
  static const Color rating = Color(0xFFFFC107); // Gold for ratings
  static const Color discount = Color(0xFF9C27B0); // Purple for discounts
  
  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFFE23744),
    Color(0xFFFC8019),
  ];
  
  static const List<Color> successGradient = [
    Color(0xFF28A745),
    Color(0xFF20C997),
  ];
  
  static const List<Color> cardGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFFAFAFA),
  ];
  
  // Role specific colors for multi-service platform
  static const Map<String, Color> roleColors = {
    'CUSTOMER': Color(0xFFE23744),
    'SHOP_OWNER': Color(0xFFFC8019),
    'DELIVERY_PARTNER': Color(0xFF00AC4F),
  };
  
  // Service category colors
  static const Map<String, Color> serviceColors = {
    'FOOD': Color(0xFFE23744),
    'GROCERY': Color(0xFF00AC4F),
    'PHARMACY': Color(0xFF6C63FF),
    'ELECTRONICS': Color(0xFF17A2B8),
    'CLOTHING': Color(0xFF9C27B0),
  };
}