# 🚚 NammaOoru Delivery Partner Mobile App - Technical Architecture

## 📋 Document Overview

**Purpose**: Complete technical documentation for Delivery Partner Flutter mobile application
**Platform**: Flutter (iOS, Android, Web)
**Audience**: Developers, Mobile Engineers, Technical Stakeholders
**Last Updated**: January 2025

---

## 🎯 App Overview

The Delivery Partner mobile app is a specialized Flutter application designed for delivery partners to manage order pickups, deliveries, real-time navigation, earnings tracking, and route optimization with GPS-based location services.

### Key Capabilities
- 📦 **Order Management**: Accept, pickup, and deliver customer orders
- 🗺️ **Real-time Navigation**: Google Maps integration with turn-by-turn directions
- 📍 **Location Tracking**: Continuous GPS tracking during deliveries
- 🔔 **Push Notifications**: Real-time order assignment notifications
- 💰 **Earnings Dashboard**: Track daily, weekly, and monthly earnings
- ✅ **OTP Verification**: Secure order handover with OTP confirmation
- 📸 **Proof of Delivery**: Photo capture and signature collection
- 📊 **Performance Stats**: Delivery metrics and rating system

---

## 🏗️ Application Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                 Delivery Partner Mobile App Architecture                    │
│                            (Flutter Framework)                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                             Presentation Layer                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │     Home     │  │   Orders     │  │  Navigation  │  │   Earnings   │  │
│  │   Dashboard  │  │  Available   │  │   Screen     │  │    Screen    │  │
│  │              │  │   Active     │  │              │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Profile    │  │   Settings   │  │  OTP Verify  │  │  Completion  │  │
│  │   Screen     │  │   Screen     │  │   Screen     │  │   Screen     │  │
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
│  ┌───────────────────────┐  ┌───────────────────────┐  ┌──────────────┐  │
│  │ DeliveryPartnerProvider│  │   LocationProvider    │  │OrderProvider │  │
│  │ - Partner info        │  │ - Current position    │  │ - Orders     │  │
│  │ - Online status       │  │ - Tracking active     │  │ - Filters    │  │
│  │ - Availability        │  │ - Location history    │  │ - Stats      │  │
│  │ - Earnings            │  │ - ETA calculation     │  │              │  │
│  └───────────────────────┘  └───────────────────────┘  └──────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                             Business Logic Layer                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │   API Service    │  │ Location Service │  │  Storage Service │         │
│  │  - HTTP Calls    │  │  - GPS Tracking  │  │  - Local Cache   │         │
│  │  - Auth Headers  │  │  - Geolocator    │  │  - JWT Storage   │         │
│  │  - Error Handle  │  │  - Battery Track │  │  - Preferences   │         │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘         │
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │  Firebase FCM    │  │ DeliveryConfirm  │  │  Maps Service    │         │
│  │  - Push Notify   │  │  Service         │  │  - Route Display │         │
│  │  - Token Mgmt    │  │  - OTP Verify    │  │  - Directions    │         │
│  │  - Background    │  │  - Photo Capture │  │  - Polylines     │         │
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
│  │  Backend API     │  │  Google Maps API │  │  Local Storage   │         │
│  │  HTTP REST       │  │  Directions API  │  │  SharedPrefs     │         │
│  │  Port: 8080      │  │  Geocoding API   │  │  GPS Cache       │         │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📱 Screen Flow Architecture

### Main Navigation & Order Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Screen Navigation Flow                               │
└─────────────────────────────────────────────────────────────────────────┘

                        ┌──────────────────┐
                        │  Login Screen    │
                        │  (Auth + OTP)    │
                        └────────┬─────────┘
                                 │
                        ┌────────▼─────────┐
                        │  Main Dashboard  │
                        │  (Home Screen)   │
                        └────────┬─────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
    ┌────▼────┐           ┌──────▼──────┐        ┌─────▼─────┐
    │Available│           │   Active    │        │  Earnings │
    │ Orders  │           │   Orders    │        │  History  │
    │         │           │             │        │           │
    └────┬────┘           └──────┬──────┘        └───────────┘
         │                       │
         │                       │
    ┌────▼──────────┐      ┌────▼──────────┐
    │ Order Details │      │  Navigation   │
    │ Accept/Reject │      │  Screen       │
    └────┬──────────┘      │  (Maps)       │
         │                 └────┬──────────┘
         │                      │
    ┌────▼──────────┐           │
    │ Pickup from   │      ┌────▼──────────┐
    │ Shop (OTP)    │      │ Arrive at     │
    └────┬──────────┘      │ Destination   │
         │                 └────┬──────────┘
         │                      │
         └──────────┬───────────┘
                    │
            ┌───────▼────────┐
            │ OTP Handover   │
            │ Screen         │
            └───────┬────────┘
                    │
            ┌───────▼────────┐
            │ Delivery       │
            │ Completion     │
            │ (Photo/Sign)   │
            └───────┬────────┘
                    │
            ┌───────▼────────┐
            │ Return to      │
            │ Dashboard      │
            └────────────────┘
```

---

## 🔄 Complete API Call Flow

### Order Acceptance & Delivery Flow

```
┌──────────┐                                           ┌──────────┐
│Delivery  │                                           │ Backend  │
│Partner   │                                           │ API      │
│ App      │                                           │          │
└────┬─────┘                                           └────┬─────┘
     │                                                      │
     │ ═══ PARTNER LOGS IN ═══                             │
     │                                                      │
     │ 1. Login with credentials                           │
     ├──────────────────────────────────────────────────►  │
     │      POST /api/delivery-partner/login               │
     │      Body: { email, password }                      │
     │                                                      │
     │                                  2. Validate creds   │
     │                                     Generate JWT    │
     │                                                      │
     │  3. Return auth response                            │
     │  ◄──────────────────────────────────────────────────┤
     │      { token, partnerId, profile }                  │
     │                                                      │
     │ 4. Store token + load profile                       │
     │    await StorageService.setToken(token)             │
     │    DeliveryPartnerProvider.setPartner(profile)      │
     │                                                      │
     │ ═══ FETCH AVAILABLE ORDERS ═══                      │
     │                                                      │
     │ 5. Get available orders                             │
     ├──────────────────────────────────────────────────►  │
     │      GET /api/delivery-partner/orders/available     │
     │      Headers: { Authorization: Bearer <token> }     │
     │                                                      │
     │                                  6. Query orders    │
     │                                     Filter by zone  │
     │                                                      │
     │  7. Return order list                               │
     │  ◄──────────────────────────────────────────────────┤
     │      { orders: [{...}], count }                     │
     │                                                      │
     │ 8. Update OrderProvider state                       │
     │    OrderProvider.setAvailableOrders(orders)         │
     │                                                      │
     │ ═══ PARTNER ACCEPTS ORDER ═══                       │
     │                                                      │
     │ 9. User taps "Accept Order"                         │
     │                                                      │
     │ 10. Accept order request                            │
     ├──────────────────────────────────────────────────►  │
     │      POST /api/delivery-partner/orders/{id}/accept  │
     │      Body: { partnerId }                            │
     │                                                      │
     │                                  11. Assign order   │
     │                                      Create assign  │
     │                                      Notify shop    │
     │                                                      │
     │  12. Return assignment details                      │
     │  ◄──────────────────────────────────────────────────┤
     │      { assignment: {...}, pickup: {...} }           │
     │                                                      │
     │ 13. Navigate to Navigation Screen                   │
     │     Start location tracking                         │
     │                                                      │
     │ ═══ NAVIGATE TO PICKUP LOCATION ═══                 │
     │                                                      │
     │ 14. LocationProvider starts tracking                │
     │     Get current GPS position                        │
     │     Send location updates every 30s                 │
     │                                                      │
     │ 15. Send location update                            │
     ├──────────────────────────────────────────────────►  │
     │      POST /api/location/partners/{id}/update        │
     │      Body: {                                        │
     │        latitude, longitude, accuracy,               │
     │        speed, heading, batteryLevel,                │
     │        assignmentId, orderStatus                    │
     │      }                                              │
     │                                                      │
     │                                  16. Store location │
     │                                      Update ETA     │
     │                                                      │
     │  17. Return acknowledgment                          │
     │  ◄──────────────────────────────────────────────────┤
     │      { message: "Location updated" }                │
     │                                                      │
     │ ═══ ARRIVE AT SHOP FOR PICKUP ═══                   │
     │                                                      │
     │ 18. Partner arrives, taps "Start Pickup"            │
     │                                                      │
     │ 19. Show OTP verification screen                    │
     │     Request pickup OTP from shop                    │
     │                                                      │
     │ 20. Verify pickup OTP                               │
     ├──────────────────────────────────────────────────►  │
     │      POST /api/delivery-partner/verify-pickup-otp   │
     │      Body: { orderId, otp }                         │
     │                                                      │
     │                                  21. Validate OTP   │
     │                                      Update status  │
     │                                      Mark picked up │
     │                                                      │
     │  22. Return pickup confirmation                     │
     │  ◄──────────────────────────────────────────────────┤
     │      { success: true, order: {...} }                │
     │                                                      │
     │ 23. Update order status to "PICKED_UP"              │
     │     Navigate to customer location                   │
     │                                                      │
     │ ═══ NAVIGATE TO CUSTOMER ═══                        │
     │                                                      │
     │ 24. Continue location tracking                      │
     │     Display route to customer                       │
     │     Calculate ETA                                   │
     │                                                      │
     │ 25. Get ETA to destination                          │
     ├──────────────────────────────────────────────────►  │
     │      POST /api/location/partners/{id}/eta           │
     │      Body: { latitude, longitude }                  │
     │                                                      │
     │                                  26. Calculate ETA  │
     │                                      Based on GPS   │
     │                                                      │
     │  27. Return ETA estimate                            │
     │  ◄──────────────────────────────────────────────────┤
     │      { eta: { estimatedMinutes: 15 } }              │
     │                                                      │
     │ ═══ ARRIVE AT CUSTOMER LOCATION ═══                 │
     │                                                      │
     │ 28. Partner arrives, taps "Complete Delivery"       │
     │                                                      │
     │ 29. Show delivery OTP screen                        │
     │     Get delivery OTP from customer                  │
     │                                                      │
     │ 30. Verify delivery OTP                             │
     ├──────────────────────────────────────────────────►  │
     │      POST /api/delivery-partner/verify-delivery-otp │
     │      Body: { orderId, otp }                         │
     │                                                      │
     │                                  31. Validate OTP   │
     │                                      Update status  │
     │                                                      │
     │  32. Return delivery confirmation                   │
     │  ◄──────────────────────────────────────────────────┤
     │      { success: true, order: {...} }                │
     │                                                      │
     │ 33. Show completion screen                          │
     │     Option to capture photo/signature               │
     │                                                      │
     │ 34. Upload proof of delivery (optional)             │
     ├──────────────────────────────────────────────────►  │
     │      POST /api/delivery-partner/proof               │
     │      Body: FormData(photo, signature)               │
     │                                                      │
     │                                  35. Store proof    │
     │                                      Mark complete  │
     │                                      Update earning │
     │                                                      │
     │  36. Return completion response                     │
     │  ◄──────────────────────────────────────────────────┤
     │      { success: true, earning: 50 }                 │
     │                                                      │
     │ 37. Stop location tracking                          │
     │     Update earnings in provider                     │
     │     Navigate back to dashboard                      │
     │                                                      │
     ▼                                                      ▼
```

---

## 📍 Location Tracking System

### GPS Location Service Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                     Location Tracking System                           │
└────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                        LocationService                               │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Configuration:                                                      │
│  - Update Interval: 10 seconds (local)                             │
│  - Server Update: 30 seconds (backend)                             │
│  - Accuracy: High (GPS + Network)                                  │
│  - Battery Tracking: Enabled                                       │
│  - Network Type: Auto-detect                                       │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────────┐
│                   Location Update Flow                               │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. Permission Check                                                │
│     ├─► Request location permission                                │
│     └─► Request background location (iOS)                          │
│                                                                      │
│  2. Initialize GPS Stream                                           │
│     ├─► Geolocator.getPositionStream()                            │
│     ├─► Accuracy: LocationAccuracy.high                           │
│     └─► DistanceFilter: 10 meters                                 │
│                                                                      │
│  3. Receive Position Updates                                        │
│     ├─► Latitude, Longitude                                        │
│     ├─► Accuracy, Speed, Heading                                   │
│     ├─► Altitude, Timestamp                                        │
│     └─► Battery Level                                              │
│                                                                      │
│  4. Process Location                                                │
│     ├─► Store in LocationProvider                                  │
│     ├─► Calculate distance to destination                          │
│     ├─► Update ETA                                                 │
│     └─► Update map markers                                         │
│                                                                      │
│  5. Server Sync (Every 30s)                                         │
│     ├─► POST /api/location/update                                  │
│     ├─► Include: GPS + Battery + Network                          │
│     └─► Attach: assignmentId + orderStatus                        │
│                                                                      │
│  6. Error Handling                                                  │
│     ├─► Permission denied → Show dialog                            │
│     ├─► GPS disabled → Prompt enable                               │
│     ├─► Network error → Queue updates                              │
│     └─► Battery low → Reduce frequency                             │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Location Data Model

```dart
class LocationUpdate {
  double latitude;
  double longitude;
  double accuracy;        // meters
  double? speed;          // m/s
  double? heading;        // degrees
  double altitude;        // meters
  DateTime timestamp;
  int? batteryLevel;      // percentage
  String? networkType;    // WIFI/4G/5G
  int? assignmentId;
  String? orderStatus;
}
```

---

## 🗺️ Google Maps Integration

### Maps Display & Navigation

```
┌────────────────────────────────────────────────────────────────────────┐
│                   Google Maps Widget Architecture                      │
└────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                    GoogleMapsWidget                                  │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Map Display:                                                        │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                                                             │   │
│  │  📍 Driver Location (Blue Marker)                          │   │
│  │       ↓                                                     │   │
│  │       ├─ Polyline Route (Blue Line)                       │   │
│  │       ↓                                                     │   │
│  │  📍 Shop Location (Orange Marker)                          │   │
│  │       ↓                                                     │   │
│  │       ├─ Polyline Route (Green Line)                      │   │
│  │       ↓                                                     │   │
│  │  📍 Customer Location (Green Marker)                       │   │
│  │                                                             │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Features:                                                           │
│  - Real-time driver position updates                                │
│  - Animated marker movement                                         │
│  - Route polylines with directions API                              │
│  - Distance and ETA calculations                                    │
│  - Auto-zoom to fit all markers                                     │
│  - Traffic layer option                                             │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

API Key: AIzaSyAr_uGbaOnhebjRyz7ohU6N-hWZJVV_R3U
```

### Route Calculation

```dart
// Calculate route between two points
Future<List<LatLng>> getRoute(
  LatLng origin,
  LatLng destination
) async {
  final url = 'https://maps.googleapis.com/maps/api/directions/json'
              '?origin=${origin.latitude},${origin.longitude}'
              '&destination=${destination.latitude},${destination.longitude}'
              '&key=$googleMapsApiKey';

  final response = await http.get(Uri.parse(url));
  final data = json.decode(response.body);

  // Decode polyline points
  final points = PolylinePoints().decodePolyline(
    data['routes'][0]['overview_polyline']['points']
  );

  return points.map((point) =>
    LatLng(point.latitude, point.longitude)
  ).toList();
}
```

---

## 📊 State Management Architecture

### Provider Pattern - Delivery Partner

```
┌─────────────────────────────────────────────────────────────────────┐
│                   DeliveryPartnerProvider State                     │
└─────────────────────────────────────────────────────────────────────┘

DeliveryPartner? _currentPartner
  │
  ├─ partnerId: String
  ├─ name: String
  ├─ phoneNumber: String
  ├─ isOnline: bool
  ├─ isAvailable: bool
  ├─ profileImageUrl: String?
  ├─ earnings: double
  ├─ totalDeliveries: int
  └─ rating: double

List<OrderModel> _availableOrders
List<OrderModel> _activeOrders
List<OrderModel> _orderHistory
Earnings? _earnings
bool _isLoading
String? _error

Methods:
  - login(email, password) → Future<bool>
  - loadProfile() → Future<void>
  - fetchAvailableOrders() → Future<void>
  - fetchActiveOrders() → Future<void>
  - acceptOrder(orderId) → Future<bool>
  - updateOnlineStatus(isOnline) → Future<void>
  - updateAvailability(isAvailable) → Future<void>
  - fetchEarnings() → Future<void>
  - logout() → Future<void>
```

### Provider Pattern - Location

```
┌─────────────────────────────────────────────────────────────────────┐
│                      LocationProvider State                         │
└─────────────────────────────────────────────────────────────────────┘

Position? _currentPosition
  │
  ├─ latitude: double
  ├─ longitude: double
  ├─ accuracy: double
  ├─ altitude: double
  ├─ heading: double
  ├─ speed: double
  └─ timestamp: DateTime

bool _isTracking
String? _currentAssignment
double? _distanceToDestination
Map<String, dynamic>? _etaData

Methods:
  - initializeLocation() → Future<bool>
  - startLocationTracking(partnerId, assignmentId, status) → Future<void>
  - stopLocationTracking() → Future<void>
  - sendLocationUpdate() → Future<void>
  - calculateDistanceToDestination(lat, lng) → double?
  - getETAToDestination(partnerId, lat, lng) → Future<Map?>
  - getCurrentLocation() → Future<Position?>
```

---

## 🔔 Push Notification System

### FCM Integration for Order Assignment

```
┌────────────────────────────────────────────────────────────────────────┐
│                  Firebase Push Notification Flow                       │
└────────────────────────────────────────────────────────────────────────┘

App Launch
    │
    ▼
┌──────────────────────────┐
│ Firebase Init            │
│ FirebaseMessaging.init() │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Request Permissions      │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Get FCM Token            │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐         ┌────────────────┐
│ Send to Backend          ├────────►│ Store in DB    │
│ POST /fcm-token          │         │ delivery_tokens│
└──────────────────────────┘         └────────────────┘

┌──────────────────────────────────────────────────────────┐
│            Receiving Order Assignment                    │
└──────────────────────────────────────────────────────────┘

Backend assigns order to partner
    │
    ▼
┌──────────────────────────┐
│ Backend sends FCM        │
│ to partner's device      │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ FCM delivers notification│
└────────────┬─────────────┘
             │
      ┌──────┴────────┐
      │               │
  Foreground      Background
      │               │
      ▼               ▼
┌──────────────┐ ┌──────────────┐
│onMessage     │ │onBackground  │
│handler       │ │Message       │
└──────┬───────┘ └──────┬───────┘
       │                │
       ▼                ▼
┌────────────────────────────┐
│ Parse notification         │
│ - type: NEW_ORDER          │
│ - orderId: 12345           │
│ - pickupAddress: "..."     │
│ - amount: 450              │
└────────────┬───────────────┘
             │
             ▼
┌────────────────────────────┐
│ Update OrderProvider       │
│ addAvailableOrder(order)   │
└────────────┬───────────────┘
             │
             ▼
┌────────────────────────────┐
│ Show local notification    │
│ Play sound alert           │
│ Navigate if tapped         │
└────────────────────────────┘
```

---

## 📦 Project Structure

```
nammaooru_delivery_partner/
├── lib/
│   ├── main.dart                          # App entry point
│   │
│   ├── core/                              # Core functionality
│   │   ├── api/
│   │   │   └── api_config.dart
│   │   ├── config/
│   │   │   └── app_config.dart            # Base URL config
│   │   ├── constants/
│   │   │   └── api_endpoints.dart
│   │   ├── models/
│   │   │   ├── delivery_partner.dart
│   │   │   └── simple_order_model.dart
│   │   ├── providers/
│   │   │   ├── delivery_partner_provider.dart
│   │   │   └── location_provider.dart
│   │   ├── services/
│   │   │   ├── api_service.dart           # HTTP client
│   │   │   └── location_service.dart      # GPS tracking
│   │   ├── storage/
│   │   │   └── storage_service.dart       # Local storage
│   │   └── widgets/
│   │       └── google_maps_widget.dart    # Map display
│   │
│   ├── features/                          # Feature modules
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   └── services/
│   │   │       └── auth_service.dart
│   │   ├── dashboard/
│   │   │   └── screens/
│   │   │       └── dashboard_screen.dart
│   │   ├── delivery/
│   │   │   ├── screens/
│   │   │   │   ├── delivery_completion_screen.dart
│   │   │   │   └── pickup_confirmation_screen.dart
│   │   │   └── services/
│   │   │       └── delivery_confirmation_service.dart
│   │   ├── earnings/
│   │   │   └── screens/
│   │   │       └── earnings_screen.dart
│   │   ├── home/
│   │   │   └── screens/
│   │   │       └── dashboard_screen.dart
│   │   ├── orders/
│   │   │   ├── screens/
│   │   │   │   ├── active_orders_screen.dart
│   │   │   │   ├── available_orders_screen.dart
│   │   │   │   ├── navigation_screen.dart
│   │   │   │   └── otp_handover_screen.dart
│   │   │   └── widgets/
│   │   │       └── order_card.dart
│   │   ├── profile/
│   │   │   └── screens/
│   │   │       └── profile_screen.dart
│   │   ├── settings/
│   │   │   └── screens/
│   │   │       └── settings_screen.dart
│   │   └── stats/
│   │       └── screens/
│   │           └── stats_screen.dart
│   │
│   └── services/
│       └── firebase_notification_service.dart
│
├── assets/
│   └── (No assets currently)
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
  flutter:
    sdk: flutter

  # Networking
  http: ^1.1.0                             # HTTP client

  # State Management
  provider: ^6.0.5                         # State management

  # Local Storage
  shared_preferences: ^2.2.2               # Key-value storage

  # Maps & Location
  google_maps_flutter: ^2.5.0              # Google Maps
  google_maps_flutter_web: ^0.5.4          # Web support
  geolocator: ^10.1.0                      # GPS location
  geolocator_web: ^2.2.0                   # Web geolocation
  geocoding: ^2.1.1                        # Address lookup
  flutter_polyline_points: ^2.0.0          # Route polylines

  # Permissions
  permission_handler: ^11.1.0              # Runtime permissions

  # Utils
  intl: ^0.18.1                            # Date/number formatting
  url_launcher: ^6.2.2                     # External URLs
  cupertino_icons: ^1.0.2                  # iOS icons

# Note: Firebase and other packages disabled for web build
# - firebase_core
# - firebase_messaging
# - flutter_local_notifications
# - image_picker (camera/photo)
# - signature (digital signatures)
```

---

## 🛠️ API Integration

### API Service Configuration

**Base URL**: `http://192.168.1.11:8080`

### Authentication & Headers

```dart
Future<Map<String, String>> _getHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('delivery_partner_token');

  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
```

### Key API Endpoints

| Method | Endpoint | Purpose | Request | Response |
|--------|----------|---------|---------|----------|
| POST | `/mobile/delivery-partner/login` | Login | `{email, password}` | `{token, partnerId}` |
| GET | `/mobile/delivery-partner/profile/{id}` | Get profile | - | `{partner data}` |
| POST | `/mobile/delivery-partner/status/{id}` | Update online status | `{isOnline}` | `{message}` |
| GET | `/mobile/delivery-partner/orders/available` | Available orders | - | `{orders: [...]}` |
| GET | `/mobile/delivery-partner/orders/active` | Active deliveries | - | `{orders: [...]}` |
| POST | `/mobile/delivery-partner/orders/{id}/accept` | Accept order | `{partnerId}` | `{assignment}` |
| POST | `/location/partners/{id}/update` | Send GPS location | `{lat, lng, ...}` | `{message}` |
| POST | `/location/partners/{id}/eta` | Get ETA | `{lat, lng}` | `{estimatedMinutes}` |
| POST | `/delivery-partner/verify-pickup-otp` | Verify pickup | `{orderId, otp}` | `{success}` |
| POST | `/delivery-partner/verify-delivery-otp` | Verify delivery | `{orderId, otp}` | `{success, earning}` |
| GET | `/mobile/delivery-partner/earnings/{id}` | Get earnings | - | `{earnings, stats}` |

---

## 🚀 Build & Deployment

### Development Build

```bash
# Run on device/emulator
flutter run

# Run on web (with fixes)
flutter run -d chrome

# Run with custom API URL
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

### Web Compatibility Notes

For web builds, the following features are disabled:
- Battery level tracking
- Connectivity status detection
- Camera/image picker
- Digital signatures

These features use platform-specific plugins not supported on web.

---

## 🔐 Security & Permissions

### Required Permissions

**Android (AndroidManifest.xml)**:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

**iOS (Info.plist)**:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show delivery routes</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need background location for real-time tracking</string>
<key>NSCameraUsageDescription</key>
<string>We need camera for proof of delivery photos</string>
```

### Security Measures

1. **JWT Authentication**: All API calls use Bearer token
2. **HTTPS Only**: Production uses SSL/TLS
3. **Location Privacy**: GPS data only sent during active deliveries
4. **OTP Verification**: Secure order handover process
5. **Token Refresh**: Auto-refresh expired JWT tokens
6. **Secure Storage**: Tokens encrypted in SharedPreferences

---

## 📈 Performance Optimizations

1. **Location Batching**: Updates sent every 30s to reduce battery drain
2. **Map Caching**: Google Maps tiles cached locally
3. **State Optimization**: Provider pattern prevents unnecessary rebuilds
4. **Background Location**: Efficient background tracking on iOS/Android
5. **Network Optimization**: API calls debounced and cached
6. **Battery Management**: Reduced GPS accuracy when battery low

---

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart

# Generate coverage report
flutter test --coverage
```

---

## 📚 Additional Resources

- **Flutter Documentation**: https://flutter.dev/docs
- **Google Maps Flutter**: https://pub.dev/packages/google_maps_flutter
- **Geolocator Package**: https://pub.dev/packages/geolocator
- **Provider Pattern**: https://pub.dev/packages/provider
- **Backend API Docs**: See `TECHNICAL_ARCHITECTURE.md`

---

**Document Version**: 1.0
**Last Updated**: January 2025
**Maintained By**: NammaOoru Development Team
