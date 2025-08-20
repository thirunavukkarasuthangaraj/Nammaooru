#!/bin/bash

# Setup script for API SSL on Hetzner server
# Run this on your server as root

echo "🔐 Setting up SSL for API..."

# Install nginx if not present
if ! command -v nginx &> /dev/null; then
    echo "Installing nginx..."
    apt-get update
    apt-get install -y nginx
fi

# Install certbot if not present
if ! command -v certbot &> /dev/null; then
    echo "Installing certbot..."
    apt-get install -y certbot python3-certbot-nginx
fi

# Copy nginx configuration
echo "Configuring nginx for API..."
cp nginx-api.conf /etc/nginx/sites-available/api.nammaoorudelivary.in
ln -sf /etc/nginx/sites-available/api.nammaoorudelivary.in /etc/nginx/sites-enabled/

# Test nginx configuration
nginx -t

# Get SSL certificate
echo "Obtaining SSL certificate..."
certbot --nginx -d api.nammaoorudelivary.in --non-interactive --agree-tos --email admin@nammaoorudelivary.in

# Reload nginx
systemctl reload nginx

echo "✅ API SSL setup complete!"
echo "📝 Next steps:"
echo "1. Make sure your DNS A record for api.nammaoorudelivary.in points to 65.21.4.236"
echo "2. Your API will be accessible at https://api.nammaoorudelivary.in"
echo "3. The frontend is already configured to use this URL"