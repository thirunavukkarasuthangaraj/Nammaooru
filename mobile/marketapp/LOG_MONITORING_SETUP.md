# Mobile App Log Monitoring Setup Guide

**Date:** August 27, 2025  
**App:** NammaOoru Mobile (com.nammaooru.app)  
**Device:** Connected via ADB  

---

## 📱 **Current App Status**

- **Package:** `com.nammaooru.app`
- **Process ID:** `3390`
- **Status:** ✅ Running and responsive
- **Device:** Connected via ADB

---

## 🔧 **Log Monitoring Commands**

### **1. Real-Time App Logs**
```bash
# Monitor specific app process
adb logcat --pid=3390 -v time

# Monitor by package name
adb logcat | findstr "com.nammaooru.app"
```

### **2. HTTP/API Request Monitoring**
```bash
# Monitor HTTP requests and responses
adb logcat | findstr -i "http\|api\|network\|request\|response"

# Monitor specific API endpoints
adb logcat | findstr -i "192.168.1.3\|register\|auth"

# Monitor with Dio (Flutter HTTP library)
adb logcat | findstr -i "dio\|http\|api"
```

### **3. Flutter-Specific Logs**
```bash
# Flutter framework logs
adb logcat | findstr "flutter"

# Flutter engine logs
adb logcat | findstr "FlutterEngine"

# Dart VM logs
adb logcat | findstr "dart"
```

### **4. Error and Debug Logs**
```bash
# Error logs only
adb logcat *:E *:W

# Debug logs with timestamp
adb logcat -v time | findstr -i "error\|exception\|debug"
```

---

## 🚀 **Active Monitoring Sessions**

### **Currently Running Monitors:**

1. **General App Logs:**
   ```bash
   adb logcat --pid=3390 -v time
   ```
   **Status:** ✅ Active (bash_5)  
   **Showing:** UI interactions, navigation, system events

2. **HTTP/API Monitor:**
   ```bash
   adb logcat -v time | findstr -i "http\|api\|dio\|request\|response\|192.168.1.3\|register\|auth"
   ```
   **Status:** ✅ Active (bash_7)  
   **Purpose:** Catch API calls when user registers

---

## 📊 **Log Analysis Results**

### **What We've Observed:**

✅ **App Launch:** Successful initialization  
✅ **Firebase:** Properly initialized  
✅ **UI Rendering:** Flutter surfaces working  
✅ **User Interactions:** Touch events captured  
✅ **Navigation:** Screen transitions working  
✅ **Keyboard Input:** Input method working  

### **Key Log Patterns:**

```
08-28 03:13:26.867 I/FirebaseApp( 3390): Device unlocked: initializing all Firebase APIs
08-28 03:13:27.327 I/SurfaceView@6009e71( 3390): surfaceCreated 1 #8
08-28 03:13:33.692 I/ViewRootImpl@328370a[MainActivity]( 3390): ViewPostIme pointer 0
08-28 03:13:33.791 I/ViewRootImpl@328370a[MainActivity]( 3390): ViewPostIme pointer 1
```

**Translation:**
- Firebase initialized ✅
- Flutter UI surface created ✅  
- Touch interactions working ✅

---

## 🔍 **API Testing Readiness**

### **Backend Status:**
- **Server:** Running on `http://192.168.1.3:8082/api`
- **Endpoint:** `/auth/register` tested and functional
- **Database:** PostgreSQL connected

### **Mobile App Status:**
- **API Configuration:** Updated to use `192.168.1.3:8082`
- **Network Access:** Device can reach backend
- **Registration Form:** Ready for testing

### **Monitoring Ready:**
All log monitors are active and will capture:
- HTTP request details
- API response data  
- Error messages
- Network connectivity issues

---

## 📋 **Testing Procedure**

### **To Test API Registration:**

1. **Keep terminals open** with active log monitoring
2. **On the mobile device:**
   - Open NammaOoru app
   - Go to "Sign Up" tab
   - Fill registration form:
     - Username: `testuser2`
     - Email: `test2@test.com`
     - Full Name: `Test User 2`
     - Phone: `9876543210`
     - Password: `test123`
     - Confirm Password: `test123`
     - ✅ Check terms agreement
   - Tap **"Create Account"**

3. **Observe logs** for:
   - HTTP request to `/auth/register`
   - Request payload
   - Response status and data
   - Any errors or exceptions

---

## 🛠️ **Troubleshooting Commands**

### **If No HTTP Logs Appear:**

```bash
# Check network connectivity
adb logcat | findstr -i "connect\|network\|internet"

# Check for exceptions
adb logcat | findstr -i "exception\|error" 

# Check Flutter framework logs
adb logcat | findstr -i "flutter\|dart"
```

### **Clear and Restart Logs:**
```bash
# Clear existing logs
adb logcat -c

# Start fresh monitoring
adb logcat -v time
```

---

## 📱 **Device Information**

- **Connected Device:** ✅ Available
- **ADB Path:** `C:\Users\MVNLA\AppData\Local\Android\Sdk\platform-tools\adb`
- **App Process:** PID 3390
- **Log Format:** Time-stamped (`-v time`)

---

## 🎯 **Current Monitoring Status**

🟢 **Active Monitors:** 2 running  
🟢 **App Status:** Running and responsive  
🟢 **Backend Status:** Connected and ready  
🟢 **Ready for API Testing:** ✅ All systems go!

---

**📞 Ready to capture your API calls! Try registering a user now.**