# Location Tracking Implementation - NammaOoru Delivery Partner App

## Overview

The delivery partner app implements intelligent location tracking with dynamic intervals based on the driver's order status:
- **Idle Mode**: 5-minute intervals when no active orders
- **Active Mode**: 30-second intervals when orders are accepted/in-progress

## Implementation Details

### 1. Location Service (`location_service.dart`)

#### Key Features:
- **Dynamic Intervals**: Switches between 2-minute and 30-second intervals automatically
- **Environment Configuration**: Intervals can be configured from environment variables
- **Battery Optimization**: Includes battery level and network type in location updates
- **Assignment Tracking**: Tracks current order ID and status with location data

#### Location Tracking Modes:
```dart
enum LocationTrackingMode {
  idle,        // No active orders - 5 minute intervals
  activeOrder, // Has active order - 30 second intervals
}
```

#### Configuration:
```dart
// Set custom intervals programmatically
LocationService.setTrackingIntervals(
  idleInterval: 300,    // 5 minutes
  activeInterval: 30,   // 30 seconds
);

// Get current configuration
Map<String, int> intervals = locationService.getTrackingIntervals();
```

### 2. API Integration

#### Location Update Endpoint:
```
PUT /api/mobile/delivery-partner/update-location/{partnerId}
```

#### Request Payload:
```json
{
  "latitude": 12.9716,
  "longitude": 77.5946,
  "accuracy": 15.0,
  "speed": 5.2,
  "heading": 180.0,
  "altitude": 920.0,
  "batteryLevel": 75,
  "networkType": "WIFI",
  "assignmentId": 123,
  "orderStatus": "picked_up"
}
```

### 3. Automatic Tracking Lifecycle

#### Start Tracking:
1. **After Login**: Location tracking starts in idle mode (5-minute intervals)
2. **Online Status**: Tracking continues only when driver is online
3. **Order Acceptance**: Switches to active mode (30-second intervals)

#### Tracking Flow:
```
Login → Load Profile → Start Location Tracking (Idle: 5min)
  ↓
Accept Order → Switch to Active Mode (30sec intervals)
  ↓
Order Status Changes → Continue Active Mode
  ↓
Order Delivered → Switch back to Idle Mode (5min)
  ↓
Go Offline → Stop Location Tracking
```

### 4. Configuration Management

#### Environment Configuration (`location_config.dart`):
```dart
class LocationConfig {
  static const int DEFAULT_IDLE_INTERVAL = 300;    // 5 minutes
  static const int DEFAULT_ACTIVE_INTERVAL = 30;   // 30 seconds

  static void initialize({
    int? idleIntervalSeconds,
    int? activeIntervalSeconds,
  }) {
    LocationService.setTrackingIntervals(
      idleInterval: idleIntervalSeconds ?? DEFAULT_IDLE_INTERVAL,
      activeInterval: activeIntervalSeconds ?? DEFAULT_ACTIVE_INTERVAL,
    );
  }
}
```

#### Usage in main.dart:
```dart
void main() async {
  // Initialize with custom intervals
  LocationConfig.initialize(
    idleIntervalSeconds: 300,   // 5 minutes
    activeIntervalSeconds: 30,  // 30 seconds
  );

  runApp(DeliveryPartnerApp());
}
```

### 5. Provider Integration

#### Automatic Order Status Tracking:
```dart
// In DeliveryPartnerProvider
void _updateLocationTrackingForOrders() {
  final hasActiveOrder = _activeOrders.any((order) =>
      order.status == 'accepted' ||
      order.status == 'picked_up' ||
      order.status == 'in_transit');

  if (hasActiveOrder) {
    // Switch to 30-second intervals
    final activeOrder = _activeOrders.firstWhere(...);
    _locationService.setAssignmentInfo(
      activeOrder.id,
      activeOrder.status,
    );
  } else {
    // Switch to 2-minute intervals
    _locationService.setAssignmentInfo(null, null);
  }
}
```

### 6. Manual Configuration Methods

#### Runtime Configuration:
```dart
// Configure from provider
provider.configureLocationTracking(
  idleIntervalSeconds: 180,    // 3 minutes
  activeIntervalSeconds: 20,   // 20 seconds
);

// Get current tracking information
Map<String, dynamic> info = provider.getLocationTrackingInfo();
print('Current mode: ${info['currentMode']}');
print('Intervals: ${info['intervals']}');
```

## API Backend Integration

### Expected Backend Endpoint

The backend should implement the location update endpoint:

```java
@PutMapping("/update-location/{partnerId}")
public ResponseEntity<?> updateLocation(
    @PathVariable String partnerId,
    @RequestBody LocationUpdateRequest request
) {
    // Update driver location in database
    // Include timestamp, order context, and metadata
    return ResponseEntity.ok().build();
}
```

### Database Schema

Recommended database structure for storing location updates:

```sql
CREATE TABLE delivery_partner_locations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    partner_id VARCHAR(50) NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    accuracy DECIMAL(8,2),
    speed DECIMAL(8,2),
    heading DECIMAL(8,2),
    altitude DECIMAL(8,2),
    battery_level INT,
    network_type VARCHAR(20),
    assignment_id BIGINT,
    order_status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_partner_time (partner_id, created_at),
    INDEX idx_assignment (assignment_id)
);
```

## Error Handling and Recovery

### Location Permission Handling:
```dart
Future<bool> checkLocationPermission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return false;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  return permission != LocationPermission.denied &&
         permission != LocationPermission.deniedForever;
}
```

### Network Failure Recovery:
- Location updates are stored locally if network fails
- Automatic retry mechanism for failed API calls
- Battery and network status included in updates

## Testing and Debugging

### Debug Information:
```dart
Map<String, dynamic> info = provider.getLocationTrackingInfo();
print('Debug Info: $info');

// Output example:
{
  "currentMode": "activeOrder",
  "hasActiveOrder": true,
  "intervals": {
    "idleInterval": 120,
    "activeInterval": 30
  },
  "currentPosition": {
    "latitude": 12.9716,
    "longitude": 77.5946,
    "accuracy": 15.0,
    "timestamp": "2025-01-23T10:30:45.123Z"
  }
}
```

### Console Logs:
- `🔧 Location tracking configured` - Configuration loaded
- `📍 Location updated` - Location successfully obtained
- `🎯 Enhanced location tracking started` - Tracking started
- `🛑 Enhanced location tracking stopped` - Tracking stopped
- `📤 Location sent to server successfully` - API call successful
- `❌ Failed to send location to server` - API call failed

## Performance Optimization

### Battery Optimization:
1. **Intelligent Intervals**: Longer intervals when idle
2. **Conditional Tracking**: Only track when online
3. **Distance Filter**: Update only when moved significantly
4. **Network-aware**: Include network status to optimize server processing

### Memory Management:
1. **Singleton Pattern**: One location service instance
2. **Proper Cleanup**: Stop tracking on logout/offline
3. **Stream Management**: Cancel subscriptions properly

## Security Considerations

1. **Permission Handling**: Proper location permission management
2. **Data Privacy**: Location data transmitted over HTTPS
3. **Authentication**: All API calls include auth tokens
4. **Minimal Data**: Only necessary location metadata included

## Usage Examples

### Basic Setup:
```dart
// In main.dart
LocationConfig.initialize();

// In provider after login
await _startLocationTracking();
```

### Custom Configuration:
```dart
// Configure different intervals for testing
LocationConfig.initialize(
  idleIntervalSeconds: 60,    // 1 minute for testing
  activeIntervalSeconds: 10,  // 10 seconds for testing
);
```

### Manual Control:
```dart
// Start tracking manually
await locationService.startEnhancedLocationTracking();

// Stop tracking manually
locationService.stopEnhancedLocationTracking();
```

---

**Key Benefits:**
- ✅ Automatic interval switching based on order status
- ✅ Environment-configurable intervals
- ✅ Battery and network optimization
- ✅ Comprehensive error handling
- ✅ Real-time order context tracking
- ✅ Easy debugging and monitoring

**Last Updated:** January 23, 2025