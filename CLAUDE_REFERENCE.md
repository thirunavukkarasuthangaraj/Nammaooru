# 🤖 CLAUDE AI REFERENCE - Complete NammaOoru Shop Management System

**⚡ THIS IS THE SINGLE SOURCE OF TRUTH FOR ALL AI ASSISTANTS ⚡**

## 🎯 Quick Start for AI Assistants

### System Overview
- **Type**: Multi-platform e-commerce system with delivery management
- **Backend**: Spring Boot (Java) on port 8080 (default, can run on 8081 if port conflict)
- **Frontend**: Angular on port 4200
- **Mobile**: Flutter app
- **Database**: PostgreSQL
- **Authentication**: JWT-based

### Key File Locations
```
📁 Backend: D:\AAWS\nammaooru\shop-management-system\backend\
📁 Frontend: D:\AAWS\nammaooru\shop-management-system\frontend\
📁 Mobile: D:\AAWS\nammaooru\shop-management-system\mobile\nammaooru_mobile_app\
📁 Documentation: Root directory (.md files)
```

## 🌐 External Service Integrations

### MSG91 SMS/WhatsApp Service
- **OTP Authentication**: Send OTP via WhatsApp or SMS
- **Order Notifications**: Notify customers about order status
- **Template-based Messaging**: Predefined templates for different notifications
- **Configuration**: `msg91.auth.key`, `msg91.sender.id`, `msg91.template.*`

### Firebase Integration  
- **Push Notifications**: Real-time order and delivery updates
- **Real-time Database**: Live tracking and status updates
- **Configuration**: Firebase config in environment.ts

### Google Maps Integration
- **Location Services**: Shop and customer location mapping  
- **Delivery Tracking**: Real-time partner location tracking
- **Route Optimization**: Best delivery route calculation
- **API Key**: `googleMapsApiKey` in environment configuration

### Email Service (Hostinger SMTP)
- **Transactional Emails**: Order confirmations, password resets
- **Template System**: Welcome emails, shop approval notifications
- **Configuration**: SMTP settings in application.yml

## 🏗️ Complete System Architecture

### Core Entities & Relationships
```
User (customers, shop_owners, delivery_partners, admins)
├── Shop (shop_owners create shops)
│   ├── Products (belong to shops)
│   └── Orders (customers order from shops)
│       └── OrderItems (products in orders)
│           └── OrderAssignments (delivered by partners)
│               └── DeliveryTracking (real-time tracking)
```

### Database Tables (Key Ones)
- `users` - All system users with roles
- `shops` - Shop information and owners
- `products` - Product catalog with categories
- `orders` - Customer orders with status flow
- `order_items` - Individual products in orders
- `order_assignments` - Delivery partner assignments
- `delivery_partners` - Partner profiles and stats

## 🔄 Complete Application Flows

### 1. Customer Journey Flow
```
Registration → Login → Browse Shops → Select Products → Add to Cart → Checkout → Place Order → Track Delivery → Receive Order
```

**Key APIs:**
- `POST /api/auth/register` - Customer registration
- `GET /api/customer/shops` - Browse available shops
- `GET /api/customer/shops/{id}/products` - Browse shop products
- `POST /api/customer/orders` - Place order
- `GET /api/customer/orders/{id}/status` - Track order

### 2. Shop Owner Journey Flow
```
Registration → Login → Create Shop → Add Products → Manage Inventory → Receive Orders → Process Orders → Update Status
```

**Key APIs:**
- `POST /api/auth/register` - Shop owner registration
- `POST /api/shop-owner/shops` - Create shop
- `POST /api/shop-owner/products` - Add products
- `GET /api/shop-owner/orders-management` - View incoming orders
- `PUT /api/shop-owner/orders-management/{id}/status` - Update order status

### 3. Delivery Partner Journey Flow
```
Registration → Login → View Assignments → Accept/Reject → Pickup → Deliver → Update Status → Receive Payment
```

**Key APIs:**
- `GET /api/delivery/assignments/partner/{id}/active` - View assignments
- `PUT /api/delivery/assignments/{id}/accept` - Accept assignment
- `PUT /api/delivery/assignments/{id}/pickup` - Mark picked up
- `PUT /api/delivery/assignments/{id}/complete` - Mark delivered

### 4. Order Status Flow
```
PENDING → CONFIRMED → PREPARING → READY_FOR_PICKUP → OUT_FOR_DELIVERY → DELIVERED
```

### 5. Assignment Status Flow
```
ASSIGNED → ACCEPTED → PICKED_UP → IN_TRANSIT → DELIVERED
```

## 📱 Frontend Architecture

### Angular Project Structure
```
src/
├── app/
│   ├── core/ (services, guards, interceptors)
│   ├── features/ (feature modules)
│   │   ├── auth/ (login, register)
│   │   ├── customer/ (shopping, orders)
│   │   ├── shop-owner/ (management, products)
│   │   └── delivery/ (partner features)
│   ├── shared/ (common components)
│   └── environments/
```

### Key Services
- `AuthService` - Authentication and JWT handling
- `OrderService` - Order management
- `ProductService` - Product operations
- `ShopService` - Shop operations
- `OrderAssignmentService` - Delivery assignments

### Environment Configuration
```typescript
// frontend/src/environments/environment.ts
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080/api',  // Backend port
  appUrl: 'http://localhost:4200',
  googleMapsApiKey: 'AIzaSyAr_uGbaOnhebjRyz7ohU6N-hWZJVV_R3U',
  websocketUrl: 'ws://localhost:8082/ws',
  firebase: {
    // Firebase configuration for push notifications
    apiKey: "AIzaSyB7MSHYRGCj9V-y3VZWCJvQ9I0LCB_-Oag",
    projectId: "grocery-5ecc5",
    messagingSenderId: "368788713881"
  }
};
```

## 🚀 Backend Architecture

### Spring Boot Project Structure
```
src/main/java/com/shopmanagement/
├── config/ (security, cors, database)
├── controller/ (REST endpoints)
├── service/ (business logic)
├── entity/ (JPA entities)
├── repository/ (data access)
├── dto/ (data transfer objects)
├── mapper/ (entity-dto mapping)
└── delivery/ (delivery module)
    ├── entity/ (delivery entities)
    ├── service/ (delivery services)
    └── controller/ (delivery endpoints)
```

### Key Controllers & Endpoints
```java
// Authentication
POST /api/auth/register
POST /api/auth/login  
POST /api/auth/refresh
POST /api/auth/send-otp        // Send WhatsApp/SMS OTP
POST /api/auth/verify-otp      // Verify OTP
POST /api/auth/resend-otp      // Resend OTP

// Customer APIs
GET /api/customer/shops
GET /api/customer/shops/{id}/products
POST /api/customer/orders

// Shop Owner APIs  
GET /api/shop-owner/shops
POST /api/shop-owner/products
GET /api/shop-owner/orders-management
PUT /api/shop-owner/shops/{id}/hours    // Business hours management

// Delivery APIs
POST /api/delivery/assignments
PUT /api/delivery/assignments/{id}/accept
PUT /api/delivery/assignments/{id}/complete
GET /api/delivery/partners/{id}/stats   // Partner performance stats

// Admin APIs
PUT /api/admin/shops/{id}/approve       // Shop approval workflow
GET /api/admin/analytics                // System analytics

// Test APIs (Development Only)
POST /api/test/msg91/send-otp          // Test MSG91 OTP
POST /api/test/whatsapp/send           // Test WhatsApp messaging
```

### Database Configuration
```yaml
# application.yml
server:
  port: 8080  # Can use 8081 if 8080 is occupied
spring:
  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/shop_management_db}
    username: ${DB_USERNAME:postgres}
    password: ${DB_PASSWORD:postgres}
```

## 📱 Mobile App (Flutter)

### Project Structure
```
lib/
├── core/ (constants, utils, services)
├── features/ (feature modules)
├── models/ (data models)
├── services/ (API services)
└── main.dart
```

### Key Services
- `ApiClient` - HTTP client for API calls
- `AuthService` - Authentication handling
- `OrderService` - Order management
- `ProductService` - Product operations

### API Configuration
```dart
// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String baseUrl = 'https://api.nammaoorudelivary.in/api';
  // For development: 'http://10.0.2.2:8081/api'
}
```

## 🔐 Authentication System

### JWT Token Flow
1. User logs in with email/password OR mobile number/OTP
2. Backend validates and returns JWT token
3. Frontend stores token in localStorage
4. All API calls include Authorization header
5. Backend validates token for protected endpoints

### OTP Authentication (MSG91 Integration)
1. User enters mobile number
2. System sends OTP via WhatsApp or SMS
3. User enters OTP for verification
4. System validates and creates JWT token

**Key APIs:**
- `POST /api/auth/send-otp` - Send OTP via WhatsApp/SMS
- `POST /api/auth/verify-otp` - Verify OTP and get JWT
- `POST /api/auth/resend-otp` - Resend OTP

### User Roles
- `CUSTOMER` - Can browse and order
- `SHOP_OWNER` - Can manage shops and products
- `DELIVERY_PARTNER` - Can accept and deliver orders
- `ADMIN` - Full system access
- `MANAGER` - Administrative access

## 🎨 UI Components & Styling

### Key Shared Components
- `HeaderComponent` - Navigation and user menu
- `LoadingComponent` - Loading spinner
- `ConfirmDialogComponent` - Confirmation dialogs
- `ImageUploadComponent` - File upload handling

### Styling Framework
- Angular Material for UI components
- Custom SCSS for specific styling
- Responsive design for mobile compatibility

## 🔧 Development Commands

### Backend
```bash
cd backend
# Default port 8080
mvn spring-boot:run

# If port 8080 is occupied, use 8081
mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=8081
```

### Frontend
```bash
cd frontend
npm start  # Runs on port 4200
```

### Mobile
```bash
cd mobile/nammaooru_mobile_app
flutter run
flutter build apk --release
```

### Database
```bash
# Connect to PostgreSQL
psql -h localhost -p 5432 -U shop_user -d shop_management
```

## 🐛 Common Issues & Solutions

### Port Conflicts
- Backend default port 8080 often occupied, use 8081
- Frontend runs on 4200, mobile emulator uses 10.0.2.2

### Authentication Issues
- Ensure JWT secret is properly configured
- Check token expiration and refresh logic
- Verify CORS settings for frontend

### Database Connection
- Ensure PostgreSQL is running
- Check connection string and credentials
- Verify database schema exists

### Image Upload Issues
- Check file size limits
- Verify upload directory permissions
- Ensure proper MIME type handling

## 📊 Key Business Logic

### Order Processing
1. Customer places order (status: PENDING)
2. Shop owner confirms order (status: CONFIRMED)
3. Shop owner prepares order (status: PREPARING)
4. Order ready for pickup (status: READY_FOR_PICKUP)
5. Delivery partner picks up (status: OUT_FOR_DELIVERY)
6. Order delivered (status: DELIVERED)

### Delivery Assignment
1. System assigns order to best available partner
2. Partner receives notification
3. Partner accepts/rejects assignment
4. If accepted, partner picks up order
5. Partner delivers and confirms delivery
6. System updates order status and partner earnings

### Payment Flow
- Orders support multiple payment methods
- Delivery partners earn commission on successful deliveries
- Shop owners receive payment minus platform fees

## 🌐 Production Environment

### Server Details
- **Domain**: nammaoorudelivary.in
- **API**: api.nammaoorudelivary.in
- **Server**: Hetzner Cloud (65.21.4.236)
- **SSL**: Let's Encrypt
- **Email**: Hostinger SMTP

### Deployment
- Backend: Docker container with Spring Boot
- Frontend: Nginx serving Angular build
- Database: PostgreSQL in Docker
- SSL: Automated Let's Encrypt renewal

## 🌍 Environment Variables

### Required Environment Variables
```bash
# Database
DB_URL=jdbc:postgresql://localhost:5432/shop_management_db
DB_USERNAME=postgres
DB_PASSWORD=postgres

# JWT Security
JWT_SECRET=your-256-bit-secret-key

# Email (Hostinger SMTP)
MAIL_HOST=smtp.hostinger.com
MAIL_PORT=587
MAIL_USERNAME=noreplay@nammaoorudelivary.in
MAIL_PASSWORD=your-email-password

# MSG91 Integration
MSG91_AUTH_KEY=your-msg91-auth-key
MSG91_SENDER_ID=your-sender-id
MSG91_OTP_TEMPLATE_ID=your-template-id
MSG91_WHATSAPP_ENABLED=true

# File Upload
FILE_UPLOAD_PATH=./uploads
APP_UPLOAD_DIR=./uploads

# Frontend URLs
FRONTEND_BASE_URL=http://localhost:4200
FRONTEND_LOGIN_URL=http://localhost:4200/auth/login

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:4200,https://nammaoorudelivary.in
```

## 🆕 New Features & Workflows

### Shop Approval Workflow
1. Shop owner registers and creates shop profile
2. Admin reviews shop details and documents
3. Admin approves/rejects shop via API
4. Approved shops become visible to customers
5. Email notification sent to shop owner

### Business Hours Management
- Shop owners can set opening/closing hours
- Different hours for different days
- Holiday/closure scheduling
- Automatic order acceptance based on hours

### WhatsApp/SMS OTP Authentication
1. User enters mobile number
2. System sends OTP via WhatsApp (primary) or SMS (fallback)
3. User enters 6-digit OTP
4. System validates and creates account/login
5. JWT token generated for session

### Real-time Delivery Tracking
- Partner location updates every 40 seconds
- Customer receives live tracking updates
- Firebase push notifications for status changes
- Google Maps integration for route visualization

### Analytics & Reporting
- Order volume and revenue tracking
- Partner performance metrics
- Shop performance analytics
- Customer behavior insights

## 📋 Testing Checklist

### Before Making Changes
- [ ] Backend running on 8080 (or 8081 if port conflict)
- [ ] Frontend running on 4200
- [ ] Database accessible
- [ ] Test user accounts exist
- [ ] Environment variables configured

### After Making Changes
- [ ] Build succeeds without errors
- [ ] All tests pass
- [ ] API endpoints respond correctly
- [ ] Frontend loads without errors
- [ ] Authentication flow works (both email and OTP)
- [ ] External services working (MSG91, Firebase, Maps)

## 🚨 Emergency Procedures

### System Down
```bash
docker-compose down
docker-compose up --build -d
```

### Database Issues
```bash
# Backup
pg_dump -h localhost -U shop_user shop_management > backup.sql

# Restore
psql -h localhost -U shop_user shop_management < backup.sql
```

### Clear Everything and Restart
```bash
# Stop all services
docker-compose down
docker system prune -a -f

# Restart
git pull origin main
docker-compose up --build -d
```

## 📚 Documentation Files Reference

- `README.md` - Project overview and setup
- `CUSTOMER_SHOP_OWNER_FLOWS.md` - Detailed user flows
- `EMAIL_CONFIGURATION.md` - SMTP setup
- `DEPLOYMENT_GUIDE.md` - Production deployment
- `MOBILE_APP_GUIDE.md` - Flutter app details
- `TROUBLESHOOTING_GUIDE.md` - Common problems
- `DOCUMENTATION_INDEX.md` - Documentation navigation

---

## 🎯 FOR AI ASSISTANTS: QUICK ACTION GUIDE

### When User Wants to Test Features
1. Check if backend/frontend are running
2. Verify database connection
3. Create test data if needed
4. Test API endpoints first
5. Then test UI functionality

### When User Reports Bugs
1. Check application logs
2. Verify API responses
3. Check database state
4. Test in isolation
5. Provide specific fix

### When User Wants New Features
1. Understand existing code patterns
2. Follow established architecture
3. Update all related components (backend, frontend, mobile)
4. Test end-to-end flow
5. Update documentation

### When User Asks About Code
1. Reference this file for context
2. Check specific implementation files
3. Explain in terms of user flows
4. Provide code examples
5. Suggest improvements if relevant

---

**🔄 Last Updated**: January 2025  
**📧 Created by**: AI Assistant for NammaOoru Team  
**🎯 Purpose**: Single source of truth for all AI assistants working on this project

**⚠️ IMPORTANT**: Always refer to this file first before making any changes or suggestions. This ensures consistency across all AI interactions with the codebase.