#!/bin/bash

# Simple deployment script for Hetzner server
# Run this from your local machine

SERVER_IP="your.hetzner.server.ip"
SERVER_USER="root"

echo "=== Deploying Shop Management to Hetzner ==="

# 1. Build the backend
echo "Building backend..."
cd backend
mvn clean package -DskipTests
cd ..

# 2. Build the frontend
echo "Building frontend..."
cd frontend
npm run build
cd ..

# 3. Create deployment package
echo "Creating deployment package..."
mkdir -p deploy
cp backend/target/*.jar deploy/shop-management-backend.jar
cp -r frontend/dist/shop-management-frontend deploy/frontend
cp hetzner-setup.sh deploy/
cp backend/.env.production deploy/

# 4. Upload to server
echo "Uploading to server..."
scp -r deploy/* $SERVER_USER@$SERVER_IP:/tmp/shop-deploy/

# 5. Run setup on server
echo "Running setup on server..."
ssh $SERVER_USER@$SERVER_IP << 'ENDSSH'
# Move files to correct locations
sudo mv /tmp/shop-deploy/shop-management-backend.jar /opt/shop-management/
sudo rm -rf /var/www/shop-management/frontend
sudo mv /tmp/shop-deploy/frontend /var/www/shop-management/
sudo chown -R www-data:www-data /var/www/shop-management/

# Restart services
sudo systemctl restart shop-management
sudo systemctl restart nginx

# Check status
sudo systemctl status shop-management --no-pager
ENDSSH

echo "=== Deployment Complete ==="
echo "Your application should be running at: https://nammaoorudelivary.in"
echo ""
echo "Storage info:"
echo "- Files are stored in: /var/www/shop-management/uploads/"
echo "- Using your FREE 60GB Hetzner storage"
echo "- No cloud storage costs!"
echo ""
echo "Check logs: ssh $SERVER_USER@$SERVER_IP 'sudo journalctl -u shop-management -f'"