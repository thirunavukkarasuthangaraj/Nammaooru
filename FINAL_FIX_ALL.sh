#!/bin/bash
# ONE SCRIPT TO FIX EVERYTHING

cd /opt/shop-management

# 1. Fix nginx for images
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80;
    server_name nammaoorudelivary.in www.nammaoorudelivary.in;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /api/ {
        proxy_pass http://localhost:8082/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Origin $http_origin;
        proxy_pass_header Access-Control-Allow-Origin;
        proxy_pass_header Access-Control-Allow-Methods;
        proxy_pass_header Access-Control-Allow-Headers;
        proxy_pass_header Access-Control-Allow-Credentials;
    }

    # SERVE IMAGES DIRECTLY
    location /api/uploads/ {
        alias /var/lib/docker/volumes/shop-management_uploads_data/_data/;
        autoindex on;
        add_header Access-Control-Allow-Origin "*" always;
        add_header Cache-Control "public, max-age=31536000";
    }
}
EOF

# 2. Reload nginx
systemctl reload nginx

echo "✅ DONE! Images should work at: https://nammaoorudelivary.in/api/uploads/..."