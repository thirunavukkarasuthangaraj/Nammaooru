# 📱 NammaOoru Mobile Apps - Complete Development Guide

## 📋 Overview

This comprehensive guide covers both Flutter mobile applications in the NammaOoru ecosystem:
- **Customer Mobile App** - Shopping and ordering platform
- **Delivery Partner Mobile App** - Delivery management platform

---

## 🏗️ Project Structure

```
mobile/
├── nammaooru_mobile_app/          # Customer Mobile App
│   ├── lib/
│   │   ├── core/                  # Core services and utilities
│   │   │   ├── constants/         # API endpoints, app constants
│   │   │   ├── services/          # HTTP client, storage services
│   │   │   ├── providers/         # State management
│   │   │   └── utils/            # Helper functions
│   │   ├── features/             # Feature-based modules
│   │   │   ├── auth/             # Authentication flow
│   │   │   ├── home/             # Home screen and navigation
│   │   │   ├── shops/            # Shop browsing
│   │   │   ├── products/         # Product catalog
│   │   │   ├── cart/             # Shopping cart
│   │   │   ├── orders/           # Order management
│   │   │   └── profile/          # User profile
│   │   ├── shared/               # Shared components
│   │   │   ├── widgets/          # Reusable UI components
│   │   │   └── models/           # Data models
│   │   └── main.dart             # Application entry point
│   ├── android/                  # Android-specific configuration
│   ├── ios/                      # iOS-specific configuration
│   └── pubspec.yaml              # Flutter dependencies
│
└── nammaooru_delivery_partner/   # Delivery Partner Mobile App
    ├── lib/
    │   ├── core/                 # Core services and utilities
    │   ├── features/             # Feature modules
    │   │   ├── auth/             # Authentication (WhatsApp OTP)
    │   │   ├── dashboard/        # Main dashboard
    │   │   ├── orders/           # Order management
    │   │   ├── earnings/         # Earnings tracking
    │   │   ├── profile/          # Profile management
    │   │   └── analytics/        # Performance analytics
    │   ├── shared/               # Shared components
    │   └── main.dart
    ├── android/
    ├── ios/
    └── pubspec.yaml
```

---

## 🛒 Customer Mobile App

### Current Implementation Status
```
✅ COMPLETED FEATURES:
├─ Authentication System
│  ├─ Email/Phone registration
│  ├─ OTP verification
│  └─ Login/logout functionality
│
├─ Shop Discovery
│  ├─ Browse available shops
│  ├─ Search and filtering
│  └─ Shop details view
│
├─ Product Browsing
│  ├─ Product catalog by shop
│  ├─ Product details view
│  ├─ Category filtering
│  └─ Search functionality
│
├─ Shopping Cart
│  ├─ Add/remove products
│  ├─ Quantity management
│  ├─ Cart persistence
│  └─ Single shop restriction
│
├─ Order Management
│  ├─ Checkout process
│  ├─ Delivery address
│  ├─ Payment method selection
│  └─ Order placement
│
└─ User Profile
   ├─ Profile management
   ├─ Address management
   └─ Order history
```

### API Integration
```dart
// API Configuration
class ApiEndpoints {
  static const String baseUrl = 'https://api.nammaoorudelivary.in/api';
  static const String customerBaseUrl = '$baseUrl/customer';
  
  // Authentication
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  
  // Customer APIs
  static const String shops = '$customerBaseUrl/shops';
  static const String orders = '$customerBaseUrl/orders';
  static String shopProducts(int shopId) => '$customerBaseUrl/shops/$shopId/products';
}
```

### Key Services

**Authentication Service**
```dart
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  Future<AuthResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.login),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _saveToken(data['token']);
      return AuthResponse.fromJson(data);
    }
    throw Exception('Login failed');
  }

  Future<void> sendOtp(String phoneNumber) async {
    await http.post(
      Uri.parse(ApiEndpoints.sendOtp),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'phoneNumber': phoneNumber}),
    );
  }
}
```

**Shop Service**
```dart
class ShopService {
  Future<List<Shop>> getShops() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse(ApiEndpoints.shops),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Shop.fromJson(json)).toList();
    }
    throw Exception('Failed to load shops');
  }

  Future<List<Product>> getShopProducts(int shopId) async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse(ApiEndpoints.shopProducts(shopId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    }
    throw Exception('Failed to load products');
  }
}
```

---

## 🚚 Delivery Partner Mobile App

### Current Implementation Status
```
✅ COMPLETED UI COMPONENTS:
├─ Authentication Flow
│  ├─ WhatsApp OTP Login Screen
│  └─ Phone Number Verification
│
├─ Main Dashboard
│  ├─ Earnings Overview Widget
│  ├─ Available Orders List
│  ├─ Quick Stats Cards
│  └─ Online/Offline Toggle
│
├─ Earnings Management
│  ├─ Daily/Weekly/Monthly Views
│  ├─ Withdrawal Request System
│  ├─ Transaction History
│  └─ Earnings Calculator
│
├─ Profile Management
│  ├─ Personal Information Forms
│  ├─ Vehicle Details Input
│  ├─ Document Upload Interface
│  └─ Bank Details Management
│
├─ Order Management
│  ├─ Order Assignment View
│  ├─ Order Details Screen
│  ├─ Navigation Integration
│  └─ Order Status Updates
│
└─ Analytics Screen
   ├─ Performance Metrics Display
   ├─ Delivery Statistics Charts
   ├─ Achievement Badges
   └─ Leaderboard View
```

### API Integration (Currently Mock)
```dart
// Delivery Partner API Configuration
class DeliveryPartnerApiEndpoints {
  static const String baseUrl = 'http://localhost:8082/api/mobile/delivery-partner';
  
  // Authentication
  static const String login = '$baseUrl/login';
  static const String verifyOtp = '$baseUrl/verify-otp';
  
  // Partner Management
  static String profile(String partnerId) => '$baseUrl/profile/$partnerId';
  static String availableOrders(String partnerId) => '$baseUrl/orders/$partnerId/available';
  static const String leaderboard = '$baseUrl/leaderboard';
  
  // Order Management (Planned)
  static String acceptOrder(String orderId) => '$baseUrl/orders/$orderId/accept';
  static String pickupOrder(String orderId) => '$baseUrl/orders/$orderId/pickup';
  static String deliverOrder(String orderId) => '$baseUrl/orders/$orderId/deliver';
}
```

**Delivery Partner Service**
```dart
class DeliveryPartnerService {
  Future<LoginResponse> login(String phoneNumber) async {
    final response = await http.post(
      Uri.parse(DeliveryPartnerApiEndpoints.login),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'phoneNumber': phoneNumber}),
    );
    
    if (response.statusCode == 200) {
      return LoginResponse.fromJson(json.decode(response.body));
    }
    throw Exception('Login failed');
  }

  Future<PartnerProfile> getProfile(String partnerId) async {
    final response = await http.get(
      Uri.parse(DeliveryPartnerApiEndpoints.profile(partnerId)),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return PartnerProfile.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load profile');
  }

  Future<List<Order>> getAvailableOrders(String partnerId) async {
    final response = await http.get(
      Uri.parse(DeliveryPartnerApiEndpoints.availableOrders(partnerId)),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> orders = data['orders'] ?? [];
      return orders.map((json) => Order.fromJson(json)).toList();
    }
    throw Exception('Failed to load orders');
  }
}
```

---

## 🛠️ Development Setup

### Prerequisites
```bash
# Install Flutter SDK
https://flutter.dev/docs/get-started/install

# Verify installation
flutter doctor

# Required versions
Flutter: 3.16.0+
Dart: 3.2.0+
```

### Customer App Setup
```bash
# Navigate to customer app
cd mobile/nammaooru_mobile_app

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build for release
flutter build apk --release
flutter build ios --release
```

### Delivery Partner App Setup
```bash
# Navigate to delivery partner app
cd mobile/nammaooru_delivery_partner

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build for release
flutter build apk --release
```

---

## 📦 Dependencies

### Common Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & API
  http: ^1.1.0
  dio: ^5.4.0
  
  # State Management
  provider: ^6.1.1
  riverpod: ^2.4.9
  
  # Local Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Navigation
  go_router: ^12.1.3
  
  # UI Components
  material_symbols_icons: ^4.2719.3
  cached_network_image: ^3.3.1
  image_picker: ^1.0.7
  
  # Utilities
  intl: ^0.19.0
  uuid: ^4.3.3
  
  # Maps & Location (Delivery Partner)
  google_maps_flutter: ^2.5.3
  geolocator: ^10.1.0
  
  # Push Notifications
  firebase_messaging: ^14.7.10
  
  # Networking
  connectivity_plus: ^5.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.8
  hive_generator: ^2.0.1
```

---

## 🏗️ Architecture Patterns

### State Management (Provider Pattern)
```dart
// Example: Cart Provider
class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  Shop? _currentShop;
  
  List<CartItem> get items => _items;
  Shop? get currentShop => _currentShop;
  double get totalAmount => _items.fold(0, (sum, item) => sum + item.totalPrice);
  
  void addItem(Product product, int quantity) {
    // Enforce single shop restriction
    if (_currentShop != null && _currentShop!.id != product.shopId) {
      throw Exception('Cannot add products from different shops');
    }
    
    final existingIndex = _items.indexWhere((item) => item.productId == product.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem.fromProduct(product, quantity));
    }
    
    _currentShop ??= Shop(id: product.shopId, name: product.shopName);
    notifyListeners();
  }
  
  void removeItem(int productId) {
    _items.removeWhere((item) => item.productId == productId);
    if (_items.isEmpty) {
      _currentShop = null;
    }
    notifyListeners();
  }
  
  void clearCart() {
    _items.clear();
    _currentShop = null;
    notifyListeners();
  }
}
```

### Service Layer Pattern
```dart
// Base API Service
abstract class BaseApiService {
  static const String baseUrl = 'https://api.nammaoorudelivary.in/api';
  late final Dio _dio;
  
  BaseApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LoggingInterceptor());
  }
  
  Future<T> get<T>(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParams);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<T> post<T>(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  ApiException _handleError(dynamic error) {
    if (error is DioException) {
      return ApiException(
        message: error.message ?? 'Network error occurred',
        statusCode: error.response?.statusCode,
      );
    }
    return ApiException(message: 'Unexpected error occurred');
  }
}
```

---

## 🎨 UI/UX Guidelines

### Design System
```dart
// Theme Configuration
class AppTheme {
  static const primaryColor = Color(0xFF2196F3);
  static const secondaryColor = Color(0xFF4CAF50);
  static const errorColor = Color(0xFFF44336);
  static const backgroundColor = Color(0xFFF5F5F5);
  
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    primaryColor: primaryColor,
    backgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}
```

### Common Widgets
```dart
// Custom App Bar
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  
  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      automaticallyImplyLeading: showBackButton,
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Loading Widget
class LoadingWidget extends StatelessWidget {
  final String? message;
  
  const LoadingWidget({Key? key, this.message}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
```

---

## 🔧 Testing

### Unit Testing
```dart
// Test file: test/services/auth_service_test.dart
void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockHttpClient mockHttpClient;
    
    setUp(() {
      mockHttpClient = MockHttpClient();
      authService = AuthService(httpClient: mockHttpClient);
    });
    
    test('login should return AuthResponse on success', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      final mockResponse = MockResponse(200, '{"token": "mock_token", "user": {}}');
      
      when(mockHttpClient.post(any, body: any, headers: any))
          .thenAnswer((_) async => mockResponse);
      
      // Act
      final result = await authService.login(email, password);
      
      // Assert
      expect(result, isA<AuthResponse>());
      expect(result.token, equals('mock_token'));
    });
  });
}
```

### Widget Testing
```dart
// Test file: test/widgets/product_card_test.dart
void main() {
  group('ProductCard', () {
    testWidgets('should display product information', (WidgetTester tester) async {
      // Arrange
      final product = Product(
        id: 1,
        name: 'Test Product',
        price: 99.99,
        imageUrl: 'https://example.com/image.jpg',
      );
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: product),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Test Product'), findsOneWidget);
      expect(find.text('₹99.99'), findsOneWidget);
    });
  });
}
```

### Integration Testing
```dart
// Test file: integration_test/app_test.dart
void main() {
  group('App Integration Tests', () {
    testWidgets('complete login flow', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      
      // Navigate to login
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
      
      // Enter credentials
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      
      // Submit login
      await tester.tap(find.byKey(const Key('submit_login')));
      await tester.pumpAndSettle();
      
      // Verify navigation to home
      expect(find.byKey(const Key('home_screen')), findsOneWidget);
    });
  });
}
```

---

## 🚀 Build & Release

### Android Release Build
```bash
# Generate keystore (one-time)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Configure android/key.properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-keystore>

# Build release APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### iOS Release Build
```bash
# Build for iOS
flutter build ios --release

# Archive in Xcode
open ios/Runner.xcworkspace
```

### Build Configuration
```yaml
# android/app/build.gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.nammaooru.shop_management"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true
    }
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            shrinkResources true
            minifyEnabled true
        }
    }
}
```

---

## 🐛 Debugging & Troubleshooting

### Common Issues & Solutions

#### 1. API Connection Issues
```dart
// Enable network logging
void main() {
  if (kDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }
  runApp(MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
```

#### 2. State Management Issues
```dart
// Debug provider changes
class DebugProvider<T extends ChangeNotifier> extends StatelessWidget {
  final T provider;
  final Widget child;
  
  const DebugProvider({Key? key, required this.provider, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: Consumer<T>(
        builder: (context, provider, child) {
          if (kDebugMode) {
            print('Provider $T changed: ${provider.toString()}');
          }
          return child!;
        },
        child: child,
      ),
    );
  }
}
```

#### 3. Build Issues
```bash
# Clean build
flutter clean
flutter pub get
flutter build apk --release

# Clear Gradle cache (Android)
cd android
./gradlew clean

# Clear derived data (iOS)
rm -rf ~/Library/Developer/Xcode/DerivedData
```

---

## 📊 Performance Optimization

### Image Optimization
```dart
// Optimized image loading
CachedNetworkImage(
  imageUrl: product.imageUrl,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  fit: BoxFit.cover,
  memCacheHeight: 200,
  memCacheWidth: 200,
)
```

### List Performance
```dart
// Use ListView.builder for large lists
ListView.builder(
  itemCount: products.length,
  itemBuilder: (context, index) {
    return ProductCard(product: products[index]);
  },
)

// Use AutomaticKeepAliveClientMixin for complex widgets
class ProductCard extends StatefulWidget with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
}
```

### Bundle Size Optimization
```yaml
# Use specific imports
import 'package:flutter/material.dart' show MaterialApp, Scaffold;

# Enable tree shaking
flutter build apk --release --tree-shake-icons
```

---

## 📈 Analytics & Monitoring

### Crash Reporting
```dart
// Firebase Crashlytics integration
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(MyApp());
}
```

### Performance Monitoring
```dart
// Track API call performance
Future<T> trackApiCall<T>(String endpoint, Future<T> Function() apiCall) async {
  final trace = FirebasePerformance.instance.newTrace('api_call_$endpoint');
  await trace.start();
  
  try {
    final result = await apiCall();
    trace.setMetric('success', 1);
    return result;
  } catch (e) {
    trace.setMetric('error', 1);
    rethrow;
  } finally {
    await trace.stop();
  }
}
```

---

## 📞 Support & Maintenance

### Logging Strategy
```dart
// Structured logging
class Logger {
  static void info(String message, {Map<String, dynamic>? extra}) {
    if (kDebugMode) {
      print('INFO: $message ${extra ?? ''}');
    }
    // Send to analytics in production
  }
  
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('ERROR: $message\nError: $error\nStack: $stackTrace');
    }
    FirebaseCrashlytics.instance.log('ERROR: $message');
    if (error != null) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }
}
```

### Version Management
```yaml
# pubspec.yaml
version: 1.0.0+1

# Update version for releases
version: 1.0.1+2  # version_name+build_number
```

---

**Last Updated**: January 2025  
**Customer App Status**: ✅ Production Ready  
**Delivery Partner App Status**: 🚧 UI Complete, API Integration Pending  
**Next Review**: When delivery partner backend APIs are implemented