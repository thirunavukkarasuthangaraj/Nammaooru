import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color secondary = Color(0xFF26A69A);
  static const Color secondaryLight = Color(0xFF80CBC4);
  static const Color secondaryDark = Color(0xFF00695C);

  // Semantic colors
  static const Color success = Color(0xFF66BB6A);
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color successDark = Color(0xFF388E3C);

  static const Color error = Color(0xFFEF5350);
  static const Color errorLight = Color(0xFFFFCDD2);
  static const Color errorDark = Color(0xFFC62828);

  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFE0B2);
  static const Color warningDark = Color(0xFFE65100);

  static const Color info = Color(0xFF42A5F5);
  static const Color infoLight = Color(0xFFBBDEFB);
  static const Color infoDark = Color(0xFF1976D2);

  // Neutral colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFF212121);

  // Border and divider colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF5F5F5);
  static const Color divider = Color(0xFFBDBDBD);

  // Overlay colors
  static const Color overlay = Color(0x80000000);
  static const Color scrim = Color(0x1F000000);

  // Legacy colors (for backward compatibility)
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF424242);
}

class AppSizes {
  // Base spacing units
  static const double spacingUnit = 4.0;

  // Spacing scale (based on 4pt grid system)
  static const double spacing2xs = spacingUnit;      // 4.0
  static const double spacingXs = spacingUnit * 2;  // 8.0
  static const double spacingSm = spacingUnit * 3;  // 12.0
  static const double spacingMd = spacingUnit * 4;  // 16.0
  static const double spacingLg = spacingUnit * 6;  // 24.0
  static const double spacingXl = spacingUnit * 8;  // 32.0
  static const double spacing2xl = spacingUnit * 10; // 40.0
  static const double spacing3xl = spacingUnit * 12; // 48.0

  // Legacy spacing (for backward compatibility)
  static const double padding = spacingMd;
  static const double margin = spacingMd;

  // Border radius scale
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radius2xl = 20.0;
  static const double radiusRound = 999.0;

  // Legacy border radius
  static const double borderRadius = radiusLg;

  // Component dimensions
  static const double buttonHeightSm = 32.0;
  static const double buttonHeightMd = 40.0;
  static const double buttonHeightLg = 48.0;
  static const double buttonHeightXl = 56.0;

  // Legacy button height
  static const double buttonHeight = buttonHeightMd;

  // Input field dimensions
  static const double inputHeightSm = 36.0;
  static const double inputHeightMd = 44.0;
  static const double inputHeightLg = 52.0;

  // Icon sizes
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
  static const double icon2xl = 40.0;
  static const double icon3xl = 48.0;

  // Elevation scale
  static const double elevationNone = 0.0;
  static const double elevationXs = 1.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 12.0;
  static const double elevation2xl = 16.0;

  // Legacy elevation
  static const double cardElevation = elevationSm;

  // Layout dimensions
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 64.0;
  static const double tabBarHeight = 48.0;
  static const double toolbarHeight = 56.0;

  // Container constraints
  static const double maxContentWidth = 1200.0;
  static const double minTouchTarget = 44.0;
  static const double listItemMinHeight = 48.0;

  // Image sizes
  static const double avatarSm = 24.0;
  static const double avatarMd = 32.0;
  static const double avatarLg = 40.0;
  static const double avatarXl = 48.0;
  static const double avatar2xl = 64.0;
  static const double avatar3xl = 96.0;

  // Progress indicators
  static const double progressIndicatorSm = 16.0;
  static const double progressIndicatorMd = 20.0;
  static const double progressIndicatorLg = 24.0;

  // Divider thickness
  static const double dividerThin = 0.5;
  static const double dividerThick = 1.0;
  static const double dividerThicker = 2.0;
}

class AppTextStyles {
  // Display text styles (largest)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // Headline text styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  // Title text styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  // Body text styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.55,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  // Label text styles (for buttons, chips, etc.)
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  // Button text styles
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
    color: AppColors.textOnPrimary,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
    color: AppColors.textOnPrimary,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
    color: AppColors.textOnPrimary,
  );

  // Special text styles
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.6,
    letterSpacing: 1.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle monospace = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
    fontFamily: 'monospace',
    color: AppColors.textPrimary,
  );

  // Error text style
  static const TextStyle error = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.4,
    color: AppColors.error,
  );

  // Legacy text styles (for backward compatibility)
  static const TextStyle heading1 = displaySmall;
  static const TextStyle heading2 = headlineMedium;
  static const TextStyle heading3 = headlineSmall;
  static const TextStyle body1 = bodyLarge;
  static const TextStyle body2 = bodyMedium;
  static const TextStyle body = bodyMedium;
  static const TextStyle caption = bodySmall;

  // Helper methods for text style variations
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }
}

class AppStrings {
  static const String appName = 'NammaOoru Shop Owner';
  static const String welcomeBack = 'Welcome back';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String dashboard = 'Dashboard';
  static const String myProducts = 'My Products';
  static const String browseProducts = 'Browse Products';
  static const String finance = 'Finance';
  static const String orders = 'Orders';
  static const String shopProfile = 'Shop Profile';
  static const String notifications = 'Notifications';
  static const String search = 'Search';
  static const String addProduct = 'Add Product';
  static const String editProduct = 'Edit Product';
  static const String deleteProduct = 'Delete Product';
  static const String totalRevenue = 'Total Revenue';
  static const String todaySales = 'Today\'s Sales';
  static const String pendingOrders = 'Pending Orders';
  static const String approved = 'APPROVED';
  static const String pending = 'PENDING';
  static const String active = 'ACTIVE';
  static const String inactive = 'INACTIVE';
}

class ApiEndpoints {
  static const String baseUrl = 'https://nammaoorudelivary.in/api';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String shopProfile = '/shop/profile';
  static const String myShop = '/shops/my-shop';
  static const String shops = '/shops';
  static const String products = '/products';
  static const String orders = '/orders';
  static const String finance = '/finance';
  static const String notifications = '/notifications';
  static const String websocket = 'wss://nammaoorudelivary.in/ws';

  // Shop-specific endpoints (require shopId parameter)
  static String shopDashboard(String shopId) => '/shops/$shopId/dashboard';
  static String shopOrders(String shopId) => '/shops/$shopId/orders';
  static String shopAnalytics(String shopId) => '/shops/$shopId/analytics';
}

class NotificationTypes {
  static const String newOrder = 'new_order';
  static const String paymentReceived = 'payment_received';
  static const String orderCancelled = 'order_cancelled';
  static const String orderModified = 'order_modified';
  static const String reviewReceived = 'review_received';
  static const String customerMessage = 'customer_message';
  static const String timeAlert = 'time_alert';
}

class SoundFiles {
  static const String newOrder = 'new_order.mp3';
  static const String paymentReceived = 'payment_received.mp3';
  static const String orderCancelled = 'order_cancelled.mp3';
  static const String urgentAlert = 'urgent_alert.mp3';
  static const String successChime = 'success_chime.mp3';
  static const String messageReceived = 'message_received.mp3';
  static const String lowStock = 'low_stock.mp3';
}

class AppAnimations {
  // Animation duration constants
  static const Duration durationInstant = Duration.zero;
  static const Duration duration75 = Duration(milliseconds: 75);
  static const Duration duration100 = Duration(milliseconds: 100);
  static const Duration duration150 = Duration(milliseconds: 150);
  static const Duration duration200 = Duration(milliseconds: 200);
  static const Duration duration300 = Duration(milliseconds: 300);
  static const Duration duration500 = Duration(milliseconds: 500);
  static const Duration duration700 = Duration(milliseconds: 700);
  static const Duration duration1000 = Duration(milliseconds: 1000);

  // Common durations
  static const Duration fast = duration150;
  static const Duration normal = duration300;
  static const Duration slow = duration500;

  // Easing curves
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticIn = Curves.elasticIn;
  static const Curve elasticOut = Curves.elasticOut;

  // Custom curves for specific interactions
  static const Curve buttonPress = Curves.easeInOut;
  static const Curve pageTransition = Curves.easeInOut;
  static const Curve slideIn = Curves.easeOut;
  static const Curve fadeIn = Curves.easeIn;
  static const Curve scale = Curves.easeInOut;

  // Stagger delays for list animations
  static const Duration staggerDelay = Duration(milliseconds: 50);
  static const Duration staggerDelayFast = Duration(milliseconds: 25);
  static const Duration staggerDelaySlow = Duration(milliseconds: 100);
}

class AppThemes {
  // Shadow definitions
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: AppColors.scrim,
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: AppColors.scrim,
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: AppColors.scrim,
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowXl = [
    BoxShadow(
      color: AppColors.scrim,
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // Button styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    elevation: AppSizes.elevationSm,
    padding: EdgeInsets.symmetric(
      horizontal: AppSizes.spacingLg,
      vertical: AppSizes.spacingMd,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    ),
    textStyle: AppTextStyles.buttonMedium,
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.primary,
    elevation: AppSizes.elevationXs,
    side: BorderSide(color: AppColors.border),
    padding: EdgeInsets.symmetric(
      horizontal: AppSizes.spacingLg,
      vertical: AppSizes.spacingMd,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    ),
    textStyle: AppTextStyles.buttonMedium,
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    padding: EdgeInsets.symmetric(
      horizontal: AppSizes.spacingMd,
      vertical: AppSizes.spacingSm,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    ),
    textStyle: AppTextStyles.buttonMedium,
  );

  // Input decoration theme
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSizes.spacingMd,
      vertical: AppSizes.spacingMd,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      borderSide: BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      borderSide: BorderSide(color: AppColors.error, width: 2),
    ),
  );

  // Card theme
  static CardTheme cardTheme = CardTheme(
    elevation: AppSizes.elevationSm,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    ),
    color: AppColors.surface,
    margin: EdgeInsets.all(AppSizes.spacingSm),
  );

  // App bar theme
  static AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    elevation: AppSizes.elevationXs,
    centerTitle: true,
    titleTextStyle: AppTextStyles.titleLarge,
    iconTheme: IconThemeData(
      color: AppColors.textPrimary,
      size: AppSizes.iconLg,
    ),
  );

  // Bottom navigation bar theme
  static BottomNavigationBarThemeData bottomNavigationBarTheme = BottomNavigationBarThemeData(
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
    type: BottomNavigationBarType.fixed,
    elevation: AppSizes.elevationMd,
    selectedLabelStyle: AppTextStyles.labelSmall,
    unselectedLabelStyle: AppTextStyles.labelSmall,
  );

  // Chip theme
  static ChipThemeData chipTheme = ChipThemeData(
    backgroundColor: AppColors.surfaceVariant,
    selectedColor: AppColors.primary,
    labelStyle: AppTextStyles.labelMedium,
    side: BorderSide(color: AppColors.border),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusRound),
    ),
  );
}