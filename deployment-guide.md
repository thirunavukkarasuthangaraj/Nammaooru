# Production Deployment Guide

## Configuration for Production Deployment

### 1. Backend Configuration

#### PostgreSQL Database (External - Not in Docker)
1. Install PostgreSQL on your server or use a managed service (AWS RDS, Google Cloud SQL, etc.)
2. Create database:
```sql
CREATE DATABASE shop_management_db;
```

#### Application Configuration
1. Use the production profile when running the application:
```bash
java -jar -Dspring.profiles.active=prod shop-management-system.jar
```

2. Set environment variables:
```bash
export DB_URL=jdbc:postgresql://your-postgres-host:5432/shop_management_db
export DB_USERNAME=your_db_username
export DB_PASSWORD=your_db_password
export JWT_SECRET=your_secure_jwt_secret_key
export MAIL_PASSWORD=your_email_app_password
```

### 2. Frontend Configuration

The production environment is configured in `frontend/src/environments/environment.prod.ts`:
- API URL: `https://api.nammaoorudelivary.in/api`
- WebSocket URL: `wss://api.nammaoorudelivary.in/ws`

Build for production:
```bash
cd frontend
npm run build --prod
```

### 3. Mobile App Configuration

For production, use `app_constants_prod.dart`:
- API URL: `https://api.nammaoorudelivary.in/api`

Build for production:
```bash
flutter build apk --release
flutter build ios --release
```

### 4. NGINX Configuration (Reverse Proxy with SSL)

```nginx
server {
    listen 443 ssl http2;
    server_name api.nammaoorudelivary.in;

    ssl_certificate /etc/letsencrypt/live/api.nammaoorudelivary.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.nammaoorudelivary.in/privkey.pem;

    location /api {
        proxy_pass http://localhost:8082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ws {
        proxy_pass http://localhost:8082;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

server {
    listen 443 ssl http2;
    server_name nammaoorudelivary.in www.nammaoorudelivary.in;

    ssl_certificate /etc/letsencrypt/live/nammaoorudelivary.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nammaoorudelivary.in/privkey.pem;

    root /var/www/shop-management/frontend;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /uploads {
        alias /var/www/shop-management/uploads;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name nammaoorudelivary.in www.nammaoorudelivary.in api.nammaoorudelivary.in;
    return 301 https://$server_name$request_uri;
}
```

### 5. SSL Certificate Setup (Let's Encrypt)

```bash
# Install certbot
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d nammaoorudelivary.in -d www.nammaoorudelivary.in -d api.nammaoorudelivary.in

# Auto-renewal
sudo certbot renew --dry-run
```

### 6. System Service Setup (systemd)

Create `/etc/systemd/system/shop-management.service`:
```ini
[Unit]
Description=Shop Management System
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/shop-management
ExecStart=/usr/bin/java -Xmx512m -Dspring.profiles.active=prod -jar shop-management-system.jar
Restart=on-failure
RestartSec=10
EnvironmentFile=/var/www/shop-management/.env

[Install]
WantedBy=multi-user.target
```

Start the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable shop-management
sudo systemctl start shop-management
sudo systemctl status shop-management
```

### 7. Directory Structure on Server

```
/var/www/shop-management/
├── shop-management-system.jar
├── .env (production environment variables)
├── uploads/
│   ├── products/
│   └── documents/
│       └── shops/
├── frontend/ (built Angular files)
└── logs/
    └── shop-management.log
```

### 8. Production Database Backup

Set up automated backups:
```bash
# Create backup script
cat > /home/user/backup-db.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/postgres"
DB_NAME="shop_management_db"
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump -h localhost -U your_db_username $DB_NAME > $BACKUP_DIR/backup_$DATE.sql
# Keep only last 7 days of backups
find $BACKUP_DIR -name "backup_*.sql" -mtime +7 -delete
EOF

# Add to crontab (daily at 2 AM)
0 2 * * * /home/user/backup-db.sh
```

### 9. Monitoring

Install monitoring tools:
```bash
# Application monitoring
sudo apt-get install htop
sudo apt-get install nethogs

# Log monitoring
sudo apt-get install logwatch

# Database monitoring
sudo apt-get install pgadmin4
```

### 10. Security Checklist

- [ ] Change default passwords
- [ ] Set up firewall (ufw)
- [ ] Configure fail2ban
- [ ] Enable database SSL connections
- [ ] Set up log rotation
- [ ] Regular security updates
- [ ] Backup verification
- [ ] Monitor disk space
- [ ] Set up alerting

### Important URLs

- Frontend: https://nammaoorudelivary.in
- API: https://api.nammaoorudelivary.in/api
- WebSocket: wss://api.nammaoorudelivary.in/ws

### Environment Variables Required

Create `.env` file on production server:
```bash
DB_URL=jdbc:postgresql://localhost:5432/shop_management_db
DB_USERNAME=your_db_username
DB_PASSWORD=your_db_password
JWT_SECRET=your_secure_256_bit_jwt_secret
MAIL_PASSWORD=your_email_app_password
```