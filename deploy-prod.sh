#!/bin/bash

# Production deployment script for Shop Management System
# Run this script on your production server

set -e

DEPLOY_DIR="/opt/shop-management"
ENV_FILE="$DEPLOY_DIR/.env"

echo "🚀 Starting production deployment..."

# Check if we're in the correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found. Please run this script from the project root."
    exit 1
fi

# Create environment file if it doesn't exist
if [ ! -f "$ENV_FILE" ]; then
    echo "📝 Creating production environment file..."
    cat > "$ENV_FILE" << 'EOF'
# Production Environment Variables
SPRING_PROFILES_ACTIVE=production

# Database Configuration (REQUIRED)
DB_URL=jdbc:postgresql://host.docker.internal:5432/shop_management_db
DB_USERNAME=postgres
DB_PASSWORD=your_db_password_here

# JWT Secret (REQUIRED - Generate a strong secret)
JWT_SECRET=your_jwt_secret_key_minimum_256_bits_long

# Mail Configuration (REQUIRED for email features)
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_app_password

# File Storage
FILE_STORAGE_TYPE=local
FILE_STORAGE_PATH=/var/www/shop-management/uploads
FILE_SERVE_URL=https://nammaoorudelivary.in/uploads

# CORS Configuration
APP_CORS_ALLOWED_ORIGINS=https://nammaoorudelivary.in,https://www.nammaoorudelivary.in
APP_CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
APP_CORS_ALLOWED_HEADERS=*
APP_CORS_ALLOW_CREDENTIALS=true
EOF
    echo "✅ Environment file created at $ENV_FILE"
    echo "⚠️  Please edit $ENV_FILE and update the configuration values!"
    echo "Press any key to continue after updating the environment file..."
    read -n 1 -s
fi

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down || true

# Remove old images (optional - uncomment if you want to force rebuild)
# echo "🗑️  Removing old images..."
# docker image prune -f

# Build and start containers
echo "🏗️  Building and starting containers..."
docker-compose up --build -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Check container status
echo "📊 Container Status:"
docker-compose ps

# Check backend health
echo "🏥 Checking backend health..."
if curl -f http://localhost:8082/actuator/health > /dev/null 2>&1; then
    echo "✅ Backend is healthy!"
else
    echo "❌ Backend health check failed. Checking logs..."
    docker-compose logs backend --tail=50
fi

# Check frontend
echo "🌐 Checking frontend..."
if curl -f http://localhost/ > /dev/null 2>&1; then
    echo "✅ Frontend is accessible!"
else
    echo "❌ Frontend is not accessible."
fi

echo "🎉 Production deployment completed!"
echo "🌐 Frontend: http://your-domain.com"
echo "⚙️  Backend API: http://your-domain.com:8082"
echo "📋 To view logs: docker-compose logs -f"