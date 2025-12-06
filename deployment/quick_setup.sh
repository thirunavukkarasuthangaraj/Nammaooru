#!/bin/bash

echo "========================================="
echo "  Quick Docker Setup for Thiru Software"
echo "========================================="

# Update system
echo "📦 Updating system..."
apt update -y

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Install Docker Compose
echo "📦 Installing Docker Compose..."
apt install docker-compose -y

# Create app directory
echo "📁 Creating app directory..."
mkdir -p /opt/shop-management
cd /opt/shop-management

# Install git
echo "🔧 Installing git..."
apt install git -y

echo "✅ Docker installation complete!"
echo ""
echo "Next: Upload your application files"
docker --version
docker-compose --version