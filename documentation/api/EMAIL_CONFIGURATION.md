# Email Configuration Documentation

## Overview
This document explains the email configuration for the NammaOoru Shop Management System, including SMTP setup, OTP functionality, and troubleshooting steps.

## Current Configuration

### Production Email Settings
- **SMTP Host**: smtp.hostinger.com
- **SMTP Port**: 465 (SSL) / 587 (STARTTLS) 
- **Email Address**: noreplay@nammaoorudelivary.in
- **Password**: noreplaynammaooruDelivary@2025
- **Provider**: Hostinger

### Application Configuration Files

#### 1. Backend Configuration (`backend/src/main/resources/application.yml`)
```yaml
spring:
  mail:
    host: ${MAIL_HOST:smtp.hostinger.com}
    port: ${MAIL_PORT:465}
    username: ${MAIL_USERNAME:noreplay@nammaoorudelivary.in}
    password: ${MAIL_PASSWORD:noreplaynammaooruDelivary@2025}
    properties:
      mail:
        smtp:
          auth: true
          ssl:
            enable: true
            required: true
            trust: "*"
          socketFactory:
            port: 465
            class: javax.net.ssl.SSLSocketFactory
            fallback: false
          connectiontimeout: 30000
          timeout: 30000
          writetimeout: 30000

email:
  from: ${EMAIL_FROM_ADDRESS:noreplay@nammaoorudelivary.in}
  from-name: ${EMAIL_FROM_NAME:NammaOoru Delivery}
  templates:
    welcome: welcome-shop-owner
    password-reset: password-reset
    shop-approval: shop-approval
  subject:
    welcome: "Welcome to NammaOoru - Your Shop Account is Ready!"
    password-reset: "Reset Your NammaOoru Account Password"
    shop-approval: "Your Shop has been Approved!"
```

#### 2. Email Properties Class (`backend/src/main/java/com/shopmanagement/config/EmailProperties.java`)
```java
@Data
@Component
@ConfigurationProperties(prefix = "email")
public class EmailProperties {
    private String from;
    private String fromName;
    private Map<String, String> templates;
    private Map<String, String> subject;
}
```

## Docker Environment Variables

### Production Environment Variables (used in docker-compose.yml)
```bash
MAIL_HOST=smtp.hostinger.com
MAIL_PORT=587
MAIL_USERNAME=noreplay@nammaoorudelivary.in
MAIL_PASSWORD=noreplaynammaooruDelivary@2025
EMAIL_FROM_ADDRESS=noreplay@nammaoorudelivary.in
SPRING_MAIL_PROPERTIES_MAIL_SMTP_AUTH=true
SPRING_MAIL_PROPERTIES_MAIL_SMTP_STARTTLS_ENABLE=true
```

## Email Service Implementation

### Key Features
1. **OTP Email Sending**: Used for user registration verification
2. **HTML Template Support**: For welcome emails, password resets, etc.
3. **Error Handling**: Graceful failure - registration continues even if email fails
4. **Logging**: Comprehensive logging for debugging

### OTP Email Flow
1. User registers via mobile app or web frontend
2. Backend calls `/auth/send-otp` endpoint
3. EmailService generates 6-digit OTP
4. Email sent via Hostinger SMTP
5. User receives OTP and enters it to verify account

## Troubleshooting

### Common Issues and Solutions

#### 1. "Sender address rejected: not owned by user"
**Cause**: FROM address doesn't match authenticated email address
**Solution**: Ensure FROM address matches SMTP username (noreplay@nammaoorudelivary.in)

#### 2. SocketTimeoutException: Connect timed out
**Cause**: Network/firewall blocking SMTP ports
**Solution**: 
- Check firewall allows ports 465/587
- For Hetzner servers: Add ports to firewall rules
- Try port 587 with STARTTLS instead of port 465

#### 3. SSL/TLS Handshake Errors
**Cause**: Java SSL incompatibility with Hostinger
**Solution**: 
- Add SSL trust configuration: `trust: "*"`
- Use proper socket factory class
- Consider using port 587 with STARTTLS

#### 4. Email Not Received
**Check List**:
- ✅ SMTP credentials are correct
- ✅ FROM address matches authenticated email
- ✅ Network connectivity to smtp.hostinger.com
- ✅ Recipient email is valid
- ✅ Check spam folder
- ✅ Review backend logs for errors

### Testing Email Configuration

#### 1. Test OTP Endpoint
```bash
curl -X POST https://api.nammaoorudelivary.in/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

#### 2. Check Backend Logs
```bash
ssh root@65.21.4.236
cd /opt/shop-management
docker-compose logs -f backend | grep -i mail
```

## Server Configuration

### Production Server Details
- **Server**: Hetzner Cloud (IP: 65.21.4.236)
- **OS**: Ubuntu
- **Container**: Docker with docker-compose
- **API URL**: https://api.nammaoorudelivary.in/api

### Required Firewall Ports
- Port 465 (SMTP SSL)
- Port 587 (SMTP STARTTLS)
- Port 80 (HTTP)
- Port 443 (HTTPS)
- Port 8082 (Backend API)

## Mobile App Integration

### API Client Configuration
```dart
// mobile/nammaooru_mobile_app/lib/core/api/api_client.dart
class ApiClient {
  static void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.nammaoorudelivary.in/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }
}
```

### Registration Flow with OTP
1. User fills registration form in mobile app
2. App calls `/auth/send-otp` with user email
3. Backend sends OTP email via Hostinger
4. User enters OTP in app
5. App verifies OTP and completes registration

## Deployment Notes

### When Rebuilding Containers
The email configuration is preserved through:
1. **Environment variables** in docker-compose.yml (immediate effect)
2. **Default values** in application.yml (permanent backup)
3. **Git repository** (version control)

### Backup Email Configuration
Always keep backup of:
- SMTP credentials
- Email templates
- Environment variables
- SSL certificates (if custom)

## Security Best Practices

1. **Never commit plain passwords** to git repository
2. **Use environment variables** for sensitive data
3. **Rotate email passwords** regularly
4. **Monitor email logs** for suspicious activity
5. **Use SSL/TLS** for all SMTP connections

## Contact Information

### Hostinger SMTP Support
- Use Hostinger support for SMTP-related issues
- FROM address must match authenticated email
- Port 465 (SSL) or 587 (STARTTLS) supported

### Production Server Access
- SSH: `root@65.21.4.236`
- Server logs: `/opt/shop-management/`
- Docker containers: `docker-compose logs -f`

---

**Last Updated**: January 2025
**Status**: ✅ Working - OTP emails successfully sending
**Next Review**: Quarterly or when SMTP issues arise