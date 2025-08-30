import 'package:flutter/material.dart';
import '../utils/theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  // Mudar para tema claro
  void setLightTheme() {
    _themeMode = ThemeMode.light;
    _isDarkMode = false;
    notifyListeners();
  }

  // Mudar para tema escuro
  void setDarkTheme() {
    _themeMode = ThemeMode.dark;
    _isDarkMode = true;
    notifyListeners();
  }

  // Mudar para tema do sistema
  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    _isDarkMode = false;
    notifyListeners();
  }

  // Alternar entre claro e escuro
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setDarkTheme();
    } else {
      setLightTheme();
    }
  }

  // Obter tema atual
  ThemeData getCurrentTheme() {
    switch (_themeMode) {
      case ThemeMode.light:
        return AppTheme.lightTheme;
      case ThemeMode.dark:
        return AppTheme.darkTheme;
      case ThemeMode.system:
        return AppTheme.lightTheme; // Fallback
    }
  }
}
