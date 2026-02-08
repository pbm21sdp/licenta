import 'package:flutter/material.dart';

/// Helper function to create TextStyle with SF Pro-like font (system default on iOS/Android)
TextStyle _textStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  double letterSpacing = 0,
  double? height,
}) {
  return TextStyle(
    fontFamily: '.SF Pro Text', // iOS system font, falls back to Roboto on Android
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

/// A class that contains all theme configurations for the pet adoption application.
/// Implements Minimalist Sage design with iOS-inspired aesthetics.
class AppTheme {
  AppTheme._();

  // Color Specifications - Soft Rose & Taupe Palette
  static const Color primaryLight = Color(0xFFE8B8C8); // Soft rose pink
  static const Color primaryVariantLight = Color(0xFFD4A0B0); // Deeper rose
  static const Color secondaryLight = Color(0xFF8A8587); // Grey taupe
  static const Color accentLight = Color(0xFFFF6B6B); // Warm coral for favorites
  static const Color successLight = Color(0xFF22C55E); // Green for confirmations
  static const Color warningLight = Color(0xFFFBBF24); // Amber for notices
  static const Color errorLight = Color(0xFFEF4444); // Red for validation
  static const Color backgroundLight = Color(0xFFF2F2F7); // iOS style background
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure white for cards
  static const Color textPrimaryLight = Color(0xFF000000); // Black for high contrast
  static const Color textSecondaryLight = Color(0xFF3C3C43); // iOS secondary label - darker gray
  static const Color borderLight = Color(0xFFE5E5EA); // iOS style border
  static const Color onPrimaryLight = Color(0xFF3C2A33); // Dark contrast on light pink
  static const Color onSecondaryLight = Color(0xFFFFFFFF); // White on grey taupe
  static const Color onBackgroundLight = Color(0xFF000000);
  static const Color onSurfaceLight = Color(0xFF000000);
  static const Color onErrorLight = Color(0xFFFFFFFF);

  // Dark theme colors - Soft Rose & Taupe (Dark Mode)
  static const Color primaryDark = Color(0xFFF0D0DC); // Lighter rose for dark mode
  static const Color primaryVariantDark = Color(0xFFE8B8C8);
  static const Color secondaryDark = Color(0xFFB0ADAF); // Lighter grey taupe
  static const Color accentDark = Color(0xFFFF8E8E); // Adjusted coral for dark mode
  static const Color successDark = Color(0xFF4ADE80);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color errorDark = Color(0xFFF87171);
  static const Color backgroundDark = Color(0xFF000000); // True black
  static const Color surfaceDark = Color(0xFF1C1C1E); // iOS dark surface
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8E8E93);
  static const Color borderDark = Color(0xFF38383A); // iOS dark border
  static const Color onPrimaryDark = Color(0xFF000000);
  static const Color onSecondaryDark = Color(0xFF000000);
  static const Color onBackgroundDark = Color(0xFFFFFFFF);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFF000000);

  // Shadow colors - Minimal Elevation Strategy (2-4dp with 0.08-0.12 opacity)
  static const Color shadowLight = Color(0x1F2C3E50); // 0.12 opacity
  static const Color shadowDark = Color(0x1FFFFFFF);

  // Divider colors - Spatial Definition Philosophy (0.1-0.2 opacity)
  static final Color dividerLight = primaryLight.withValues(alpha: 0.15);
  static final Color dividerDark = primaryDark.withValues(alpha: 0.15);

  // Text emphasis colors - full opacity for better visibility
  static final Color textHighEmphasisLight = textPrimaryLight; // Pure black
  static final Color textMediumEmphasisLight = Color(0xFF3C3C43); // iOS secondary label
  static final Color textDisabledLight = Color(0xFFC7C7CC); // iOS disabled

  static final Color textHighEmphasisDark = textPrimaryDark; // Pure white
  static final Color textMediumEmphasisDark = Color(0xFFEBEBF5); // iOS dark secondary
  static final Color textDisabledDark = Color(0xFF48484A); // iOS dark disabled

  /// Light theme - Contemporary Warmth Minimalism
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryLight,
      onPrimary: onPrimaryLight,
      primaryContainer: primaryVariantLight,
      onPrimaryContainer: onPrimaryLight,
      secondary: accentLight,
      onSecondary: onPrimaryLight,
      secondaryContainer: accentLight.withValues(alpha: 0.2),
      onSecondaryContainer: textPrimaryLight,
      tertiary: successLight,
      onTertiary: onPrimaryLight,
      tertiaryContainer: successLight.withValues(alpha: 0.2),
      onTertiaryContainer: textPrimaryLight,
      error: errorLight,
      onError: onErrorLight,
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      onSurfaceVariant: textSecondaryLight,
      outline: borderLight,
      outlineVariant: dividerLight,
      shadow: shadowLight,
      scrim: shadowLight,
      inverseSurface: surfaceDark,
      onInverseSurface: onSurfaceDark,
      inversePrimary: primaryDark,
    ),
    scaffoldBackgroundColor: backgroundLight,
    cardColor: surfaceLight,
    dividerColor: dividerLight,

    // AppBar Theme - Clean and minimal
    appBarTheme: AppBarThemeData(
      backgroundColor: surfaceLight,
      foregroundColor: textPrimaryLight,
      elevation: 0,
      shadowColor: shadowLight,
      centerTitle: true,
      titleTextStyle: _textStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        letterSpacing: 0.15,
      ),
      iconTheme: IconThemeData(color: textPrimaryLight),
    ),

    // Card Theme - Minimal elevation with subtle shadows
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 2.0,
      shadowColor: shadowLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Bottom Navigation Bar Theme - Thumb-accessible design
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: primaryLight,
      unselectedItemColor: textSecondaryLight,
      selectedLabelStyle: _textStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: _textStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    // Floating Action Button Theme - Contextual undo functionality
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentLight,
      foregroundColor: onPrimaryLight,
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    ),

    // Elevated Button Theme - Primary actions
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: onPrimaryLight,
        backgroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 2.0,
        shadowColor: shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: _textStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Outlined Button Theme - Secondary actions
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: BorderSide(color: primaryLight, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: _textStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Text Button Theme - Tertiary actions
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: _textStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Text Theme - Typography Standards
    textTheme: _buildTextTheme(isLight: true),

    // Input Decoration Theme - Form elements with focused states
    inputDecorationTheme: InputDecorationThemeData(
      fillColor: surfaceLight,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: borderLight, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: borderLight, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: primaryLight, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorLight, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorLight, width: 2.0),
      ),
      labelStyle: _textStyle(
        color: textSecondaryLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: _textStyle(
        color: textDisabledLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: _textStyle(
        color: errorLight,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight;
        }
        return textSecondaryLight;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight.withValues(alpha: 0.5);
        }
        return borderLight;
      }),
    ),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(onPrimaryLight),
      side: BorderSide(color: borderLight, width: 1.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
    ),

    // Radio Theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight;
        }
        return textSecondaryLight;
      }),
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryLight,
      linearTrackColor: borderLight,
      circularTrackColor: borderLight,
    ),

    // Slider Theme
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryLight,
      thumbColor: primaryLight,
      overlayColor: primaryLight.withValues(alpha: 0.2),
      inactiveTrackColor: borderLight,
      valueIndicatorColor: primaryLight,
      valueIndicatorTextStyle: _textStyle(
        color: onPrimaryLight,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Tab Bar Theme
    tabBarTheme: TabBarThemeData(
      labelColor: primaryLight,
      unselectedLabelColor: textSecondaryLight,
      indicatorColor: primaryLight,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: _textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      unselectedLabelStyle: _textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
    ),

    // Tooltip Theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: textPrimaryLight.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: _textStyle(
        color: surfaceLight,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // SnackBar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimaryLight,
      contentTextStyle: _textStyle(
        color: surfaceLight,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: accentLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4.0,
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceLight,
      elevation: 8.0,
      shadowColor: shadowLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      titleTextStyle: _textStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
      ),
      contentTextStyle: _textStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textSecondaryLight,
      ),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: secondaryLight,
      selectedColor: primaryLight.withValues(alpha: 0.2),
      disabledColor: borderLight,
      labelStyle: _textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimaryLight,
      ),
      secondaryLabelStyle: _textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onPrimaryLight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),
  );

  /// Dark theme - Contemporary Warmth Minimalism (Dark Mode)
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: onPrimaryDark,
      primaryContainer: primaryVariantDark,
      onPrimaryContainer: onPrimaryDark,
      secondary: accentDark,
      onSecondary: onPrimaryDark,
      secondaryContainer: accentDark.withValues(alpha: 0.2),
      onSecondaryContainer: textPrimaryDark,
      tertiary: successDark,
      onTertiary: onPrimaryDark,
      tertiaryContainer: successDark.withValues(alpha: 0.2),
      onTertiaryContainer: textPrimaryDark,
      error: errorDark,
      onError: onErrorDark,
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      onSurfaceVariant: textSecondaryDark,
      outline: borderDark,
      outlineVariant: dividerDark,
      shadow: shadowDark,
      scrim: shadowDark,
      inverseSurface: surfaceLight,
      onInverseSurface: onSurfaceLight,
      inversePrimary: primaryLight,
    ),
    scaffoldBackgroundColor: backgroundDark,
    cardColor: surfaceDark,
    dividerColor: dividerDark,

    appBarTheme: AppBarThemeData(
      backgroundColor: surfaceDark,
      foregroundColor: textPrimaryDark,
      elevation: 0,
      shadowColor: shadowDark,
      centerTitle: true,
      titleTextStyle: _textStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
        letterSpacing: 0.15,
      ),
      iconTheme: IconThemeData(color: textPrimaryDark),
    ),

    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 2.0,
      shadowColor: shadowDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: primaryDark,
      unselectedItemColor: textSecondaryDark,
      selectedLabelStyle: _textStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: _textStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentDark,
      foregroundColor: onPrimaryDark,
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: onPrimaryDark,
        backgroundColor: primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 2.0,
        shadowColor: shadowDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: _textStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: BorderSide(color: primaryDark, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: _textStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: _textStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),

    textTheme: _buildTextTheme(isLight: false),

    inputDecorationTheme: InputDecorationThemeData(
      fillColor: surfaceDark,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: borderDark, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: borderDark, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: primaryDark, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorDark, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: errorDark, width: 2.0),
      ),
      labelStyle: _textStyle(
        color: textSecondaryDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: _textStyle(
        color: textDisabledDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: _textStyle(
        color: errorDark,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark;
        }
        return textSecondaryDark;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark.withValues(alpha: 0.5);
        }
        return borderDark;
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(onPrimaryDark),
      side: BorderSide(color: borderDark, width: 1.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark;
        }
        return textSecondaryDark;
      }),
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryDark,
      linearTrackColor: borderDark,
      circularTrackColor: borderDark,
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: primaryDark,
      thumbColor: primaryDark,
      overlayColor: primaryDark.withValues(alpha: 0.2),
      inactiveTrackColor: borderDark,
      valueIndicatorColor: primaryDark,
      valueIndicatorTextStyle: _textStyle(
        color: onPrimaryDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: primaryDark,
      unselectedLabelColor: textSecondaryDark,
      indicatorColor: primaryDark,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: _textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      unselectedLabelStyle: _textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: textPrimaryDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: _textStyle(
        color: surfaceDark,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimaryDark,
      contentTextStyle: _textStyle(
        color: surfaceDark,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: accentDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4.0,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: surfaceDark,
      elevation: 8.0,
      shadowColor: shadowDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      titleTextStyle: _textStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
      ),
      contentTextStyle: _textStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textSecondaryDark,
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: secondaryDark,
      selectedColor: primaryDark.withValues(alpha: 0.2),
      disabledColor: borderDark,
      labelStyle: _textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimaryDark,
      ),
      secondaryLabelStyle: _textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onPrimaryDark,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),
  );

  /// Helper method to build text theme based on brightness
  /// Typography Standards: DM Sans (headings, body, labels),
  /// JetBrains Mono (data/monospace)
  static TextTheme _buildTextTheme({required bool isLight}) {
    final Color textHighEmphasis = isLight
        ? textHighEmphasisLight
        : textHighEmphasisDark;
    final Color textMediumEmphasis = isLight
        ? textMediumEmphasisLight
        : textMediumEmphasisDark;
    final Color textDisabled = isLight ? textDisabledLight : textDisabledDark;

    return TextTheme(
      // Display styles - Inter for headings
      displayLarge: _textStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: -0.25,
      ),
      displayMedium: _textStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),
      displaySmall: _textStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),

      // Headline styles - Inter for headings
      headlineLarge: _textStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),
      headlineMedium: _textStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),
      headlineSmall: _textStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),

      // Title styles - Inter for headings
      titleLarge: _textStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textHighEmphasis,
        letterSpacing: 0,
      ),
      titleMedium: _textStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0.15,
      ),
      titleSmall: _textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0.1,
      ),

      // Body styles - Inter (replacing Source Sans Pro)
      bodyLarge: _textStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0.5,
        height: 1.5,
      ),
      bodyMedium: _textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: _textStyle(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        color: textMediumEmphasis,
        letterSpacing: 0.4,
        height: 1.33,
      ),

      // Label styles - Roboto for captions
      labelLarge: _textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
        letterSpacing: 0.1,
      ),
      labelMedium: _textStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMediumEmphasis,
        letterSpacing: 0.5,
      ),
      labelSmall: _textStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textDisabled,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Helper method to get monospace text style for data display
  /// Uses system monospace font for ages, IDs, and structured information
  static TextStyle getMonospaceStyle({
    required bool isLight,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    final Color textColor = isLight ? textPrimaryLight : textPrimaryDark;
    return TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: textColor,
      letterSpacing: 0,
    );
  }
}
