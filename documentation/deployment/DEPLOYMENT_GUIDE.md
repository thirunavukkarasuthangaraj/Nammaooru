# Deployment Guide - NammaOoru Thiru Software System

## Why We Faced Email Issues (Root Cause Analysis)

### Problem Timeline
1. **Initial Setup**: Used Gmail SMTP configuration 
2. **Production Deploy**: Gmail credentials not working on Hetzner server
3. **Switch to Hostinger**: Changed to Hostinger SMTP but kept Gmail FROM address
4. **Authentication Error**: "Sender address rejected: not owned by user"
5. **Network Issues**: Port 465 blocked by Hetzner firewall
6. **SSL/TLS Issues**: Java handshake failure with Hostinger SSL
7. **Final Fix**: Corrected FROM address + port 587 + proper SSL config

### Root Causes Identified
1. **Hardcoded Default Values**: `application.yml` had Gmail defaults
2. **FROM Address Mismatch**: Using Gmail address with Hostinger auth
3. **Network Configuration**: Missing firewall rules for SMTP ports
4. **SSL Configuration**: Incomplete SSL socket factory setup
5. **Environment Variables**: Missing proper Docker environment mapping

### Lessons Learned
- **Always match FROM address with SMTP username**
- **Document all configuration dependencies**
- **Test email in production-like environment**
- **Use environment variables for all external services**
- **Keep backup documentation of working configurations**

## Deployment Architecture

### Server Infrastructure
```
┌─────────────────────────────────────────────┐
│ Hetzner Cloud Server (65.21.4.236)         │
├─────────────────────────────────────────────┤
│ Ubuntu Server                               │
│ ├── Docker Engine                           │
│ ├── Docker Compose                          │
│ ├── Nginx (Reverse Proxy)                   │
│ └── SSL Certificates                        │
└─────────────────────────────────────────────┘
```

### Application Stack
```
Frontend (Angular) → Nginx → Backend (Spring Boot) → PostgreSQL
                              ↓
                         External SMTP (Hostinger)
```

## Deployment Process

### 1. Frontend Deployment
```bash
# Build Angular frontend
cd frontend
npm run build:prod

# Deploy to production server
./deploy-prod.sh
```

### 2. Backend Deployment
```bash
# SSH to production server
ssh root@65.21.4.236

# Navigate to project directory
cd /opt/shop-management

# Pull latest changes
git pull origin main

# Rebuild and restart containers
docker-compose down
docker-compose up --build -d

# Monitor logs
docker-compose logs -f backend
```

### 3. Mobile App Deployment
```bash
# Build APK
cd mobile/nammaooru_mobile_app
flutter build apk --release

# Install on device
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Docker Configuration

### docker-compose.yml Structure
```yaml
version: '3.8'
services:
  backend:
    build: ./backend
    ports:
      - "8082:8082"
    environment:
      # Database
      - DB_URL=jdbc:postgresql://db:5432/shop_management_db
      - DB_USERNAME=postgres
      - DB_PASSWORD=${DB_PASSWORD}
      
      # Email Configuration
      - MAIL_HOST=smtp.hostinger.com
      - MAIL_PORT=587
      - MAIL_USERNAME=noreplay@nammaoorudelivary.in
      - MAIL_PASSWORD=${MAIL_PASSWORD}
      - EMAIL_FROM_ADDRESS=noreplay@nammaoorudelivary.in
      
      # Security
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - db
      
  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=shop_management_db
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      
volumes:
  postgres_data:
```

### Environment Variables
```bash
# .env file (never commit this)
DB_PASSWORD=secure_database_password
MAIL_PASSWORD=noreplaynammaooruDelivary@2025
JWT_SECRET=your_jwt_secret_minimum_256_bits
```

## Server Configuration

### Nginx Configuration
```nginx
server {
    listen 80;
    server_name nammaoorudelivary.in www.nammaoorudelivary.in;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name nammaoorudelivary.in www.nammaoorudelivary.in;
    
    ssl_certificate /etc/ssl/certs/cert.pem;
    ssl_certificate_key /etc/ssl/private/key.pem;
    
    # Frontend
    location / {
        root /var/www/html;
        try_files $uri $uri/ /index.html;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://localhost:8082/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Firewall Configuration
```bash
# Allow necessary ports
ufw allow 22      # SSH
ufw allow 80      # HTTP
ufw allow 443     # HTTPS
ufw allow 465     # SMTP SSL
ufw allow 587     # SMTP STARTTLS
ufw allow 8082    # Backend API
ufw enable
```

## Monitoring and Maintenance

### Log Monitoring
```bash
# Backend logs
docker-compose logs -f backend

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# System logs
journalctl -f
```

### Health Checks
```bash
# Backend health
curl https://api.nammaoorudelivary.in/api/actuator/health

# Database connection
docker-compose exec db psql -U postgres -d shop_management_db -c "SELECT 1;"

# Email service
curl -X POST https://api.nammaoorudelivary.in/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

### Backup Strategy
```bash
# Database backup
docker-compose exec db pg_dump -U postgres shop_management_db > backup_$(date +%Y%m%d).sql

# File uploads backup
tar -czf uploads_backup_$(date +%Y%m%d).tar.gz /opt/shop-management/uploads/

# Configuration backup
cp docker-compose.yml docker-compose.yml.backup
cp .env .env.backup
```

## Troubleshooting Common Issues

### 1. Container Won't Start
```bash
# Check container status
docker-compose ps

# View container logs
docker-compose logs backend

# Rebuild from scratch
docker-compose down
docker system prune -a -f
docker-compose up --build -d
```

### 2. Database Connection Issues
```bash
# Check database container
docker-compose logs db

# Test database connection
docker-compose exec backend java -jar app.jar --spring.datasource.url=jdbc:postgresql://db:5432/shop_management_db
```

### 3. Frontend Not Loading
```bash
# Check nginx status
systemctl status nginx

# Test nginx configuration
nginx -t

# Restart nginx
systemctl restart nginx
```

### 4. Email Not Working
```bash
# Check email configuration in logs
docker-compose logs backend | grep -i mail

# Test SMTP connectivity
telnet smtp.hostinger.com 587

# Verify environment variables
docker-compose exec backend printenv | grep MAIL
```

## Performance Optimization

### Database Optimization
```sql
-- Create indexes for frequently queried columns
CREATE INDEX idx_shop_owner_id ON shops(owner_id);
CREATE INDEX idx_product_shop_id ON products(shop_id);
CREATE INDEX idx_user_email ON users(email);
```

### Backend Optimization
```yaml
# application.yml performance settings
spring:
  jpa:
    hibernate:
      jdbc:
        batch_size: 25
    properties:
      hibernate:
        jdbc:
          batch_versioned_data: true
        order_inserts: true
        order_updates: true
```

### Frontend Optimization
```bash
# Build with optimization
ng build --prod --aot --build-optimizer

# Enable gzip compression in nginx
gzip on;
gzip_types text/plain text/css application/json application/javascript;
```

## Security Checklist

### Server Security
- [ ] SSH key-based authentication only
- [ ] Firewall configured and enabled
- [ ] SSL certificates installed and valid
- [ ] Regular security updates applied
- [ ] Non-root user for application processes

### Application Security
- [ ] JWT tokens with proper expiration
- [ ] Input validation on all endpoints
- [ ] CORS configured correctly
- [ ] No sensitive data in logs
- [ ] Database credentials secured

### Email Security
- [ ] SMTP credentials not in git
- [ ] SSL/TLS encryption enabled
- [ ] FROM address matches authenticated user
- [ ] Rate limiting on email endpoints

## Recovery Procedures

### Disaster Recovery
```bash
# Stop services
docker-compose down

# Restore database backup
docker-compose up -d db
docker-compose exec -T db psql -U postgres -d shop_management_db < backup_20250102.sql

# Restore file uploads
tar -xzf uploads_backup_20250102.tar.gz -C /

# Start all services
docker-compose up -d

# Verify functionality
curl https://api.nammaoorudelivary.in/api/actuator/health
```

### Rollback Procedure
```bash
# Rollback to previous git commit
git log --oneline -5
git checkout <previous-commit-hash>

# Rebuild and deploy
docker-compose up --build -d
```

---

**Deployment Checklist**
- [ ] Code tested locally
- [ ] Environment variables configured
- [ ] Database migrations applied
- [ ] SSL certificates valid
- [ ] Email configuration tested
- [ ] Firewall rules updated
- [ ] Monitoring set up
- [ ] Backup strategy in place
- [ ] Recovery procedures documented
- [ ] Team notified of deployment