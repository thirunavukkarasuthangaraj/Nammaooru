# Zero Downtime Deployment Guide

This guide explains how to deploy your application with **ZERO DOWNTIME** using rolling updates.

## 🎯 Overview

**Current Problem:**
- `docker-compose up -d` stops old containers before starting new ones → **downtime**
- Frontend deployment clears `/var/www/html` before copying → **downtime**

**Solution:**
1. **Backend:** Run new container alongside old one, switch traffic, then stop old one
2. **Frontend:** Use atomic symlink swaps instead of deleting files
3. **Nginx:** Load balance between containers and retry failed requests

---

## 📋 Prerequisites

- Docker & Docker Compose installed
- Nginx installed on server
- SSH access to production server (root@65.21.4.236)

---

## 🚀 Setup (One-Time)

### 1. Update Nginx Configuration

On your **production server**, update Nginx to use upstream load balancing:

```bash
# SSH to server
ssh root@65.21.4.236

# Create upstream configuration file
touch /etc/nginx/conf.d/backend-upstream.conf

# Update nginx site configuration
sudo nano /etc/nginx/sites-available/api.nammaoorudelivary.in
```

Copy the contents from `deployment/nginx-api-zero-downtime.conf` to replace your current config.

```bash
# Test configuration
sudo nginx -t

# If OK, reload
sudo systemctl reload nginx
```

### 2. Convert /var/www/html to Symlink

This allows atomic swaps for frontend deployments:

```bash
# On production server
cd /var/www

# Backup current site
mkdir -p releases/backup_$(date +%Y%m%d)
cp -r html/* releases/backup_$(date +%Y%m%d)/

# Remove old html directory
rm -rf html

# Create releases directory structure
mkdir -p releases/$(date +%Y%m%d_%H%M%S)
cp -r releases/backup_$(date +%Y%m%d)/* releases/$(date +%Y%m%d_%H%M%S)/

# Create symlink
ln -s releases/$(date +%Y%m%d_%H%M%S) html

# Set permissions
chown -R www-data:www-data releases
chmod -R 755 releases
```

### 3. Make Deployment Scripts Executable

```bash
# On local machine
chmod +x zero-downtime-deploy.sh
chmod +x zero-downtime-frontend-deploy.sh

# Upload to server
scp zero-downtime-deploy.sh root@65.21.4.236:/opt/shop-management/
scp zero-downtime-frontend-deploy.sh root@65.21.4.236:/opt/shop-management/
```

---

## 🎬 Deployment Process

### Option 1: Automated CI/CD (Recommended)

**Simply push to main branch:**

```bash
# Bump versions
# backend/pom.xml: <version>1.0.X</version>
# frontend/package.json: "version": "1.0.X"

git add .
git commit -m "chore: Bump versions to 1.0.X"
git push
```

**GitHub Actions will automatically:**
1. ✅ Validate builds (backend + frontend)
2. ✅ Deploy backend with zero downtime (~9 minutes)
3. ✅ Deploy frontend with zero downtime (~3 minutes)
4. ✅ Run health checks and verify deployment

**Total time:** ~16 minutes with **zero downtime**

Monitor progress: https://github.com/thirunavukkarasuthangaraj/Nammaooru/actions

---

### Option 2: Manual Deployment

**On Production Server:**

```bash
ssh root@65.21.4.236
cd /opt/shop-management

# Pull latest code
git pull

# Run zero downtime deployment
./deployment-automation/scripts/zero-downtime-deploy.sh
```

**What happens:**
1. ✅ Builds new Docker image
2. ✅ Starts new container (old one still running)
3. ✅ Waits for health check to pass
4. ✅ Updates Nginx to route to new container
5. ✅ Waits 30s for connections to drain
6. ✅ Stops old container
7. ✅ Updates Nginx config

**Zero downtime!** Traffic seamlessly moves from old → new container.

---

### Frontend Deployment

**Step 1: Build locally**

```bash
# On local machine
cd frontend
ng build --configuration production
```

**Step 2: Upload to server**

```bash
# Create tarball
cd dist
tar -czf deploy.tar.gz shop-management-frontend/

# Upload
scp deploy.tar.gz root@65.21.4.236:/opt/shop-management/frontend/dist/

# Clean up
rm deploy.tar.gz
```

**Step 3: Deploy on server**

```bash
# SSH to server
ssh root@65.21.4.236
cd /opt/shop-management

# Extract new build
cd frontend/dist
tar -xzf deploy.tar.gz
rm deploy.tar.gz

# Run zero downtime deployment
cd /opt/shop-management
./zero-downtime-frontend-deploy.sh
```

**What happens:**
1. ✅ Copies new build to `/var/www/releases/TIMESTAMP`
2. ✅ Atomically swaps symlink `/var/www/html` → new release
3. ✅ Reloads Nginx
4. ✅ Keeps last 5 releases for rollback

**Zero downtime!** Symlink swap is atomic - no moment where files don't exist.

---

## 🔄 Rollback

### Backend Rollback

```bash
# List recent images
docker images | grep nammaooru-backend

# Start old image
docker run -d --name nammaooru-backend-rollback \
  --env-file .env \
  -p 8082:8080 \
  nammaooru-backend:OLD_TAG

# Wait for health check
sleep 30

# Update Nginx upstream to point to old container
# Then stop new container
```

### Frontend Rollback

```bash
# On server
cd /var/www/releases

# List available releases
ls -lth

# Get previous release
PREVIOUS=$(ls -t | head -n 2 | tail -n 1)

# Atomic swap back
ln -sfn /var/www/releases/$PREVIOUS /var/www/html

# Reload Nginx
systemctl reload nginx
```

---

## 🔍 Monitoring & Verification

### Check Backend Health

```bash
# From anywhere
curl -f https://api.nammaoorudelivary.in/actuator/health

# On server
docker ps --filter "label=com.shop.service=backend"
docker logs <container-name>
```

### Check Frontend

```bash
# HTTP headers
curl -I https://nammaoorudelivary.in

# Check symlink
ls -la /var/www/html

# View current release
readlink /var/www/html
```

### Check Nginx Upstream

```bash
# On server
cat /etc/nginx/conf.d/backend-upstream.conf
nginx -t
systemctl status nginx
```

---

## 📊 Architecture Diagram

### Production Setup (v1.0.7)

```
┌────────────────────────────────────────────────────────────┐
│  Internet Traffic (HTTPS)                                   │
│  - nammaoorudelivary.in (Frontend)                         │
│  - api.nammaoorudelivary.in (Backend API)                  │
└────────────┬───────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│  Nginx (Port 443) - SSL via Cloudflare                     │
│  ├─ Frontend: Serves static files from symlink             │
│  └─ API: Reverse proxy to dynamic backend port             │
└──────┬──────────────────────────┬──────────────────────────┘
       │                          │
       │ Backend                  │ Frontend
       ▼                          ▼
┌──────────────────┐      ┌─────────────────────────┐
│ Docker Container │      │ /var/www/html           │
│ (Spring Boot)    │      │ ↓ (symlink)             │
│                  │      │ /var/www/releases/      │
│ Port: 32787      │      │   20251118_172432/      │
│ (Dynamic)        │      │   ├─ index.html         │
│                  │      │   ├─ main.*.js          │
│ Health: ✅        │      │   └─ assets/            │
│ Version: 1.0.7   │      │                         │
└──────────────────┘      │ Old Releases (Rollback): │
                          │   20251118_163102       │
                          │   20251118_133933       │
                          └─────────────────────────┘
```

### During Zero-Downtime Deployment

```
┌────────────────────────────────────────────────────────────┐
│  Nginx - No Configuration Change Yet                       │
└──────┬────────────────────────────┬────────────────────────┘
       │                            │
       │ Old Backend                │ New Backend
       │ (Still Serving)            │ (Starting Up)
       ▼                            ▼
┌──────────────────┐        ┌──────────────────┐
│ Container 6      │        │ Container 7      │
│ Port: 32785      │        │ Port: 32787      │
│ Status: ✅ UP     │        │ Status: ⏳ Starting│
│ Traffic: 100%    │        │ Health Check...  │
└──────────────────┘        └──────────────────┘
                                    │
                                    ▼
                            ┌──────────────────┐
                            │ Health Check OK  │
                            │ ✅ Container 7    │
                            └──────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────┐
│  Nginx Config Updated (proxy_pass → port 32787)           │
│  systemctl reload nginx (no downtime)                      │
└──────┬────────────────────────────┬────────────────────────┘
       │                            │
       │ Old Backend                │ New Backend
       │ (Draining 30s)             │ (Receiving Traffic)
       ▼                            ▼
┌──────────────────┐        ┌──────────────────┐
│ Container 6      │        │ Container 7      │
│ Port: 32785      │        │ Port: 32787      │
│ Status: ⏳ Draining│        │ Status: ✅ UP     │
│ Traffic: 0%      │        │ Traffic: 100%    │
└──────────────────┘        └──────────────────┘
       │
       ▼
┌──────────────────┐
│ docker stop      │
│ Container 6      │
│ Removed ♻️        │
└──────────────────┘
```

### CI/CD Workflow (GitHub Actions)

```
┌─────────────────────────────────────────────────────────┐
│  Developer: git push to main                            │
└─────────────┬───────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────┐
│  GitHub Actions Workflow (16m 45s)                      │
├─────────────────────────────────────────────────────────┤
│  [1] Pre-Deployment Validation (3m 36s)                 │
│      ├─ Build backend (mvn clean package)              │
│      └─ Build frontend (npm run build:production)      │
│                                                         │
│  [2] Deploy Backend Zero Downtime (9m 26s)             │
│      ├─ SCP source code to server                      │
│      ├─ SSH: Run zero-downtime-deploy.sh               │
│      │   ├─ Build new Docker image                     │
│      │   ├─ Start Container 7 (old still running)      │
│      │   ├─ Wait for health check (2 min retry)        │
│      │   ├─ Update Nginx → port 32787                  │
│      │   ├─ Drain Container 6 (30s)                    │
│      │   └─ Stop Container 6                           │
│      └─ Verify: curl api.../actuator/health            │
│                                                         │
│  [3] Deploy Frontend Zero Downtime (3m 17s)            │
│      ├─ Build frontend in GitHub Actions               │
│      ├─ Package: tar -czf deploy.tar.gz                │
│      ├─ SCP to server                                  │
│      ├─ SSH: Run zero-downtime-frontend-deploy.sh      │
│      │   ├─ Extract to /var/www/releases/TIMESTAMP    │
│      │   ├─ Atomic symlink swap                        │
│      │   └─ systemctl reload nginx                     │
│      └─ Verify: curl nammaoorudelivary.in              │
│                                                         │
│  [4] Deployment Summary (11s)                          │
│      ├─ Show container status                          │
│      ├─ Show current release symlink                   │
│      └─ Report: Total Downtime = 0 seconds ✨           │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 Key Benefits

✅ **Zero Downtime:** Old version serves traffic while new one starts
✅ **Health Checks:** New version must be healthy before receiving traffic
✅ **Auto Rollback:** Script rolls back if health check fails
✅ **Easy Rollback:** Keep last 5 releases for instant rollback
✅ **Atomic Swaps:** Symlinks ensure no "file not found" errors
✅ **Proven Pattern:** Used by major platforms (Heroku, Capistrano, etc.)

---

## ⚠️ Important Notes

1. **Database Migrations:** Run migrations BEFORE deployment (backward compatible)
2. **Shared State:** Sessions/cache should be in Redis/external storage (not in-memory)
3. **File Uploads:** Shared volume ensures both containers see same files
4. **Environment Variables:** Must be identical between old/new containers
5. **Port Range:** Nginx config supports ports 8082-8084 (3 simultaneous containers max)

---

## 🐛 Troubleshooting

### Issue: New container fails health check

```bash
# Check logs
docker logs <new-container-name>

# Check health status
docker inspect <new-container-name> | grep -A 10 Health

# Manual health check
curl http://localhost:<port>/actuator/health
```

### Issue: Nginx returns 502

```bash
# Check if Nginx is pointing to correct backend port
cat /etc/nginx/sites-available/api.nammaoorudelivary.in | grep proxy_pass

# Get actual backend port
docker ps --format '{{.Names}}\t{{.Ports}}' | grep backend

# Update Nginx to correct port
BACKEND_PORT=$(docker port shop-management_backend_7 8080 | cut -d':' -f2)
sed -i "s|proxy_pass http://localhost:[0-9]*;|proxy_pass http://localhost:$BACKEND_PORT;|" /etc/nginx/sites-available/api.nammaoorudelivary.in
nginx -t && systemctl reload nginx

# Check Nginx logs
tail -f /var/log/nginx/error.log
```

### Issue: CI/CD health check timeout

**Fixed in v1.0.7:** Health check now retries 12 times (2 minutes total) instead of single 10s check.

```yaml
# .github/workflows/deploy-production-zero-downtime.yml
RETRY_COUNT=0
MAX_RETRIES=12
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  curl -f https://api.nammaoorudelivary.in/actuator/health && exit 0
  sleep 10
  RETRY_COUNT=$((RETRY_COUNT+1))
done
```

### Issue: CI/CD command timeout

**Fixed in v1.0.7:** Added explicit timeouts to SSH actions:
- Backend deployment: 15 minutes
- Frontend deployment: 10 minutes

```yaml
- name: Deploy backend with zero downtime
  uses: appleboy/ssh-action@v0.1.5
  with:
    command_timeout: 15m
```

### Issue: Frontend showing old code

**Root cause:** `frontend/src/environments/environment.prod.ts` had wrong API URL.

**Fixed in v1.0.7:**
```typescript
// WRONG (old)
apiUrl: 'https://nammaoorudelivary.in/api'

// CORRECT (v1.0.7+)
apiUrl: 'https://api.nammaoorudelivary.in/api'
```

After fix, clear browser cache or hard refresh (Ctrl+Shift+R).

### Issue: Old container won't stop

```bash
# Check active connections
netstat -an | grep :8082

# Force stop
docker stop -t 60 <container-name>
docker kill <container-name>
```

---

## 📚 Additional Resources

- [Docker Compose Docs](https://docs.docker.com/compose/)
- [Nginx Upstream Docs](http://nginx.org/en/docs/http/ngx_http_upstream_module.html)
- [Blue-Green Deployment Pattern](https://martinfowler.com/bliki/BlueGreenDeployment.html)

---

## 📝 Recent Changes (v1.0.7 - Nov 18, 2025)

### CI/CD Improvements
- ✅ Added SSH command timeouts (15m backend, 10m frontend)
- ✅ Improved health check retry logic (12 attempts over 2 minutes)
- ✅ Fixed deployment script Nginx config updates (regex-based)
- ✅ Automated deployment via GitHub Actions on push to main

### Configuration Fixes
- ✅ Fixed frontend API URL to use correct subdomain
- ✅ Updated environment.prod.ts with `api.nammaoorudelivary.in`
- ✅ Frontend v1.0.7 deployed with zero-downtime release strategy

### Deployment Stats (v1.0.7)
- **Total CI/CD time:** 16m 45s
- **Downtime:** 0 seconds
- **Backend deployment:** 9m 26s
- **Frontend deployment:** 3m 17s
- **Health checks:** Pass ✅

---

## 🎉 Summary

You now have **production-grade zero downtime deployments**!

**Before:** 30-60 seconds of downtime per deployment
**After:** 0 seconds of downtime ✨

**CI/CD Status:** https://github.com/thirunavukkarasuthangaraj/Nammaooru/actions

Happy deploying! 🚀
