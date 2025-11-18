# Docker Compose Files - Production Setup

## ✅ Active File (USE THIS)

**`docker-compose.yml`** - Production deployment with zero downtime support

### Features:
- ✅ No fixed container names (allows scaling)
- ✅ Port ranges for multiple instances
- ✅ Labels for container identification
- ✅ Health checks configured
- ✅ Zero downtime deployment ready

### Usage:
```bash
# Deploy
docker-compose up -d

# Scale backend (for zero downtime)
docker-compose up -d --scale backend=2

# Deploy with zero downtime script
./deployment-automation/scripts/zero-downtime-deploy.sh
```

---

## 📦 Backup File (Reference Only)

**`docker-compose.yml.backup`** - Old production config

### Why it's backed up:
- ❌ Fixed container names (prevents scaling)
- ❌ Fixed ports (prevents multiple instances)
- ❌ Can't run zero downtime deployments

### Kept for reference only - DO NOT USE

---

## 🔧 Application Properties File

### Single Unified Configuration:

**`application.yml`** - Complete configuration with production defaults
- ✅ All settings in ONE file
- ✅ Production values as defaults
- ✅ Environment variables for customization
- ✅ No profile activation needed

### How It Works:

```
Spring Boot starts
    ↓
Loads: application.yml (production defaults)
    ↓
Reads: Environment variables (if set)
    ↓
Final config = Production defaults + Environment overrides
```

**Benefits:**
- ✅ Single source of truth - no sync issues
- ✅ Production-ready by default
- ✅ Easy to override for local development
- ✅ No SPRING_PROFILES_ACTIVE needed

### For Local Development:

Set environment variables to override production defaults:
```bash
JPA_DDL_AUTO=update
JPA_SHOW_SQL=true
FILE_UPLOAD_PATH=D:/AAWS/nammaooru/uploads
FRONTEND_BASE_URL=http://localhost:4200
```

---

## 🎯 Summary

| File | Status | Purpose |
|------|--------|---------|
| `docker-compose.yml` | ✅ **ACTIVE** | Production deployment (zero downtime) |
| `application.yml` | ✅ **ACTIVE** | Complete configuration (production defaults) |
| ~~`docker-compose.yml.backup`~~ | ❌ Removed | Old config (had fixed names) |
| ~~`application-production.yml`~~ | ❌ Removed | Merged into application.yml |

---

## 🚀 For Deployment:

**Active Files:**
- ✅ `docker-compose.yml` - Zero downtime deployment
- ✅ `application.yml` - Single unified configuration

**Removed Files (to avoid sync issues):**
- ❌ `docker-compose.yml.backup` - Had fixed container names
- ❌ `application-production.yml` - Merged into application.yml

**Key Changes:**
- No more `SPRING_PROFILES_ACTIVE` needed
- Production defaults in application.yml
- Override with environment variables for local dev
