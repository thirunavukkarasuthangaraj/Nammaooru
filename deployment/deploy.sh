#!/bin/bash

echo "========================================="
echo "  Deploying Shop Management System"
echo "========================================="

cd /opt/shop-management

# Build backend
echo "🔨 Building backend..."
cd backend
docker build -f Dockerfile.simple -t shop-backend:latest .
cd ..

# Copy frontend files
echo "📦 Setting up frontend..."
mkdir -p frontend/dist
# Frontend files should already be in place from upload

# Start services
echo "🚀 Starting Docker containers..."
docker-compose down
docker-compose up -d

# Check status
echo "📊 Checking container status..."
docker ps

# Import database
echo "💾 Importing database..."
docker exec -i shop-postgres psql -U postgres -d shop_management_db < database/schema.sql
docker exec -i shop-postgres psql -U postgres -d shop_management_db < database/init.sql

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Your application is running at:"
echo "  http://YOUR_SERVER_IP"
echo ""
echo "Default login:"
echo "  Username: admin"
echo "  Password: password"