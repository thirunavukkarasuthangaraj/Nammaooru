#!/bin/bash

# Hetzner Server Setup Script for Shop Management System
# This uses your FREE 60GB storage - no extra cost!

echo "=== Setting up Shop Management on Hetzner Server ==="

# 1. Create upload directories (FREE - uses your 60GB storage)
echo "Creating upload directories..."
sudo mkdir -p /var/www/shop-management/uploads/products
sudo mkdir -p /var/www/shop-management/uploads/documents/shops
sudo mkdir -p /var/www/shop-management/uploads/profiles
sudo mkdir -p /var/www/shop-management/uploads/temp

# 2. Set proper permissions
echo "Setting permissions..."
sudo chown -R www-data:www-data /var/www/shop-management/uploads
sudo chmod -R 755 /var/www/shop-management/uploads

# 3. Create application directory
echo "Creating application directory..."
sudo mkdir -p /opt/shop-management
sudo mkdir -p /var/log/shop-management

# 4. Install Java 17 if not installed
echo "Checking Java installation..."
if ! command -v java &> /dev/null; then
    sudo apt update
    sudo apt install openjdk-17-jdk -y
fi

# 5. Install PostgreSQL if not installed
echo "Checking PostgreSQL..."
if ! command -v psql &> /dev/null; then
    sudo apt install postgresql postgresql-contrib -y
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
fi

# 6. Create database
echo "Setting up database..."
sudo -u postgres psql << EOF
CREATE DATABASE shop_management_db;
CREATE USER shopuser WITH PASSWORD 'your_secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE shop_management_db TO shopuser;
EOF

# 7. Configure Nginx to serve uploaded files
echo "Configuring Nginx..."
cat << 'NGINX' | sudo tee /etc/nginx/sites-available/shop-management
server {
    listen 80;
    server_name nammaoorudelivary.in www.nammaoorudelivary.in;

    # Serve uploaded files directly (FREE - no CDN cost!)
    location /uploads/ {
        alias /var/www/shop-management/uploads/;
        expires 30d;
        add_header Cache-Control "public, immutable";
        
        # Security headers
        add_header X-Content-Type-Options nosniff;
        
        # Allow specific file types only
        location ~ \.(jpg|jpeg|png|gif|webp|pdf|doc|docx)$ {
            # Serve the file
        }
        
        # Block other file types
        location ~ \.(php|jsp|asp|sh|cgi)$ {
            deny all;
        }
    }

    # Proxy to Spring Boot backend
    location /api/ {
        proxy_pass http://localhost:8080/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Upload size limits
        client_max_body_size 10M;
    }

    # Frontend static files
    location / {
        root /var/www/shop-management/frontend;
        try_files $uri $uri/ /index.html;
    }
}
NGINX

# 8. Enable Nginx site
sudo ln -sf /etc/nginx/sites-available/shop-management /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# 9. Create systemd service for backend
echo "Creating systemd service..."
cat << 'SERVICE' | sudo tee /etc/systemd/system/shop-management.service
[Unit]
Description=Shop Management Backend
After=syslog.target

[Service]
User=www-data
WorkingDirectory=/opt/shop-management
ExecStart=/usr/bin/java -jar /opt/shop-management/shop-management-backend.jar --spring.profiles.active=production
SuccessExitStatus=143
TimeoutStopSec=10
Restart=on-failure
RestartSec=5

# Environment variables
Environment="DB_URL=jdbc:postgresql://localhost:5432/shop_management_db"
Environment="DB_USERNAME=shopuser"
Environment="DB_PASSWORD=your_secure_password_here"
Environment="JWT_SECRET=your_very_long_secret_key_here_minimum_32_characters"
Environment="FILE_STORAGE_PATH=/var/www/shop-management/uploads"
Environment="APP_UPLOAD_DIR=/var/www/shop-management/uploads"
Environment="DOCUMENT_UPLOAD_PATH=/var/www/shop-management/uploads/documents"
Environment="PRODUCT_IMAGES_PATH=/var/www/shop-management/uploads/products"

[Install]
WantedBy=multi-user.target
SERVICE

# 10. Reload systemd
sudo systemctl daemon-reload

echo "=== Setup Complete ==="
echo ""
echo "IMPORTANT: Your file storage configuration:"
echo "- Upload directory: /var/www/shop-management/uploads"
echo "- Storage used: Your FREE 60GB Hetzner disk space"
echo "- No additional cost!"
echo "- Files served directly via Nginx"
echo ""
echo "Next steps:"
echo "1. Upload your JAR file to /opt/shop-management/"
echo "2. Start the service: sudo systemctl start shop-management"
echo "3. Enable auto-start: sudo systemctl enable shop-management"
echo "4. Check status: sudo systemctl status shop-management"
echo ""
echo "File upload URLs will be:"
echo "https://nammaoorudelivary.in/uploads/products/[filename]"
echo "https://nammaoorudelivary.in/uploads/documents/shops/[shopId]/[filename]"