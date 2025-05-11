import 'package:flutter/material.dart';
import 'package:page/theme/theme_data.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData;
  ThemeMode _themeMode;

  ThemeProvider(ThemeData lightMode)
    : _themeData = ThemeModes().lightMode,
      _themeMode = ThemeMode.light;

  ThemeData get themeData => _themeData;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeData = ThemeModes().darkMode;
      _themeMode = ThemeMode.dark;
    } else {
      _themeData = ThemeModes().lightMode;
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }
}
