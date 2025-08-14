# Shop Management System

A comprehensive, modular shop management system built with **Spring Boot 3.x** backend, **PostgreSQL** database, and **Angular 16+** frontend with Google Maps integration.

## 🚀 Features

### Backend Features
- **Spring Boot 3.x** with Java 17+
- **PostgreSQL** database with comprehensive schema
- **JWT Authentication** with role-based access control (ADMIN, USER, SHOP_OWNER)
- **Modular Shop Module** - completely independent and reusable
- **RESTful APIs** with comprehensive validation
- **Advanced filtering, search, and pagination**
- **File upload** for shop images with multiple image types
- **Geographic location support** with lat/lng coordinates
- **Global exception handling**
- **CORS support** for frontend integration

### Frontend Features
- **Angular 16+** with TypeScript
- **Angular Material UI** for modern, responsive design
- **Modular architecture** with feature modules
- **JWT authentication** with HTTP interceptors
- **Google Maps integration** for location picking and directions
- **Role-based access control**
- **Responsive design** for all devices
- **Image upload** with drag-and-drop support

### Database Features
- **Complete shop information** - business details, location, owner info
- **Performance metrics** - ratings, orders, revenue tracking
- **Image management** - multiple images per shop with types (logo, banner, gallery)
- **Geographic data** - latitude/longitude for location services
- **Audit trail** - created/updated by and timestamps
- **Optimized indexes** for fast queries

## 🏗️ Architecture

### Modular Design
The shop functionality is implemented as a **completely independent module** that can be easily integrated into other projects:

```
shop-module/
├── entity/          # JPA entities
├── repository/      # Data access layer
├── service/         # Business logic
├── controller/      # REST endpoints
├── dto/             # Data transfer objects
├── mapper/          # Entity-DTO mapping
├── specification/   # Dynamic queries
├── exception/       # Custom exceptions
└── util/           # Helper utilities
```

## 📋 Prerequisites

- **Java 17+**
- **Node.js 16+**
- **PostgreSQL 12+**
- **Maven 3.6+**
- **Angular CLI 16+**
- **Google Maps API Key** (for location features)

## 🛠️ Installation & Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd shop-management-system
```

### 2. Database Setup
```sql
-- Create database
CREATE DATABASE shop_management;

-- Create user (optional)
CREATE USER shop_admin WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE shop_management TO shop_admin;

-- Run the schema
psql -d shop_management -f database/schema.sql
```

### 3. Backend Setup
```bash
cd backend

# Update application.yml with your database credentials
# src/main/resources/application.yml

# Build and run
mvn clean install
mvn spring-boot:run
```

The backend will start on `http://localhost:8080`

### 4. Frontend Setup
```bash
cd frontend

# Install dependencies
npm install

# Update environment configuration
# src/environments/environment.ts - Add your Google Maps API key

# Start development server
ng serve
```

The frontend will start on `http://localhost:4200`

## 📚 API Documentation

### Authentication Endpoints
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration

### Shop Management Endpoints
- `GET /api/shops` - Get all shops with filtering
- `GET /api/shops/active` - Get active shops only
- `GET /api/shops/search?q=term` - Search shops
- `GET /api/shops/nearby?lat=X&lng=Y&radius=Z` - Get nearby shops
- `GET /api/shops/featured` - Get featured shops
- `GET /api/shops/{id}` - Get shop by ID
- `POST /api/shops` - Create new shop (AUTH required)
- `PUT /api/shops/{id}` - Update shop (AUTH required)
- `DELETE /api/shops/{id}` - Delete shop (ADMIN only)
- `PUT /api/shops/{id}/approve` - Approve shop (ADMIN only)
- `PUT /api/shops/{id}/reject` - Reject shop (ADMIN only)

### Shop Images Endpoints
- `POST /api/shops/{shopId}/images` - Upload shop image
- `GET /api/shops/{shopId}/images` - Get shop images
- `DELETE /api/shops/{shopId}/images/{imageId}` - Delete image
- `PUT /api/shops/{shopId}/images/{imageId}/primary` - Set primary image

## 🔐 Authentication & Authorization

### User Roles
- **ADMIN**: Full system access, can approve/reject shops
- **SHOP_OWNER**: Can create and manage own shops
- **USER**: Can view shops and basic functionality

### JWT Token
- Include in requests: `Authorization: Bearer <token>`
- Token expires in 24 hours (configurable)
- Automatic refresh handling in frontend

## 🗺️ Google Maps Integration

### Setup
1. Get Google Maps API Key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable these APIs:
   - Maps JavaScript API
   - Places API
   - Geocoding API
3. Update `environment.ts` with your API key

### Features
- **Location Picker**: Interactive map for selecting shop locations
- **Geocoding**: Convert addresses to coordinates
- **Directions**: Get directions to shops
- **Nearby Search**: Find shops within radius

## 📱 Responsive Design

The application is fully responsive and works on:
- **Desktop** (1200px+)
- **Tablet** (768px - 1199px)
- **Mobile** (< 768px)

## 🔧 Configuration

### Backend Configuration (`application.yml`)
```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/shop_management
    username: ${DB_USERNAME:postgres}
    password: ${DB_PASSWORD:password}

jwt:
  secret: ${JWT_SECRET:your-secret-key}
  expiration: 86400000 # 24 hours

file:
  upload:
    path: ${FILE_UPLOAD_PATH:./uploads}
    max-size: 10MB
```

### Frontend Configuration (`environment.ts`)
```typescript
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080/api',
  googleMapsApiKey: 'YOUR_GOOGLE_MAPS_API_KEY_HERE'
};
```

## 🚀 Deployment

### Production Build

#### Backend
```bash
cd backend
mvn clean package -Pprod
java -jar target/shop-management-backend-1.0.0.jar
```

#### Frontend
```bash
cd frontend
ng build --configuration=production
# Deploy dist/ folder to web server
```

## 🧪 Testing

### Backend Tests
```bash
cd backend
mvn test
```

### Frontend Tests
```bash
cd frontend
npm test
```

## 📞 Support

For support and questions:
- Email: support@shopmanagement.com
- Issues: Create issues in the repository
- Documentation: Refer to code comments and API documentation

---

**Built with ❤️ using Spring Boot, Angular, and PostgreSQL**"# Nammaooru" 
