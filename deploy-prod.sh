#!/bin/bash

# Production deployment script
echo "🚀 Deploying frontend to production..."

# Configuration
SERVER="root@65.21.4.236"
REMOTE_PATH="/opt/shop-management/frontend/dist"

# Create archive
echo "📦 Creating deployment archive..."
cd frontend/dist
tar -czf deploy.tar.gz shop-management-frontend/
cd ../..

# Upload to server
echo "📤 Uploading to server..."
scp frontend/dist/deploy.tar.gz $SERVER:~/

# Deploy on server
echo "🔧 Deploying on server..."
ssh $SERVER "cd /opt/shop-management && tar -xzf ~/deploy.tar.gz -C frontend/dist/ --strip-components=1 && rm ~/deploy.tar.gz && chown -R www-data:www-data frontend && nginx -t && systemctl reload nginx"

# Clean up
rm frontend/dist/deploy.tar.gz

echo "✅ Deployment complete!"
