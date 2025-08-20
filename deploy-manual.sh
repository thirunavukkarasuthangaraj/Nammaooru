#!/bin/bash

# Manual deployment script for Shop Management System
# Run this locally to deploy to your Hetzner server

echo "🚀 Starting manual deployment..."

# Build frontend with production configuration
echo "📦 Building frontend..."
cd frontend
npm ci
npm run build

# Copy files to server (adjust paths as needed)
echo "📤 Uploading files to server..."
scp -r dist/shop-management-frontend/* root@65.21.4.236:/var/www/nammaoorudelivary.in/

echo "✅ Deployment complete!"
echo "🌐 Your application is now live at https://www.nammaoorudelivary.in"