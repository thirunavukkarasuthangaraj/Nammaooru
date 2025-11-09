# MSG91 SMS & OTP Implementation Guide

## Overview
This guide provides complete instructions for implementing MSG91 SMS and OTP functionality in the NammaOoru Shop Management System, including the registration OTP template ID **1207176226012464195**.

---

## Table of Contents
1. [MSG91 Account Setup](#msg91-account-setup)
2. [Template Configuration](#template-configuration)
3. [Backend Configuration](#backend-configuration)
4. [Implementation Items Checklist](#implementation-items-checklist)
5. [API Endpoints](#api-endpoints)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

---

## MSG91 Account Setup

### Step 1: Create MSG91 Account
1. Visit [https://msg91.com](https://msg91.com)
2. Sign up for an account
3. Complete email verification
4. Complete KYC (Know Your Customer) process
5. Add credits to your account

### Step 2: Get API Credentials
1. Login to MSG91 Dashboard
2. Navigate to **Settings** → **API Keys**
3. Copy your **Auth Key** (e.g., `463859A66N4Ih6468c48e0dP1`)
4. Note down your **Sender ID** (e.g., `NMROOU` or numeric ID)

### Step 3: WhatsApp Business Setup (Optional)
1. Navigate to **WhatsApp** section in MSG91 dashboard
2. Set up WhatsApp Business API
3. Get your **WhatsApp Namespace** (e.g., `020b365c_912b_4032_b27e_c343ddbc1e08`)
4. Enable WhatsApp templates

---

## Template Configuration

### Registration OTP Template

**Template ID:** `1207176226012464195`

#### Create Template in MSG91 Dashboard

1. Go to MSG91 Dashboard → **Templates** → **Create New Template**
2. Select template type: **OTP**
3. Fill in template details:

```
Template Name: NammaOoru Registration OTP
Template ID: 1207176226012464195
Category: Transactional
Language: English

Template Content:
Dear Customer, Your NammaOoru registration OTP is ##OTP##. Valid for ##VALIDITY## minutes. Please do not share this OTP with anyone. - NammaOoru Team

Variables:
- ##OTP## (6-digit code)
- ##VALIDITY## (validity in minutes, e.g., 10)

DLT Template ID: <Your DLT Template ID from TRAI>
```

4. Submit for approval
5. Wait for MSG91 and DLT (Distributed Ledger Technology) approval

#### DLT Registration (India - Mandatory)

For sending SMS in India, you MUST register with DLT:

1. Visit your telecom operator's DLT portal (e.g., Jio DLT, Airtel DLT, Vodafone DLT)
2. Register as a **Principal Entity**
3. Create **Header** (Sender ID): NMROOU
4. Create **Template** with the exact content mentioned above
5. Get **DLT Template ID** (e.g., `1101234567890123`)
6. Link this DLT Template ID in MSG91 dashboard

**Important:** Without DLT registration, SMS will not be delivered in India.

### Other Template Types Needed

#### 1. Order Confirmation Template
```
Template Name: NammaOoru Order Confirmation
Category: Transactional
Content: Dear ##NAME##, Your order ##ORDER_ID## for Rs.##AMOUNT## has been confirmed. Track your order in the app. - NammaOoru
```

#### 2. Order Status Update Template
```
Template Name: NammaOoru Order Status
Category: Transactional
Content: Order ##ORDER_ID## status: ##STATUS##. ##MESSAGE##. Track in app. - NammaOoru
```

#### 3. Order Delivered Template
```
Template Name: NammaOoru Order Delivered
Category: Transactional
Content: Your order ##ORDER_ID## has been delivered. Thank you for shopping with NammaOoru! Rate your experience in the app.
```

#### 4. Welcome Message Template
```
Template Name: NammaOoru Welcome
Category: Promotional
Content: Welcome to NammaOoru ##NAME##! Start ordering from local shops. Download app: ##APP_LINK##. - NammaOoru Team
```

---

## Backend Configuration

### Step 1: Update application.yml

Navigate to: `backend/src/main/resources/application.yml`

```yaml
# MSG91 Configuration
msg91:
  auth:
    key: ${MSG91_AUTH_KEY:YOUR_ACTUAL_AUTH_KEY}
  sender:
    id: ${MSG91_SENDER_ID:NMROOU}
  template:
    otp: ${MSG91_OTP_TEMPLATE_ID:1207176226012464195}
    order-confirmation: ${MSG91_ORDER_CONFIRMATION_TEMPLATE_ID:YOUR_TEMPLATE_ID}
    order-status: ${MSG91_ORDER_STATUS_TEMPLATE_ID:YOUR_TEMPLATE_ID}
    order-delivered: ${MSG91_ORDER_DELIVERED_TEMPLATE_ID:YOUR_TEMPLATE_ID}
    welcome: ${MSG91_WELCOME_TEMPLATE_ID:YOUR_TEMPLATE_ID}
  whatsapp:
    enabled: ${MSG91_WHATSAPP_ENABLED:false}
    namespace: ${MSG91_NAMESPACE:YOUR_NAMESPACE}
  api:
    base-url: ${MSG91_API_URL:https://control.msg91.com/api/v5}

# SMS Configuration
sms:
  enabled: ${SMS_ENABLED:true}
  gateway:
    url: https://control.msg91.com/api/v5/otp
    api-key: ${MSG91_AUTH_KEY:YOUR_ACTUAL_AUTH_KEY}
    sender-id: ${MSG91_SENDER_ID:NMROOU}
    provider: MSG91  # Options: MSG91, TEXTLOCAL, TWILIO, MOCK

# Mobile OTP Configuration
mobile:
  otp:
    expiry-minutes: 10
    length: 6
    max-attempts: 3
    rate-limit-minutes: 2
    max-requests-per-hour: 5
```

### Step 2: Set Environment Variables

For **Production** deployment, set these environment variables:

```bash
# On Linux/Mac
export MSG91_AUTH_KEY="YOUR_ACTUAL_MSG91_AUTH_KEY"
export MSG91_SENDER_ID="NMROOU"
export MSG91_OTP_TEMPLATE_ID="1207176226012464195"
export MSG91_ORDER_CONFIRMATION_TEMPLATE_ID="YOUR_ORDER_CONFIRMATION_TEMPLATE_ID"
export MSG91_ORDER_STATUS_TEMPLATE_ID="YOUR_ORDER_STATUS_TEMPLATE_ID"
export MSG91_ORDER_DELIVERED_TEMPLATE_ID="YOUR_ORDER_DELIVERED_TEMPLATE_ID"
export MSG91_WELCOME_TEMPLATE_ID="YOUR_WELCOME_TEMPLATE_ID"
export MSG91_WHATSAPP_ENABLED="true"  # if using WhatsApp
export MSG91_NAMESPACE="YOUR_WHATSAPP_NAMESPACE"
export SMS_ENABLED="true"

# On Windows
set MSG91_AUTH_KEY=YOUR_ACTUAL_MSG91_AUTH_KEY
set MSG91_SENDER_ID=NMROOU
set MSG91_OTP_TEMPLATE_ID=1207176226012464195
...
```

### Step 3: Update WhatsAppNotificationService.java

File: `backend/src/main/java/com/shopmanagement/service/WhatsAppNotificationService.java`

The service is already configured to use MSG91. Verify the following:

1. **Auth Key is injected:**
```java
@Value("${msg91.auth.key}")
private String msg91AuthKey;
```

2. **Template IDs are injected:**
```java
@Value("${msg91.template.otp}")
private String otpTemplateId; // Should be: 1207176226012464195
```

3. **API endpoint is correct:**
```java
private static final String MSG91_BASE_URL = "https://control.msg91.com/api/v5";
```

### Step 4: Verify SmsService.java Configuration

File: `backend/src/main/java/com/shopmanagement/service/SmsService.java`

Ensure MSG91 provider is properly configured:

```java
@Value("${sms.gateway.provider:MSG91}")
private String smsProvider;

@Value("${sms.gateway.api-key}")
private String apiKey;

@Value("${msg91.template.otp}")
private String msg91OtpTemplateId;
```

---

## Implementation Items Checklist

### ✅ Items Already Implemented in Codebase

- [x] **MobileOtpService** - OTP generation, verification, rate limiting
- [x] **WhatsAppNotificationService** - MSG91 integration for WhatsApp & SMS
- [x] **SmsService** - Multi-provider SMS service (MSG91, Twilio, TextLocal)
- [x] **Database Entities** - MobileOtp, EmailOtp, PasswordResetOtp
- [x] **REST APIs** - OTP request, verify, resend endpoints
- [x] **OTP Purposes** - REGISTRATION, LOGIN, FORGOT_PASSWORD, etc.
- [x] **Rate Limiting** - Per mobile, per device, per hour
- [x] **Security Features** - Device tracking, IP logging, attempt limits
- [x] **Scheduled Cleanup** - Auto-delete expired OTPs
- [x] **Configuration Support** - application.yml with environment variables

### 🔧 Items You Need to Configure

#### 1. MSG91 Account Setup
- [ ] Create MSG91 account
- [ ] Complete KYC verification
- [ ] Add credits (minimum ₹500 recommended)
- [ ] Get Auth Key from dashboard
- [ ] Note Sender ID

#### 2. DLT Registration (India Only)
- [ ] Register on telecom operator's DLT portal
- [ ] Create Principal Entity
- [ ] Register Header/Sender ID (NMROOU)
- [ ] Create and approve OTP template
- [ ] Get DLT Template ID
- [ ] Link DLT Template ID in MSG91

#### 3. Template Creation in MSG91
- [ ] Create Registration OTP Template (ID: 1207176226012464195)
- [ ] Create Order Confirmation Template
- [ ] Create Order Status Update Template
- [ ] Create Order Delivered Template
- [ ] Create Welcome Message Template
- [ ] Wait for MSG91 approval
- [ ] Test each template

#### 4. Backend Configuration
- [ ] Update `application.yml` with actual template IDs
- [ ] Set environment variables for production
- [ ] Update `MSG91_AUTH_KEY` with actual key
- [ ] Update `MSG91_SENDER_ID` with approved sender ID
- [ ] Set `SMS_ENABLED=true`
- [ ] Verify WhatsApp namespace if using WhatsApp

#### 5. Testing
- [ ] Test OTP generation API
- [ ] Test OTP verification API
- [ ] Test OTP resend API
- [ ] Verify SMS delivery
- [ ] Test rate limiting (max 5 per hour)
- [ ] Test OTP expiry (10 minutes)
- [ ] Test max attempts (3 attempts)
- [ ] Test device ID validation
- [ ] Test WhatsApp fallback (if enabled)

#### 6. Frontend Integration
- [ ] Verify mobile app calls `/api/mobile/otp/generate`
- [ ] Implement OTP input screen
- [ ] Call `/api/mobile/otp/verify` with user input
- [ ] Handle resend OTP with `/api/mobile/otp/resend`
- [ ] Display error messages (rate limit, invalid OTP, expired)
- [ ] Show countdown timer (10 minutes)
- [ ] Show attempts remaining

#### 7. Production Deployment
- [ ] Set all environment variables on server
- [ ] Verify MSG91 credits are sufficient
- [ ] Enable SMS (`SMS_ENABLED=true`)
- [ ] Monitor OTP delivery success rate
- [ ] Set up logging for failed SMS
- [ ] Configure alerts for low MSG91 credits

#### 8. Monitoring & Maintenance
- [ ] Set up dashboard for OTP statistics
- [ ] Monitor daily SMS usage
- [ ] Track OTP delivery failures
- [ ] Review rate limiting logs
- [ ] Schedule regular credit top-ups
- [ ] Review DLT compliance monthly

---

## API Endpoints

### 1. Generate OTP (Registration)

**Endpoint:** `POST /api/mobile/otp/generate`

**Request:**
```json
{
  "mobileNumber": "+919876543210",
  "purpose": "REGISTRATION",
  "deviceId": "device-uuid-12345",
  "deviceType": "ANDROID",
  "appVersion": "1.0.0"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "OTP sent successfully to +919876543210",
  "otpId": 12345,
  "expiresIn": 600,
  "canRetryAfter": 120,
  "attemptsRemaining": 3
}
```

**Response (Rate Limited):**
```json
{
  "success": false,
  "message": "Please wait 2 minutes before requesting another OTP",
  "errorCode": "RATE_LIMIT_EXCEEDED",
  "canRetryAfter": 120
}
```

### 2. Verify OTP

**Endpoint:** `POST /api/mobile/otp/verify`

**Request:**
```json
{
  "mobileNumber": "+919876543210",
  "otpCode": "123456",
  "purpose": "REGISTRATION",
  "deviceId": "device-uuid-12345"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "OTP verified successfully",
  "verified": true
}
```

**Response (Failed):**
```json
{
  "success": false,
  "message": "Invalid OTP. 2 attempts remaining.",
  "verified": false,
  "attemptsRemaining": 2,
  "errorCode": "INVALID_OTP"
}
```

### 3. Resend OTP

**Endpoint:** `POST /api/mobile/otp/resend`

**Request:**
```json
{
  "mobileNumber": "+919876543210",
  "purpose": "REGISTRATION",
  "deviceId": "device-uuid-12345"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP resent successfully",
  "expiresIn": 600
}
```

### 4. Complete Registration (After OTP Verification)

**Endpoint:** `POST /api/mobile/customer/register`

**Request:**
```json
{
  "name": "John Doe",
  "mobileNumber": "+919876543210",
  "email": "john@example.com",
  "password": "SecurePassword123",
  "deviceId": "device-uuid-12345"
}
```

**Response:**
```json
{
  "customerId": 123,
  "name": "John Doe",
  "mobileNumber": "+919876543210",
  "email": "john@example.com",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "message": "Registration successful"
}
```

---

## Testing

### Manual Testing Steps

#### Test 1: OTP Generation
```bash
curl -X POST http://localhost:8080/api/mobile/otp/generate \
  -H "Content-Type: application/json" \
  -d '{
    "mobileNumber": "+919876543210",
    "purpose": "REGISTRATION",
    "deviceId": "test-device-001",
    "deviceType": "ANDROID",
    "appVersion": "1.0.0"
  }'
```

**Expected:** SMS received with 6-digit OTP

#### Test 2: OTP Verification
```bash
curl -X POST http://localhost:8080/api/mobile/otp/verify \
  -H "Content-Type: application/json" \
  -d '{
    "mobileNumber": "+919876543210",
    "otpCode": "123456",
    "purpose": "REGISTRATION",
    "deviceId": "test-device-001"
  }'
```

**Expected:** `{"success": true, "verified": true}`

#### Test 3: Rate Limiting
Send OTP request 6 times within 1 hour to same mobile number.

**Expected:** 6th request should fail with rate limit error

#### Test 4: OTP Expiry
1. Generate OTP
2. Wait 11 minutes
3. Try to verify

**Expected:** Verification should fail with "OTP expired" error

#### Test 5: Max Attempts
1. Generate OTP
2. Try wrong OTP 3 times

**Expected:** 4th attempt should fail with "Max attempts exceeded"

### Automated Testing

Create JUnit tests:

```java
@Test
public void testOtpGeneration() {
    MobileOtpRequest request = new MobileOtpRequest();
    request.setMobileNumber("+919876543210");
    request.setPurpose("REGISTRATION");

    MobileOtpResponse response = mobileOtpService.generateOtp(request);

    assertTrue(response.isSuccess());
    assertNotNull(response.getOtpId());
}

@Test
public void testRateLimiting() {
    // Generate 5 OTPs in 1 hour
    for (int i = 0; i < 5; i++) {
        mobileOtpService.generateOtp(request);
    }

    // 6th should fail
    assertThrows(RateLimitException.class, () -> {
        mobileOtpService.generateOtp(request);
    });
}
```

---

## Troubleshooting

### Issue 1: SMS Not Received

**Possible Causes:**
1. **DLT not registered** - SMS to Indian numbers requires DLT registration
2. **Low credits** - Check MSG91 balance
3. **Template not approved** - Verify template status in MSG91 dashboard
4. **Wrong sender ID** - Ensure sender ID is DLT-approved
5. **SMS disabled** - Check `SMS_ENABLED=true` in config

**Solution:**
```bash
# Check logs
tail -f backend/logs/application.log | grep SMS

# Verify configuration
curl http://localhost:8080/actuator/configprops | grep msg91

# Test with mock provider first
sms.gateway.provider=MOCK
```

### Issue 2: OTP Expired Too Quickly

**Cause:** System time mismatch

**Solution:**
```bash
# Check server time
date

# Sync with NTP
sudo ntpdate -s time.nist.gov

# Verify OTP expiry setting
mobile.otp.expiry-minutes=10
```

### Issue 3: Rate Limiting Too Strict

**Cause:** Default limits too low for testing

**Solution:**
```yaml
mobile:
  otp:
    max-requests-per-hour: 10  # Increase for testing
    rate-limit-minutes: 1      # Reduce for testing
```

### Issue 4: WhatsApp Fallback Not Working

**Cause:** WhatsApp not enabled or namespace incorrect

**Solution:**
```yaml
msg91:
  whatsapp:
    enabled: true
    namespace: YOUR_CORRECT_NAMESPACE  # From MSG91 dashboard
```

### Issue 5: Invalid Template Error

**Cause:** Template ID mismatch

**Solution:**
1. Verify template ID in MSG91 dashboard
2. Update `application.yml`:
```yaml
msg91:
  template:
    otp: "1207176226012464195"  # Must match exactly
```
3. Restart application

---

## Production Checklist

Before going live:

- [ ] MSG91 account verified and funded (min ₹1000)
- [ ] DLT registration complete (India)
- [ ] All templates approved
- [ ] Environment variables set on production server
- [ ] SMS_ENABLED=true
- [ ] Test with real mobile numbers
- [ ] Monitor logs for errors
- [ ] Set up alerts for low credits
- [ ] Configure backup SMS provider (optional)
- [ ] Test rate limiting in production
- [ ] Verify OTP delivery time (should be < 30 seconds)
- [ ] Set up analytics dashboard

---

## Support & Resources

### MSG91 Resources
- Dashboard: https://msg91.com/login
- Documentation: https://docs.msg91.com/
- API Reference: https://docs.msg91.com/p/tf9GTextN/e/Oui1dvLYW/MSG91
- Support: support@msg91.com

### DLT Resources
- Jio DLT: https://trueconnect.jio.com/
- Airtel DLT: https://www.airtel.in/business/commercial-communication/
- Vodafone DLT: https://www.myvi.in/dlt

### Internal Resources
- Backend Code: `backend/src/main/java/com/shopmanagement/service/`
- Configuration: `backend/src/main/resources/application.yml`
- API Docs: `documentation/api/COMPLETE_FEATURES_AND_API_LIST.md`

---

## Appendix: Sample MSG91 API Requests

### Send OTP via MSG91 API (Direct)

```bash
curl -X POST "https://control.msg91.com/api/v5/otp?template_id=1207176226012464195&mobile=919876543210&authkey=YOUR_AUTH_KEY&otp=123456"
```

### Verify OTP via MSG91 API (Direct)

```bash
curl -X GET "https://control.msg91.com/api/v5/otp/verify?mobile=919876543210&otp=123456&authkey=YOUR_AUTH_KEY"
```

### Check MSG91 Balance

```bash
curl -X GET "https://control.msg91.com/api/balance.php?authkey=YOUR_AUTH_KEY"
```

---

**Last Updated:** November 8, 2025
**Version:** 1.0
**Maintained By:** NammaOoru Development Team