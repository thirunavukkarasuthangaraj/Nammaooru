#!/bin/bash

echo "=== Fixing NGINX CORS Configuration ==="

# Find all nginx config files with CORS headers
echo "Searching for CORS headers in nginx configs..."
CORS_FILES=$(grep -rl "Access-Control" /etc/nginx/ 2>/dev/null)

if [ -z "$CORS_FILES" ]; then
    echo "No CORS headers found in nginx config. Issue might be elsewhere."
    exit 1
fi

echo "Found CORS headers in:"
echo "$CORS_FILES"

# Backup and remove CORS headers from each file
for file in $CORS_FILES; do
    echo ""
    echo "Processing: $file"

    # Create backup
    cp "$file" "$file.backup-$(date +%Y%m%d-%H%M%S)"
    echo "  Backup created: $file.backup-$(date +%Y%m%d-%H%M%S)"

    # Show current CORS lines
    echo "  Current CORS lines:"
    grep -n "Access-Control" "$file"

    # Comment out CORS headers
    sed -i 's/^\(\s*add_header.*Access-Control.*\)/# REMOVED - CORS in SecurityConfig.java only\n# \1/g' "$file"

    echo "  CORS headers commented out"
done

# Test nginx config
echo ""
echo "Testing nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo ""
    echo "Nginx config is valid. Reloading..."
    nginx -s reload
    echo "Nginx reloaded successfully!"
    echo ""
    echo "Testing CORS headers..."
    sleep 2
    curl -I -X OPTIONS https://api.nammaoorudelivary.in/api/auth/login \
         -H "Origin: https://nammaoorudelivary.in" \
         -H "Access-Control-Request-Method: POST" 2>&1 | grep -i "access-control"
else
    echo ""
    echo "ERROR: Nginx config has errors. Restoring backups..."
    for file in $CORS_FILES; do
        LATEST_BACKUP=$(ls -t "$file.backup-"* 2>/dev/null | head -1)
        if [ -n "$LATEST_BACKUP" ]; then
            cp "$LATEST_BACKUP" "$file"
            echo "  Restored: $file"
        fi
    done
    echo "Backups restored. Please check nginx config manually."
    exit 1
fi

echo ""
echo "=== DONE! Login should work now. ==="
