# 🔐 Complete Credentials Summary for Production

## 📋 Current Credentials Status

### ✅ Database (PostgreSQL)
- **Status**: External (not in Docker)
- **Host**: localhost (from Docker: host.docker.internal)
- **Port**: 5432
- **Database**: shop_management_db
- **Username**: postgres
- **Password**: postgres ⚠️ **MUST CHANGE IN PRODUCTION**

### ❌ Email (Gmail) - NEEDS UPDATE
- **Account**: noreplaynammaoorudelivery@gmail.com
- **App Password**: YOUR_NEW_APP_PASSWORD_HERE ❌ **NOT SET**
- **Action Required**: Generate Gmail App Password

### ⚠️ JWT Security
- **Current Secret**: mySecretKey123456789012345678901234567890
- **Status**: Default key - **MUST CHANGE IN PRODUCTION**
- **Recommendation**: Generate 256-bit secure key

### 🌐 Server Details
- **IP**: 65.21.4.236
- **Domain**: nammaoorudelivary.in
- **Frontend Port**: 80
- **Backend Port**: 8082
- **User**: root

## 🚨 IMMEDIATE ACTIONS REQUIRED

### 1. Generate Gmail App Password
```bash
# Steps:
1. Go to https://myaccount.google.com/security
2. Enable 2-Step Verification
3. Click "App passwords"
4. Generate password for "Mail"
5. Copy the 16-character password
6. Update in .env.production: EMAIL_PASSWORD=xxxx xxxx xxxx xxxx
```

### 2. Generate Secure JWT Secret
```bash
# Generate secure key:
openssl rand -base64 32

# Or use this Python command:
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Update in .env.production: JWT_SECRET=generated_key_here
```

### 3. Change Database Password
```bash
# On production server:
sudo -u postgres psql
ALTER USER postgres PASSWORD 'new_secure_password';
\q

# Update in .env.production: DB_PASSWORD=new_secure_password
```

## 📝 Files to Update

### 1. `.env.production` (Main configuration)
```env
# Database
DB_PASSWORD=your_new_secure_password

# JWT
JWT_SECRET=your_generated_32_char_key

# Email
EMAIL_PASSWORD=your_gmail_app_password

# Docker Hub
DOCKER_USERNAME=your_docker_username
DOCKER_PASSWORD=your_docker_password
```

### 2. `backend/src/main/resources/application.yml`
```yaml
spring:
  mail:
    password: YOUR_NEW_APP_PASSWORD_HERE  # Update this
```

### 3. GitHub Secrets (for CI/CD)
Go to GitHub → Settings → Secrets → Actions:
- `DOCKER_USERNAME`: Your Docker Hub username
- `DOCKER_PASSWORD`: Your Docker Hub password
- `SERVER_SSH_KEY`: Your server's SSH private key

## 🔄 Deployment Steps

### Step 1: Update Local Files
```bash
# Update .env.production with all credentials
nano .env.production

# Update application.yml with Gmail password
nano backend/src/main/resources/application.yml
```

### Step 2: Deploy to Production
```bash
# Make executable
chmod +x deploy-production.sh

# Run deployment
./deploy-production.sh
```

### Step 3: Verify on Server
```bash
# SSH to server
ssh root@65.21.4.236

# Check services
docker ps

# View logs
docker-compose logs -f backend
```

## 🔑 Test Users (After Deployment)

### Super Admin
- Username: `superadmin`
- Password: `password`
- BCrypt Hash: `$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi`

### Shop Owner
- Username: `shopowner1`
- Password: `password`

### Customer
- Username: `customer1`
- Password: `password`

## 📊 Verification URLs

After deployment, verify these endpoints:

```bash
# Frontend
http://65.21.4.236

# Backend API
http://65.21.4.236:8082

# Health Check
http://65.21.4.236:8082/actuator/health

# API Documentation
http://65.21.4.236:8082/swagger-ui.html
```

## ⚠️ Security Checklist

- [ ] Changed PostgreSQL password from default
- [ ] Generated secure JWT secret (32+ characters)
- [ ] Set up Gmail App Password
- [ ] Updated .env.production with all credentials
- [ ] Removed default passwords from production
- [ ] Configured firewall (ufw) on server
- [ ] Set up SSL certificates for domain
- [ ] Enabled fail2ban for SSH protection
- [ ] Set up regular database backups
- [ ] Configured log rotation

## 🆘 Troubleshooting

### Email Not Sending
```bash
# Check logs for email errors
docker-compose logs backend | grep -i email

# Test email configuration
curl -X POST http://localhost:8082/api/email/test \
  -H "Content-Type: application/json" \
  -d '{"to": "test@example.com"}'
```

### Database Connection Issues
```bash
# Test PostgreSQL connection
psql -U postgres -h localhost -d shop_management_db

# Check if PostgreSQL is running
systemctl status postgresql
```

### JWT Token Issues
```bash
# Regenerate JWT secret
openssl rand -base64 32

# Update and restart
docker-compose restart backend
```

## 📌 Important Notes

1. **NEVER** commit credentials to Git
2. **ALWAYS** use environment variables
3. **CHANGE** all default passwords before production
4. **BACKUP** database before deployment
5. **TEST** in staging environment first
6. **MONITOR** logs after deployment

## 🚀 Quick Deploy Command

Once all credentials are updated:

```bash
# One-line deployment
./deploy-production.sh && ssh root@65.21.4.236 'docker-compose logs -f'
```

---

**Remember**: Update all credentials marked with ⚠️ or ❌ before deploying to production!