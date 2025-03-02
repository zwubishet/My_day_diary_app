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
      surface: Color(0xffcaf0f8),
      onSurface: Colors.black87,
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
  );
}
