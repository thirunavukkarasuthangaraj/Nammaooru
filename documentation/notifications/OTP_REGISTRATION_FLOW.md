# OTP Registration Flow Diagram

## Complete Registration Flow with MSG91 OTP

### Template ID: 1207176226012464195

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     CUSTOMER REGISTRATION FLOW                   │
│                    Using MSG91 OTP Verification                  │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐
│  Mobile App  │
│  User Opens  │
│Registration  │
│   Screen     │
└──────┬───────┘
       │
       │ Enter Mobile Number
       │ (+919876543210)
       ▼
┌──────────────────────────────────────────────┐
│  STEP 1: Request OTP                         │
│  POST /api/mobile/otp/generate               │
│  ┌────────────────────────────────────────┐  │
│  │ Request Body:                          │  │
│  │ {                                      │  │
│  │   "mobileNumber": "+919876543210",    │  │
│  │   "purpose": "REGISTRATION",          │  │
│  │   "deviceId": "device-uuid-001",      │  │
│  │   "deviceType": "ANDROID"             │  │
│  │ }                                      │  │
│  └────────────────────────────────────────┘  │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  Backend: MobileOtpService                              │
│  ┌───────────────────────────────────────────────────┐  │
│  │ 1. Validate Mobile Number                         │  │
│  │ 2. Check Rate Limiting (max 5/hour)              │  │
│  │ 3. Check Time Since Last Request (min 2 min)     │  │
│  │ 4. Generate 6-digit OTP (SecureRandom)           │  │
│  │ 5. Store in Database (mobile_otps table)         │  │
│  │ 6. Set Expiry (10 minutes from now)              │  │
│  └───────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────┐
        │  Rate Limit Check                  │
        │  ┌──────────────────────────────┐  │
        │  │ Requests in last hour < 5?   │  │
        │  │ Time since last > 2 min?     │  │
        │  └──────────┬────────────────────  │
        └─────────────┼────────────────────┘
                      │
           ┌──────────┴──────────┐
           │                     │
        YES│                     │NO
           ▼                     ▼
   ┌───────────────┐    ┌────────────────────┐
   │  Proceed      │    │  Return Error:     │
   │  with OTP     │    │  "Rate Limited"    │
   │  Generation   │    │  "Wait 2 minutes"  │
   └───────┬───────┘    └────────────────────┘
           │                     │
           │                     └──────────┐
           ▼                                │
┌──────────────────────────────────┐        │
│  WhatsAppNotificationService     │        │
│  ┌────────────────────────────┐  │        │
│  │ 1. Get OTP Code            │  │        │
│  │ 2. Get Template ID         │  │        │
│  │    (1207176226012464195)   │  │        │
│  │ 3. Build MSG91 Request     │  │        │
│  │ 4. Send to MSG91 API       │  │        │
│  └────────────────────────────┘  │        │
└───────────────┬──────────────────┘        │
                │                           │
                ▼                           │
┌───────────────────────────────────┐       │
│  MSG91 SMS Gateway                │       │
│  ┌─────────────────────────────┐  │       │
│  │ Template: 1207176226012464195│ │       │
│  │ Mobile: +919876543210       │  │       │
│  │ OTP: 123456                 │  │       │
│  │ Sender: NMROOU              │  │       │
│  └─────────────────────────────┘  │       │
└───────────────┬───────────────────┘       │
                │                           │
                ▼                           │
        ┌───────────────┐                   │
        │  DLT Check    │                   │
        │  (India)      │                   │
        └───────┬───────┘                   │
                │                           │
                ▼                           │
        ┌───────────────┐                   │
        │ SMS Delivered │                   │
        │ to Customer   │                   │
        └───────┬───────┘                   │
                │                           │
                │                           │
                ▼                           │
┌───────────────────────────────────┐       │
│  Response to Mobile App           │◄──────┘
│  ┌─────────────────────────────┐  │
│  │ Success Response:           │  │
│  │ {                           │  │
│  │   "success": true,          │  │
│  │   "message": "OTP sent",    │  │
│  │   "otpId": 12345,           │  │
│  │   "expiresIn": 600,         │  │
│  │   "attemptsRemaining": 3    │  │
│  │ }                           │  │
│  │                             │  │
│  │ OR Error Response:          │  │
│  │ {                           │  │
│  │   "success": false,         │  │
│  │   "errorCode": "RATE_LIMIT",│  │
│  │   "canRetryAfter": 120      │  │
│  │ }                           │  │
│  └─────────────────────────────┘  │
└───────────────┬───────────────────┘
                │
                ▼
┌───────────────────────────────────┐
│  Mobile App: OTP Input Screen     │
│  ┌─────────────────────────────┐  │
│  │ Enter 6-digit OTP:          │  │
│  │ [1] [2] [3] [4] [5] [6]     │  │
│  │                             │  │
│  │ Resend OTP (in 02:00)       │  │
│  │ Valid for: 09:45            │  │
│  └─────────────────────────────┘  │
└───────────────┬───────────────────┘
                │
                │ User enters OTP
                ▼
┌──────────────────────────────────────────────┐
│  STEP 2: Verify OTP                          │
│  POST /api/mobile/otp/verify                 │
│  ┌────────────────────────────────────────┐  │
│  │ Request Body:                          │  │
│  │ {                                      │  │
│  │   "mobileNumber": "+919876543210",    │  │
│  │   "otpCode": "123456",                │  │
│  │   "purpose": "REGISTRATION",          │  │
│  │   "deviceId": "device-uuid-001"       │  │
│  │ }                                      │  │
│  └────────────────────────────────────────┘  │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│  Backend: MobileOtpService.verifyOtp()          │
│  ┌───────────────────────────────────────────┐  │
│  │ 1. Find OTP by mobile + purpose           │  │
│  │ 2. Check OTP not expired (< 10 min)       │  │
│  │ 3. Check OTP not already used             │  │
│  │ 4. Check attempts < 3                     │  │
│  │ 5. Check device ID matches                │  │
│  │ 6. Compare OTP codes                      │  │
│  └───────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────┘
                     │
        ┌────────────┴───────────┐
        │                        │
     VALID                    INVALID
        │                        │
        ▼                        ▼
┌───────────────┐      ┌─────────────────────┐
│ Mark as Used  │      │ Increment Attempts  │
│ Set verified_ │      │ Return Error        │
│ at timestamp  │      │ "Invalid OTP"       │
└───────┬───────┘      │ "X attempts left"   │
        │              └─────────────────────┘
        │                        │
        ▼                        │
┌───────────────────────┐        │
│ Return Success:       │        │
│ {                     │        │
│   "success": true,    │        │
│   "verified": true    │        │
│ }                     │        │
└───────┬───────────────┘        │
        │                        │
        ▼                        │
┌───────────────────────────────┐│
│  Mobile App: Success          ││
│  ┌─────────────────────────┐  ││
│  │ OTP Verified! ✓         │  ││
│  │ Proceeding to register  │  ││
│  └─────────────────────────┘  ││
└───────────────┬───────────────┘│
                │                │
                ▼                │
┌──────────────────────────────────────────────┐
│  STEP 3: Complete Registration               │
│  POST /api/mobile/customer/register          │
│  ┌────────────────────────────────────────┐  │
│  │ Request Body:                          │  │
│  │ {                                      │  │
│  │   "name": "John Doe",                 │  │
│  │   "mobileNumber": "+919876543210",    │  │
│  │   "email": "john@example.com",        │  │
│  │   "password": "SecurePass123",        │  │
│  │   "deviceId": "device-uuid-001"       │  │
│  │ }                                      │  │
│  └────────────────────────────────────────┘  │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│  Backend: CustomerService               │
│  ┌───────────────────────────────────┐  │
│  │ 1. Verify OTP was verified        │  │
│  │ 2. Check mobile not already used  │  │
│  │ 3. Hash password                  │  │
│  │ 4. Create customer record         │  │
│  │ 5. Generate JWT token             │  │
│  │ 6. Send welcome SMS (optional)    │  │
│  └───────────────────────────────────┘  │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────┐
│  Database: customers table             │
│  ┌──────────────────────────────────┐  │
│  │ INSERT INTO customers            │  │
│  │ (name, mobile, email, password)  │  │
│  │ VALUES (...)                     │  │
│  └──────────────────────────────────┘  │
└────────────────┬───────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  Response: Registration Complete        │
│  ┌───────────────────────────────────┐  │
│  │ {                                 │  │
│  │   "customerId": 123,              │  │
│  │   "name": "John Doe",             │  │
│  │   "mobileNumber": "+919876543210",│  │
│  │   "token": "eyJhbG...",           │  │
│  │   "message": "Welcome!"           │  │
│  │ }                                 │  │
│  └───────────────────────────────────┘  │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│  Mobile App: Navigate to Dashboard      │
│  - Store JWT token                      │
│  - Show welcome screen                  │
│  - Load customer data                   │
└─────────────────────────────────────────┘
```

---

## Error Handling Flow

```
┌─────────────────────────────────────────────────┐
│           ERROR SCENARIOS & HANDLING             │
└─────────────────────────────────────────────────┘

1. RATE LIMITING
   ┌─────────────────────────────────────┐
   │ Request OTP                         │
   │  ↓                                  │
   │ Check: Requests in last hour        │
   │  ↓                                  │
   │ If > 5: Return Error                │
   │ {                                   │
   │   "errorCode": "RATE_LIMIT",        │
   │   "message": "Max 5 OTP per hour",  │
   │   "canRetryAfter": 3600             │
   │ }                                   │
   └─────────────────────────────────────┘

2. TOO FREQUENT REQUESTS
   ┌─────────────────────────────────────┐
   │ Request OTP                         │
   │  ↓                                  │
   │ Check: Last request time            │
   │  ↓                                  │
   │ If < 2 min: Return Error            │
   │ {                                   │
   │   "errorCode": "TOO_FREQUENT",      │
   │   "message": "Wait 2 minutes",      │
   │   "canRetryAfter": 120              │
   │ }                                   │
   └─────────────────────────────────────┘

3. INVALID OTP
   ┌─────────────────────────────────────┐
   │ Verify OTP                          │
   │  ↓                                  │
   │ Compare: Input vs Stored            │
   │  ↓                                  │
   │ If not match: Increment attempts    │
   │ {                                   │
   │   "verified": false,                │
   │   "message": "Invalid OTP",         │
   │   "attemptsRemaining": 2            │
   │ }                                   │
   └─────────────────────────────────────┘

4. EXPIRED OTP
   ┌─────────────────────────────────────┐
   │ Verify OTP                          │
   │  ↓                                  │
   │ Check: expires_at < now()           │
   │  ↓                                  │
   │ If expired: Return Error            │
   │ {                                   │
   │   "verified": false,                │
   │   "errorCode": "OTP_EXPIRED",       │
   │   "message": "OTP expired"          │
   │ }                                   │
   │ → User must request new OTP         │
   └─────────────────────────────────────┘

5. MAX ATTEMPTS EXCEEDED
   ┌─────────────────────────────────────┐
   │ Verify OTP (3rd wrong attempt)      │
   │  ↓                                  │
   │ Check: attempt_count >= 3           │
   │  ↓                                  │
   │ If yes: Mark OTP invalid            │
   │ {                                   │
   │   "verified": false,                │
   │   "errorCode": "MAX_ATTEMPTS",      │
   │   "message": "Too many attempts"    │
   │ }                                   │
   │ → User must request new OTP         │
   └─────────────────────────────────────┘

6. DEVICE MISMATCH
   ┌─────────────────────────────────────┐
   │ Verify OTP from different device    │
   │  ↓                                  │
   │ Check: deviceId matches             │
   │  ↓                                  │
   │ If not match: Return Error          │
   │ {                                   │
   │   "verified": false,                │
   │   "errorCode": "DEVICE_MISMATCH",   │
   │   "message": "Security violation"   │
   │ }                                   │
   └─────────────────────────────────────┘
```

---

## Database Tables Involved

```
┌────────────────────────────────────────────────────┐
│  mobile_otps                                       │
├────────────────────────────────────────────────────┤
│  id (PK)                  BIGINT AUTO_INCREMENT    │
│  mobile_number            VARCHAR(15)              │
│  otp_code                 VARCHAR(6)               │
│  purpose                  ENUM('REGISTRATION',..') │
│  expires_at               TIMESTAMP                │
│  is_used                  BOOLEAN                  │
│  is_active                BOOLEAN                  │
│  attempt_count            INT (0-3)                │
│  max_attempts             INT (default 3)          │
│  device_id                VARCHAR(255)             │
│  device_type              VARCHAR(50)              │
│  ip_address               VARCHAR(45)              │
│  verified_at              TIMESTAMP                │
│  created_at               TIMESTAMP                │
└────────────────────────────────────────────────────┘
           │
           │ After successful verification
           ▼
┌────────────────────────────────────────────────────┐
│  customers                                         │
├────────────────────────────────────────────────────┤
│  customer_id (PK)         BIGINT AUTO_INCREMENT    │
│  name                     VARCHAR(100)             │
│  mobile_number            VARCHAR(15) UNIQUE       │
│  email                    VARCHAR(100)             │
│  password                 VARCHAR(255) (hashed)    │
│  is_verified              BOOLEAN (true)           │
│  created_at               TIMESTAMP                │
└────────────────────────────────────────────────────┘
```

---

## Configuration Values

```yaml
┌─────────────────────────────────────────────────┐
│  application.yml                                │
├─────────────────────────────────────────────────┤
│                                                 │
│  msg91:                                         │
│    auth:                                        │
│      key: <YOUR_MSG91_AUTH_KEY>                │
│    template:                                    │
│      otp: 1207176226012464195                  │
│                                                 │
│  mobile:                                        │
│    otp:                                         │
│      expiry-minutes: 10                        │
│      length: 6                                  │
│      max-attempts: 3                            │
│      rate-limit-minutes: 2                      │
│      max-requests-per-hour: 5                   │
│                                                 │
│  sms:                                           │
│    enabled: true                                │
│    gateway:                                     │
│      provider: MSG91                            │
└─────────────────────────────────────────────────┘
```

---

## Security Features

```
┌──────────────────────────────────────────────────┐
│              SECURITY LAYERS                     │
└──────────────────────────────────────────────────┘

1. RATE LIMITING
   └─ Max 5 requests per hour per mobile
   └─ Min 2 minutes between requests
   └─ Prevents brute force

2. DEVICE TRACKING
   └─ Device ID must match for verification
   └─ Prevents OTP interception

3. ATTEMPT LIMITING
   └─ Max 3 wrong attempts per OTP
   └─ Forces new OTP request after 3 fails

4. TIME EXPIRY
   └─ OTP valid for 10 minutes only
   └─ Reduces attack window

5. ONE-TIME USE
   └─ OTP marked as used after verification
   └─ Cannot reuse same OTP

6. IP LOGGING
   └─ IP address stored for audit
   └─ Helps detect suspicious activity

7. SECURE GENERATION
   └─ Uses SecureRandom (crypto-grade)
   └─ 6-digit = 1,000,000 combinations
```

---

**Template ID:** 1207176226012464195
**Service:** MobileOtpService.java
**Endpoints:** /api/mobile/otp/*
**Last Updated:** November 8, 2025