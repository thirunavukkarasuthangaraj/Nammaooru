# Notifications & Communication Documentation

This folder contains all documentation related to Firebase Cloud Messaging (FCM), SMS, and OTP systems for the NammaOoru platform.

## 📁 Documentation Index

### Firebase Push Notifications

#### 1. [FIREBASE_BACKEND_SETUP.md](./FIREBASE_BACKEND_SETUP.md)
**Backend Firebase Configuration**
- FirebaseConfig setup and initialization
- Service account configuration
- Production deployment steps
- Troubleshooting backend issues

#### 2. [MOBILE_APP_FIREBASE_SETUP.md](./MOBILE_APP_FIREBASE_SETUP.md)
**Mobile App Firebase Setup**
- Android Firebase setup
- iOS Firebase setup (if applicable)
- google-services.json configuration
- Mobile app FCM token registration

#### 3. [FIREBASE_NOTIFICATION_SYSTEM.md](./FIREBASE_NOTIFICATION_SYSTEM.md)
**Complete Notification System Architecture**
- System overview
- Notification types
- Topic-based messaging
- User-specific notifications

#### 4. [PUSH_NOTIFICATION_GUIDE.md](./PUSH_NOTIFICATION_GUIDE.md)
**General Push Notification Guide**
- How notifications work
- Best practices
- Testing notifications
- Production considerations

#### 5. [PUSH_NOTIFICATION_LOCAL_SETUP.md](./PUSH_NOTIFICATION_LOCAL_SETUP.md)
**Local Development Setup**
- Setting up Firebase for local development
- Testing notifications locally
- Debugging tips
- Local vs Production differences

#### 6. [PUSH_NOTIFICATION_TROUBLESHOOTING.md](./PUSH_NOTIFICATION_TROUBLESHOOTING.md)
**Troubleshooting Guide**
- Common issues and solutions
- Debugging checklist
- Error messages explained
- Support resources

### MSG91 SMS & OTP System

#### 7. [MSG91_SMS_OTP_IMPLEMENTATION_GUIDE.md](./MSG91_SMS_OTP_IMPLEMENTATION_GUIDE.md)
**Complete MSG91 Implementation Guide** ⭐ **NEW**
- MSG91 account setup
- DLT registration for India
- Template configuration (Template ID: 1207176226012464195)
- Backend configuration
- Complete implementation checklist
- API endpoints documentation
- Testing procedures
- Production deployment guide
- Troubleshooting

#### 8. [MSG91_QUICK_SETUP_CHECKLIST.md](./MSG91_QUICK_SETUP_CHECKLIST.md)
**Quick Setup Reference** ⚡
- 30-minute setup guide
- Registration OTP template (1207176226012464195)
- Essential configuration items
- Pre-go-live checklist
- Quick fixes for common issues

#### 9. [OTP_REGISTRATION_FLOW.md](./OTP_REGISTRATION_FLOW.md)
**OTP Registration Flow Diagram** 📊
- Complete registration flow visualization
- Step-by-step process diagrams
- Error handling flows
- Database schema
- Security features overview

#### 10. [MSG91_API_TESTING_GUIDE.md](./MSG91_API_TESTING_GUIDE.md)
**API Testing & Validation** 🧪
- cURL examples
- Postman collection
- JUnit test cases
- Load testing scripts
- Monitoring queries
- Test scenarios

## 🚀 Quick Start

### For Firebase Push Notifications

#### Backend Developers
1. Read [FIREBASE_BACKEND_SETUP.md](./FIREBASE_BACKEND_SETUP.md)
2. Set up service account credentials
3. Configure environment variables
4. Deploy and verify initialization

#### Mobile Developers
1. Read [MOBILE_APP_FIREBASE_SETUP.md](./MOBILE_APP_FIREBASE_SETUP.md)
2. Download google-services.json from Firebase Console
3. Configure FCM in mobile app
4. Test token registration

#### Local Testing
1. Read [PUSH_NOTIFICATION_LOCAL_SETUP.md](./PUSH_NOTIFICATION_LOCAL_SETUP.md)
2. Set up local Firebase credentials
3. Run backend locally
4. Test with mobile emulator/device

### For MSG91 SMS & OTP

#### Quick Setup (30 minutes)
1. Read [MSG91_QUICK_SETUP_CHECKLIST.md](./MSG91_QUICK_SETUP_CHECKLIST.md)
2. Create MSG91 account and complete KYC
3. Set up DLT registration (India only)
4. Configure template ID: **1207176226012464195**
5. Update backend configuration
6. Test with real mobile number

#### Complete Implementation
1. Read [MSG91_SMS_OTP_IMPLEMENTATION_GUIDE.md](./MSG91_SMS_OTP_IMPLEMENTATION_GUIDE.md)
2. Follow all implementation steps
3. Review [OTP_REGISTRATION_FLOW.md](./OTP_REGISTRATION_FLOW.md) for flow diagrams
4. Test using [MSG91_API_TESTING_GUIDE.md](./MSG91_API_TESTING_GUIDE.md)

## 🔧 Setup Checklist

### Firebase Backend Setup
- [ ] Firebase project created in Firebase Console
- [ ] Service account key downloaded
- [ ] `firebase-service-account.json` placed in `firebase-config/` folder
- [ ] Environment variables configured in `docker-compose.yml`
- [ ] Backend deployed and Firebase initialized successfully
- [ ] Database table `user_fcm_tokens` exists

### Firebase Mobile App Setup
- [ ] `google-services.json` (Android) added to project
- [ ] FCM dependencies added to build.gradle/pubspec.yaml
- [ ] Notification permissions requested
- [ ] FCM token registration implemented
- [ ] Token sent to backend on login

### MSG91 SMS & OTP Setup
- [ ] MSG91 account created and KYC completed
- [ ] MSG91 credits added (minimum ₹500)
- [ ] DLT registration completed (India)
- [ ] DLT Header/Sender ID approved (NMROOU)
- [ ] DLT Template created and approved
- [ ] MSG91 Template ID configured: **1207176226012464195**
- [ ] `MSG91_AUTH_KEY` environment variable set
- [ ] `MSG91_SENDER_ID` environment variable set
- [ ] `SMS_ENABLED=true` in production
- [ ] Backend `application.yml` updated with template IDs
- [ ] Database table `mobile_otps` exists

### Testing - Firebase
- [ ] Backend logs show Firebase initialization success
- [ ] Mobile app can register FCM token
- [ ] Token stored in database
- [ ] Test notification sent successfully
- [ ] Notification received on device

### Testing - MSG91 OTP
- [ ] OTP generation API tested
- [ ] OTP received via SMS within 30 seconds
- [ ] OTP verification API tested
- [ ] Rate limiting tested (max 5 per hour)
- [ ] OTP expiry tested (10 minutes)
- [ ] Max attempts tested (3 attempts)
- [ ] Complete registration flow tested

## 🌍 Environment Configuration

### Local Development - Firebase
```bash
# Environment variable
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-config/firebase-service-account.json
```

### Local Development - MSG91
```bash
MSG91_AUTH_KEY=your-msg91-auth-key
MSG91_SENDER_ID=NMROOU
MSG91_OTP_TEMPLATE_ID=1207176226012464195
SMS_ENABLED=true
```

### Production - Firebase
```bash
# Docker environment
FIREBASE_SERVICE_ACCOUNT_PATH=/app/firebase-config/firebase-service-account.json
```

### Production - MSG91
```bash
# Docker environment variables
MSG91_AUTH_KEY=your-production-auth-key
MSG91_SENDER_ID=NMROOU
MSG91_OTP_TEMPLATE_ID=1207176226012464195
MSG91_ORDER_CONFIRMATION_TEMPLATE_ID=your-template-id
MSG91_ORDER_STATUS_TEMPLATE_ID=your-template-id
MSG91_ORDER_DELIVERED_TEMPLATE_ID=your-template-id
MSG91_WHATSAPP_ENABLED=true
MSG91_NAMESPACE=your-whatsapp-namespace
SMS_ENABLED=true
```

## 📱 Supported Platforms

- **Shop Owner App** (Android)
- **Customer App** (Android)
- **Delivery Partner App** (Android)

## 🔐 Security Notes

⚠️ **NEVER commit sensitive credentials to Git!**

### Firebase Files (Keep Secret)
- `firebase-service-account.json`
- `google-services.json` (contains API keys)

### MSG91 Credentials (Keep Secret)
- `MSG91_AUTH_KEY` - Never hardcode, use environment variables
- MSG91 template IDs are safe to commit (not sensitive)
- DLT Template IDs are safe to commit (not sensitive)

### Security Best Practices
- All credentials must be environment variables
- Use different MSG91 accounts for dev/staging/production
- Rotate MSG91 Auth Key periodically
- Monitor SMS usage for suspicious activity
- Enable IP whitelisting in MSG91 dashboard
- Set up credit alerts to prevent service disruption

These files and credentials are in `.gitignore` for security.

## 🆘 Need Help?

### Firebase Issues
1. Check [PUSH_NOTIFICATION_TROUBLESHOOTING.md](./PUSH_NOTIFICATION_TROUBLESHOOTING.md)
2. Review backend logs: `docker logs nammaooru-backend`
3. Check Firebase Console for delivery status
4. Review mobile app logs

### MSG91 SMS/OTP Issues
1. Check [MSG91_SMS_OTP_IMPLEMENTATION_GUIDE.md - Troubleshooting Section](./MSG91_SMS_OTP_IMPLEMENTATION_GUIDE.md#troubleshooting)
2. Verify DLT registration status
3. Check MSG91 dashboard for delivery reports
4. Review backend logs: `tail -f logs/application.log | grep -E "OTP|SMS|MSG91"`
5. Verify credits in MSG91 account
6. Contact MSG91 Support: support@msg91.com

## 📊 Current Status

### Backend - Firebase
- ✅ Firebase Admin SDK integrated
- ✅ FCM token storage implemented
- ✅ Notification service created
- 🔄 Production initialization (in progress)

### Backend - MSG91 SMS/OTP
- ✅ MobileOtpService implemented
- ✅ WhatsAppNotificationService integrated with MSG91
- ✅ SmsService with multi-provider support
- ✅ OTP database entities created (mobile_otps, email_otps)
- ✅ Rate limiting implemented
- ✅ Security features (device tracking, attempt limits)
- ✅ Scheduled cleanup jobs
- ✅ REST APIs for OTP generation, verification, resend
- 📝 Documentation complete
- ⏳ MSG91 account setup and DLT registration (pending)
- ⏳ Template approval (pending)

### Mobile Apps
- ✅ Shop Owner App - FCM integrated
- ✅ Customer App - FCM integrated
- ✅ Delivery Partner App - FCM integrated
- 📱 OTP verification screens (to be verified)

## 🔄 Recent Updates

- **2025-11-08**: Added comprehensive MSG91 SMS/OTP documentation
- **2025-11-08**: Created MSG91 implementation guide with template ID 1207176226012464195
- **2025-11-08**: Added OTP registration flow diagrams
- **2025-11-08**: Created API testing guide with cURL and Postman examples
- **2025-10-24**: Fixed Firebase environment variable mapping (`FIREBASE_SERVICE_ACCOUNT_PATH`)
- **2025-10-24**: Added debug logging to FirebaseConfig
- **2025-10-24**: Created comprehensive documentation folder

## 📚 Related Documentation

### Firebase Related
- `/backend/src/main/java/com/shopmanagement/config/FirebaseConfig.java`
- `/backend/src/main/java/com/shopmanagement/service/FirebaseService.java`
- `/firebase-config/README.md`

### MSG91 SMS/OTP Related
- `/backend/src/main/java/com/shopmanagement/service/MobileOtpService.java`
- `/backend/src/main/java/com/shopmanagement/service/WhatsAppNotificationService.java`
- `/backend/src/main/java/com/shopmanagement/service/SmsService.java`
- `/backend/src/main/java/com/shopmanagement/entity/MobileOtp.java`
- `/backend/src/main/java/com/shopmanagement/controller/MobileCustomerController.java`
- `/backend/src/main/resources/application.yml` (MSG91 configuration)

## 🎯 Service Configuration Details

### Firebase Project
**Project Name**: NammaOoru Thiru Software
**Project ID**: `nammaooru-shop-management`
**Region**: Default (us-central1)

### MSG91 Configuration
**Service Provider**: MSG91
**Primary Template ID**: `1207176226012464195` (Registration OTP)
**Sender ID**: `NMROOU`
**OTP Validity**: 10 minutes
**Max Attempts**: 3
**Rate Limit**: 5 requests per hour, minimum 2 minutes between requests
**Supported Purposes**: REGISTRATION, LOGIN, FORGOT_PASSWORD, CHANGE_MOBILE, VERIFY_MOBILE, ORDER_CONFIRMATION

## ⚡ Quick Commands

### Firebase - Check Status (Production)
```bash
ssh root@nammaoorudelivary.in
docker logs nammaooru-backend 2>&1 | grep -i firebase
```

### Firebase - Test Notification
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

### Firebase - View FCM Tokens in Database
```sql
SELECT u.username, uft.device_type, uft.is_active, uft.created_at
FROM user_fcm_tokens uft
JOIN users u ON u.id = uft.user_id
WHERE uft.is_active = true
ORDER BY uft.created_at DESC;
```

### MSG91 - Generate OTP (Local/Production)
```bash
curl -X POST "http://localhost:8080/api/mobile/otp/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "mobileNumber": "+919876543210",
    "purpose": "REGISTRATION",
    "deviceId": "test-device-001",
    "deviceType": "ANDROID"
  }'
```

### MSG91 - Verify OTP
```bash
curl -X POST "http://localhost:8080/api/mobile/otp/verify" \
  -H "Content-Type: application/json" \
  -d '{
    "mobileNumber": "+919876543210",
    "otpCode": "123456",
    "purpose": "REGISTRATION",
    "deviceId": "test-device-001"
  }'
```

### MSG91 - View OTP Requests (Last Hour)
```sql
SELECT
  mobile_number,
  purpose,
  otp_code,
  is_used,
  attempt_count,
  expires_at,
  created_at
FROM mobile_otps
WHERE created_at > NOW() - INTERVAL 1 HOUR
ORDER BY created_at DESC;
```

### MSG91 - Check OTP Success Rate (Last 24 Hours)
```sql
SELECT
  COUNT(*) as total_otps,
  SUM(CASE WHEN is_used = TRUE THEN 1 ELSE 0 END) as verified_otps,
  ROUND(SUM(CASE WHEN is_used = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as success_rate
FROM mobile_otps
WHERE created_at > NOW() - INTERVAL 24 HOUR;
```

---

**Last Updated**: November 8, 2025
**Maintained by**: NammaOoru Development Team
