import 'package:flutter/material.dart';

const _googleBlue = Color(0xFF4285F4);
const _googleRed = Color(0xFFEA4335);
const _googleYellow = Color(0xFFFBBC04);
const _googleGreen = Color(0xFF34A853);

class GdgTheme {
  GdgTheme._();

  static const googleBlue = _googleBlue;
  static const googleRed = _googleRed;
  static const googleYellow = _googleYellow;
  static const googleGreen = _googleGreen;

  static ThemeData light() {
    final base = ThemeData(
      colorSchemeSeed: _googleBlue,
      useMaterial3: true,
      brightness: Brightness.light,
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'Google Sans',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF202124),
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE8EAED)),
        ),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _googleBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Google Sans',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _googleBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          side: const BorderSide(color: Color(0xFFDADCE0)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Google Sans',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: Colors.white,
        elevation: 2,
        indicatorColor: _googleBlue.withOpacity(0.12),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Google Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: base.colorScheme.onSurface,
          ),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDADCE0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDADCE0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _googleBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
