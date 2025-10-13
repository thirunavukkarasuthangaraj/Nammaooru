# File Storage Setup Guide

## Current Setup (Recommended)

Files are stored on the host machine at `/opt/shop-management/uploads` and mounted into Docker.

### How It Works:
```
Server Filesystem: /opt/shop-management/uploads/
                   ├── products/
                   │   ├── master/
                   │   └── shop/
                   ├── shops/
                   ├── delivery-proof/
                   └── documents/

Docker Container: /app/uploads/ (mounted from above)

Nginx: Serves directly from /opt/shop-management/uploads/
```

### Setup Commands (Run Once on Server):

```bash
# 1. Create uploads directory with proper permissions
sudo mkdir -p /opt/shop-management/uploads
sudo chmod -R 755 /opt/shop-management/uploads

# 2. Create subdirectories
cd /opt/shop-management/uploads
mkdir -p products/master products/shop shops delivery-proof documents

# 3. Verify permissions
ls -la /opt/shop-management/uploads

# Expected output:
# drwxr-xr-x ... uploads
# drwxr-xr-x ... products
# drwxr-xr-x ... shops
# etc.
```

### Verify Storage is Working:

```bash
# Test 1: Create test file on host
echo "test" > /opt/shop-management/uploads/test.txt

# Test 2: Start containers
docker-compose up -d

# Test 3: Check file is accessible inside container
docker exec nammaooru-backend ls -la /app/uploads/
# Should show test.txt

# Test 4: Upload image via API and verify
# Upload an image through your app, then check:
ls -la /opt/shop-management/uploads/products/

# Test 5: Verify nginx can serve it
curl http://localhost/uploads/test.txt
# Should return "test"
```

### Files Persist Through:
- ✅ Container restart
- ✅ Container removal
- ✅ Image rebuild
- ✅ `docker-compose down`
- ✅ Server reboot

### Files are LOST if:
- ❌ You delete `/opt/shop-management/uploads` directory
- ❌ You format the server disk

---

## Alternative: Cloud Storage (Recommended for Production)

If you want even more safety, use cloud storage:

### Option 1: DigitalOcean Spaces (S3-compatible)

**Advantages:**
- Automatic backups
- CDN included
- Unlimited storage
- Files survive server failure
- ~$5/month for 250GB

**Setup:**

```bash
# 1. Create Space on DigitalOcean
# - Name: nammaooru-uploads
# - Region: Frankfurt (closest to your server)

# 2. Update docker-compose.yml
environment:
  - FILE_STORAGE_TYPE=s3
  - S3_ENABLED=true
  - S3_ENDPOINT=https://fra1.digitaloceanspaces.com
  - S3_REGION=fra1
  - S3_BUCKET=nammaooru-uploads
  - S3_ACCESS_KEY=your_access_key_here
  - S3_SECRET_KEY=your_secret_key_here
  - S3_PUBLIC_URL=https://nammaooru-uploads.fra1.cdn.digitaloceanspaces.com

# 3. No nginx configuration needed - files served from CDN
```

### Option 2: Cloudinary (Best for Images)

**Advantages:**
- Automatic image optimization
- Automatic resizing
- Automatic format conversion (WebP)
- Free tier: 25GB storage, 25GB bandwidth/month

**Setup:**

```bash
# 1. Create account at cloudinary.com
# 2. Update docker-compose.yml
environment:
  - FILE_STORAGE_TYPE=cloudinary
  - CLOUDINARY_ENABLED=true
  - CLOUDINARY_CLOUD_NAME=your_cloud_name
  - CLOUDINARY_API_KEY=your_api_key
  - CLOUDINARY_API_SECRET=your_api_secret
```

---

## Backup Strategy

### Daily Backup Script:

```bash
#!/bin/bash
# Save as: /opt/shop-management/backup-uploads.sh

UPLOAD_DIR="/opt/shop-management/uploads"
BACKUP_DIR="/opt/shop-management/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup
mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/uploads_$DATE.tar.gz -C $UPLOAD_DIR .

# Keep only last 7 days
find $BACKUP_DIR -name "uploads_*.tar.gz" -mtime +7 -delete

echo "Backup completed: uploads_$DATE.tar.gz"
```

**Setup cron job:**
```bash
# Run daily at 2 AM
crontab -e

# Add this line:
0 2 * * * /opt/shop-management/backup-uploads.sh
```

---

## Troubleshooting

### Problem: "Permission denied" when uploading

```bash
# Fix permissions
sudo chmod -R 755 /opt/shop-management/uploads
sudo chown -R root:root /opt/shop-management/uploads
```

### Problem: Files not showing in container

```bash
# Check mount
docker inspect nammaooru-backend | grep -A 5 Mounts

# Should show:
# "Source": "/opt/shop-management/uploads"
# "Destination": "/app/uploads"
```

### Problem: Nginx returns 404 for images

```bash
# 1. Check nginx config
nginx -t

# 2. Verify file exists
ls -la /opt/shop-management/uploads/products/...

# 3. Check nginx can read directory
sudo -u www-data ls /opt/shop-management/uploads

# 4. Reload nginx
systemctl reload nginx
```

### Problem: Files disappear after deployment

```bash
# This means you're using Docker volume instead of host mount
# Solution: Use host mount as configured in docker-compose.yml

# Check current setup:
docker inspect nammaooru-backend | grep -A 10 Mounts

# Should show:
# "Type": "bind"  (NOT "volume")
# "Source": "/opt/shop-management/uploads"
```

---

## Migration to Cloud Storage (Future)

If you decide to migrate to cloud storage later:

```bash
# 1. Install rclone
curl https://rclone.org/install.sh | sudo bash

# 2. Configure DigitalOcean Spaces
rclone config

# 3. Sync existing files
rclone sync /opt/shop-management/uploads/ spaces:nammaooru-uploads/

# 4. Verify
rclone ls spaces:nammaooru-uploads/

# 5. Update docker-compose.yml to use S3
# 6. Restart containers
```
