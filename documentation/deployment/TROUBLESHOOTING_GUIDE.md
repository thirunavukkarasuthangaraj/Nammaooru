# 🔧 NammaOoru Thiru Software System - Troubleshooting Guide

## 🚨 Emergency Quick Reference

### System Down? Try These Steps (In Order):
1. **Check container status**: `docker-compose ps`
2. **Restart services**: `docker-compose restart`
3. **Check logs**: `docker-compose logs -f backend`
4. **Nuclear option**: `docker-compose down && docker-compose up --build -d`

### Quick Health Checks:
- **API Health**: `curl https://api.nammaoorudelivary.in/actuator/health`
- **Frontend**: Open https://nammaoorudelivary.in in browser
- **Database**: `docker exec -it <postgres-container> psql -U postgres -l`
- **Email Test**: `curl -X POST https://api.nammaoorudelivary.in/api/auth/send-otp`

---

## 📧 Email Issues (Most Common Problem)

### Symptoms:
- OTP emails not being sent
- "Email service unavailable" errors
- SMTP connection timeouts
- SSL handshake failures

### Solutions:

#### 1. Check SMTP Configuration
```bash
# Verify environment variables
docker-compose exec backend env | grep SMTP

# Should show:
SMTP_HOST=smtp.hostinger.com
SMTP_PORT=587
SMTP_USERNAME=noreplay@nammaoorudelivary.in
SMTP_PASSWORD=<your_password>
```

#### 2. Verify FROM Address Match
**CRITICAL**: The FROM address must match SMTP username
```yaml
# In application.yml or environment variables
spring:
  mail:
    username: noreplay@nammaoorudelivary.in  # SMTP username
    properties:
      from: noreplay@nammaoorudelivary.in    # Must be SAME as username
```

#### 3. Test SMTP Connection
```bash
# Test from server
telnet smtp.hostinger.com 587

# Should connect successfully
# If timeout, check firewall
```

#### 4. Check Backend Logs for Email Errors
```bash
# Look for email-related errors
docker-compose logs backend | grep -i "mail\|smtp\|email"

# Common errors and fixes:
# "AuthenticationFailedException" → Wrong password
# "MessagingException" → Wrong SMTP settings  
# "SSL handshake failed" → Wrong port/SSL config
# "Connection timed out" → Firewall blocking port
```

#### 5. Fix SSL/TLS Configuration
```yaml
# Correct SMTP configuration
spring:
  mail:
    host: smtp.hostinger.com
    port: 587
    username: noreplay@nammaoorudelivary.in
    password: ${SMTP_PASSWORD}
    properties:
      mail.smtp.auth: true
      mail.smtp.starttls.enable: true
      mail.smtp.starttls.required: true
      from: noreplay@nammaoorudelivary.in
```

---

## 🐳 Docker Issues

### Container Won't Start
```bash
# Check container logs
docker-compose logs <service-name>

# Common issues:
# - Port already in use → Change ports in docker-compose.yml
# - Environment variables missing → Check .env file
# - Build failures → docker-compose build --no-cache
```

### Database Connection Issues
```bash
# Check PostgreSQL container
docker-compose ps postgres

# Test connection
docker exec -it <postgres-container> psql -U postgres -d shop_management_db

# If connection fails:
# 1. Check if PostgreSQL is running
docker-compose restart postgres

# 2. Check environment variables
docker-compose exec backend env | grep DB_

# 3. Check network connectivity
docker-compose exec backend ping postgres
```

### Out of Disk Space
```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a -f
docker volume prune -f

# Clean up old images
docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi
```

---

## 🌐 Network & SSL Issues

### SSL Certificate Problems
```bash
# Check certificate status
openssl x509 -in /etc/letsencrypt/live/nammaoorudelivary.in/cert.pem -text -noout

# Check expiry date
openssl x509 -in /etc/letsencrypt/live/nammaoorudelivary.in/cert.pem -noout -dates

# Renew certificate
certbot renew --dry-run
certbot renew

# If renewal fails, regenerate
certbot delete --cert-name nammaoorudelivary.in
certbot certonly --standalone -d nammaoorudelivary.in -d api.nammaoorudelivary.in
```

### Nginx Configuration Issues
```bash
# Test nginx configuration
nginx -t

# Reload nginx
systemctl reload nginx

# Check nginx logs
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log

# Common nginx errors:
# 502 Bad Gateway → Backend not responding
# 504 Gateway Timeout → Backend too slow
# SSL errors → Check certificate paths
```

### Firewall Issues
```bash
# Check firewall status
ufw status verbose

# Check if ports are open
netstat -tlnp | grep :80
netstat -tlnp | grep :443
netstat -tlnp | grep :587  # SMTP

# Open required ports
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 587/tcp  # If SMTP blocked
```

---

## 🗄️ Database Issues

### Database Won't Start
```bash
# Check PostgreSQL logs
docker-compose logs postgres

# Common issues:
# - Permission denied → Check volume permissions
# - Port conflict → Change port in docker-compose.yml
# - Corrupted data → docker volume rm postgres_data (WARNING: Data loss!)
```

### Connection Pool Exhaustion
```bash
# Check active connections
docker exec -it <postgres-container> psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"

# Kill idle connections
docker exec -it <postgres-container> psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle';"
```

### Database Performance Issues
```bash
# Check slow queries
docker exec -it <postgres-container> psql -U postgres -d shop_management_db -c "SELECT query, calls, total_time, rows, 100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent FROM pg_stat_statements ORDER BY total_time DESC LIMIT 5;"

# Check database size
docker exec -it <postgres-container> psql -U postgres -c "SELECT pg_database_size('shop_management_db');"
```

---

## 🔌 API Issues

### Backend Not Responding
```bash
# Check backend container
docker-compose ps backend

# Check backend logs
docker-compose logs -f backend

# Test API directly
curl http://localhost:8080/actuator/health

# Common issues:
# - JVM out of memory → Increase container memory
# - Database connection failed → Check DB config
# - Port conflict → Change port
```

### API Endpoints Returning Errors
```bash
# Check specific endpoint
curl -v https://api.nammaoorudelivary.in/api/shops

# Check authentication
curl -H "Authorization: Bearer <token>" https://api.nammaoorudelivary.in/api/orders

# Common HTTP status codes:
# 401 Unauthorized → Invalid/expired token
# 403 Forbidden → Insufficient permissions
# 404 Not Found → Wrong endpoint URL
# 500 Internal Server Error → Check backend logs
```

### CORS Issues
```bash
# Test CORS from browser console
fetch('https://api.nammaoorudelivary.in/api/shops', {
  method: 'GET',
  headers: {'Authorization': 'Bearer <token>'}
}).then(r => r.json()).then(console.log)

# If CORS error, check nginx configuration
# Look for Access-Control-Allow-Origin headers
```

---

## 📱 Mobile App Issues

### App Can't Connect to API
```dart
// Enable debug logging
void main() {
  if (kDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }
  runApp(MyApp());
}

// Check API endpoint configuration
class ApiEndpoints {
  static const String baseUrl = 'https://api.nammaoorudelivary.in/api';  // Verify URL
}
```

### Login Not Working
```bash
# Test login endpoint
curl -X POST "https://api.nammaoorudelivary.in/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password"}'

# Check response for errors
```

### Build Issues
```bash
# Flutter build issues
flutter clean
flutter pub get
rm -rf ~/.pub-cache  # Nuclear option

# Android build issues
cd android
./gradlew clean

# iOS build issues
cd ios
pod install --clean-install
```

---

## 💾 Performance Issues

### High Memory Usage
```bash
# Check container memory usage
docker stats

# Check system memory
free -h

# If backend using too much memory:
# 1. Check for memory leaks in logs
# 2. Restart backend container
docker-compose restart backend
```

### Slow API Response Times
```bash
# Check backend performance
curl -w "@curl-format.txt" -o /dev/null -s "https://api.nammaoorudelivary.in/api/shops"

# curl-format.txt:
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n

# Check database query performance
docker exec -it <postgres-container> psql -U postgres -d shop_management_db -c "EXPLAIN ANALYZE SELECT * FROM orders LIMIT 10;"
```

### Disk Space Issues
```bash
# Check disk usage
df -h

# Find large files
du -h --max-depth=1 /var/lib/docker/
du -h --max-depth=1 /var/log/

# Clean up logs
sudo truncate -s 0 /var/log/nginx/*.log
docker-compose logs backend | head -n 1000 > recent_backend.log
```

---

## 🔐 Security Issues

### JWT Token Issues
```bash
# Test token validation
curl -H "Authorization: Bearer <token>" https://api.nammaoorudelivary.in/api/orders

# If token invalid:
# 1. Check token expiry
# 2. Verify JWT secret in environment variables
# 3. Check token format (should start with 'Bearer ')
```

### Unauthorized Access Attempts
```bash
# Check nginx access logs for suspicious activity
tail -f /var/log/nginx/access.log | grep -E "(401|403|404)"

# Check for brute force attempts
grep "401" /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -nr

# Block suspicious IPs
ufw deny from <suspicious-ip>
```

---

## 🚀 Deployment Issues

### Deployment Fails
```bash
# Check git status
git status
git log --oneline -5

# Check Docker build
docker-compose build --no-cache

# Check environment variables
cat .env  # Verify all required variables are set

# Common deployment failures:
# - Missing environment variables
# - Docker build context issues
# - Port conflicts
# - SSL certificate problems
```

### Service Won't Start After Deployment
```bash
# Check all services
docker-compose ps

# Check logs for all services
docker-compose logs

# Restart specific service
docker-compose restart <service-name>

# Full restart
docker-compose down && docker-compose up -d
```

---

## 🔍 Monitoring & Logging

### Check System Health
```bash
# Overall system status
systemctl status nginx
docker-compose ps
df -h
free -h
uptime

# Check for errors in logs
docker-compose logs backend | grep -i error
tail -50 /var/log/nginx/error.log
```

### Performance Monitoring
```bash
# Real-time system monitoring
htop

# Docker container monitoring
docker stats

# Network monitoring
netstat -tlnp

# Disk I/O monitoring
iotop
```

### Log Analysis
```bash
# Backend application logs
docker-compose logs backend | grep -E "(ERROR|WARN)"

# Nginx access patterns
tail -1000 /var/log/nginx/access.log | awk '{print $7}' | sort | uniq -c | sort -nr

# Database connections
docker exec -it <postgres-container> psql -U postgres -c "SELECT count(*), state FROM pg_stat_activity GROUP BY state;"
```

---

## 📋 Emergency Procedures

### Complete System Recovery
```bash
# 1. Stop all services
docker-compose down

# 2. Backup important data
cp -r uploads /backup/
cp -r .env /backup/
docker exec <postgres-container> pg_dump -U postgres shop_management_db > /backup/db_backup.sql

# 3. Clean everything
docker system prune -a -f
docker volume prune -f

# 4. Restore from git
git stash  # Save any local changes
git pull origin main

# 5. Rebuild everything
docker-compose up --build -d

# 6. Restore data if needed
docker exec -i <postgres-container> psql -U postgres shop_management_db < /backup/db_backup.sql
```

### Database Recovery
```bash
# 1. Backup current state
docker exec <postgres-container> pg_dump -U postgres shop_management_db > current_backup.sql

# 2. Stop backend to prevent writes
docker-compose stop backend

# 3. Restore from backup
docker exec -i <postgres-container> psql -U postgres shop_management_db < backup_file.sql

# 4. Start backend
docker-compose start backend
```

---

## 📞 Getting Help

### Before Contacting Support:
1. **Check this troubleshooting guide first**
2. **Gather error logs**: `docker-compose logs > all_logs.txt`
3. **Note what you were trying to do when the issue occurred**
4. **Try basic fixes**: restart, check logs, verify configuration

### Information to Provide:
- **Error messages**: Exact text of any error messages
- **Steps to reproduce**: What were you doing when it broke?
- **System status**: Output of `docker-compose ps` and `systemctl status nginx`
- **Logs**: Relevant portions of error logs
- **Environment**: Any recent changes to configuration

### Common Commands for Support:
```bash
# System information
uname -a
docker --version
docker-compose --version
nginx -v

# Container status
docker-compose ps
docker stats --no-stream

# Recent logs
docker-compose logs --tail=100 backend > backend_logs.txt
tail -100 /var/log/nginx/error.log > nginx_errors.txt

# Configuration
docker-compose config
cat .env | grep -v PASSWORD  # Don't share passwords!
```

---

## 🎓 Prevention Tips

### Regular Maintenance
- **Weekly**: Check disk space, review error logs
- **Monthly**: Update system packages, rotate logs
- **Quarterly**: Review security, update documentation

### Monitoring Setup
```bash
# Setup log monitoring
tail -f /var/log/nginx/error.log | grep -i error &
docker-compose logs -f backend | grep -i error &

# Setup alerts
echo "*/5 * * * * df -h | grep -E '9[0-9]%|100%' && echo 'Disk space critical' | mail admin@example.com" | crontab -
```

### Best Practices
1. **Always backup before changes**
2. **Test in staging environment first**
3. **Keep documentation updated**
4. **Monitor system resources**
5. **Review logs regularly**

---

**Last Updated**: January 2025  
**Status**: Active troubleshooting guide  
**Next Review**: When new issues are discovered or resolved  

---

*Remember: Most issues can be resolved with basic steps. When in doubt, restart the service, check the logs, and verify the configuration.*