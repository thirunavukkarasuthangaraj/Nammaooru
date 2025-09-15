# NammaOoru Shop Management System

A comprehensive multi-platform e-commerce solution designed for local businesses and customers. This system includes web applications for shop owners and administrators, plus a mobile app for customers.

## 🚀 System Overview

**NammaOoru** is a complete shop management and delivery platform that connects local shops with customers through a unified digital marketplace.

### 🎯 Core Features

- **Multi-Role Support**: Customers, Shop Owners, Super Admins, and Delivery Partners
- **Product Management**: Complete catalog management with categories, pricing, and inventory
- **Order Processing**: End-to-end order management from placement to delivery
- **Real-time Notifications**: Firebase-powered notifications across all platforms
- **Mobile-First Design**: Flutter mobile app with offline capabilities
- **Image Management**: Automated image processing and URL handling
- **Authentication**: JWT-based secure authentication with OTP verification

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │  Web Frontend   │    │  Admin Panel    │
│   (Flutter)     │    │   (Angular)     │    │   (Angular)     │
│   📱 Customers  │    │   🏪 Shop Owners│    │  👑 Super Admin │
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
                    │   🔐 JWT + Role-based   │
                    └────────────┬────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
┌─────────▼───────┐   ┌──────────▼──────────┐   ┌───────▼───────┐
│   PostgreSQL    │   │   File Storage      │   │  Firebase FCM │
│   Database      │   │   (Images/Files)    │   │ (Push Notifications)│
└─────────────────┘   └─────────────────────┘   └───────────────┘
```

## 🛠️ Technology Stack

### Backend
- **Framework**: Spring Boot 3.x
- **Database**: PostgreSQL
- **Security**: Spring Security + JWT
- **Email**: SMTP Integration (Hostinger)
- **File Upload**: Multipart handling
- **API Documentation**: Swagger/OpenAPI
- **Notifications**: Firebase Admin SDK

### Frontend (Web)
- **Framework**: Angular 17+
- **UI Library**: Angular Material
- **Authentication**: JWT Interceptors
- **State Management**: RxJS Observables
- **HTTP Client**: Angular HttpClient
- **Responsive Design**: CSS Grid + Flexbox

### Mobile App
- **Framework**: Flutter
- **State Management**: Provider/Bloc
- **HTTP Client**: Dio
- **Local Storage**: SharedPreferences
- **Push Notifications**: Firebase Messaging
- **Image Handling**: Image Picker

### Infrastructure
- **Containerization**: Docker + Docker Compose
- **Web Server**: Nginx (Reverse Proxy)
- **SSL**: Let's Encrypt
- **Hosting**: Hetzner Cloud
- **Domain**: nammaoorudelivary.in

## 🌟 Recent Achievements & Fixed Issues

### ✅ Authentication & Security
- **Fixed login error messages**: Specific error handling for invalid credentials
- **JWT Integration**: Secure token-based authentication
- **Response Interceptor**: Centralized error handling and user-friendly messages
- **Role-based Access**: Separate dashboards for different user types

### ✅ Customer Flow (Complete End-to-End)
- **Shop Discovery**: Browse available shops with filtering and search
- **Product Browsing**: View products by shop with categories and search
- **Shopping Cart**: Add/remove items with quantity management
- **Checkout Process**: Complete order placement with address and payment options
- **Order Tracking**: Real-time order status updates

### ✅ Shop Owner Features
- **Product Management**: Add, edit, and manage product inventory
- **Order Management**: View and process incoming orders
- **Dashboard Analytics**: Sales and performance metrics
- **Image Upload**: Automated image processing and URL generation
- **Inventory Tracking**: Stock level management

### ✅ System Integration
- **API Endpoint Mapping**: All frontend services correctly calling backend APIs
- **Image URL Consistency**: Fixed image serving across shop owner and customer views
- **Error Handling**: Comprehensive error management with user-friendly messages
- **Service Integration**: All customer and shop owner services properly connected

### ✅ Technical Improvements
- **Service Layer**: Proper separation of concerns in frontend services
- **Component Architecture**: Modular and reusable Angular components
- **Backend Controllers**: RESTful API design with proper response formatting
- **Database Integration**: Efficient query handling and data relationships

## 📱 User Flows

### Customer Journey
1. **Registration/Login** → Email OTP verification
2. **Browse Shops** → Filter by location, category, or rating
3. **Select Shop** → View shop details and products
4. **Browse Products** → Search, filter by category, view details
5. **Add to Cart** → Manage quantities, view totals
6. **Checkout** → Enter delivery address, select payment method
7. **Place Order** → Receive confirmation and tracking number
8. **Track Order** → Real-time status updates via notifications

### Shop Owner Journey
1. **Registration/Login** → Admin approval required
2. **Setup Shop Profile** → Business details, hours, contact info
3. **Product Management** → Add products, upload images, set prices
4. **Inventory Management** → Track stock levels, update availability
5. **Order Processing** → Receive orders, update status, manage delivery
6. **Analytics Dashboard** → View sales reports, customer analytics
7. **Profile Management** → Update shop information, business hours

### Admin Journey
1. **System Dashboard** → Overview of all shops, orders, users
2. **Shop Management** → Approve new shops, manage existing ones
3. **Product Oversight** → Monitor product listings, handle reports
4. **Order Monitoring** → Track system-wide order patterns
5. **User Management** → Handle customer support, manage accounts
6. **System Configuration** → Manage categories, delivery settings

## 🔧 Development Setup

### Prerequisites
- Java 17+
- Node.js 18+
- Angular CLI 17+
- Flutter 3.x
- PostgreSQL 14+
- Docker & Docker Compose

### Backend Setup
```bash
cd backend
mvn clean install
mvn spring-boot:run
```

### Frontend Setup
```bash
cd frontend
npm install
ng serve
```

### Mobile App Setup
```bash
cd mobile/nammaooru_mobile_app
flutter pub get
flutter run
```

### Full System with Docker
```bash
docker-compose up --build -d
```

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/auth/send-otp` - Send OTP for verification

### Customer APIs
- `GET /api/customer/shops` - List available shops
- `GET /api/customer/shops/{id}` - Shop details
- `GET /api/customer/shops/{id}/products` - Shop products
- `POST /api/customer/orders` - Place new order
- `GET /api/customer/orders` - Order history

### Shop Owner APIs
- `GET /api/shop-owner/products` - Manage products
- `POST /api/shop-owner/products` - Add new product
- `PUT /api/shop-owner/products/{id}` - Update product
- `GET /api/shop-owner/orders-management` - Shop orders
- `PUT /api/shop-owner/orders-management/{id}/status` - Update order status

### Admin APIs
- `GET /api/admin/shops` - All shops management
- `GET /api/admin/users` - User management
- `GET /api/admin/analytics` - System analytics

## 🚀 Deployment

### Production Environment
- **Server**: Hetzner Cloud (65.21.4.236)
- **Domain**: nammaoorudelivary.in
- **API**: api.nammaoorudelivary.in
- **SSL**: Let's Encrypt auto-renewal
- **Database**: PostgreSQL in Docker
- **Email**: Hostinger SMTP

### Deployment Process
```bash
# Pull latest changes
git pull origin main

# Build and deploy
docker-compose down
docker-compose up --build -d

# Check status
docker-compose ps
docker-compose logs -f
```

## 🔧 Configuration

### Environment Variables
```bash
# Database
POSTGRES_DB=shop_management
POSTGRES_USER=shop_user
POSTGRES_PASSWORD=shop_password

# JWT
JWT_SECRET=your-256-bit-secret
JWT_EXPIRATION=86400000

# Email (Hostinger)
SPRING_MAIL_HOST=smtp.hostinger.com
SPRING_MAIL_PORT=465
SPRING_MAIL_USERNAME=noreplay@nammaoorudelivary.in
SPRING_MAIL_PASSWORD=your-email-password

# Firebase
FIREBASE_CONFIG_PATH=/path/to/firebase-config.json
```

## 📊 Features by Role

### 👤 Customers
- ✅ Shop discovery and browsing
- ✅ Product search and filtering
- ✅ Shopping cart management
- ✅ Order placement and tracking
- ✅ Profile management
- ✅ Order history
- ✅ Push notifications

### 🏪 Shop Owners
- ✅ Product catalog management
- ✅ Order processing
- ✅ Inventory tracking
- ✅ Sales analytics
- ✅ Customer communication
- ✅ Business profile management
- ✅ Image upload and management

### 👑 Super Admins
- ✅ System-wide dashboard
- ✅ Shop approval and management
- ✅ User management
- ✅ Category management
- ✅ System analytics
- ✅ Platform configuration

### 🚚 Delivery Partners
- ⏳ Order assignment
- ⏳ Route optimization
- ⏳ Delivery tracking
- ⏳ Payment collection

## 🐛 Known Issues & Solutions

### Fixed Issues ✅
1. **Login Error Messages** - Now shows specific error for wrong email/password
2. **Image URL Consistency** - Fixed missing file extensions and API path issues
3. **Service Integration** - All frontend services correctly mapped to backend APIs
4. **Cart Functionality** - Shopping cart now properly manages items and quantities
5. **Checkout Flow** - Order placement integrated with backend order system

### Ongoing Improvements 🔄
1. **Performance Optimization** - Database query optimization
2. **Mobile App Polish** - Enhanced UI/UX for mobile users
3. **Advanced Analytics** - More detailed reporting features
4. **Payment Integration** - Multiple payment gateway support

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [📧 Email Configuration](EMAIL_CONFIGURATION.md) | SMTP setup and troubleshooting |
| [🚀 Deployment Guide](DEPLOYMENT_GUIDE.md) | Complete deployment instructions |
| [📱 Mobile App Guide](MOBILE_APP_GUIDE.md) | Flutter app development guide |
| [🔧 Troubleshooting Guide](TROUBLESHOOTING_GUIDE.md) | Common issues and solutions |
| [📋 Documentation Index](DOCUMENTATION_INDEX.md) | Complete documentation overview |

## 🤝 Contributing

### Development Workflow
1. Create feature branch from `main`
2. Implement changes with tests
3. Update documentation
4. Submit pull request
5. Code review and merge

### Code Standards
- **Backend**: Java Spring Boot best practices
- **Frontend**: Angular style guide
- **Mobile**: Flutter conventions
- **API**: RESTful design principles

## 📞 Support

### Quick Help
1. Check [Troubleshooting Guide](TROUBLESHOOTING_GUIDE.md)
2. Review [Documentation Index](DOCUMENTATION_INDEX.md)
3. Check system logs
4. Contact system administrator

### Emergency Contacts
- **System Admin**: Available for critical issues
- **Infrastructure**: Hetzner Cloud support
- **Email Issues**: Hostinger support

## 🔄 Recent Updates

### Latest Changes (January 2025)
- ✅ **Customer Flow Integration**: Complete end-to-end customer journey
- ✅ **Shop Owner Dashboard**: Enhanced product and order management
- ✅ **API Standardization**: Consistent error handling and response format
- ✅ **Image Management**: Fixed URL generation and serving
- ✅ **Authentication**: Improved error messages and user experience
- ✅ **Service Architecture**: Proper frontend-backend integration

### Next Planned Features
- 🔄 **Delivery Partner Module**: Complete delivery management system
- 🔄 **Advanced Analytics**: Enhanced reporting and insights
- 🔄 **Payment Gateway**: Multiple payment options
- 🔄 **Mobile App Enhancements**: Improved UI/UX and performance

## 📈 System Status

**Overall Status**: ✅ **Operational**

- **Backend API**: ✅ Running
- **Web Frontend**: ✅ Running  
- **Mobile App**: ✅ Compatible
- **Database**: ✅ Connected
- **Email Service**: ✅ Working
- **File Upload**: ✅ Working
- **Notifications**: ✅ Active

---

**Project**: NammaOoru Shop Management System  
**Version**: 2.0.0  
**Last Updated**: January 2025  
**Status**: Production Ready with Full Customer & Shop Owner Flows  
**License**: Private/Commercial Use  

For technical questions or support, refer to the [Documentation Index](DOCUMENTATION_INDEX.md).