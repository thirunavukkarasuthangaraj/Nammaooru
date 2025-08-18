#!/bin/bash

echo "========================================="
echo "  Shop Management System - Server Setup"
echo "========================================="

# Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Install Docker Compose
echo "📦 Installing Docker Compose..."
apt install docker-compose -y

# Install required tools
echo "🔧 Installing required tools..."
apt install -y git nginx certbot python3-certbot-nginx ufw

# Configure firewall
echo "🔒 Configuring firewall..."
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8082/tcp
ufw --force enable

# Create app directory
echo "📁 Creating application directory..."
mkdir -p /opt/shop-management
cd /opt/shop-management

# Create docker-compose.yml
echo "📝 Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: shop-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: shop_management_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres123
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - shop-network

  backend:
    image: shop-backend:latest
    container_name: shop-backend
    restart: unless-stopped
    environment:
      SPRING_PROFILES_ACTIVE: docker
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/shop_management_db
      SPRING_DATASOURCE_USERNAME: postgres
      SPRING_DATASOURCE_PASSWORD: postgres123
    ports:
      - "8082:8082"
    depends_on:
      - postgres
    networks:
      - shop-network

  frontend:
    image: nginx:alpine
    container_name: shop-frontend
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./frontend/dist:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - backend
    networks:
      - shop-network

volumes:
  postgres_data:

networks:
  shop-network:
    driver: bridge
EOF

echo "✅ Server setup complete!"
echo ""
echo "Next steps:"
echo "1. Upload your application files"
echo "2. Build Docker images"
echo "3. Run docker-compose up -d"
echo "4. Configure your domain"