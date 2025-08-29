#!/bin/bash

# TRANSFER FILES TO PRODUCTION SERVER
# ===================================

SERVER_IP="65.21.4.236"
SERVER_USER="root"

echo "🚀 Building and Transferring to Production Server..."
echo "=================================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Step 1: Building Backend${NC}"
cd backend
mvn clean package -DskipTests
if [ $? -ne 0 ]; then
    echo -e "${RED}Backend build failed!${NC}"
    exit 1
fi
cd ..
echo -e "${GREEN}✓ Backend built successfully${NC}"

echo -e "${BLUE}Step 2: Building Frontend${NC}"
cd frontend
npm install
npm run build --prod
if [ $? -ne 0 ]; then
    echo -e "${RED}Frontend build failed!${NC}"
    exit 1
fi
cd ..
echo -e "${GREEN}✓ Frontend built successfully${NC}"

echo -e "${BLUE}Step 3: Transferring Deployment Script${NC}"
scp deploy-production.sh ${SERVER_USER}@${SERVER_IP}:/tmp/
echo -e "${GREEN}✓ Deployment script transferred${NC}"

echo -e "${BLUE}Step 4: Setting up Server Environment${NC}"
ssh ${SERVER_USER}@${SERVER_IP} "bash /tmp/deploy-production.sh"

echo -e "${BLUE}Step 5: Transferring Application Files${NC}"
echo "Transferring backend JAR..."
scp backend/target/*.jar ${SERVER_USER}@${SERVER_IP}:/opt/shop-management/

echo "Transferring frontend..."
scp -r frontend/dist ${SERVER_USER}@${SERVER_IP}:/opt/shop-management/

echo -e "${BLUE}Step 6: Starting Services on Server${NC}"
ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
cd /opt/shop-management

# Stop existing services
docker-compose down 2>/dev/null || true

# Build and start services
docker-compose build
docker-compose up -d

# Wait for startup
sleep 30

# Check status
echo "=== Container Status ==="
docker-compose ps

echo ""
echo "=== Testing Services ==="
echo -n "Backend: "
if curl -s -f http://localhost:8082/actuator/health > /dev/null; then
    echo "✓ Running"
else
    echo "❌ Failed"
fi

echo -n "Frontend: "
if curl -s -f http://localhost:80 > /dev/null; then
    echo "✓ Running"
else
    echo "❌ Failed"
fi

echo ""
echo "🎉 Deployment complete!"
echo "Frontend: http://65.21.4.236"
echo "Backend:  http://65.21.4.236:8082"
ENDSSH

echo -e "${GREEN}✅ Production deployment completed!${NC}"
echo ""
echo "🌐 Your application is now available at:"
echo "   http://65.21.4.236     (Frontend)"
echo "   http://65.21.4.236:8082 (Backend API)"
echo ""
echo "🛠  To manage your deployment:"
echo "   ssh ${SERVER_USER}@${SERVER_IP}"
echo "   cd /opt/shop-management"
echo "   docker-compose logs -f    # View logs"
echo "   docker-compose restart    # Restart services"