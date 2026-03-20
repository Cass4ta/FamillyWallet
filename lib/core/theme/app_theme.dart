import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgDark = Color(0xFF0D0D0D);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color cardDark = Color(0xFF252525);
  static const Color primaryLight = Color(0xFF1A237E);
  static const Color accent = Color(0xFF00C853);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFC107);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryLight,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        secondary: accent,
        surface: surfaceDark,
        error: error,
      ),
      appBarTheme: const AppBarTheme(backgroundColor: surfaceDark, elevation: 0),
    );
  }

  static ThemeData get lightTheme => ThemeData.light();
}
