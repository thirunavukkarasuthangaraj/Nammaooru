# 🚀 NammaOoru Shop Management System - Deployment Guide

## 📋 Overview

This guide covers the complete deployment process for the NammaOoru Shop Management System, including server setup, Docker configuration, SSL certificates, and troubleshooting deployment issues.

---

## 🏗️ Production Environment

### Server Specifications
- **Provider**: Hetzner Cloud
- **Server IP**: 65.21.4.236
- **Operating System**: Ubuntu Server 22.04 LTS
- **Domain**: nammaoorudelivary.in
- **API Subdomain**: api.nammaoorudelivary.in
- **Resources**: 4GB RAM, 2 vCPUs, 80GB SSD

### DNS Configuration
```
A Record: nammaoorudelivary.in → 65.21.4.236
A Record: api.nammaoorudelivary.in → 65.21.4.236
```

---

## 🐳 Docker Deployment

### Docker Compose Configuration

**File**: `docker-compose.yml`
```yaml
version: '3.8'

services:
  backend:
    build: 
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - DB_URL=jdbc:postgresql://postgres:5432/shop_management_db
      - DB_USERNAME=postgres
      - DB_PASSWORD=${DB_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - MSG91_AUTH_KEY=${MSG91_AUTH_KEY}
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_PORT=${SMTP_PORT}
      - SMTP_USERNAME=${SMTP_USERNAME}
      - SMTP_PASSWORD=${SMTP_PASSWORD}
    volumes:
      - ./uploads:/app/uploads
      - ./logs:/app/logs
    depends_on:
      - postgres
    restart: unless-stopped

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=shop_management_db
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    ports:
      - "5432:5432"
    restart: unless-stopped

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - backend
    restart: unless-stopped

volumes:
  postgres_data:
```

### Environment Variables

**File**: `.env`
```bash
# Database Configuration
DB_PASSWORD=your_secure_database_password

# JWT Configuration
JWT_SECRET=your_256_bit_jwt_secret_key

# External API Keys
MSG91_AUTH_KEY=your_msg91_api_key

# SMTP Configuration (Hostinger)
SMTP_HOST=smtp.hostinger.com
SMTP_PORT=587
SMTP_USERNAME=noreplay@nammaoorudelivary.in
SMTP_PASSWORD=your_email_password
```

---

## 🔧 Server Setup Process

### 1. Initial Server Configuration

```bash
# Connect to server
ssh root@65.21.4.236

# Update system packages
apt update && apt upgrade -y

# Install required packages
apt install -y docker.io docker-compose nginx certbot python3-certbot-nginx git

# Enable Docker service
systemctl enable docker
systemctl start docker

# Add user to docker group (optional)
usermod -aG docker $USER
```

### 2. Project Deployment

```bash
# Clone repository
git clone https://github.com/your-repo/shop-management-system.git
cd shop-management-system

# Create environment file
cp .env.example .env
nano .env  # Configure all environment variables

# Create required directories
mkdir -p uploads logs backups

# Set proper permissions
chmod 755 uploads logs backups
```

### 3. SSL Certificate Setup

```bash
# Stop nginx if running
systemctl stop nginx

# Obtain SSL certificate
certbot certonly --standalone -d nammaoorudelivary.in -d api.nammaoorudelivary.in

# Setup auto-renewal
crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 4. Nginx Configuration

**File**: `/etc/nginx/sites-available/nammaoorudelivary`
```nginx
# Frontend (Angular SPA)
server {
    listen 80;
    listen 443 ssl http2;
    server_name nammaoorudelivary.in;

    ssl_certificate /etc/letsencrypt/live/nammaoorudelivary.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nammaoorudelivary.in/privkey.pem;

    # Redirect HTTP to HTTPS
    if ($scheme != "https") {
        return 301 https://$server_name$request_uri;
    }

    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Backend API
server {
    listen 80;
    listen 443 ssl http2;
    server_name api.nammaoorudelivary.in;

    ssl_certificate /etc/letsencrypt/live/nammaoorudelivary.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nammaoorudelivary.in/privkey.pem;

    # Redirect HTTP to HTTPS
    if ($scheme != "https") {
        return 301 https://$server_name$request_uri;
    }

    # API endpoints
    location /api/ {
        proxy_pass http://localhost:8080/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Accept,Authorization,Cache-Control,Content-Type,DNT,If-Modified-Since,Keep-Alive,Origin,User-Agent,X-Requested-With' always;
        
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'Accept,Authorization,Cache-Control,Content-Type,DNT,If-Modified-Since,Keep-Alive,Origin,User-Agent,X-Requested-With';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }

    # File uploads
    location /uploads/ {
        alias /var/www/uploads/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

### 5. Enable Nginx Configuration

```bash
# Create symbolic link
ln -s /etc/nginx/sites-available/nammaoorudelivary /etc/nginx/sites-enabled/

# Test configuration
nginx -t

# Restart nginx
systemctl restart nginx
systemctl enable nginx
```

### 6. Deploy Application

```bash
# Build and start services
docker-compose up --build -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

---

## 🔄 Deployment Commands

### Initial Deployment
```bash
# Full deployment from scratch
git clone https://github.com/your-repo/shop-management-system.git
cd shop-management-system
cp .env.example .env
# Configure .env file
docker-compose up --build -d
```

### Update Deployment
```bash
# Pull latest changes
git pull origin main

# Rebuild and restart services
docker-compose down
docker-compose up --build -d

# Check status
docker-compose ps
```

### Rollback Deployment
```bash
# Rollback to previous commit
git log --oneline -5  # Find previous commit hash
git checkout <previous-commit-hash>

# Rebuild
docker-compose down
docker-compose up --build -d
```

---

## 🔧 Build Process

### Backend (Spring Boot)
```dockerfile
# Dockerfile
FROM openjdk:17-jdk-slim

WORKDIR /app

# Copy Maven files
COPY pom.xml .
COPY src ./src

# Build application
RUN ./mvnw clean package -DskipTests

# Run application
EXPOSE 8080
CMD ["java", "-jar", "target/shop-management-system-1.0.jar"]
```

### Frontend (Angular)
```dockerfile
# Multi-stage build
FROM node:18 AS builder

WORKDIR /app
COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build --prod

# Production stage
FROM nginx:alpine
COPY --from=builder /app/dist/shop-management-system /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## 🛡️ Security Configuration

### Firewall Setup
```bash
# Configure UFW
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw allow 5432/tcp  # PostgreSQL (only if needed externally)
ufw --force enable

# Check status
ufw status verbose
```

### SSL Security Headers
```nginx
# Add to nginx server blocks
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Content-Type-Options nosniff always;
add_header X-Frame-Options DENY always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

---

## 📊 Monitoring & Health Checks

### Docker Health Checks
```yaml
# Add to docker-compose.yml services
backend:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
```

### System Monitoring Commands
```bash
# Check disk space
df -h

# Check memory usage
free -h

# Check Docker containers
docker stats

# Check system resources
htop

# Check logs
docker-compose logs -f backend
tail -f /var/log/nginx/error.log
```

---

## 🚨 Troubleshooting Deployment Issues

### Common Issues & Solutions

#### 1. Docker Build Failures
```bash
# Clear Docker cache
docker system prune -a -f

# Rebuild without cache
docker-compose build --no-cache

# Check Docker logs
docker-compose logs backend
```

#### 2. SSL Certificate Issues
```bash
# Renew certificates
certbot renew

# Test certificate
curl -I https://nammaoorudelivary.in
curl -I https://api.nammaoorudelivary.in

# Check certificate expiry
openssl x509 -in /etc/letsencrypt/live/nammaoorudelivary.in/cert.pem -text -noout
```

#### 3. Database Connection Issues
```bash
# Check PostgreSQL container
docker-compose logs postgres

# Test database connection
docker exec -it <postgres-container> psql -U postgres -d shop_management_db

# Reset database (if needed)
docker-compose down
docker volume rm shop-management-system_postgres_data
docker-compose up -d
```

#### 4. API Not Accessible
```bash
# Check backend container status
docker-compose ps backend

# Check backend logs
docker-compose logs -f backend

# Test API directly
curl http://localhost:8080/actuator/health

# Check nginx proxy
curl -I https://api.nammaoorudelivary.in/actuator/health
```

#### 5. Frontend Not Loading
```bash
# Check nginx status
systemctl status nginx

# Test nginx configuration
nginx -t

# Check frontend container
docker-compose logs frontend

# Test direct access
curl http://localhost:80
```

---

## 🔄 Backup & Recovery

### Database Backup
```bash
# Create backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="/backups/db_backup_$DATE.sql"

docker exec <postgres-container> pg_dump -U postgres shop_management_db > $BACKUP_FILE
gzip $BACKUP_FILE

# Keep only last 7 days of backups
find /backups -name "db_backup_*.sql.gz" -mtime +7 -delete
```

### Database Restore
```bash
# Restore from backup
gunzip db_backup_20250113_120000.sql.gz
docker exec -i <postgres-container> psql -U postgres shop_management_db < db_backup_20250113_120000.sql
```

### File Backup
```bash
# Backup uploaded files
tar -czf uploads_backup_$(date +%Y%m%d).tar.gz uploads/

# Backup logs
tar -czf logs_backup_$(date +%Y%m%d).tar.gz logs/
```

---

## 📈 Performance Optimization

### Docker Optimization
```yaml
# Production docker-compose optimizations
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G
```

### Nginx Optimization
```nginx
# Performance optimizations
worker_processes auto;
worker_connections 1024;

gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

# Caching
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

---

## ✅ Deployment Checklist

### Pre-Deployment
- [ ] Code tested locally
- [ ] Environment variables configured
- [ ] SSL certificates valid
- [ ] Database backup taken
- [ ] Dependencies updated
- [ ] Docker images built successfully

### Deployment
- [ ] Services deployed
- [ ] Health checks passing
- [ ] API endpoints responding
- [ ] Frontend loading correctly
- [ ] Database connections working
- [ ] Email functionality tested

### Post-Deployment
- [ ] SSL certificate working
- [ ] All endpoints accessible
- [ ] Mobile app connectivity verified
- [ ] Monitoring alerts configured
- [ ] Backup cron jobs setup
- [ ] Performance metrics baseline established

---

## 📞 Support

### Emergency Contacts
- **System Admin**: Available 24/7
- **Hetzner Support**: Server infrastructure issues
- **Domain Provider**: DNS-related issues

### Useful Commands for Support
```bash
# System status overview
docker-compose ps && systemctl status nginx && df -h

# Recent error logs
docker-compose logs --tail=50 backend
tail -50 /var/log/nginx/error.log

# Performance snapshot
docker stats --no-stream
free -h && uptime
```

---

**Last Updated**: January 2025
**Status**: Production Ready
**Next Review**: When major architecture changes are made