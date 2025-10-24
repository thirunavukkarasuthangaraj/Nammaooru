# 🏪 NammaOoru Shop Owner Mobile App - Technical Architecture

## 📋 Document Overview

**Purpose**: Complete technical documentation for Shop Owner Flutter mobile application
**Platform**: Flutter (iOS, Android, Web)
**Audience**: Developers, Mobile Engineers, Technical Stakeholders
**Last Updated**: January 2025

---

## 🎯 App Overview

The Shop Owner mobile app is a comprehensive Flutter application that enables shop owners to manage their business operations, including inventory management, order processing, customer engagement, and real-time analytics.

### Key Capabilities
- 📦 **Product Management**: Full CRUD operations for products with image upload
- 📋 **Order Processing**: Real-time order notifications and status management
- 💰 **Financial Dashboard**: Revenue tracking, payment management, analytics
- 🔔 **Push Notifications**: Firebase Cloud Messaging for order updates
- 📊 **Business Analytics**: Sales metrics, product performance, revenue graphs
- 🎧 **Audio Alerts**: Custom sound notifications for important events
- ⚙️ **Business Settings**: Shop profile, business hours, availability management

---

## 🏗️ Application Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Shop Owner Mobile App Architecture                       │
│                           (Flutter Framework)                               │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                             Presentation Layer                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Dashboard  │  │   Products   │  │    Orders    │  │  Notifications │  │
│  │    Screen    │  │   Screens    │  │   Screens    │  │    Screen    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Finance    │  │   Analytics  │  │   Profile    │  │   Settings   │  │
│  │    Screen    │  │    Screen    │  │    Screen    │  │    Screen    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            State Management Layer                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                            Provider Pattern                                 │
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │  AuthProvider    │  │  OrderProvider   │  │ ProductProvider  │         │
│  │  - User state    │  │  - Order list    │  │  - Product list  │         │
│  │  - JWT token     │  │  - Order stats   │  │  - Categories    │         │
│  │  - Login status  │  │  - Real-time     │  │  - Search/Filter │         │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                             Business Logic Layer                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │   API Service    │  │  WebSocket Svc   │  │  Storage Service │         │
│  │  - HTTP Calls    │  │  - Real-time     │  │  - Local Cache   │         │
│  │  - Auth Headers  │  │  - Order Updates │  │  - JWT Storage   │         │
│  │  - Error Handle  │  │  - Notifications │  │  - Preferences   │         │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘         │
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │  Firebase FCM    │  │  Audio Service   │  │  Notification    │         │
│  │  - Push Notify   │  │  - Sound Alerts  │  │  Handler Service │         │
│  │  - Token Mgmt    │  │  - Custom Sounds │  │  - Local Notify  │         │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                             Data & Network Layer                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │  Backend API     │  │  Firebase Cloud  │  │  Local Storage   │         │
│  │  HTTP REST       │  │  FCM Gateway     │  │  SharedPrefs     │         │
│  │  Port: 8080      │  │  Push Delivery   │  │  SQLite Cache    │         │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📱 Screen Flow Architecture

### Main Navigation Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Screen Navigation Flow                          │
└─────────────────────────────────────────────────────────────────────────┘

                        ┌──────────────────┐
                        │  Login Screen    │
                        │  (Auth)          │
                        └────────┬─────────┘
                                 │
                        ┌────────▼─────────┐
                        │  Main Navigation │
                        │  (Bottom TabBar) │
                        └────────┬─────────┘
                                 │
         ┌───────────────┬───────┼───────┬──────────────┬──────────────┐
         │               │       │       │              │              │
    ┌────▼────┐    ┌────▼────┐  │  ┌────▼────┐   ┌────▼────┐   ┌────▼────┐
    │Dashboard│    │Products │  │  │ Orders  │   │ Finance │   │ Profile │
    │         │    │         │  │  │         │   │         │   │         │
    └─────────┘    └────┬────┘  │  └────┬────┘   └────┬────┘   └────┬────┘
                        │       │       │             │              │
           ┌────────────┼───────┘       │             │              │
           │            │               │             │              │
    ┌──────▼──────┐ ┌──▼──────────┐ ┌──▼─────────┐┌──▼──────┐  ┌───▼────────┐
    │My Products  │ │Add Product  │ │Order Detail││Payments │  │Shop Profile│
    │Browse       │ │Edit Product │ │Order List  ││Analytics│  │Settings    │
    │Categories   │ │Product Form │ │Status Mgmt ││Revenue  │  │Bus. Hours  │
    └─────────────┘ └─────────────┘ └────────────┘└─────────┘  └────────────┘
```

---

## 🔄 Complete API Call Flow

### Authentication Flow Diagram

```
┌──────────┐                                           ┌──────────┐
│  UI      │                                           │ Backend  │
│  Layer   │                                           │ API      │
└────┬─────┘                                           └────┬─────┘
     │                                                      │
     │ 1. User enters credentials                           │
     │    (email + password)                                │
     │                                                      │
     │ 2. Call ApiService.login()                          │
     ├──────────────────────────────────────────────────►  │
     │      POST /api/shop-owner/auth/login                │
     │      Body: { identifier, password }                 │
     │                                                      │
     │                                  3. Validate user    │
     │                                     Generate JWT    │
     │                                                      │
     │  4. Return response                                 │
     │  ◄──────────────────────────────────────────────────┤
     │      { token, user, message }                       │
     │                                                      │
     │ 5. Store token in StorageService                    │
     │    await setToken(token)                            │
     │    await setUser(user)                              │
     │                                                      │
     │ 6. Update AuthProvider state                        │
     │    notifyListeners()                                │
     │                                                      │
     │ 7. Navigate to Dashboard                            │
     │                                                      │
     ▼                                                      ▼
```

### Product Management Flow

```
┌──────────┐                                           ┌──────────┐
│ Product  │                                           │ Backend  │
│ Screen   │                                           │ API      │
└────┬─────┘                                           └────┬─────┘
     │                                                      │
     │ 1. Load products on screen init                     │
     ├──────────────────────────────────────────────────►  │
     │      GET /api/shop-owner/products                   │
     │      Headers: { Authorization: Bearer <token> }     │
     │                                                      │
     │                                  2. Fetch products   │
     │                                     from database   │
     │                                                      │
     │  3. Return product list                             │
     │  ◄──────────────────────────────────────────────────┤
     │      { products: [...], totalCount }                │
     │                                                      │
     │ 4. Update ProductProvider                           │
     │    setProducts(products)                            │
     │    notifyListeners()                                │
     │                                                      │
     │ 5. UI rebuilds with product list                    │
     │                                                      │
     │ ═══ USER ADDS NEW PRODUCT ═══                       │
     │                                                      │
     │ 6. Fill product form + upload image                 │
     │                                                      │
     │ 7. Submit product creation                          │
     ├──────────────────────────────────────────────────►  │
     │      POST /api/shop-owner/products                  │
     │      Body: FormData with:                           │
     │      - name, price, description, stock              │
     │      - category, image file                         │
     │                                                      │
     │                                  8. Validate data    │
     │                                     Save to DB      │
     │                                     Upload image    │
     │                                                      │
     │  9. Return created product                          │
     │  ◄──────────────────────────────────────────────────┤
     │      { product: {...}, message }                    │
     │                                                      │
     │ 10. Add to ProductProvider                          │
     │     addProduct(product)                             │
     │     notifyListeners()                               │
     │                                                      │
     │ 11. Show success message & refresh list             │
     │                                                      │
     ▼                                                      ▼
```

### Order Management Flow with Real-time Updates

```
┌──────────┐    ┌─────────────┐                        ┌──────────┐
│ Orders   │    │  WebSocket  │                        │ Backend  │
│ Screen   │    │  Service    │                        │ API      │
└────┬─────┘    └──────┬──────┘                        └────┬─────┘
     │                 │                                     │
     │ 1. Init orders screen                                │
     │                 │                                     │
     │ 2. Fetch initial order list                          │
     ├──────────────────────────────────────────────────────►
     │      GET /api/shop-owner/orders                      │
     │      Query: ?status=pending&limit=20                 │
     │                                                       │
     │  3. Return order list                                │
     │  ◄───────────────────────────────────────────────────┤
     │      { orders: [...], stats }                        │
     │                                                       │
     │ 4. Connect to WebSocket for real-time updates        │
     ├────────────────►│                                     │
     │      connect()  │ 5. Establish WS connection         │
     │                 ├─────────────────────────────────────►
     │                 │      WS: /ws/shop-owner/orders     │
     │                 │                                     │
     │                 │  6. Connection established          │
     │                 │  ◄──────────────────────────────────┤
     │                 │                                     │
     │ 7. Subscribe to order updates                        │
     │                 │                                     │
     │ ═══ NEW ORDER ARRIVES ═══                            │
     │                 │                                     │
     │                 │  8. Broadcast new order event      │
     │                 │  ◄──────────────────────────────────┤
     │                 │      { type: NEW_ORDER, data }     │
     │                 │                                     │
     │ 9. Notify order event                                │
     │  ◄──────────────┤                                     │
     │     onNewOrder() │                                    │
     │                 │                                     │
     │ 10. Update OrderProvider                             │
     │     addOrder(order)                                  │
     │     updateStats()                                    │
     │     notifyListeners()                                │
     │                                                       │
     │ 11. Trigger audio alert                              │
     ├──► AudioService.play('new_order.mp3')                │
     │                                                       │
     │ 12. Show local notification                          │
     ├──► NotificationService.show()                        │
     │                                                       │
     │ 13. UI auto-updates with new order                   │
     │                                                       │
     │ ═══ SHOP OWNER ACCEPTS ORDER ═══                     │
     │                                                       │
     │ 14. User taps "Accept Order"                         │
     │                                                       │
     │ 15. Update order status                              │
     ├───────────────────────────────────────────────────────►
     │      PUT /api/shop-owner/orders/{id}/status          │
     │      Body: { status: "ACCEPTED" }                    │
     │                                                       │
     │                                  16. Update status   │
     │                                      Notify customer │
     │                                      Notify partners │
     │                                                       │
     │  17. Return updated order                            │
     │  ◄───────────────────────────────────────────────────┤
     │      { order: {...}, message }                       │
     │                                                       │
     │ 18. Update OrderProvider                             │
     │     updateOrderStatus(orderId, status)               │
     │     notifyListeners()                                │
     │                                                       │
     │ 19. Show success feedback                            │
     │                                                       │
     ▼                 ▼                                     ▼
```

---

## 📊 State Management Architecture

### Provider Pattern Implementation

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         State Management Flow                           │
└─────────────────────────────────────────────────────────────────────────┘

                            ┌──────────────────┐
                            │   main.dart      │
                            │  MultiProvider   │
                            └────────┬─────────┘
                                     │
         ┌───────────────────────────┼───────────────────────────┐
         │                           │                           │
    ┌────▼────────┐         ┌────────▼──────┐         ┌────────▼──────┐
    │AuthProvider │         │OrderProvider  │         │ProductProvider│
    │             │         │               │         │               │
    │- _user      │         │- _orders      │         │- _products    │
    │- _token     │         │- _stats       │         │- _categories  │
    │- _isAuth    │         │- _isLoading   │         │- _isLoading   │
    │             │         │- _filter      │         │- _search      │
    │Methods:     │         │               │         │               │
    │login()      │         │Methods:       │         │Methods:       │
    │logout()     │         │fetchOrders()  │         │fetchProducts()│
    │refreshToken│         │acceptOrder()  │         │addProduct()   │
    └─────────────┘         │rejectOrder()  │         │updateProduct()│
                            │updateStatus() │         │deleteProduct()│
                            └───────────────┘         └───────────────┘

    Each Provider extends ChangeNotifier
    ↓
    When state changes → notifyListeners()
    ↓
    All listening widgets rebuild automatically
    ↓
    UI stays in sync with data
```

### Data Flow Example: Creating a Product

```
User Action                                              Provider State
─────────                                                ──────────────

1. Fill form ────────────────┐
                             │
2. Tap "Create Product" ─────┤
                             │
                             ▼
                    ┌──────────────────┐
                    │ ProductProvider  │
                    │ createProduct()  │
                    └────────┬─────────┘
                             │
                             │ setLoading(true)
                             │ notifyListeners()
                             │
                             ▼
                    ┌──────────────────┐
                    │   API Service    │
                    │   POST /products │
                    └────────┬─────────┘
                             │
                    ┌────────┴─────────┐
                    │                  │
            Success │                  │ Error
                    │                  │
                    ▼                  ▼
           ┌────────────────┐  ┌────────────────┐
           │ Add to list    │  │ Set error msg  │
           │ setLoading     │  │ setLoading     │
           │ notifyListeners│  │ notifyListeners│
           └────────┬───────┘  └────────┬───────┘
                    │                   │
                    ▼                   ▼
          ┌──────────────────┐  ┌──────────────────┐
          │ UI shows new     │  │ UI shows error   │
          │ product in list  │  │ message          │
          └──────────────────┘  └──────────────────┘
```

---

## 🔔 Push Notification System

### Firebase Cloud Messaging Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│                  Firebase Push Notification Flow                       │
└────────────────────────────────────────────────────────────────────────┘

App Launch
    │
    ▼
┌──────────────────────────┐
│ Firebase Initialization  │
│ FirebaseMessaging.init() │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Request Permissions      │
│ (iOS/Android)            │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Get FCM Token            │
│ getToken()               │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐         ┌────────────────┐
│ Send Token to Backend    ├────────►│ Backend Stores │
│ POST /fcm-token          │         │ Token in DB    │
└──────────────────────────┘         └────────────────┘

┌──────────────────────────────────────────────────────────┐
│              Receiving Notifications                     │
└──────────────────────────────────────────────────────────┘

Backend Event (New Order)
    │
    ▼
┌──────────────────────────┐
│ Backend Triggers FCM     │
│ Send to stored token     │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Firebase Cloud Messaging │
│ Delivers to Device       │
└────────────┬─────────────┘
             │
      ┌──────┴────────┐
      │               │
  App Active      App Background
      │               │
      ▼               ▼
┌──────────────┐ ┌──────────────┐
│onMessage     │ │onBackgroundMsg│
│handler       │ │handler        │
└──────┬───────┘ └──────┬────────┘
       │                │
       ▼                ▼
┌──────────────────────────┐
│ NotificationHandler      │
│ - Parse notification     │
│ - Update OrderProvider   │
│ - Play sound alert       │
│ - Show local notification│
│ - Navigate if clicked    │
└──────────────────────────┘
```

---

## 📦 Project Structure

```
shop-owner-app/
├── lib/
│   ├── main.dart                          # App entry point
│   │
│   ├── models/                            # Data models
│   │   ├── api_response.dart
│   │   ├── models.dart                    # User, Shop, Product
│   │   ├── order_model.dart
│   │   ├── product_model.dart
│   │   └── notification_model.dart
│   │
│   ├── screens/                           # UI screens
│   │   ├── auth/
│   │   │   └── login_screen.dart
│   │   ├── dashboard/
│   │   │   ├── dashboard_screen.dart
│   │   │   └── main_navigation.dart       # Bottom nav bar
│   │   ├── products/
│   │   │   ├── products_screen.dart
│   │   │   ├── my_products_screen.dart
│   │   │   ├── product_form_screen.dart
│   │   │   ├── create_product_screen.dart
│   │   │   ├── categories_screen.dart
│   │   │   └── browse_products_screen.dart
│   │   ├── orders/
│   │   │   ├── orders_screen.dart
│   │   │   └── order_details_screen.dart
│   │   ├── finance/
│   │   │   └── finance_screen.dart
│   │   ├── analytics/
│   │   │   └── analytics_screen.dart
│   │   ├── notifications/
│   │   │   └── notifications_screen.dart
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   └── shop_profile_screen.dart
│   │   ├── settings/
│   │   │   ├── shop_settings_screen.dart
│   │   │   └── business_hours_screen.dart
│   │   └── payments/
│   │       └── payments_screen.dart
│   │
│   ├── services/                          # Business logic
│   │   ├── api_service.dart               # HTTP client
│   │   ├── storage_service.dart           # Local storage
│   │   ├── websocket_service.dart         # Real-time
│   │   ├── firebase_messaging_service.dart# FCM
│   │   ├── notification_service.dart      # Local notifications
│   │   ├── audio_service.dart             # Sound alerts
│   │   ├── sound_service.dart             # Audio playback
│   │   └── mock_data_service.dart         # Dev/testing
│   │
│   ├── utils/                             # Helpers & constants
│   │   ├── constants.dart                 # API endpoints
│   │   └── app_config.dart                # App configuration
│   │
│   └── widgets/                           # Reusable components
│       ├── custom_button.dart
│       ├── product_card.dart
│       ├── order_card.dart
│       └── stat_card.dart
│
├── assets/                                # Static resources
│   ├── sounds/                            # Audio alerts
│   │   ├── new_order.mp3
│   │   ├── order_cancelled.mp3
│   │   ├── payment_received.mp3
│   │   ├── low_stock.mp3
│   │   └── urgent_alert.mp3
│   └── images/                            # App images
│
├── pubspec.yaml                           # Dependencies
├── android/                               # Android config
├── ios/                                   # iOS config
└── web/                                   # Web config
```

---

## 🔑 Core Dependencies

### pubspec.yaml Key Packages

```yaml
dependencies:
  # Core
  flutter:
    sdk: flutter

  # Networking
  http: ^1.1.0                             # HTTP client

  # State Management
  provider: ^6.0.5                         # State management

  # Local Storage
  shared_preferences: ^2.2.2               # Key-value storage
  shared_preferences_web: ^2.2.1           # Web support
  sqflite: ^2.3.0                          # SQLite database
  path_provider: ^2.1.1                    # File paths

  # UI & Media
  cached_network_image: ^3.3.0             # Image caching
  image_picker: ^1.0.4                     # Photo selection
  pull_to_refresh: ^2.0.0                  # Pull-to-refresh
  fl_chart: ^0.66.2                        # Charts & graphs
  audioplayers: ^5.2.1                     # Audio playback

  # Firebase
  firebase_core: ^3.8.1                    # Firebase init
  firebase_messaging: ^15.1.5              # Push notifications

  # Notifications
  flutter_local_notifications: ^17.0.0     # Local notifications
  permission_handler: ^11.1.0              # Permissions

  # Utils
  intl: ^0.18.1                            # Internationalization
  url_launcher: ^6.2.1                     # URL launching
```

---

## 🛠️ API Integration

### API Service Configuration

**Base URL**: `http://192.168.1.11:8080/api`

### Authentication Headers

```dart
Map<String, String> get _authHeaders {
  final token = StorageService.getToken();
  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  if (token != null) {
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
}
```

### Key API Endpoints

| Method | Endpoint | Purpose | Request Body | Response |
|--------|----------|---------|--------------|----------|
| POST | `/shop-owner/auth/login` | Login | `{identifier, password}` | `{token, user}` |
| POST | `/shop-owner/auth/logout` | Logout | - | `{message}` |
| GET | `/shop-owner/products` | Get products | - | `{products: [...]}` |
| POST | `/shop-owner/products` | Create product | `FormData(product + image)` | `{product}` |
| PUT | `/shop-owner/products/{id}` | Update product | `{product data}` | `{product}` |
| DELETE | `/shop-owner/products/{id}` | Delete product | - | `{message}` |
| GET | `/shop-owner/orders` | Get orders | `?status=&limit=` | `{orders: [...]}` |
| GET | `/shop-owner/orders/{id}` | Get order details | - | `{order}` |
| PUT | `/shop-owner/orders/{id}/status` | Update order status | `{status}` | `{order}` |
| GET | `/shop-owner/analytics/revenue` | Revenue stats | `?period=` | `{revenue, stats}` |
| POST | `/shop-owner/fcm-token` | Register FCM token | `{token, device}` | `{message}` |

---

## 🎨 UI/UX Features

### Dashboard Components

```
┌─────────────────────────────────────────────────────────┐
│                    Dashboard Layout                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │              Welcome Message & Stats              │  │
│  │  "Welcome back, [Shop Name]"                     │  │
│  │  Revenue Today: ₹2,450 | Orders: 23              │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌────────────────┐  ┌────────────────┐               │
│  │ Pending Orders │  │ New Products   │               │
│  │      12        │  │      45        │               │
│  └────────────────┘  └────────────────┘               │
│                                                         │
│  ┌────────────────────────────────────────────────┐   │
│  │           Recent Orders List                   │   │
│  │  ╔═══════════════════════════════════════════╗ │   │
│  │  ║ Order #1234 - ₹450 - Pending            ║ │   │
│  │  ║ Order #1235 - ₹890 - Preparing          ║ │   │
│  │  ║ Order #1236 - ₹120 - Delivered          ║ │   │
│  │  ╚═══════════════════════════════════════════╝ │   │
│  └────────────────────────────────────────────────┘   │
│                                                         │
│  ┌────────────────────────────────────────────────┐   │
│  │         Revenue Chart (Last 7 Days)            │   │
│  │         Line/Bar Chart using fl_chart          │   │
│  └────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Audio Alert System

The app includes custom audio alerts for important events:

- **new_order.mp3**: Played when new order arrives
- **order_cancelled.mp3**: Order cancellation alert
- **payment_received.mp3**: Payment confirmation
- **low_stock.mp3**: Low inventory warning
- **urgent_alert.mp3**: Critical notifications

```dart
// Audio playback implementation
await AudioService.play('new_order.mp3');
```

---

## 🚀 Build & Deployment

### Development Build

```bash
# Run on mobile/emulator
flutter run

# Run on web
flutter run -d chrome

# Run with specific base URL
flutter run --dart-define=API_URL=http://192.168.1.11:8080
```

### Production Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Environment Configuration

```dart
// lib/utils/app_config.dart
class AppConfig {
  static String get apiBaseUrl {
    if (kIsProduction) {
      return 'https://api.nammaooru.com';
    } else {
      return 'http://192.168.1.11:8080/api';
    }
  }
}
```

---

## 🔐 Security Considerations

1. **JWT Token Storage**: Tokens stored securely in SharedPreferences
2. **HTTPS Only**: Production uses SSL/TLS encryption
3. **Input Validation**: All user inputs validated before API calls
4. **File Upload Security**: Image validation (type, size, dimensions)
5. **Authorization**: All API calls include Bearer token
6. **Session Management**: Auto-logout on token expiration

---

## 📈 Performance Optimizations

1. **Image Caching**: `cached_network_image` for efficient image loading
2. **Lazy Loading**: Orders and products loaded on-demand
3. **Debouncing**: Search queries debounced to reduce API calls
4. **State Optimization**: Provider pattern prevents unnecessary rebuilds
5. **Audio Preloading**: Sound files preloaded for instant playback
6. **WebSocket**: Real-time updates without polling

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Integration tests
flutter drive --target=test_driver/app.dart
```

---

## 📚 Additional Resources

- **Flutter Documentation**: https://flutter.dev/docs
- **Provider Package**: https://pub.dev/packages/provider
- **Firebase Messaging**: https://firebase.flutter.dev/docs/messaging
- **Backend API Docs**: See `TECHNICAL_ARCHITECTURE.md`

---

**Document Version**: 1.0
**Last Updated**: January 2025
**Maintained By**: NammaOoru Development Team
