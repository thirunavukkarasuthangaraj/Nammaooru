#!/bin/bash

# Backup PostgreSQL to Hetzner Storage Box
# Cost: Only €3.20/month for 1TB backup storage!

# Storage Box credentials (replace with yours)
STORAGE_USER="u12345"
STORAGE_HOST="u12345.your-storagebox.de"
STORAGE_PATH="/backups/postgres"

# Local backup
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="/tmp/db_backup_$DATE.sql"

# Create database backup
echo "Creating database backup..."
docker exec shop-postgres pg_dump -U postgres shop_management_db > $BACKUP_FILE

# Compress backup
gzip $BACKUP_FILE

# Upload to Storage Box via SFTP
echo "Uploading to Hetzner Storage Box..."
sftp $STORAGE_USER@$STORAGE_HOST << EOF
cd $STORAGE_PATH
put ${BACKUP_FILE}.gz
EOF

# Clean up local backup
rm ${BACKUP_FILE}.gz

# Remove old backups from Storage Box (keep 30 days)
ssh $STORAGE_USER@$STORAGE_HOST "find $STORAGE_PATH -name '*.sql.gz' -mtime +30 -delete"

echo "Backup completed and uploaded to Storage Box!"