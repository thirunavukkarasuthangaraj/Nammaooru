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

### Backend Deployment

**On Production Server:**

```bash
ssh root@65.21.4.236
cd /opt/shop-management

# Pull latest code
git pull

# Run zero downtime deployment
./zero-downtime-deploy.sh
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

```
┌─────────────────────────────────────────────┐
│  Internet Traffic                            │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│  Nginx (Port 443)                            │
│  - SSL Termination                           │
│  - Load Balancing                            │
│  - Auto Retry on Failure                     │
└──────┬──────────────────┬───────────────────┘
       │                  │
       │ Backend          │ Frontend
       ▼                  ▼
┌──────────────┐    ┌──────────────┐
│ Container 1  │    │ /var/www/html│
│ (New)        │    │ → symlink    │
│ Port: 8083   │    │   ↓          │
│ Status: ✅    │    │ releases/    │
└──────────────┘    │ 20250118...  │
       │            └──────────────┘
       │ Draining
       ▼
┌──────────────┐
│ Container 2  │
│ (Old)        │
│ Port: 8082   │
│ Status: ⏳    │
└──────────────┘
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
# Check upstream config
cat /etc/nginx/conf.d/backend-upstream.conf

# Check Nginx logs
tail -f /var/log/nginx/error.log

# Verify containers are running
docker ps
```

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

## 🎉 Summary

You now have **production-grade zero downtime deployments**!

**Before:** 30-60 seconds of downtime per deployment
**After:** 0 seconds of downtime ✨

Happy deploying! 🚀
