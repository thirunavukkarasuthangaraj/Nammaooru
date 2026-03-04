# 12 - Backup & Disaster Recovery

## What You'll Learn
- Backup strategies
- Hetzner backups and snapshots
- Database backup
- Disaster recovery plan

---

## 1. What to Backup

```
CRITICAL (lose this = lose business):
  ✅ PostgreSQL database (orders, users, shops, products)
  ✅ Uploaded files (product images, documents)
  ✅ Environment variables (.env file)
  ✅ SSL certificates (or just re-generate with Certbot)

IMPORTANT (lose this = hours of work):
  ✅ Nginx configuration
  ✅ Docker Compose files
  ✅ Deployment scripts

ALREADY SAFE (in Git):
  ✅ Source code (GitHub)
  ✅ Database migrations (Flyway)
```

---

## 2. Hetzner Backups & Snapshots

### Backups (Automatic - Enable This!):
```
Your dashboard shows: BACKUPS -> Enable

Cost: 20% of server price = ~$1.20/month
Frequency: Weekly automatic backups
Retention: Last 3 backups kept

Enable: Hetzner Console -> Server -> Backups -> Enable
```

### Snapshots (Manual):
```
Your dashboard: Snapshots tab

Create before risky operations:
  - Before major deployments
  - Before server upgrades
  - Before OS updates

Hetzner Console -> Server -> Snapshots -> Create Snapshot
Cost: $0.012/GB/month
```

---

## 3. Database Backup

```bash
# Manual backup
pg_dump -U postgres shop_management_db > backup_$(date +%Y%m%d).sql

# Compressed backup
pg_dump -U postgres shop_management_db | gzip > backup_$(date +%Y%m%d).sql.gz

# Automated daily backup (add to crontab)
crontab -e
# Add:
0 2 * * * pg_dump -U postgres shop_management_db | gzip > /mnt/HC_Volume_XXXXXX/backups/db_$(date +\%Y\%m\%d).sql.gz

# Keep only last 7 days
0 3 * * * find /mnt/HC_Volume_XXXXXX/backups/ -name "db_*.sql.gz" -mtime +7 -delete

# Restore from backup
gunzip < backup_20260303.sql.gz | psql -U postgres shop_management_db
```

---

## 4. Disaster Recovery Plan

```
Scenario: Server completely dies

Recovery Steps:
1. Create new Hetzner server (same spec CX33)
2. Restore from latest Hetzner snapshot OR:
   a. Install Docker, Nginx, PostgreSQL
   b. Clone repo from GitHub
   c. Restore .env from secure backup
   d. Restore database from backup file
   e. Restore uploaded files from volume backup
   f. Run docker-compose up -d
   g. Setup SSL: certbot --nginx
   h. Update DNS to point to new server IP
3. Test everything works
4. Time to recover: ~30-60 minutes with snapshots

Keep backups in MULTIPLE locations:
  Location 1: Hetzner Volume (/mnt/HC_Volume_...)
  Location 2: Hetzner Snapshot
  Location 3: External (download to local / other cloud)
```

---

## Key Takeaways

1. **Enable Hetzner Backups** - costs only ~$1.20/month (DO THIS NOW!)
2. **Automate database backups** - daily cron job with 7-day retention
3. **Create snapshots** before risky changes
4. **Test restoring** from backup at least once
5. **Keep .env file** backed up securely (not in Git!)

---

## Next: [13 - Database Administration](./13-database-admin.md)
