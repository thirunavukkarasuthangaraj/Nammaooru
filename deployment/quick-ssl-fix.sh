#!/bin/bash

# Quick SSL setup for API on your Hetzner server
# Run this as root on 65.21.4.236

# Create nginx config for API
cat > /etc/nginx/sites-available/api.nammaoorudelivary.in << 'EOF'
server {
    listen 80;
    server_name api.nammaoorudelivary.in;
    
    location / {
        proxy_pass http://localhost:8082;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/api.nammaoorudelivary.in /etc/nginx/sites-enabled/

# Test and reload nginx
nginx -t && systemctl reload nginx

# Get SSL certificate using certbot
certbot --nginx -d api.nammaoorudelivary.in --non-interactive --agree-tos --email thirun2394@gmail.com --redirect

echo "✅ Done! Your API should now be accessible at https://api.nammaoorudelivary.in"