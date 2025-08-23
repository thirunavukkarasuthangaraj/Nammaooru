# 🚀 Deployment Instructions for NammaOoru Platform

## Prerequisites
- Docker and Docker Compose installed
- Git installed
- Domain configured (nammaoorudelivary.in)

## 📋 Step-by-Step Deployment on Ubuntu Server

### 1. Clone/Update Repository
```bash
# Navigate to deployment directory
cd /opt/shop-management

# Pull latest changes
git pull origin main
```

### 2. Create Environment File
Create `.env` file with your configuration:

```bash
cat > .env << 'EOF'
# Database Configuration
POSTGRES_DB=shop_management_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password_here

# Redis Configuration
REDIS_PASSWORD=your_redis_password_here

# Spring Boot Configuration
SPRING_PROFILES_ACTIVE=docker
JWT_SECRET=your-256-bit-secret-key-for-jwt-token-generation

# Build Configuration
BUILD_ID=latest
EOF
```

### 3. Build and Start Services

```bash
# Stop any running containers
docker-compose down

# Remove old images (optional, for clean build)
docker system prune -f

# Build fresh images
docker-compose build --no-cache

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### 4. Initialize Database (First Time Only)

If database is not initialized, run:

```bash
# Access postgres container
docker exec -it shop-postgres psql -U postgres -d shop_management_db

# Run initial schema (if needed)
\i /docker-entrypoint-initdb.d/schema.sql
\q
```

### 5. Verify Services

Check if services are running:

```bash
# Check all containers
docker ps

# Test backend health
curl http://localhost:8082/actuator/health

# Test frontend
curl http://localhost:8080

# Test database connection
docker exec shop-postgres pg_isready -U postgres
```

### 6. Configure Nginx (For Production)

Create nginx configuration:

```bash
sudo nano /etc/nginx/sites-available/nammaooru

# Add this configuration:
server {
    listen 80;
    server_name nammaoorudelivary.in www.nammaoorudelivary.in;

    # Frontend
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:8082;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Enable the site
sudo ln -s /etc/nginx/sites-available/nammaooru /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 7. Setup SSL with Let's Encrypt

```bash
# Install certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d nammaoorudelivary.in -d www.nammaoorudelivary.in

# Auto-renewal
sudo systemctl status certbot.timer
```

### 8. Service Management Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart specific service
docker-compose restart backend
docker-compose restart frontend

# View logs
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f postgres

# Scale services (if needed)
docker-compose up -d --scale backend=2

# Update and restart
git pull origin main
docker-compose build
docker-compose up -d
```

### 9. Monitoring and Maintenance

```bash
# Check disk usage
df -h

# Check memory usage
free -m

# Monitor containers
docker stats

# Clean up unused images
docker system prune -a

# Backup database
docker exec shop-postgres pg_dump -U postgres shop_management_db > backup_$(date +%Y%m%d).sql

# Restore database
docker exec -i shop-postgres psql -U postgres shop_management_db < backup.sql
```

## 🔧 Troubleshooting

### If containers won't start:
```bash
# Check logs
docker-compose logs

# Check specific service
docker-compose logs backend
docker-compose logs postgres

# Rebuild specific service
docker-compose build --no-cache backend
docker-compose up -d backend
```

### If database connection fails:
```bash
# Check postgres is running
docker ps | grep postgres

# Test connection
docker exec shop-postgres psql -U postgres -c "SELECT 1"

# Check network
docker network ls
docker network inspect shop-management_shop-network
```

### If frontend shows API errors:
```bash
# Check backend is running
curl http://localhost:8082/api/health

# Check CORS configuration
docker exec backend env | grep CORS

# Restart backend
docker-compose restart backend
```

## 📊 Service Ports

- Frontend: http://localhost:8080
- Backend API: http://localhost:8082
- PostgreSQL: localhost:5432
- Redis: localhost:6379

## 🔐 Security Notes

1. Always use strong passwords in production
2. Keep `.env` file secure (chmod 600 .env)
3. Regularly update Docker images
4. Enable firewall (ufw) and only allow necessary ports
5. Use SSL certificates in production
6. Regular backups of database

## 📱 Mobile App Configuration

For mobile app to connect to production server:

1. Update `mobile/nammaooru_mobile_app/lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = 'https://nammaoorudelivary.in/api';
```

2. Rebuild mobile app for production.

## ✅ Post-Deployment Checklist

- [ ] All containers running (`docker-compose ps`)
- [ ] Backend health check passing
- [ ] Frontend accessible
- [ ] Database connected
- [ ] SSL certificate installed
- [ ] Nginx configured
- [ ] Firewall configured
- [ ] Backups scheduled
- [ ] Monitoring setup
- [ ] Mobile app API URL updated

## 🆘 Support

For issues, check:
1. Docker logs: `docker-compose logs -f`
2. System logs: `journalctl -xe`
3. Nginx logs: `/var/log/nginx/error.log`