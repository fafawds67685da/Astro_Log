import 'package:flutter/material.dart';

class AppTheme {
  // Color palette
  static const Color deepNavy = Color(0xFF0A0E27);
  static const Color spacePurple = Color(0xFF1A1A3E);
  static const Color accentBlue = Color(0xFF4A6FE3);
  static const Color starWhite = Color(0xFFF0F0F5);
  static const Color cosmicPurple = Color(0xFF7B2CBF);

  // Text styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: starWhite,
    letterSpacing: 0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: starWhite,
    letterSpacing: 0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: starWhite,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: starWhite,
    height: 1.5,
  );

  static const TextStyle bodyTextSecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xFFB0B0C0),
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Color(0xFF808090),
  );

  // Theme data
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepNavy,
      primaryColor: accentBlue,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: cosmicPurple,
        surface: spacePurple,
        onPrimary: starWhite,
        onSecondary: starWhite,
        onSurface: starWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: spacePurple,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: heading2,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: spacePurple,
        selectedItemColor: accentBlue,
        unselectedItemColor: Color(0xFF808090),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: const TextTheme(
        displayLarge: heading1,
        displayMedium: heading2,
        displaySmall: heading3,
        bodyLarge: bodyText,
        bodyMedium: bodyTextSecondary,
        bodySmall: caption,
      ),
      cardTheme: CardThemeData(
        color: spacePurple,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
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
