#!/bin/bash

# QUICK DEPLOYMENT SCRIPT FOR HETZNER SERVER
# ==========================================

echo "🚀 Starting deployment to Hetzner server..."

# Configuration - CHANGE THESE VALUES
SERVER_IP="your-hetzner-server-ip"
SERVER_USER="root"
DB_HOST="localhost"  # PostgreSQL on same server
DB_PASSWORD="your-postgresql-password"
DOMAIN="yourdomain.com"
UPLOADS_DIR="/opt/shop-uploads"  # Photo storage location

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Step 1: Building Backend JAR${NC}"
cd backend
mvn clean package -DskipTests
if [ $? -ne 0 ]; then
    echo -e "${RED}Backend build failed!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Backend built successfully${NC}"

echo -e "${YELLOW}Step 2: Building Frontend${NC}"
cd ../frontend
npm install
npm run build --prod
if [ $? -ne 0 ]; then
    echo -e "${RED}Frontend build failed!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Frontend built successfully${NC}"

echo -e "${YELLOW}Step 3: Creating deployment package${NC}"
cd ..
mkdir -p deployment-package
cp -r backend/target/*.jar deployment-package/
cp -r frontend/dist deployment-package/
cp docker-compose.prod.yml deployment-package/
cp -r nginx deployment-package/

# Create Dockerfiles
cat > deployment-package/backend.dockerfile << 'EOF'
FROM openjdk:17-jdk-alpine
WORKDIR /app
COPY *.jar app.jar
EXPOSE 8082
CMD ["java", "-jar", "-Dspring.profiles.active=prod", "app.jar"]
EOF

cat > deployment-package/frontend.dockerfile << 'EOF'
FROM nginx:alpine
COPY dist/shop-management-frontend /usr/share/nginx/html
EXPOSE 80
EOF

# Create environment file
cat > deployment-package/.env << EOF
DB_HOST=${DB_HOST}
DB_PORT=5432
DB_NAME=shop_management_db
DB_USER=shopuser
DB_PASSWORD=${DB_PASSWORD}
DOMAIN=${DOMAIN}
API_URL=https://api.${DOMAIN}
JWT_SECRET=$(openssl rand -base64 32)
EOF

tar -czf deployment.tar.gz deployment-package/

echo -e "${YELLOW}Step 4: Uploading to server${NC}"
scp deployment.tar.gz ${SERVER_USER}@${SERVER_IP}:/tmp/
if [ $? -ne 0 ]; then
    echo -e "${RED}Upload failed! Check server IP and credentials${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 5: Deploying on server${NC}"
ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
cd /opt
rm -rf shop-management
mkdir -p shop-management
cd shop-management
tar -xzf /tmp/deployment.tar.gz --strip-components=1
rm /tmp/deployment.tar.gz

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  backend:
    build:
      context: .
      dockerfile: backend.dockerfile
    container_name: shop-backend
    restart: always
    ports:
      - "8082:8082"
    env_file: .env
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://${DB_HOST}:5432/shop_management_db
      - SPRING_DATASOURCE_USERNAME=shopuser
      - SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./uploads:/uploads
      - ./logs:/logs
    networks:
      - shopnet

  frontend:
    build:
      context: .
      dockerfile: frontend.dockerfile
    container_name: shop-frontend
    restart: always
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - shopnet

networks:
  shopnet:
    driver: bridge
EOF

# Start services
docker-compose down 2>/dev/null
docker-compose build
docker-compose up -d

echo "Waiting for services to start..."
sleep 10

# Check status
docker ps
echo ""
echo "Testing backend health..."
curl -s http://localhost:8082/actuator/health || echo "Backend not ready yet"
ENDSSH

echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "📝 Next steps:"
echo "1. SSH to server: ssh ${SERVER_USER}@${SERVER_IP}"
echo "2. Check logs: docker logs shop-backend"
echo "3. Test API: curl http://${SERVER_IP}:8082/actuator/health"
echo "4. Access frontend: http://${SERVER_IP}"
echo ""
echo "⚠️  Don't forget to:"
echo "- Configure SSL certificates"
echo "- Update DNS records"
echo "- Check database connection"