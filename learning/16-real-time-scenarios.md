# 16 - Real-Time Scenarios & Troubleshooting

## Real-World Scenarios You'll Face Running YourApp

---

## Scenario 1: Server is Slow (High Response Times)

### Symptoms:
- Users complain app is slow
- API responses take >2 seconds

### Diagnosis (Step by Step):

```bash
# Step 1: Check server resources
ssh root@YOUR_SERVER_IP
htop
# Look for: CPU near 100%? RAM near 8GB?

# Step 2: Check Docker containers
docker stats --no-stream
# Which container is using most resources?

# Step 3: Check Nginx
tail -f /var/log/nginx/error.log
# Any 502/504 errors?

# Step 4: Check backend logs
docker logs --tail 100 backend-container
# Any OutOfMemoryError? Connection pool exhausted?

# Step 5: Check database
psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"
# Too many connections? (>20 = problem)

psql -U postgres -c "SELECT pid, now()-query_start AS duration, query
FROM pg_stat_activity WHERE state='active' ORDER BY duration DESC LIMIT 5;"
# Any query running for >5 seconds?

# Step 6: Check disk space
df -h
# If disk is 90%+ full, that's the problem!
```

### Solutions:
```
CPU high?     -> Scale up server (CX33 -> CX53) or optimize code
RAM high?     -> Increase JVM memory or reduce connection pool
DB slow?      -> Add indexes, optimize queries
Disk full?    -> Clean Docker images: docker system prune
Nginx errors? -> Check backend health, increase timeouts
```

---

## Scenario 2: Website Goes Down (502 Bad Gateway)

### What Users See:
```
502 Bad Gateway
nginx
```

### What This Means:
Nginx is running but can't reach your Spring Boot backend.

### Fix It:

```bash
# Step 1: Is backend container running?
docker ps
# If backend not listed:
docker ps -a  # Check if it crashed

# Step 2: Check why it crashed
docker logs --tail 200 backend-container
# Common causes:
#   OutOfMemoryError -> Increase memory limit
#   Port already in use -> Kill old container
#   Database connection refused -> PostgreSQL down

# Step 3: Restart backend
docker-compose restart backend

# Step 4: If that doesn't work, full restart
docker-compose down
docker-compose up -d

# Step 5: Verify it's working
curl http://localhost:8082/actuator/health
# Should return: {"status":"UP"}
```

---

## Scenario 3: Database Connection Pool Exhausted

### Symptoms:
```
ERROR: HikariPool - Connection is not available, request timed out after 30000ms
```

### Diagnosis:
```bash
# Check active connections
psql -U postgres -c "SELECT count(*), state FROM pg_stat_activity GROUP BY state;"
#  count | state
# -------+--------
#     20 | active     <-- All connections busy!
#      5 | idle

# Check what's holding connections
psql -U postgres -c "SELECT pid, state, query, now()-query_start AS duration
FROM pg_stat_activity WHERE state='active' ORDER BY duration DESC;"
```

### Fix:
```bash
# Kill stuck queries
psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity
WHERE state='active' AND now()-query_start > interval '60 seconds';"

# Increase pool size (in docker-compose.yml environment):
# SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE=30

# Restart backend
docker-compose restart backend
```

---

## Scenario 4: SSL Certificate Expired

### Symptoms:
```
Browser shows: "Your connection is not private"
ERR_CERT_DATE_INVALID
```

### Fix:
```bash
# Check current cert expiration
certbot certificates

# Renew certificate
certbot renew

# If auto-renewal failed:
certbot renew --force-renewal

# Reload Nginx to use new cert
systemctl reload nginx

# Verify
curl -vI https://YOUR_DOMAIN.com 2>&1 | grep "expire"
```

### Prevent:
```bash
# Ensure auto-renewal is set up
systemctl status certbot.timer
# Should show: active (waiting)

# Test renewal works
certbot renew --dry-run
```

---

## Scenario 5: Disk Space Full

### Symptoms:
```
- File uploads fail
- Database can't write
- Docker can't start containers
```

### Fix:
```bash
# Check disk usage
df -h

# Find what's using space
du -sh /* 2>/dev/null | sort -rh | head -10

# Common culprits:
# 1. Docker images
docker system df
docker system prune -a  # Remove unused images

# 2. Docker logs
truncate -s 0 /var/lib/docker/containers/*/*.log

# 3. Nginx logs
truncate -s 0 /var/log/nginx/access.log
truncate -s 0 /var/log/nginx/error.log

# 4. Old database backups
find /mnt/HC_Volume_XXXXXX/backups -mtime +7 -delete

# Set up log rotation to prevent this:
cat > /etc/logrotate.d/nginx << 'EOF'
/var/log/nginx/*.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    sharedscripts
    postrotate
        systemctl reload nginx
    endscript
}
EOF
```

---

## Scenario 6: DDoS Attack / Unusual Traffic

### Symptoms:
```
- Server very slow or unresponsive
- CPU at 100%
- Thousands of requests from same IPs
```

### Immediate Response:
```bash
# Step 1: Identify attacking IPs
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -20
# If one IP has 100,000+ requests -> attack

# Step 2: Block the IP immediately
iptables -A INPUT -s ATTACKER_IP -j DROP

# Step 3: Block in Hetzner Firewall (network level - more effective)
# Hetzner Console -> Firewalls -> Add rule to block IP

# Step 4: Add rate limiting if not already present
# (See 09-traffic-management.md)

# Step 5: Consider enabling Cloudflare (free DDoS protection)
```

---

## Scenario 7: Deploy Goes Wrong (Rollback)

### Symptoms:
```
- New version deployed but app crashes
- Users getting errors
```

### Quick Rollback:
```bash
# Option 1: Docker rollback (fastest)
# Check what containers/images exist
docker images | grep yourapp

# Stop broken container
docker stop backend-new

# Start previous version
docker start backend-old
# Or: docker run -d --name backend -p 8082:8080 yourapp-backend:previous-tag

# Reload Nginx to point to old container
systemctl reload nginx

# Option 2: Git rollback
cd /opt/shop-management
git log --oneline -5
# Find the last good commit
git revert HEAD
docker-compose up -d --build
```

---

## Scenario 8: PostgreSQL Crash / Data Corruption

### Symptoms:
```
- All API calls return 500 errors
- Backend logs: "Connection refused" or "FATAL: database does not exist"
```

### Recovery:
```bash
# Step 1: Check PostgreSQL status
systemctl status postgresql
# If stopped, try starting:
systemctl start postgresql

# Step 2: Check PostgreSQL logs
tail -50 /var/log/postgresql/postgresql-*.log

# Step 3: If data corrupted, restore from backup
# Stop PostgreSQL
systemctl stop postgresql

# Restore from latest backup
gunzip < /mnt/HC_Volume_XXXXXX/backups/db_latest.sql.gz | psql -U postgres shop_management_db

# Start PostgreSQL
systemctl start postgresql

# Step 4: If no backup, restore from Hetzner snapshot
# Hetzner Console -> Snapshots -> Rebuild from snapshot
```

---

## Scenario 9: WebSocket Disconnections

### Symptoms:
```
- Real-time order updates stop working
- Shop owners don't see new orders
- Browser console: "WebSocket connection closed"
```

### Fix:
```bash
# Check Nginx WebSocket config
grep -A5 "ws" /etc/nginx/sites-enabled/*
# Ensure these are present:
# proxy_http_version 1.1;
# proxy_set_header Upgrade $http_upgrade;
# proxy_set_header Connection "upgrade";
# proxy_read_timeout 86400;

# Check if backend WebSocket endpoint is responding
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: test" \
  https://api.YOUR_DOMAIN.com/ws

# Check backend logs for WebSocket errors
docker logs backend-container 2>&1 | grep -i "websocket\|stomp"
```

---

## Scenario 10: Memory Leak in Spring Boot

### Symptoms:
```
- Memory usage gradually increases over hours
- Eventually: OutOfMemoryError
- Container gets killed (OOM killed)
```

### Diagnosis:
```bash
# Monitor memory over time
watch -n 10 'docker stats --no-stream --format "{{.MemUsage}}" backend-container'

# Check JVM heap usage
curl http://localhost:8082/actuator/metrics/jvm.memory.used
curl http://localhost:8082/actuator/metrics/jvm.memory.max

# Check for OOM kills
dmesg | grep -i "oom\|killed"

# Generate heap dump for analysis
docker exec backend-container jmap -dump:format=b,file=/tmp/heap.hprof 1
docker cp backend-container:/tmp/heap.hprof ./heap.hprof
# Analyze with Eclipse MAT or VisualVM
```

### Quick Fix:
```yaml
# Increase memory limits in docker-compose.yml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 1536M    # Increase from 1024M
    environment:
      - JAVA_OPTS=-Xms512m -Xmx1024m  # Increase max heap
```

---

## Quick Reference: Emergency Commands

```bash
# Server status overview
htop                          # CPU/RAM
df -h                         # Disk space
docker stats --no-stream      # Container resources
systemctl status nginx        # Nginx status
systemctl status postgresql   # DB status

# Restart services
systemctl restart nginx
systemctl restart postgresql
docker-compose restart backend
docker-compose restart frontend

# View logs
tail -f /var/log/nginx/error.log
docker logs -f --tail 100 backend-container

# Kill stuck processes
docker stop backend-container && docker start backend-container

# Nuclear option (restarts everything)
docker-compose down && docker-compose up -d
systemctl restart nginx
```

---

## Monitoring Checklist (Check Daily)

```
[ ] Server CPU < 70%
[ ] Server RAM < 80%
[ ] Disk space > 20% free
[ ] Docker containers all healthy (docker ps)
[ ] SSL cert not expiring soon (certbot certificates)
[ ] No errors in Nginx error log
[ ] No OOM kills (dmesg | grep oom)
[ ] Database connections healthy
[ ] Health endpoint returns UP
[ ] Backups running (check backup folder dates)
```
