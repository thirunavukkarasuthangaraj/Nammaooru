# File Storage Persistence Explanation

## Current Configuration: Host Directory Mount

### Production (docker-compose.yml)
```yaml
volumes:
  - /opt/shop-management/uploads:/app/uploads
```

### What Happens with Images

#### Scenario 1: Container Deleted
```bash
# 1. Upload an image
POST /api/products/123/images
# Image saved to: /opt/shop-management/uploads/products/master/image.jpg

# 2. Delete container
docker rm -f nammaooru-backend

# 3. Image still exists on host
ls /opt/shop-management/uploads/products/master/image.jpg
# ✅ File still there!

# 4. Start new container
docker-compose up -d

# 5. Image still accessible
GET https://nammaoorudelivary.in/uploads/products/master/image.jpg
# ✅ Still works!
```

#### Scenario 2: Complete Docker Cleanup
```bash
# Even if you do:
docker-compose down          # Stop containers
docker system prune -a       # Remove all images
docker volume prune          # Remove volumes

# Files are STILL there because they're on the host:
ls /opt/shop-management/uploads/
# ✅ All files intact!
```

---

## Comparison: Host Mount vs Docker Volume

### Host Mount (Current - Recommended)
```yaml
volumes:
  - /opt/shop-management/uploads:/app/uploads
```

**Pros:**
- ✅ Files persist forever (even if Docker is uninstalled)
- ✅ Easy to backup (just copy /opt/shop-management/uploads)
- ✅ Nginx can serve files directly
- ✅ Can access files outside Docker
- ✅ Easy to migrate to another server

**Cons:**
- ⚠️ Need to ensure directory permissions
- ⚠️ Need to manage disk space manually

### Docker Volume (Old - Not Recommended for uploads)
```yaml
volumes:
  uploads_data:/app/uploads

volumes:
  uploads_data:
    driver: local
```

**Pros:**
- Managed by Docker
- Automatic permissions

**Cons:**
- ❌ Nginx can't access (isolated)
- ❌ Harder to backup
- ❌ Harder to inspect files
- ❌ Lost if volume deleted
- ❌ Can't serve files directly

---

## File Locations

### In Container (Application View)
```
/app/uploads/
├── products/
│   ├── master/
│   │   └── master_123_20250113_143022_a1b2c3d4.jpg
│   └── shop/
│       └── shop_456_123_20250113_143022_e5f6g7h8.jpg
├── delivery-proof/
│   └── 789/
│       ├── photo/
│       └── signature/
└── shops/
    └── 456/
        └── shop_image.jpg
```

### On Host (Actual Storage)
```
/opt/shop-management/uploads/
├── products/
│   ├── master/
│   │   └── master_123_20250113_143022_a1b2c3d4.jpg
│   └── shop/
│       └── shop_456_123_20250113_143022_e5f6g7h8.jpg
├── delivery-proof/
│   └── 789/
│       ├── photo/
│       └── signature/
└── shops/
    └── 456/
        └── shop_image.jpg
```

**They are THE SAME FILES!** Container just sees them through mount.

---

## Nginx Serving Files

```nginx
location /uploads/ {
    alias /opt/shop-management/uploads/;  # ← Reads from HOST, not container
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```

**Flow:**
1. User requests: `https://nammaoorudelivary.in/uploads/products/master/image.jpg`
2. Nginx reads from: `/opt/shop-management/uploads/products/master/image.jpg` (HOST)
3. Serves directly (fast, no Docker involved)

---

## Backup Strategy

### Daily Backup
```bash
# Backup uploads
tar -czf /backups/uploads-$(date +%Y%m%d).tar.gz /opt/shop-management/uploads/

# Keep last 30 days
find /backups/ -name "uploads-*.tar.gz" -mtime +30 -delete
```

### Restore from Backup
```bash
# Extract to temp location
tar -xzf /backups/uploads-20250113.tar.gz -C /tmp/

# Copy to production
cp -r /tmp/opt/shop-management/uploads/* /opt/shop-management/uploads/
```

---

## Testing Persistence

Run this on your server to test:

```bash
# 1. Create a test file
echo "test" > /opt/shop-management/uploads/test.txt

# 2. Verify container can see it
docker exec nammaooru-backend ls /app/uploads/test.txt

# 3. Delete container
docker rm -f nammaooru-backend

# 4. Verify file still exists on host
cat /opt/shop-management/uploads/test.txt
# Should print: test

# 5. Start new container
docker-compose up -d

# 6. Verify new container sees the same file
docker exec nammaooru-backend cat /app/uploads/test.txt
# Should print: test

# 7. Verify nginx can serve it
curl http://localhost/uploads/test.txt
# Should print: test

# Cleanup
rm /opt/shop-management/uploads/test.txt
```

---

## Summary

✅ **Files are stored on HOST, not in container**
✅ **Files persist even if container is deleted**
✅ **Nginx serves files directly from host**
✅ **Easy to backup and restore**
✅ **Same setup as your local Windows machine**
