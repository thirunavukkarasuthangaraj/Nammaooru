# Firebase Configuration Files

**⚠️ SECURITY: Firebase files contain sensitive API keys and MUST NOT be committed to Git!**

## Server Location
All Firebase configuration files are stored on the production server at:
```
/opt/shop-management/firebase-config/
```

## Files Required

### 1. Backend (Java Spring Boot)
**File:** `firebase-service-account.json`
**Location:** `/opt/shop-management/firebase-config/firebase-service-account.json`

```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  "private_key": "...",
  "client_email": "...",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "..."
}
```

### 2. Android App
**File:** `google-services.json`
**Location:** `/opt/shop-management/firebase-config/google-services.json`

```json
{
  "project_info": {
    "project_number": "...",
    "firebase_url": "...",
    "project_id": "...",
    "storage_bucket": "..."
  },
  "client": [...]
}
```

### 3. iOS App (if needed)
**File:** `GoogleService-Info.plist`
**Location:** `/opt/shop-management/firebase-config/GoogleService-Info.plist`

### 4. Web/Frontend Config
**File:** `firebase-web-config.json`
**Location:** `/opt/shop-management/firebase-config/firebase-web-config.json`

```json
{
  "apiKey": "...",
  "authDomain": "...",
  "projectId": "...",
  "storageBucket": "...",
  "messagingSenderId": "...",
  "appId": "...",
  "measurementId": "..."
}
```

## How to Set Up on Server

### Step 1: Create Directory on Server
```bash
ssh root@65.21.4.236
mkdir -p /opt/shop-management/firebase-config
cd /opt/shop-management/firebase-config
```

### Step 2: Upload Firebase Files from Local Machine
```bash
# From your local machine (Windows):

# Backend service account
scp /path/to/firebase-service-account.json root@65.21.4.236:/opt/shop-management/firebase-config/

# Android config
scp /path/to/google-services.json root@65.21.4.236:/opt/shop-management/firebase-config/

# Web config
scp /path/to/firebase-web-config.json root@65.21.4.236:/opt/shop-management/firebase-config/
```

### Step 3: Set Proper Permissions
```bash
ssh root@65.21.4.236
chmod 600 /opt/shop-management/firebase-config/*.json
chown root:root /opt/shop-management/firebase-config/*.json
```

### Step 4: Verify Files Exist
```bash
ssh root@65.21.4.236
ls -la /opt/shop-management/firebase-config/
```

You should see:
```
-rw------- 1 root root  2345 Oct 13 12:00 firebase-service-account.json
-rw------- 1 root root  1234 Oct 13 12:00 google-services.json
-rw------- 1 root root   567 Oct 13 12:00 firebase-web-config.json
```

## How Applications Reference These Files

### Backend (Spring Boot)
**File:** `backend/src/main/resources/application-production.yml`

```yaml
firebase:
  service-account-file: /opt/shop-management/firebase-config/firebase-service-account.json
```

Or use environment variable:
```bash
FIREBASE_SERVICE_ACCOUNT=/opt/shop-management/firebase-config/firebase-service-account.json
```

### Docker Compose
Mount the firebase-config directory as a volume:

```yaml
services:
  backend:
    volumes:
      - /opt/shop-management/firebase-config:/app/firebase-config:ro
    environment:
      - FIREBASE_SERVICE_ACCOUNT=/app/firebase-config/firebase-service-account.json
```

### Android Build
During mobile app build, copy the file:
```bash
cp /opt/shop-management/firebase-config/google-services.json \
   /opt/shop-management/mobile/nammaooru_mobile_app/android/app/
```

### Frontend (Angular)
Set environment variables from the config file:
```typescript
// frontend/src/environments/environment.prod.ts
export const environment = {
  firebase: {
    apiKey: process.env.FIREBASE_API_KEY,
    authDomain: process.env.FIREBASE_AUTH_DOMAIN,
    // ... other config
  }
};
```

## CI/CD Integration

The CI/CD pipeline will:
1. ✅ **NOT overwrite** files in `/opt/shop-management/firebase-config/`
2. ✅ **Check** if files exist before deployment
3. ✅ **Warn** if files are missing

See `.github/workflows/deploy.yml` for implementation.

## Security Best Practices

### ✅ DO:
- Store files on server only
- Use strict permissions (600)
- Keep backups in secure location (not Git)
- Rotate keys regularly

### ❌ DON'T:
- Commit Firebase files to Git
- Share Firebase files in Slack/Email
- Use same Firebase project for dev and production
- Give Firebase files world-readable permissions

## Troubleshooting

### Error: "Firebase credentials not found"
```bash
# Check if file exists
ls -la /opt/shop-management/firebase-config/firebase-service-account.json

# Check permissions
stat /opt/shop-management/firebase-config/firebase-service-account.json

# Re-upload if missing
scp /local/path/to/file root@65.21.4.236:/opt/shop-management/firebase-config/
```

### Error: "Permission denied reading Firebase config"
```bash
# Fix permissions
chmod 600 /opt/shop-management/firebase-config/*.json
chown root:root /opt/shop-management/firebase-config/*.json
```

## Backup Strategy

### Create Encrypted Backup
```bash
# On server
cd /opt/shop-management
tar -czf firebase-backup-$(date +%Y%m%d).tar.gz firebase-config/
gpg -c firebase-backup-$(date +%Y%m%d).tar.gz
rm firebase-backup-$(date +%Y%m%d).tar.gz

# Download encrypted backup to local
scp root@65.21.4.236:/opt/shop-management/firebase-backup-*.tar.gz.gpg ~/secure-backups/
```

### Restore from Backup
```bash
# Upload encrypted backup
scp ~/secure-backups/firebase-backup-*.tar.gz.gpg root@65.21.4.236:/opt/shop-management/

# On server
cd /opt/shop-management
gpg -d firebase-backup-*.tar.gz.gpg > firebase-backup.tar.gz
tar -xzf firebase-backup.tar.gz
chmod 600 firebase-config/*.json
```

## Quick Setup Script

```bash
#!/bin/bash
# setup-firebase-config.sh
# Run on server: bash setup-firebase-config.sh

echo "Setting up Firebase configuration..."

# Create directory
mkdir -p /opt/shop-management/firebase-config

# Check if files exist
if [ ! -f "/opt/shop-management/firebase-config/firebase-service-account.json" ]; then
    echo "❌ Missing: firebase-service-account.json"
    echo "   Upload: scp /local/path/firebase-service-account.json root@65.21.4.236:/opt/shop-management/firebase-config/"
fi

if [ ! -f "/opt/shop-management/firebase-config/google-services.json" ]; then
    echo "⚠️  Missing: google-services.json (needed for mobile apps)"
    echo "   Upload: scp /local/path/google-services.json root@65.21.4.236:/opt/shop-management/firebase-config/"
fi

# Set permissions
chmod 700 /opt/shop-management/firebase-config
chmod 600 /opt/shop-management/firebase-config/*.json 2>/dev/null || true

# List files
echo ""
echo "Current Firebase config files:"
ls -la /opt/shop-management/firebase-config/

echo ""
echo "✅ Firebase config directory ready!"
```

---
**Last updated:** October 13, 2025
**Security Level:** HIGH - Never commit these files to Git!
