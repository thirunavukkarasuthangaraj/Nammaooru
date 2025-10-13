# Technical Architecture Documentation Update

## Updates Made: January 2025

This document contains updates to the TECHNICAL_ARCHITECTURE.md file regarding:
1. File Storage Architecture (Host Directory Mount)
2. Firebase Configuration
3. Nginx Configuration for File Serving
4. Docker Compose Configuration Updates

---

## 📦 File Storage Architecture (Updated)

### Overview

The system uses **host directory mount** for persistent file storage, ensuring files survive container restarts, rebuilds, and deployments.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     File Storage Architecture                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Host Server (Hetzner)                                          │
│                                                                 │
│  📁 /opt/shop-management/uploads/  ← PHYSICAL STORAGE          │
│     ├── products/                                               │
│     │   ├── master/         (Master product images)            │
│     │   └── shop/           (Shop-specific product images)     │
│     ├── shops/              (Shop logos, documents)            │
│     ├── delivery-proof/     (Delivery confirmation images)     │
│     │   ├── {orderId}/                                         │
│     │   │   ├── photo/                                         │
│     │   │   └── signature/                                     │
│     └── documents/          (Legal documents, invoices)        │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Docker Container (Backend)                            │    │
│  │                                                        │    │
│  │  📂 /app/uploads/  ←─────────────────────────┐       │    │
│  │     (Mounted from host)                       │       │    │
│  │                                               │       │    │
│  │  Spring Boot Backend writes here ────────────┘       │    │
│  │  Files actually written to host directory            │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Nginx (Host Process)                                  │    │
│  │                                                        │    │
│  │  Serves files from: /opt/shop-management/uploads/     │    │
│  │  Public URL: https://nammaoorudelivary.in/uploads/    │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘

                            ↓

┌─────────────────────────────────────────────────────────────────┐
│  Client Access (Mobile/Web)                                     │
│                                                                 │
│  https://nammaoorudelivary.in/uploads/products/master/xxx.jpg  │
│                                                                 │
│  ↓ Nginx serves directly from host filesystem                  │
│  ↓ Fast, no container overhead                                 │
│  ↓ Files persist through deployments                           │
└─────────────────────────────────────────────────────────────────┘
```

### File Upload Flow

```
┌─────────────┐
│ User Device │  (Mobile App / Web Browser)
└──────┬──────┘
       │ 1. Upload Image (multipart/form-data)
       ↓
┌──────────────────────────────────────────────┐
│ Nginx (Port 80/443)                          │
│ Domain: nammaoorudelivary.in                 │
└──────┬───────────────────────────────────────┘
       │ 2. Proxy to Backend
       ↓
┌──────────────────────────────────────────────┐
│ Spring Boot Backend (Port 8082 → 8080)      │
│ Container: nammaooru-backend                 │
│                                              │
│ FileUploadService.uploadFile()               │
│ ├─ Validate file (size, type, extension)    │
│ ├─ Generate unique filename                 │
│ └─ Save to: /app/uploads/{category}/         │
└──────┬───────────────────────────────────────┘
       │ 3. Write file (via mount)
       ↓
┌──────────────────────────────────────────────┐
│ Host Filesystem                              │
│ /opt/shop-management/uploads/{category}/     │
│                                              │
│ File persists here (survives container       │
│ restarts, rebuilds, and deployments)         │
└──────┬───────────────────────────────────────┘
       │ 4. Return URL
       ↓
┌──────────────────────────────────────────────┐
│ Backend Response                             │
│ {                                            │
│   "imageUrl": "/uploads/products/xxx.jpg"    │
│ }                                            │
└──────┬───────────────────────────────────────┘
       │ 5. Frontend displays image
       ↓
┌──────────────────────────────────────────────┐
│ Image Request                                │
│ GET https://nammaoorudelivary.in/uploads/   │
│     products/master/xxx.jpg                  │
└──────┬───────────────────────────────────────┘
       │ 6. Nginx serves directly
       ↓
┌──────────────────────────────────────────────┐
│ Nginx reads from:                            │
│ /opt/shop-management/uploads/products/       │
│     master/xxx.jpg                           │
│                                              │
│ Response: Image file (with caching headers)  │
└──────────────────────────────────────────────┘
```

### Storage Configuration

#### Docker Compose Configuration

```yaml
# docker-compose.yml (Production)
version: '3.8'

services:
  backend:
    build:
      context: ./backend
    container_name: nammaooru-backend
    environment:
      - SPRING_PROFILES_ACTIVE=production
      - FILE_UPLOAD_PATH=/app/uploads
      - APP_UPLOAD_DIR=/app/uploads
      - DOCUMENT_UPLOAD_PATH=/app/uploads/documents
      - PRODUCT_IMAGES_PATH=products
      - FIREBASE_SERVICE_ACCOUNT=/app/firebase-config/firebase-service-account.json
    ports:
      - "0.0.0.0:8082:8080"
    volumes:
      # Host directory mount for persistent file storage
      - /opt/shop-management/uploads:/app/uploads
      # Firebase configuration (read-only)
      - ./firebase-config:/app/firebase-config:ro
    networks:
      - shop-network
    restart: unless-stopped

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: nammaooru-frontend
    ports:
      - "8080:80"
    networks:
      - shop-network
    depends_on:
      - backend
    restart: unless-stopped

networks:
  shop-network:
    driver: bridge

# Note: No Docker volumes for uploads - using host directory mount instead
# This allows nginx to serve files directly and ensures persistence
```

#### Nginx Configuration

```nginx
# /etc/nginx/sites-available/nammaoorudelivary.conf

server {
    listen 80;
    server_name nammaoorudelivary.in www.nammaoorudelivary.in;

    # Serve uploaded images/files directly from host directory
    location /uploads/ {
        alias /opt/shop-management/uploads/;

        # Caching headers for performance
        expires 30d;
        add_header Cache-Control "public, immutable";

        # Disable access logs for uploads (optional)
        access_log off;

        # Enable CORS for uploaded files
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS' always;

        # Security: prevent directory listing
        autoindex off;
    }

    # Frontend proxy (Angular app running in Docker on port 8080)
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # API proxy (Spring Boot backend)
    location /api {
        proxy_pass http://localhost:8082;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # CORS headers removed - configured in SecurityConfig.java
        # to avoid duplicate headers
    }
}
```

### File Storage Characteristics

| Aspect | Configuration |
|--------|---------------|
| **Storage Type** | Host Directory Mount |
| **Host Path** | `/opt/shop-management/uploads/` |
| **Container Path** | `/app/uploads/` |
| **Mount Type** | Bind Mount (read-write) |
| **Persistence** | Survives container removal, rebuild, and deployment |
| **Accessibility** | Backend (R/W), Nginx (R), External (R via HTTP) |
| **Backup** | Simple filesystem backup |
| **Scalability** | Single server (for horizontal scaling, use cloud storage) |

### File Categories and Paths

```
/opt/shop-management/uploads/
├── products/
│   ├── master/                    # Master product images
│   │   └── master_{id}_{timestamp}_{uuid}.jpg
│   └── shop/                      # Shop-specific product images
│       └── shop_{shopId}_{productId}_{timestamp}_{uuid}.jpg
│
├── shops/                         # Shop images and logos
│   └── {shopId}/
│       └── shop_image_{timestamp}_{uuid}.jpg
│
├── delivery-proof/                # Delivery confirmation images
│   └── {orderId}/
│       ├── photo/                 # Delivery photo proof
│       │   └── order_{orderId}_photo_{timestamp}_{uuid}.jpg
│       └── signature/             # Customer signature
│           └── order_{orderId}_signature_{timestamp}_{uuid}.jpg
│
└── documents/                     # Legal and business documents
    ├── shop-documents/
    ├── delivery-partner-documents/
    └── invoices/
```

### Storage Persistence Testing

```bash
# Test file persistence

# 1. Create test file on host
echo "test" > /opt/shop-management/uploads/test.txt

# 2. Verify container can see it
docker exec nammaooru-backend ls -la /app/uploads/test.txt
# Should show the file

# 3. Delete container
docker rm -f nammaooru-backend

# 4. Verify file still exists on host
cat /opt/shop-management/uploads/test.txt
# Should print: test

# 5. Recreate container
docker-compose up -d

# 6. Verify new container sees the file
docker exec nammaooru-backend cat /app/uploads/test.txt
# Should print: test

# 7. Verify nginx can serve it
curl http://localhost/uploads/test.txt
# Should print: test

# 8. Cleanup
rm /opt/shop-management/uploads/test.txt
```

---

## 🔥 Firebase Push Notification Configuration

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ Firebase Cloud Messaging (FCM) Integration                     │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│ Backend Service  │
│ (Spring Boot)    │
│                  │
│ Reads config:    │
│ /app/firebase-   │
│ config/firebase- │
│ service-account  │
│ .json            │
└────────┬─────────┘
         │
         │ 1. Load credentials
         │ 2. Initialize Firebase Admin SDK
         │
         ↓
┌────────────────────────────────────┐
│ Firebase Admin SDK                 │
│                                    │
│ - Authentication                   │
│ - Cloud Messaging API              │
│ - Token Management                 │
└────────┬───────────────────────────┘
         │
         │ 3. Send notification
         │
         ↓
┌────────────────────────────────────┐
│ Firebase Cloud Messaging (FCM)     │
│                                    │
│ - Google's notification service    │
│ - Handles delivery to devices      │
└────────┬───────────────────────────┘
         │
         │ 4. Push to devices
         │
         ↓
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Mobile App   │    │ Mobile App   │    │ Mobile App   │
│ (Customer)   │    │ (Shop Owner) │    │ (Delivery)   │
│              │    │              │    │              │
│ - FCM Token  │    │ - FCM Token  │    │ - FCM Token  │
│ - Receives   │    │ - Receives   │    │ - Receives   │
│   push       │    │   push       │    │   push       │
└──────────────┘    └──────────────┘    └──────────────┘
```

### Firebase Configuration Setup

#### File Location

```
/opt/shop-management/
├── firebase-config/
│   └── firebase-service-account.json  ← Firebase credentials
├── backend/
├── frontend/
├── docker-compose.yml
└── uploads/
```

#### Docker Mount Configuration

```yaml
services:
  backend:
    volumes:
      # Mount firebase config as read-only
      - ./firebase-config:/app/firebase-config:ro
    environment:
      - FIREBASE_SERVICE_ACCOUNT=/app/firebase-config/firebase-service-account.json
```

#### Firebase Service Account JSON Structure

```json
{
  "type": "service_account",
  "project_id": "nammaooru-xxxxx",
  "private_key_id": "xxxxx",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@nammaooru-xxxxx.iam.gserviceaccount.com",
  "client_id": "xxxxx",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

### Deployment Verification

The CI/CD pipeline automatically checks for Firebase configuration:

```bash
# From .github/workflows/deploy.yml

# Check Firebase configuration (DO NOT overwrite existing files)
echo "=== STEP 3.2: Check Firebase configuration ==="
if [ ! -d "firebase-config" ]; then
  echo "Creating firebase-config directory..."
  mkdir -p firebase-config
  chmod 700 firebase-config
fi

if [ ! -f "firebase-config/firebase-service-account.json" ]; then
  echo "⚠️  WARNING: firebase-service-account.json NOT FOUND!"
  echo "   Backend may fail if Firebase is required."
  echo "   Upload: scp /path/to/firebase-service-account.json root@65.21.4.236:/opt/shop-management/firebase-config/"
else
  echo "✅ Firebase service account found"
fi
```

### Firebase Setup Instructions

#### Step 1: Obtain Firebase Service Account

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project (or create new)
3. Go to Project Settings → Service Accounts
4. Click "Generate New Private Key"
5. Download the JSON file

#### Step 2: Upload to Server

```bash
# From your local machine
scp /path/to/firebase-service-account.json root@65.21.4.236:/opt/shop-management/firebase-config/

# On server, set permissions
ssh root@65.21.4.236
chmod 700 /opt/shop-management/firebase-config
chmod 600 /opt/shop-management/firebase-config/firebase-service-account.json
```

#### Step 3: Verify Configuration

```bash
# Check file exists
ls -la /opt/shop-management/firebase-config/

# Check container can access it
docker exec nammaooru-backend ls -la /app/firebase-config/

# Check backend logs for Firebase initialization
docker logs nammaooru-backend | grep -i firebase
```

---

## 📊 Complete System Diagram (Updated)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    NammaOoru Production Infrastructure                  │
│                        Hetzner Cloud Server (Ubuntu)                    │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│  Internet Traffic                                                       │
│  https://nammaoorudelivary.in                                          │
└───────────────────────────┬─────────────────────────────────────────────┘
                            │
                            ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  Nginx (Port 80/443)                                                    │
│  - SSL Termination (Let's Encrypt)                                     │
│  - Reverse Proxy                                                        │
│  - Static File Serving                                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  location / {                                                           │
│    proxy_pass http://localhost:8080;  ← Frontend Container            │
│  }                                                                      │
│                                                                         │
│  location /api {                                                        │
│    proxy_pass http://localhost:8082;  ← Backend Container             │
│  }                                                                      │
│                                                                         │
│  location /uploads/ {                                                   │
│    alias /opt/shop-management/uploads/;  ← Host Directory             │
│  }                                                                      │
└────┬────────────────────┬───────────────────┬──────────────────────────┘
     │                    │                   │
     ↓                    ↓                   ↓
┌─────────────┐  ┌────────────────┐  ┌───────────────────┐
│  Frontend   │  │   Backend      │  │ Host Uploads Dir  │
│  Container  │  │   Container    │  │                   │
│  (Port 8080)│  │   (Port 8082)  │  │ /opt/shop-       │
│             │  │                │  │ management/       │
│  nammaooru- │  │  nammaooru-    │  │ uploads/          │
│  frontend   │  │  backend       │  │                   │
└─────────────┘  └────┬───────────┘  └───────────────────┘
                      │
                      │ Mounts:
                      │ - /opt/shop-management/uploads:/app/uploads
                      │ - ./firebase-config:/app/firebase-config:ro
                      │
                      ↓
      ┌───────────────┴────────────────┬───────────────┐
      │                                │               │
      ↓                                ↓               ↓
┌─────────────┐         ┌──────────────────┐  ┌──────────────┐
│ PostgreSQL  │         │  Firebase FCM    │  │  External    │
│ Database    │         │                  │  │  APIs        │
│             │         │  Push            │  │              │
│ Port: 5432  │         │  Notifications   │  │ - MSG91 SMS  │
│             │         │                  │  │ - Google     │
│ - Users     │         │  Reads:          │  │   Maps       │
│ - Orders    │         │  /app/firebase-  │  │ - Email SMTP │
│ - Products  │         │  config/         │  │              │
└─────────────┘         └──────────────────┘  └──────────────┘
```

---

## 🔐 Security Considerations

### File Storage Security

1. **Directory Permissions**
   ```bash
   chmod 755 /opt/shop-management/uploads
   # Owner: rwx, Group: r-x, Others: r-x
   ```

2. **Nginx Security**
   - Disabled directory listing (`autoindex off`)
   - Read-only access via HTTP
   - File type restrictions (handled by backend)

3. **Backend Validation**
   - File size limits (5MB for images)
   - Allowed extensions: jpg, jpeg, png, gif, webp
   - Malware scanning (recommended for production)

### Firebase Security

1. **Service Account Protection**
   ```bash
   chmod 700 /opt/shop-management/firebase-config
   chmod 600 /opt/shop-management/firebase-config/firebase-service-account.json
   ```

2. **Read-Only Mount**
   - Firebase config mounted as `:ro` (read-only) in container
   - Prevents accidental modification

3. **Environment Variables**
   - Never commit Firebase credentials to git
   - Use environment variables or mounted files only

---

## 📝 Monitoring and Maintenance

### File Storage Monitoring

```bash
# Disk usage
df -h /opt/shop-management/uploads

# File count by category
find /opt/shop-management/uploads -type f | wc -l

# Size by subdirectory
du -h --max-depth=1 /opt/shop-management/uploads

# Recent uploads
find /opt/shop-management/uploads -type f -mtime -1 -ls
```

### Backup Strategy

```bash
# Daily backup script
#!/bin/bash
tar -czf /backups/uploads-$(date +%Y%m%d).tar.gz \
  /opt/shop-management/uploads/

# Keep last 30 days
find /backups/ -name "uploads-*.tar.gz" -mtime +30 -delete
```

### Performance Metrics

- **Upload Speed**: ~10MB/s (network dependent)
- **Download Speed**: Cached by Nginx (30 days)
- **Storage Growth**: Monitor weekly
- **Disk Alert Threshold**: 80% capacity

---

## 🚀 Deployment Checklist

### Pre-Deployment

- [ ] Create uploads directory: `mkdir -p /opt/shop-management/uploads`
- [ ] Set permissions: `chmod 755 /opt/shop-management/uploads`
- [ ] Upload Firebase config
- [ ] Copy existing images from local to server
- [ ] Verify nginx config: `nginx -t`

### Post-Deployment

- [ ] Verify mount: `docker exec nammaooru-backend ls /app/uploads`
- [ ] Test upload via API
- [ ] Test image URL in browser
- [ ] Check backend logs: `docker logs nammaooru-backend`
- [ ] Verify Firebase initialization in logs

---

## 📚 References

- Docker Compose File: `/opt/shop-management/docker-compose.yml`
- Nginx Config: `/etc/nginx/sites-available/nammaoorudelivary.conf`
- Backend Config: `backend/src/main/resources/application-production.yml`
- File Upload Service: `backend/src/main/java/com/shopmanagement/service/FileUploadService.java`
- CI/CD Pipeline: `.github/workflows/deploy.yml`
