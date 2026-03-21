# 📱 NammaOoru Multi-Service Delivery Platform - Flutter Mobile App

A comprehensive Flutter mobile application for the NammaOoru Multi-Service Delivery Platform with role-based authentication and dynamic routing.

## 🎯 Overview

NammaOoru is a single Flutter application that handles all user types (Customer, Shop Owner, Delivery Partner) with dynamic UI and routing based on user role after login. The app detects user type from JWT token and redirects to appropriate dashboard and features.

## 👥 User Roles & Features

### 🛒 Customer Features
- **Home Dashboard**: Service categories, location selector, featured shops, promotional banners
- **Product Browsing**: Category-wise listings, advanced search, product details with image gallery
- **Shopping Cart**: Add/remove items, quantity management, checkout process
- **Order Management**: Real-time tracking, order history, reorder functionality
- **Location Services**: GPS tracking, delivery address management

### 🏪 Shop Owner Features
- **Business Dashboard**: Sales summary, pending orders, shop status toggle
- **Product Management**: Add/edit products, bulk operations, price management
- **Inventory Control**: Stock tracking, low-stock alerts, bulk updates
- **Order Processing**: Accept/reject orders, status updates, customer communication
- **Analytics**: Sales performance, customer reviews, growth metrics

### 🚚 Delivery Partner Features
- **Delivery Dashboard**: Earnings summary, online/offline status, performance metrics
- **Order Management**: Available orders, route optimization, pickup/delivery confirmation
- **GPS Tracking**: Real-time location sharing, navigation integration
- **Earnings**: Daily/weekly/monthly earnings, cash/online payment tracking

## 🔧 Technical Stack

### Core Technologies
- **Framework**: Flutter 3.x with Dart
- **State Management**: Provider pattern with role-based state
- **Navigation**: GoRouter with role-based route guards
- **HTTP Client**: Dio for API integration with JWT interceptors
- **Local Storage**: SharedPreferences + Flutter Secure Storage

### Maps & Location
- **Maps**: Google Maps Flutter plugin
- **Location**: Geolocator for GPS tracking
- **Geocoding**: Address to coordinates conversion

### Firebase Integration
- **Cloud Messaging**: Push notifications
- **Analytics**: User behavior tracking
- **Crashlytics**: Error reporting

### Media & Images
- **Image Picker**: Camera and gallery integration
- **Image Cropper**: Photo editing capabilities
- **Cached Images**: Network image caching

### Localization
- **Languages**: Tamil + English support
- **Intl**: Flutter internationalization

## 🏗️ Project Structure

```
nammaooru_mobile_app/
├── lib/
│   ├── main.dart                     # App entry point
│   ├── app/                         # App configuration
│   │   ├── app.dart                 # Main app widget
│   │   ├── routes.dart              # Role-based routing
│   │   └── theme.dart               # App theming
│   ├── core/                        # Core functionality
│   │   ├── auth/                    # Authentication
│   │   │   ├── auth_service.dart
│   │   │   ├── auth_provider.dart
│   │   │   ├── role_guard.dart
│   │   │   └── jwt_helper.dart
│   │   ├── api/                     # API integration
│   │   │   ├── api_client.dart
│   │   │   ├── api_endpoints.dart
│   │   │   └── api_interceptors.dart
│   │   ├── constants/               # App constants
│   │   ├── utils/                   # Helper utilities
│   │   └── storage/                 # Local storage
│   ├── shared/                      # Shared components
│   │   ├── widgets/                 # Reusable widgets
│   │   ├── models/                  # Data models
│   │   └── services/                # Shared services
│   └── features/                    # Feature modules
│       ├── auth/                    # Authentication screens
│       ├── customer/                # Customer features
│       ├── shop_owner/              # Shop owner features
│       └── delivery_partner/        # Delivery partner features
├── assets/                          # Static assets
├── android/                         # Android configuration
├── ios/                            # iOS configuration
└── l10n/                           # Localization files
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd nammaooru_mobile_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project
   - Add Android/iOS apps to Firebase
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in appropriate directories
   - Update `firebase_options.dart` with your Firebase configuration

4. **Configure Google Maps**
   - Get Google Maps API key
   - Add to `android/app/src/main/AndroidManifest.xml`
   - Add to `ios/Runner/AppDelegate.swift`

5. **Configure API endpoints**
   - Update `lib/core/constants/app_constants.dart` with your backend URL
   - Configure API endpoints in `lib/core/api/api_endpoints.dart`

### Running the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specific platform
flutter run -d android
flutter run -d ios
```

### Building for Production

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 🔐 Authentication Flow

1. **App Launch**: Check stored JWT token validity
2. **Token Invalid**: Redirect to login screen
3. **User Login**: API call to `/auth/login`
4. **JWT Received**: Parse token to extract user role
5. **Role-based Routing**: Redirect to appropriate dashboard
6. **Secure Storage**: Store token and role for future sessions
7. **Auto Refresh**: Automatic token refresh mechanism

## 🎨 Role-based UI Themes

### Customer Theme
- **Colors**: Blue/Green for trust and freshness
- **Navigation**: Home, Categories, Cart, Orders, Profile
- **Focus**: Easy product browsing and ordering

### Shop Owner Theme
- **Colors**: Orange/Purple for business professionalism
- **Navigation**: Dashboard, Products, Orders, Analytics, Profile
- **Focus**: Business management and analytics

### Delivery Partner Theme
- **Colors**: Red/Dark for visibility and urgency
- **Navigation**: Dashboard, Orders, Map, Earnings, Profile
- **Focus**: Navigation and quick actions

## 🗺️ Real-time Tracking

- **WebSocket Integration**: Real-time location updates
- **Battery Optimization**: Efficient location tracking
- **Offline Support**: Cached maps for poor connectivity
- **Route Optimization**: Multi-stop delivery planning
- **Geofencing**: Automatic pickup/delivery confirmations

## 🔔 Notification System

### Push Notifications
- **Order Updates**: Status changes throughout lifecycle
- **Business Alerts**: New orders, low stock warnings
- **Delivery Alerts**: Route optimization, earnings updates
- **Custom Sounds**: Role-specific notification tones

### Local Notifications
- **In-app Alerts**: Real-time status updates
- **Badge Counts**: Unread notification indicators

## 🌍 Localization

### Supported Languages
- **English**: Primary language
- **Tamil**: Regional language support

### Features
- **Dynamic Switching**: Runtime language change
- **Cultural Adaptation**: Local business practices
- **Currency Formatting**: ₹ INR with proper formatting
- **Voice Support**: Search and commands in both languages

## 📱 Mobile-specific Features

### Performance
- **Lazy Loading**: Role-specific feature loading
- **Image Optimization**: Compression and caching
- **Memory Management**: Efficient resource usage
- **Offline Mode**: Local data caching

### User Experience
- **Biometric Auth**: Fingerprint/Face ID support
- **Dark Mode**: System theme following
- **Haptic Feedback**: Important action responses
- **Voice Search**: Speech-to-text integration

### Security
- **Secure Storage**: Encrypted token storage
- **Session Management**: Automatic timeout
- **Device Binding**: Enhanced security
- **Screenshot Prevention**: Sensitive screen protection

## 🔧 Development

### Code Style
- Follow Flutter/Dart style guidelines
- Use meaningful variable names
- Add documentation for public APIs
- Implement proper error handling

### Testing
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

### Debugging
```bash
# Flutter inspector
flutter inspector

# Performance profiling
flutter run --profile
```

## 📦 Dependencies

### Core Dependencies
- `flutter`: SDK framework
- `provider`: State management
- `go_router`: Navigation
- `dio`: HTTP client
- `shared_preferences`: Local storage
- `flutter_secure_storage`: Secure storage

### Firebase
- `firebase_core`: Firebase core
- `firebase_messaging`: Push notifications
- `firebase_analytics`: Analytics

### Maps & Location
- `google_maps_flutter`: Google Maps
- `geolocator`: Location services
- `geocoding`: Address conversion

### Media & Images
- `image_picker`: Image selection
- `cached_network_image`: Image caching
- `image_cropper`: Image editing

### Utilities
- `jwt_decode`: JWT token parsing
- `connectivity_plus`: Network status
- `permission_handler`: System permissions
- `local_auth`: Biometric authentication

## 🚀 Deployment

### Android Play Store
1. Build signed APK/AAB
2. Upload to Play Console
3. Configure store listing
4. Submit for review

### iOS App Store
1. Build for iOS device
2. Archive in Xcode
3. Upload to App Store Connect
4. Configure app metadata
5. Submit for review

## 🐛 Troubleshooting

### Common Issues

**Build Errors:**
- Run `flutter clean && flutter pub get`
- Check Android/iOS SDK versions
- Verify API keys and configurations

**Location Issues:**
- Ensure location permissions granted
- Check location services enabled
- Verify API keys for maps

**Firebase Issues:**
- Verify configuration files
- Check package name/bundle ID
- Ensure Firebase project setup

### Performance Issues
- Use `flutter run --profile` for profiling
- Check memory usage with DevTools
- Optimize image sizes and caching

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check documentation and troubleshooting guides

---

**Built with ❤️ using Flutter for the NammaOoru Multi-Service Delivery Platform**