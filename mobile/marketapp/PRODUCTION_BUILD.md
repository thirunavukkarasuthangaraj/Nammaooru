# NammaOoru Mobile App - Production Build Guide

## 📱 Production Build Configuration

### Prerequisites
1. **Flutter SDK**: Latest stable version (3.10.0+)
2. **Android Studio**: For Android builds
3. **Xcode**: For iOS builds (macOS only)
4. **Google Maps API Key**: For maps functionality
5. **Firebase Project**: Setup with Android/iOS apps configured

## 🔑 Required API Keys & Configuration

### 1. Google Maps API Key
```bash
# Android: Update android/app/src/main/AndroidManifest.xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_GOOGLE_MAPS_API_KEY"/>

# iOS: Update ios/Runner/AppDelegate.swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

### 2. Firebase Configuration
```bash
# Android: Place google-services.json in android/app/
# iOS: Place GoogleService-Info.plist in ios/Runner/

# Ensure these Firebase services are enabled:
- Authentication
- Cloud Messaging (FCM)
- Analytics
- Crashlytics
```

### 3. Environment Variables
Create `lib/core/config/env_config.dart`:
```dart
class EnvConfig {
  static const String baseUrl = 'https://api.nammaooru.com';
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  static const String razorpayKey = 'YOUR_RAZORPAY_KEY';
  static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';
}
```

## 🔐 Android Signing Configuration

### 1. Generate Release Keystore
```bash
keytool -genkey -v -keystore ~/nammaooru-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nammaooru
```

### 2. Configure Signing (android/local.properties)
```properties
android.keystore.path=/path/to/nammaooru-release-key.jks
android.keystore.alias=nammaooru
android.keystore.password=YOUR_KEYSTORE_PASSWORD
```

### 3. Build Android Release
```bash
# Build APK
flutter build apk --release

# Build App Bundle (Recommended for Play Store)
flutter build appbundle --release
```

## 🍎 iOS Configuration

### 1. Signing & Certificates
- Create Apple Developer Account
- Generate App ID: com.nammaooru.app
- Create Distribution Certificate
- Create Distribution Provisioning Profile

### 2. Build iOS Release
```bash
# Build iOS Archive
flutter build ios --release

# Open in Xcode for final submission
open ios/Runner.xcworkspace
```

## 📦 Build Commands

### Development Builds
```bash
# Debug builds
flutter run --debug

# Profile builds (for performance testing)
flutter run --profile
```

### Production Builds
```bash
# Android
flutter build apk --release --target-platform android-arm64
flutter build appbundle --release

# iOS
flutter build ios --release --no-codesign
```

## 🔍 Pre-Build Checklist

### Code Quality
- [ ] Run `flutter analyze` - No errors
- [ ] Run `flutter test` - All tests pass
- [ ] Check `dart format .` - Code formatted
- [ ] Review `flutter doctor` - All dependencies met

### Configuration
- [ ] API endpoints updated to production URLs
- [ ] Google Maps API key configured
- [ ] Firebase configuration files added
- [ ] App icons and splash screens updated
- [ ] Version number updated in pubspec.yaml
- [ ] Release notes prepared

### Permissions
- [ ] Android permissions minimal and justified
- [ ] iOS usage descriptions clear and specific
- [ ] Location permissions properly configured
- [ ] Camera/microphone permissions explained

## 🚀 Deployment

### Google Play Store
1. **App Bundle**: Upload .aab file
2. **Store Listing**: Complete all required fields
3. **Content Rating**: Complete questionnaire
4. **Pricing**: Set pricing and distribution
5. **Release Management**: Configure staged rollout

### Apple App Store
1. **Archive**: Create archive in Xcode
2. **App Store Connect**: Upload via Xcode or Transporter
3. **TestFlight**: Test with beta users
4. **Store Listing**: Complete all metadata
5. **Review Submission**: Submit for Apple review

## 📊 Performance Optimization

### Build Optimization
```bash
# Enable R8 minification (Android)
# Already configured in build.gradle

# Tree shaking for web builds
flutter build web --web-renderer html --dart-define=FLUTTER_WEB_USE_SKIA=false
```

### Asset Optimization
- **Images**: Use WebP format where possible
- **Icons**: Use vector icons (SVG)
- **Fonts**: Subset fonts to reduce size
- **Animations**: Use Lottie for complex animations

## 🔒 Security Configuration

### Network Security
```dart
// Configure certificate pinning
class ApiClient {
  static dio = Dio();
  
  static void configureCertificatePinning() {
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
      client.badCertificateCallback = (cert, host, port) {
        // Implement certificate pinning logic
        return true;
      };
      return client;
    };
  }
}
```

### Data Protection
- All sensitive data encrypted using flutter_secure_storage
- JWT tokens stored securely
- Biometric authentication for sensitive operations
- API communication over HTTPS only

## 📱 Device Support

### Android
- **Minimum SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Architecture**: arm64-v8a, armeabi-v7a
- **Screen Sizes**: All phone and tablet sizes

### iOS
- **Minimum Version**: 12.0
- **Target Version**: Latest iOS
- **Architecture**: arm64
- **Device Support**: iPhone 6s and newer, all iPads

## 🧪 Testing

### Unit Testing
```bash
flutter test
```

### Integration Testing
```bash
flutter test integration_test/
```

### Performance Testing
```bash
flutter run --profile
# Use Flutter Inspector and Performance Overlay
```

## 📋 Release Notes Template

### Version 1.0.0 (Build 1)
**New Features:**
- Complete multi-service delivery platform
- Role-based authentication (Customer, Shop Owner, Delivery Partner)
- Real-time GPS tracking and navigation
- Comprehensive business management tools
- Multi-language support (Tamil, English)

**Technical Improvements:**
- Firebase integration for analytics and messaging
- Optimized performance and battery usage
- Enhanced security with biometric authentication
- Offline functionality for key features

**Bug Fixes:**
- Initial release - no previous bugs to fix

## 🆘 Troubleshooting

### Common Build Issues

#### Android
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release

# Gradle issues
cd android && ./gradlew clean
cd .. && flutter build apk --release
```

#### iOS
```bash
# Clean and rebuild
flutter clean
flutter pub get
cd ios && rm -rf Pods Podfile.lock
pod install
cd .. && flutter build ios --release
```

### Performance Issues
- Use `flutter run --profile` to identify bottlenecks
- Implement lazy loading for large lists
- Optimize image loading with cached_network_image
- Use Provider for efficient state management

## 📞 Support

For build and deployment support:
- **Technical Issues**: Check Flutter documentation
- **API Integration**: Refer to backend API documentation
- **Store Submission**: Follow platform-specific guidelines
- **Performance**: Use Flutter DevTools for analysis

---

**Note**: This guide assumes you have the necessary developer accounts and certificates. Ensure all API keys and sensitive information are properly secured and not committed to version control.