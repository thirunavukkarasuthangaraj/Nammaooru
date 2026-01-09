# FCM (Firebase Cloud Messaging) Troubleshooting Guide

## Common Issue: Driver Not Receiving Notifications

### Symptoms
- Driver app not receiving FCM notifications for order assignments
- Shop owner receives email but driver doesn't get push notification
- Notifications work sometimes but not consistently

### Root Causes

| Error Message | Meaning | Solution |
|---------------|---------|----------|
| `UNREGISTERED` | Token expired but recoverable | Refresh token |
| `Requested entity was not found` / `404 Not Found` | Token completely invalid | **Must install new APK** |
| `InvalidRegistration` | Token format is wrong | Re-register token |

---

## Diagnosis Steps

### Step 1: Check Server Logs
```bash
ssh root@api.nammaoorudelivary.in "docker logs --tail 100 shop-management_backend_87 2>&1 | grep -iE 'FCM|notification|ERROR|firebase'"
```

### Step 2: Check FCM Tokens in Database
```bash
ssh root@api.nammaoorudelivary.in "sudo -u postgres psql -d shop_management_db -c \"SELECT id, user_id, device_id, LEFT(fcm_token::text, 40) as token_preview, is_active, updated_at FROM user_fcm_tokens ORDER BY updated_at DESC LIMIT 20;\""
```

### Step 3: Find Delivery Partner's User ID
```bash
ssh root@api.nammaoorudelivary.in "sudo -u postgres psql -d shop_management_db -c \"SELECT id, username, email, role FROM users WHERE role = 'DELIVERY_PARTNER';\""
```

### Step 4: Check Specific Driver's Tokens
```bash
# Replace USER_ID with actual user ID (e.g., 43)
ssh root@api.nammaoorudelivary.in "sudo -u postgres psql -d shop_management_db -c \"SELECT id, LEFT(fcm_token::text, 40), is_active, updated_at FROM user_fcm_tokens WHERE user_id = USER_ID ORDER BY updated_at DESC;\""
```

---

## Solutions

### Solution 1: Driver Reinstalls APK (Most Common Fix)

**When to use**: Error shows `404 Not Found` or `Requested entity was not found`

1. Build new driver APK:
```bash
cd D:/AAWS/nammaooru/shop-management-system/mobile/nammaooru_delivery_partner
flutter pub get
flutter build apk --release
```

2. APK location: `build/app/outputs/flutter-apk/app-release.apk`

3. Send APK to driver and ask them to:
   - Install the new APK
   - **Open the app** (this triggers token refresh)

4. Verify token was registered:
```bash
ssh root@api.nammaoorudelivary.in "sudo -u postgres psql -d shop_management_db -c \"SELECT id, is_active, updated_at FROM user_fcm_tokens WHERE user_id = USER_ID ORDER BY updated_at DESC LIMIT 5;\""
```

### Solution 2: Manually Deactivate Invalid Tokens

**When to use**: Multiple tokens exist, some invalid

```bash
# Deactivate all tokens for a user except the latest one
ssh root@api.nammaoorudelivary.in "sudo -u postgres psql -d shop_management_db -c \"UPDATE user_fcm_tokens SET is_active = false WHERE user_id = USER_ID AND id NOT IN (SELECT id FROM user_fcm_tokens WHERE user_id = USER_ID ORDER BY updated_at DESC LIMIT 1);\""
```

### Solution 3: Delete All Tokens and Re-register

**When to use**: Nothing else works

```bash
# Delete all tokens for the user
ssh root@api.nammaoorudelivary.in "sudo -u postgres psql -d shop_management_db -c \"DELETE FROM user_fcm_tokens WHERE user_id = USER_ID;\""
```

Then ask driver to:
1. Close the app completely
2. Open the app again
3. Token will be auto-registered

---

## How FCM Token Registration Works

### Driver App Flow (firebase_mobile_init.dart)
1. App opens → `initializeFirebase()` is called
2. Gets FCM token from Firebase
3. Registers token with backend via `/api/delivery-partner/notifications/fcm-token`
4. On token refresh → automatically re-registers

### Backend Flow
1. Receives token registration request
2. Saves to `user_fcm_tokens` table with `is_active = true`
3. Deactivates old tokens for same device

### When Sending Notification (OrderAssignmentService.java)
1. Queries `user_fcm_tokens` for active tokens: `findByUserIdAndIsActiveTrue(userId)`
2. Tries each token until one succeeds
3. If token fails with `UNREGISTERED`/`NOT_FOUND`, marks it as inactive

---

## Key Files

| File | Purpose |
|------|---------|
| `mobile/nammaooru_delivery_partner/lib/firebase_mobile_init.dart` | FCM token registration on driver app |
| `backend/.../service/OrderAssignmentService.java` | Sends assignment notifications |
| `backend/.../service/FirebaseNotificationService.java` | Core FCM sending logic |
| `backend/.../repository/UserFcmTokenRepository.java` | Token database queries |

---

## Database Tables

### user_fcm_tokens
| Column | Description |
|--------|-------------|
| id | Primary key |
| user_id | References users table |
| fcm_token | The Firebase token (500 chars) |
| device_id | Device identifier |
| device_type | android/ios |
| is_active | true = valid token |
| created_at | When token was first saved |
| updated_at | Last update time |

---

## Quick Commands Reference

```bash
# Check backend health
curl -s "https://api.nammaoorudelivary.in/actuator/health"

# Watch live logs for FCM
ssh root@api.nammaoorudelivary.in "docker logs -f --tail 50 shop-management_backend_87 2>&1 | grep -iE 'FCM|notification|assign'"

# Check recent orders and their assignment status
ssh root@api.nammaoorudelivary.in "sudo -u postgres psql -d shop_management_db -c \"SELECT o.order_number, o.status, oa.status as assignment_status, oa.created_at FROM orders o LEFT JOIN order_assignments oa ON o.id = oa.order_id ORDER BY o.created_at DESC LIMIT 10;\""

# Check delivery partner user
ssh root@api.nammaoorudelivary.in "sudo -u postgres psql -d shop_management_db -c \"SELECT id, username, email FROM users WHERE role = 'DELIVERY_PARTNER';\""
```

---

## Prevention

The driver app now has automatic token refresh (`reRegisterFcmToken()`) that runs:
1. When app opens
2. When user logs in
3. When Firebase rotates the token

This should prevent future token expiration issues.

---

## Contact

If issue persists after following this guide:
1. Check server logs for specific error message
2. Verify driver has latest APK installed
3. Verify driver opened the app after installation
4. Check database for active tokens

Last updated: 2026-01-10
