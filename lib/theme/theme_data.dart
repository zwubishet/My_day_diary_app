import 'package:flutter/material.dart';

class ThemeModes {
  final ThemeData lightMode = ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: Colors.white12,
      onPrimary: Colors.black45,
      secondary: Colors.blueAccent,
      onSecondary: Colors.black,
      error: Colors.red,
      onError: Colors.black,
      surface: const Color(0xffcaf0f8),
      onSurface: Colors.black87,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      bodyMedium: TextStyle(fontSize: 14),
    ),
  );

  final ThemeData darkMode = ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Colors.black26,
      onPrimary: Colors.white54,
      secondary: Colors.blueAccent,
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      surface: Colors.black,
      onSurface: Colors.white70,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      bodyMedium: TextStyle(fontSize: 14),
    ),
  );
}
