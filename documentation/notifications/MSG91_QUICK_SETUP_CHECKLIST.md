# MSG91 Quick Setup Checklist

## Registration OTP Template ID: 1207176226012464195

---

## ⚡ Quick Setup Steps (30 Minutes)

### 1. MSG91 Account (10 min)
```
[ ] Sign up at https://msg91.com
[ ] Verify email
[ ] Complete KYC
[ ] Add ₹500 credits minimum
[ ] Copy Auth Key: ____________________
[ ] Note Sender ID: ___________________
```

### 2. DLT Registration - India Only (Varies)
```
[ ] Visit telecom DLT portal (Jio/Airtel/Vodafone)
[ ] Register as Principal Entity
[ ] Create Header: NMROOU
[ ] Create Template with content below
[ ] Get DLT Template ID: ____________________
```

**OTP Template Content:**
```
Dear Customer, Your NammaOoru registration OTP is ##OTP##. Valid for ##VALIDITY## minutes. Please do not share this OTP with anyone. - NammaOoru Team
```

### 3. MSG91 Template Setup (5 min)
```
[ ] Login to MSG91 Dashboard
[ ] Go to Templates → Create New
[ ] Template Name: NammaOoru Registration OTP
[ ] Template ID: 1207176226012464195
[ ] Add DLT Template ID from step 2
[ ] Submit for approval
[ ] Wait for approval (usually 2-4 hours)
```

### 4. Backend Configuration (5 min)

**File:** `backend/src/main/resources/application.yml`

```yaml
msg91:
  auth:
    key: ${MSG91_AUTH_KEY:YOUR_KEY_HERE}
  sender:
    id: ${MSG91_SENDER_ID:NMROOU}
  template:
    otp: ${MSG91_OTP_TEMPLATE_ID:1207176226012464195}

sms:
  enabled: ${SMS_ENABLED:true}
  gateway:
    provider: MSG91
```

### 5. Environment Variables (2 min)

**Production Server:**
```bash
export MSG91_AUTH_KEY="your-actual-auth-key"
export MSG91_SENDER_ID="NMROOU"
export MSG91_OTP_TEMPLATE_ID="1207176226012464195"
export SMS_ENABLED="true"
```

### 6. Test (5 min)
```bash
# Generate OTP
curl -X POST http://localhost:8080/api/mobile/otp/generate \
  -H "Content-Type: application/json" \
  -d '{
    "mobileNumber": "+919876543210",
    "purpose": "REGISTRATION",
    "deviceId": "test-001"
  }'

# Check your mobile for OTP SMS
# Verify OTP
curl -X POST http://localhost:8080/api/mobile/otp/verify \
  -H "Content-Type: application/json" \
  -d '{
    "mobileNumber": "+919876543210",
    "otpCode": "YOUR_OTP_HERE",
    "purpose": "REGISTRATION",
    "deviceId": "test-001"
  }'
```

---

## 🎯 Items Needed

### From MSG91 Dashboard
1. **Auth Key** - API authentication key
2. **Sender ID** - NMROOU (or your approved sender)
3. **Template ID** - 1207176226012464195 (must be approved)
4. **DLT Template ID** - From your telecom DLT portal
5. **WhatsApp Namespace** (optional) - If using WhatsApp

### Configuration Changes
1. Update `application.yml` with Auth Key
2. Set environment variables on production
3. Enable SMS: `SMS_ENABLED=true`
4. Set provider: `sms.gateway.provider=MSG91`

### Testing Requirements
1. Valid Indian mobile number for testing
2. MSG91 credits (minimum ₹100)
3. Template approval from MSG91
4. DLT registration complete

---

## ✅ Pre-Go-Live Checklist

```
[ ] MSG91 account funded (₹1000+)
[ ] DLT registration approved
[ ] Template 1207176226012464195 approved
[ ] Auth key configured in production
[ ] SMS_ENABLED=true in production
[ ] Tested OTP generation
[ ] Tested OTP verification
[ ] Tested rate limiting
[ ] Tested OTP expiry
[ ] Verified SMS delivery < 30 seconds
[ ] Set up credit alerts in MSG91
[ ] Monitored logs for errors
```

---

## 🚨 Common Issues & Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| SMS not received | Check DLT registration, verify template approval |
| "Template not found" | Update template ID in application.yml |
| "Invalid auth key" | Verify MSG91_AUTH_KEY environment variable |
| "Insufficient credits" | Add credits in MSG91 dashboard |
| Rate limit error | Wait 2 minutes between requests |
| OTP expired | OTPs valid for 10 minutes only |

---

## 📞 Support Contacts

- **MSG91 Support:** support@msg91.com
- **MSG91 Dashboard:** https://msg91.com/login
- **DLT Support:** Contact your telecom operator
- **Internal Doc:** `/documentation/notifications/MSG91_SMS_OTP_IMPLEMENTATION_GUIDE.md`

---

## 🔗 Quick Links

- MSG91 Dashboard: https://msg91.com/login
- MSG91 Docs: https://docs.msg91.com/
- DLT Portal (Jio): https://trueconnect.jio.com/
- Backend Config: `backend/src/main/resources/application.yml`
- OTP Service: `backend/src/main/java/com/shopmanagement/service/MobileOtpService.java`

---

**Registration OTP Template ID:** `1207176226012464195`

**Last Updated:** November 8, 2025