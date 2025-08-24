# Local Development Setup with Your PostgreSQL

## Prerequisites
- PostgreSQL installed locally (port 5432)
- pgAdmin4 (for database management)
- Docker Desktop
- Node.js and npm
- Java 17+

## Setup Steps

### 1. Create Database in Your Local PostgreSQL
Open pgAdmin4 and create:
```sql
CREATE DATABASE shop_management_db;
```

### 2. Run Database Scripts
In pgAdmin4, run these scripts in order:
1. `database/schema.sql` - Creates tables
2. `database/init-data.sql` - Initial data
3. `database/test-data.sql` - Test data (optional)

### 3. Configure Environment
Create `.env` file with your local PostgreSQL password:
```env
POSTGRES_DB=shop_management_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_local_postgres_password
REDIS_PASSWORD=Redis@2024Pass
JWT_SECRET=nammaooru-jwt-secret-key-2024-secure
```

### 4. Start Docker Containers (without PostgreSQL)
```bash
# Use the local compose file
docker-compose -f docker-compose.local.yml up -d

# This starts:
# - backend (connects to your local PostgreSQL)
# - frontend
# - redis
```

### 5. Access Application
- Frontend: http://localhost:8080
- Backend API: http://localhost:8082/api
- Login: `superadmin` / `password`

## Verify Setup
```bash
# Check containers
docker ps

# Check backend health
curl http://localhost:8082/actuator/health

# Check frontend
curl http://localhost:8080
```

## Database Management
Use pgAdmin4 to:
- View tables
- Run queries
- Manage data
- Monitor connections

## Troubleshooting

### Backend can't connect to PostgreSQL?
1. Check PostgreSQL is running: `services.msc` → PostgreSQL
2. Check password in `.env` file
3. Ensure PostgreSQL accepts connections on port 5432

### Port conflicts?
- Frontend: Change 8080 in docker-compose.local.yml
- Backend: Change 8082 in docker-compose.local.yml
- Redis: Already bound to localhost only

## Stop Everything
```bash
docker-compose -f docker-compose.local.yml down
```