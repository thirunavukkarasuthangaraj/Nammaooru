import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/village_theme.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: VillageTheme.primaryGreen,
      scaffoldBackgroundColor: VillageTheme.lightBackground,
      fontFamily: 'Inter',
      
      // Color scheme for Material 3 with Village colors
      colorScheme: ColorScheme.light(
        primary: VillageTheme.primaryGreen,
        primaryContainer: VillageTheme.lightGreen,
        secondary: VillageTheme.accentOrange,
        surface: VillageTheme.cardBackground,
        surfaceVariant: VillageTheme.surfaceColor,
        background: VillageTheme.lightBackground,
        error: VillageTheme.errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
        onBackground: Colors.black,
        onError: Colors.white,
        outline: VillageTheme.primaryGreen.withOpacity(0.3),
      ),

      // App Bar Theme with Village colors
      appBarTheme: AppBarTheme(
        backgroundColor: VillageTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: VillageTheme.primaryGreen,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: VillageTheme.headingMedium.copyWith(
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: VillageTheme.iconMedium,
        ),
      ),

      // Card Theme with Village styling
      cardTheme: CardTheme(
        color: VillageTheme.cardBackground,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: VillageTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VillageTheme.cardRadius),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),

      // Elevated Button Theme with Village colors
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: VillageTheme.primaryButtonStyle,
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: VillageTheme.secondaryButtonStyle,
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VillageTheme.accentOrange,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
          ),
          textStyle: VillageTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme with Village styling
      inputDecorationTheme: VillageTheme.inputDecorationTheme,

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: VillageTheme.cardBackground,
        selectedItemColor: VillageTheme.primaryGreen,
        unselectedItemColor: Colors.black87,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: VillageTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: VillageTheme.bodySmall,
      ),

      // Chip Theme with Village colors
      chipTheme: ChipThemeData(
        backgroundColor: VillageTheme.surfaceColor,
        selectedColor: VillageTheme.primaryGreen,
        secondarySelectedColor: VillageTheme.lightGreen,
        labelStyle: VillageTheme.bodyMedium,
        secondaryLabelStyle: VillageTheme.bodyMedium.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VillageTheme.chipRadius),
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarTheme(
        labelColor: VillageTheme.primaryGreen,
        unselectedLabelColor: Colors.black87,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: VillageTheme.primaryGreen, width: 3),
        ),
        labelStyle: VillageTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: VillageTheme.bodyMedium,
      ),

      // Text Theme with Village styles
      textTheme: TextTheme(
        displayLarge: VillageTheme.headingLarge,
        displayMedium: VillageTheme.headingMedium,
        displaySmall: VillageTheme.headingSmall,
        headlineLarge: VillageTheme.headingMedium,
        headlineMedium: VillageTheme.headingSmall,
        headlineSmall: VillageTheme.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleLarge: VillageTheme.bodyLarge.copyWith(
          fontWeight: FontWeight.w500,
        ),
        titleMedium: VillageTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
        titleSmall: VillageTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: VillageTheme.bodyLarge,
        bodyMedium: VillageTheme.bodyMedium,
        bodySmall: VillageTheme.bodySmall,
        labelLarge: VillageTheme.labelText,
        labelMedium: VillageTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w500,
        ),
        labelSmall: VillageTheme.bodySmall.copyWith(
          fontSize: 10,
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: VillageTheme.primaryGreen.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),

      // Dialog Theme with Village styling
      dialogTheme: DialogTheme(
        backgroundColor: VillageTheme.cardBackground,
        surfaceTintColor: VillageTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VillageTheme.cardRadius * 2),
        ),
        titleTextStyle: VillageTheme.headingMedium,
        contentTextStyle: VillageTheme.bodyMedium.copyWith(
          color: Colors.black,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: VillageTheme.accentOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: VillageTheme.primaryGreen,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return VillageTheme.primaryGreen;
          }
          return Colors.black87;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return VillageTheme.primaryGreen.withOpacity(0.5);
          }
          return Colors.black54;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return VillageTheme.primaryGreen;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return VillageTheme.primaryGreen;
          }
          return Colors.black87;
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: VillageTheme.primaryGreen,
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Inter',
      
      colorScheme: ColorScheme.dark(
        primary: VillageTheme.primaryGreen,
        primaryContainer: VillageTheme.primaryGreen.withOpacity(0.3),
        secondary: VillageTheme.accentOrange,
        surface: const Color(0xFF1E1E1E),
        surfaceVariant: const Color(0xFF2A2A2A),
        background: const Color(0xFF121212),
        error: VillageTheme.errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFFE1E1E1),
        onBackground: const Color(0xFFE1E1E1),
        onError: Colors.white,
        outline: const Color(0xFF3A3A3A),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: VillageTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: VillageTheme.primaryGreen,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: VillageTheme.headingMedium.copyWith(
          color: Colors.white,
        ),
      ),

      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shadowColor: Colors.black26,
        surfaceTintColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VillageTheme.cardRadius),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VillageTheme.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VillageTheme.buttonRadius),
          ),
          textStyle: VillageTheme.buttonText,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: VillageTheme.primaryGreen,
        unselectedItemColor: const Color(0xFF888888),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: VillageTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: VillageTheme.bodySmall,
      ),

      textTheme: TextTheme(
        displayLarge: VillageTheme.headingLarge.copyWith(
          color: const Color(0xFFE1E1E1),
        ),
        bodyMedium: VillageTheme.bodyMedium.copyWith(
          color: const Color(0xFFE1E1E1),
        ),
        // Add more text styles as needed for dark theme
      ),
    );
  }
}