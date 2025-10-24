# NammaOoru Delivery Partner App - Function Flow Documentation

## Table of Contents
1. [App Overview](#app-overview)
2. [Architecture](#architecture)
3. [Function Flow Diagram](#function-flow-diagram)
4. [Core Function Categories](#core-function-categories)
5. [Screen Hierarchy](#screen-hierarchy)
6. [State Management](#state-management)
7. [Services & Providers](#services--providers)
8. [Order Status Flow](#order-status-flow)
9. [API Integration](#api-integration)
10. [Notification System](#notification-system)

## App Overview

The NammaOoru Delivery Partner app is a Flutter-based mobile application designed for delivery partners to manage orders, track earnings, and handle deliveries efficiently. The app provides real-time order updates, navigation assistance, and comprehensive order management features.

### Key Features
- Real-time order notifications
- GPS-based navigation
- OTP verification for order pickup
- Earnings tracking
- Online/offline status management
- Firebase integration for notifications

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                        │
├─────────────────────────────────────────────────────────────┤
│ • Screens (UI Components)                                   │
│ • Widgets (Reusable Components)                            │
│ • Navigation (Route Management)                             │
└─────────────────────────────────────────────────────────────┘
                             │
┌─────────────────────────────────────────────────────────────┐
│                   BUSINESS LOGIC LAYER                      │
├─────────────────────────────────────────────────────────────┤
│ • Providers (State Management)                              │
│ • Services (Business Logic)                                │
│ • Models (Data Structures)                                 │
└─────────────────────────────────────────────────────────────┘
                             │
┌─────────────────────────────────────────────────────────────┐
│                    DATA LAYER                               │
├─────────────────────────────────────────────────────────────┤
│ • API Services                                              │
│ • Local Storage                                             │
│ • WebSocket Services                                        │
│ • Firebase Services                                         │
└─────────────────────────────────────────────────────────────┘
```

## Function Flow Diagram

```
┌────────────────────────────────────────────────────────────────────┐
│                        APP ENTRY POINT                              │
├────────────────────────────────────────────────────────────────────┤
│ main.dart                                                           │
│ └── DeliveryPartnerApp                                             │
│     ├── Initialize Firebase & Notifications                        │
│     ├── Setup Local Storage                                        │
│     └── Provider Setup (DeliveryPartnerProvider)                   │
└────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────┐
│                      AUTHENTICATION FLOW                            │
├────────────────────────────────────────────────────────────────────┤
│ LoginScreen                                                         │
│ ├── Email/Password Login                                           │
│ ├── Password Validation Check                                      │
│ ├── FCM Token Registration                                         │
│ └── Routes:                                                        │
│     ├── ForcePasswordChangeScreen (first login)                   │
│     ├── ForgotPasswordScreen                                       │
│     └── DashboardScreen (successful login)                        │
└────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────┐
│                     MAIN DASHBOARD HUB                              │
├────────────────────────────────────────────────────────────────────┤
│ DashboardScreen                                                     │
│ ├── Online/Offline Toggle                                          │
│ ├── Welcome Card (Profile Info)                                    │
│ ├── Stats Cards (Today's Orders & Earnings)                        │
│ └── Bottom Navigation:                                             │
│     ├── Home Tab                                                   │
│     ├── Earnings Tab                                               │
│     ├── Order History Tab                                          │
│     └── Profile Tab                                                │
└────────────────────────────────────────────────────────────────────┘
                                  │
        ┌─────────────┬──────────┴────────┬─────────────┐
        ▼             ▼                   ▼             ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   HOME TAB   │ │ EARNINGS TAB │ │ ORDERS TAB   │ │ PROFILE TAB  │
├──────────────┤ ├──────────────┤ ├──────────────┤ ├──────────────┤
│ • Stats      │ │ • Today      │ │ • History    │ │ • Edit       │
│ • Active     │ │ • Weekly     │ │ • Completed  │ │ • Vehicle    │
│   Orders     │ │ • Monthly    │ │ • Cancelled  │ │ • Documents  │
│ • Available  │ │ • Payouts    │ │ • Filter     │ │ • Bank       │
│   Orders     │ │              │ │              │ │ • Settings   │
│              │ │              │ │              │ │ • Logout     │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
        │
        ▼
┌────────────────────────────────────────────────────────────────────┐
│                      ORDER MANAGEMENT FLOW                          │
├────────────────────────────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────────────────────────┐  │
│ │ AVAILABLE ORDERS                                              │  │
│ ├──────────────────────────────────────────────────────────────┤  │
│ │ AvailableOrdersScreen                                         │  │
│ │ ├── Load Available Orders                                     │  │
│ │ ├── Order Cards Display                                       │  │
│ │ └── Actions: Accept / Reject                                  │  │
│ └──────────────────────────────────────────────────────────────┘  │
│                              │                                      │
│                              ▼ (Accept)                            │
│ ┌──────────────────────────────────────────────────────────────┐  │
│ │ ACTIVE ORDERS                                                 │  │
│ ├──────────────────────────────────────────────────────────────┤  │
│ │ ActiveOrdersScreen                                            │  │
│ │ ├── Display Accepted Orders                                   │  │
│ │ ├── Status: ACCEPTED → PICKED_UP → IN_TRANSIT → DELIVERED    │  │
│ │ └── Actions:                                                  │  │
│ │     ├── Pick Up (with OTP)                                    │  │
│ │     ├── Navigate to Customer                                  │  │
│ │     ├── Call Customer                                         │  │
│ │     └── Mark Delivered                                        │  │
│ └──────────────────────────────────────────────────────────────┘  │
│                              │                                      │
│                              ▼ (Pick Up)                           │
│ ┌──────────────────────────────────────────────────────────────┐  │
│ │ OTP VERIFICATION                                              │  │
│ ├──────────────────────────────────────────────────────────────┤  │
│ │ OTPHandoverScreen                                             │  │
│ │ ├── 4-digit OTP Input                                         │  │
│ │ ├── Verify with Shop Owner                                    │  │
│ │ └── Update Status to PICKED_UP                                │  │
│ └──────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

## Core Function Categories

### 1. Authentication Functions

| Function | File Location | Description |
|----------|---------------|-------------|
| Login | `features/auth/screens/login_screen.dart` | Email/password authentication |
| Logout | `core/providers/delivery_partner_provider.dart` | Clear session and return to login |
| Force Password Change | `features/profile/screens/force_password_change_screen.dart` | First-time login password update |
| Forgot Password | `features/auth/screens/forgot_password_screen.dart` | Password recovery |
| FCM Token Registration | `services/firebase_notification_service.dart` | Push notification setup |

**Authentication Flow:**
```
Login Screen → Validate Credentials → Check Password Status
    ├── First Login → Force Password Change → Dashboard
    └── Regular Login → Setup Notifications → Dashboard
```

### 2. Order Management Functions

| Function | File Location | Description |
|----------|---------------|-------------|
| Load Available Orders | `features/orders/screens/available_orders_screen.dart` | Fetch orders available for pickup |
| Accept Order | `core/providers/delivery_partner_provider.dart` | Accept an available order |
| Reject Order | `core/providers/delivery_partner_provider.dart` | Decline an order with reason |
| Load Active Orders | `features/orders/screens/active_orders_screen.dart` | Display accepted/in-progress orders |
| OTP Verification | `features/orders/screens/otp_handover_screen.dart` | Verify pickup with 4-digit OTP |
| Update Order Status | `core/providers/delivery_partner_provider.dart` | Change order status (picked_up, delivered) |
| Call Customer | `features/orders/screens/active_orders_screen.dart` | Make phone call to customer |

**Order Management Flow:**
```
Available Orders → Accept → OTP Verification → Pick Up → Navigate → Deliver
                ↓
           Active Orders → Update Status → Order History
```

### 3. Dashboard & Navigation Functions

| Function | File Location | Description |
|----------|---------------|-------------|
| Dashboard Display | `features/dashboard/screens/dashboard_screen.dart` | Main app interface |
| Online/Offline Toggle | `core/providers/delivery_partner_provider.dart` | Availability status control |
| Stats Display | `features/dashboard/screens/dashboard_screen.dart` | Today's orders and earnings |
| Bottom Navigation | `features/dashboard/screens/dashboard_screen.dart` | Tab navigation system |
| Refresh Data | `core/providers/delivery_partner_provider.dart` | Pull-to-refresh functionality |

### 4. Profile & Settings Functions

| Function | File Location | Description |
|----------|---------------|-------------|
| View Profile | `features/dashboard/screens/dashboard_screen.dart` (ProfileTab) | Display partner information |
| Edit Profile | `features/profile/screens/profile_screen.dart` | Update profile details |
| Vehicle Details | Profile section | Manage vehicle information |
| Documents | Profile section | Upload/view required documents |
| Bank Details | Profile section | Banking information for payouts |
| App Settings | `features/profile/screens/app_settings_screen.dart` | Application preferences |

### 5. Earnings Functions

| Function | File Location | Description |
|----------|---------------|-------------|
| View Today's Earnings | `features/earnings/screens/earnings_screen.dart` | Current day earnings |
| Historical Earnings | `features/earnings/screens/earnings_screen.dart` | Past earnings data |
| Earnings Analytics | `core/providers/earnings_provider.dart` | Earnings calculations |
| Payout Management | Earnings section | Withdrawal and payment history |

### 6. Real-time Functions

| Function | File Location | Description |
|----------|---------------|-------------|
| WebSocket Connection | `core/services/websocket_service.dart` | Real-time order updates |
| Push Notifications | `services/firebase_notification_service.dart` | Firebase messaging |
| Location Tracking | `core/services/location_service.dart` | GPS location services |
| Live Order Updates | `core/providers/realtime_provider.dart` | Real-time order status changes |

## Screen Hierarchy

```
DeliveryPartnerApp (Root)
│
├── LoginScreen
│   ├── ForgotPasswordScreen
│   └── ForcePasswordChangeScreen
│
└── DashboardScreen
    ├── HomeTab
    │   ├── AvailableOrdersScreen
    │   │   └── OrderDetailsBottomSheet
    │   ├── ActiveOrdersScreen
    │   │   ├── OrderDetailsBottomSheet
    │   │   ├── OTPHandoverScreen
    │   │   └── NavigationScreen
    │   └── OrderHistoryScreen
    │
    ├── EarningsScreen
    │   ├── EarningsAnalyticsScreen
    │   └── PayoutHistoryScreen
    │
    ├── OrderHistoryTab
    │   └── OrderDetailsBottomSheet
    │
    └── ProfileTab
        ├── ProfileScreen
        ├── AppSettingsScreen
        ├── ChangePasswordScreen
        └── VehicleDetailsScreen
```

## State Management

### DeliveryPartnerProvider
**Location:** `core/providers/delivery_partner_provider.dart`

**Key Properties:**
- `currentPartner`: Current delivery partner data
- `isLoggedIn`: Authentication status
- `isOnline`: Availability status
- `activeOrders`: List of accepted orders
- `availableOrders`: List of orders available for pickup
- `orderHistory`: List of completed orders
- `earnings`: Earnings data
- `error`: Error messages
- `isLoading`: Loading state

**Key Methods:**
```dart
// Authentication
Future<Map<String, dynamic>> loginWithPasswordCheck(String email, String password)
Future<void> logout()
Future<void> checkLoginStatus()

// Order Management
Future<bool> acceptOrder(String orderId)
Future<bool> rejectOrder(String orderId, String reason)
Future<bool> updateOrderStatus(String orderId, String status)
Future<bool> verifyPickupOTP(String orderId, String otp)

// Data Loading
Future<void> loadDashboardData()
Future<void> loadAvailableOrders()
Future<void> loadCurrentOrders()
Future<void> refreshAll()

// Status Management
Future<void> toggleOnlineStatus()
```

### Other Providers

| Provider | Location | Purpose |
|----------|----------|---------|
| AuthProvider | `core/providers/auth_provider.dart` | Authentication management |
| OrderProvider | `core/providers/order_provider.dart` | Order-specific operations |
| LocationProvider | `core/providers/location_provider.dart` | GPS and location services |
| EarningsProvider | `core/providers/earnings_provider.dart` | Earnings calculations |
| RealtimeProvider | `core/providers/realtime_provider.dart` | Real-time updates |

## Services & Providers

### Core Services

| Service | Location | Purpose |
|---------|----------|---------|
| APIService | `core/services/api_service.dart` | HTTP API communication |
| LocalStorage | `core/storage/local_storage.dart` | Local data persistence |
| LocationService | `core/services/location_service.dart` | GPS and location tracking |
| WebSocketService | `core/services/websocket_service.dart` | Real-time communication |
| NavigationService | `core/services/navigation_service.dart` | Route management |

### Firebase Services

| Service | Location | Purpose |
|---------|----------|---------|
| FirebaseNotificationService | `services/firebase_notification_service.dart` | Push notifications |
| FirebaseMessagingService | `core/services/firebase_messaging_service.dart` | Message handling |

## Order Status Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                      ORDER LIFECYCLE                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  AVAILABLE → ACCEPTED → PICKED_UP → IN_TRANSIT → DELIVERED     │
│      ↓          ↓           ↓           ↓            ↓         │
│   [Accept]  [OTP Verify] [Navigate]  [Tracking]  [Complete]    │
│      ↓          ↓           ↓           ↓            ↓         │
│   Show in   Move to     Start GPS    Live Track   Move to     │
│  Available  Active      Navigation    Location    History     │
│   Orders    Orders                                             │
│                                                                 │
│  Alternative Flow:                                              │
│  AVAILABLE → REJECTED (with reason)                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Status Descriptions

| Status | Description | Actions Available |
|--------|-------------|-------------------|
| AVAILABLE | Order is available for pickup | Accept, Reject |
| ACCEPTED | Order has been accepted by delivery partner | OTP Verification, Pick Up |
| PICKED_UP | Order has been picked up from shop | Navigate, Call Customer, Mark Delivered |
| IN_TRANSIT | Order is being delivered | Navigate, Call Customer, Mark Delivered |
| DELIVERED | Order has been successfully delivered | View in History |
| REJECTED | Order was declined by delivery partner | None |

## API Integration

### API Configuration
**Location:** `core/api/api_config.dart`

### API Endpoints
**Location:** `core/constants/api_endpoints.dart`

### Key API Methods

```dart
// Authentication
POST /api/delivery-partner/login
POST /api/delivery-partner/logout
POST /api/delivery-partner/change-password

// Order Management
GET /api/delivery-partner/available-orders
POST /api/delivery-partner/accept-order/{orderId}
POST /api/delivery-partner/reject-order/{orderId}
PUT /api/delivery-partner/update-order-status/{orderId}
POST /api/delivery-partner/verify-pickup-otp

// Profile & Status
GET /api/delivery-partner/profile
PUT /api/delivery-partner/profile
POST /api/delivery-partner/toggle-online-status

// Earnings
GET /api/delivery-partner/earnings
GET /api/delivery-partner/earnings/history
```

## Notification System

### Firebase Messaging Integration

**Setup Process:**
1. Initialize Firebase in `main.dart`
2. Configure FCM tokens in `FirebaseNotificationService`
3. Handle background messages
4. Subscribe to delivery partner topics

**Notification Types:**
- New order available
- Order status updates
- Earnings notifications
- System announcements

**Topic Subscriptions:**
- `delivery_partner_{partnerId}` - Individual notifications
- `delivery_partners_{zone}` - Zone-based notifications
- `all_delivery_partners` - Broadcast notifications

### WebSocket Integration

**Real-time Updates:**
- Order status changes
- New order notifications
- Location updates
- Partner online status

## Data Models

### Core Models

| Model | Location | Purpose |
|-------|----------|---------|
| DeliveryPartner | `core/models/delivery_partner.dart` | Partner profile data |
| OrderModel | `core/models/order_model.dart` | Order information |
| SimpleOrderModel | `core/models/simple_order_model.dart` | Simplified order data |
| EarningsModel | `core/models/earnings_model.dart` | Earnings information |
| StatsModel | `core/models/stats_model.dart` | Dashboard statistics |
| ProfileModel | `core/models/profile_model.dart` | Profile data structure |
| PartnerModel | `core/models/partner_model.dart` | Partner details |

## Key Configuration Files

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Dependencies and project configuration |
| `firebase_options.dart` | Firebase platform configuration |
| `core/constants/app_theme.dart` | UI theme and styling |
| `core/constants/app_colors.dart` | Color scheme |
| `core/constants/api_endpoints.dart` | API endpoint definitions |

## Testing

### Test Structure
```
test/
├── widget_test.dart          # Widget testing
└── unit_tests/               # Unit tests for providers and services
    ├── provider_tests/
    ├── service_tests/
    └── model_tests/
```

## Security Features

1. **Authentication**: Secure email/password login with JWT tokens
2. **OTP Verification**: 4-digit OTP for order pickup verification
3. **Local Storage Encryption**: Secure local data storage
4. **API Security**: HTTPS communication with authentication headers
5. **Firebase Security**: Secure push notification delivery

## Performance Optimizations

1. **Lazy Loading**: Load data only when needed
2. **Caching**: Local storage for frequently accessed data
3. **Real-time Updates**: WebSocket for efficient live updates
4. **Image Optimization**: Optimized image loading and caching
5. **Memory Management**: Proper disposal of controllers and streams

---

**Last Updated:** 2025-01-23
**Version:** 1.0.0
**Author:** Development Team