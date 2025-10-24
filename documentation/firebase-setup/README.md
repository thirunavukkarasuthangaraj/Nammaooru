# Firebase Push Notification Setup - Complete Guide

This folder contains all documentation related to Firebase Cloud Messaging (FCM) setup for the NammaOoru platform.

## 📁 Documentation Index

### 1. [FIREBASE_BACKEND_SETUP.md](./FIREBASE_BACKEND_SETUP.md)
**Backend Firebase Configuration**
- FirebaseConfig setup and initialization
- Service account configuration
- Production deployment steps
- Troubleshooting backend issues

### 2. [MOBILE_APP_FIREBASE_SETUP.md](./MOBILE_APP_FIREBASE_SETUP.md)
**Mobile App Firebase Setup**
- Android Firebase setup
- iOS Firebase setup (if applicable)
- google-services.json configuration
- Mobile app FCM token registration

### 3. [FIREBASE_NOTIFICATION_SYSTEM.md](./FIREBASE_NOTIFICATION_SYSTEM.md)
**Complete Notification System Architecture**
- System overview
- Notification types
- Topic-based messaging
- User-specific notifications

### 4. [PUSH_NOTIFICATION_GUIDE.md](./PUSH_NOTIFICATION_GUIDE.md)
**General Push Notification Guide**
- How notifications work
- Best practices
- Testing notifications
- Production considerations

### 5. [PUSH_NOTIFICATION_LOCAL_SETUP.md](./PUSH_NOTIFICATION_LOCAL_SETUP.md)
**Local Development Setup**
- Setting up Firebase for local development
- Testing notifications locally
- Debugging tips
- Local vs Production differences

### 6. [PUSH_NOTIFICATION_TROUBLESHOOTING.md](./PUSH_NOTIFICATION_TROUBLESHOOTING.md)
**Troubleshooting Guide**
- Common issues and solutions
- Debugging checklist
- Error messages explained
- Support resources

## 🚀 Quick Start

### For Backend Developers

1. Read [FIREBASE_BACKEND_SETUP.md](./FIREBASE_BACKEND_SETUP.md)
2. Set up service account credentials
3. Configure environment variables
4. Deploy and verify initialization

### For Mobile Developers

1. Read [MOBILE_APP_FIREBASE_SETUP.md](./MOBILE_APP_FIREBASE_SETUP.md)
2. Download google-services.json from Firebase Console
3. Configure FCM in mobile app
4. Test token registration

### For Local Testing

1. Read [PUSH_NOTIFICATION_LOCAL_SETUP.md](./PUSH_NOTIFICATION_LOCAL_SETUP.md)
2. Set up local Firebase credentials
3. Run backend locally
4. Test with mobile emulator/device

## 🔧 Setup Checklist

### Backend Setup
- [ ] Firebase project created in Firebase Console
- [ ] Service account key downloaded
- [ ] `firebase-service-account.json` placed in `firebase-config/` folder
- [ ] Environment variables configured in `docker-compose.yml`
- [ ] Backend deployed and Firebase initialized successfully
- [ ] Database table `user_fcm_tokens` exists

### Mobile App Setup
- [ ] `google-services.json` (Android) added to project
- [ ] FCM dependencies added to build.gradle/pubspec.yaml
- [ ] Notification permissions requested
- [ ] FCM token registration implemented
- [ ] Token sent to backend on login

### Testing
- [ ] Backend logs show Firebase initialization success
- [ ] Mobile app can register FCM token
- [ ] Token stored in database
- [ ] Test notification sent successfully
- [ ] Notification received on device

## 🌍 Environment Configuration

### Local Development
```bash
# Environment variable
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-config/firebase-service-account.json
```

### Production
```bash
# Docker environment
FIREBASE_SERVICE_ACCOUNT_PATH=/app/firebase-config/firebase-service-account.json
```

## 📱 Supported Platforms

- **Shop Owner App** (Android)
- **Customer App** (Android)
- **Delivery Partner App** (Android)

## 🔐 Security Notes

⚠️ **NEVER commit Firebase credentials to Git!**

Files to keep secret:
- `firebase-service-account.json`
- `google-services.json` (contains API keys)

These files are in `.gitignore` for security.

## 🆘 Need Help?

1. Check [PUSH_NOTIFICATION_TROUBLESHOOTING.md](./PUSH_NOTIFICATION_TROUBLESHOOTING.md)
2. Review backend logs: `docker logs nammaooru-backend`
3. Check Firebase Console for delivery status
4. Review mobile app logs

## 📊 Current Status

### Backend
- ✅ Firebase Admin SDK integrated
- ✅ FCM token storage implemented
- ✅ Notification service created
- 🔄 Production initialization (in progress)

### Mobile Apps
- ✅ Shop Owner App - FCM integrated
- ✅ Customer App - FCM integrated
- ✅ Delivery Partner App - FCM integrated

## 🔄 Recent Updates

- **2025-10-24**: Fixed Firebase environment variable mapping (`FIREBASE_SERVICE_ACCOUNT_PATH`)
- **2025-10-24**: Added debug logging to FirebaseConfig
- **2025-10-24**: Created comprehensive documentation folder

## 📚 Related Documentation

- `/backend/src/main/java/com/shopmanagement/config/FirebaseConfig.java`
- `/backend/src/main/java/com/shopmanagement/service/FirebaseService.java`
- `/firebase-config/README.md`

## 🎯 Firebase Project Details

**Project Name**: NammaOoru Shop Management
**Project ID**: `nammaooru-shop-management`
**Region**: Default (us-central1)

## ⚡ Quick Commands

### Check Firebase Status (Production)
```bash
ssh root@nammaoorudelivary.in
docker logs nammaooru-backend 2>&1 | grep -i firebase
```

### Test Notification
```bash
curl -X POST "https://nammaoorudelivary.in/api/fcm/tokens" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "fcmToken": "test-token",
    "deviceType": "ANDROID",
    "deviceId": "test-device"
  }'
```

### View FCM Tokens in Database
```sql
SELECT u.username, uft.device_type, uft.is_active, uft.created_at
FROM user_fcm_tokens uft
JOIN users u ON u.id = uft.user_id
WHERE uft.is_active = true
ORDER BY uft.created_at DESC;
```

---

**Last Updated**: October 24, 2025
**Maintained by**: Development Team
