# Production Credentials & Configuration

⚠️ **IMPORTANT**: This file contains sensitive information. Never commit to Git!

## Database Configuration (PostgreSQL)

```bash
# Production Database (External - not in Docker)
DB_URL=jdbc:postgresql://localhost:5432/shop_management_db
DB_USERNAME=postgres
DB_PASSWORD=postgres  # CHANGE THIS IN PRODUCTION!

# For Docker containers to connect to host PostgreSQL
# Use: jdbc:postgresql://host.docker.internal:5432/shop_management_db
```

## Email Configuration (Gmail)

```bash
# Gmail Account
EMAIL_FROM_ADDRESS=noreplaynammaoorudelivery@gmail.com
EMAIL_PASSWORD=YOUR_NEW_APP_PASSWORD_HERE  # NEEDS TO BE UPDATED!

# To generate Gmail App Password:
# 1. Go to https://myaccount.google.com/security
# 2. Enable 2-Step Verification
# 3. Click "App passwords"
# 4. Generate password for "Mail"
```

## JWT Security

```bash
# JWT Secret (Generate a secure 256-bit key)
JWT_SECRET=mySecretKey123456789012345678901234567890  # CHANGE IN PRODUCTION!

# Generate secure JWT secret:
# openssl rand -base64 32
```

## Server Details

```bash
# Hetzner VPS
SERVER_HOST=65.21.4.236
SERVER_USER=root
SERVER_PORT=22

# Application URLs
FRONTEND_URL=http://65.21.4.236
BACKEND_URL=http://65.21.4.236:8082
DOMAIN=nammaoorudelivary.in
```

## Docker Hub

```bash
DOCKER_REGISTRY=docker.io
DOCKER_USERNAME=nammaooru  # Create Docker Hub account
DOCKER_PASSWORD=your_docker_password
```

## Application Ports

```bash
# Backend
BACKEND_PORT=8082

# Frontend
FRONTEND_PORT=80
FRONTEND_SSL_PORT=443

# PostgreSQL (External)
POSTGRES_PORT=5432
```

## CORS Configuration

```bash
CORS_ALLOWED_ORIGINS=http://localhost:4200,http://65.21.4.236,https://nammaoorudelivary.in,https://www.nammaoorudelivary.in
CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
CORS_ALLOWED_HEADERS=*
CORS_ALLOW_CREDENTIALS=true
```

## Production Environment File (.env.production)

Create this file on the server at `/root/nammaooru/.env.production`:

```bash
# Database
DB_URL=jdbc:postgresql://localhost:5432/shop_management_db
DB_USERNAME=postgres
DB_PASSWORD=your_secure_password_here

# JWT
JWT_SECRET=generate_32_character_secure_key_here

# Email
EMAIL_FROM_ADDRESS=noreplaynammaoorudelivery@gmail.com
EMAIL_PASSWORD=your_gmail_app_password_16_chars

# Server
SERVER_HOST=65.21.4.236
SPRING_PROFILES_ACTIVE=production

# File Upload
FILE_UPLOAD_PATH=/app/uploads

# Docker
DOCKER_REGISTRY=docker.io
DOCKER_USERNAME=nammaooru
DOCKER_PASSWORD=your_docker_hub_password
```

## GitHub Secrets (for CI/CD)

Add these in GitHub repository settings → Secrets:

```yaml
DOCKER_USERNAME: nammaooru
DOCKER_PASSWORD: your_docker_hub_password
SERVER_SSH_KEY: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  your_private_ssh_key_here
  -----END OPENSSH PRIVATE KEY-----
```

## Production Deployment Commands

```bash
# On Server - Set up environment
cd /root/nammaooru
cp .env.example .env.production
# Edit .env.production with actual values
nano .env.production

# Load environment variables
export $(cat .env.production | xargs)

# Deploy with Docker Compose
docker-compose --env-file .env.production up -d

# View logs
docker-compose logs -f backend
docker-compose logs -f frontend
```

## Security Checklist

- [ ] Change default PostgreSQL password
- [ ] Generate secure JWT secret (32+ characters)
- [ ] Set up Gmail App Password
- [ ] Configure firewall (ufw)
- [ ] Set up SSL certificates
- [ ] Enable fail2ban
- [ ] Regular backups configured
- [ ] Monitor disk space
- [ ] Set up log rotation

## Test Credentials (Development Only)

```bash
# Super Admin
Username: superadmin
Password: password  # BCrypt: $2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi

# Shop Owner
Username: shopowner1
Password: password

# Customer
Username: customer1
Password: password
```

## Backup Commands

```bash
# Backup Database
pg_dump -U postgres shop_management_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup Uploads
tar -czf uploads_backup_$(date +%Y%m%d).tar.gz /app/uploads

# Restore Database
psql -U postgres shop_management_db < backup.sql
```

## Monitoring URLs

```bash
# Health Check
curl http://65.21.4.236:8082/actuator/health

# Application Status
http://65.21.4.236 - Frontend
http://65.21.4.236:8082 - Backend API
http://65.21.4.236:8082/swagger-ui.html - API Documentation
```

## Important Notes

1. **NEVER** commit this file to Git
2. **ALWAYS** use environment variables for secrets
3. **CHANGE** all default passwords before production
4. **ENABLE** SSL/HTTPS for production domain
5. **BACKUP** database regularly
6. **MONITOR** server resources and logs
7. **UPDATE** dependencies regularly for security patches