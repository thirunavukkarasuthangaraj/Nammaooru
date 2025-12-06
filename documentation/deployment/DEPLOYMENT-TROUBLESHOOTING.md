# Deployment Troubleshooting Guide

## Common Issues and Solutions

This document covers the major deployment issues encountered and their solutions for the Thiru Software System.

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

### Issue 7: Database Schema Mismatch - Missing Columns

**Problem**: Backend container crashes with "Schema-validation: missing column [email_otp] in table [customers]"
**Root Cause**: Database schema doesn't match Entity classes after code changes

**Error Log**:
```
Caused by: org.hibernate.tool.schema.spi.SchemaManagementException: 
Schema-validation: missing column [email_otp] in table [customers]
```

**Solution**:
```bash
# Access PostgreSQL as postgres user
sudo -u postgres psql -d shop_management_db

# Add missing columns
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS email_otp VARCHAR(6),
ADD COLUMN IF NOT EXISTS email_otp_expiry TIMESTAMP,
ADD COLUMN IF NOT EXISTS is_email_otp_verified BOOLEAN DEFAULT FALSE;

\q

# Restart backend
docker restart nammaooru-backend
```

**Alternative Solution** (if database changes not needed):
```bash
# Rebuild with latest code that removed the fields
cd /opt/shop-management
git pull
docker-compose down
docker-compose build --no-cache backend  # --no-cache is CRUCIAL
docker-compose up -d
```

**Key Lesson**: Always check `docker logs` when backend fails - CORS errors often mask the real issue (backend not running)

---

### Issue 8: CORS Nightmare - The 50-Hour Debugging Marathon

**Problem**: Frontend works locally but fails in production with persistent CORS errors
- Login API works (200 OK)
- All authenticated APIs fail with CORS errors
- Command-line API tests work perfectly
- Browser requests consistently fail

**Root Cause**: **MULTIPLE DUPLICATE CORS HEADERS** from different sources
1. 23 controllers had `@CrossOrigin` annotations
2. `WebConfig.java` had `addCorsMappings()` method
3. `SimpleSecurityConfig.java` had CORS configuration
4. Nginx was adding CORS headers
= **4 different sources adding CORS headers = Browser rejection**

**Why Local Worked vs Production Failed**:
- **Local**: Browser → Spring Boot directly (port 8082) - Single CORS source
- **Production**: Browser → Nginx → Spring Boot - Multiple CORS sources creating duplicates

**Error Symptoms**:
```javascript
// Browser Console Errors
Access to XMLHttpRequest at 'https://api.nammaoorudelivary.in/api/dashboard' 
from origin 'https://nammaoorudelivary.in' has been blocked by CORS policy
```

**Diagnosis Commands**:
```bash
# Test for duplicate headers
curl -X OPTIONS https://api.nammaoorudelivary.in/api/shops \
  -H "Origin: https://nammaoorudelivary.in" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Authorization" \
  -i | grep "access-control-allow-origin"

# Should return ONLY 1 line, not 2+
```

**Complete Solution**:

1. **Remove all @CrossOrigin annotations** (23 files):
```bash
# Find all files with @CrossOrigin
find backend/src/main/java -name "*.java" -exec grep -l "@CrossOrigin" {} \;

# Remove @CrossOrigin annotations and imports from ALL controller files
# Files affected: AuthController, ProductController, ShopController, etc.
```

2. **Disable WebConfig CORS** (main duplicate source):
```java
// File: backend/src/main/java/com/shopmanagement/config/WebConfig.java
// COMMENT OUT the addCorsMappings method:

// DISABLED - Using Security-level CORS configuration instead
// @Override  
// public void addCorsMappings(CorsRegistry registry) {
//     // ... commented out
// }
```

3. **Remove nginx CORS headers**:
```bash
# Edit /etc/nginx/sites-available/api.nammaoorudelivary.in
# Remove ALL add_header Access-Control-* lines
sudo nano /etc/nginx/sites-available/api.nammaoorudelivary.in
sudo nginx -s reload
```

4. **Keep ONLY Security-level CORS** (single source):
```java
// File: backend/src/main/java/com/shopmanagement/config/SimpleSecurityConfig.java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowedOriginPatterns(Arrays.asList("*"));
    configuration.setAllowedMethods(Arrays.asList("*"));
    configuration.setAllowedHeaders(Arrays.asList("*"));
    configuration.setExposedHeaders(Arrays.asList("*"));
    configuration.setAllowCredentials(false); // CRITICAL for wildcard origins
    configuration.setMaxAge(3600L);
    
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
}
```

**Verification**:
```bash
# Should return exactly 1 (not 2+)
curl -X OPTIONS https://api.nammaoorudelivary.in/api/shops \
  -H "Origin: https://nammaoorudelivary.in" \
  -H "Access-Control-Request-Method: GET" \
  -i | grep -c "access-control-allow-origin"
```

**Files Modified**:
- 23 controller files (removed `@CrossOrigin` annotations)
- `backend/src/main/java/com/shopmanagement/config/WebConfig.java`
- `backend/src/main/java/com/shopmanagement/config/SimpleSecurityConfig.java`
- `/etc/nginx/sites-available/api.nammaoorudelivary.in`

**Deployment Commands**:
```bash
# After making changes
git add -A
git commit -m "FINAL CORS FIX: Remove duplicate headers from multiple sources"
git push origin main

# On server
cd /opt/shop-management
git pull
docker-compose restart backend
```

**Key Lessons**:
1. **ONE CORS source only** - Never mix WebMvcConfigurer, Security, and nginx CORS
2. **Browser cache matters** - Clear cache or use incognito after CORS fixes
3. **Duplicate headers = instant browser rejection** - Even identical duplicates fail
4. **Simple requests vs Complex requests** - Login (simple) works, authenticated APIs (complex) need preflight
5. **Wildcard origins require `allowCredentials(false)`** - Critical browser requirement

**Total Debug Time**: 50+ hours across multiple days
**Final Status**: ✅ **RESOLVED** - Single CORS header, all APIs working

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

*Last updated: 2025-09-01*
*Working deployment confirmed - CORS nightmare finally resolved*
*Total debugging time: 50+ hours across multiple debugging sessions*
*Root cause: Multiple duplicate CORS headers from 4 different sources*
*Solution: Single CORS configuration in SecurityConfig only*
*Status: ✅ PRODUCTION WORKING - All APIs functional*