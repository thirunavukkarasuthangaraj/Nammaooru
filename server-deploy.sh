#!/bin/bash
# Run this script ON THE SERVER (not locally)
# ssh root@65.21.4.236 then run this script

echo "🚀 Moving frontend build to nginx directory..."

# Backup current site
if [ -d "/var/www/html/backup" ]; then
    rm -rf /var/www/html/backup-old
    mv /var/www/html/backup /var/www/html/backup-old
fi
mkdir -p /var/www/html/backup
cp /var/www/html/*.html /var/www/html/backup/ 2>/dev/null || true

# Clear nginx directory
rm -rf /var/www/html/*

# Copy new build
cp -r /opt/shop-management/frontend/dist/shop-management-frontend/* /var/www/html/

# Set permissions
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

# Test and reload nginx
nginx -t
if [ $? -eq 0 ]; then
    systemctl reload nginx
    echo "✅ Frontend deployed successfully!"
    echo "🌐 Site: https://nammaoorudelivary.in"
else
    echo "❌ Nginx config error - check configuration"
fi

# Also fix upload directories while we're here
echo "🔧 Ensuring upload directories exist..."
cd /opt/shop-management
mkdir -p uploads/products/master uploads/products/shop uploads/shops
chmod -R 755 uploads/
chown -R root:root uploads/

echo "✅ All done!"
ls -la /var/www/html/