import 'package:flutter/material.dart';

class AppThemes {
  /// Unix‐style Dark Theme: pure black + neon green accents, mono font.
  static final ThemeData unixDark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: const Color(0xFF00FF00),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00FF00),
      secondary: Color(0xFF00FF00),
      surface: Colors.black,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Color(0xFF00FF00),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Color(0xFF00FF00),
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'RobotoMono',
        color: Color(0xFF00FF00),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontFamily: 'RobotoMono',
        color: Color(0xFF00FF00),
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'RobotoMono',
        color: Color(0xFF00FF00),
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'RobotoMono',
        color: Color(0xFF00FF00),
        fontSize: 14,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00FF00),
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontFamily: 'RobotoMono'),
      ),
    ),
  );

  /// Futuristic Light Theme: off-white background + electric blue & silver.
  static final ThemeData neoLight = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    primaryColor: const Color(0xFF00FFFF),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF00FFFF),
      secondary: Color(0xFFC0C0C0),
      surface: Colors.white,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF00FFFF),
      foregroundColor: Colors.black,
      elevation: 4,
      titleTextStyle: TextStyle(
        fontFamily: 'RobotoMono',
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontFamily: 'RobotoMono',
        color: Colors.black,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'RobotoMono',
        color: Colors.black87,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'RobotoMono',
        color: Colors.black87,
        fontSize: 14,
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00FFFF),
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontFamily: 'RobotoMono'),
      ),
    ),
  );

  /// Helpers to pick the active theme
  static ThemeData get lightTheme => neoLight;
  static ThemeData get darkTheme  => unixDark;
}
