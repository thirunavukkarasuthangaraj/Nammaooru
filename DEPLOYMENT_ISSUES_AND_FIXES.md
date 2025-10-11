# Deployment Issues and Fixes - Shop Management System

**Date:** October 11, 2025
**Environment:** Production (nammaoorudelivary.in)
**Server:** Hetzner Cloud (65.21.4.236)

---

## Table of Contents
1. [CORS Errors](#1-cors-errors)
2. [Build Failures](#2-build-failures)
3. [SSL Certificate Issues](#3-ssl-certificate-issues)
4. [Image Loading Issues](#4-image-loading-issues)
5. [Connection Refused Errors](#5-connection-refused-errors)
6. [Redirect Loop Issues](#6-redirect-loop-issues)
7. [Final Architecture](#7-final-architecture)

---

## 1. CORS Errors

### Problem
```
Cross-Origin Request Blocked
net::ERR_CONNECTION_REFUSED
```

**Root Cause:**
- Backend CORS configuration was not allowing credentials
- `allowCredentials` was set to `false`
- Origin patterns were not properly configured for localhost and production domains

### Solution

**File:** `backend/src/main/java/com/shopmanagement/config/SecurityConfig.java`

```java
// BEFORE (Broken)
configuration.setAllowCredentials(false);
configuration.setAllowedOrigins(Arrays.asList("http://localhost"));

// AFTER (Fixed)
configuration.setAllowCredentials(true);
configuration.setAllowedOriginPatterns(Arrays.asList(
    "https://nammaoorudelivary.in",
    "https://www.nammaoorudelivary.in",
    "http://localhost:*",
    "http://localhost"
));
```

**Files Changed:**
- `backend/src/main/java/com/shopmanagement/config/SecurityConfig.java` (lines 117-128)

**Commit:** `da484e4` - "Fix product image display issues and improve image loading"

---

## 2. Build Failures

### Problem 1: Backend Container Not Starting After CI/CD

**Error:**
```
Backend container missing from docker ps
Only frontend container running
```

**Root Cause:**
- CI/CD workflow completed successfully but backend container didn't start
- Port conflicts with nginx on port 80
- Docker compose configuration needed adjustment

**Solution:**
```bash
# Manual intervention required
cd /opt/shop-management
docker compose up -d backend
```

### Problem 2: Nginx Build Failure - Port 80 Conflict

**Error:**
```
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
nginx.service: Failed with result 'exit-code'
```

**Root Cause:**
- Frontend Docker container was directly binding to port 80
- Nginx needed port 80 for SSL termination
- Incorrect architecture: containers should not expose port 80 directly

**Solution:**

**File:** `docker-compose.yml`

```yaml
# BEFORE (Broken)
frontend:
  ports:
    - "80:80"  # ❌ Blocking nginx

# AFTER (Fixed)
frontend:
  ports:
    - "8080:80"  # ✅ Internal port only
```

**Commands Executed:**
```bash
docker compose down
sed -i 's/"80:80"/"8080:80"/' docker-compose.yml
systemctl start nginx
docker compose up -d
```

---

## 3. SSL Certificate Issues

### Problem: API Subdomain Without SSL

**Error:**
```
curl: (7) Failed to connect to api.nammaoorudelivary.in port 443
Connection refused
```

**Root Cause:**
- API subdomain `api.nammaoorudelivary.in` was not configured in nginx
- No SSL certificates for API subdomain
- Frontend trying to call HTTPS API but nginx not listening

### Solution

#### Step 1: Create Nginx Configuration

**File:** `/etc/nginx/sites-available/api.nammaoorudelivary.in`

```nginx
server {
    listen 80;
    server_name api.nammaoorudelivary.in;

    location / {
        proxy_pass http://localhost:8082;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    client_max_body_size 50M;
}
```

#### Step 2: Enable Site
```bash
ln -sf /etc/nginx/sites-available/api.nammaoorudelivary.in /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

#### Step 3: Get SSL Certificate
```bash
certbot --nginx -d nammaoorudelivary.in \
  -d www.nammaoorudelivary.in \
  -d api.nammaoorudelivary.in \
  --non-interactive \
  --agree-tos \
  --email noreplaynammaoorudelivery@gmail.com \
  --expand
```

**Result:**
```
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/api.nammaoorudelivary.in/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/api.nammaoorudelivary.in/privkey.pem
This certificate expires on 2026-01-09.
```

---

## 4. Image Loading Issues

### Problem: Product Images Not Displaying

**Errors:**
```
http://localhost:8082/uploads/products/master/master_101_*.png - 404 Not Found
Image paths in database: /opt/shop-management/uploads/products/...
```

**Root Causes:**

1. **JPA Lazy Loading** - Master product images not fetched with products
2. **Wrong Environment Variable** - `PRODUCT_IMAGES_PATH` not set correctly
3. **Database Path Issues** - Old images stored with absolute server paths

### Solutions

#### Fix 1: Eager Load Images

**File:** `backend/src/main/java/com/shopmanagement/product/service/ShopProductService.java`

```java
// Added to getAvailableMasterProducts() method (lines 417-440)
Page<MasterProduct> masterProducts = masterProductRepository.findAll(spec, pageable);

// Fetch images for all products to avoid lazy loading issues
List<Long> productIds = masterProducts.getContent().stream()
        .map(MasterProduct::getId)
        .toList();

if (!productIds.isEmpty()) {
    List<MasterProduct> productsWithImages =
        masterProductRepository.findAllWithImages(productIds);

    java.util.Map<Long, MasterProduct> imageMap = productsWithImages.stream()
            .collect(java.util.stream.Collectors.toMap(
                MasterProduct::getId, p -> p));

    masterProducts.getContent().forEach(product -> {
        MasterProduct productWithImages = imageMap.get(product.getId());
        if (productWithImages != null && productWithImages.getImages() != null) {
            product.setImages(productWithImages.getImages());
        }
    });
}
```

#### Fix 2: Set Correct Environment Variable

**File:** `docker-compose.yml` (Local)

```yaml
backend:
  environment:
    - PRODUCT_IMAGES_PATH=products  # ✅ Correct
    # NOT: /opt/shop-management/uploads/products ❌
```

**File:** `docker-compose.yml` (Production) - Already had correct value

```yaml
backend:
  environment:
    - PRODUCT_IMAGES_PATH=products
```

#### Fix 3: Database Path Correction Endpoint

**File:** `backend/src/main/java/com/shopmanagement/util/ImagePathFixController.java` (NEW)

```java
@RestController
@RequestMapping("/api/admin/fix-images")
public class ImagePathFixController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @PostMapping
    public Map<String, Object> fixImagePaths() {
        Map<String, Object> result = new HashMap<>();

        // Fix shop product images with /opt/ paths
        int shopOptFixed = jdbcTemplate.update(
            "UPDATE shop_product_images " +
            "SET image_url = REPLACE(image_url, '/opt/shop-management/uploads/', '/uploads/') " +
            "WHERE image_url LIKE '/opt/shop-management/uploads/%'"
        );

        // Fix shop product images with /app/ paths
        int shopAppFixed = jdbcTemplate.update(
            "UPDATE shop_product_images " +
            "SET image_url = REPLACE(image_url, '/app/uploads/', '/uploads/') " +
            "WHERE image_url LIKE '/app/uploads/%'"
        );

        // Fix master product images
        int masterOptFixed = jdbcTemplate.update(
            "UPDATE master_product_images " +
            "SET image_url = REPLACE(image_url, '/opt/shop-management/uploads/', '/uploads/') " +
            "WHERE image_url LIKE '/opt/shop-management/uploads/%'"
        );

        int masterAppFixed = jdbcTemplate.update(
            "UPDATE master_product_images " +
            "SET image_url = REPLACE(image_url, '/app/uploads/', '/uploads/') " +
            "WHERE image_url LIKE '/app/uploads/%'"
        );

        result.put("shopOptFixed", shopOptFixed);
        result.put("shopAppFixed", shopAppFixed);
        result.put("masterOptFixed", masterOptFixed);
        result.put("masterAppFixed", masterAppFixed);
        result.put("totalFixed", shopOptFixed + shopAppFixed + masterOptFixed + masterAppFixed);

        return result;
    }
}
```

**Usage:**
```bash
curl -X POST http://localhost:8080/api/admin/fix-images
```

---

## 5. Connection Refused Errors

### Problem: Login Failing with ERR_CONNECTION_REFUSED

**Error:**
```
POST https://api.nammaoorudelivary.in/api/auth/login
net::ERR_CONNECTION_REFUSED
```

**Root Cause:**
- Backend container not running after CI/CD deployment
- API subdomain not configured in nginx
- Port 443 not listening for api.nammaoorudelivary.in

### Solution

1. **Start Backend Container**
```bash
docker compose up -d backend
```

2. **Configure API Subdomain** (See Section 3 - SSL Certificate Issues)

3. **Verify Containers Running**
```bash
docker ps
# Should show:
# - nammaooru-backend (port 8082)
# - nammaooru-frontend (port 8080)
```

---

## 6. Redirect Loop Issues

### Problem: ERR_TOO_MANY_REDIRECTS

**Error:**
```
ERR_TOO_MANY_REDIRECTS
This page isn't working
nammaoorudelivary.in redirected you too many times.
```

**Root Cause:**
- **Cloudflare SSL Mode:** Set to "Flexible" instead of "Full"
- With Flexible SSL:
  1. Browser → Cloudflare (HTTPS)
  2. Cloudflare → Nginx (HTTP)
  3. Nginx → Redirect to HTTPS
  4. Loop back to step 1
- Nginx `proxy_set_header X-Forwarded-Proto $scheme` was sending "http" instead of "https"

### Solutions Attempted

#### Attempt 1: Fix Nginx Proxy Headers (PARTIAL FIX)

**File:** `/etc/nginx/sites-enabled/nammaoorudelivary.in`

```nginx
location / {
    proxy_pass http://localhost:8080;
    proxy_http_version 1.1;

    # FIXED: Force HTTPS in forwarded proto
    proxy_set_header X-Forwarded-Proto https;  # Was: $scheme
    proxy_set_header X-Forwarded-Host $host;

    proxy_redirect off;  # Prevent proxy-induced redirects
    proxy_buffering off;
}
```

**Commands:**
```bash
sed -i 's/proxy_set_header X-Forwarded-Proto \$scheme;/proxy_set_header X-Forwarded-Proto https;/' \
  /etc/nginx/sites-enabled/nammaoorudelivary.in
nginx -t
systemctl reload nginx
```

### REQUIRED FIX: Cloudflare SSL Settings

**⚠️ THIS IS THE REAL FIX NEEDED:**

1. **Login to Cloudflare Dashboard**
   - Go to: https://dash.cloudflare.com/
   - Select domain: `nammaoorudelivary.in`

2. **Navigate to SSL/TLS Settings**
   - Click "SSL/TLS" in the left sidebar
   - Click "Overview" tab

3. **Change SSL Mode**
   ```
   Current: Flexible ❌
   Change to: Full ✅ or Full (strict) ✅
   ```

4. **Why Each Mode?**
   - **Flexible:** Cloudflare↔Server uses HTTP (CAUSES REDIRECT LOOP) ❌
   - **Full:** Cloudflare↔Server uses HTTPS (self-signed OK) ✅
   - **Full (strict):** Cloudflare↔Server uses HTTPS (valid cert required) ✅ RECOMMENDED

**After Changing:**
- Wait 1-2 minutes for Cloudflare to update
- Clear browser cache: `Ctrl + Shift + Delete`
- Test site: https://nammaoorudelivary.in

---

## 7. Final Architecture

### Before (Broken)
```
Internet → Cloudflare (HTTPS) → Nginx ❌ NOT RUNNING
                                  ↓
Frontend Container (Port 80) ← Blocking nginx
Backend Container ❌ NOT RUNNING
```

### After (Fixed)
```
Internet → Cloudflare (HTTPS) → Nginx (Port 80/443)
                                  ├─ nammaoorudelivary.in → Frontend (Port 8080)
                                  └─ api.nammaoorudelivary.in → Backend (Port 8082)

Containers:
- nammaooru-frontend: localhost:8080 (internal)
- nammaooru-backend: localhost:8082 (internal)
```

### Port Mapping

| Service | Internal Port | External Port | Protocol |
|---------|--------------|---------------|----------|
| Nginx | - | 80 | HTTP → HTTPS redirect |
| Nginx | - | 443 | HTTPS (SSL termination) |
| Frontend Container | 80 | 8080 | HTTP (internal) |
| Backend Container | 8080 | 8082 | HTTP (internal) |

### SSL Certificates

**Domains Covered:**
- nammaoorudelivary.in ✅
- www.nammaoorudelivary.in ✅
- api.nammaoorudelivary.in ✅

**Certificate Location:**
- `/etc/letsencrypt/live/api.nammaoorudelivary.in/fullchain.pem`
- `/etc/letsencrypt/live/api.nammaoorudelivary.in/privkey.pem`

**Expiry:** January 9, 2026
**Auto-renewal:** Configured via certbot

---

## Summary of All Fixes

### Files Modified
1. ✅ `backend/src/main/java/com/shopmanagement/config/SecurityConfig.java` - CORS fix
2. ✅ `backend/src/main/java/com/shopmanagement/product/service/ShopProductService.java` - Eager image loading
3. ✅ `backend/src/main/java/com/shopmanagement/util/ImagePathFixController.java` - NEW file for DB path fixes
4. ✅ `docker-compose.yml` - Frontend port changed from 80 to 8080
5. ✅ `/etc/nginx/sites-available/nammaoorudelivary.in` - Main domain config
6. ✅ `/etc/nginx/sites-available/api.nammaoorudelivary.in` - API subdomain config

### Deployment Steps Executed

1. ✅ Git commit and push changes to main branch
2. ✅ CI/CD automatically deployed via GitHub Actions
3. ✅ Manual backend container start (CI/CD didn't start it)
4. ✅ Fixed docker-compose.yml port mapping
5. ✅ Stopped containers to free port 80
6. ✅ Created nginx configurations for both domains
7. ✅ Started nginx service
8. ✅ Started Docker containers
9. ✅ Obtained SSL certificates with certbot
10. ✅ Fixed nginx proxy headers to prevent redirect loops
11. ⚠️ **PENDING:** Change Cloudflare SSL mode to "Full"

### Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| CI/CD | ✅ Working | GitHub Actions deploys on push to main |
| Backend Container | ✅ Running | Port 8082, Healthy |
| Frontend Container | ✅ Running | Port 8080, Healthy |
| Nginx | ✅ Running | Port 80/443, SSL configured |
| SSL Certificates | ✅ Valid | Expires Jan 9, 2026 |
| CORS | ✅ Fixed | Backend configuration updated |
| Image Loading | ✅ Fixed | Eager loading + env vars |
| API Endpoint | ✅ Working | https://api.nammaoorudelivary.in/api/version |
| **Main Website** | ⚠️ **REDIRECT LOOP** | **Needs Cloudflare SSL mode change** |

---

## How to Fix Future Issues

### If Backend Stops
```bash
ssh root@65.21.4.236
cd /opt/shop-management
docker compose restart backend
docker logs nammaooru-backend --tail 50
```

### If Frontend Stops
```bash
docker compose restart frontend
docker logs nammaooru-frontend --tail 50
```

### If Nginx Fails
```bash
nginx -t  # Test configuration
systemctl status nginx
systemctl restart nginx
journalctl -xeu nginx.service --no-pager | tail -50
```

### If SSL Certificate Expires
```bash
certbot renew
systemctl reload nginx
```

### To Deploy New Changes
```bash
# Just push to main branch
git add .
git commit -m "Your changes"
git push origin main

# CI/CD will automatically:
# 1. Pull latest code
# 2. Rebuild containers
# 3. Restart services
```

### To Fix Redirect Loops
1. Check Cloudflare SSL mode (should be "Full" not "Flexible")
2. Clear browser cache
3. Check nginx logs: `tail -50 /var/log/nginx/error.log`
4. Verify X-Forwarded-Proto header is set to "https"

---

## Monitoring Commands

### Check All Services
```bash
# Containers
docker ps

# Nginx
systemctl status nginx
curl -I https://nammaoorudelivary.in

# Backend health
curl https://api.nammaoorudelivary.in/actuator/health

# SSL expiry
certbot certificates
```

### View Logs
```bash
# Backend logs
docker logs nammaooru-backend --tail 100 -f

# Frontend logs
docker logs nammaooru-frontend --tail 100 -f

# Nginx access log
tail -f /var/log/nginx/access.log

# Nginx error log
tail -f /var/log/nginx/error.log
```

---

## Contact & Support

**Repository:** https://github.com/thirunavukkarasuthangaraj/Nammaooru
**Server:** Hetzner Cloud (65.21.4.236)
**SSL Email:** noreplaynammaoorudelivery@gmail.com

**⚠️ CRITICAL: To fix the redirect loop, change Cloudflare SSL mode to "Full" immediately!**
