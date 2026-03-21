import 'package:flutter/material.dart';

class VillageTheme {
  // Modern color palette
  static const Color primaryGreen = Color(0xFF4CAF50); // Primary Green
  static const Color lightGreen = Color(0xFF81C784);   // Light Green variant
  static const Color accentOrange = Color(0xFF66BB6A); // Green accent
  static const Color warmYellow = Color(0xFFFFA726);   // Turmeric Yellow
  static const Color earthBrown = Color(0xFF8D6E63);   // Earth Brown
  static const Color skyBlue = Color(0xFF2196F3);      // Info Blue

  // Modern gradient colors
  static const Color gradientPurple1 = Color(0xFF8B5A96);
  static const Color gradientPurple2 = Color(0xFF6B4F72);
  static const Color gradientPurple3 = Color(0xFF5D4E75);

  // Modern text colors
  static const Color modernDark = Color(0xFF2C3E50);
  static const Color modernGray = Color(0xFF7F8C8D);
  static const Color modernLight = Color(0xFF95A5A6);

  // Background colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color inputBackground = Color(0xFFF8F9FA);
  
  // Text colors - All black for visibility
  static const Color primaryText = Colors.black;
  static const Color secondaryText = Colors.black87;
  static const Color hintText = Colors.black54;
  
  // Status colors (matching delivery partner app)
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);

  // Additional consistent colors
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color pending = Color(0xFFFF9800);
  static const Color accepted = Color(0xFF2196F3);
  static const Color delivered = Color(0xFF4CAF50);
  static const Color cancelled = Color(0xFFF44336);
  
  // Text style shortcuts for easy access
  static const Color textPrimary = primaryText;
  static const Color textSecondary = secondaryText;
  
  // Text styles - All black for visibility
  static const TextStyle textSmall = TextStyle(
    fontSize: 12,
    color: Colors.black,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle textMedium = TextStyle(
    fontSize: 14,
    color: Colors.black,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle textLarge = TextStyle(
    fontSize: 16,
    color: Colors.black,
    fontWeight: FontWeight.w600,
  );
  
  // Shadows and elevation
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 1,
    ),
  ];
  
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primaryGreen.withOpacity(0.3),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  // Border radius
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
  static const double chipRadius = 20.0;
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Village-friendly TextStyles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    height: 1.4,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.black,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.black,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
    height: 1.4,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );
  
  static const TextStyle labelText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black,
    height: 1.3,
  );

  // Village-friendly button styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryGreen,
    foregroundColor: Colors.white,
    elevation: 2,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    ),
    textStyle: buttonText,
  );
  
  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryGreen,
    side: const BorderSide(color: primaryGreen, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    ),
    textStyle: buttonText.copyWith(color: primaryGreen),
  );
  
  static ButtonStyle get accentButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: accentOrange,
    foregroundColor: Colors.white,
    elevation: 2,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    ),
    textStyle: buttonText,
  );

  // Input decoration theme - Black text for visibility
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: cardBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
      borderSide: const BorderSide(color: primaryGreen, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
      borderSide: const BorderSide(color: errorRed, width: 2),
    ),
    labelStyle: labelText.copyWith(color: Colors.black),
    hintStyle: bodyMedium.copyWith(color: Colors.black54),
  );

  // Input text style for black text
  static TextStyle get inputTextStyle => const TextStyle(
    color: Colors.black,
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  // Card decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(cardRadius),
    boxShadow: cardShadow,
  );
  
  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(cardRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 12,
        offset: const Offset(0, 4),
        spreadRadius: 2,
      ),
    ],
  );

  // Modern gradients
  static LinearGradient get modernPurpleGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientPurple1, gradientPurple2, gradientPurple3],
  );

  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, Color(0xFF66BB6A)],
  );

  static LinearGradient get accentGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentOrange, warmYellow],
  );

  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightBackground, surfaceColor],
  );

  // Modern card decoration
  static BoxDecoration get modernCardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  // Modern input decoration
  static BoxDecoration get modernInputDecoration => BoxDecoration(
    color: inputBackground,
    borderRadius: BorderRadius.circular(12),
  );

  // Icon sizes for village-friendly UI
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  static const double iconHuge = 64.0;

  // Village category colors for visual recognition
  static const Map<String, Color> categoryColors = {
    'grocery': Color(0xFF4CAF50),      // Green for vegetables/groceries
    'medical': Color(0xFFF44336),      // Red for medical/pharmacy
    'electronics': Color(0xFF2196F3),  // Blue for electronics
    'clothing': Color(0xFF9C27B0),     // Purple for clothing
    'food': Color(0xFFFF9800),         // Orange for food/restaurants
    'services': Color(0xFF607D8B),     // Grey for services
    'default': primaryGreen,
  };

  // Status indicator colors
  static const Map<String, Color> statusColors = {
    'pending': warningOrange,
    'confirmed': infoBlue,
    'preparing': Color(0xFF9C27B0), // Purple
    'ready': Color(0xFF00BCD4),     // Teal
    'out_for_delivery': Color(0xFF3F51B5), // Indigo
    'delivered': successGreen,
    'cancelled': errorRed,
    'default': Colors.grey,
  };
}

// Modern helper widgets
class VillageWidgets {
  // Modern screen wrapper with gradient background
  static Widget modernScreenWrapper({
    required Widget child,
    bool hasBackButton = false,
  }) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: VillageTheme.modernPurpleGradient,
        ),
        child: SafeArea(
          child: hasBackButton
              ? Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(Navigator.of(child as BuildContext).context).pop(),
                        ),
                      ),
                    ),
                    Expanded(child: child),
                  ],
                )
              : child,
        ),
      ),
    );
  }

  // Modern card container
  static Widget modernCard({
    required Widget child,
    EdgeInsets? margin,
    EdgeInsets? padding,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(24.0),
      padding: padding ?? const EdgeInsets.all(32.0),
      decoration: VillageTheme.modernCardDecoration,
      child: child,
    );
  }

  // Modern input field
  static Widget modernInput({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return Container(
      decoration: VillageTheme.modernInputDecoration,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: Colors.black54,
                  size: 20,
                )
              : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // Large touch-friendly button
  static Widget bigButton({
    required String text,
    required VoidCallback onPressed,
    required IconData icon,
    Color? backgroundColor,
    Color? textColor,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: backgroundColor ?? VillageTheme.primaryGreen,
        borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
        boxShadow: VillageTheme.buttonShadow,
      ),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading 
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor ?? Colors.white,
                ),
              ),
            )
          : Icon(icon, size: VillageTheme.iconMedium),
        label: Text(
          text,
          style: VillageTheme.buttonText.copyWith(
            color: textColor ?? Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? VillageTheme.primaryGreen,
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // Image-based category card
  static Widget categoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? backgroundColor,
    String? imageUrl,
  }) {
    return Container(
      decoration: VillageTheme.cardDecoration,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VillageTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(VillageTheme.spacingM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: VillageTheme.iconHuge,
                height: VillageTheme.iconHuge,
                decoration: BoxDecoration(
                  color: (backgroundColor ?? VillageTheme.primaryGreen).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(VillageTheme.cardRadius),
                ),
                child: Icon(
                  icon,
                  size: VillageTheme.iconLarge,
                  color: backgroundColor ?? VillageTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: VillageTheme.spacingS),
              Text(
                title,
                style: VillageTheme.headingSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: VillageTheme.spacingXS),
              Text(
                subtitle,
                style: VillageTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Status chip with color coding
  static Widget statusChip({
    required String status,
    required String text,
  }) {
    final color = VillageTheme.statusColors[status.toLowerCase()] ?? 
                  VillageTheme.statusColors['default']!;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VillageTheme.spacingS,
        vertical: VillageTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(VillageTheme.chipRadius),
      ),
      child: Text(
        text,
        style: VillageTheme.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}