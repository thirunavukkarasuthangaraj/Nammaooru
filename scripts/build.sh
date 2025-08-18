#!/bin/bash

# Build script for local development

echo "🚀 Building Shop Management System..."

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from example..."
    cp .env.example .env
    echo "⚠️  Please update .env file with your configuration"
fi

# Build and start services
echo "🐳 Building Docker images..."
docker-compose build --no-cache

echo "🌟 Starting services..."
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to start..."
sleep 30

# Check service health
echo "🏥 Checking service health..."
docker-compose ps

# Show logs
echo "📋 Recent logs:"
docker-compose logs --tail=20

echo "✅ Build complete!"
echo "📱 Frontend: http://localhost"
echo "🔧 Backend: http://localhost:8082"
echo "🗄️  Database: localhost:5432"
echo ""
echo "📖 Useful commands:"
echo "  docker-compose logs -f          # Follow logs"
echo "  docker-compose down             # Stop all services"
echo "  docker-compose restart backend  # Restart backend only"