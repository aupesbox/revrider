// lib/utils/themes.dart

import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurpleAccent,
      brightness: Brightness.light,
    ),

    // Basic text + AppBar + Button + Slider styling
    textTheme: ThemeData.light().textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: Colors.deepPurple,
      inactiveTrackColor: Colors.deepPurple.shade100,
      thumbColor: Colors.deepPurpleAccent,
      overlayColor: Colors.deepPurpleAccent.withOpacity(0.2),
    ),
    iconTheme: const IconThemeData(color: Colors.deepPurpleAccent),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.tealAccent,
      brightness: Brightness.dark,
    ),

    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: Colors.greenAccent,
      displayColor: Colors.greenAccent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      foregroundColor: Colors.greenAccent,
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: Colors.greenAccent,
      inactiveTrackColor: Colors.greenAccent.withOpacity(0.3),
      thumbColor: Colors.greenAccent,
      overlayColor: Colors.greenAccent.withOpacity(0.2),
    ),
    iconTheme: const IconThemeData(color: Colors.greenAccent),
  );
}
