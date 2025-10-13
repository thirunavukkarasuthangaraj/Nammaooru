# CORS Issue - Actual Root Cause (RESOLVED)

## Date: October 13, 2025

## The Real Problem

The duplicate CORS headers were caused by a **SEPARATE nginx configuration file** that was never checked:

### Culprit File:
`/etc/nginx/sites-available/api.nammaoorudelivary.in`

This file contained:
```nginx
location / {
    proxy_pass http://localhost:8082/;
    proxy_set_header Host $host;

    # THESE WERE THE DUPLICATE CORS HEADERS:
    add_header Access-Control-Allow-Origin "https://nammaoorudelivary.in" always;
    add_header Access-Control-Allow-Credentials "true" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Origin, Content-Type, Accept, Authorization" always;
}
```

### Why This Caused Duplicates:
1. Spring Security (`SecurityConfig.java`) adds CORS headers ✓ (CORRECT)
2. nginx (`api.nammaoorudelivary.in`) ALSO adds CORS headers ✗ (DUPLICATE)
3. Browser sees TWO `access-control-allow-origin` headers = REJECT ALL REQUESTS

## The Fix

### Step 1: Remove CORS Headers from Nginx
Edit `/etc/nginx/sites-available/api.nammaoorudelivary.in`:

```nginx
server {
    listen 80;
    server_name api.nammaoorudelivary.in;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name api.nammaoorudelivary.in;

    ssl_certificate /etc/letsencrypt/live/api.nammaoorudelivary.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.nammaoorudelivary.in/privkey.pem;

    location / {
        proxy_pass http://localhost:8082;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # NO CORS HEADERS HERE - Spring Security handles it
    }

    client_max_body_size 50M;
}
```

### Step 2: Clean Up Duplicate Nginx Configs
```bash
sudo rm /etc/nginx/sites-enabled/api-only
sudo rm /etc/nginx/sites-enabled/default
```

### Step 3: Test and Reload
```bash
sudo nginx -t
sudo systemctl reload nginx
```

### Step 4: Verify Fix
```bash
curl -I -X GET https://api.nammaoorudelivary.in/api/version \
  -H "Origin: https://nammaoorudelivary.in" | grep -i access-control
```

Should see only ONE set of headers (3 lines):
```
access-control-allow-origin: https://nammaoorudelivary.in
access-control-expose-headers: Authorization, Content-Type, X-Total-Count
access-control-allow-credentials: true
```

## Why Previous Fixes Failed

### Checked Files (But Not the Problem):
- ✓ `/opt/shop-management/nginx/nammaoorudelivary.conf` - Checked many times
- ✓ `backend/src/main/resources/application-production.yml` - Removed CORS config
- ✓ `backend/src/main/java/com/shopmanagement/config/SecurityConfig.java` - Already correct
- ✓ `backend/src/main/java/com/shopmanagement/config/WebConfig.java` - Already correct

### Missed File (The Actual Problem):
- ✗ `/etc/nginx/sites-available/api.nammaoorudelivary.in` - NEVER CHECKED until user found it

## Lesson Learned

When dealing with nginx CORS issues:

1. Check ALL nginx config files in `/etc/nginx/sites-available/`
2. List all enabled sites: `ls -l /etc/nginx/sites-enabled/`
3. Search ALL nginx configs for CORS headers: `sudo grep -R "Access-Control" /etc/nginx/`
4. Don't assume there's only one nginx config file

## Current Status

✅ **FIXED** - Only ONE set of CORS headers now sent
✅ **Verified** - curl test shows correct headers
✅ **Production** - Login should work from browser now

## Credit

**Fix discovered and implemented by: User**
The user found this after a week of troubleshooting and asking ChatGPT for help.

---
**Resolution Date:** October 13, 2025
**Status:** ✅ RESOLVED
