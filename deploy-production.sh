#!/bin/bash

# PRODUCTION DEPLOYMENT SCRIPT FOR HETZNER SERVER
# ==============================================
# Run this script on your server: ssh root@65.21.4.236
# Then execute: bash deploy-production.sh

set -e  # Exit on any error

echo "🚀 Starting Production Deployment..."
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Configuration
DB_HOST="localhost"
DB_NAME="shop_management_db"
DB_USER="shopuser"
DB_PASSWORD="SecurePassword@2024"
REDIS_PASSWORD="RedisSecure@2024Pass"
JWT_SECRET="production-jwt-secret-key-2024-very-secure-change-this"
DOMAIN="nammaoorudelivary.in"
SERVER_IP="65.21.4.236"

echo -e "${BLUE}Step 1: Checking System Requirements${NC}"
echo "======================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run this script as root${NC}"
    exit 1
fi

# Update system
echo "Updating system packages..."
apt update && apt upgrade -y

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl enable docker
    systemctl start docker
    rm get-docker.sh
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

echo -e "${GREEN}✓ System requirements checked${NC}"

echo -e "${BLUE}Step 2: Setting up PostgreSQL${NC}"
echo "==============================="

# Install PostgreSQL if not present
if ! command -v psql &> /dev/null; then
    echo "Installing PostgreSQL..."
    apt install postgresql postgresql-contrib -y
    systemctl enable postgresql
    systemctl start postgresql
fi

# Create database and user
echo "Setting up database..."
sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME};" 2>/dev/null || echo "Database already exists"
sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';" 2>/dev/null || echo "User already exists"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"
sudo -u postgres psql -c "ALTER USER ${DB_USER} CREATEDB;"

echo -e "${GREEN}✓ PostgreSQL setup completed${NC}"

echo -e "${BLUE}Step 3: Creating Application Directory${NC}"
echo "======================================"

# Create application directory
mkdir -p /opt/shop-management
cd /opt/shop-management

# Create required directories
mkdir -p /opt/shop-uploads
mkdir -p /var/log/shop-management
chown -R www-data:www-data /opt/shop-uploads
chown -R www-data:www-data /var/log/shop-management

echo -e "${GREEN}✓ Directories created${NC}"

echo -e "${BLUE}Step 4: Creating Docker Files${NC}"
echo "============================="

# Create Dockerfile for backend
cat > backend.dockerfile << 'EOF'
FROM eclipse-temurin:17-jre-alpine
RUN apk add --no-cache curl
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup
WORKDIR /app
COPY *.jar app.jar
RUN mkdir -p /app/uploads && \
    chown -R appuser:appgroup /app
USER appuser
EXPOSE 8082
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8082/actuator/health || exit 1
CMD ["java", "-jar", "-Xmx512m", "-Dspring.profiles.active=prod", "app.jar"]
EOF

# Create Dockerfile for frontend
cat > frontend.dockerfile << 'EOF'
FROM nginx:alpine
RUN apk add --no-cache curl
COPY nginx.conf /etc/nginx/nginx.conf
COPY dist/shop-management-frontend /usr/share/nginx/html
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    mkdir -p /run/nginx && \
    chown -R nginx:nginx /run/nginx && \
    touch /run/nginx.pid && \
    chown nginx:nginx /run/nginx.pid && \
    chmod 755 /run/nginx
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost/ || exit 1
CMD ["nginx", "-g", "daemon off;"]
EOF

# Create Nginx config for frontend
cat > nginx.conf << 'EOF'
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
        server_name _;
        root /usr/share/nginx/html;
        index index.html;
        
        # Handle Angular routing
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF

# Create Docker Compose file
cat > docker-compose.yml << EOF
version: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: backend.dockerfile
    container_name: shop-backend-prod
    restart: always
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - SPRING_DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/${DB_NAME}
      - SPRING_DATASOURCE_USERNAME=${DB_USER}
      - SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - FILE_UPLOAD_PATH=/app/uploads
      - APP_CORS_ALLOWED_ORIGINS=https://${DOMAIN},http://${SERVER_IP}
    ports:
      - "8082:8082"
    volumes:
      - /opt/shop-uploads:/app/uploads
      - /var/log/shop-management:/app/logs
    networks:
      - shop-network
    extra_hosts:
      - "host.docker.internal:host-gateway"

  frontend:
    build:
      context: .
      dockerfile: frontend.dockerfile
    container_name: shop-frontend-prod
    restart: always
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - shop-network

  redis:
    image: redis:7-alpine
    container_name: shop-redis-prod
    restart: always
    command: redis-server --requirepass ${REDIS_PASSWORD}
    ports:
      - "127.0.0.1:6379:6379"
    networks:
      - shop-network

networks:
  shop-network:
    driver: bridge
EOF

echo -e "${GREEN}✓ Docker files created${NC}"

echo -e "${YELLOW}Step 5: Transfer Instructions${NC}"
echo "============================"
echo ""
echo "Now you need to transfer the built application files:"
echo ""
echo "1. On your LOCAL machine, run:"
echo "   cd backend && mvn clean package -DskipTests"
echo "   cd ../frontend && npm install && npm run build"
echo ""
echo "2. Transfer files to server:"
echo "   scp backend/target/*.jar root@${SERVER_IP}:/opt/shop-management/"
echo "   scp -r frontend/dist root@${SERVER_IP}:/opt/shop-management/"
echo ""
echo "3. Then continue with Step 6 on the server"
echo ""
read -p "Press Enter when you've transferred the files..."

echo -e "${BLUE}Step 6: Building and Starting Services${NC}"
echo "====================================="

# Check if JAR file exists
if [ ! -f *.jar ]; then
    echo -e "${RED}❌ JAR file not found! Please transfer backend/target/*.jar to this directory${NC}"
    exit 1
fi

# Check if frontend dist exists
if [ ! -d "dist" ]; then
    echo -e "${RED}❌ Frontend dist folder not found! Please transfer frontend/dist to this directory${NC}"
    exit 1
fi

# Stop existing containers
docker-compose down 2>/dev/null || true

# Build and start services
echo "Building Docker images..."
docker-compose build

echo "Starting services..."
docker-compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 30

# Check service health
echo -e "${BLUE}Step 7: Verifying Deployment${NC}"
echo "============================"

# Check containers
echo "Container status:"
docker-compose ps

echo ""
echo "Testing services..."

# Test backend
if curl -f http://localhost:8082/actuator/health &>/dev/null; then
    echo -e "${GREEN}✓ Backend is running${NC}"
else
    echo -e "${RED}❌ Backend health check failed${NC}"
    echo "Backend logs:"
    docker logs shop-backend-prod --tail 20
fi

# Test frontend
if curl -f http://localhost:80 &>/dev/null; then
    echo -e "${GREEN}✓ Frontend is running${NC}"
else
    echo -e "${RED}❌ Frontend health check failed${NC}"
    echo "Frontend logs:"
    docker logs shop-frontend-prod --tail 20
fi

# Test Redis
if docker exec shop-redis-prod redis-cli -a ${REDIS_PASSWORD} ping &>/dev/null; then
    echo -e "${GREEN}✓ Redis is running${NC}"
else
    echo -e "${RED}❌ Redis health check failed${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "======================"
echo ""
echo "📱 Access your application:"
echo "   Frontend: http://${SERVER_IP}"
echo "   Backend:  http://${SERVER_IP}:8082"
echo ""
echo "🛠  Management commands:"
echo "   View logs:    docker-compose logs -f [service]"
echo "   Restart:      docker-compose restart [service]"
echo "   Stop all:     docker-compose down"
echo "   Start all:    docker-compose up -d"
echo ""
echo "🔧 Next steps:"
echo "   1. Configure domain DNS to point to ${SERVER_IP}"
echo "   2. Set up SSL certificates with certbot"
echo "   3. Configure firewall if needed"
echo "   4. Set up monitoring and backups"
echo ""