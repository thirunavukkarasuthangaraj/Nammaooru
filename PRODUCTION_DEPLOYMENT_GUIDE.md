# Production Deployment Guide - Nammaooru Shop Management System

## Prerequisites
- Hetzner Server with Ubuntu 20.04/22.04
- External PostgreSQL Database (Hetzner Managed or Separate)
- Domain name pointing to server
- SSL Certificate (Let's Encrypt)

---

## Part 1: Database Setup (External PostgreSQL)

### 1.1 Connect to PostgreSQL Database
```bash
# Connect to your Hetzner PostgreSQL instance
psql -h your-db-host.hetzner.com -U postgres -p 5432

# Create database
CREATE DATABASE shop_management_db;

# Create user (change password!)
CREATE USER shopuser WITH ENCRYPTED PASSWORD 'YourStrongPassword123!';

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE shop_management_db TO shopuser;
\q
```

### 1.2 Import Schema and Initial Data
```bash
# From your local machine, export current schema
pg_dump -h localhost -U postgres -d shop_management_db --schema-only > schema.sql
pg_dump -h localhost -U postgres -d shop_management_db --data-only -t users -t shops -t master_products > initial_data.sql

# Import to Hetzner PostgreSQL
psql -h your-db-host.hetzner.com -U shopuser -d shop_management_db < schema.sql
psql -h your-db-host.hetzner.com -U shopuser -d shop_management_db < initial_data.sql
```

---

## Part 2: Server Setup

### 2.1 Connect to Hetzner Server
```bash
ssh root@your-server-ip
```

### 2.2 Install Required Software
```bash
# Update system
apt update && apt upgrade -y

# Install Java 17
apt install openjdk-17-jdk -y
java -version

# Install Nginx
apt install nginx -y

# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install nodejs -y
node -v
npm -v

# Install PM2 for process management
npm install -g pm2

# Install Certbot for SSL
apt install certbot python3-certbot-nginx -y
```

### 2.3 Create Application User
```bash
# Create user for running application
useradd -m -s /bin/bash shopapp
usermod -aG sudo shopapp

# Create directories
mkdir -p /opt/shopmanagement/backend
mkdir -p /opt/shopmanagement/frontend
mkdir -p /opt/shopmanagement/uploads
mkdir -p /var/log/shopmanagement

# Set permissions
chown -R shopapp:shopapp /opt/shopmanagement
chown -R shopapp:shopapp /var/log/shopmanagement
```

---

## Part 3: Backend Deployment

### 3.1 Build Backend JAR (On Local Machine)
```bash
cd backend

# Create production application.yml
cat > src/main/resources/application-prod.yml << 'EOF'
server:
  port: 8082
  servlet:
    context-path: /

spring:
  datasource:
    url: jdbc:postgresql://your-db-host.hetzner.com:5432/shop_management_db
    username: shopuser
    password: YourStrongPassword123!
    driver-class-name: org.postgresql.driver.Driver
  
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: true
    show-sql: false
  
  security:
    jwt:
      secret: your-production-secret-key-change-this
      expiration: 86400000

file:
  upload-dir: /opt/shopmanagement/uploads

cors:
  allowed-origins:
    - https://yourdomain.com
    - https://www.yourdomain.com

logging:
  level:
    root: INFO
    com.shopmanagement: INFO
  file:
    name: /var/log/shopmanagement/backend.log
EOF

# Build JAR
mvn clean package -DskipTests -Pprod
```

### 3.2 Transfer JAR to Server
```bash
# From local machine
scp target/shop-management-backend-1.0.0.jar root@your-server-ip:/opt/shopmanagement/backend/
scp src/main/resources/application-prod.yml root@your-server-ip:/opt/shopmanagement/backend/
```

### 3.3 Create Systemd Service (On Server)
```bash
# Create service file
cat > /etc/systemd/system/shopmanagement-backend.service << 'EOF'
[Unit]
Description=Shop Management Backend
After=network.target

[Service]
Type=simple
User=shopapp
Group=shopapp
WorkingDirectory=/opt/shopmanagement/backend
ExecStart=/usr/bin/java -jar -Xmx512m -Dspring.profiles.active=prod /opt/shopmanagement/backend/shop-management-backend-1.0.0.jar
Restart=always
RestartSec=10
StandardOutput=append:/var/log/shopmanagement/backend.log
StandardError=append:/var/log/shopmanagement/backend-error.log

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable shopmanagement-backend
systemctl start shopmanagement-backend
systemctl status shopmanagement-backend
```

---

## Part 4: Frontend Deployment

### 4.1 Build Frontend (On Local Machine)
```bash
cd frontend

# Update environment.prod.ts
cat > src/environments/environment.prod.ts << 'EOF'
export const environment = {
  production: true,
  apiUrl: 'https://api.yourdomain.com/api',
  wsUrl: 'wss://api.yourdomain.com/ws',
  uploadUrl: 'https://api.yourdomain.com/uploads'
};
EOF

# Build production
npm install
npm run build --prod
```

### 4.2 Transfer Build to Server
```bash
# From local machine
tar -czf frontend-dist.tar.gz -C dist/shop-management-frontend .
scp frontend-dist.tar.gz root@your-server-ip:/tmp/

# On server
cd /opt/shopmanagement/frontend
tar -xzf /tmp/frontend-dist.tar.gz
rm /tmp/frontend-dist.tar.gz
```

---

## Part 5: Nginx Configuration

### 5.1 Create Nginx Config
```bash
# Backend API config
cat > /etc/nginx/sites-available/api.yourdomain.com << 'EOF'
server {
    listen 80;
    server_name api.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:8082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /uploads {
        alias /opt/shopmanagement/uploads;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    client_max_body_size 50M;
}
EOF

# Frontend config
cat > /etc/nginx/sites-available/yourdomain.com << 'EOF'
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://yourdomain.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    root /opt/shopmanagement/frontend;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
EOF

# Enable sites
ln -s /etc/nginx/sites-available/api.yourdomain.com /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/yourdomain.com /etc/nginx/sites-enabled/

# Test and reload
nginx -t
systemctl reload nginx
```

### 5.2 Setup SSL Certificates
```bash
# Get SSL for API
certbot --nginx -d api.yourdomain.com

# Get SSL for Frontend
certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Auto-renewal
certbot renew --dry-run
```

---

## Part 6: Security & Firewall

```bash
# Install UFW firewall
apt install ufw -y

# Configure firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Install fail2ban
apt install fail2ban -y
systemctl enable fail2ban
systemctl start fail2ban
```

---

## Part 7: Monitoring & Maintenance

### 7.1 Setup Monitoring
```bash
# Install monitoring tools
apt install htop ncdu -y

# Create backup script
cat > /opt/shopmanagement/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/shopmanagement/backups"
mkdir -p $BACKUP_DIR

# Backup database
PGPASSWORD="YourStrongPassword123!" pg_dump -h your-db-host.hetzner.com -U shopuser -d shop_management_db > $BACKUP_DIR/db_backup_$DATE.sql

# Backup uploads
tar -czf $BACKUP_DIR/uploads_backup_$DATE.tar.gz /opt/shopmanagement/uploads

# Keep only last 7 days
find $BACKUP_DIR -type f -mtime +7 -delete
EOF

chmod +x /opt/shopmanagement/backup.sh

# Add to crontab
echo "0 2 * * * /opt/shopmanagement/backup.sh" | crontab -
```

### 7.2 View Logs
```bash
# Backend logs
tail -f /var/log/shopmanagement/backend.log

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# System logs
journalctl -u shopmanagement-backend -f
```

---

## Part 8: Health Checks

```bash
# Check services
systemctl status shopmanagement-backend
systemctl status nginx

# Check API
curl https://api.yourdomain.com/actuator/health

# Check database connection
psql -h your-db-host.hetzner.com -U shopuser -d shop_management_db -c "SELECT 1"

# Check disk space
df -h

# Check memory
free -m
```

---

## Part 9: Update Deployment

When updating the application:

```bash
# 1. Build new JAR locally
mvn clean package -DskipTests -Pprod

# 2. Transfer to server
scp target/shop-management-backend-1.0.0.jar root@your-server-ip:/opt/shopmanagement/backend/app-new.jar

# 3. On server - backup old version
mv /opt/shopmanagement/backend/shop-management-backend-1.0.0.jar /opt/shopmanagement/backend/app-backup.jar

# 4. Replace with new version
mv /opt/shopmanagement/backend/app-new.jar /opt/shopmanagement/backend/shop-management-backend-1.0.0.jar

# 5. Restart service
systemctl restart shopmanagement-backend

# 6. Check logs
tail -f /var/log/shopmanagement/backend.log
```

---

## Environment Variables Summary

Replace these with your actual values:
- `your-db-host.hetzner.com` - Your PostgreSQL host
- `YourStrongPassword123!` - Database password
- `your-server-ip` - Your Hetzner server IP
- `yourdomain.com` - Your domain name
- `your-production-secret-key-change-this` - JWT secret key

---

## Troubleshooting

### Backend won't start
```bash
# Check logs
journalctl -u shopmanagement-backend -n 100
# Check database connection
telnet your-db-host.hetzner.com 5432
```

### Frontend 404 errors
```bash
# Check nginx config
nginx -t
# Check file permissions
ls -la /opt/shopmanagement/frontend
```

### Database connection issues
```bash
# Test connection
psql -h your-db-host.hetzner.com -U shopuser -d shop_management_db
# Check firewall on database server
```

---

## Support Contacts
- Database Issues: Check Hetzner PostgreSQL logs
- Server Issues: Check systemd logs with journalctl
- Application Issues: Check /var/log/shopmanagement/

---

**Note:** Remember to change all default passwords and secret keys before deploying to production!