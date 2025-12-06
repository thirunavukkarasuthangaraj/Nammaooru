# NammaOoru Thiru Software System - Documentation

Complete documentation for the NammaOoru multi-vendor food delivery and e-commerce platform.

## 📁 Documentation Structure

### 1. [Deployment](deployment/)
**Production deployment guides and CI/CD configuration**
- Deployment procedures
- Server setup
- CI/CD pipeline
- Environment configuration
- Troubleshooting deployment issues

### 2. [Notifications](notifications/)
**Firebase Cloud Messaging and push notification system**
- Firebase setup (backend & mobile)
- Notification flows
- FCM token management
- Troubleshooting notifications
- Local development setup

### 3. [Application Flows](application-flows/)
**Business logic and user workflows**
- Complete order flows
- Self-pickup feature
- Delivery workflows
- Payment flows
- Order state management

### 4. [Technical Architecture](technical/)
**System design and architecture documentation**
- Technical architecture overview
- Database schema
- System components
- Technology stack
- Documentation index

### 5. [API Documentation](api/)
**REST API endpoints and integration guides**
- Complete features and API list
- API endpoints
- Request/response formats
- Authentication
- Email configuration

### 6. [Mobile Apps](mobile-apps/)
**Mobile application architecture and guides**
- Customer app architecture
- Shop owner app architecture
- Delivery partner app architecture
- Mobile app development guide
- App version management

## 🚀 Quick Start

### For New Developers
1. Start with [Technical Architecture](technical/TECHNICAL_ARCHITECTURE.md)
2. Review [Complete Order Flows](application-flows/COMPLETE_ORDER_FLOWS.md)
3. Check [API Documentation](api/COMPLETE_FEATURES_AND_API_LIST.md)

### For Deployment
1. Follow [Deployment Guide](deployment/DEPLOYMENT_GUIDE.md)
2. If issues occur, check [Troubleshooting Guide](deployment/TROUBLESHOOTING_GUIDE.md)

### For Mobile Development
1. Review mobile app architecture docs in [Mobile Apps](mobile-apps/)
2. Set up notifications using [Notification guides](notifications/)

### For Firebase/Notifications
1. Backend setup: [Firebase Backend Setup](notifications/FIREBASE_BACKEND_SETUP.md)
2. Mobile setup: [Mobile Firebase Setup](notifications/MOBILE_APP_FIREBASE_SETUP.md)
3. Issues: [Notification Troubleshooting](notifications/NOTIFICATION_ISSUE_RESOLUTION.md)

## 📊 System Overview

**NammaOoru** is a comprehensive multi-vendor platform supporting:
- 🛒 **E-commerce**: Multiple shops selling products
- 🍔 **Food Delivery**: Restaurant orders with delivery
- 📦 **Self-Pickup**: Customers can pick up orders
- 🚗 **Delivery Partners**: Rapido-style delivery system
- 👥 **Multiple User Types**: Customers, Shop Owners, Delivery Partners, Admins

## 🔑 Key Features

- Real-time order tracking
- Push notifications (Firebase)
- Multiple payment methods
- Promo code system
- Analytics dashboard
- Auto-assignment of delivery partners
- Guest mode (no login required)
- Location-based shop discovery

## 🛠️ Technology Stack

### Backend
- Java Spring Boot
- PostgreSQL
- Firebase Admin SDK
- JWT Authentication

### Frontend
- Angular
- Material UI
- RxJS

### Mobile
- Flutter
- Firebase Cloud Messaging
- Location Services

## 📱 Applications

1. **Customer App** - Order food/products
2. **Shop Owner App** - Manage shop and orders
3. **Delivery Partner App** - Deliver orders
4. **Admin Panel** - System management

## 🆘 Need Help?

- **Deployment Issues**: See [Troubleshooting Guide](deployment/TROUBLESHOOTING_GUIDE.md)
- **Notification Issues**: See [Notification Troubleshooting](notifications/PUSH_NOTIFICATION_TROUBLESHOOTING.md)
- **API Questions**: See [API Documentation](api/COMPLETE_FEATURES_AND_API_LIST.md)
- **Architecture Questions**: See [Technical Documentation](technical/TECHNICAL_ARCHITECTURE.md)

## 📝 Contributing

When adding new documentation:
1. Place in appropriate folder
2. Update the folder's README.md
3. Link from this main README.md
4. Follow markdown formatting standards

## 📅 Last Updated

October 24, 2025

---

**Maintained by**: Development Team