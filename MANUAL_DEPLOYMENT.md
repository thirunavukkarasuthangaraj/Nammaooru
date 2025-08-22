# Manual Deployment Guide - Nammaooru Shop Management System

**Last Updated**: August 22, 2025  
**Production URL**: https://nammaoorudelivary.in  
**API URL**: https://api.nammaoorudelivary.in  
**Server**: Hetzner Cloud (65.21.4.236)

## 🚨 IMPORTANT: CI/CD is DISABLED
- GitHub Actions workflow has been disabled (backed up as `deploy.yml.backup`)
- All deployments must be done manually following this guide
- To re-enable CI/CD in future: rename `deploy.yml.backup` → `deploy.yml`

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Local Build Process](#local-build-process)
3. [Server Deployment](#server-deployment)
4. [Post-Deployment Verification](#post-deployment-verification)
5. [Troubleshooting](#troubleshooting)
6. [Rollback Procedures](#rollback-procedures)

---

## Prerequisites

### Local Machine Requirements
- Java 17+ (for backend)
- Node.js 18+ and npm (for frontend)
- Maven 3.8+ (for backend build)
- Git
- SSH client
- Docker (optional, for local testing)

### Server Access
```bash
# SSH access to Hetzner server
ssh root@65.21.4.236
# Password: [stored securely]
```

### Server Requirements (Already Installed)
- Docker and Docker Compose
- Nginx (for reverse proxy)
- PostgreSQL 15 (via Docker)
- Redis (via Docker)
- SSL certificates (Let's Encrypt)

---

## Local Build Process

### 1. Update Code Repository
```bash
# Navigate to project directory
cd D:\AAWS\nammaooru\shop-management-system

# Pull latest changes (if any)
git pull origin main

# Check current status
git status
```

### 2. Build Backend (Spring Boot)
```bash
cd backend

# Clean and build JAR file
mvn clean package -DskipTests

# Verify JAR creation
ls target/shop-management-backend-1.0.0.jar

# Optional: Run tests
mvn test
```

### 3. Build Frontend (Angular)
```bash
cd ../frontend

# Install dependencies
npm ci

# Build production version
npm run build -- --configuration=production

# Verify build output
ls dist/shop-management-frontend/
```

### 4. Prepare Deployment Package
```bash
cd ..

# Create deployment directory
mkdir -p deployment-package

# Copy backend JAR
cp backend/target/shop-management-backend-1.0.0.jar deployment-package/

# Copy frontend dist
cp -r frontend/dist/shop-management-frontend/* deployment-package/frontend/

# Copy Docker files
cp docker-compose.yml deployment-package/
cp backend/Dockerfile deployment-package/Dockerfile.backend
cp frontend/Dockerfile deployment-package/Dockerfile.frontend
cp frontend/nginx.conf deployment-package/

# Copy database scripts (if needed)
cp -r database deployment-package/

# Create deployment archive
tar -czf deployment-$(date +%Y%m%d-%H%M%S).tar.gz deployment-package/
```

---

## Server Deployment

### 1. Transfer Files to Server
```bash
# From local machine
scp deployment-*.tar.gz root@65.21.4.236:/root/

# Or use individual files
scp backend/target/shop-management-backend-1.0.0.jar root@65.21.4.236:/root/shop-management-system/backend/
scp -r frontend/dist/shop-management-frontend/* root@65.21.4.236:/root/shop-management-system/frontend/
```

### 2. Connect to Server
```bash
ssh root@65.21.4.236
```

### 3. Backup Current Deployment
```bash
cd /root/shop-management-system

# Create backup
cp -r . ../backup-$(date +%Y%m%d-%H%M%S)/

# Backup database
docker exec shop-postgres pg_dump -U postgres shop_management_db > backup-db-$(date +%Y%m%d).sql
```

### 4. Stop Current Services
```bash
# Stop all containers
docker-compose down

# Optional: Remove old images to ensure fresh build
docker rmi shop-frontend:latest shop-backend:latest
```

### 5. Update Files on Server
```bash
# If using archive
cd /root
tar -xzf deployment-*.tar.gz
cp -r deployment-package/* shop-management-system/

# Or update individual components
# For backend only:
docker-compose stop backend
docker-compose build backend
docker-compose up -d backend

# For frontend only:
docker-compose stop frontend
docker-compose build frontend
docker-compose up -d frontend
```

### 6. Update Environment Variables
```bash
# Edit .env file if needed
nano /root/shop-management-system/.env

# Required variables:
POSTGRES_DB=shop_management_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=yourpassword
JWT_SECRET=your-jwt-secret
REDIS_PASSWORD=your-redis-password
```

### 7. Apply CORS Configuration Fix
```bash
# Update docker-compose.yml with correct CORS settings
nano docker-compose.yml

# Ensure backend service has these environment variables:
- APP_CORS_ALLOWED_ORIGINS=https://nammaoorudelivary.in,https://www.nammaoorudelivary.in
- APP_CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
- APP_CORS_ALLOWED_HEADERS=*
- APP_CORS_ALLOW_CREDENTIALS=true
```

### 8. Update Nginx Configuration
```bash
# Edit API nginx config
nano /etc/nginx/sites-available/api.nammaoorudelivary.in

# Ensure CORS headers allow both www and non-www:
# See deployment/nginx-api.conf for correct configuration

# Test nginx config
nginx -t

# Reload nginx
systemctl reload nginx
```

### 9. Deploy Application
```bash
cd /root/shop-management-system

# Build and start all services
docker-compose build --no-cache
docker-compose up -d

# Check container status
docker-compose ps

# Monitor logs
docker-compose logs -f
# Press Ctrl+C to exit logs
```

---

## Post-Deployment Verification

### 1. Check Container Health
```bash
# View all containers
docker ps

# Check specific service logs
docker-compose logs backend
docker-compose logs frontend
docker-compose logs postgres

# Check container health
docker inspect shop-backend | grep -A 5 Health
```

### 2. Test Backend API
```bash
# From server
curl http://localhost:8082/actuator/health

# Test CORS headers
curl -I -X OPTIONS \
  -H "Origin: https://nammaoorudelivary.in" \
  -H "Access-Control-Request-Method: POST" \
  https://api.nammaoorudelivary.in/api/auth/login
```

### 3. Test Frontend
```bash
# From server
curl -I http://localhost:8080

# Check nginx access
curl -I https://nammaoorudelivary.in
```

### 4. Browser Testing
1. Open https://nammaoorudelivary.in
2. Open browser console (F12)
3. Try to login
4. Check for any CORS errors in console
5. Test both www and non-www versions

### 5. Database Verification
```bash
# Connect to PostgreSQL
docker exec -it shop-postgres psql -U postgres -d shop_management_db

# Check tables
\dt

# Check user count
SELECT COUNT(*) FROM users;

# Exit
\q
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. CORS Errors
```bash
# Fix: Update nginx and backend CORS settings
cd /root/shop-management-system
./scripts/fix-cors-production.sh
```

#### 2. Container Won't Start
```bash
# Check logs
docker-compose logs backend

# Common fixes:
# - Check port conflicts
netstat -tlnp | grep -E ':8082|:8080|:5432'

# - Check disk space
df -h

# - Rebuild container
docker-compose build --no-cache backend
docker-compose up -d backend
```

#### 3. Database Connection Issues
```bash
# Test database connection
docker exec shop-postgres pg_isready -U postgres

# Reset database password
docker-compose exec postgres psql -U postgres
ALTER USER postgres PASSWORD 'newpassword';
```

#### 4. Frontend Not Loading
```bash
# Check nginx in frontend container
docker exec shop-frontend nginx -t

# Restart frontend
docker-compose restart frontend

# Check frontend logs
docker logs shop-frontend
```

#### 5. SSL Certificate Issues
```bash
# Renew certificates
certbot renew

# Restart nginx
systemctl restart nginx
```

---

## Rollback Procedures

### Quick Rollback
```bash
# If deployment fails, restore from backup
cd /root
docker-compose down
rm -rf shop-management-system
mv backup-[date] shop-management-system
cd shop-management-system
docker-compose up -d
```

### Database Rollback
```bash
# Restore database from backup
docker exec -i shop-postgres psql -U postgres -d shop_management_db < backup-db-[date].sql
```

---

## Monitoring and Logs

### View Real-time Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend

# System logs
tail -f /var/log/nginx/error.log
journalctl -u docker -f
```

### Check Resource Usage
```bash
# Docker stats
docker stats

# System resources
htop
df -h
free -h
```

---

## Security Notes

1. **Never commit secrets** to Git repository
2. **Use environment variables** for sensitive data
3. **Keep backups** before each deployment
4. **Monitor logs** for suspicious activity
5. **Update dependencies** regularly

---

## Contact & Support

For deployment issues:
1. Check logs first
2. Refer to troubleshooting section
3. Keep backup ready for rollback
4. Document any new issues and solutions

---

## Deployment Checklist

Before deployment:
- [ ] Code tested locally
- [ ] Build successful (backend & frontend)
- [ ] Environment variables ready
- [ ] Backup created
- [ ] Maintenance window scheduled (if needed)

During deployment:
- [ ] Services stopped properly
- [ ] Files transferred successfully
- [ ] Docker images built
- [ ] Containers started
- [ ] Health checks passing

After deployment:
- [ ] Frontend accessible
- [ ] API responding
- [ ] Login working
- [ ] No CORS errors
- [ ] Monitor logs for 10 minutes

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2025-08-22 | 1.0.7 | CI/CD disabled, manual deployment only |
| 2025-08-21 | 1.0.6 | CORS fixes applied |
| 2025-08-20 | 1.0.5 | Initial production deployment |

---

*This document will be updated with each deployment. Always use the latest version.*