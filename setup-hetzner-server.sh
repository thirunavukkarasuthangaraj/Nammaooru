#!/bin/bash

# Hetzner Server Setup Script - Ubuntu 22.04
# ===========================================

echo "🚀 Setting up Shop Management System on Hetzner Server"
echo "======================================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Update system
echo -e "${YELLOW}[1/10] Updating system packages...${NC}"
apt update && apt upgrade -y

# Install Docker
echo -e "${YELLOW}[2/10] Installing Docker...${NC}"
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# Install Docker Compose
echo -e "${YELLOW}[3/10] Installing Docker Compose...${NC}"
curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install PostgreSQL
echo -e "${YELLOW}[4/10] Installing PostgreSQL...${NC}"
apt install -y postgresql postgresql-contrib
systemctl enable postgresql
systemctl start postgresql

# Create database and user
echo -e "${YELLOW}[5/10] Setting up PostgreSQL database...${NC}"
sudo -u postgres psql << EOF
CREATE DATABASE shop_management_db;
CREATE USER shopuser WITH ENCRYPTED PASSWORD 'SecurePassword2024!';
GRANT ALL PRIVILEGES ON DATABASE shop_management_db TO shopuser;
\q
EOF

# Create directory structure
echo -e "${YELLOW}[6/10] Creating directory structure...${NC}"
mkdir -p /opt/shop-management
mkdir -p /opt/shop-uploads/products
mkdir -p /opt/shop-uploads/shops
mkdir -p /opt/shop-uploads/categories
mkdir -p /opt/shop-uploads/temp
mkdir -p /var/log/shop-management

# Set permissions for uploads
echo -e "${YELLOW}[7/10] Setting permissions...${NC}"
chmod -R 755 /opt/shop-uploads
chown -R www-data:www-data /opt/shop-uploads

# Install Nginx
echo -e "${YELLOW}[8/10] Installing Nginx...${NC}"
apt install -y nginx
systemctl enable nginx

# Install Certbot for SSL
echo -e "${YELLOW}[9/10] Installing Certbot...${NC}"
apt install -y certbot python3-certbot-nginx

# Setup firewall
echo -e "${YELLOW}[10/10] Configuring firewall...${NC}"
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8082/tcp
ufw --force enable

echo -e "${GREEN}✅ Server setup complete!${NC}"
echo ""
echo "Directory structure created:"
echo "  /opt/shop-management/     - Application files"
echo "  /opt/shop-uploads/        - Photo storage"
echo "    ├── products/           - Product images"
echo "    ├── shops/              - Shop logos/banners"
echo "    ├── categories/         - Category images"
echo "    └── temp/               - Temporary uploads"
echo ""
echo "PostgreSQL Database:"
echo "  Database: shop_management_db"
echo "  User: shopuser"
echo "  Password: SecurePassword2024! (CHANGE THIS!)"
echo ""
echo "Next steps:"
echo "  1. Upload application files to /opt/shop-management/"
echo "  2. Configure .env with database credentials"
echo "  3. Run docker-compose up -d"
echo "  4. Configure domain and SSL with certbot"