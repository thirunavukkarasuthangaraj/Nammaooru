# 🚀 Next Time Deployment Guide

## 📋 **Quick Deployment Checklist**

When you need to deploy again (updates, new server, etc.), follow these proven steps:

### ⚡ **Quick Start (5 Minutes)**
```bash
# 1. Connect to server
ssh root@65.21.4.236

# 2. Check current status
cd /opt/shop-management
docker ps
curl -I https://nammaoorudelivary.in

# 3. If services are down, restart with working configuration
docker stop shop-backend-prod shop-frontend-prod 2>/dev/null || true
docker rm shop-backend-prod shop-frontend-prod 2>/dev/null || true

# 4. Start backend (use these exact settings)
docker run -d --name shop-backend-prod \
  --network shop-network \
  -p 8082:8082 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/shop_management_db \
  -e SPRING_DATASOURCE_USERNAME=postgres \
  -e SPRING_DATASOURCE_PASSWORD=postgres \
  -e JWT_SECRET=production-jwt-secret-key-2024-very-secure-change-this \
  -e FILE_UPLOAD_PATH=/app/uploads \
  -e "APP_CORS_ALLOWED_ORIGINS=http://65.21.4.236,https://65.21.4.236,http://nammaoorudelivary.in,https://nammaoorudelivary.in,http://www.nammaoorudelivary.in,https://www.nammaoorudelivary.in,http://api.nammaoorudelivary.in,https://api.nammaoorudelivary.in" \
  -e APP_CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS \
  -e APP_CORS_ALLOWED_HEADERS=Authorization,Content-Type,X-Requested-With,Accept,Origin,Access-Control-Request-Method,Access-Control-Request-Headers \
  -e APP_CORS_ALLOW_CREDENTIALS=true \
  --add-host="host.docker.internal:host-gateway" \
  -v /opt/shop-management/backend-new.jar:/app/app.jar:ro \
  eclipse-temurin:17-jre-alpine sh -c "apk add --no-cache curl && java -jar -Xmx512m -Dspring.profiles.active=prod /app/app.jar"

# 5. Start frontend
docker run -d --name shop-frontend-prod \
  --network shop-network \
  -p 80:80 \
  -v /opt/shop-management/dist/shop-management-frontend:/usr/share/nginx/html:ro \
  -v /opt/shop-management/nginx-frontend.conf:/etc/nginx/nginx.conf:ro \
  nginx:alpine

# 6. Test deployment
sleep 15
curl -X POST https://api.nammaoorudelivary.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"superadmin","password":"password"}'
```

---

## 📦 **Full Deployment from Scratch**

### Step 1: Server Setup
```bash
# Connect to server
ssh root@65.21.4.236

# Update system
apt update && apt upgrade -y

# Install Docker if needed
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install PostgreSQL if needed
apt install postgresql postgresql-contrib -y
systemctl enable postgresql
systemctl start postgresql
```

### Step 2: Database Setup
```bash
# Create database and user
sudo -u postgres psql -c "CREATE DATABASE shop_management_db;" 2>/dev/null || true
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"

# Test connection
PGPASSWORD=postgres psql -h localhost -U postgres -d shop_management_db -c "SELECT current_database();"
```

### Step 3: Application Directory
```bash
# Create directories
mkdir -p /opt/shop-management
mkdir -p /opt/shop-uploads
chown -R www-data:www-data /opt/shop-uploads

cd /opt/shop-management
```

### Step 4: Build and Transfer Application
```bash
# On LOCAL machine:
cd backend
mvn clean package -DskipTests
cd ../frontend
npm install
npm run build --prod
cd ..

# Transfer to server
scp backend/target/*.jar root@65.21.4.236:/opt/shop-management/backend-new.jar
scp -r frontend/dist root@65.21.4.236:/opt/shop-management/
```

### Step 5: Create Docker Network
```bash
# On server
docker network create shop-network 2>/dev/null || true
```

### Step 6: Create Nginx Configuration
```bash
cat > /opt/shop-management/nginx-frontend.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript;
    
    server {
        listen 80;
        server_name _ nammaoorudelivary.in www.nammaoorudelivary.in api.nammaoorudelivary.in 65.21.4.236;
        root /usr/share/nginx/html;
        index index.html;
        
        # Handle Angular routing
        location / {
            try_files $uri $uri/ /index.html;
        }
        
        # Proxy API calls to backend container  
        location /api/ {
            proxy_pass http://shop-backend-prod:8082;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF
```

### Step 7: Update Frontend API Endpoint
```bash
# Make sure frontend calls the correct API
cd /opt/shop-management
find dist/ -name "*.js" -exec sed -i "s|https://api.nammaoorudelivary.in|https://api.nammaoorudelivary.in|g" {} \;
```

### Step 8: Start Services (Use commands from Quick Start above)

---

## 🌐 **Domain Configuration**

### Cloudflare DNS Records (Required):
```
Type: A     Name: @              Content: 65.21.4.236    Status: 🟠 Proxied
Type: A     Name: api            Content: 65.21.4.236    Status: 🟠 Proxied  
Type: A     Name: www            Content: 65.21.4.236    Status: 🟠 Proxied
```

**Important**: Make sure `api` record is set to **🟠 Proxied** (not DNS only) for SSL to work.

---

## 🧪 **Verification Tests**

### Test 1: API Health
```bash
curl -X POST https://api.nammaoorudelivary.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"superadmin","password":"password"}'

# Should return JWT token
```

### Test 2: Frontend Loading
```bash
curl -I https://nammaoorudelivary.in
# Should return 200 OK
```

### Test 3: Database Connection
```bash
ssh root@65.21.4.236 'PGPASSWORD=postgres psql -h localhost -U postgres -d shop_management_db -c "SELECT COUNT(*) FROM users;"'
# Should return user count
```

### Test 4: Container Status
```bash
docker ps
# Should show: shop-backend-prod, shop-frontend-prod (both healthy)
```

---

## 🔧 **Common Issues & Quick Fixes**

### Issue: Connection Timeout
```bash
# Check container status
docker logs shop-backend-prod
docker logs shop-frontend-prod

# Restart if needed
docker restart shop-backend-prod shop-frontend-prod
```

### Issue: Database Connection Failed
```bash
# Reset postgres password
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"

# Test connection
PGPASSWORD=postgres psql -h localhost -U postgres -d shop_management_db -c "SELECT 1;"
```

### Issue: JAR File Corrupt
```bash
# Use the working JAR file
ls -la /opt/shop-management/*.jar
# Make sure backend-new.jar exists and is not corrupted

# Restart backend with correct JAR
docker stop shop-backend-prod && docker rm shop-backend-prod
# Then run the backend docker command from Quick Start
```

### Issue: Frontend API Calls Failing
```bash
# Check frontend API endpoint configuration
grep -r "api.nammaoorudelivary.in" /opt/shop-management/dist/

# Update if needed
find /opt/shop-management/dist/ -name "*.js" -exec sed -i "s|OLD_API_URL|https://api.nammaoorudelivary.in|g" {} \;
```

---

## 📊 **Current Working Configuration**

### Server Details:
- **IP**: 65.21.4.236
- **OS**: Ubuntu 24.04.3 LTS
- **Domain**: nammaoorudelivary.in

### Database:
- **Name**: shop_management_db
- **User**: postgres
- **Password**: postgres
- **Port**: 5432

### Application URLs:
- **Frontend**: https://nammaoorudelivary.in
- **Backend API**: https://api.nammaoorudelivary.in
- **Direct IP Access**: http://65.21.4.236

### Login Credentials:
- **Username**: superadmin
- **Password**: password
- **Role**: SUPER_ADMIN

---

## 🚀 **Automation Script**

Create this script for one-command deployment:

```bash
#!/bin/bash
# save as: deploy.sh

echo "🚀 Starting Shop Management System Deployment..."

# Stop existing containers
docker stop shop-backend-prod shop-frontend-prod 2>/dev/null || true
docker rm shop-backend-prod shop-frontend-prod 2>/dev/null || true

# Create network if not exists
docker network create shop-network 2>/dev/null || true

# Start backend
echo "Starting backend..."
docker run -d --name shop-backend-prod \
  --network shop-network -p 8082:8082 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/shop_management_db \
  -e SPRING_DATASOURCE_USERNAME=postgres \
  -e SPRING_DATASOURCE_PASSWORD=postgres \
  -e JWT_SECRET=production-jwt-secret-key-2024-very-secure-change-this \
  -e "APP_CORS_ALLOWED_ORIGINS=http://65.21.4.236,https://65.21.4.236,http://nammaoorudelivary.in,https://nammaoorudelivary.in,http://www.nammaoorudelivary.in,https://www.nammaoorudelivary.in,http://api.nammaoorudelivary.in,https://api.nammaoorudelivary.in" \
  --add-host="host.docker.internal:host-gateway" \
  -v /opt/shop-management/backend-new.jar:/app/app.jar:ro \
  eclipse-temurin:17-jre-alpine sh -c "apk add --no-cache curl && java -jar -Xmx512m -Dspring.profiles.active=prod /app/app.jar"

# Start frontend
echo "Starting frontend..."
docker run -d --name shop-frontend-prod \
  --network shop-network -p 80:80 \
  -v /opt/shop-management/dist/shop-management-frontend:/usr/share/nginx/html:ro \
  -v /opt/shop-management/nginx-frontend.conf:/etc/nginx/nginx.conf:ro \
  nginx:alpine

# Test deployment
echo "Testing deployment..."
sleep 15
curl -X POST https://api.nammaoorudelivary.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"superadmin","password":"password"}' | grep -q "accessToken" && echo "✅ API Working" || echo "❌ API Failed"

curl -I https://nammaoorudelivary.in | grep -q "200 OK" && echo "✅ Frontend Working" || echo "❌ Frontend Failed"

echo "🎉 Deployment complete!"
echo "Frontend: https://nammaoorudelivary.in"
echo "API: https://api.nammaoorudelivary.in"
```

**Usage:**
```bash
# Make executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

---

**Next Deployment Guide Created**: August 2025  
**Status**: ✅ READY FOR NEXT DEPLOYMENT