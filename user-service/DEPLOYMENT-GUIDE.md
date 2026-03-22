# User Service Microservice - Complete Deployment Guide

## Overview

Extracted the User/Auth module from the monolithic Spring Boot app into a standalone microservice with its **own database** (`user_db`). The monolith remains unchanged and fully functional.

### Architecture

```
                    ┌─────────────────────────────────┐
                    │         OLD SERVER               │
                    │   Monolith (port 8080)           │
                    │   DB: shop_management_db         │
                    │   (Unchanged - still working)    │
                    └─────────────────────────────────┘

                    ┌─────────────────────────────────┐
                    │      NEW SERVER (Hetzner)        │
                    │      46.225.224.191              │
                    │                                  │
                    │   user-service (port 8081)       │
                    │   Docker container (512MB)       │
                    │          │                       │
                    │          ▼                       │
                    │   PostgreSQL (user_db)           │
                    │   (directly on server)           │
                    └─────────────────────────────────┘
```

### Tech Stack
- **Java 17** (Eclipse Temurin)
- **Spring Boot 3.2.0**
- **PostgreSQL** (on server, not Docker)
- **Docker** (for the app only)
- **Server:** Hetzner CAX11 (ARM64, 4GB RAM, Ubuntu, $3.99/month)

---

## Step-by-Step: What We Did

### Step 1: Created the `user-service` Spring Boot Project

Created a new Spring Boot project at `user-service/` inside the monolith repo.

**Files created:**

```
user-service/
├── pom.xml                          # Maven config (Spring Boot 3.2.0, Java 17)
├── Dockerfile                       # Multi-stage Docker build (ARM64 compatible)
├── .env.example                     # Environment variables template
├── setup-server.sh                  # Server setup script
├── nginx-microservice.conf.example  # Nginx routing example
│
└── src/main/
    ├── java/com/shopmanagement/userservice/
    │   ├── UserServiceApplication.java
    │   │
    │   ├── entity/
    │   │   ├── User.java
    │   │   ├── Permission.java
    │   │   ├── MobileOtp.java
    │   │   └── EmailOtp.java
    │   │
    │   ├── repository/
    │   │   ├── UserRepository.java
    │   │   ├── PermissionRepository.java
    │   │   ├── MobileOtpRepository.java
    │   │   └── EmailOtpRepository.java
    │   │
    │   ├── service/
    │   │   ├── AuthService.java        # Login, register, password reset
    │   │   ├── UserService.java        # CRUD, search, pagination
    │   │   ├── JwtService.java         # JWT token generation/validation
    │   │   ├── TokenBlacklistService.java  # In-memory token blacklist
    │   │   ├── MobileOtpService.java   # SMS OTP (adapted: removed CustomerRepository)
    │   │   ├── EmailOtpService.java    # Email OTP
    │   │   ├── SmsService.java         # SMS via MSG91 (simplified: user-related only)
    │   │   └── EmailService.java       # Emails (simplified: user/auth emails only)
    │   │
    │   ├── controller/
    │   │   ├── AuthController.java     # /api/auth/* endpoints
    │   │   ├── UserController.java     # /api/users/* endpoints
    │   │   ├── InternalUserController.java  # /internal/users/* (inter-service)
    │   │   └── VersionController.java  # /api/version (health check)
    │   │
    │   ├── config/
    │   │   ├── SecurityConfig.java     # Spring Security (simplified for user-service)
    │   │   ├── JwtAuthenticationFilter.java  # JWT filter (skips /internal/ paths)
    │   │   ├── WebConfig.java          # RestTemplate bean
    │   │   └── EmailProperties.java    # Email config properties
    │   │
    │   ├── dto/
    │   │   ├── auth/   (AuthRequest, AuthResponse, RegisterRequest, ChangePasswordRequest)
    │   │   ├── user/   (UserRequest, UserResponse, UserUpdateRequest)
    │   │   ├── mobile/ (MobileOtpRequest, MobileOtpVerificationRequest)
    │   │   └── internal/ (UserBasicDTO - for inter-service communication)
    │   │
    │   ├── common/
    │   │   ├── dto/ApiResponse.java
    │   │   ├── constants/ResponseConstants.java
    │   │   └── util/ResponseUtil.java
    │   │
    │   └── exception/
    │       ├── GlobalExceptionHandler.java
    │       └── AuthenticationFailedException.java
    │
    └── resources/
        ├── application.yml
        ├── db/migration/V1__create_user_tables.sql
        └── templates/
            ├── otp-verification.html
            ├── forgot-password-otp.html
            ├── user-welcome.html
            └── welcome-shop-owner.html
```

**Key adaptations from monolith:**
- `MobileOtpService`: Replaced `CustomerRepository` with `UserRepository` for `lookupUserEmail()`
- `SmsService`: Removed order/delivery/welcome SMS methods (not needed for user-service)
- `EmailService`: Simplified from 765 lines to only user/auth related emails
- `SecurityConfig`: Only permits `/api/auth/**`, `/api/public/**`, `/api/version`, `/internal/**`, `/actuator/**`
- `JwtAuthenticationFilter`: Added `/internal/` path skip
- `InternalUserController`: NEW - provides endpoints for other services to query user data

### Step 2: Created the Database (`user_db`)

**Tables owned by user-service:**
- `users` - all user data
- `permissions` - permission definitions
- `user_permissions` - user-permission mappings
- `driver_assigned_shops` - driver shop assignments
- `mobile_otps` - SMS OTP records
- `email_otps` - Email OTP records

SQL migration: `src/main/resources/db/migration/V1__create_user_tables.sql`

### Step 3: Created Hetzner Server

1. **Server:** Hetzner Cloud > CAX11 (ARM64, 4GB RAM, 40GB SSD)
2. **Location:** Nuremberg, Germany
3. **OS:** Ubuntu 24.04
4. **IP:** 46.225.224.191
5. **Cost:** ~$3.99/month

### Step 4: Server Setup

#### 4.1 SSH Access
```bash
# Hetzner initially set up with SSH key only
# Connected via Hetzner Console to set password:
passwd root

# Enabled password login:
nano /etc/ssh/sshd_config
# Changed: PermitRootLogin yes
systemctl restart ssh    # Note: Ubuntu uses 'ssh' not 'sshd'
```

#### 4.2 Install Docker
```bash
snap install docker
```

#### 4.3 Install PostgreSQL
```bash
apt update && apt install -y postgresql postgresql-contrib
systemctl start postgresql
systemctl enable postgresql
```

#### 4.4 Create Database
```bash
sudo -u postgres psql -c "CREATE DATABASE user_db;"
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
```

#### 4.5 Configure PostgreSQL for password auth
```bash
# Find pg_hba.conf
sudo -u postgres psql -t -c "SHOW hba_file;"

# Edit: change 'peer' to 'md5' for local connections
nano /etc/postgresql/16/main/pg_hba.conf

# Also allow remote connections (for pgAdmin from PC):
nano /etc/postgresql/16/main/postgresql.conf
# Set: listen_addresses = '*'

systemctl restart postgresql
```

#### 4.6 Firewall
```bash
ufw enable
ufw allow 22/tcp      # SSH
ufw allow 5432/tcp    # PostgreSQL (for remote pgAdmin)
ufw allow 8081/tcp    # user-service
```

### Step 5: Deploy the Code

#### 5.1 Copy code to server
```bash
# From your local PC:
scp -r user-service/* root@46.225.224.191:/opt/user-service/
```

**Note:** `scp -r` does NOT copy hidden files (like `.env`). Create `.env` manually on server.

#### 5.2 Create .env on server
```bash
nano /opt/user-service/.env
```

Content:
```env
DB_URL=jdbc:postgresql://localhost:5432/user_db
DB_USERNAME=postgres
DB_PASSWORD=postgres
JWT_SECRET=<same-as-monolith>
MAIL_HOST=smtp.hostinger.com
MAIL_PORT=587
MAIL_USERNAME=noreplay@nammaoorudelivary.in
MAIL_PASSWORD=<your-email-password>
MSG91_AUTH_KEY=<your-msg91-key>
MSG91_SENDER_ID=NAMMAO
MSG91_OTP_TEMPLATE_ID=<your-template-id>
MSG91_FORGOT_PASSWORD_TEMPLATE_ID=<your-template-id>
SMS_ENABLED=false
```

**Important:** `DB_URL` must use `localhost` (NOT `host.docker.internal`) because we use `--network host`.

#### 5.3 Create tables manually
```bash
# Flyway had baseline issue, so we created tables manually:
sudo -u postgres psql -d user_db -f /opt/user-service/src/main/resources/db/migration/V1__create_user_tables.sql
```

#### 5.4 Build Docker image
```bash
cd /opt/user-service
docker build --no-cache -t user-service .
```

#### 5.5 Run the container
```bash
docker run -d \
  --name user-service \
  --network host \
  --env-file /opt/user-service/.env \
  -m 512m \
  -e JAVA_OPTS="-Xms128m -Xmx384m" \
  user-service
```

#### 5.6 Verify
```bash
# Check container status
docker ps

# Check logs
docker logs -f user-service

# Test endpoint
curl http://localhost:8081/api/version
```

---

## Errors We Faced & How We Fixed Them

### Error 1: SSH Permission Denied
```
Permission denied (publickey,password)
```
**Cause:** Hetzner server was set up with SSH key only, no password.
**Fix:** Connected via Hetzner Console, ran `passwd root`, enabled `PermitRootLogin yes` in sshd_config, restarted `ssh` service.

### Error 2: Docker Image ARM64 Incompatible
```
eclipse-temurin:17-jre-alpine - no matching manifest for linux/arm64/v8
```
**Cause:** Alpine-based JRE image doesn't support ARM64 (Hetzner CAX11 is ARM).
**Fix:** Changed Dockerfile from `eclipse-temurin:17-jre-alpine` to `eclipse-temurin:17-jre-jammy` (Ubuntu-based). Also changed `apk add` to `apt-get install` and `addgroup/adduser` to `groupadd/useradd`.

### Error 3: Compilation Error - fullName not found
```
cannot find symbol: method fullName(java.lang.String) in UserBasicDTO.UserBasicDTOBuilder
```
**Cause:** `InternalUserController.mapToBasicDTO()` called `.fullName()` but `UserBasicDTO` only has `firstName` and `lastName` fields.
**Fix:** Removed `.fullName(user.getFullName())` from the builder in `InternalUserController.java`.

### Error 4: Database Connection Failed (host.docker.internal)
```
java.net.UnknownHostException: host.docker.internal
```
**Cause:** `.env` had `DB_URL=jdbc:postgresql://host.docker.internal:5432/user_db`. On Linux, `host.docker.internal` doesn't resolve (it's a Docker Desktop feature for Mac/Windows).
**Fix:** Changed to `DB_URL=jdbc:postgresql://localhost:5432/user_db` since we use `--network host`.

### Error 5: Flyway Migration Not Running (missing tables)
```
Schema-validation: missing table [driver_assigned_shops]
```
**Cause:** `baseline-on-migrate: true` with default `baseline-version: 1` caused Flyway to skip V1 migration (it thinks V1 is the baseline, not a migration to run).
**Fix:** Added `baseline-version: 0` to `application.yml`. Also ran the SQL migration manually as a quick fix:
```bash
sudo -u postgres psql -d user_db -f /opt/user-service/src/main/resources/db/migration/V1__create_user_tables.sql
```

### Error 6: Docker Build Cache Not Picking Up Changes
```
CACHED [build 5/6] COPY src ./src
```
**Cause:** Docker cached the old source files even after editing `application.yml` on the server.
**Fix:** Used `docker build --no-cache -t user-service .` to force rebuild.

### Error 7: 403 Forbidden on /api/version
```
HTTP/1.1 403
```
**Cause:** `/api/version` was not in Spring Security's `permitAll()` list.
**Fix:** Added `"/api/version"` to the `requestMatchers` in `SecurityConfig.java`.

### Error 8: Container OOM Killed (Exit Code 137)
```
Exited (137)
```
**Cause:** 256MB Docker memory limit was too small for Spring Boot + JVM.
**Fix:** Increased to 512MB with explicit JVM settings:
```bash
docker run -d -m 512m -e JAVA_OPTS="-Xms128m -Xmx384m" ...
```

---

## Useful Commands

### Server Management
```bash
# Check if running
docker ps

# View logs (follow)
docker logs -f user-service

# Restart
docker restart user-service

# Stop and remove
docker rm -f user-service

# Rebuild after code changes
docker build --no-cache -t user-service .

# Start again
docker run -d --name user-service --network host --env-file /opt/user-service/.env -m 512m -e JAVA_OPTS="-Xms128m -Xmx384m" user-service
```

### Database
```bash
# Connect to user_db
sudo -u postgres psql -d user_db

# List tables
sudo -u postgres psql -d user_db -c "\dt"

# Check users table
sudo -u postgres psql -d user_db -c "SELECT id, username, email, role FROM users;"
```

### Testing Endpoints
```bash
# Version check
curl http://localhost:8081/api/version

# Login
curl -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}'

# Register
curl -X POST http://localhost:8081/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@test.com","mobileNumber":"9876543210","password":"Test@123"}'
```

### pgAdmin Connection (from your PC)
- **Host:** 46.225.224.191
- **Port:** 5432
- **Database:** user_db
- **Username:** postgres
- **Password:** postgres

---

## API Endpoints

### Public (no auth needed)
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/api/version` | Service info |
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login |
| POST | `/api/auth/forgot-password` | Forgot password |
| POST | `/api/auth/reset-password` | Reset password |
| POST | `/api/auth/send-otp` | Send OTP |
| POST | `/api/auth/verify-otp` | Verify OTP |
| POST | `/api/auth/resend-otp` | Resend OTP |
| GET | `/actuator/health` | Health check |

### Protected (JWT required)
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/api/users` | List users (ADMIN only) |
| GET | `/api/users/{id}` | Get user by ID |
| PUT | `/api/users/{id}` | Update user |
| POST | `/api/auth/logout` | Logout |
| POST | `/api/auth/change-password` | Change password |
| GET | `/api/auth/validate` | Validate JWT token |

### Internal (service-to-service, no auth)
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/internal/users/{id}` | Get user by ID |
| GET | `/internal/users/by-email?email=` | Get user by email |
| GET | `/internal/users/by-username?username=` | Get user by username |
| GET | `/internal/users/by-mobile?mobileNumber=` | Get user by mobile |
| POST | `/internal/users/by-ids` | Get users by IDs (batch) |
| GET | `/internal/users/by-role?role=` | Get users by role |
| GET | `/internal/users/{id}/exists` | Check if user exists |
| POST | `/internal/users/create-shop-owner` | Create shop owner |

---

## When Done Learning

1. Go to Hetzner Console
2. Select the server (ubuntu-4gb-nbg1-5)
3. Click "Delete"
4. Your old monolith on the old server continues working unchanged
5. Cost stops immediately
