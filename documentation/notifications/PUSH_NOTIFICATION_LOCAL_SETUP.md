# Push Notification Local Setup Guide

## Overview
Push notifications are now fully integrated in the Thiru Software System. When a shop owner accepts an order, the customer will receive a push notification on their device.

## How It Works

### 1. FCM Token Registration (Mobile App)
When a user logs in on the mobile app:
1. The app gets an FCM token from Firebase
2. Sends it to backend: `POST /api/customer/notifications/fcm-token`
3. Backend stores the token in `user_fcm_tokens` table

### 2. Order Acceptance Flow
When a shop owner accepts an order:
1. Shop owner calls: `POST /api/orders/{orderId}/accept`
2. Backend updates order status to CONFIRMED
3. Backend fetches customer's FCM token from database
4. Sends push notification via Firebase

## Database Setup

### Create FCM Token Table
```sql
CREATE TABLE IF NOT EXISTS user_fcm_tokens (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    fcm_token VARCHAR(500) NOT NULL,
    device_type VARCHAR(20),
    device_id VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_fcm_token (fcm_token)
);
```

## Backend Configuration

### 1. Add Firebase Server Key
In `application.properties` or `application.yml`:
```properties
firebase.server-key=YOUR_FIREBASE_SERVER_KEY
firebase.project-id=YOUR_PROJECT_ID
```

### 2. Get Firebase Server Key
1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project
3. Go to Project Settings > Cloud Messaging
4. Copy the "Server key" (legacy) or create a new one

## Testing Push Notifications Locally

### 1. Test with Mobile App
```bash
# 1. Start backend server
cd backend
mvn spring-boot:run

# 2. Install and run mobile app
cd mobile/nammaooru_mobile_app
flutter run
```

### 2. Test Notification Endpoint
```bash
# Test push notification for logged-in user
curl -X GET http://localhost:8080/api/customer/notifications/test-push \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 3. Test Order Acceptance
```bash
# Accept an order (triggers push notification)
curl -X PUT http://localhost:8080/api/orders/1/accept \
  -H "Authorization: Bearer SHOP_OWNER_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "estimatedPreparationTime": "30",
    "notes": "Order will be ready soon"
  }'
```

## Flow Diagram

```
User Login (Mobile App)
    ↓
Get FCM Token from Firebase
    ↓
Send Token to Backend
    ↓
Store in user_fcm_tokens table
    ↓
...
Shop Owner Accepts Order
    ↓
Backend: acceptOrder() method
    ↓
Get Customer's User ID
    ↓
Fetch FCM Token from DB
    ↓
Send via FirebaseNotificationService
    ↓
Customer Receives Push Notification
```

## Notification Payload

When an order is accepted, the customer receives:

```json
{
  "notification": {
    "title": "Order Confirmed! 🎉",
    "body": "Your order #ORD-001 has been confirmed and is being prepared.",
    "icon": "/assets/icons/notification.png"
  },
  "data": {
    "type": "order_update",
    "orderNumber": "ORD-001",
    "status": "CONFIRMED",
    "timestamp": "1234567890"
  }
}
```

## Troubleshooting

### 1. Notification Not Received
- Check if FCM token is saved in database:
  ```sql
  SELECT * FROM user_fcm_tokens WHERE user_id = ?;
  ```
- Verify Firebase server key is configured
- Check backend logs for errors

### 2. Invalid FCM Token
- Token may be expired
- User needs to logout and login again
- Check if app has notification permissions

### 3. Backend Errors
- Ensure `UserFcmToken` entity is mapped correctly
- Check if `UserFcmTokenRepository` has required methods
- Verify Firebase dependencies are included

## Test Scenarios

### Scenario 1: New User Registration
1. User registers on mobile app
2. After successful registration, login
3. FCM token should be sent and stored
4. Verify in database

### Scenario 2: Order Flow
1. Customer places order
2. Shop owner views pending orders
3. Shop owner accepts order
4. Customer receives push notification
5. Notification appears in app

### Scenario 3: Multiple Devices
1. User logs in on multiple devices
2. Each device gets its own FCM token
3. All active tokens receive notifications

## Security Considerations

1. **Token Validation**: Always validate FCM tokens before storing
2. **User Authentication**: Only authenticated users can update tokens
3. **Token Cleanup**: Regularly clean up expired/invalid tokens
4. **Rate Limiting**: Implement rate limiting for notification APIs

## Implementation Files

### Backend
- `/backend/src/main/java/com/shopmanagement/entity/UserFcmToken.java`
- `/backend/src/main/java/com/shopmanagement/repository/UserFcmTokenRepository.java`
- `/backend/src/main/java/com/shopmanagement/service/FirebaseNotificationService.java`
- `/backend/src/main/java/com/shopmanagement/service/OrderService.java` (acceptOrder method)
- `/backend/src/main/java/com/shopmanagement/controller/FcmTokenController.java`

### Mobile App
- `/mobile/nammaooru_mobile_app/lib/services/firebase_notification_service.dart`
- `/mobile/nammaooru_mobile_app/lib/services/notification_api_service.dart`
- `/mobile/nammaooru_mobile_app/lib/core/auth/auth_provider.dart`

## Next Steps

1. **Configure Firebase Server Key** in backend properties
2. **Test with real devices** (not emulators for FCM)
3. **Implement notification history** in app
4. **Add notification preferences** for users
5. **Implement topic-based notifications** for broadcasts