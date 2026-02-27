import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Builds Material 3 [ThemeData] from [AppTokens].
///
/// Font families are declared via [AppTokens.fontBody] / [AppTokens.fontDisplay].
/// Call [AppTheme.loadFonts] once at app startup (e.g., in `main()`) to ensure
/// DM Sans and Lora are fetched and cached by google_fonts.
///
/// Usage in [MaterialApp.router]:
/// ```dart
/// theme: AppTheme.light(),
/// darkTheme: AppTheme.dark(),
/// ```
abstract final class AppTheme {
  /// Pre-fetches DM Sans and Lora via google_fonts cache.
  /// Call once in `main()` before `runApp()`.
  static Future<void> loadFonts() async {
    try {
      await GoogleFonts.pendingFonts([
        GoogleFonts.dmSans(),
        GoogleFonts.lora(),
      ]);
    } catch (_) {
      // Best-effort only: app startup must not fail if fonts cannot be fetched.
    }
  }

  /// Light theme — warm cream palette.
  static ThemeData light() => _build(
        brightness: Brightness.light,
        background: AppTokens.lightBackground,
        surface: AppTokens.lightSurface,
        primary: AppTokens.lightPrimary,
        onPrimary: AppTokens.lightOnPrimary,
        secondary: AppTokens.lightSecondary,
        onSecondary: AppTokens.lightOnSecondary,
        onSurface: AppTokens.lightOnSurface,
        outline: AppTokens.lightOutline,
      );

  /// Dark theme — warm brown palette.
  ///
  /// Uses [AppTokens.darkBackground] to avoid cold grey fallback (AC7).
  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        background: AppTokens.darkBackground,
        surface: AppTokens.darkSurface,
        primary: AppTokens.darkPrimary,
        onPrimary: AppTokens.darkOnPrimary,
        secondary: AppTokens.darkSecondary,
        onSecondary: AppTokens.darkOnSecondary,
        onSurface: AppTokens.darkOnSurface,
        outline: AppTokens.darkOutline,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color primary,
    required Color onPrimary,
    required Color secondary,
    required Color onSecondary,
    required Color onSurface,
    required Color outline,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      // Override seed-generated colours with our hand-crafted warm palette.
      surface: surface,
      surfaceContainerLowest: background,
      surfaceContainerHighest: surface,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      onSurface: onSurface,
      outline: outline,
    );

    // Build text theme using font-family names only (no async google_fonts fetch).
    // google_fonts font bytes are pre-loaded via AppTheme.loadFonts() at startup.
    final textTheme = _buildTextTheme(onSurface: onSurface, colorScheme: colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: AppTokens.fontBody,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTokens.cardBorderRadius,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Builds [TextTheme] using token font families without triggering
  /// google_fonts async loading (safe for both production and tests).
  ///
  /// Display styles use [AppTokens.fontDisplay] (Lora); body styles use
  /// [AppTokens.fontBody] (DM Sans) via [ThemeData.fontFamily] inheritance.
  static TextTheme _buildTextTheme({
    required Color onSurface,
    required ColorScheme colorScheme,
  }) {
    const displayFont = AppTokens.fontDisplay;

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
    ).textTheme.copyWith(
          displayLarge: TextStyle(
            fontFamily: displayFont,
            fontSize: 57,
            fontWeight: FontWeight.w400,
            color: onSurface,
          ),
          displayMedium: TextStyle(
            fontFamily: displayFont,
            fontSize: 45,
            fontWeight: FontWeight.w400,
            color: onSurface,
          ),
          displaySmall: TextStyle(
            fontFamily: displayFont,
            fontSize: 36,
            fontWeight: FontWeight.w400,
            color: onSurface,
          ),
        );
  }
}
