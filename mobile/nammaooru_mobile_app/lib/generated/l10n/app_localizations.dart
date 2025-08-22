import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta')
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'NammaOoru'**
  String get appTitle;

  /// Welcome message displayed on splash and login
  ///
  /// In en, this message translates to:
  /// **'Welcome to NammaOoru'**
  String get welcomeMessage;

  /// Prompt shown on login screen
  ///
  /// In en, this message translates to:
  /// **'Please login to continue'**
  String get loginPrompt;

  /// Prompt shown on register screen
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get registerPrompt;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Dashboard menu item
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Products menu item
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// Orders menu item
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// Profile menu item
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Cart menu item
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// Tracking menu item
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get tracking;

  /// Inventory menu item
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// Analytics menu item
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// Earnings menu item
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// Add to cart button text
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// Checkout button text
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// Place order button text
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// Accept order button text
  ///
  /// In en, this message translates to:
  /// **'Accept Order'**
  String get acceptOrder;

  /// Reject order button text
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrder;

  /// Mark as ready button text
  ///
  /// In en, this message translates to:
  /// **'Mark as Ready'**
  String get markAsReady;

  /// Start delivery button text
  ///
  /// In en, this message translates to:
  /// **'Start Delivery'**
  String get startDelivery;

  /// Complete delivery button text
  ///
  /// In en, this message translates to:
  /// **'Complete Delivery'**
  String get completeDelivery;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get errorNetwork;

  /// Authentication error message
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please login again.'**
  String get errorAuth;

  /// Location error message
  ///
  /// In en, this message translates to:
  /// **'Unable to get location. Please enable location services.'**
  String get errorLocation;

  /// Generic loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingGeneric;

  /// Loading products message
  ///
  /// In en, this message translates to:
  /// **'Loading products...'**
  String get loadingProducts;

  /// Loading orders message
  ///
  /// In en, this message translates to:
  /// **'Loading orders...'**
  String get loadingOrders;

  /// Getting location message
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get loadingLocation;

  /// Customer role label
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// Shop owner role label
  ///
  /// In en, this message translates to:
  /// **'Shop Owner'**
  String get shopOwner;

  /// Delivery partner role label
  ///
  /// In en, this message translates to:
  /// **'Delivery Partner'**
  String get deliveryPartner;

  /// Order status: pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orderPending;

  /// Order status: confirmed
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get orderConfirmed;

  /// Order status: preparing
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get orderPreparing;

  /// Order status: ready for pickup
  ///
  /// In en, this message translates to:
  /// **'Ready for Pickup'**
  String get orderReadyForPickup;

  /// Order status: out for delivery
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get orderOutForDelivery;

  /// Order status: delivered
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderDelivered;

  /// Order status: cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderCancelled;

  /// Service category: grocery
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get categoryGrocery;

  /// Service category: food
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// Service category: parcel
  ///
  /// In en, this message translates to:
  /// **'Parcel'**
  String get categoryParcel;

  /// Search field hint text
  ///
  /// In en, this message translates to:
  /// **'Search for products, shops...'**
  String get searchHint;

  /// Delivery address label
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get deliverTo;

  /// Today's sales label
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get todaysSales;

  /// Pending orders label
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pendingOrders;

  /// Total products label
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProducts;

  /// Active orders label
  ///
  /// In en, this message translates to:
  /// **'Active Orders'**
  String get activeOrders;

  /// Online status label
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineStatus;

  /// Offline status label
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineStatus;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
