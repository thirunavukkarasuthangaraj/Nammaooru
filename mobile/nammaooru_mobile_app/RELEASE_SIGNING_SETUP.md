# 🔐 Release APK Signing Setup for NammaOoru Customer App

**Complete guide to create properly signed release APK for Google Play Store**

---

## 📋 What You Need:

1. ✅ Keystore file (signing key)
2. ✅ Keystore password
3. ✅ Key alias
4. ✅ Key password

---

## 🚀 Step-by-Step Setup:

### **Step 1: Generate Keystore (ONE TIME ONLY)**

Run the keystore generator:

```bash
cd mobile\nammaooru_mobile_app
create_keystore.bat
```

**You'll be asked for:**

| Question | Example Answer | Notes |
|----------|---------------|-------|
| Keystore password | `MySecure123!` | **Remember this!** |
| Re-enter password | `MySecure123!` | Same as above |
| Key password | `MySecure123!` | Can be same as keystore password |
| First and last name | `Thiruna Kumar` | Your name |
| Organizational unit | `Development` | Your department |
| Organization name | `NammaOoru` | Company name |
| City | `Chennai` | Your city |
| State/Province | `Tamil Nadu` | Your state |
| Country code | `IN` | Two-letter code (IN for India) |

**Output:**
```
✅ File created: android/app/nammaooru-customer-release-key.jks
```

---

### **Step 2: Create key.properties File**

Create file: `android/key.properties`

```properties
storePassword=MySecure123!
keyPassword=MySecure123!
keyAlias=nammaooru-customer
storeFile=app/nammaooru-customer-release-key.jks
```

**Replace with YOUR passwords from Step 1!**

---

### **Step 3: Verify Files**

Check that these files exist:

```
android/
  ├── app/
  │   └── nammaooru-customer-release-key.jks  ✅ Created in Step 1
  └── key.properties                          ✅ Created in Step 2
```

---

### **Step 4: Build Signed Release APK**

```bash
flutter clean
flutter build apk --release
```

**Output:**
```
✅ Built build\app\outputs\flutter-apk\app-release.apk
```

**This APK is now signed with YOUR key and ready for Play Store!**

---

### **Step 5: Build Signed App Bundle (For Play Store)**

```bash
flutter build appbundle --release
```

**Output:**
```
✅ Built build\app\outputs\bundle\release\app-release.aab
```

**Upload this .aab file to Google Play Store!**

---

## ⚠️ IMPORTANT SECURITY:

### **🔐 NEVER Commit These Files to Git:**

- ❌ `android/app/*.jks` (keystore file)
- ❌ `android/key.properties` (passwords)
- ✅ Already in .gitignore

### **💾 BACKUP Your Keystore:**

```
android/app/nammaooru-customer-release-key.jks
```

**Save this file in:**
- 📦 External hard drive
- ☁️ Secure cloud storage (encrypted)
- 🔑 Password manager

**⚠️ If you lose this keystore, you CANNOT update your app on Play Store!**

---

## 📱 App Information:

### **Current Configuration:**

```gradle
applicationId: com.nammaooru.app
versionCode: 1
versionName: 1.0
targetSdk: 34
minSdk: 21 (Android 5.0+)
```

### **Signing:**

```
Keystore: nammaooru-customer-release-key.jks
Alias: nammaooru-customer
Validity: 10,000 days (~27 years)
Algorithm: RSA 2048-bit
```

---

## 🎯 Quick Commands:

### **Build Release APK:**
```bash
flutter build apk --release
```

### **Build App Bundle (Play Store):**
```bash
flutter build appbundle --release
```

### **Build Split APKs (Smaller):**
```bash
flutter build apk --split-per-abi --release
```

---

## 📦 Output Locations:

### **APK (Universal):**
```
build/app/outputs/flutter-apk/app-release.apk
Size: ~57MB
```

### **App Bundle (Play Store):**
```
build/app/outputs/bundle/release/app-release.aab
Size: ~25-30MB
Users download: 15-20MB (optimized by Play Store)
```

### **Split APKs:**
```
build/app/outputs/flutter-apk/
  ├── app-arm64-v8a-release.apk     (15MB)
  ├── app-armeabi-v7a-release.apk   (14MB)
  └── app-x86_64-release.apk        (16MB)
```

---

## 🔧 Troubleshooting:

### **Error: "Keystore was tampered with"**
- Wrong keystore password
- Check `key.properties` file

### **Error: "Key not found"**
- Wrong key alias
- Check `keyAlias` in `key.properties`

### **Warning: "Using debug signing"**
- `key.properties` file not found
- Create it in `android/` folder

---

## ✅ Verification:

### **Check if APK is properly signed:**

```bash
# Windows (PowerShell)
Get-Content build\app\outputs\flutter-apk\app-release.apk | Select-String "META-INF"

# Should show: META-INF/CERT.RSA (not DEBUG)
```

### **View signing info:**

```bash
keytool -list -v -keystore android\app\nammaooru-customer-release-key.jks
```

---

## 🎉 You're Ready!

**Upload to Play Store:**
1. Build app bundle: `flutter build appbundle --release`
2. Go to Play Console: https://play.google.com/console
3. Create new release
4. Upload: `app-release.aab`
5. Fill in store listing
6. Submit for review

**Your app is now properly signed and ready for production!** 🚀
