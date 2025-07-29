import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode;
  final Box<bool> _themeBox;

  ThemeProvider(this._themeBox)
      : _isDarkMode = _themeBox.get('isDarkMode', defaultValue: false)!;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _themeBox.put('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}
