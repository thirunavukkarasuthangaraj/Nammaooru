# Push Notification Troubleshooting Guide

## Issue: Order Notifications Not Being Received

### Root Cause Analysis
After analyzing the codebase, the push notification system is properly configured but requires the following conditions to work:

### ✅ What's Working
1. **Firebase Configuration**: Firebase Admin SDK is properly initialized in the backend
2. **Notification Service**: `FirebaseNotificationService.java` is correctly implemented
3. **Order Service Integration**: Notifications are triggered on order status updates in `OrderService.java`
4. **FCM Token Endpoint**: The `/api/customer/notifications/fcm-token` endpoint exists and works
5. **Mobile App Integration**: Firebase is configured in the mobile app and FCM tokens are sent on login

### 🔍 Requirements for Push Notifications to Work

#### 1. FCM Token Must Be Registered
- **When**: After customer login
- **Where**: `auth_provider.dart` calls `FirebaseNotificationService.initializeWithPermissions()`
- **Verification**: Check if FCM token is stored in `user_fcm_tokens` table

#### 2. Customer Must Have a User Account
- **Issue**: Order notifications look up customer by email to find user ID
- **Code Location**: `OrderService.java` lines 256-277
- **Solution**: Ensure customer email in order matches user email in `users` table

#### 3. Firebase Service Account Must Be Valid
- **File**: `backend/src/main/resources/firebase-service-account.json`
- **Verification**: Check backend logs for "Firebase Admin SDK initialized successfully"

### 📋 Testing Checklist

#### Step 1: Verify FCM Token Registration
```sql
-- Check if customer has FCM token
SELECT u.id, u.username, u.email, uft.fcm_token, uft.is_active
FROM users u
LEFT JOIN user_fcm_tokens uft ON u.id = uft.user_id
WHERE u.email = 'customer_email@example.com';
```

#### Step 2: Test Push Notification Endpoint
```bash
# Login as customer
curl -X POST http://localhost:8080/api/customer/login \
  -H "Content-Type: application/json" \
  -d '{"emailOrMobile":"customer_email","password":"password"}'

# Test push notification (use token from login response)
curl -X GET http://localhost:8080/api/customer/notifications/test-push \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Step 3: Mobile App Setup
1. **Run the mobile app**:
   ```bash
   cd mobile/nammaooru_mobile_app
   flutter run
   ```

2. **Login as customer**:
   - Use registered customer credentials
   - Grant notification permissions when prompted
   - Check console logs for "FCM Token: ..." message

3. **Verify token registration**:
   - Check backend logs for "FCM token saved successfully"
   - Verify token in database using SQL query above

#### Step 4: Test Order Flow
1. **Create an order** through the mobile app
2. **Update order status** (as shop owner):
   - Login to shop owner dashboard
   - Find the order
   - Change status to "CONFIRMED", "PREPARING", "READY_FOR_PICKUP", etc.
3. **Check mobile device** for push notification

### 🐛 Common Issues and Solutions

#### Issue 1: No FCM Token in Database
**Symptoms**: `user_fcm_tokens` table is empty
**Solution**:
- Ensure mobile app has notification permissions
- Check if FCM token endpoint is being called on login
- Verify Firebase configuration in mobile app

#### Issue 2: Customer Email Mismatch
**Symptoms**: Notification code can't find user for customer
**Solution**:
- Ensure customer email in `customers` table matches email in `users` table
- Check logs for "No user found for customer email" warning

#### Issue 3: Firebase Authentication Failed
**Symptoms**: "Error sending Firebase notification" in backend logs
**Solution**:
- Verify `firebase-service-account.json` is valid
- Check Firebase project configuration matches between backend and mobile
- Ensure Firebase Cloud Messaging API is enabled in Google Cloud Console

#### Issue 4: Mobile App Not Receiving Notifications
**Symptoms**: Backend shows notification sent but mobile doesn't receive
**Solution**:
- Check if app is in foreground (notifications may be silent)
- Verify notification permissions are granted on device
- Check if FCM token is still valid (tokens can expire)
- Test with Firebase Console to isolate backend issues

### 📱 Mobile App Debug Commands

```dart
// Check current FCM token
final token = await FirebaseMessaging.instance.getToken();
print('Current FCM Token: $token');

// Check notification permissions
final settings = await FirebaseMessaging.instance.getNotificationSettings();
print('Notification permission status: ${settings.authorizationStatus}');

// Force token refresh
await FirebaseMessaging.instance.deleteToken();
final newToken = await FirebaseMessaging.instance.getToken();
print('New FCM Token: $newToken');
```

### 🔧 Backend Debug Points

1. **OrderService.java:253-281**: Where notifications are sent on status update
2. **FirebaseNotificationService.java:18-28**: Main notification sending method
3. **FcmTokenController.java:30-88**: FCM token registration endpoint

### 📊 Monitoring Notifications

#### Backend Logs to Watch
```
✅ "Firebase Admin SDK initialized successfully"
✅ "FCM token saved successfully for user: {userId}"
✅ "Push notification sent to customer for order status update"
✅ "Firebase notification sent successfully. Message ID: {messageId}"

❌ "No FCM token found for customer user ID: {userId}"
❌ "No user found for customer email: {email}"
❌ "Error sending Firebase notification for order: {orderNumber}"
```

### 🚀 Quick Fix Steps

1. **Restart backend** with proper Firebase config
2. **Login to mobile app** as customer
3. **Grant notification permissions**
4. **Create a test order**
5. **Update order status** from shop owner dashboard
6. **Check notification** on mobile device

### 💡 Pro Tips

1. Use Firebase Console to send test notifications directly
2. Enable verbose logging in Firebase for debugging
3. Test on real device (not emulator) for best results
4. Keep FCM tokens fresh by implementing token refresh logic
5. Monitor Firebase Cloud Messaging dashboard for delivery stats

---

## Need More Help?

If notifications still aren't working:
1. Check Firebase project settings match across all components
2. Verify Google Services JSON/plist files are up to date
3. Ensure Firebase Cloud Messaging API is enabled
4. Check device-specific notification settings
5. Review backend logs for specific error messages