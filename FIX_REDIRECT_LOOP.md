# URGENT: Fix ERR_TOO_MANY_REDIRECTS

## Problem
Your website shows: **ERR_TOO_MANY_REDIRECTS**

## Root Cause
Cloudflare SSL mode is set to "Flexible" which creates a redirect loop:
1. Browser → Cloudflare (HTTPS)
2. Cloudflare → Your Server (HTTP)
3. Your Nginx → Redirects back to HTTPS
4. **LOOP REPEATS FOREVER** ♻️

## The Fix (5 Minutes)

### Step 1: Login to Cloudflare
Go to: **https://dash.cloudflare.com/**

### Step 2: Select Your Domain
Click on: **nammaoorudelivary.in**

### Step 3: Go to SSL Settings
- Click **"SSL/TLS"** in the left sidebar
- Click **"Overview"** tab

### Step 4: Change SSL Mode
Change from:
```
⚠️ Flexible (causes redirect loop)
```

To:
```
✅ Full (recommended)
```

**What each mode does:**
- **Flexible:** Cloudflare uses HTTPS, but talks to your server with HTTP ❌ CAUSES LOOP
- **Full:** Cloudflare uses HTTPS to talk to your server ✅ WORKS (self-signed certs OK)
- **Full (strict):** Same as Full but requires valid SSL cert ✅ BEST (we have valid certs)

### Step 5: Wait & Test
1. Wait **1-2 minutes** for Cloudflare to apply changes
2. **Clear your browser cache:**
   - Chrome/Edge: Press `Ctrl + Shift + Delete`
   - Select "Cached images and files"
   - Click "Clear data"
3. Go to: **https://nammaoorudelivary.in**
4. Site should now load! ✅

---

## If Still Not Working After Cloudflare Fix

### Option A: Disable Cloudflare Temporarily

1. In Cloudflare, go to your domain
2. Click "Overview" tab
3. Scroll down to "Advanced Actions"
4. Click "Pause Cloudflare on Site"
5. Wait 2 minutes
6. Test site

### Option B: Check DNS Records

Make sure DNS is pointing correctly:
```
A Record:
nammaoorudelivary.in → 65.21.4.236 (Proxied: ON)
www.nammaoorudelivary.in → 65.21.4.236 (Proxied: ON)
api.nammaoorudelivary.in → 65.21.4.236 (Proxied: ON)
```

---

## Screenshot Guide

### Where to Find SSL Settings:

```
Cloudflare Dashboard
  ↓
[Your Domain: nammaoorudelivary.in]
  ↓
Left Sidebar → SSL/TLS
  ↓
Overview Tab
  ↓
"SSL/TLS encryption mode"
  ↓
Select: ● Full
```

---

## Verification

After fixing, run these tests:

### Test 1: Check HTTP to HTTPS Redirect
```bash
curl -I http://nammaoorudelivary.in
# Should show: HTTP/1.1 301 Moved Permanently
# Location: https://nammaoorudelivary.in
```

### Test 2: Check HTTPS Works
```bash
curl -I https://nammaoorudelivary.in
# Should show: HTTP/2 200
```

### Test 3: Check API
```bash
curl https://api.nammaoorudelivary.in/api/version
# Should return JSON with version info
```

---

## Why This Happened

Your server **IS CORRECTLY CONFIGURED** with:
- ✅ Valid SSL certificates (Let's Encrypt)
- ✅ Nginx properly configured
- ✅ Backend and Frontend running
- ✅ CORS fixed
- ✅ All containers healthy

**BUT** Cloudflare's "Flexible SSL" mode breaks the chain by using HTTP between Cloudflare and your server, causing nginx to redirect back to HTTPS infinitely.

---

## Summary

**Quick Fix:**
1. Cloudflare Dashboard
2. SSL/TLS → Overview
3. Change to "Full"
4. Wait 2 minutes
5. Clear browser cache
6. ✅ Done!

**Questions?** Check the full documentation in `DEPLOYMENT_ISSUES_AND_FIXES.md`
