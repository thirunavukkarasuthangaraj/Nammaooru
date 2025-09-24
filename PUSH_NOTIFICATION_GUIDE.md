# Push Notification Guide

## How FCM Token Registration Works

### 1. User Registration/Login Flow
When a user logs in or registers successfully:
1. The app gets an FCM token from Firebase
2. The token is sent to backend endpoint: `POST /api/customer/notifications/fcm-token`
3. Backend stores the token associated with the user ID
4. The app subscribes to user-specific and role-based topics

### 2. Topic Subscriptions
Each user subscribes to multiple topics based on their role:

#### Customer:
- `user_{userId}` - Personal notifications
- `customers` - All customer notifications
- `promotions` - Promotional notifications

#### Shop Owner:
- `user_{userId}` - Personal notifications
- `shop_owners` - All shop owner notifications
- `shop_updates` - Shop-related updates
- `shop_owner_{userId}` - Shop-specific notifications

#### Delivery Partner:
- `user_{userId}` - Personal notifications
- `delivery_partners` - All delivery partner notifications
- `delivery_updates` - Delivery-related updates

## How to Send Push Notifications

### Send to Specific Shop Owner

#### Method 1: Direct FCM Token (Recommended)
```java
// Backend code to send notification to specific shop owner
public void sendNotificationToShopOwner(Long shopOwnerId, String title, String message) {
    // Get FCM token from database
    String fcmToken = userRepository.getFcmTokenByUserId(shopOwnerId);

    if (fcmToken != null) {
        // Send notification using FCM
        Message notification = Message.builder()
            .setToken(fcmToken)
            .setNotification(Notification.builder()
                .setTitle(title)
                .setBody(message)
                .build())
            .putData("type", "shop_notification")
            .putData("shopOwnerId", shopOwnerId.toString())
            .putData("timestamp", String.valueOf(System.currentTimeMillis()))
            .build();

        FirebaseMessaging.getInstance().send(notification);
    }
}
```

#### Method 2: Topic-Based
```java
// Send to shop owner's personal topic
public void sendToShopOwnerTopic(Long shopOwnerId, String title, String message) {
    String topic = "shop_owner_" + shopOwnerId;

    Message notification = Message.builder()
        .setTopic(topic)
        .setNotification(Notification.builder()
            .setTitle(title)
            .setBody(message)
            .build())
        .putData("type", "shop_notification")
        .build();

    FirebaseMessaging.getInstance().send(notification);
}
```

### Send to All Shop Owners
```java
public void sendToAllShopOwners(String title, String message) {
    Message notification = Message.builder()
        .setTopic("shop_owners")
        .setNotification(Notification.builder()
            .setTitle(title)
            .setBody(message)
            .build())
        .build();

    FirebaseMessaging.getInstance().send(notification);
}
```

## Notification Types & Examples

### 1. Order Notification to Shop Owner
```java
public void notifyShopOwnerOfNewOrder(Long shopOwnerId, Order order) {
    sendNotificationToShopOwner(
        shopOwnerId,
        "New Order Received! 🛍️",
        "Order #" + order.getId() + " - ₹" + order.getTotalAmount()
    );
}
```

### 2. Order Status Update to Customer
```java
public void notifyCustomerOrderStatus(Long customerId, Order order) {
    String fcmToken = userRepository.getFcmTokenByUserId(customerId);

    Message notification = Message.builder()
        .setToken(fcmToken)
        .setNotification(Notification.builder()
            .setTitle("Order " + order.getStatus() + " 📦")
            .setBody("Your order #" + order.getId() + " is " + order.getStatus().toLowerCase())
            .build())
        .putData("type", "order")
        .putData("orderId", order.getId().toString())
        .build();

    FirebaseMessaging.getInstance().send(notification);
}
```

### 3. Delivery Assignment to Partner
```java
public void notifyDeliveryPartnerOfAssignment(Long partnerId, Delivery delivery) {
    String fcmToken = userRepository.getFcmTokenByUserId(partnerId);

    Message notification = Message.builder()
        .setToken(fcmToken)
        .setNotification(Notification.builder()
            .setTitle("New Delivery Assigned! 🚚")
            .setBody("Pickup from " + delivery.getShopName())
            .build())
        .putData("type", "delivery")
        .putData("deliveryId", delivery.getId().toString())
        .build();

    FirebaseMessaging.getInstance().send(notification);
}
```

## Database Schema for FCM Tokens

```sql
-- Add FCM token column to users table
ALTER TABLE users ADD COLUMN fcm_token VARCHAR(255);
ALTER TABLE users ADD COLUMN fcm_updated_at TIMESTAMP;

-- Create index for faster queries
CREATE INDEX idx_users_fcm_token ON users(fcm_token);

-- Table to track notification history
CREATE TABLE notification_history (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    title VARCHAR(255),
    message TEXT,
    type VARCHAR(50),
    data JSON,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('sent', 'failed', 'pending'),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

## Backend API Endpoints

### Update FCM Token
```
POST /api/customer/notifications/fcm-token
Headers: Authorization: Bearer {token}
Body: {
    "fcmToken": "firebase_token_here"
}
```

### Send Notification to Specific User
```
POST /api/admin/notifications/send
Headers: Authorization: Bearer {admin_token}
Body: {
    "userId": 123,
    "title": "Notification Title",
    "message": "Notification message",
    "type": "shop_notification",
    "data": {
        "key": "value"
    }
}
```

### Send to Multiple Users
```
POST /api/admin/notifications/send-bulk
Headers: Authorization: Bearer {admin_token}
Body: {
    "userIds": [123, 456, 789],
    "title": "Bulk Notification",
    "message": "Message for multiple users"
}
```

### Send to Role
```
POST /api/admin/notifications/send-by-role
Headers: Authorization: Bearer {admin_token}
Body: {
    "role": "SHOP_OWNER",
    "title": "Shop Owner Update",
    "message": "Important message for all shop owners"
}
```

## Testing Push Notifications

### Using Firebase Console
1. Go to Firebase Console > Cloud Messaging
2. Click "Send your first message"
3. Enter notification details
4. Target by:
   - User segment (all users)
   - Topic (e.g., `shop_owners`)
   - Device token (specific user's FCM token)

### Using cURL
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "DEVICE_FCM_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test"
    },
    "data": {
      "type": "test"
    }
  }'
```

### Using Postman
1. Create a POST request to: `https://fcm.googleapis.com/fcm/send`
2. Headers:
   - Authorization: `key=YOUR_SERVER_KEY`
   - Content-Type: `application/json`
3. Body:
```json
{
    "to": "/topics/shop_owner_123",
    "notification": {
        "title": "New Order!",
        "body": "You have received a new order"
    },
    "data": {
        "type": "order",
        "orderId": "456"
    }
}
```

## Important Notes

1. **Token Expiry**: FCM tokens can expire. Handle token refresh:
   - Listen for token refresh in the app
   - Update backend with new token
   - Remove old tokens

2. **Silent Notifications**: For background updates without showing notification:
   - Send data-only message (no notification payload)
   - App handles in background

3. **Priority**: Set high priority for time-sensitive notifications:
   ```java
   .setAndroidConfig(AndroidConfig.builder()
       .setPriority(AndroidConfig.Priority.HIGH)
       .build())
   ```

4. **iOS Considerations**:
   - Need APNs certificates
   - Request notification permissions
   - Handle provisional authorization

5. **Rate Limits**:
   - FCM has rate limits
   - Batch notifications when possible
   - Use topics for broadcasting