# Docker Production Deployment with External PostgreSQL

## Quick Deploy Commands

### 1. Environment Setup
```bash
# Create production .env file
cat > .env.production << 'EOF'
# Database (External PostgreSQL - NOT in Docker)
DB_HOST=your-postgres-host.hetzner.com
DB_PORT=5432
DB_NAME=shop_management_db
DB_USER=shopuser
DB_PASSWORD=YourStrongPassword123!

# Backend
BACKEND_PORT=8082
JWT_SECRET=your-production-jwt-secret-key-change-this
SPRING_PROFILES_ACTIVE=prod

# Frontend
FRONTEND_PORT=80
API_URL=https://api.yourdomain.com

# Domains
DOMAIN=yourdomain.com
API_DOMAIN=api.yourdomain.com
EOF
```

### 2. Docker Compose Production File
```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: shop-backend
    restart: always
    ports:
      - "8082:8082"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - SPRING_DATASOURCE_URL=jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}
      - SPRING_DATASOURCE_USERNAME=${DB_USER}
      - SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - FILE_UPLOAD_DIR=/uploads
    volumes:
      - ./uploads:/uploads
      - ./logs/backend:/logs
    networks:
      - shopnet

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        - API_URL=${API_URL}
    container_name: shop-frontend
    restart: always
    ports:
      - "3000:80"
    depends_on:
      - backend
    networks:
      - shopnet

  nginx:
    image: nginx:alpine
    container_name: shop-nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/sites-enabled:/etc/nginx/sites-enabled
      - ./ssl:/etc/ssl/certs
      - ./uploads:/var/www/uploads
    depends_on:
      - backend
      - frontend
    networks:
      - shopnet

networks:
  shopnet:
    driver: bridge
```

### 3. Backend Dockerfile
```dockerfile
# backend/Dockerfile
FROM openjdk:17-jdk-alpine
RUN apk add --no-cache tzdata
ENV TZ=Asia/Kolkata
WORKDIR /app
COPY target/shop-management-backend-1.0.0.jar app.jar
EXPOSE 8082
ENTRYPOINT ["java", "-jar", "-Xmx512m", "-Dspring.profiles.active=prod", "app.jar"]
```

### 4. Frontend Dockerfile
```dockerfile
# frontend/Dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
ARG API_URL
ENV API_URL=$API_URL
RUN npm run build --prod

FROM nginx:alpine
COPY --from=builder /app/dist/shop-management-frontend /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 5. Nginx Configuration
```nginx
# nginx/nginx.conf
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    upstream backend {
        server backend:8082;
    }
    
    upstream frontend {
        server frontend:80;
    }

    # API Server
    server {
        listen 80;
        server_name api.yourdomain.com;
        
        location / {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        location /uploads {
            alias /var/www/uploads;
            expires 30d;
        }
    }
    
    # Frontend Server
    server {
        listen 80;
        server_name yourdomain.com www.yourdomain.com;
        
        location / {
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```

---

## DEPLOYMENT STEPS

### Step 1: On Your Local Machine
```bash
# 1. Build Backend JAR
cd backend
mvn clean package -DskipTests

# 2. Build Frontend
cd ../frontend
npm install
npm run build --prod

# 3. Create deployment package
cd ..
tar -czf shop-deployment.tar.gz \
    backend/Dockerfile \
    backend/target/*.jar \
    frontend/Dockerfile \
    frontend/dist \
    frontend/nginx.conf \
    docker-compose.prod.yml \
    nginx/
```

### Step 2: Transfer to Server
```bash
# Transfer deployment package
scp shop-deployment.tar.gz root@your-server-ip:/opt/

# Connect to server
ssh root@your-server-ip
```

### Step 3: On Your Hetzner Server
```bash
# 1. Extract files
cd /opt
tar -xzf shop-deployment.tar.gz
cd shop-management

# 2. Create required directories
mkdir -p uploads logs/backend logs/frontend

# 3. Set environment variables
cp .env.production .env
nano .env  # Edit with your actual values

# 4. Build and start containers
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# 5. Check status
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs -f
```

---

## DATABASE SETUP (External PostgreSQL)

### Connect to your PostgreSQL (Already installed)
```bash
# Connect to PostgreSQL
psql -h localhost -U postgres

# Create database and user
CREATE DATABASE shop_management_db;
CREATE USER shopuser WITH ENCRYPTED PASSWORD 'YourStrongPassword123!';
GRANT ALL PRIVILEGES ON DATABASE shop_management_db TO shopuser;
\q

# Import schema
psql -U shopuser -d shop_management_db < schema.sql
```

---

## SSL WITH CERTBOT (Optional but Recommended)

```bash
# Install Certbot
apt install certbot python3-certbot-nginx -y

# Get certificates
certbot certonly --standalone -d yourdomain.com -d api.yourdomain.com

# Update docker-compose to use SSL
# Add to nginx service volumes:
volumes:
  - /etc/letsencrypt:/etc/letsencrypt:ro
```

---

## QUICK COMMANDS

### Start/Stop Services
```bash
# Start all services
docker-compose -f docker-compose.prod.yml up -d

# Stop all services
docker-compose -f docker-compose.prod.yml down

# Restart backend only
docker-compose -f docker-compose.prod.yml restart backend

# View logs
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f frontend
```

### Update Application
```bash
# 1. Build new version locally
mvn clean package -DskipTests

# 2. Transfer new JAR
scp target/shop-management-backend-1.0.0.jar root@server:/opt/shop-management/backend/target/

# 3. On server - rebuild and restart
docker-compose -f docker-compose.prod.yml build backend
docker-compose -f docker-compose.prod.yml up -d backend
```

### Health Check
```bash
# Check containers
docker ps

# Check backend health
curl http://localhost:8082/actuator/health

# Check database connection
docker exec shop-backend sh -c "nc -zv ${DB_HOST} 5432"

# View backend logs
docker logs shop-backend --tail 100 -f
```

---

## ENVIRONMENT VARIABLES TO CHANGE

Replace these in `.env.production`:
- `your-postgres-host.hetzner.com` → Your PostgreSQL host (or localhost if on same server)
- `YourStrongPassword123!` → Your PostgreSQL password
- `yourdomain.com` → Your actual domain
- `your-production-jwt-secret-key-change-this` → Generate a secure JWT secret

---

## TROUBLESHOOTING

### Backend can't connect to database
```bash
# Test from container
docker exec shop-backend ping your-postgres-host.hetzner.com

# Check PostgreSQL is accepting connections
netstat -an | grep 5432

# Check PostgreSQL config
nano /etc/postgresql/*/main/postgresql.conf
# Ensure: listen_addresses = '*' or your Docker network

nano /etc/postgresql/*/main/pg_hba.conf
# Add: host all all 172.0.0.0/8 md5  # For Docker networks
```

### Container won't start
```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs backend

# Check resources
docker system df
df -h
```

### Port already in use
```bash
# Find what's using port
lsof -i :8082
lsof -i :80

# Kill process or change port in docker-compose
```

---

## MINIMAL QUICK START (5 Minutes)

```bash
# On server
cd /opt/shop-management

# 1. Edit environment
nano .env.production
# Set: DB_HOST, DB_PASSWORD, DOMAIN

# 2. Start everything
docker-compose -f docker-compose.prod.yml up -d

# 3. Check it's working
docker ps
curl http://localhost:8082/actuator/health

# Done! Access at http://yourdomain.com
```

---

This setup uses Docker for the application but connects to your external PostgreSQL database!