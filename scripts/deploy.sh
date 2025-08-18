#!/bin/bash

# Deployment script for production

set -e

echo "🚀 Deploying Shop Management System..."

# Check if environment is specified
ENVIRONMENT=${1:-local}

if [ "$ENVIRONMENT" = "aws" ]; then
    echo "☁️  Deploying to AWS..."
    
    # Build and push images to Docker registry
    echo "📦 Building and pushing Docker images..."
    docker build -t $DOCKER_USERNAME/shop-management-backend:latest ./backend
    docker build -t $DOCKER_USERNAME/shop-management-frontend:latest ./frontend
    
    docker push $DOCKER_USERNAME/shop-management-backend:latest
    docker push $DOCKER_USERNAME/shop-management-frontend:latest
    
    # Deploy to AWS (customize based on your AWS setup)
    echo "🌐 Deploying to AWS..."
    # aws ecs update-service --cluster shop-cluster --service shop-service --force-new-deployment
    
elif [ "$ENVIRONMENT" = "local" ]; then
    echo "🏠 Deploying locally..."
    
    # Stop existing containers
    docker-compose down
    
    # Pull latest images
    docker-compose pull
    
    # Start services
    docker-compose up -d
    
    # Wait for services
    echo "⏳ Waiting for services..."
    sleep 30
    
    # Health check
    echo "🏥 Health check..."
    curl -f http://localhost/health || echo "Frontend health check failed"
    curl -f http://localhost:8082/actuator/health || echo "Backend health check failed"
    
else
    echo "❌ Invalid environment: $ENVIRONMENT"
    echo "Usage: ./deploy.sh [local|aws]"
    exit 1
fi

echo "✅ Deployment complete!"