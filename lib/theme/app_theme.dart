import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const primary = Color(0xFF0B1F3B);
    const accent = Color(0xFF1D4ED8);
    const error = Color(0xFFDC2626);
    const surface = Colors.white;
    const gray = Color(0xFF6B7280);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      error: error,
      surface: surface,
      onSurface: Colors.black87,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: gray),
      ),
      useMaterial3: true,
    );
  }
}

