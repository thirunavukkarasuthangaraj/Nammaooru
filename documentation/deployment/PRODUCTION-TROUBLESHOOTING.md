# Production Troubleshooting Guide

## Current Issue: Backend Container Restarting

Your backend container is in a restart loop. Here's how to diagnose and fix it:

### 1. Check Container Logs
```bash
cd /opt/shop-management
docker-compose logs backend --tail=100
```

### 2. Common Issues and Solutions

#### Issue A: YAML Configuration Error
**Symptoms:** Error about duplicate keys in YAML
**Solution:** 
```bash
# Check if application-production.yml has duplicate spring: keys
docker exec -it nammaooru-backend cat /app/classes/application-production.yml | grep -n "^spring:"
```

#### Issue B: Database Connection Error  
**Symptoms:** Connection refused to PostgreSQL
**Solution:**
1. Verify PostgreSQL is running:
   ```bash
   sudo systemctl status postgresql
   ```
2. Check database credentials in `.env` file
3. Ensure database exists:
   ```bash
   sudo -u postgres psql -c "\l" | grep shop_management
   ```

#### Issue C: Mail Configuration Error
**Symptoms:** Mail authentication failed
**Solution:**
1. Update mail credentials in `.env`:
   ```bash
   # Use Gmail App Password, not regular password
   MAIL_USERNAME=your_email@gmail.com
   MAIL_PASSWORD=your_16_digit_app_password
   ```

#### Issue D: Missing Environment Variables
**Symptoms:** Application fails to start with missing env var errors
**Solution:**
1. Copy environment template:
   ```bash
   cp .env.production.example .env
   ```
2. Update all required values in `.env`

### 3. Quick Fix Commands

#### Restart with Fresh Build
```bash
cd /opt/shop-management
docker-compose down
docker-compose build --no-cache backend
docker-compose up -d
```

#### Check Health Status
```bash
# Wait 30 seconds, then check health
sleep 30
curl http://localhost:8082/actuator/health
```

#### View Real-time Logs
```bash
docker-compose logs -f backend
```

### 4. Environment File Setup

Create `/opt/shop-management/.env` with these minimum required values:
```env
SPRING_PROFILES_ACTIVE=production
DB_URL=jdbc:postgresql://host.docker.internal:5432/shop_management_db  
DB_USERNAME=postgres
DB_PASSWORD=your_actual_db_password
JWT_SECRET=your_very_long_secure_jwt_secret_at_least_32_characters
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_gmail_app_password
```

### 5. Testing Each Component

#### Test Database Connection
```bash
# Test PostgreSQL connection
docker run --rm postgres:13 psql -h host.docker.internal -U postgres -d shop_management_db -c "SELECT 1;"
```

#### Test Backend API
```bash
# Test after container starts
curl -I http://localhost:8082/api/shops
```

#### Test Frontend
```bash
curl -I http://localhost/
```

### 6. Common Port Issues

If port 8082 is occupied:
```bash
# Check what's using port 8082
sudo netstat -tulpn | grep 8082
sudo lsof -i :8082
```

### 7. Docker Cleanup (if needed)
```bash
# Remove all containers and rebuild
docker-compose down --volumes --remove-orphans
docker system prune -f
docker volume prune -f
```

## Need More Help?

1. Run this command and share the output:
   ```bash
   cd /opt/shop-management
   docker-compose ps
   docker-compose logs backend --tail=50
   ```

2. Check if `.env` file exists and has correct values:
   ```bash
   ls -la .env
   cat .env | grep -E "(DB_|JWT_|MAIL_)" | head -10
   ```