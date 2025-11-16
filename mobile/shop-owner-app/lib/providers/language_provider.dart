import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';
  bool _showTamil = false;
  static const String _keyShowTamil = 'show_tamil';
  static const String _keyCurrentLanguage = 'current_language';

  String get currentLanguage => _currentLanguage;
  bool get showTamil => _showTamil;

  LanguageProvider() {
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showTamil = prefs.getBool(_keyShowTamil) ?? false;
      _currentLanguage = prefs.getString(_keyCurrentLanguage) ?? 'en';

      // Sync showTamil with currentLanguage
      if (_currentLanguage == 'ta') {
        _showTamil = true;
      }

      notifyListeners();
    } catch (e) {
      print('Error loading language preference: $e');
    }
  }

  Future<void> toggleLanguage() async {
    _showTamil = !_showTamil;
    _currentLanguage = _showTamil ? 'ta' : 'en';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowTamil, _showTamil);
      await prefs.setString(_keyCurrentLanguage, _currentLanguage);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  void setLanguage(String language) {
    _currentLanguage = language;
    _showTamil = language == 'ta';
    notifyListeners();

    // Save to preferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_keyCurrentLanguage, language);
      prefs.setBool(_keyShowTamil, _showTamil);
    });
  }

  // Get localized text based on current language
  String getText(String englishText, String tamilText) {
    return _currentLanguage == 'ta' ? tamilText : englishText;
  }

  // Get product name based on language preference
  String getProductName(dynamic product) {
    if (product == null) return '';

    // Handle Product class objects (strongly typed)
    if (product is Object && product.runtimeType.toString().contains('Product')) {
      // Access via reflection-like approach
      try {
        final name = (product as dynamic).name;
        final nameTamil = (product as dynamic).nameTamil;

        if (_showTamil && nameTamil != null && nameTamil.toString().isNotEmpty) {
          return nameTamil;
        }
        return name ?? '';
      } catch (e) {
        // Fallback to name if reflection fails
        return (product as dynamic).name ?? '';
      }
    }

    // Handle nested masterProduct structure (shop products from JSON)
    if (product is Map && product['masterProduct'] != null) {
      if (_showTamil &&
          product['masterProduct']['nameTamil'] != null &&
          product['masterProduct']['nameTamil'].toString().isNotEmpty) {
        return product['masterProduct']['nameTamil'];
      }
      return product['masterProduct']['name'] ?? product['displayName'] ?? '';
    }

    // Handle direct product structure (master products from JSON)
    if (product is Map) {
      if (_showTamil && product['nameTamil'] != null && product['nameTamil'].toString().isNotEmpty) {
        return product['nameTamil'];
      }
      return product['name'] ?? '';
    }

    return '';
  }
}
