import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// The app's single source of visual truth: two [ThemeData] objects (light and
/// dark) built from one [ColorScheme] each, plus shared component styling and a
/// tuned type scale. Widgets should pull colours/sizes from `Theme.of(context)`
/// and never hard-code them.
abstract final class AppTheme {
  static ThemeData get light => _build(_lightScheme, AppColors.light, Brightness.light);
  static ThemeData get dark => _build(_darkScheme, AppColors.dark, Brightness.dark);

  // --- Colour schemes -------------------------------------------------------

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF4F6CF7),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE4E9FF),
    onPrimaryContainer: Color(0xFF14235C),
    secondary: Color(0xFF0FB981),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD7F5EA),
    onSecondaryContainer: Color(0xFF063D2C),
    tertiary: Color(0xFF7C5CFC),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFEBE4FF),
    onTertiaryContainer: Color(0xFF2A1A66),
    error: Color(0xFFE5484D),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFCE9E9),
    onErrorContainer: Color(0xFF5B1212),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1B1F2A),
    onSurfaceVariant: Color(0xFF5B6478),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F8FC),
    surfaceContainer: Color(0xFFF1F3FA),
    surfaceContainerHigh: Color(0xFFEAEEF6),
    surfaceContainerHighest: Color(0xFFE3E8F2),
    outline: Color(0xFFD3D9E6),
    outlineVariant: Color(0xFFE7EBF3),
    shadow: Color(0xFF0B1020),
    scrim: Color(0xFF0B1020),
    inverseSurface: Color(0xFF2B303C),
    onInverseSurface: Color(0xFFF1F3FA),
    inversePrimary: Color(0xFFB9C4FF),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF9DB0FF),
    onPrimary: Color(0xFF10205C),
    primaryContainer: Color(0xFF2A3A8F),
    onPrimaryContainer: Color(0xFFDCE3FF),
    secondary: Color(0xFF5FE0B5),
    onSecondary: Color(0xFF00382A),
    secondaryContainer: Color(0xFF0C4C39),
    onSecondaryContainer: Color(0xFFC6F5E5),
    tertiary: Color(0xFFC3B0FF),
    onTertiary: Color(0xFF2A1A66),
    tertiaryContainer: Color(0xFF433191),
    onTertiaryContainer: Color(0xFFEBE4FF),
    error: Color(0xFFFF6B6E),
    onError: Color(0xFF5B1212),
    errorContainer: Color(0xFF5B1A1C),
    onErrorContainer: Color(0xFFFFD9DA),
    surface: Color(0xFF0E1117),
    onSurface: Color(0xFFE6E9F0),
    onSurfaceVariant: Color(0xFF9AA3B2),
    surfaceContainerLowest: Color(0xFF0B0E13),
    surfaceContainerLow: Color(0xFF141821),
    surfaceContainer: Color(0xFF161A22),
    surfaceContainerHigh: Color(0xFF1E232D),
    surfaceContainerHighest: Color(0xFF272D39),
    outline: Color(0xFF2C333F),
    outlineVariant: Color(0xFF232935),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE6E9F0),
    onInverseSurface: Color(0xFF161A22),
    inversePrimary: Color(0xFF4F6CF7),
  );

  // --- Assembly -----------------------------------------------------------

  static ThemeData _build(
    ColorScheme scheme,
    AppColors appColors,
    Brightness brightness,
  ) {
    final TextTheme text = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? scheme.surfaceContainerLow
          : scheme.surface,
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[appColors],
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge,
        foregroundColor: scheme.onSurface,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.allLg,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? scheme.surfaceContainerLow
            : scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          textStyle: text.titleMedium,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: text.labelLarge,
          foregroundColor: scheme.primary,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }

  /// One tuned type scale for the whole app. Tighter letter-spacing on the big
  /// numbers, comfortable line height on body copy.
  static TextTheme _textTheme(ColorScheme scheme) {
    final Color base = scheme.onSurface;
    final Color muted = scheme.onSurfaceVariant;
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 36,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: base,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: base,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: base,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: base,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: base),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: base),
      bodySmall: TextStyle(fontSize: 12.5, height: 1.4, color: muted),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: muted,
      ),
    );
  }
}
