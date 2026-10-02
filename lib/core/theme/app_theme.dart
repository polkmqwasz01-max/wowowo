import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color accentColor = Color(0xFF00E676);

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D0F12),
      cardColor: const Color(0xFF191D23),
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: Color(0xFF15181D),
      ),
      dividerColor: const Color(0xFF2A3038),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D0F12),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F7F9),
      cardColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00A85A),
        secondary: Color(0xFF00A85A),
        surface: Colors.white,
      ),
      dividerColor: const Color(0xFFE1E5E9),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F7F9),
        foregroundColor: Color(0xFF121212),
        elevation: 0,
      ),
    );
  }
}
