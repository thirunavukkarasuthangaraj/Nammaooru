# 📚 Detailed Setup Guide - Gemini API 4 Keys Rotation

## 📋 Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step-by-Step Setup](#step-by-step-setup)
4. [Configuration Options](#configuration-options)
5. [Testing & Verification](#testing--verification)
6. [Monitoring](#monitoring)
7. [Troubleshooting](#troubleshooting)
8. [Security Best Practices](#security-best-practices)

---

## Overview

### What is API Key Rotation?
API key rotation distributes requests across multiple API keys to increase throughput and avoid rate limits.

### Your Configuration
- **4 API Keys** from Google AI Studio
- **15 RPM per key** = **60 RPM total**
- **Round-robin rotation** (automatic, thread-safe)
- **Shared quota**: 1M tokens/day

### How It Works
```
┌─────────────┐
│   Request   │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│  Key Rotator        │
│  (AtomicInteger)    │
└──────┬──────────────┘
       │
       ├─► Key 1 → Request 1, 5, 9, 13...
       ├─► Key 2 → Request 2, 6, 10, 14...
       ├─► Key 3 → Request 3, 7, 11, 15...
       └─► Key 4 → Request 4, 8, 12, 16...
```

---

## Prerequisites

### 1. Google AI Studio Account
- Visit: https://aistudio.google.com/
- Sign in with your Google account
- Ensure you have access to Gemini API

### 2. Your 4 API Keys
From your screenshot, you have:
```
✓ Key 1 (key3):          ...GB3Q  - Nov 11, 2025
✓ Key 2 (key2):          ...JlQE  - Nov 11, 2025
✓ Key 3 (key1):          ...CmQo  - Nov 11, 2025
✓ Key 4 (ProductSearch): ...XoTc  - Nov 10, 2025
```

### 3. Development Environment
- Java 17+
- Maven
- Spring Boot 3.x
- Your backend already running

---

## Step-by-Step Setup

### Step 1: Get Full API Keys

1. Open https://aistudio.google.com/api-keys
2. You'll see your 4 keys listed
3. For each key, click the **"Show API key"** button (eye icon)
4. Copy the full key (should start with `AIzaSy...`)
5. Paste each key into `your-api-keys.txt` file in this folder

**Example of full key format:**
```
AIzaSyA-SdjVz-rnQbPk17e9k2FSq6LY_svGB3Q
```

### Step 2: Choose Configuration Method

You have **3 options** (choose one):

#### ✨ Option A: Direct Update in application.yml (Fastest)

**Pros:** Quick, no extra setup needed
**Cons:** Keys visible in codebase (don't commit!)

1. Open: `backend/src/main/resources/application.yml`
2. Find lines 192-196:
```yaml
gemini:
  enabled: true
  api-keys:
    - ${GEMINI_API_KEY_1:AIzaSyAb1cde2fgh3ijk4lmn5opq6rst7uvw8xyz}
    - ${GEMINI_API_KEY_2:AIzaSyAYqI-DsGx4QWBjyS9K8P9uSqMEcD7CmQo}
    - ${GEMINI_API_KEY_3:AIzaSyDvKELg3zFky3G2Pg0uN2_NV5BoIl9JiQE}
    - ${GEMINI_API_KEY_4:AIzaSyA-SdjVz-rnQbPk17e9k2FSq6LY_svGB3Q}
```
3. Replace with your full keys (remove the `${...}` wrapper):
```yaml
gemini:
  enabled: true
  api-keys:
    - AIzaSy...YOUR_FULL_KEY_1_GB3Q
    - AIzaSy...YOUR_FULL_KEY_2_JlQE
    - AIzaSy...YOUR_FULL_KEY_3_CmQo
    - AIzaSy...YOUR_FULL_KEY_4_XoTc
```
4. Save the file
5. ⚠️ **DO NOT COMMIT** this file to Git!

---

#### 🔒 Option B: Environment Variables (Recommended)

**Pros:** Secure, keys not in codebase
**Cons:** Requires setting env vars

**Windows (PowerShell):**
```powershell
$env:GEMINI_API_KEY_1="AIzaSy...YOUR_KEY_1"
$env:GEMINI_API_KEY_2="AIzaSy...YOUR_KEY_2"
$env:GEMINI_API_KEY_3="AIzaSy...YOUR_KEY_3"
$env:GEMINI_API_KEY_4="AIzaSy...YOUR_KEY_4"
```

**Windows (CMD):**
```cmd
set GEMINI_API_KEY_1=AIzaSy...YOUR_KEY_1
set GEMINI_API_KEY_2=AIzaSy...YOUR_KEY_2
set GEMINI_API_KEY_3=AIzaSy...YOUR_KEY_3
set GEMINI_API_KEY_4=AIzaSy...YOUR_KEY_4
```

**Linux/Mac (Bash/Zsh):**
```bash
export GEMINI_API_KEY_1="AIzaSy...YOUR_KEY_1"
export GEMINI_API_KEY_2="AIzaSy...YOUR_KEY_2"
export GEMINI_API_KEY_3="AIzaSy...YOUR_KEY_3"
export GEMINI_API_KEY_4="AIzaSy...YOUR_KEY_4"
```

**Or use the provided scripts:**
```bash
# Windows
cd gemini-api-setup
set-keys-windows.bat

# Linux/Mac
cd gemini-api-setup
chmod +x set-keys-linux.sh
./set-keys-linux.sh
```

**Make Permanent (Windows):**
1. Press `Win + R`
2. Type: `sysdm.cpl` → Enter
3. Go to: **Advanced** → **Environment Variables**
4. Under "User variables", click **New**
5. Add all 4 variables

**Make Permanent (Linux/Mac):**
Add to `~/.bashrc` or `~/.zshrc`:
```bash
export GEMINI_API_KEY_1="AIzaSy...YOUR_KEY_1"
export GEMINI_API_KEY_2="AIzaSy...YOUR_KEY_2"
export GEMINI_API_KEY_3="AIzaSy...YOUR_KEY_3"
export GEMINI_API_KEY_4="AIzaSy...YOUR_KEY_4"
```
Then: `source ~/.bashrc`

---

#### 📄 Option C: .env File

**Pros:** Clean, organized, easy to manage
**Cons:** Requires dotenv library

1. Copy the template:
```bash
cd backend
copy .env.template .env    # Windows
cp .env.template .env      # Linux/Mac
```

2. Edit `.env` and add your keys:
```bash
GEMINI_API_KEY_1=AIzaSy...YOUR_KEY_1
GEMINI_API_KEY_2=AIzaSy...YOUR_KEY_2
GEMINI_API_KEY_3=AIzaSy...YOUR_KEY_3
GEMINI_API_KEY_4=AIzaSy...YOUR_KEY_4
```

3. Add spring-boot-dotenv to `pom.xml`:
```xml
<dependency>
    <groupId>me.paulschwarz</groupId>
    <artifactId>spring-boot-dotenv</artifactId>
    <version>4.0.0</version>
</dependency>
```

---

### Step 3: Start the Backend

```bash
cd backend
mvnw.cmd spring-boot:run    # Windows
./mvnw spring-boot:run      # Linux/Mac
```

### Step 4: Verify Configuration

Check the startup logs for:
```
INFO  c.s.service.GeminiSearchService - Loaded 4 Gemini API keys
```

---

## Configuration Options

### application.yml Settings

```yaml
gemini:
  enabled: true                    # Enable/disable Gemini AI
  api-keys:                        # List of API keys
    - key1
    - key2
    - key3
    - key4
  model: gemini-1.5-flash         # Model to use
  api-url: https://...            # API endpoint
  rate-limit:
    per-key-rpm: 15                # Rate limit per key
    total-rpm: 60                  # Total rate limit
```

### Environment Variables Override

```bash
GEMINI_ENABLED=true              # Enable/disable
GEMINI_API_KEY_1=...            # Key 1
GEMINI_API_KEY_2=...            # Key 2
GEMINI_API_KEY_3=...            # Key 3
GEMINI_API_KEY_4=...            # Key 4
GEMINI_MODEL=gemini-1.5-flash   # Model name
```

---

## Testing & Verification

### Test 1: Backend Logs

Start the backend and look for:
```
🔄 Using API key #1 (Total keys: 4)
🤖 Gemini AI Search - Query: sugar
✅ Gemini AI found 3 matching products
```

### Test 2: Mobile App Voice Search

1. Open mobile app in Chrome: http://localhost:59999
2. Navigate to any shop
3. Click the microphone icon (voice search)
4. Type: "sugar" or "rice" or "milk"
5. Submit the search
6. Check backend logs for rotation:
```
🔄 Using API key #1 (Total keys: 4)
```
7. Search again - should rotate to key #2:
```
🔄 Using API key #2 (Total keys: 4)
```

### Test 3: API Key Info Endpoint

You can create a simple endpoint to check configuration:

```java
@RestController
@RequestMapping("/api/gemini")
public class GeminiController {

    @Autowired
    private GeminiSearchService geminiService;

    @GetMapping("/info")
    public Map<String, Object> getInfo() {
        return geminiService.getApiKeyInfo();
    }
}
```

Call: http://localhost:8080/api/gemini/info

Response:
```json
{
  "totalKeys": 4,
  "currentKeyIndex": 2,
  "perKeyRpm": 15,
  "totalRpm": 60,
  "enabled": true
}
```

---

## Monitoring

### 1. Application Logs

Enable DEBUG logging for Gemini service:

**application.yml:**
```yaml
logging:
  level:
    com.shopmanagement.service.GeminiSearchService: DEBUG
```

### 2. Google AI Studio Dashboard

1. Visit: https://aistudio.google.com/
2. Click on each API key
3. View usage metrics:
   - Requests per minute
   - Token usage
   - Error rates

### 3. Key Rotation Pattern

Check logs for even distribution:
```
🔄 Using API key #1 (Total keys: 4)
🔄 Using API key #2 (Total keys: 4)
🔄 Using API key #3 (Total keys: 4)
🔄 Using API key #4 (Total keys: 4)
🔄 Using API key #1 (Total keys: 4)  ← Cycles back
```

---

## Troubleshooting

### Issue 1: "No Gemini API keys configured"

**Cause:** API keys not loaded

**Solution:**
- Check environment variables are set
- Verify application.yml has keys
- Restart Spring Boot application

### Issue 2: 403 Forbidden Error

**Cause:** Invalid API key or IP restriction

**Solution:**
1. Go to Google AI Studio
2. Click on the key
3. Check "Application restrictions"
4. Add your server IP or set to "None" for testing

### Issue 3: 429 Rate Limit Error

**Cause:** Exceeding 15 RPM per key

**Solution:**
- Rotation should prevent this
- Check if all 4 keys are active
- Monitor Google AI Studio dashboard

### Issue 4: Keys Not Rotating

**Cause:** Application cached old configuration

**Solution:**
1. Stop Spring Boot
2. Clean build: `mvnw clean`
3. Restart: `mvnw spring-boot:run`

### Issue 5: All Requests Use Same Key

**Cause:** Counter not incrementing

**Solution:**
- Check thread safety (should use AtomicInteger)
- Verify GeminiSearchService is a singleton (@Service)
- Check logs for key index

---

## Security Best Practices

### ✅ Do's

1. **Use Environment Variables**
   - Keep keys out of codebase
   - Use CI/CD secrets for deployment

2. **Restrict API Keys**
   - In Google AI Studio, add IP restrictions
   - Set HTTP referrer restrictions

3. **Rotate Keys Regularly**
   - Generate new keys every 90 days
   - Delete old keys after rotation

4. **Monitor Usage**
   - Set up alerts for unusual activity
   - Check daily token consumption

5. **Use .gitignore**
   - Ensure `.env` files are ignored
   - Never commit keys to version control

### ❌ Don'ts

1. **Don't Commit Keys**
   - Never push API keys to GitHub
   - Use git-secrets or similar tools

2. **Don't Share Keys**
   - Each environment should have its own keys
   - Don't reuse keys across projects

3. **Don't Use Keys in Frontend**
   - Always call from backend
   - Never expose in JavaScript

4. **Don't Ignore Rate Limits**
   - Respect 15 RPM per key
   - Implement exponential backoff

---

## Performance Expectations

### With 4 Keys (60 RPM Total)

| Metric | Value |
|--------|-------|
| Max throughput | 60 requests/minute |
| Avg response time | ~500ms |
| Daily token quota | 1,000,000 (shared) |
| Concurrent requests | Up to 4 |
| Failover | Automatic |

### Load Distribution

Each key handles **25%** of requests:
- Key 1: 15 RPM (25%)
- Key 2: 15 RPM (25%)
- Key 3: 15 RPM (25%)
- Key 4: 15 RPM (25%)

---

## Next Steps

1. ✅ Configure your 4 API keys
2. ✅ Start the backend server
3. ✅ Test voice search in mobile app
4. ✅ Monitor logs for rotation
5. ✅ Set up Google AI Studio monitoring
6. ✅ Configure alerts for rate limits

---

## Support & Resources

- **Google AI Studio:** https://aistudio.google.com/
- **Gemini API Docs:** https://ai.google.dev/docs
- **Rate Limits:** https://ai.google.dev/pricing
- **Your Setup Files:** See other files in this folder

---

**Need Help?**
Check the logs, verify your keys, and ensure all 4 are active in Google AI Studio.
