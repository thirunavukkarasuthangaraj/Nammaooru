# Firebase Notification Issue - Resolution Guide

## ✅ Current Status

**Firebase Backend**: ✅ **WORKING**
- Firebase Admin SDK initialized successfully in production
- Credentials loaded: `/app/firebase-config/firebase-service-account.json`
- Project: `nammaooru-shop-management`

**Notification Code**: ✅ **EXISTS**
- `acceptOrder()` method sends notifications to customers (line 650)
- Code calls: `firebaseNotificationService.sendOrderNotification()`

## ❌ Problem

**Shop owner accepts order → Customer receives NO notification**

## 🔍 Root Cause Analysis

### The Issue
The notification code exists and Firebase is working, but notifications fail because:

1. **FCM Tokens Not Stored** - Mobile apps might not be registering FCM tokens with backend
2. **No Active Tokens** - Database has no active FCM tokens for users
3. **Token Registration Not Called** - Apps don't call the FCM token API on login

### Code Flow (What SHOULD Happen)

```
Mobile App Login
    ↓
Get FCM Token from Firebase
    ↓
POST /api/customer/notifications/fcm-token  (or /api/shop-owner/notifications/fcm-token)
    ↓
Token stored in user_fcm_tokens table
    ↓
Order accepted by shop owner
    ↓
Backend fetches FCM token from database
    ↓
Firebase sends notification to device
    ↓
✅ Customer receives notification
```

### What's Happening NOW

```
Mobile App Login
    ↓
❌ FCM token NOT sent to backend (or endpoint failing)
    ↓
Order accepted by shop owner
    ↓
Backend finds NO FCM tokens for user
    ↓
⚠️ Log: "No user found" or empty token list
    ↓
❌ Customer receives NO notification
```

## 🛠️ Solution Steps

### Step 1: Verify FCM Token Endpoints Exist

Check if these endpoints are working:

```bash
# For Customer App
POST /api/customer/notifications/fcm-token
Content-Type: application/json
Authorization: Bearer <JWT_TOKEN>

{
  "fcmToken": "device-fcm-token-here",
  "deviceType": "ANDROID",
  "deviceId": "unique-device-id"
}

# For Shop Owner App
POST /api/shop-owner/notifications/fcm-token
Content-Type: application/json
Authorization: Bearer <JWT_TOKEN>

{
  "fcmToken": "device-fcm-token-here",
  "deviceType": "ANDROID",
  "deviceId": "unique-device-id"
}
```

### Step 2: Check Mobile App FCM Integration

**Customer App** (`mobile/nammaooru_mobile_app/`):
1. Verify Firebase is initialized on app startup
2. Check FCM token is retrieved on login
3. Ensure token is sent to backend API

**Shop Owner App** (`mobile/shop-owner-app/`):
1. Verify Firebase is initialized on app startup
2. Check FCM token is retrieved on login
3. Ensure token is sent to backend API

**Key Code to Check** (Flutter):
```dart
// 1. Initialize Firebase
await Firebase.initializeApp();

// 2. Get FCM Token
FirebaseMessaging messaging = FirebaseMessaging.instance;
String? token = await messaging.getToken();

// 3. Send to Backend
final response = await http.post(
  Uri.parse('$baseUrl/api/customer/notifications/fcm-token'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $jwtToken',
  },
  body: jsonEncode({
    'fcmToken': token,
    'deviceType': 'ANDROID',
    'deviceId': deviceId,
  }),
);
```

### Step 3: Test FCM Token Storage

**Test with Postman/cURL**:

```bash
# 1. Login as customer
curl -X POST https://nammaoorudelivary.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "customer_username",
    "password": "password"
  }'

# 2. Store FCM Token
curl -X POST https://nammaoorudelivary.in/api/customer/notifications/fcm-token \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN_FROM_LOGIN>" \
  -d '{
    "fcmToken": "test-fcm-token-12345",
    "deviceType": "ANDROID",
    "deviceId": "test-device-001"
  }'

# 3. Verify in database
# Connect to database and check:
SELECT * FROM user_fcm_tokens WHERE user_id = <USER_ID>;
```

### Step 4: Check Backend Logs

After shop owner accepts order, check logs:

```bash
# SSH to production
ssh root@nammaoorudelivary.in

# Check notification logs
docker logs nammaooru-backend 2>&1 | grep -E "Accepting order|Push notification|FCM token|No user found" | tail -50
```

**Expected Logs** (if working):
```
Accepting order: 123 with estimated preparation time: 30
✅ Push notification sent successfully to customer for order: ORD123
```

**Error Logs** (if failing):
```
⚠️ No user found for customer email: customer@email.com
⚠️ Failed to send notification with token...
```

### Step 5: Database Check

**Check FCM tokens in database**:

```sql
-- Check total FCM tokens
SELECT COUNT(*) FROM user_fcm_tokens WHERE is_active = true;

-- Check tokens by user role
SELECT u.role, COUNT(uft.id) as token_count
FROM users u
LEFT JOIN user_fcm_tokens uft ON u.id = uft.user_id
WHERE uft.is_active = true
GROUP BY u.role;

-- Check specific user's tokens
SELECT uft.*, u.username, u.email, u.role
FROM user_fcm_tokens uft
JOIN users u ON u.id = uft.user_id
WHERE u.email = 'customer@email.com'
  AND uft.is_active = true;
```

## 📱 Mobile App Requirements

### What Mobile Apps MUST Do

1. **Initialize Firebase on Startup**
   ```dart
   await Firebase.initializeApp();
   ```

2. **Request Notification Permission**
   ```dart
   NotificationSettings settings = await messaging.requestPermission();
   if (settings.authorizationStatus == AuthorizationStatus.authorized) {
     print('User granted permission');
   }
   ```

3. **Get FCM Token on Login**
   ```dart
   String? token = await FirebaseMessaging.instance.getToken();
   ```

4. **Send Token to Backend**
   ```dart
   await apiService.storeFcmToken(token);
   ```

5. **Handle Token Refresh**
   ```dart
   FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
     apiService.storeFcmToken(newToken);
   });
   ```

6. **Handle Foreground Notifications**
   ```dart
   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
     // Show notification UI
   });
   ```

## 🔧 Quick Fix Guide

### Immediate Actions

1. **Check if mobile apps are calling FCM token API**
   - Add logs in mobile app when FCM token is obtained
   - Add logs when sending to backend
   - Check API response

2. **Test with one user**
   - Manually store FCM token in database:
   ```sql
   INSERT INTO user_fcm_tokens (user_id, fcm_token, device_type, is_active)
   VALUES (
     (SELECT id FROM users WHERE email = 'test@email.com'),
     'TEST_FCM_TOKEN_FROM_DEVICE',
     'ANDROID',
     true
   );
   ```

3. **Accept an order and check backend logs**
   - See if backend finds the FCM token
   - See if notification is sent
   - Check for any errors

## 📋 Verification Checklist

- [ ] Firebase initialized in backend (✅ DONE - confirmed working)
- [ ] Mobile apps initialize Firebase on startup
- [ ] Mobile apps get FCM token after login
- [ ] Mobile apps send FCM token to backend API
- [ ] Backend stores FCM token in database
- [ ] Backend retrieves FCM token when order accepted
- [ ] Firebase sends notification to device
- [ ] Device receives notification

## 🎯 Expected Behavior

### When Customer Logs In
1. App gets FCM token from Firebase
2. App sends token to: `POST /api/customer/notifications/fcm-token`
3. Backend stores token in `user_fcm_tokens` table
4. Response: `200 OK`

### When Shop Owner Accepts Order
1. Backend finds customer's user record
2. Backend fetches customer's active FCM token from database
3. Backend calls `firebaseNotificationService.sendOrderNotification()`
4. Firebase sends notification to customer's device
5. Customer receives: "Order Confirmed! Your order has been accepted..."

## 🐛 Common Issues

### Issue 1: "No FCM tokens found"
**Cause**: Mobile app not sending FCM token to backend
**Fix**: Implement FCM token registration in mobile app

### Issue 2: "Invalid FCM token"
**Cause**: Old/expired tokens in database
**Fix**: Implement token refresh logic in mobile app

### Issue 3: "User not found"
**Cause**: Customer email doesn't match user email in database
**Fix**: Ensure customer record has correct email

### Issue 4: "Permission denied"
**Cause**: User hasn't granted notification permission
**Fix**: Request permission in mobile app on first launch

## 📞 Next Steps

1. **Check Customer App**: Verify it calls `/api/customer/notifications/fcm-token` after login
2. **Check Shop Owner App**: Verify it calls `/api/shop-owner/notifications/fcm-token` after login
3. **Test Token Storage**: Manually test the FCM token API endpoints
4. **Monitor Logs**: Watch backend logs when order is accepted
5. **Fix Mobile Apps**: Add FCM token registration if missing

## 📚 Related Files

- **Backend**:
  - `backend/src/main/java/com/shopmanagement/service/OrderService.java` (line 632-665)
  - `backend/src/main/java/com/shopmanagement/service/FirebaseService.java`
  - `backend/src/main/java/com/shopmanagement/config/FirebaseConfig.java`

- **Mobile Apps**:
  - Customer App: `mobile/nammaooru_mobile_app/`
  - Shop Owner App: `mobile/shop-owner-app/`

---

**Last Updated**: October 24, 2025
**Status**: Firebase backend working ✅ | Mobile integration needed 🔧
