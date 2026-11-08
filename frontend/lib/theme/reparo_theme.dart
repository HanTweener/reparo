import 'package:flutter/material.dart';

/// Design tokens derived from taste-skill 'framed-sheet' (seed 1252817679)
/// Canonical specifications defined in docs/DESIGN_SYSTEM.md
class ReparoTheme {
  ReparoTheme._();

  // Color tokens
  static const Color frame = Color(0xFFF9FBFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceRaised = Color(0xFFF4F6F8);
  static const Color stateSelected = Color(0xFFEBEDEE);
  static const Color border = Color(0xFFE8EAEC);
  static const Color rule = Color(0xFFF0F1F2);
  static const Color controlBorder = Color(0xFFCDCED1);
  static const Color textPrimary = Color(0xFF131416);
  static const Color textMuted = Color(0xFF5D5F60);
  static const Color actionPrimary = Color(0xFF1D1F20);
  static const Color accent = Color(0xFF1B6C80);

  // Status tokens
  static const Color statusSuccess = Color(0xFF1E7B4F);
  static const Color statusSuccessBg = Color(0xFFDCFAE5);
  static const Color statusError = Color(0xFFC4242A);
  static const Color statusErrorBg = Color(0xFFFFEDEA);
  static const Color statusWarning = Color(0xFF92400E);
  static const Color statusWarningBg = Color(0xFFFFFBEB);
  static const Color statusNeutral = Color(0xFF353736);
  static const Color statusNeutralBg = Color(0xFFEBEDEE);

  // Font family names
  static const String fontSans = 'IBM Plex Sans';
  static const String fontMono = 'IBM Plex Mono';

  // Radii
  static const double radiusSheet = 16.0;
  static const double radiusPanel = 8.0;
  static const double radiusControl = 6.0;

  // Responsive breakpoints
  static const double breakpointDesktop = 1024.0;
  static const double breakpointTablet = 641.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: frame,
      fontFamily: fontSans,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: actionPrimary,
        onPrimary: surface,
        secondary: accent,
        onSecondary: surface,
        error: statusError,
        onError: surface,
        surface: surface,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: frame,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontSans,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(fontSize: 14, color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: controlBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: controlBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusControl),
          borderSide: const BorderSide(color: statusError, width: 1),
        ),
      ),
    );
  }
}

