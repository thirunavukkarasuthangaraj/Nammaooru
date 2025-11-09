# MSG91 OTP API Testing Guide

## Template ID: 1207176226012464195

Complete testing guide with cURL, Postman, and automated test examples.

---

## Table of Contents
1. [API Endpoints Overview](#api-endpoints-overview)
2. [cURL Testing Examples](#curl-testing-examples)
3. [Postman Collection](#postman-collection)
4. [Automated Testing](#automated-testing)
5. [Test Scenarios](#test-scenarios)

---

## API Endpoints Overview

| Endpoint | Method | Purpose | Auth Required |
|----------|--------|---------|---------------|
| `/api/mobile/otp/generate` | POST | Generate OTP | No |
| `/api/mobile/otp/verify` | POST | Verify OTP | No |
| `/api/mobile/otp/resend` | POST | Resend OTP | No |
| `/api/mobile/customer/register` | POST | Complete registration | No |
| `/api/mobile/auth/login` | POST | Login with OTP | No |

**Base URL:**
- Local: `http://localhost:8080`
- Production: `https://api.nammaooru.com`

---

## cURL Testing Examples

### 1. Generate OTP for Registration

```bash
curl -X POST "http://localhost:8080/api/mobile/otp/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "mobileNumber": "+919876543210",
    "purpose": "REGISTRATION",
    "deviceId": "test-device-001",
    "deviceType": "ANDROID",
    "appVersion": "1.0.0",
    "ipAddress": "192.168.1.1"
  }' | jq
```

**Expected Response:**
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

### 2. Verify OTP

```bash
curl -X POST "http://localhost:8080/api/mobile/otp/verify" \
  -H "Content-Type: application/json" \
  -d '{
    "mobileNumber": "+919876543210",
    "otpCode": "123456",
    "purpose": "REGISTRATION",
    "deviceId": "test-device-001"
  }' | jq
```

**Expected Response (Success):**
```json
{
  "success": true,
  "message": "OTP verified successfully",
  "verified": true
}
```

**Expected Response (Failure):**
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

```bash
curl -X POST "http://localhost:8080/api/mobile/otp/resend" \
  -H "Content-Type: application/json" \
  -d '{
    "mobileNumber": "+919876543210",
    "purpose": "REGISTRATION",
    "deviceId": "test-device-001"
  }' | jq
```

**Expected Response:**
```json
{
  "success": true,
  "message": "OTP resent successfully to +919876543210",
  "expiresIn": 600,
  "canRetryAfter": 120
}
```

### 4. Complete Registration

```bash
curl -X POST "http://localhost:8080/api/mobile/customer/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "mobileNumber": "+919876543210",
    "email": "john.doe@example.com",
    "password": "SecurePassword123!",
    "deviceId": "test-device-001",
    "deviceType": "ANDROID"
  }' | jq
```

**Expected Response:**
```json
{
  "customerId": 123,
  "name": "John Doe",
  "mobileNumber": "+919876543210",
  "email": "john.doe@example.com",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM...",
  "message": "Registration successful"
}
```

### 5. Login with OTP

**Step 1: Request Login OTP**
```bash
curl -X POST "http://localhost:8080/api/mobile/otp/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "mobileNumber": "+919876543210",
    "purpose": "LOGIN",
    "deviceId": "test-device-001",
    "deviceType": "ANDROID"
  }' | jq
```

**Step 2: Verify and Login**
```bash
curl -X POST "http://localhost:8080/api/mobile/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "mobileNumber": "+919876543210",
    "otpCode": "123456",
    "deviceId": "test-device-001"
  }' | jq
```

---

## Postman Collection

### Collection Setup

**Collection Name:** NammaOoru OTP Testing

**Variables:**
```json
{
  "base_url": "http://localhost:8080",
  "mobile_number": "+919876543210",
  "device_id": "postman-test-device",
  "otp_code": "",
  "auth_token": ""
}
```

### Request 1: Generate OTP

```
POST {{base_url}}/api/mobile/otp/generate

Headers:
  Content-Type: application/json

Body (raw JSON):
{
  "mobileNumber": "{{mobile_number}}",
  "purpose": "REGISTRATION",
  "deviceId": "{{device_id}}",
  "deviceType": "ANDROID",
  "appVersion": "1.0.0"
}

Tests (JavaScript):
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has success field", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.success).to.eql(true);
});

pm.test("Response has otpId", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.otpId).to.be.a('number');
});

pm.test("Expires in 10 minutes (600 seconds)", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.expiresIn).to.eql(600);
});
```

### Request 2: Verify OTP

```
POST {{base_url}}/api/mobile/otp/verify

Headers:
  Content-Type: application/json

Body (raw JSON):
{
  "mobileNumber": "{{mobile_number}}",
  "otpCode": "{{otp_code}}",
  "purpose": "REGISTRATION",
  "deviceId": "{{device_id}}"
}

Tests (JavaScript):
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("OTP verified successfully", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.verified).to.eql(true);
});
```

### Request 3: Complete Registration

```
POST {{base_url}}/api/mobile/customer/register

Headers:
  Content-Type: application/json

Body (raw JSON):
{
  "name": "Test User",
  "mobileNumber": "{{mobile_number}}",
  "email": "test@example.com",
  "password": "Test@123456",
  "deviceId": "{{device_id}}"
}

Tests (JavaScript):
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Registration successful", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.customerId).to.be.a('number');
    pm.expect(jsonData.token).to.be.a('string');

    // Save token for future requests
    pm.collectionVariables.set("auth_token", jsonData.token);
});
```

---

## Automated Testing

### JUnit Test Cases

#### Test 1: OTP Generation

```java
@SpringBootTest
@AutoConfigureMockMvc
public class OtpApiTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void testGenerateOtp_Success() throws Exception {
        MobileOtpRequest request = new MobileOtpRequest();
        request.setMobileNumber("+919876543210");
        request.setPurpose("REGISTRATION");
        request.setDeviceId("test-device-001");
        request.setDeviceType("ANDROID");

        mockMvc.perform(post("/api/mobile/otp/generate")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.otpId").exists())
                .andExpect(jsonPath("$.expiresIn").value(600));
    }

    @Test
    public void testGenerateOtp_RateLimitExceeded() throws Exception {
        MobileOtpRequest request = new MobileOtpRequest();
        request.setMobileNumber("+919876543210");
        request.setPurpose("REGISTRATION");
        request.setDeviceId("test-device-001");

        // Generate 5 OTPs (max allowed per hour)
        for (int i = 0; i < 5; i++) {
            mockMvc.perform(post("/api/mobile/otp/generate")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk());
        }

        // 6th request should fail
        mockMvc.perform(post("/api/mobile/otp/generate")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("RATE_LIMIT"));
    }
}
```

#### Test 2: OTP Verification

```java
@Test
public void testVerifyOtp_Success() throws Exception {
    // First generate OTP
    MobileOtpRequest generateRequest = new MobileOtpRequest();
    generateRequest.setMobileNumber("+919876543210");
    generateRequest.setPurpose("REGISTRATION");
    generateRequest.setDeviceId("test-device-001");

    MvcResult generateResult = mockMvc.perform(post("/api/mobile/otp/generate")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(generateRequest)))
            .andExpect(status().isOk())
            .andReturn();

    // Extract OTP from database (for testing only)
    String otp = getOtpFromDatabase("+919876543210");

    // Verify OTP
    MobileOtpVerificationRequest verifyRequest = new MobileOtpVerificationRequest();
    verifyRequest.setMobileNumber("+919876543210");
    verifyRequest.setOtpCode(otp);
    verifyRequest.setPurpose("REGISTRATION");
    verifyRequest.setDeviceId("test-device-001");

    mockMvc.perform(post("/api/mobile/otp/verify")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(verifyRequest)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.verified").value(true));
}

@Test
public void testVerifyOtp_InvalidOtp() throws Exception {
    // Generate OTP first
    generateOtp("+919876543210");

    // Try with wrong OTP
    MobileOtpVerificationRequest verifyRequest = new MobileOtpVerificationRequest();
    verifyRequest.setMobileNumber("+919876543210");
    verifyRequest.setOtpCode("999999"); // Wrong OTP
    verifyRequest.setPurpose("REGISTRATION");
    verifyRequest.setDeviceId("test-device-001");

    mockMvc.perform(post("/api/mobile/otp/verify")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(verifyRequest)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.verified").value(false))
            .andExpect(jsonPath("$.attemptsRemaining").value(2));
}

@Test
public void testVerifyOtp_Expired() throws Exception {
    // Generate OTP
    generateOtp("+919876543210");

    // Manually expire OTP in database (for testing)
    expireOtpInDatabase("+919876543210");

    // Try to verify
    MobileOtpVerificationRequest verifyRequest = new MobileOtpVerificationRequest();
    verifyRequest.setMobileNumber("+919876543210");
    verifyRequest.setOtpCode(getOtpFromDatabase("+919876543210"));
    verifyRequest.setPurpose("REGISTRATION");
    verifyRequest.setDeviceId("test-device-001");

    mockMvc.perform(post("/api/mobile/otp/verify")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(verifyRequest)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("OTP_EXPIRED"));
}
```

#### Test 3: Complete Flow

```java
@Test
public void testCompleteRegistrationFlow() throws Exception {
    String mobileNumber = "+919876543210";
    String deviceId = "test-device-001";

    // Step 1: Generate OTP
    MobileOtpRequest otpRequest = new MobileOtpRequest();
    otpRequest.setMobileNumber(mobileNumber);
    otpRequest.setPurpose("REGISTRATION");
    otpRequest.setDeviceId(deviceId);

    mockMvc.perform(post("/api/mobile/otp/generate")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(otpRequest)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true));

    // Step 2: Verify OTP
    String otp = getOtpFromDatabase(mobileNumber);
    MobileOtpVerificationRequest verifyRequest = new MobileOtpVerificationRequest();
    verifyRequest.setMobileNumber(mobileNumber);
    verifyRequest.setOtpCode(otp);
    verifyRequest.setPurpose("REGISTRATION");
    verifyRequest.setDeviceId(deviceId);

    mockMvc.perform(post("/api/mobile/otp/verify")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(verifyRequest)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.verified").value(true));

    // Step 3: Complete Registration
    SimpleMobileRegistrationRequest registerRequest = new SimpleMobileRegistrationRequest();
    registerRequest.setName("Test User");
    registerRequest.setMobileNumber(mobileNumber);
    registerRequest.setEmail("test@example.com");
    registerRequest.setPassword("Test@123456");
    registerRequest.setDeviceId(deviceId);

    mockMvc.perform(post("/api/mobile/customer/register")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(registerRequest)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.customerId").exists())
            .andExpect(jsonPath("$.token").exists())
            .andExpect(jsonPath("$.mobileNumber").value(mobileNumber));
}
```

---

## Test Scenarios

### Scenario 1: Happy Path - Successful Registration

```bash
#!/bin/bash

BASE_URL="http://localhost:8080"
MOBILE="+919876543210"
DEVICE_ID="test-001"

echo "=== Test Scenario 1: Happy Path ==="

# Step 1: Generate OTP
echo "Step 1: Generating OTP..."
RESPONSE=$(curl -s -X POST "$BASE_URL/api/mobile/otp/generate" \
  -H "Content-Type: application/json" \
  -d "{
    \"mobileNumber\": \"$MOBILE\",
    \"purpose\": \"REGISTRATION\",
    \"deviceId\": \"$DEVICE_ID\",
    \"deviceType\": \"ANDROID\"
  }")

echo "$RESPONSE" | jq

# Extract OTP from SMS or database
read -p "Enter OTP received on mobile: " OTP

# Step 2: Verify OTP
echo "Step 2: Verifying OTP..."
curl -s -X POST "$BASE_URL/api/mobile/otp/verify" \
  -H "Content-Type: application/json" \
  -d "{
    \"mobileNumber\": \"$MOBILE\",
    \"otpCode\": \"$OTP\",
    \"purpose\": \"REGISTRATION\",
    \"deviceId\": \"$DEVICE_ID\"
  }" | jq

# Step 3: Complete Registration
echo "Step 3: Completing Registration..."
curl -s -X POST "$BASE_URL/api/mobile/customer/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Test User\",
    \"mobileNumber\": \"$MOBILE\",
    \"email\": \"test@example.com\",
    \"password\": \"Test@123456\",
    \"deviceId\": \"$DEVICE_ID\"
  }" | jq

echo "=== Test Complete ==="
```

### Scenario 2: Rate Limiting Test

```bash
#!/bin/bash

BASE_URL="http://localhost:8080"
MOBILE="+919876543210"

echo "=== Test Scenario 2: Rate Limiting ==="

for i in {1..6}; do
  echo "Request $i of 6..."
  curl -s -X POST "$BASE_URL/api/mobile/otp/generate" \
    -H "Content-Type: application/json" \
    -d "{
      \"mobileNumber\": \"$MOBILE\",
      \"purpose\": \"REGISTRATION\",
      \"deviceId\": \"test-$i\"
    }" | jq '.success, .message'

  if [ $i -lt 6 ]; then
    echo "Waiting 5 seconds..."
    sleep 5
  fi
done

echo "=== Expected: 6th request should fail with rate limit error ==="
```

### Scenario 3: Invalid OTP Test

```bash
#!/bin/bash

BASE_URL="http://localhost:8080"
MOBILE="+919876543210"
DEVICE_ID="test-001"

echo "=== Test Scenario 3: Invalid OTP Attempts ==="

# Generate OTP
curl -s -X POST "$BASE_URL/api/mobile/otp/generate" \
  -H "Content-Type: application/json" \
  -d "{
    \"mobileNumber\": \"$MOBILE\",
    \"purpose\": \"REGISTRATION\",
    \"deviceId\": \"$DEVICE_ID\"
  }" | jq

# Try wrong OTP 3 times
for i in {1..4}; do
  echo "Attempt $i with wrong OTP..."
  curl -s -X POST "$BASE_URL/api/mobile/otp/verify" \
    -H "Content-Type: application/json" \
    -d "{
      \"mobileNumber\": \"$MOBILE\",
      \"otpCode\": \"999999\",
      \"purpose\": \"REGISTRATION\",
      \"deviceId\": \"$DEVICE_ID\"
    }" | jq '.verified, .attemptsRemaining, .errorCode'

  sleep 2
done

echo "=== Expected: 4th attempt should fail with MAX_ATTEMPTS error ==="
```

### Scenario 4: OTP Expiry Test

```bash
#!/bin/bash

BASE_URL="http://localhost:8080"
MOBILE="+919876543210"
DEVICE_ID="test-001"

echo "=== Test Scenario 4: OTP Expiry (10 minutes) ==="

# Generate OTP
RESPONSE=$(curl -s -X POST "$BASE_URL/api/mobile/otp/generate" \
  -H "Content-Type: application/json" \
  -d "{
    \"mobileNumber\": \"$MOBILE\",
    \"purpose\": \"REGISTRATION\",
    \"deviceId\": \"$DEVICE_ID\"
  }")

echo "$RESPONSE" | jq

read -p "Enter OTP: " OTP

echo "Waiting 10 minutes for OTP to expire..."
echo "You can manually update database to set expires_at to past time"
read -p "Press Enter after OTP is expired..."

# Try to verify expired OTP
curl -s -X POST "$BASE_URL/api/mobile/otp/verify" \
  -H "Content-Type: application/json" \
  -d "{
    \"mobileNumber\": \"$MOBILE\",
    \"otpCode\": \"$OTP\",
    \"purpose\": \"REGISTRATION\",
    \"deviceId\": \"$DEVICE_ID\"
  }" | jq

echo "=== Expected: OTP_EXPIRED error ==="
```

### Scenario 5: Device Mismatch Test

```bash
#!/bin/bash

BASE_URL="http://localhost:8080"
MOBILE="+919876543210"

echo "=== Test Scenario 5: Device Mismatch ==="

# Generate OTP with device-1
curl -s -X POST "$BASE_URL/api/mobile/otp/generate" \
  -H "Content-Type: application/json" \
  -d "{
    \"mobileNumber\": \"$MOBILE\",
    \"purpose\": \"REGISTRATION\",
    \"deviceId\": \"device-1\"
  }" | jq

read -p "Enter OTP: " OTP

# Try to verify with device-2
curl -s -X POST "$BASE_URL/api/mobile/otp/verify" \
  -H "Content-Type: application/json" \
  -d "{
    \"mobileNumber\": \"$MOBILE\",
    \"otpCode\": \"$OTP\",
    \"purpose\": \"REGISTRATION\",
    \"deviceId\": \"device-2\"
  }" | jq

echo "=== Expected: DEVICE_MISMATCH error ==="
```

---

## Performance Testing

### Load Test with Apache Bench

```bash
# Test OTP generation endpoint
ab -n 1000 -c 10 -p otp_request.json -T application/json \
  http://localhost:8080/api/mobile/otp/generate

# otp_request.json content:
{
  "mobileNumber": "+919876543210",
  "purpose": "REGISTRATION",
  "deviceId": "load-test-device"
}
```

### JMeter Test Plan

```xml
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2">
  <hashTree>
    <TestPlan testname="OTP API Load Test">
      <ThreadGroup testname="OTP Users">
        <numThreads>100</numThreads>
        <rampTime>60</rampTime>
        <loops>10</loops>

        <HTTPSampler testname="Generate OTP">
          <domain>localhost</domain>
          <port>8080</port>
          <path>/api/mobile/otp/generate</path>
          <method>POST</method>
          <contentType>application/json</contentType>
          <body>{
            "mobileNumber": "+91${__Random(9000000000,9999999999)}",
            "purpose": "REGISTRATION",
            "deviceId": "jmeter-${__threadNum}"
          }</body>
        </HTTPSampler>
      </ThreadGroup>
    </TestPlan>
  </hashTree>
</jmeterTestPlan>
```

---

## Monitoring & Logging

### Check Application Logs

```bash
# Tail logs for OTP-related events
tail -f backend/logs/application.log | grep -E "OTP|SMS|MSG91"

# Check for errors
tail -f backend/logs/application.log | grep ERROR | grep -E "OTP|SMS"

# Monitor rate limiting
tail -f backend/logs/application.log | grep "RATE_LIMIT"
```

### Database Queries for Monitoring

```sql
-- Check recent OTP requests
SELECT
  mobile_number,
  purpose,
  is_used,
  attempt_count,
  expires_at,
  created_at
FROM mobile_otps
WHERE created_at > NOW() - INTERVAL 1 HOUR
ORDER BY created_at DESC;

-- Count OTP requests by mobile number (last hour)
SELECT
  mobile_number,
  COUNT(*) as request_count,
  MAX(created_at) as last_request
FROM mobile_otps
WHERE created_at > NOW() - INTERVAL 1 HOUR
GROUP BY mobile_number
HAVING COUNT(*) >= 3
ORDER BY request_count DESC;

-- Check verification success rate
SELECT
  COUNT(*) as total,
  SUM(CASE WHEN is_used = TRUE THEN 1 ELSE 0 END) as verified,
  ROUND(SUM(CASE WHEN is_used = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as success_rate
FROM mobile_otps
WHERE created_at > NOW() - INTERVAL 24 HOUR;

-- Find expired unverified OTPs
SELECT COUNT(*) as expired_count
FROM mobile_otps
WHERE expires_at < NOW()
  AND is_used = FALSE
  AND created_at > NOW() - INTERVAL 24 HOUR;
```

---

**Template ID:** 1207176226012464195
**Last Updated:** November 8, 2025
**Version:** 1.0
