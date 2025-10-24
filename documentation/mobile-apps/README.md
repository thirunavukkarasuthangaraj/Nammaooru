# Mobile Apps Documentation

Flutter mobile application architecture and development guides for NammaOoru.

## 📄 Documents in this folder

### [DELIVERY_PARTNER_APP_ARCHITECTURE.md](DELIVERY_PARTNER_APP_ARCHITECTURE.md)
Delivery Partner mobile app complete documentation
- App architecture
- Feature modules
- State management
- API integration
- Location tracking
- Earnings system

### [SHOP_OWNER_APP_ARCHITECTURE.md](SHOP_OWNER_APP_ARCHITECTURE.md)
Shop Owner mobile app documentation
- App structure
- Order management features
- Menu management
- Analytics integration
- Notification handling

### [MOBILE_APP_GUIDE.md](MOBILE_APP_GUIDE.md)
General mobile app development guide
- Flutter setup
- Development workflow
- Testing procedures
- Build and deployment
- Common issues

### [APP_VERSION_MANAGEMENT.md](APP_VERSION_MANAGEMENT.md)
App version control and release management
- Version numbering
- Release process
- Play Store deployment
- Version compatibility
- Update notifications

## 📱 Mobile Applications

### 1. Customer App
**Package**: `com.nammaooru.app`
**Purpose**: Order food and products

**Features**:
- Browse shops and products
- Place orders
- Track deliveries
- Payment integration
- Order history

### 2. Shop Owner App
**Package**: `com.nammaooru.shopowner`
**Purpose**: Manage shop and orders

**Features**:
- Accept/reject orders
- Menu management
- Order tracking
- Analytics dashboard
- Earnings reports

### 3. Delivery Partner App
**Package**: `com.nammaooru.delivery`
**Purpose**: Deliver orders

**Features**:
- Accept delivery requests
- Real-time navigation
- Earnings tracking
- Order history
- Performance metrics

## 🛠️ Development Setup

### Prerequisites
- Flutter SDK 3.x+
- Android Studio / VS Code
- Android SDK
- Firebase project setup

### Quick Start
```bash
cd mobile/<app-name>
flutter pub get
flutter run
```

### Build Release APK
```bash
flutter build apk --release
```

## 📞 Support

For mobile app development questions, review the specific app architecture documents.
