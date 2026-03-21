import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _selectedLanguage = 'en';

  bool get isDarkMode => _isDarkMode;
  String get selectedLanguage => _selectedLanguage;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }
}