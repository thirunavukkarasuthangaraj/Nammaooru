# Deployment Issues Log - August 22, 2025

## Issues Faced and Solutions

### 1. CORS Error - Mixed Domain Access
**Issue**: 
- CORS blocked requests from `https://nammaoorudelivary.in` (non-www)
- Nginx only allowed `https://www.nammaoorudelivary.in` (with www)
- Error: "Http failure response for https://api.nammaoorudelivary.in/api/auth/login: 0 Unknown Error"

**Root Cause**:
- Nginx configuration had hardcoded single origin
- Backend CORS settings not properly configured with environment variables

**Solution**:
```bash
# Updated nginx config to accept both www and non-www
set $cors_origin "";
if ($http_origin ~* ^https://(www\.)?nammaoorudelivary\.in$) {
    set $cors_origin $http_origin;
}
add_header 'Access-Control-Allow-Origin' $cors_origin always;
```

### 2. Wrong Project Directory on Server
**Issue**:
- Project was in `/opt/shop-management` not `/root/shop-management-system`
- Scripts were looking in wrong directory
- Commands failed with "No such file or directory"

**Root Cause**:
- Different deployment paths between documentation and actual setup

**Solution**:
```bash
cd /opt/shop-management  # Correct path
# Not cd /root/shop-management-system
```

### 3. Docker Container Name Conflict
**Issue**:
- Error: "Container name '/backend' is already in use"
- Container got corrupted name: `60ea61808c18_backend`
- Docker-compose couldn't recreate container

**Error Message**:
```
ERROR: for backend 'ContainerConfig'
KeyError: 'ContainerConfig'
```

**Solution**:
```bash
# Remove conflicting containers
docker rm -f backend
docker rm -f 60ea61808c18_backend
# Then restart
docker-compose up -d backend
```

### 4. PostgreSQL Password Authentication Failed
**Issue**:
- Backend couldn't connect to database
- Error: "FATAL: password authentication failed for user 'postgres'"
- Backend kept crashing on startup

**Root Cause**:
- Password mismatch between PostgreSQL and backend configuration
- Missing .env file with correct credentials

**Solution**:
```bash
# Reset PostgreSQL password
docker exec -it shop-postgres psql -U postgres -c "ALTER USER postgres PASSWORD 'postgres';"

# Create .env file
cat > .env << 'EOF'
POSTGRES_DB=shop_management_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
EOF

# Restart backend
docker-compose restart backend
```

### 5. Backend CORS Environment Variables Not Applied
**Issue**:
- Backend WebConfig looking for `app.cors.*` properties
- Docker-compose had wrong variable names (`CORS_ALLOWED_ORIGINS` instead of `APP_CORS_*`)

**Solution**:
Updated docker-compose.yml:
```yaml
environment:
  - APP_CORS_ALLOWED_ORIGINS=https://nammaoorudelivary.in,https://www.nammaoorudelivary.in
  - APP_CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
  - APP_CORS_ALLOWED_HEADERS=*
  - APP_CORS_ALLOW_CREDENTIALS=true
```

### 6. CI/CD Pipeline Interference
**Issue**:
- GitHub Actions automatically deploying on every push
- Manual changes getting overwritten

**Solution**:
- Renamed `.github/workflows/deploy.yml` → `deploy.yml.backup`
- Disabled automatic deployment
- All deployments now manual only

### 7. Git Repository Not Found
**Issue**:
- Server home directory didn't have git repository
- `git pull` failed with "not a git repository"

**Solution**:
- Found correct path: `/opt/shop-management`
- Repository already cloned there

### 8. Backend Health Check Timing
**Issue**:
- Backend takes 30-60 seconds to fully start
- Health checks failing immediately after container start
- `curl: (56) Recv failure: Connection reset by peer`

**Solution**:
```bash
# Wait for backend to fully start
sleep 30
# Then check health
curl http://localhost:8082/actuator/health
```

## Prevention Checklist for Future Deployments

1. ✅ Always check correct project directory first: `/opt/shop-management`
2. ✅ Ensure .env file exists with correct database passwords
3. ✅ Remove any conflicting containers before starting new ones
4. ✅ Wait 30+ seconds for backend to start before health checks
5. ✅ Verify nginx CORS config allows both www and non-www domains
6. ✅ Use correct environment variable names (APP_CORS_* not CORS_*)
7. ✅ Don't rely on CI/CD - use manual deployment

## Quick Fixes Reference

```bash
# If container name conflict
docker rm -f backend

# If password error
docker exec -it shop-postgres psql -U postgres -c "ALTER USER postgres PASSWORD 'postgres';"

# If CORS error
systemctl reload nginx

# If backend not starting
docker-compose logs --tail=100 backend  # Check actual error

# Full reset if needed
docker-compose down
docker-compose up -d --build
```

## Server Details
- **Server IP**: 65.21.4.236
- **Project Path**: `/opt/shop-management`
- **Main URL**: https://nammaoorudelivary.in
- **API URL**: https://api.nammaoorudelivary.in
- **Ports**: 
  - Frontend: 8080
  - Backend: 8082
  - PostgreSQL: 5432
  - Redis: 6379

---
*This log helps prevent repeating the same issues in future deployments*