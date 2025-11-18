# Application Configuration Guide

## ✅ Single Configuration File

We now use **ONE** unified configuration file instead of separate dev/production files.

### File Structure:
```
backend/src/main/resources/
└── application.yml          ✅ Single file with production defaults
    ├── (REMOVED) application-production.yml  ❌ No longer needed
```

---

## 🎯 How It Works

### Production (Default):
The `application.yml` file contains production-ready defaults:
- JPA DDL: `validate` (safe for production)
- Show SQL: `false` (production logging)
- File paths: `/opt/shop-management/uploads` (production server)
- Frontend URL: `https://nammaoorudelivary.in`
- JWT Secret: **Required from environment variable**

### Local Development:
Override production defaults using environment variables:

```bash
# Development Environment Variables
JPA_DDL_AUTO=update                              # Auto-update DB schema
JPA_SHOW_SQL=true                                # Show SQL in logs
HIBERNATE_FORMAT_SQL=true                        # Format SQL output
FILE_UPLOAD_PATH=D:/AAWS/nammaooru/uploads      # Local file path
APP_UPLOAD_DIR=D:/AAWS/nammaooru/uploads        # Local upload directory
FRONTEND_BASE_URL=http://localhost:4200          # Local frontend URL
JWT_SECRET=mySecretKey123456789012345678901234567890  # Dev JWT secret
LOG_LEVEL_APP=DEBUG                              # Enable debug logs
```

---

## 🔧 Setting Environment Variables

### IntelliJ IDEA:
1. Edit Run Configuration
2. Environment Variables → Add:
   ```
   JPA_DDL_AUTO=update;JPA_SHOW_SQL=true;FILE_UPLOAD_PATH=D:/AAWS/nammaooru/uploads
   ```

### Eclipse:
1. Run → Run Configurations
2. Environment tab → Add variables

### VS Code:
Create `.vscode/launch.json`:
```json
{
  "configurations": [
    {
      "type": "java",
      "name": "Spring Boot",
      "env": {
        "JPA_DDL_AUTO": "update",
        "JPA_SHOW_SQL": "true",
        "FILE_UPLOAD_PATH": "D:/AAWS/nammaooru/uploads"
      }
    }
  ]
}
```

### Command Line:
```bash
# Linux/Mac
export JPA_DDL_AUTO=update
export JPA_SHOW_SQL=true
mvn spring-boot:run

# Windows (PowerShell)
$env:JPA_DDL_AUTO="update"
$env:JPA_SHOW_SQL="true"
mvn spring-boot:run

# Windows (CMD)
set JPA_DDL_AUTO=update
set JPA_SHOW_SQL=true
mvn spring-boot:run
```

---

## 📋 Common Environment Variables

| Variable | Production Default | Development Override |
|----------|-------------------|---------------------|
| `JPA_DDL_AUTO` | `validate` | `update` |
| `JPA_SHOW_SQL` | `false` | `true` |
| `HIBERNATE_FORMAT_SQL` | `false` | `true` |
| `FILE_UPLOAD_PATH` | `/opt/shop-management/uploads` | `D:/AAWS/nammaooru/uploads` |
| `APP_UPLOAD_DIR` | `/opt/shop-management/uploads` | `D:/AAWS/nammaooru/uploads` |
| `FRONTEND_BASE_URL` | `https://nammaoorudelivary.in` | `http://localhost:4200` |
| `LOG_LEVEL_APP` | `WARN` | `DEBUG` or `INFO` |
| `SERVER_COMPRESSION_ENABLED` | `true` | `false` (optional) |

---

## ✅ Benefits of Single Configuration

1. **No Sync Issues** - One file means no forgetting to update the other
2. **Production Ready** - Defaults are safe for production
3. **Easy Development** - Just set env vars for local dev
4. **Clear Overrides** - Environment variables show what's different
5. **Docker Friendly** - Works seamlessly with Docker Compose

---

## 🚨 Important Notes

### JWT Secret:
- **Production**: MUST set `JWT_SECRET` environment variable (no default!)
- **Development**: Can use default or set your own

### Database Password:
- **Production**: MUST set `DB_PASSWORD` environment variable
- **Development**: Defaults to `postgres` (change if needed)

### File Upload Paths:
- **Production**: Uses `/opt/shop-management/uploads`
- **Development**: Override with Windows paths like `D:/AAWS/...`

---

## 🔍 Verifying Configuration

Start your application and check the logs for:
```
JPA DDL Auto: validate/update
Show SQL: true/false
File Upload Path: /opt/.../uploads or D:/AAWS/.../uploads
```

---

## 🆘 Troubleshooting

### Problem: Application uses production DB in development
**Solution**: Set `DB_URL` environment variable to your local database

### Problem: Files uploaded to wrong directory
**Solution**: Set `FILE_UPLOAD_PATH` and `APP_UPLOAD_DIR` to your local path

### Problem: JWT authentication fails
**Solution**: Set `JWT_SECRET` environment variable (minimum 32 characters)

### Problem: Database schema not updating in development
**Solution**: Set `JPA_DDL_AUTO=update` environment variable

---

## 📚 Related Files

- **Docker Compose**: `docker-compose.yml` - Container environment variables
- **Documentation**: `deployment-automation/configs/COMPOSE-FILES-INFO.md`
- **Deployment Scripts**: `deployment-automation/scripts/`

---

**Remember**: Production defaults are safe. Override only what you need for local development!
