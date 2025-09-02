# Troubleshooting Guide - NammaOoru Shop Management System

## Quick Reference - Common Issues

| Issue | Quick Fix | Documentation |
|-------|-----------|---------------|
| Email not sending | Check FROM address matches SMTP username | [Email Issues](#email-issues) |
| Container won't start | `docker-compose down && docker-compose up --build -d` | [Docker Issues](#docker-issues) |
| API timeout | Check network, increase timeout values | [Network Issues](#network-issues) |
| Mobile app not connecting | Verify API base URL and network | [Mobile Issues](#mobile-app-issues) |
| Database connection failed | Check credentials and container status | [Database Issues](#database-issues) |

## Email Issues

### 1. "Sender address rejected: not owned by user"

**Symptom**: OTP emails not sending, error in backend logs
```
MessagingException: 554 5.7.1 Sender address rejected: not owned by user
```

**Root Cause**: FROM email address doesn't match SMTP authenticated user

**Solution**:
```yaml
# application.yml - Ensure FROM matches SMTP username
email:
  from: ${EMAIL_FROM_ADDRESS:noreplay@nammaoorudelivary.in}  # Must match SMTP username
  
spring:
  mail:
    username: ${MAIL_USERNAME:noreplay@nammaoorudelivary.in}  # Must match FROM address
```

**Prevention**: Always use the same email address for both FROM and SMTP authentication

---

### 2. SocketTimeoutException: Connect timed out

**Symptom**: Email sending hangs, timeout errors in logs
```
java.net.SocketTimeoutException: Connect timed out
```

**Root Cause**: Network/firewall blocking SMTP ports

**Diagnosis**:
```bash
# Test SMTP connectivity
telnet smtp.hostinger.com 587
telnet smtp.hostinger.com 465

# Check firewall rules
ufw status
```

**Solution**:
```bash
# Open SMTP ports in firewall
ufw allow 587/tcp
ufw allow 465/tcp
ufw reload

# For Hetzner servers, also add in Hetzner Console:
# Firewall Rules: Add ports 587, 465
```

---

### 3. SSL/TLS Handshake Failure

**Symptom**: SSL handshake errors, certificate issues
```
javax.net.ssl.SSLHandshakeException: Received fatal alert: handshake_failure
```

**Root Cause**: Java SSL incompatibility with SMTP server

**Solution**:
```yaml
# application.yml - Add SSL bypass configuration
spring:
  mail:
    properties:
      mail:
        smtp:
          ssl:
            trust: "*"  # Trust all certificates
          socketFactory:
            class: javax.net.ssl.SSLSocketFactory
            fallback: false
```

**Alternative**: Switch to port 587 with STARTTLS instead of port 465 SSL

---

### 4. Email Sent But Not Received

**Diagnosis Checklist**:
- [ ] Check spam/junk folder
- [ ] Verify recipient email address is valid
- [ ] Check SMTP logs for delivery confirmation
- [ ] Test with different email provider (Gmail, Yahoo)
- [ ] Check domain reputation (sender reputation)

**Solution**:
```bash
# Check email logs
docker-compose logs backend | grep -i "mail\|smtp\|email"

# Test with curl
curl -X POST https://api.nammaoorudelivary.in/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email": "test@gmail.com"}'
```

---

## Docker Issues

### 1. Container Won't Start

**Symptom**: Container exits immediately or fails to start
```
ERROR: Service 'backend' failed to build
```

**Diagnosis**:
```bash
# Check container status
docker-compose ps

# View detailed logs
docker-compose logs backend

# Check for port conflicts
netstat -tulpn | grep :8082
```

**Solution**:
```bash
# Clean rebuild
docker-compose down
docker system prune -a -f
docker-compose up --build -d

# If still failing, check:
# 1. Environment variables in .env file
# 2. Port availability
# 3. Docker daemon status
```

---

### 2. Database Connection Failed

**Symptom**: Backend can't connect to PostgreSQL
```
org.postgresql.util.PSQLException: Connection refused
```

**Diagnosis**:
```bash
# Check database container
docker-compose logs db

# Test database connectivity
docker-compose exec db psql -U postgres -l
```

**Solution**:
```bash
# Restart database container
docker-compose restart db

# If data corruption:
docker-compose down
docker volume rm shop-management-system_postgres_data
docker-compose up -d db
```

---

### 3. Out of Disk Space

**Symptom**: Docker operations failing due to space
```
no space left on device
```

**Diagnosis**:
```bash
# Check disk usage
df -h
docker system df

# Check Docker volumes
docker volume ls
```

**Solution**:
```bash
# Clean up Docker resources
docker system prune -a -f
docker volume prune -f

# Remove unused images
docker image prune -a -f

# Check application logs for large files
du -sh /opt/shop-management/uploads/
```

---

## Network Issues

### 1. API Connection Timeout

**Symptom**: Mobile app or frontend can't reach backend
```
Network Error: timeout of 30000ms exceeded
```

**Diagnosis**:
```bash
# Test API endpoint
curl -I https://api.nammaoorudelivary.in/api/actuator/health

# Check nginx status
systemctl status nginx
nginx -t

# Check backend container
docker-compose logs backend
```

**Solution**:
```bash
# Restart nginx
systemctl restart nginx

# Increase timeout in nginx
# /etc/nginx/sites-available/default
proxy_read_timeout 300;
proxy_connect_timeout 300;
proxy_send_timeout 300;

# Restart backend container
docker-compose restart backend
```

---

### 2. CORS Issues

**Symptom**: Frontend JavaScript errors about CORS
```
Access to fetch at 'https://api.nammaoorudelivary.in' has been blocked by CORS policy
```

**Root Cause**: Missing or incorrect CORS configuration

**Solution**:
```yaml
# application.yml - Update CORS settings
app:
  cors:
    allowed-origins: ${CORS_ALLOWED_ORIGINS:https://nammaoorudelivary.in,https://www.nammaoorudelivary.in,http://localhost:4200}
    allowed-methods: ${CORS_ALLOWED_METHODS:GET,POST,PUT,DELETE,OPTIONS}
    allowed-headers: ${CORS_ALLOWED_HEADERS:*}
    allow-credentials: ${CORS_ALLOW_CREDENTIALS:true}
```

---

### 3. SSL Certificate Issues

**Symptom**: HTTPS not working, certificate warnings
```
NET::ERR_CERT_AUTHORITY_INVALID
```

**Diagnosis**:
```bash
# Check certificate status
openssl s_client -connect nammaoorudelivary.in:443

# Check nginx SSL configuration
nginx -t
```

**Solution**:
```bash
# Renew Let's Encrypt certificate
certbot renew --nginx

# Or install new certificate
certbot --nginx -d nammaoorudelivary.in -d www.nammaoorudelivary.in
```

---

## Mobile App Issues

### 1. API Connection Failed

**Symptom**: Mobile app shows "Network Error" or "Connection Failed"

**Diagnosis**:
```dart
// Enable debug logging in ApiClient
if (kDebugMode) {
  _dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
  ));
}
```

**Solution**:
```dart
// Check base URL in api_client.dart
baseUrl: 'https://api.nammaoorudelivary.in/api',  // Must be correct

// Increase timeout values
connectTimeout: const Duration(seconds: 60),
receiveTimeout: const Duration(seconds: 60),
```

---

### 2. OTP Not Received on Mobile

**Symptom**: User registration hangs at OTP step

**Diagnosis**:
1. Check if backend API is working: `curl -X POST https://api.nammaoorudelivary.in/api/auth/send-otp`
2. Check backend logs for email errors
3. Verify email address entered correctly
4. Check spam folder on mobile email app

**Solution**:
```dart
// Add better error handling in register_screen.dart
try {
  final response = await ApiClient.post('/auth/send-otp', data: {'email': email});
  if (response.statusCode == 200) {
    showSuccessDialog('OTP sent to your email');
  }
} catch (e) {
  showErrorDialog('Failed to send OTP: ${e.toString()}');
}
```

---

### 3. App Crashes on Startup

**Symptom**: Flutter app crashes immediately after launch

**Diagnosis**:
```bash
# Check device logs
adb logcat | grep -i flutter

# Run in debug mode
flutter run --debug
```

**Common Causes & Solutions**:
1. **Missing permissions**: Add required permissions in `android/app/src/main/AndroidManifest.xml`
2. **Plugin conflicts**: Run `flutter clean && flutter pub get`
3. **Build configuration**: Check `android/app/build.gradle` Java version compatibility

---

### 4. Image Upload Fails

**Symptom**: Shop or product image uploads not working

**Diagnosis**:
```dart
// Add debugging to image upload
print('File size: ${file.lengthSync()} bytes');
print('File path: ${file.path}');
print('MIME type: ${lookupMimeType(file.path)}');
```

**Solution**:
```dart
// Check file size limits
if (file.lengthSync() > 10 * 1024 * 1024) {  // 10MB limit
  showError('File too large. Please select a smaller image.');
  return;
}

// Compress image before upload
final compressedFile = await compressImage(file);
```

---

## Database Issues

### 1. Database Migration Failed

**Symptom**: Backend startup fails with database errors
```
Schema validation failed: Missing table or column
```

**Solution**:
```bash
# Check current database state
docker-compose exec db psql -U postgres -d shop_management_db -c "\dt"

# Reset database (WARNING: Data loss)
docker-compose down
docker volume rm shop-management-system_postgres_data
docker-compose up -d
```

---

### 2. Data Corruption

**Symptom**: Inconsistent data, foreign key violations
```
ERROR: insert or update on table violates foreign key constraint
```

**Solution**:
```sql
-- Check data integrity
SELECT * FROM users WHERE id NOT IN (SELECT DISTINCT owner_id FROM shops WHERE owner_id IS NOT NULL);

-- Fix orphaned records
DELETE FROM shops WHERE owner_id NOT IN (SELECT id FROM users);
```

---

### 3. Performance Issues

**Symptom**: Slow database queries, high CPU usage

**Diagnosis**:
```sql
-- Check slow queries
SELECT query, mean_exec_time, calls 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;

-- Check missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation 
FROM pg_stats 
WHERE schemaname = 'public' 
ORDER BY n_distinct DESC;
```

**Solution**:
```sql
-- Add indexes for frequently queried columns
CREATE INDEX CONCURRENTLY idx_shops_owner_id ON shops(owner_id);
CREATE INDEX CONCURRENTLY idx_products_shop_id ON products(shop_id);
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
```

---

## Performance Issues

### 1. High Memory Usage

**Symptom**: Server running out of memory, containers getting killed

**Diagnosis**:
```bash
# Check memory usage
free -h
docker stats

# Check application memory
docker-compose exec backend jstat -gc 1
```

**Solution**:
```yaml
# docker-compose.yml - Add memory limits
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
```

---

### 2. Slow API Response

**Symptom**: API endpoints taking too long to respond

**Diagnosis**:
```bash
# Test API response time
time curl https://api.nammaoorudelivary.in/api/shops

# Check backend logs for slow queries
docker-compose logs backend | grep -i "slow"
```

**Solution**:
```yaml
# application.yml - Optimize database connection pool
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 20000
```

---

## Security Issues

### 1. Unauthorized Access

**Symptom**: API endpoints accessible without authentication

**Solution**:
```java
// SecurityConfig.java - Ensure proper security configuration
@Override
protected void configure(HttpSecurity http) throws Exception {
    http
        .authorizeRequests()
        .antMatchers("/api/auth/**").permitAll()
        .anyRequest().authenticated()
        .and()
        .oauth2ResourceServer()
        .jwt();
}
```

---

### 2. JWT Token Issues

**Symptom**: Authentication failing, token expired errors

**Diagnosis**:
```bash
# Check JWT secret configuration
docker-compose exec backend printenv | grep JWT

# Decode JWT token (for debugging)
echo "YOUR_JWT_TOKEN" | base64 -d
```

**Solution**:
```yaml
# application.yml - Configure JWT properly
jwt:
  secret: ${JWT_SECRET:your-256-bit-secret-key-here}
  expiration: 86400000  # 24 hours
```

---

## Emergency Recovery Procedures

### 1. Complete System Recovery

```bash
# Stop all services
docker-compose down

# Backup current state (if possible)
tar -czf backup_$(date +%Y%m%d).tar.gz /opt/shop-management/

# Clean slate restart
docker system prune -a -f
git pull origin main
docker-compose up --build -d

# Restore database from backup (if needed)
docker-compose exec -T db psql -U postgres -d shop_management_db < backup.sql
```

### 2. Rollback to Previous Version

```bash
# Check git history
git log --oneline -10

# Rollback to stable commit
git checkout <stable-commit-hash>
docker-compose up --build -d

# If rollback successful, create new branch
git checkout -b hotfix-$(date +%Y%m%d)
git push origin hotfix-$(date +%Y%m%d)
```

---

## Monitoring and Alerting

### 1. Health Check Scripts

```bash
#!/bin/bash
# health-check.sh

# API Health
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://api.nammaoorudelivary.in/api/actuator/health)
if [ "$API_STATUS" != "200" ]; then
    echo "ALERT: API is down (Status: $API_STATUS)"
    # Send notification (email, Slack, etc.)
fi

# Database Health
DB_STATUS=$(docker-compose exec -T db pg_isready -U postgres)
if [ $? -ne 0 ]; then
    echo "ALERT: Database is not responding"
fi

# Email Service Health
EMAIL_TEST=$(curl -s -X POST https://api.nammaoorudelivary.in/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email": "healthcheck@example.com"}' \
  -w "%{http_code}")
if [[ "$EMAIL_TEST" != *"200"* ]]; then
    echo "ALERT: Email service is not working"
fi
```

### 2. Log Monitoring

```bash
# Monitor for critical errors
tail -f /var/log/nginx/error.log | grep -i error
docker-compose logs -f backend | grep -i "error\|exception\|failed"
```

---

## Contact and Support

### Emergency Contacts
- **System Admin**: root@65.21.4.236
- **Domain Provider**: Hostinger Support
- **Server Provider**: Hetzner Support

### Documentation References
- [Email Configuration](EMAIL_CONFIGURATION.md)
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
- [Mobile App Guide](MOBILE_APP_GUIDE.md)

### Useful Commands Reference
```bash
# Quick status check
docker-compose ps && curl -I https://api.nammaoorudelivary.in/api/actuator/health

# View all logs
docker-compose logs -f

# Restart everything
docker-compose restart

# Nuclear option (rebuild everything)
docker-compose down && docker system prune -a -f && docker-compose up --build -d
```

---

**Last Updated**: January 2025
**Emergency Hotline**: Check server status first, then review this guide
**Status**: ✅ All systems operational