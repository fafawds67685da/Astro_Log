import 'package:flutter/material.dart';

class AppTheme {
  static const Color deepSpace = Color(0xFF0B1120);
  static const Color nebulaPurple = Color(0xFF6B4FBB);
  static const Color starBlue = Color(0xFF4A90E2);
  static const Color cosmicPink = Color(0xFFE91E63);
  static const Color starWhite = Color(0xFFF5F5F5);
  static const Color darkSurface = Color(0xFF1A1F2E);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepSpace,
      primaryColor: starBlue,
      colorScheme: const ColorScheme.dark(
        primary: starBlue,
        secondary: nebulaPurple,
        surface: darkSurface,
        background: deepSpace,
        onPrimary: starWhite,
        onSecondary: starWhite,
        onSurface: starWhite,
        onBackground: starWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: starWhite,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: starBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: starBlue,
          foregroundColor: starWhite,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
