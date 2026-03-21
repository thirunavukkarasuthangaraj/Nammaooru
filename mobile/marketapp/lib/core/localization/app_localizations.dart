import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Map<String, String> _localizedStrings = {};

  Future<bool> load() async {
    String jsonString = await rootBundle.loadString('lib/assets/i18n/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  String translate(String key, {List<String>? args}) {
    String text = _localizedStrings[key] ?? key;
    
    if (args != null) {
      for (int i = 0; i < args.length; i++) {
        text = text.replaceAll('{$i}', args[i]);
      }
    }
    
    return text;
  }

  // Common translations with fallbacks
  String get appName => _localizedStrings['app_name'] ?? 'NammaOoru';
  String get welcome => _localizedStrings['welcome'] ?? 'Welcome';
  String get login => _localizedStrings['login'] ?? 'Login';
  String get register => _localizedStrings['register'] ?? 'Register';
  String get shops => _localizedStrings['shops'] ?? 'Shops';
  String get cart => _localizedStrings['cart'] ?? 'Cart';
  String get orders => _localizedStrings['orders'] ?? 'Orders';
  String get profile => _localizedStrings['profile'] ?? 'Profile';
  String get help => _localizedStrings['help'] ?? 'Help';
  String get support => _localizedStrings['support'] ?? 'Support';
  String get search => _localizedStrings['search'] ?? 'Search';
  String get addToCart => _localizedStrings['add_to_cart'] ?? 'Add to Cart';
  String get buyNow => _localizedStrings['buy_now'] ?? 'Buy Now';
  String get checkout => _localizedStrings['checkout'] ?? 'Checkout';
  String get placeOrder => _localizedStrings['place_order'] ?? 'Place Order';
  String get orderPlaced => _localizedStrings['order_placed'] ?? 'Order Placed';
  String get orderHistory => _localizedStrings['order_history'] ?? 'Order History';
  String get trackOrder => _localizedStrings['track_order'] ?? 'Track Order';
  String get cancelOrder => _localizedStrings['cancel_order'] ?? 'Cancel Order';
  String get contactSupport => _localizedStrings['contact_support'] ?? 'Contact Support';
  String get callNow => _localizedStrings['call_now'] ?? 'Call Now';
  String get whatsapp => _localizedStrings['whatsapp'] ?? 'WhatsApp';
  String get email => _localizedStrings['email'] ?? 'Email';
  String get website => _localizedStrings['website'] ?? 'Website';
  String get cashOnDelivery => _localizedStrings['cash_on_delivery'] ?? 'Cash on Delivery';
  String get deliveryAddress => _localizedStrings['delivery_address'] ?? 'Delivery Address';
  String get paymentMethod => _localizedStrings['payment_method'] ?? 'Payment Method';
  String get orderSummary => _localizedStrings['order_summary'] ?? 'Order Summary';
  String get totalAmount => _localizedStrings['total_amount'] ?? 'Total Amount';
  String get deliveryTime => _localizedStrings['delivery_time'] ?? 'Delivery Time';
  String get outForDelivery => _localizedStrings['out_for_delivery'] ?? 'Out for Delivery';
  String get delivered => _localizedStrings['delivered'] ?? 'Delivered';
  String get cancelled => _localizedStrings['cancelled'] ?? 'Cancelled';
  String get pending => _localizedStrings['pending'] ?? 'Pending';
  String get confirmed => _localizedStrings['confirmed'] ?? 'Confirmed';
  String get preparing => _localizedStrings['preparing'] ?? 'Preparing';
  
  // Error messages
  String get errorOccurred => _localizedStrings['error_occurred'] ?? 'An error occurred';
  String get noInternetConnection => _localizedStrings['no_internet_connection'] ?? 'No internet connection';
  String get serverError => _localizedStrings['server_error'] ?? 'Server error';
  String get tryAgain => _localizedStrings['try_again'] ?? 'Try Again';
  
  // Success messages
  String get success => _localizedStrings['success'] ?? 'Success';
  String get itemAddedToCart => _localizedStrings['item_added_to_cart'] ?? 'Item added to cart';
  String get orderPlacedSuccessfully => _localizedStrings['order_placed_successfully'] ?? 'Order placed successfully';
  
  // Village-friendly terms
  String get nearbyShops => _localizedStrings['nearby_shops'] ?? 'Nearby Shops';
  String get localShops => _localizedStrings['local_shops'] ?? 'Local Shops';
  String get villageShops => _localizedStrings['village_shops'] ?? 'Village Shops';
  String get groceryStore => _localizedStrings['grocery_store'] ?? 'Grocery Store';
  String get medicalStore => _localizedStrings['medical_store'] ?? 'Medical Store';
  String get generalStore => _localizedStrings['general_store'] ?? 'General Store';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ta'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Extension method for easy access
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations? get loc => AppLocalizations.of(this);
}