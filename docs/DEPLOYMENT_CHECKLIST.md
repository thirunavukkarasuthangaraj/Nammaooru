# Deployment Checklist

## Pre-Deployment (Run Once on Server)

### 1. Create Storage Directory

```bash
ssh root@65.21.4.236

# Create uploads folder
mkdir -p /opt/shop-management/uploads
chmod -R 755 /opt/shop-management/uploads

# Verify
ls -la /opt/shop-management/
```

**Expected output:**
```
drwxr-xr-x ... uploads
```

### 2. Upload Firebase Config (If Not Already Done)

```bash
# From your local machine
scp /path/to/firebase-service-account.json root@65.21.4.236:/opt/shop-management/firebase-config/

# On server, set permissions
ssh root@65.21.4.236
chmod 700 /opt/shop-management/firebase-config
chmod 600 /opt/shop-management/firebase-config/firebase-service-account.json
```

---

## Deploy

### Option 1: Trigger GitHub Actions (Recommended)

1. Commit your changes:
   ```bash
   git add docker-compose.yml nginx/nammaoorudelivary.conf
   git commit -m "Fix: Add persistent file storage for uploads"
   git push origin main
   ```

2. GitHub Actions will automatically:
   - ✅ Clone latest code
   - ✅ Copy files to `/opt/shop-management/`
   - ✅ Update nginx config
   - ✅ Rebuild containers
   - ✅ Start services

### Option 2: Manual Deployment

```bash
# SSH to server
ssh root@65.21.4.236

# Navigate to deployment directory
cd /opt/shop-management

# Pull latest code
cd shop-management-system
git pull origin main
cd ..

# Copy files
cp -r shop-management-system/backend ./
cp -r shop-management-system/frontend ./
cp shop-management-system/docker-compose.yml ./
cp -r shop-management-system/nginx ./

# Update nginx
cp nginx/nammaoorudelivary.conf /etc/nginx/sites-available/
nginx -t && systemctl reload nginx

# Rebuild and restart containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Check status
docker ps
docker logs nammaooru-backend --tail 50
docker logs nammaooru-frontend --tail 20
```

---

## Post-Deployment Verification

### 1. Check Containers Running

```bash
docker ps
```

**Expected output:**
```
CONTAINER ID   IMAGE                                  STATUS          PORTS
xxxxx          shop-management-system-frontend        Up 2 minutes    0.0.0.0:8080->80/tcp
xxxxx          shop-management-system-backend         Up 2 minutes    0.0.0.0:8082->8080/tcp
```

### 2. Check Backend Health

```bash
curl http://localhost:8082/actuator/health
```

**Expected output:**
```json
{"status":"UP"}
```

### 3. Check Uploads Directory Mount

```bash
# Check inside container
docker exec nammaooru-backend ls -la /app/uploads/

# Should show empty directory (or existing files)
```

### 4. Test File Upload

```bash
# Create test file
echo "test upload" > /opt/shop-management/uploads/test.txt

# Check backend can see it
docker exec nammaooru-backend cat /app/uploads/test.txt

# Check nginx can serve it
curl http://localhost/uploads/test.txt

# Clean up
rm /opt/shop-management/uploads/test.txt
```

### 5. Check Application URLs

```bash
# Frontend
curl -I https://nammaoorudelivary.in
# Expected: 200 OK

# Backend API
curl https://nammaoorudelivary.in/api/version
# Expected: JSON with version info

# Upload endpoint (after uploading real image)
curl -I https://nammaoorudelivary.in/uploads/products/master/xxx.jpg
# Expected: 200 OK
```

---

## Image Upload Flow (How It Works)

### Upload Process:

```
1. User uploads image via mobile app/web
   ↓
2. Angular sends POST to: https://nammaoorudelivary.in/api/products/upload
   ↓
3. Nginx forwards to: http://localhost:8082/api/products/upload
   ↓
4. Spring Boot backend receives file
   ↓
5. Backend saves to: /app/uploads/products/master/xxx.jpg
   ↓ (mounted to)
6. File written to: /opt/shop-management/uploads/products/master/xxx.jpg
   ↓
7. Backend returns URL: /uploads/products/master/xxx.jpg
   ↓
8. Frontend displays image from: https://nammaoorudelivary.in/uploads/products/master/xxx.jpg
   ↓
9. Nginx serves directly from: /opt/shop-management/uploads/products/master/xxx.jpg
```

### File Locations:

| Location | Path | Accessible By |
|----------|------|---------------|
| **Physical Storage** | `/opt/shop-management/uploads/` | Server, Nginx, Docker (mounted) |
| **Backend View** | `/app/uploads/` | Backend container only |
| **Public URL** | `https://nammaoorudelivary.in/uploads/` | Anyone (read-only) |

---

## Storage Verification Commands

```bash
# Check disk usage
df -h /opt/shop-management/uploads

# Check number of uploaded files
find /opt/shop-management/uploads -type f | wc -l

# Check recent uploads
ls -lhtr /opt/shop-management/uploads/products/master/ | tail -10

# Check total upload size
du -sh /opt/shop-management/uploads
du -h /opt/shop-management/uploads/* | sort -h
```

---

## Rollback (If Something Goes Wrong)

```bash
# Rollback to previous git commit
cd /opt/shop-management/shop-management-system
git log --oneline -5
git reset --hard <previous-commit-hash>

# Redeploy
cd /opt/shop-management
cp shop-management-system/docker-compose.yml ./
docker-compose down
docker-compose up -d
```

---

## Common Issues & Solutions

### Issue: "Cannot create directory"

```bash
# Fix permissions
sudo chmod -R 755 /opt/shop-management/uploads
sudo chown -R 1000:1000 /opt/shop-management/uploads
```

### Issue: "Upload directory not writable"

```bash
# Check who runs the container
docker exec nammaooru-backend whoami

# Adjust permissions accordingly
sudo chmod 777 /opt/shop-management/uploads
```

### Issue: Nginx returns 403 Forbidden

```bash
# Check nginx can read uploads
sudo -u www-data ls /opt/shop-management/uploads

# Fix permissions
sudo chmod -R 755 /opt/shop-management/uploads
```

### Issue: Images not loading after deployment

```bash
# 1. Check file exists on server
ls -la /opt/shop-management/uploads/products/master/

# 2. Check nginx config
nginx -t
cat /etc/nginx/sites-available/nammaoorudelivary.conf | grep uploads

# 3. Check backend environment
docker exec nammaooru-backend env | grep UPLOAD

# 4. Check mount
docker inspect nammaooru-backend | grep -A 5 Mounts
```

---

## Monitoring

### Check Logs

```bash
# Backend logs
docker logs nammaooru-backend --tail 100 -f

# Frontend logs
docker logs nammaooru-frontend --tail 50 -f

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### Monitor Uploads

```bash
# Watch uploads directory in real-time
watch -n 5 'ls -lhtr /opt/shop-management/uploads/products/master/ | tail -10'

# Monitor disk space
watch -n 60 'df -h /opt/shop-management/uploads'
```

---

## Success Criteria

After deployment, verify ALL of these:

- [ ] Containers are running: `docker ps` shows 2 containers
- [ ] Backend health check: `curl http://localhost:8082/actuator/health` returns `UP`
- [ ] Frontend accessible: `curl https://nammaoorudelivary.in` returns 200
- [ ] Uploads directory exists: `ls /opt/shop-management/uploads`
- [ ] Container can write: `docker exec nammaooru-backend touch /app/uploads/test && rm /app/uploads/test`
- [ ] Nginx can serve uploads: `curl https://nammaoorudelivary.in/uploads/test.txt` (after creating test file)
- [ ] Firebase config exists: `ls /opt/shop-management/firebase-config/firebase-service-account.json`
- [ ] No errors in logs: `docker logs nammaooru-backend | grep -i error`

---

## 🎉 Ready to Deploy!

Your files will be stored at: **`/opt/shop-management/uploads/`**

They will **persist** through:
- Container restarts
- Image rebuilds
- Server reboots
- Code deployments

They will **NOT** be lost unless you manually delete the folder!
