# Deployment Troubleshooting Guide

## Common Issues and Solutions

This document covers the major deployment issues encountered and their solutions for the Shop Management System.

### Issue 1: Docker Build Failures (Local)

**Problem**: Frontend Docker build failing with "COPY failed: no source files found"
**Root Cause**: `.dockerignore` was excluding the `dist/` folder needed for Docker builds

**Solution**:
```bash
# Edit frontend/.dockerignore
# Comment out the dist/ exclusion:
# dist/ -> # dist/
```

**Files Modified**: `frontend/.dockerignore`

---

### Issue 2: Backend Container Restart Loop

**Problem**: Backend container continuously restarting, never becoming healthy
**Root Cause**: Duplicate YAML keys in Spring configuration file

**Error Log**:
```
Duplicate key: spring
```

**Solution**:
```bash
# Fix application-production.yml
# Merge duplicate 'spring:' sections into one
# Add mail health check disable: management.health.mail.enabled: false
```

**Files Modified**: `backend/src/main/resources/application-production.yml`

---

### Issue 3: Port Mapping Confusion

**Problem**: Backend health checks failing, wrong port exposure
**Root Cause**: Port mapping mismatch (8082:8082 vs 8082:8080)

**Solution**:
```yaml
# In docker-compose.yml
ports:
  - "8082:8080"  # External:Internal
# Backend runs on internal port 8080, exposed as 8082
```

**Files Modified**: `docker-compose.yml`

---

### Issue 4: CORS Errors

**Problem**: Frontend unable to connect to API due to CORS restrictions
**Root Cause**: Missing or incorrect CORS configuration

**Solution**:
1. Created comprehensive CORS filter in Spring Boot
2. Removed duplicate bean definitions to avoid conflicts

**Files Modified**: 
- `backend/src/main/java/com/shopmanagement/config/CorsConfig.java`
- Removed duplicate `corsConfigurationSource` beans

---

### Issue 5: Nginx vs Container Port Conflicts

**Problem**: Both nginx and frontend container trying to use port 80, resulting in 502 errors

**Symptoms**:
- Frontend container running on port 80
- Nginx also trying to serve on port 80
- API calls getting 502 Bad Gateway

**Root Cause**: Nginx configuration pointing to wrong ports and IPv6 connection issues

**Solution Steps**:

1. **Stop nginx temporarily**:
   ```bash
   systemctl stop nginx
   ```

2. **Fix DNS routing**: Change `api.nammaoorudelivary.in` in Cloudflare from "Proxied" to "DNS only"

3. **Create proper nginx config** for API subdomain only:
   ```nginx
   # Main domain - let container handle directly
   # API subdomain - nginx SSL proxy
   server {
       listen 443 ssl http2;
       server_name api.nammaoorudelivary.in;
       
       ssl_certificate /etc/letsencrypt/live/api.nammaoorudelivary.in/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/api.nammaoorudelivary.in/privkey.pem;
       
       location / {
           proxy_pass http://127.0.0.1:8082;  # Force IPv4
           proxy_http_version 1.1;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
           
           # CORS headers
           add_header 'Access-Control-Allow-Origin' "$http_origin" always;
           add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
           add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;
           add_header 'Access-Control-Allow-Credentials' 'true' always;
       }
   }
   ```

4. **Start nginx back**:
   ```bash
   systemctl start nginx
   ```

**Key Points**:
- Use `127.0.0.1` instead of `localhost` to force IPv4
- Frontend container handles port 80 directly
- Nginx only handles API subdomain HTTPS

---

### Issue 6: Cloudflare DNS Configuration

**Problem**: API subdomain returning 502 errors even with correct nginx config
**Root Cause**: Cloudflare proxy intercepting requests instead of direct DNS resolution

**Solution**:
1. In Cloudflare DNS settings, find `api.nammaoorudelivary.in` record
2. Change from "Proxied" (orange cloud) to "DNS only" (gray cloud)
3. Wait for DNS propagation (1-5 minutes)

**Verification**:
```bash
nslookup api.nammaoorudelivary.in
# Should return your server IP directly, not Cloudflare IPs
```

---

## Final Working Architecture

```
Internet
│
├── https://nammaoorudelivary.in → Frontend Container (port 80)
│
└── https://api.nammaoorudelivary.in → Nginx SSL Proxy → Backend Container (port 8082)
```

### Container Status (Working):
```
CONTAINER ID   IMAGE                      PORTS                                 NAMES
73456177195c   shop-management_frontend   0.0.0.0:80->80/tcp                    nammaooru-frontend
4fb8edbc6001   shop-management_backend    0.0.0.0:8082->8080/tcp                nammaooru-backend
```

### Services:
- **Frontend**: Direct container access on port 80
- **Backend**: Container on port 8082, proxied through nginx for SSL on API subdomain
- **Database**: External PostgreSQL (not in Docker)

---

## CI/CD Deployment Checklist

Before running CI/CD pipeline, ensure:

1. ✅ All containers are healthy
2. ✅ Frontend accessible on main domain
3. ✅ API accessible on API subdomain with HTTPS
4. ✅ Nginx configured correctly (if using API subdomain)
5. ✅ DNS settings correct in Cloudflare
6. ✅ No port conflicts

## Testing Commands

```bash
# Test containers
docker ps

# Test frontend
curl -I https://nammaoorudelivary.in

# Test API
curl -X POST https://api.nammaoorudelivary.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"superadmin","password":"password"}'

# Test nginx status
systemctl status nginx

# Check DNS resolution
nslookup api.nammaoorudelivary.in
```

---

## Key Lessons Learned

1. **Keep it simple**: Don't over-engineer nginx configs when containers work fine directly
2. **IPv6 issues**: Always use `127.0.0.1` instead of `localhost` in nginx configs
3. **DNS matters**: Cloudflare proxy can interfere with direct server access
4. **Port conflicts**: Check what's actually running on each port before configuring
5. **Health checks**: Ensure all health check endpoints are accessible and working
6. **CORS**: Configure CORS at application level, not just reverse proxy level

---

*Last updated: 2025-08-30*
*Working deployment confirmed with superadmin/password login successful*