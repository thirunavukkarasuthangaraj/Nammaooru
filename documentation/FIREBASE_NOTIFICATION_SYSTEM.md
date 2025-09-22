# Firebase Notification System Documentation

## Overview
Complete Firebase Cloud Messaging (FCM) implementation for real-time push notifications across the NammaOoru Shop Management System.

## Architecture Components

### 1. Backend (Spring Boot)

#### Firebase Configuration
- **Location**: `backend/src/main/java/com/shopmanagement/config/FirebaseConfig.java`
- **Service Account**: `backend/src/main/resources/firebase-service-account.json`
- **Dependencies**: Firebase Admin SDK v9.2.0 in `pom.xml`

#### Core Services

##### FirebaseService.java
```java
- sendNotificationToUser(userId, title, body, data, type)
- sendNotificationToShop(shopId, title, body, data)
- sendNotificationToRole(role, title, body, data)
- sendBulkNotifications(tokens, title, body, data)
```

##### NotificationTriggerService.java
Handles automatic notifications for:
- New order placed → Shop owner notification
- Order accepted → Customer notification
- Order status changes → Relevant party notifications
- Delivery assignments → Delivery partner notifications

#### Database Schema
```sql
TABLE user_fcm_tokens (
  id BIGINT PRIMARY KEY,
  user_id BIGINT,
  token VARCHAR(500),
  device_type VARCHAR(50),
  device_info TEXT,
  is_active BOOLEAN,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
```

### 2. Frontend (Angular)

#### Firebase Configuration
- **Config File**: `frontend/src/firebase-messaging-sw.js`
- **Dependencies**:
  - `@angular/fire: ^7.6.1`
  - `firebase: ^9.23.0`

#### Core Services

##### FirebaseService.ts
Located at: `frontend/src/app/core/services/firebase.service.ts`

**Key Features:**
- FCM token management
- Message reception handling
- Browser notification display
- Debouncing mechanism (prevents duplicate sounds)
- Order notification formatting

**Methods:**
```typescript
- requestPermission(): Observable<string>
- getToken(): Observable<string>
- receiveMessage(): Observable<any>
- showNotification(title, options)
- sendOrderNotification(orderNumber, status, message)
```

##### NotificationOrchestratorService.ts
Coordinates notifications across different channels:
- Firebase push notifications
- Email notifications
- In-app notifications
- WebSocket real-time updates

### 3. Mobile App (Flutter)

#### Configuration Files
- **Android**: `mobile/nammaooru_mobile_app/android/app/google-services.json`
- **iOS**: AppDelegate.swift configured for FCM

#### Firebase Service
Located at: `mobile/nammaooru_mobile_app/lib/services/firebase_notification_service.dart`

**Features:**
- Token registration with backend
- Foreground/background message handling
- Local notification display
- Auto-refresh on notification receipt

## Notification Flow

### 1. Order Placement Flow
```
Customer places order
    ↓
Backend creates order
    ↓
NotificationTriggerService.onOrderPlaced()
    ↓
FirebaseService.sendNotificationToShop(shopId)
    ↓
FCM sends to shop owner devices
    ↓
Shop owner receives push notification
```

### 2. Token Registration Flow
```
App Launch → Request Permission → Get FCM Token
    ↓
Send to Backend: POST /api/firebase/register-token
    ↓
Store in user_fcm_tokens table
    ↓
Token ready for notifications
```

## Notification Types

### Shop Owner Notifications
| Event | Title | Priority | Action Required |
|-------|-------|----------|-----------------|
| New Order | 🆕 New Order Received | High | Yes - Accept/Reject |
| Order Cancelled | ❌ Order Cancelled | High | No |
| Order Returned | ↩️ Order Returned | High | Yes - Process refund |
| Payment Received | 💰 Payment Confirmed | Medium | No |

### Customer Notifications
| Event | Title | Priority | Action Required |
|-------|-------|----------|-----------------|
| Order Accepted | ✅ Order Accepted | High | No |
| Out for Delivery | 🚚 Order Out for Delivery | High | No |
| Delivered | ✔️ Order Delivered | Medium | Yes - Rate/Review |
| Order Rejected | 🚫 Order Rejected | High | No |

### Delivery Partner Notifications
| Event | Title | Priority | Action Required |
|-------|-------|----------|-----------------|
| New Assignment | 📦 New Delivery Assignment | High | Yes - Accept |
| Route Update | 🗺️ Route Updated | Medium | No |
| Customer Update | 📍 Delivery Address Changed | High | Yes - Confirm |

## Implementation Details

### Frontend Implementation

#### Shop Owner Dashboard Integration
```typescript
// Dashboard Component
unreadNotificationCount: number = 0;

loadNotificationCount(): void {
  // Fetches orders and counts unread notifications
  // Pending orders + Recent orders (24h) = unread count
}
```

#### Notification Component Features
- Real-time updates via Firebase messaging
- Auto-refresh every 30 seconds
- Filter by type, priority, status
- Bulk actions (mark all read)
- Order details display with items
- Accept/Reject actions for pending orders

### Backend Implementation

#### REST Endpoints
```
POST /api/firebase/register-token
POST /api/firebase/send-notification
POST /api/firebase/send-bulk
DELETE /api/firebase/unregister-token
GET /api/firebase/test-notification
```

#### Order Status Notification Mapping
```java
@EventListener
public void handleOrderStatusChange(OrderStatusChangeEvent event) {
    switch(event.getNewStatus()) {
        case ACCEPTED:
            sendCustomerNotification("Order Accepted", ...);
            break;
        case OUT_FOR_DELIVERY:
            sendCustomerNotification("Out for Delivery", ...);
            sendDeliveryPartnerNotification("Pickup Ready", ...);
            break;
        case DELIVERED:
            sendCustomerNotification("Order Delivered", ...);
            sendShopNotification("Order Completed", ...);
            break;
    }
}
```

## Security Considerations

1. **Token Security**
   - FCM tokens stored encrypted in database
   - Tokens expire and auto-refresh
   - Device-specific token validation

2. **Permission Management**
   - User must grant notification permission
   - Fallback to in-app notifications if denied
   - Graceful degradation for unsupported browsers

3. **Rate Limiting**
   - Notification debouncing (1 second minimum gap)
   - Bulk notification batching (max 500 per request)
   - Daily notification limits per user

## Testing

### Test Notification Flow
1. Register FCM token: `POST /api/firebase/register-token`
2. Send test notification: `GET /api/firebase/test-notification`
3. Verify receipt in app/browser
4. Check notification history in database

### Debug Commands
```bash
# Check registered tokens
curl http://localhost:8080/api/firebase/tokens

# Send test notification
curl -X POST http://localhost:8080/api/firebase/test-notification \
  -H "Authorization: Bearer {token}"

# Monitor notification logs
tail -f logs/notification.log
```

## Troubleshooting

### Common Issues

1. **Duplicate Notification Sounds**
   - Solution: Debouncing implemented with 1-second delay
   - Check: `FirebaseService.notificationDebounceTime`

2. **Notifications Not Received**
   - Check: Browser notification permissions
   - Verify: FCM token registration successful
   - Test: Use test endpoint to verify connectivity

3. **Service Worker Issues**
   - Location: Must be in root (`/firebase-messaging-sw.js`)
   - HTTPS: Required for service workers (except localhost)
   - Cache: Clear browser cache if updates not reflecting

## Performance Optimizations

1. **Batching**: Bulk notifications sent in batches of 500
2. **Caching**: 15-minute token cache to reduce database queries
3. **Async Processing**: Non-blocking notification sending
4. **Queue Management**: Redis queue for high-volume periods

## Monitoring

### Key Metrics
- Notification delivery rate
- Token registration success rate
- Average delivery time
- Failed notification count
- User engagement rate

### Logging
```
INFO: Notification sent successfully to user {userId}
WARN: FCM token expired for user {userId}
ERROR: Failed to send notification: {error}
```

## Future Enhancements

1. **Rich Notifications**
   - Image attachments
   - Action buttons
   - Custom sounds

2. **Analytics**
   - Click-through rates
   - Conversion tracking
   - A/B testing

3. **Segmentation**
   - Location-based notifications
   - Behavior-based targeting
   - Scheduled campaigns

4. **Web Push**
   - Safari push notification support
   - PWA enhancements
   - Offline notification queue

## Configuration Files

### Firebase Project Config
```json
{
  "project_info": {
    "project_number": "368788713881",
    "project_id": "grocery-5ecc5",
    "storage_bucket": "grocery-5ecc5.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:368788713881:android:7c1dba64bacddbfd866308",
        "android_client_info": {
          "package_name": "com.nammaooru.app"
        }
      }
    }
  ]
}
```

## Support & Maintenance

- Firebase Console: https://console.firebase.google.com/project/grocery-5ecc5
- Documentation: https://firebase.google.com/docs/cloud-messaging
- Support Email: support@nammaooru.com