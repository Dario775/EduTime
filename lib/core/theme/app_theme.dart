import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// EduTime Design System - Premium Educational Theme
/// 
/// A modern, vibrant design system optimized for focus and productivity.
/// Features adaptive color schemes, glassmorphism, and smooth micro-animations.

class AppTheme {
  AppTheme._();

  // ============================================================
  // COLOR PALETTE - Curated for Educational Focus
  // ============================================================
  
  // Primary Colors - Deep Ocean Blue (Focus & Trust)
  static const Color primaryLight = Color(0xFF4F8CFF);
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color onPrimaryContainer = Color(0xFF1E3A5F);

  // Secondary Colors - Vibrant Coral (Energy & Motivation)
  static const Color secondaryLight = Color(0xFFFF8A80);
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color secondaryDark = Color(0xFFE85555);
  static const Color secondaryContainer = Color(0xFFFFE5E5);
  static const Color onSecondaryContainer = Color(0xFF5C2020);

  // Tertiary Colors - Emerald Green (Success & Growth)
  static const Color tertiaryLight = Color(0xFF6EE7B7);
  static const Color tertiary = Color(0xFF10B981);
  static const Color tertiaryDark = Color(0xFF059669);
  static const Color tertiaryContainer = Color(0xFFD1FAE5);
  static const Color onTertiaryContainer = Color(0xFF064E3B);

  // Accent Colors - Golden Amber (Achievement & Reward)
  static const Color accentLight = Color(0xFFFCD34D);
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentContainer = Color(0xFFFEF3C7);
  static const Color onAccentContainer = Color(0xFF78350F);

  // Neutral Colors
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color surfaceVariantDark = Color(0xFF334155);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ============================================================
  // TYPOGRAPHY - Modern & Readable
  // ============================================================
  
  static const String fontFamily = 'Poppins';

  static const TextTheme textTheme = TextTheme(
    // Display Styles
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 57,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 45,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 36,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.22,
    ),
    
    // Headline Styles
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.33,
    ),
    
    // Title Styles
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.5,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    
    // Body Styles
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
    ),
    
    // Label Styles
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
    ),
  );

  // ============================================================
  // SPACING SYSTEM
  // ============================================================
  
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // ============================================================
  // BORDER RADIUS
  // ============================================================
  
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radius2Xl = 24.0;
  static const double radius3Xl = 32.0;
  static const double radiusFull = 9999.0;

  // ============================================================
  // ELEVATION & SHADOWS
  // ============================================================
  
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 6,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 6),
    ),
  ];

  // Premium Glow Effect
  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.4),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  // ============================================================
  // ANIMATION DURATIONS
  // ============================================================
  
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationVerySlow = Duration(milliseconds: 800);

  // Animation Curves
  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveEmphasized = Curves.easeOutCubic;
  static const Curve curveDecelerate = Curves.decelerate;
  static const Curve curveBounce = Curves.elasticOut;

  // ============================================================
  // THEME DATA - LIGHT MODE
  // ============================================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: Colors.white,
        surface: surfaceLight,
        onSurface: neutral900,
        surfaceContainerHighest: surfaceVariantLight,
        onSurfaceVariant: neutral600,
        outline: neutral300,
        outlineVariant: neutral200,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: backgroundLight,
      
      // Text Theme
      textTheme: textTheme.apply(
        bodyColor: neutral900,
        displayColor: neutral900,
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: backgroundLight,
        foregroundColor: neutral900,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: neutral900),
      ),
      
      // Card
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        color: surfaceLight,
        surfaceTintColor: Colors.transparent,
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: const BorderSide(color: primary, width: 1.5),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariantLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: neutral400),
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariantLight,
        selectedColor: primaryContainer,
        disabledColor: neutral200,
        labelStyle: textTheme.labelMedium?.copyWith(color: neutral700),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing12,
          vertical: spacing8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: surfaceLight,
        selectedItemColor: primary,
        unselectedItemColor: neutral400,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      
      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        indicatorColor: primaryContainer,
        elevation: 0,
        height: 80,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: primary,
            );
          }
          return textTheme.labelSmall?.copyWith(color: neutral500);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return IconThemeData(color: neutral500, size: 24);
        }),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: neutral200,
        thickness: 1,
        space: 1,
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primaryContainer,
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return neutral400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return neutral200;
        }),
      ),
      
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXs),
        ),
        side: BorderSide(color: neutral400, width: 1.5),
      ),
      
      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return neutral400;
        }),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: neutral800,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius2Xl),
        ),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceLight,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radius2Xl),
          ),
        ),
        dragHandleColor: neutral300,
        dragHandleSize: const Size(40, 4),
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        titleTextStyle: textTheme.bodyLarge?.copyWith(color: neutral900),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: neutral500),
      ),
    );
  }

  // ============================================================
  // THEME DATA - DARK MODE
  // ============================================================
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        onPrimary: neutral900,
        primaryContainer: primaryDark,
        onPrimaryContainer: primaryContainer,
        secondary: secondaryLight,
        onSecondary: neutral900,
        secondaryContainer: secondaryDark,
        onSecondaryContainer: secondaryContainer,
        tertiary: tertiaryLight,
        onTertiary: neutral900,
        tertiaryContainer: tertiaryDark,
        onTertiaryContainer: tertiaryContainer,
        error: Color(0xFFFF8A80),
        onError: neutral900,
        surface: surfaceDark,
        onSurface: neutral100,
        surfaceContainerHighest: surfaceVariantDark,
        onSurfaceVariant: neutral400,
        outline: neutral600,
        outlineVariant: neutral700,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: backgroundDark,
      
      // Text Theme
      textTheme: textTheme.apply(
        bodyColor: neutral100,
        displayColor: neutral100,
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: backgroundDark,
        foregroundColor: neutral100,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: neutral100),
      ),
      
      // Card
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        color: surfaceDark,
        surfaceTintColor: Colors.transparent,
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryLight,
          foregroundColor: neutral900,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: const BorderSide(color: primaryLight, width: 1.5),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: neutral900,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariantDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: neutral500),
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariantDark,
        selectedColor: primaryDark,
        disabledColor: neutral700,
        labelStyle: textTheme.labelMedium?.copyWith(color: neutral200),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing12,
          vertical: spacing8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: surfaceDark,
        selectedItemColor: primaryLight,
        unselectedItemColor: neutral500,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      
      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: primaryDark,
        elevation: 0,
        height: 80,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: primaryLight,
            );
          }
          return textTheme.labelSmall?.copyWith(color: neutral400);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryLight, size: 24);
          }
          return IconThemeData(color: neutral500, size: 24);
        }),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: neutral700,
        thickness: 1,
        space: 1,
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryLight,
        linearTrackColor: primaryDark,
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return neutral900;
          }
          return neutral500;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight;
          }
          return neutral700;
        }),
      ),
      
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(neutral900),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXs),
        ),
        side: BorderSide(color: neutral500, width: 1.5),
      ),
      
      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight;
          }
          return neutral500;
        }),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: neutral200,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: neutral900),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius2Xl),
        ),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceDark,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radius2Xl),
          ),
        ),
        dragHandleColor: neutral600,
        dragHandleSize: const Size(40, 4),
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        titleTextStyle: textTheme.bodyLarge?.copyWith(color: neutral100),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: neutral400),
      ),
    );
  }
}

/// Extension for easy access to custom colors from BuildContext
extension ThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  
  // Semantic colors
  Color get successColor => AppTheme.success;
  Color get warningColor => AppTheme.warning;
  Color get errorColor => AppTheme.error;
  Color get infoColor => AppTheme.info;
}

// ============================================================
// CONVENIENCE CLASSES FOR COMPONENT USE
// ============================================================

/// AppColors - Convenience class for accessing colors
/// 
/// These map to the AppTheme colors for easier use in components.
class AppColors {
  AppColors._();
  
  // Primary
  static const Color primary = AppTheme.primary;
  static const Color primaryDark = AppTheme.primaryDark;
  static const Color primaryLight = AppTheme.primaryLight;
  static const Color primarySurface = AppTheme.primaryContainer;
  
  // Secondary
  static const Color secondary = AppTheme.secondary;
  static const Color accent = AppTheme.accent;
  static const Color secondarySurface = AppTheme.secondaryContainer;
  
  // Semantic
  static const Color success = AppTheme.success;
  static const Color successLight = AppTheme.tertiaryContainer;
  static const Color warning = AppTheme.warning;
  static const Color warningLight = AppTheme.accentContainer;
  static const Color error = AppTheme.error;
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = AppTheme.info;
  
  // Neutrals
  static const Color background = AppTheme.backgroundLight;
  static const Color surface = AppTheme.surfaceLight;
  static const Color surfaceVariant = AppTheme.surfaceVariantLight;
  static const Color border = AppTheme.neutral200;
  static const Color divider = AppTheme.neutral200;
  
  // Text
  static const Color textPrimary = AppTheme.neutral900;
  static const Color textSecondary = AppTheme.neutral500;
  static const Color textTertiary = AppTheme.neutral400;
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  
  // Dark Mode
  static const Color darkBackground = AppTheme.backgroundDark;
  static const Color darkSurface = AppTheme.surfaceDark;
}

/// AppSpacing - Convenience class for accessing spacing values
class AppSpacing {
  AppSpacing._();
  
  // Spacing
  static const double xxs = AppTheme.spacing2;
  static const double xs = AppTheme.spacing4;
  static const double sm = AppTheme.spacing8;
  static const double md = AppTheme.spacing16;
  static const double lg = AppTheme.spacing24;
  static const double xl = AppTheme.spacing32;
  static const double xxl = AppTheme.spacing48;
  static const double xxxl = AppTheme.spacing64;
  
  // Radius
  static const double radiusXs = AppTheme.radiusXs;
  static const double radiusSm = AppTheme.radiusSm;
  static const double radiusMd = AppTheme.radiusMd;
  static const double radiusLg = AppTheme.radiusLg;
  static const double radiusXl = AppTheme.radiusXl;
  static const double radiusFull = AppTheme.radiusFull;
}

/// AppTypography - Convenience class for accessing text styles
class AppTypography {
  AppTypography._();
  
  static TextStyle get displayLarge => AppTheme.textTheme.displayLarge!;
  static TextStyle get displayMedium => AppTheme.textTheme.displayMedium!;
  static TextStyle get displaySmall => AppTheme.textTheme.displaySmall!;
  
  static TextStyle get headlineLarge => AppTheme.textTheme.headlineLarge!;
  static TextStyle get headlineMedium => AppTheme.textTheme.headlineMedium!;
  static TextStyle get headlineSmall => AppTheme.textTheme.headlineSmall!;
  
  static TextStyle get titleLarge => AppTheme.textTheme.titleLarge!;
  static TextStyle get titleMedium => AppTheme.textTheme.titleMedium!;
  static TextStyle get titleSmall => AppTheme.textTheme.titleSmall!;
  
  static TextStyle get labelLarge => AppTheme.textTheme.labelLarge!;
  static TextStyle get labelMedium => AppTheme.textTheme.labelMedium!;
  static TextStyle get labelSmall => AppTheme.textTheme.labelSmall!;
  
  static TextStyle get bodyLarge => AppTheme.textTheme.bodyLarge!;
  static TextStyle get bodyMedium => AppTheme.textTheme.bodyMedium!;
  static TextStyle get bodySmall => AppTheme.textTheme.bodySmall!;
}
