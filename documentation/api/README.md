# API Documentation

REST API endpoints and integration guides for NammaOoru platform.

## 📄 Documents in this folder

### [COMPLETE_FEATURES_AND_API_LIST.md](COMPLETE_FEATURES_AND_API_LIST.md)
Complete feature list with all API endpoints
- Customer APIs
- Shop Owner APIs
- Delivery Partner APIs
- Admin APIs
- Authentication endpoints
- Payment endpoints
- Notification endpoints

### [EMAIL_CONFIGURATION.md](EMAIL_CONFIGURATION.md)
Email service configuration
- SMTP setup
- Email templates
- Notification emails
- Order confirmation emails
- Password reset emails

## 🔑 Authentication

All APIs require JWT token authentication (except login/register).

**Header**: `Authorization: Bearer <JWT_TOKEN>`

## 📱 API Base URLs

- **Backend**: `https://nammaoorudelivary.in/api`
- **Local**: `http://localhost:8080/api`

## 🔗 Main API Categories

### Customer APIs (`/api/customer/`)
- Order management
- Product browsing
- Cart operations
- Address management

### Shop Owner APIs (`/api/shop-owner/`)
- Shop management
- Order processing
- Menu management
- Analytics

### Delivery Partner APIs (`/api/mobile/delivery-partner/`)
- Order assignments
- Delivery management
- Earnings tracking
- Location updates

### Admin APIs (`/api/admin/`)
- User management
- System configuration
- Analytics
- Reports

## 📞 Support

For detailed API specifications, see [COMPLETE_FEATURES_AND_API_LIST.md](COMPLETE_FEATURES_AND_API_LIST.md).
