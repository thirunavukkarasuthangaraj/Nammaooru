#!/bin/bash

# PostgreSQL Backup Script for Production
# Run this daily via cron job

BACKUP_DIR="/opt/backups/postgres"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="shop_management_db"

# Create backup directory
mkdir -p $BACKUP_DIR

# Create backup
docker exec shop-postgres pg_dump -U postgres $DB_NAME > $BACKUP_DIR/backup_$DATE.sql

# Keep only last 7 days of backups
find $BACKUP_DIR -name "backup_*.sql" -mtime +7 -delete

echo "Backup completed: backup_$DATE.sql"