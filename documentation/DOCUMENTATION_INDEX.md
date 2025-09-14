# NammaOoru Shop Management System - Documentation Index

## 📚 Complete Documentation Suite

This documentation covers everything you need to know about the NammaOoru Shop Management System, including the painful email issues we faced and how we solved them.

## 🔗 Quick Navigation

| Document | Description | When to Use |
|----------|-------------|-------------|
| [📖 Main README](README.md) | Complete application overview, features, recent updates | Project overview and current status |
| [🛍️ Customer & Shop Owner Flows](CUSTOMER_SHOP_OWNER_FLOWS.md) | Complete e-commerce flow implementation details | Understanding customer/shop owner features |
| [📧 Email Configuration](EMAIL_CONFIGURATION.md) | SMTP setup, OTP emails, Hostinger config | When email isn't working |
| [🚀 Deployment Guide](DEPLOYMENT_GUIDE.md) | Server setup, Docker, why we faced issues | When deploying or rebuilding |
| [📱 Mobile App Guide](MOBILE_APP_GUIDE.md) | Flutter app, API integration, build process | When working on mobile app |
| [🔧 Troubleshooting Guide](TROUBLESHOOTING_GUIDE.md) | Common issues, solutions, emergency fixes | When things break |

## 🎯 Why This Documentation Exists

### The Email Nightmare We Survived
We spent hours troubleshooting email issues because:
1. **Hardcoded Gmail defaults** in application.yml
2. **FROM address mismatch** with Hostinger SMTP
3. **Network/firewall** blocking SMTP ports  
4. **SSL handshake failures** between Java and Hostinger
5. **Missing documentation** of working configurations

**Result**: Lost time, frustrated debugging, production downtime

### What We Learned
- **Document everything** before it breaks
- **Test email in production** environment
- **Always match FROM address** with SMTP username
- **Keep working configurations** in version control
- **Have troubleshooting guides** ready

## 🏗️ System Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │  Web Frontend   │    │  Admin Panel    │
│   (Flutter)     │    │   (Angular)     │    │   (Angular)     │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │     API Gateway         │
                    │  (nginx reverse proxy)  │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   Backend API Server    │
                    │   (Spring Boot)         │
                    └────────────┬────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
┌─────────▼───────┐   ┌──────────▼──────────┐   ┌───────▼───────┐
│   PostgreSQL    │   │   File Storage      │   │  SMTP Server  │
│   Database      │   │   (Local/Cloud)     │   │ (Hostinger)   │
└─────────────────┘   └─────────────────────┘   └───────────────┘
```

## 🌐 Production Environment

### Server Details
- **Provider**: Hetzner Cloud
- **IP**: 65.21.4.236  
- **OS**: Ubuntu Server
- **Domain**: nammaoorudelivary.in
- **API**: api.nammaoorudelivary.in
- **SSL**: Let's Encrypt

### Key Services
- **Frontend**: Nginx serving Angular SPA
- **Backend**: Spring Boot in Docker container
- **Database**: PostgreSQL in Docker container
- **Email**: Hostinger SMTP (noreplay@nammaoorudelivary.in)
- **Mobile**: Flutter app connecting to production API

## 🚨 Emergency Quick Reference

### Email Not Working?
1. Check FROM address matches SMTP username: `noreplay@nammaoorudelivary.in`
2. Verify SMTP port (465 or 587) is open in firewall
3. Check backend logs: `docker-compose logs backend | grep -i mail`
4. Test OTP endpoint: `curl -X POST https://api.nammaoorudelivary.in/api/auth/send-otp`

### API Not Responding?
1. Check container status: `docker-compose ps`
2. Restart services: `docker-compose restart`
3. Check nginx: `systemctl status nginx`
4. View logs: `docker-compose logs -f backend`

### Mobile App Not Connecting?
1. Verify API URL: `https://api.nammaoorudelivary.in/api`
2. Check network connectivity from device
3. Enable debug logging in ApiClient
4. Test API in browser first

### Complete System Down?
```bash
# Nuclear option - rebuild everything
docker-compose down
docker system prune -a -f
git pull origin main
docker-compose up --build -d
```

## 📋 Pre-Flight Checklist

### Before Any Deployment
- [ ] Code tested locally
- [ ] Environment variables configured
- [ ] Email sending tested
- [ ] Database migrations applied
- [ ] SSL certificates valid
- [ ] Firewall rules updated
- [ ] Backup taken
- [ ] Documentation updated

### After Deployment
- [ ] API health check passes
- [ ] Email OTP working
- [ ] Mobile app can connect
- [ ] Frontend loads correctly
- [ ] Database queries working
- [ ] SSL certificate valid
- [ ] Monitoring alerts configured

## 🔐 Security Notes

### Critical Security Points
- **Never commit** SMTP passwords to git
- **JWT secrets** must be 256+ bits
- **HTTPS only** for all external communication
- **Firewall** properly configured
- **Database** not exposed externally
- **File uploads** size and type limited

### Current Credentials Location
- SMTP: Environment variables in docker-compose
- JWT: Environment variables 
- Database: Environment variables
- SSL: Let's Encrypt auto-renewal

## 📞 Support Information

### When Things Go Wrong
1. **Check this documentation first**
2. **Review troubleshooting guide**
3. **Check system logs**  
4. **Test individual components**
5. **Contact system admin** if needed

### External Support
- **Hostinger**: SMTP/email issues
- **Hetzner**: Server/infrastructure issues
- **Let's Encrypt**: SSL certificate issues

## 🔄 Regular Maintenance

### Daily
- Monitor error logs
- Check system resource usage
- Verify backup completion

### Weekly  
- Review security logs
- Update system packages
- Test backup restoration

### Monthly
- Review and update documentation
- Performance optimization
- Security audit

## 📈 Performance Monitoring

### Key Metrics to Watch
- **API Response Time**: < 500ms average
- **Database Query Time**: < 100ms average  
- **Email Delivery Rate**: > 95%
- **System Memory Usage**: < 80%
- **Disk Space**: < 85% full

### Monitoring Commands
```bash
# API performance
time curl https://api.nammaoorudelivary.in/api/actuator/health

# System resources  
htop
df -h
docker stats

# Application logs
docker-compose logs -f backend | grep -E "(ERROR|WARN)"
```

## 🎓 Learning Resources

### Technologies Used
- **Spring Boot**: Backend framework
- **Angular**: Frontend framework  
- **Flutter**: Mobile app framework
- **PostgreSQL**: Database
- **Docker**: Containerization
- **Nginx**: Web server/reverse proxy
- **Hostinger**: Email service provider

### Useful Commands Reference
```bash
# Git operations
git status
git log --oneline -5
git push origin main

# Docker operations  
docker-compose ps
docker-compose logs -f
docker-compose restart
docker-compose up --build -d

# Server operations
ssh root@65.21.4.236
systemctl status nginx
ufw status
```

---

## 💡 Final Words

This documentation exists because we learned the hard way that:

1. **Complex systems need documentation**
2. **Email issues are surprisingly complex**
3. **Production environments behave differently**
4. **Time spent documenting saves hours debugging**
5. **Future you will thank current you**

Keep this documentation updated. Your future self (and your team) will appreciate it when something breaks at 2 AM.

---

**Created**: January 2025
**Last Updated**: September 2025 - After implementing Delivery Partner Document Management System
**Status**: ✅ All systems operational with full e-commerce functionality and delivery partner document management
**Next Review**: When additional delivery features are added

## 🎉 Recent Major Updates (January 2025)

### ✅ Complete Customer & Shop Owner Flow Implementation

We've successfully implemented and integrated the entire e-commerce workflow:

#### Customer Experience
- **Shop Discovery**: Browse available shops with search and filtering
- **Product Browsing**: View products by shop with categories and search functionality  
- **Shopping Cart**: Full cart management with quantity controls and single-shop restriction
- **Checkout Process**: Complete order placement with delivery address and payment options
- **Order Integration**: Orders properly created in backend with customer authentication

#### Shop Owner Experience  
- **Product Management**: Add, edit, and manage product inventory with image upload
- **Order Processing**: View and manage incoming customer orders
- **Dashboard Analytics**: Sales metrics and business insights
- **Profile Management**: Update business information and operating hours

#### Technical Achievements
- **API Integration**: All frontend services correctly mapped to backend endpoints
- **Authentication Flow**: Fixed login error messages to show specific credential errors
- **Image Management**: Resolved URL inconsistencies between shop owner and customer views
- **Service Architecture**: Proper separation of concerns with Angular services
- **Error Handling**: Comprehensive error management with user-friendly messages

#### Key Fixes Applied
1. **Shop List Service**: Updated to use `/api/customer/shops` endpoint
2. **Product Browsing**: Integrated with `/api/customer/shops/{id}/products`
3. **Checkout Integration**: Connected to `/api/customer/orders` for order placement
4. **Image URL Consistency**: Fixed missing file extensions and API path issues
5. **Authentication**: Enhanced error messages for invalid login credentials

The system now provides a complete end-to-end e-commerce experience from shop discovery to order placement, with all major user flows fully functional and tested.

## 🚚 Latest Update (September 2025)

### ✅ Delivery Partner Document Management System

We've successfully implemented a comprehensive document management system for delivery partners with the following key features:

#### Document Management Features
- **Multi-Document Upload**: Support for 4 essential document types:
  - **Driver Photo**: Clear photo identification of the delivery partner
  - **Driving License**: License document with automatic license number capture
  - **Vehicle Photo**: Photo of delivery vehicle with vehicle number tracking
  - **RC Book**: Registration Certificate for vehicle verification

#### User Experience
- **Seamless Integration**: Document management integrated into the main user management system
- **Role-Based Access**: Document options only appear for delivery partner users
- **Admin Verification Workflow**: Administrators can view, approve, or reject documents
- **Progress Tracking**: Real-time upload progress with status indicators
- **Document Viewer**: Modal interface for viewing and managing all partner documents

#### Technical Implementation
- **Frontend Components**:
  - `DeliveryPartnerDocumentsComponent`: Main upload interface
  - `DeliveryPartnerDocumentViewerComponent`: Admin document viewer modal
  - Integrated into user list with context-aware menu options

- **Backend Services**:
  - `DeliveryPartnerDocumentService`: File handling and validation
  - `DeliveryPartnerDocumentController`: REST API endpoints
  - Secure file storage with configurable upload paths

- **File Management**:
  - File type validation (PDF, JPG, PNG, DOCX)
  - Size limits (10MB maximum)
  - Unique filename generation with partner identification
  - Secure download with proper content-type headers

#### Integration Flow
1. **User Creation**: Admin creates delivery partner users through user management
2. **Document Access**: Delivery partner menu options automatically appear in user list
3. **Upload Interface**: Navigate to `/users/{userId}/documents` for full upload experience
4. **Admin Verification**: Admins can view and verify documents through the document viewer
5. **Status Tracking**: Real-time verification status updates for all stakeholders

#### API Endpoints
- `GET /api/delivery/partners/{partnerId}/documents` - Retrieve partner documents
- `POST /api/delivery/partners/{partnerId}/documents/upload` - Upload new document
- `GET /api/delivery/partners/{partnerId}/documents/{documentId}/download` - Download document
- `PUT /api/delivery/partners/{partnerId}/documents/{documentId}/verify` - Admin verification
- `DELETE /api/delivery/partners/{partnerId}/documents/{documentId}` - Delete document

#### Security & Validation
- **Role-Based Authorization**: Admin and delivery partner role validation
- **File Security**: Comprehensive file type and size validation
- **Secure Storage**: Files stored outside web root with controlled access
- **Audit Trail**: Complete tracking of document verification activities

This implementation provides a complete document lifecycle management system for delivery partners, ensuring all necessary documentation is collected, verified, and securely stored for operational compliance.

## 🌐 Real-time Delivery Partner Status Tracking (September 2025)

### ✅ Real-time Online/Offline and Ride Status System

We've successfully implemented a comprehensive real-time status monitoring system that provides live visibility into delivery partner activity and availability.

#### Core Status Tracking Features
- **Dual Status Indicators**: Online/offline status with ride status tracking
- **Live Activity Monitoring**: Real-time updates based on partner interactions
- **Visual Status Display**: Color-coded status chips with animations
- **Location Tracking**: GPS coordinate storage for location-based services
- **Automatic State Management**: Intelligent status transitions based on business rules

#### Status Types Implemented

**Online/Offline Status:**
- **Online**: Green gradient with pulsing animation (wifi icon)
- **Offline**: Gray gradient (wifi_off icon) - auto-set after 10 minutes inactivity

**Ride Status Types:**
- **Available**: Green with pulse animation (check_circle) - Ready for new orders
- **On Ride**: Blue with spinning animation (directions_bike) - Active delivery
- **Busy**: Yellow/Orange with pulse animation (hourglass_empty) - Multiple tasks
- **On Break**: Purple gradient (coffee) - Partner-controlled break time
- **Offline**: Red gradient (offline_pin) - Not available for assignments

#### Technical Implementation

**Frontend Enhancements:**
- Enhanced `user-list.component` with delivery partner status indicators
- Dual status display showing both online status and ride status
- Advanced CSS animations with keyframe effects for visual feedback
- Comprehensive tooltip system with last activity timestamps
- Responsive status management with hover effects

**Backend API Enhancements:**
- New status tracking fields added to users table:
  - `is_online`, `is_available`, `ride_status`
  - `current_latitude`, `current_longitude`
  - `last_location_update`, `last_activity`
- Enhanced repository queries for status-based partner filtering
- Business logic for automatic status transitions
- Performance optimization with proper database indexing

**Status Management Endpoints:**
- `PUT /{partnerId}/online-status` - Update online/offline status
- `PUT /{partnerId}/ride-status` - Update current ride status
- `PUT /{partnerId}/location` - Update GPS location
- `PUT /{partnerId}/availability` - Update availability for orders
- `GET /all-partners-status` - Comprehensive status overview
- `POST /batch-status-update` - Bulk status updates

#### Database Enhancements
```sql
-- New columns added to users table
ALTER TABLE users
ADD COLUMN is_online BOOLEAN DEFAULT FALSE,
ADD COLUMN is_available BOOLEAN DEFAULT FALSE,
ADD COLUMN ride_status VARCHAR(20) DEFAULT 'AVAILABLE',
ADD COLUMN current_latitude DECIMAL(10,6),
ADD COLUMN current_longitude DECIMAL(10,6),
ADD COLUMN last_location_update TIMESTAMP,
ADD COLUMN last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Performance indexes
CREATE INDEX idx_users_online_status ON users(is_online) WHERE role = 'DELIVERY_PARTNER';
CREATE INDEX idx_users_ride_status ON users(ride_status) WHERE role = 'DELIVERY_PARTNER';
```

#### Business Logic & Automation
- **Automatic Offline Detection**: Partners auto-marked offline after 10 minutes inactivity
- **Smart Status Transitions**: Ride status changes automatically update online/availability
- **Location-Based Queries**: Find online partners with GPS coordinates
- **Performance Monitoring**: Track partner utilization and response times

#### Visual Design
- **Gradient Backgrounds**: Beautiful gradient designs for each status type
- **CSS Animations**: Pulsing, spinning, and scaling animations for visual feedback
- **Responsive Design**: Proper mobile and desktop layouts
- **Accessibility**: Proper contrast ratios and tooltip descriptions

#### Integration Benefits
- **Real-time Visibility**: Instant view of all partner availability
- **Operational Efficiency**: Quick identification of available partners
- **Better Assignment**: Location and status-based order assignment capability
- **Performance Analytics**: Detailed metrics on partner activity patterns

This system provides the foundation for advanced delivery partner management, enabling efficient order assignment, performance tracking, and operational optimization through real-time status monitoring and automated business logic.