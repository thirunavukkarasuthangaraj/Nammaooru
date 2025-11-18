# 🤖 Gemini API - 4 Keys Rotation Setup

## 📋 Overview
This folder contains all configuration files for setting up **4 Gemini API keys** with automatic round-robin rotation to achieve **60 requests/minute** (15 RPM × 4 keys).

## 📁 Files in This Folder

1. **README.md** - This file (overview and quick start)
2. **setup-guide.md** - Detailed setup instructions
3. **your-api-keys.txt** - Template to paste your actual API keys
4. **set-keys-windows.bat** - Windows script to set environment variables
5. **set-keys-linux.sh** - Linux/Mac script to set environment variables
6. **.env.template** - Environment variables template

## 🎯 Quick Start (3 Steps)

### Step 1: Get Your API Keys
From your Google AI Studio screenshot, you have these 4 keys:
```
Key 1 (key3):          ...GB3Q  → Created: Nov 11, 2025
Key 2 (key2):          ...JlQE  → Created: Nov 11, 2025
Key 3 (key1):          ...CmQo  → Created: Nov 11, 2025
Key 4 (ProductSearch): ...XoTc  → Created: Nov 10, 2025
```

### Step 2: Copy Full API Keys
1. Go to https://aistudio.google.com/api-keys
2. Click "Show API key" for each key
3. Copy the full keys to `your-api-keys.txt` in this folder

### Step 3: Update Configuration

**Option A: Direct Update (Fastest)**
Edit: `backend/src/main/resources/application.yml` (lines 192-196)
```yaml
api-keys:
  - YOUR_FULL_KEY_1_HERE  # GB3Q
  - YOUR_FULL_KEY_2_HERE  # JlQE
  - YOUR_FULL_KEY_3_HERE  # CmQo
  - YOUR_FULL_KEY_4_HERE  # XoTc
```

**Option B: Environment Variables (Most Secure)**
```bash
# Windows
set GEMINI_API_KEY_1=YOUR_FULL_KEY_1
set GEMINI_API_KEY_2=YOUR_FULL_KEY_2
set GEMINI_API_KEY_3=YOUR_FULL_KEY_3
set GEMINI_API_KEY_4=YOUR_FULL_KEY_4

# Or use the batch script
cd gemini-api-setup
set-keys-windows.bat
```

## ✅ What's Already Done

### Backend Code Changes ✓
- `GeminiSearchService.java` - Updated with rotation logic
- `application.yml` - Configured for 4 keys
- `.gitignore` - Protected environment files

### How Rotation Works
```
Request 1 → Key 1 (GB3Q)
Request 2 → Key 2 (JlQE)
Request 3 → Key 3 (CmQo)
Request 4 → Key 4 (XoTc)
Request 5 → Key 1 (GB3Q) ← Cycles back
```

## 🧪 Testing

1. Start backend: `cd backend && mvnw.cmd spring-boot:run`
2. Open mobile app in browser
3. Use voice search multiple times
4. Check logs for rotation:
   ```
   🔄 Using API key #1 (Total keys: 4)
   🔄 Using API key #2 (Total keys: 4)
   🔄 Using API key #3 (Total keys: 4)
   🔄 Using API key #4 (Total keys: 4)
   ```

## 📊 Expected Performance

| Metric | Value |
|--------|-------|
| Keys | 4 |
| RPM per key | 15 |
| **Total RPM** | **60** |
| Daily tokens | 1,000,000 (shared) |
| Response time | ~500ms |

## 🔒 Security Checklist

- [ ] Don't commit API keys to Git
- [ ] Use environment variables for production
- [ ] Restrict keys to server IP in Google AI Studio
- [ ] Rotate keys every 90 days
- [ ] Monitor usage in dashboard

## 📚 Need More Help?

See `setup-guide.md` for detailed instructions with screenshots and troubleshooting.

## 🎉 You're All Set!

Once you update the keys, your system will automatically:
- ✅ Rotate through all 4 keys
- ✅ Handle 60 requests/minute
- ✅ Balance load across keys
- ✅ Work seamlessly with voice search
