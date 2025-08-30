# NammaOoru CI/CD Deployment Guide

## Overview
Complete CI/CD pipeline for automatic deployment when code is pushed to GitHub.

## Architecture
- **Backend**: Spring Boot (Port 8082)
- **Frontend**: Angular (Port 80)
- **Database**: PostgreSQL (External - not in Docker)
- **Server**: Hetzner VPS (65.21.4.236)

## Prerequisites

### 1. GitHub Repository Setup
- Repository should be public or have Docker Hub access
- Main branch should be protected

### 2. Docker Hub Account
- Create account at https://hub.docker.com
- Create repositories:
  - `nammaooru/backend`
  - `nammaooru/frontend`

### 3. Server Requirements
- Ubuntu 20.04+ or similar Linux
- Docker and Docker Compose installed
- PostgreSQL installed locally (not in Docker)
- Ports 80, 443, 8082 open

## Setup Instructions

### Step 1: Configure GitHub Secrets
Go to your GitHub repository → Settings → Secrets and add:

```
DOCKER_USERNAME     - Your Docker Hub username
DOCKER_PASSWORD     - Your Docker Hub password
SERVER_SSH_KEY      - Private SSH key for server access
```

### Step 2: Configure Environment Variables
1. Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

2. Update `.env` with your values:
```env
# Database (External PostgreSQL)
DB_URL=jdbc:postgresql://localhost:5432/shop_management_db
DB_USERNAME=postgres
DB_PASSWORD=your_actual_password

# JWT Secret (generate a secure key)
JWT_SECRET=your_32_character_secret_key_here

# Email (Gmail App Password)
EMAIL_PASSWORD=your_gmail_app_password
```

### Step 3: Server Setup
SSH into your server and run:

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create deployment directory
mkdir -p /root/nammaooru
cd /root/nammaooru

# Clone repository (or copy docker-compose.yml)
git clone https://github.com/yourusername/shop-management-system.git .
```

### Step 4: Database Setup
Since PostgreSQL is external (not in Docker):

```bash
# Install PostgreSQL if not already installed
sudo apt update
sudo apt install postgresql postgresql-contrib

# Create database
sudo -u postgres psql
CREATE DATABASE shop_management_db;
ALTER USER postgres PASSWORD 'your_password';
\q

# Allow Docker containers to connect
# Edit /etc/postgresql/14/main/postgresql.conf
listen_addresses = '*'

# Edit /etc/postgresql/14/main/pg_hba.conf
# Add: host all all 172.0.0.0/8 md5

# Restart PostgreSQL
sudo systemctl restart postgresql
```

## Deployment Process

### Automatic Deployment (CI/CD)
1. Make changes to your code
2. Commit and push to main branch:
```bash
git add .
git commit -m "Your changes"
git push origin main
```

3. GitHub Actions will automatically:
   - Build Docker images
   - Push to Docker Hub
   - Deploy to server
   - Run health checks

### Manual Deployment
```bash
# On your local machine
./deploy.sh

# Or on the server
cd /root/nammaooru
docker-compose pull
docker-compose up -d
```

## Monitoring

### Check Application Status
```bash
# View running containers
docker ps

# Check backend health
curl http://localhost:8082/actuator/health

# View logs
docker-compose logs -f backend
docker-compose logs -f frontend
```

### View GitHub Actions
- Go to GitHub → Actions tab
- Monitor deployment progress
- Check for any errors

## Troubleshooting

### Backend Not Starting
```bash
# Check logs
docker-compose logs backend

# Common issues:
# 1. Database connection - verify PostgreSQL is running
# 2. Port already in use - kill existing process
# 3. Email config - check Gmail app password
```

### Frontend Not Accessible
```bash
# Check nginx config
docker exec frontend nginx -t

# Restart frontend
docker-compose restart frontend
```

### Database Connection Issues
```bash
# Test connection from Docker
docker run --rm -it postgres:15 psql -h host.docker.internal -U postgres -d shop_management_db

# Check PostgreSQL logs
sudo journalctl -u postgresql
```

## Email Configuration

### Generate Gmail App Password
1. Go to https://myaccount.google.com/security
2. Enable 2-Step Verification
3. Generate App Password for "Mail"
4. Update in `.env` file

### Fix Email Issues
```bash
# Update application.yml
EMAIL_PASSWORD=new_app_password_here

# Restart backend
docker-compose restart backend
```

## Security Considerations

1. **Never commit secrets** - Use environment variables
2. **Use strong passwords** - Especially for database and JWT
3. **Enable firewall** - Only allow necessary ports
4. **Regular updates** - Keep Docker and dependencies updated
5. **HTTPS** - Use SSL certificates for production

## Rollback Process

If deployment fails:
```bash
# Rollback to previous version
docker-compose down
docker pull nammaooru/backend:previous-tag
docker pull nammaooru/frontend:previous-tag
docker-compose up -d
```

## Maintenance

### Backup Database
```bash
# Create backup
pg_dump -U postgres shop_management_db > backup_$(date +%Y%m%d).sql

# Restore backup
psql -U postgres shop_management_db < backup_20240830.sql
```

### Update Dependencies
```bash
# Pull latest images
docker-compose pull

# Rebuild with no cache
docker-compose build --no-cache

# Clean up old images
docker system prune -a
```

## Support

For issues:
1. Check logs: `docker-compose logs`
2. Check GitHub Actions tab
3. Verify environment variables
4. Test database connection
5. Check server resources: `df -h`, `free -m`

## Quick Commands

```bash
# Deploy
./deploy.sh

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop everything
docker-compose down

# Clean everything
docker system prune -a --volumes
```