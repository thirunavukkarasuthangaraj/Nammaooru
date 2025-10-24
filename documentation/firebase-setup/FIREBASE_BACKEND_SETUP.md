# Firebase Backend Setup Guide

This document explains how Firebase Cloud Messaging (FCM) is configured in the backend for push notifications.

## Overview

The NammaOoru backend uses Firebase Admin SDK to send push notifications to:
- Shop Owner App
- Customer App
- Delivery Partner App

## Backend Components

### 1. FirebaseConfig (`backend/src/main/java/com/shopmanagement/config/FirebaseConfig.java`)

**Purpose**: Initializes Firebase Admin SDK on application startup.

**Key Features**:
- Uses `@Configuration` to register as Spring bean
- Uses `@PostConstruct` to initialize Firebase on startup
- Reads Firebase credentials from mounted file
- Validates Firebase project configuration

**Configuration**:
```java
@Value("${firebase.service-account-path:}")
private String firebaseServiceAccountPath;
```

### 2. FirebaseService (`backend/src/main/java/com/shopmanagement/service/FirebaseService.java`)

**Purpose**: Handles all FCM operations.

**Key Methods**:
- `sendNotificationToUser()` - Send to specific user (all devices)
- `sendNotificationToUsers()` - Send to multiple users
- `sendNotificationToTopic()` - Send to topic subscribers
- `storeFcmToken()` - Store/update user FCM tokens
- `subscribeUserToTopics()` - Subscribe users to role-based topics

### 3. FirebaseController (`backend/src/main/java/com/shopmanagement/controller/FirebaseController.java`)

**Purpose**: REST API endpoints for FCM token management.

**Endpoints**:
- `POST /api/fcm/tokens` - Store FCM token
- `POST /api/fcm/subscribe` - Subscribe to topics

### 4. Database Schema

**Table**: `user_fcm_tokens`

```sql
CREATE TABLE user_fcm_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    fcm_token VARCHAR(255) NOT NULL,
    device_type VARCHAR(50),
    device_id VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Production Setup

### 1. Firebase Service Account File

Location: `/opt/shop-management/firebase-config/firebase-service-account.json`

**Required Fields**:
```json
{
  "type": "service_account",
  "project_id": "nammaooru-shop-management",
  "private_key_id": "...",
  "private_key": "...",
  "client_email": "...",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "...",
  "client_x509_cert_url": "..."
}
```

### 2. Environment Configuration

**docker-compose.yml**:
```yaml
environment:
  - FIREBASE_SERVICE_ACCOUNT_PATH=/app/firebase-config/firebase-service-account.json

volumes:
  - ./firebase-config:/app/firebase-config:ro
```

**application.yml**:
```yaml
firebase:
  project-id: ${FIREBASE_PROJECT_ID:nammaooru-shop-management}
  service-account-path: ${FIREBASE_SERVICE_ACCOUNT_PATH:classpath:firebase-service-account.json}
```

### 3. Deployment Steps

1. **Place Firebase credentials on server**:
   ```bash
   # On production server
   cd /opt/shop-management/firebase-config
   nano firebase-service-account.json
   # Paste credentials from Firebase Console
   chmod 600 firebase-service-account.json
   ```

2. **Rebuild and deploy backend**:
   ```bash
   cd /opt/shop-management
   git pull origin main
   docker-compose build --no-cache backend
   docker-compose up -d backend
   ```

3. **Verify Firebase initialization**:
   ```bash
   docker logs nammaooru-backend 2>&1 | grep -i firebase
   ```

   **Expected output**:
   ```
   🔥🔥🔥 FirebaseConfig CLASS LOADING - Static block executed!
   🔥🔥🔥 FirebaseConfig CONSTRUCTOR called!
   🔥🔥🔥 FirebaseConfig @PostConstruct method CALLED!
   📂 Loading Firebase credentials from: /app/firebase-config/firebase-service-account.json
   ✅ Firebase Admin SDK initialized successfully for project: nammaooru-shop-management
   📱 Connected to same Firebase project as mobile app
   ```

## Testing

### 1. Test FCM Token Storage

```bash
curl -X POST "http://localhost:8082/api/fcm/tokens" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "fcmToken": "test-token-123",
    "deviceType": "ANDROID",
    "deviceId": "test-device-001"
  }'
```

### 2. Verify Token in Database

```sql
SELECT * FROM user_fcm_tokens WHERE user_id = YOUR_USER_ID;
```

### 3. Test Notification Sending

When an order status changes, the backend automatically sends notifications:

```java
// Example from OrderService
firebaseService.sendNotificationToUser(
    userId,
    "Order Update",
    "Your order #" + orderId + " status: " + newStatus,
    Map.of("orderId", orderId, "status", newStatus),
    "ORDER_UPDATE"
);
```

## Troubleshooting

### Firebase Not Initializing

**Symptoms**:
- No Firebase logs in startup
- Notifications not being sent
- FCM token storage fails

**Solution**:
1. Check environment variable:
   ```bash
   docker exec nammaooru-backend env | grep FIREBASE
   ```

2. Verify file exists and is readable:
   ```bash
   docker exec nammaooru-backend ls -la /app/firebase-config/
   ```

3. Check for initialization errors:
   ```bash
   docker logs nammaooru-backend 2>&1 | grep -i "firebase\|error"
   ```

### Invalid Credentials

**Symptoms**:
```
❌ Failed to initialize Firebase Admin SDK: Invalid credentials
```

**Solution**:
1. Re-download service account key from Firebase Console
2. Verify JSON is valid: `cat firebase-service-account.json | jq .`
3. Ensure project_id matches mobile app configuration

### Notifications Not Received

**Checklist**:
- [ ] Firebase initialized successfully in backend
- [ ] FCM token stored in database
- [ ] Token is active (is_active = true)
- [ ] Mobile app has correct Firebase configuration
- [ ] Mobile app registered for notifications
- [ ] Device has internet connection
- [ ] Notifications enabled in device settings

## Project Configuration

**Firebase Project**: `nammaooru-shop-management`

**Project ID**: Must match in:
- `FirebaseConfig.java` (line 37)
- Mobile app `google-services.json`
- Firebase service account JSON

## Security

1. **File Permissions**: Service account file should be read-only
   ```bash
   chmod 600 firebase-service-account.json
   ```

2. **Git Ignore**: Never commit credentials
   ```
   # .gitignore
   **/firebase-service-account.json
   !**/firebase-service-account.json.template
   ```

3. **Docker Mount**: Use read-only volume mount
   ```yaml
   volumes:
     - ./firebase-config:/app/firebase-config:ro
   ```

## Related Documentation

- [Push Notification Guide](./PUSH_NOTIFICATION_GUIDE.md)
- [Firebase Notification System](./FIREBASE_NOTIFICATION_SYSTEM.md)
- [Mobile App Setup](./MOBILE_APP_FIREBASE_SETUP.md)
- [Troubleshooting Guide](./PUSH_NOTIFICATION_TROUBLESHOOTING.md)

## Maintenance

### Rotating Service Account Keys

1. Generate new key in Firebase Console
2. Place new key on server
3. Update docker-compose.yml if path changed
4. Restart backend: `docker-compose restart backend`
5. Delete old key from Firebase Console after verification

### Monitoring

Check Firebase Cloud Messaging in Firebase Console:
- Message delivery rates
- Failed delivery reasons
- Active device tokens

## Support

For issues with Firebase setup, check:
1. Backend logs: `docker logs nammaooru-backend`
2. Firebase Console > Cloud Messaging
3. Device logs (Android Studio Logcat / Xcode Console)
