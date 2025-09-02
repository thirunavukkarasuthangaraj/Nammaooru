# Mobile App Configuration Guide - NammaOoru

## Overview
This guide covers the Flutter mobile app configuration, API integration, and deployment process for the NammaOoru delivery system.

## Project Structure
```
mobile/nammaooru_mobile_app/
├── lib/
│   ├── app/
│   │   └── app.dart                    # Main app configuration
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart         # HTTP client configuration
│   │   │   ├── api_endpoints.dart      # API endpoint constants
│   │   │   └── api_service.dart        # API service wrapper
│   │   ├── models/                     # Data models
│   │   ├── providers/                  # State management
│   │   └── services/
│   │       ├── api_service.dart        # Core API service
│   │       └── storage_service.dart    # Local storage
│   ├── features/
│   │   ├── auth/
│   │   │   └── screens/
│   │   │       └── register_screen.dart # User registration
│   │   └── customer/
│   │       └── shops/
│   │           └── shops_screen.dart   # Shop listing
│   ├── shared/
│   │   ├── models/
│   │   │   └── shop_model.dart         # Shop data model
│   │   └── services/
│   │       └── image_service.dart      # Image handling
│   └── main.dart                       # App entry point
├── android/                            # Android configuration
├── ios/                               # iOS configuration
└── pubspec.yaml                       # Dependencies
```

## API Configuration

### Base URL Configuration
The app connects to the production API server:

```dart
// lib/core/api/api_client.dart
class ApiClient {
  static late Dio _dio;
  
  static void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.nammaoorudelivary.in/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Debug logging in development mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }
}
```

### API Endpoints
```dart
// lib/core/api/api_endpoints.dart
class ApiEndpoints {
  static const String baseUrl = 'https://api.nammaoorudelivary.in/api';
  
  // Authentication
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  
  // Shops
  static const String shops = '/shops';
  static const String shopsByLocation = '/shops/by-location';
  
  // Products
  static const String products = '/products';
  static const String productsByShop = '/products/shop';
  
  // User Profile
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';
}
```

## Authentication Flow

### Registration Process
1. **User Input**: User fills registration form
2. **OTP Request**: App calls `/auth/send-otp`
3. **Email Delivery**: Backend sends OTP via SMTP
4. **OTP Verification**: User enters OTP, app calls `/auth/verify-otp`
5. **Registration**: App calls `/auth/register` to complete signup

```dart
// lib/features/auth/screens/register_screen.dart
class RegisterScreen extends StatefulWidget {
  // Registration form with:
  // - firstName, lastName
  // - email, mobile
  // - password, confirmPassword
  // - OTP verification
}
```

### OTP Email Integration
```dart
Future<void> sendOtp(String email) async {
  try {
    final response = await ApiClient.post(
      ApiEndpoints.sendOtp,
      data: {'email': email},
    );
    
    if (response.statusCode == 200) {
      // OTP sent successfully
      // Backend will send email via Hostinger SMTP
      showSuccessMessage('OTP sent to your email');
    }
  } catch (e) {
    showErrorMessage('Failed to send OTP');
  }
}
```

## Data Models

### Shop Model
```dart
// lib/shared/models/shop_model.dart
class Shop {
  final String id;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> images;
  final String ownerName;
  final String contactNumber;
  final bool isActive;
  final DateTime createdAt;

  Shop({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.ownerName,
    required this.contactNumber,
    required this.isActive,
    required this.createdAt,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      images: List<String>.from(json['images'] ?? []),
      ownerName: json['ownerName'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      isActive: json['active'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
```

## Dependencies (pubspec.yaml)

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP client
  dio: ^5.4.0
  
  # State management
  provider: ^6.1.1
  
  # Local storage
  shared_preferences: ^2.5.3
  flutter_secure_storage: ^9.2.4
  
  # Image handling
  image_picker: ^1.1.2
  image_cropper: ^9.1.0
  
  # Connectivity
  connectivity_plus: ^5.0.2
  
  # Firebase (for push notifications)
  firebase_core: ^2.32.0
  firebase_messaging: ^14.7.10
  firebase_analytics: ^10.10.7
  
  # Authentication helpers
  smart_auth: ^1.1.1
  
  # Database
  sqflite: ^2.4.1
  path_provider: ^2.1.5
```

### Dev Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

## Build Configuration

### Android Configuration
```gradle
// android/app/build.gradle
android {
    compileSdk 34
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }
    
    kotlinOptions {
        jvmTarget = '11'
    }
    
    defaultConfig {
        applicationId "com.nammaooru.delivery"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0.0"
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Kotlin Version
```gradle
// android/settings.gradle
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "7.3.0" apply false
    id "org.jetbrains.kotlin.android" version "1.9.22" apply false
}
```

## Image Handling

### Image Service Configuration
```dart
// lib/shared/services/image_service.dart
class ImageService {
  static Future<File?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    
    if (image != null) {
      return File(image.path);
    }
    return null;
  }
  
  static Future<File?> cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
      ],
    );
    
    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }
}
```

## State Management

### Provider Setup
```dart
// lib/core/providers/auth_provider.dart
class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  User? _user;
  
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  User? get user => _user;
  
  Future<void> login(String email, String password) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      
      if (response.statusCode == 200) {
        _token = response.data['token'];
        _user = User.fromJson(response.data['user']);
        _isAuthenticated = true;
        
        // Save token securely
        await StorageService.saveToken(_token!);
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }
  
  Future<void> logout() async {
    _token = null;
    _user = null;
    _isAuthenticated = false;
    
    await StorageService.clearToken();
    notifyListeners();
  }
}
```

## Local Storage

### Secure Storage Service
```dart
// lib/core/services/storage_service.dart
class StorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Secure token storage
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }
  
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }
  
  static Future<void> clearToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }
  
  // Regular preferences
  static Future<void> saveUserPreference(String key, String value) async {
    await _prefs?.setString(key, value);
  }
  
  static String? getUserPreference(String key) {
    return _prefs?.getString(key);
  }
}
```

## Build and Deployment

### Debug Build
```bash
flutter run --debug
# or
flutter build apk --debug
```

### Release Build
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Install on Device
```bash
# Check connected devices
adb devices

# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Or install with replacement
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Testing

### Unit Tests
```dart
// test/api_client_test.dart
void main() {
  group('ApiClient Tests', () {
    test('should initialize with correct base URL', () {
      ApiClient.initialize();
      expect(ApiClient.dio.options.baseUrl, 'https://api.nammaoorudelivary.in/api');
    });
    
    test('should have correct timeout values', () {
      ApiClient.initialize();
      expect(ApiClient.dio.options.connectTimeout, const Duration(seconds: 30));
      expect(ApiClient.dio.options.receiveTimeout, const Duration(seconds: 30));
    });
  });
}
```

### Widget Tests
```dart
// test/register_screen_test.dart
void main() {
  testWidgets('Register screen should display all form fields', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: RegisterScreen()));
    
    expect(find.text('First Name'), findsOneWidget);
    expect(find.text('Last Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mobile'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
```

## Troubleshooting

### Common Issues

#### 1. API Connection Issues
```
Error: SocketException: Failed host lookup
```
**Solution**: Check network connectivity and API endpoint URL

#### 2. Build Failures
```
Error: Could not resolve all files for configuration ':app:debugRuntimeClasspath'
```
**Solution**: 
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### 3. OTP Not Received
**Check List**:
- API endpoint responding correctly
- Backend email configuration working
- Network connectivity from device
- Email in spam folder

#### 4. Image Upload Issues
**Check List**:
- Image size within limits
- Network connectivity
- Authentication token valid
- Server storage permissions

### Debug Mode Setup
```dart
// main.dart - Enable debug logging
void main() async {
  if (kDebugMode) {
    // Enable HTTP logging
    ApiClient.initialize();
    
    // Enable console logging
    debugPrint('App starting in debug mode');
  }
  
  runApp(MyApp());
}
```

## Performance Optimization

### Image Optimization
```dart
// Compress images before upload
static Future<File> compressImage(File file) async {
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);
  
  if (image != null) {
    final compressed = img.encodeJpg(image, quality: 80);
    final compressedFile = File('${file.path}_compressed.jpg');
    await compressedFile.writeAsBytes(compressed);
    return compressedFile;
  }
  
  return file;
}
```

### Network Caching
```dart
// Add caching interceptor
static void addCacheInterceptor() {
  _dio.interceptors.add(DioCacheInterceptor(
    options: CacheOptions(
      store: MemCacheStore(),
      policy: CachePolicy.request,
      hitCacheOnErrorExcept: [401, 403],
      maxStale: const Duration(days: 7),
      priority: CachePriority.normal,
    ),
  ));
}
```

## Security Best Practices

### Token Management
- Store auth tokens in secure storage
- Implement token refresh mechanism
- Clear tokens on logout
- Validate token expiry

### Network Security
- Use HTTPS for all API calls
- Implement certificate pinning
- Validate SSL certificates
- Handle network timeouts gracefully

### Data Protection
- Encrypt sensitive local data
- Implement biometric authentication
- Clear cache on app uninstall
- Validate user input

---

**Mobile App Status**: ✅ Working - Connected to production API
**Last Updated**: January 2025
**Next Review**: When new features are added