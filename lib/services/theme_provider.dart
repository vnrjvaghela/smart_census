import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePrefKey = 'theme_preference';
  
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTheme = prefs.getString(_themePrefKey);
    
    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      prefs.setString(_themePrefKey, 'light');
    } else if (mode == ThemeMode.dark) {
      prefs.setString(_themePrefKey, 'dark');
    } else {
      prefs.setString(_themePrefKey, 'system');
    }
  }
}
