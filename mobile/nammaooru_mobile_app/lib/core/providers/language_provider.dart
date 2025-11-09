import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  bool _showTamil = false;
  static const String _keyShowTamil = 'show_tamil';

  bool get showTamil => _showTamil;

  LanguageProvider() {
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showTamil = prefs.getBool(_keyShowTamil) ?? false;
      notifyListeners();
    } catch (e) {
      print('Error loading language preference: $e');
    }
  }

  Future<void> toggleLanguage() async {
    _showTamil = !_showTamil;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowTamil, _showTamil);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  String getProductName(dynamic product) {
    if (product == null) return '';

    if (_showTamil && product['nameTamil'] != null && product['nameTamil'].toString().isNotEmpty) {
      return product['nameTamil'];
    }

    return product['name'] ?? '';
  }
}
