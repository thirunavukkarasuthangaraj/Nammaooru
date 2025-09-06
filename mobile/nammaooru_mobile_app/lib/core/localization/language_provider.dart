import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';
  
  String get currentLanguage => _currentLanguage;
  
  void setLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }
  
  // Get localized text based on current language
  String getText(String englishText, String tamilText) {
    return _currentLanguage == 'ta' ? tamilText : englishText;
  }
  
  // Common app translations
  String get appName => getText('NammaOoru', 'நம்மூரு');
  String get welcome => getText('Welcome!', 'வணக்கம்!');
  String get login => getText('Sign In', 'உள்நுழைய');
  String get register => getText('Create Account', 'கணக்கு உருவாக்க');
  String get email => getText('Email', 'மின்னஞ்சல்');
  String get password => getText('Password', 'கடவுச்சொல்');
  String get firstName => getText('First Name', 'முதல் பெயர்');
  String get lastName => getText('Last Name', 'கடைசி பெயர்');
  String get phone => getText('Phone Number', 'தொலைபேசி எண்');
  String get profile => getText('Profile', 'சுயவிவரம்');
  String get shops => getText('Shops', 'கடைகள்');
  String get cart => getText('Cart', 'வண்டி');
  String get orders => getText('Orders', 'ஆர்டர்கள்');
  String get logout => getText('Logout', 'வெளியேறு');
  String get rememberMe => getText('Remember me', 'நினைவில் வைத்துக்கொள்');
  String get forgotPassword => getText('Forgot Password?', 'கடவுச்சொல் மறந்தீர்களா?');
  String get newToApp => getText('New to NammaOoru?', 'நம்மூருவில் புதிதா?');
  String get alreadyHaveAccount => getText('Already have an account?', 'ஏற்கனவே கணக்கு உள்ளதா?');
  String get termsAndConditions => getText('Terms of Service', 'சேவை விதிமுறைகள்');
  String get privacyPolicy => getText('Privacy Policy', 'தனியுரிமை கொள்கை');
  String get agreeToTerms => getText('I agree to the', 'நான் ஒப்புக்கொள்கிறேன்');
  String get and => getText('and', 'மற்றும்');
}