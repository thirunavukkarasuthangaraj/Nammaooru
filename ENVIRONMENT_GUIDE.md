# Environment Configuration Guide

## 🏠 Local Development (Your PC)

### Option 1: Use YOUR Local PostgreSQL
```bash
# Use your existing PostgreSQL installation
docker-compose -f docker-compose.local.yml --env-file .env.local up -d

# This starts:
# - Backend (connects to YOUR PostgreSQL on localhost:5432)
# - Frontend
# - Redis
```

### Option 2: Use Docker PostgreSQL
```bash
# Everything in Docker containers
docker-compose --env-file .env.docker up -d

# This starts:
# - PostgreSQL (in Docker on port 5433)
# - Backend
# - Frontend
# - Redis
```

## 🚀 Production (Server)

```bash
# On server (65.21.4.236)
cd /opt/shop-management
docker-compose --env-file .env.prod up -d

# Or use the deployment script
./NEVER_WASTE_TIME_DEPLOY.sh
```

## 📋 Environment Files

| File | Purpose | Database | Use When |
|------|---------|----------|----------|
| `.env.local` | Local development | YOUR PostgreSQL (port 5432) | Developing with your existing PostgreSQL |
| `.env.docker` | Docker development | Docker PostgreSQL (port 5433) | Testing full Docker setup locally |
| `.env.prod` | Production server | Docker PostgreSQL (port 5432) | Deployed on server |

## 🔧 Quick Commands

### Start Local Development (Your PostgreSQL)
```bash
# Windows PowerShell
docker-compose -f docker-compose.local.yml --env-file .env.local up -d

# Access
# Frontend: http://localhost:8080
# Backend: http://localhost:8082
# Database: pgAdmin4 (your local)
```

### Start Docker Development (All in Docker)
```bash
# Windows PowerShell
docker-compose --env-file .env.docker up -d

# Access
# Frontend: http://localhost:8080
# Backend: http://localhost:8082
# Database: localhost:5433 (Docker PostgreSQL)
```

### Stop Everything
```bash
docker-compose down
```

## 🔑 Important Notes

1. **Update .env.local** with YOUR PostgreSQL password
2. **Never commit** .env files with real passwords
3. **Server uses** .env.prod with secure passwords
4. **Local uses** .env.local with your local credentials

## 📊 Database Setup

### For Local PostgreSQL (pgAdmin4)
1. Create database: `shop_management_db`
2. Run: `database/schema.sql`
3. Run: `database/init-data.sql`

### For Docker PostgreSQL
- Automatically initialized from `database/` folder

## 🧪 Test Your Setup

```bash
# Check containers
docker ps

# Test backend
curl http://localhost:8082/actuator/health

# Login credentials
Username: superadmin
Password: password
```