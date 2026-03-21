# 📱 MOBILE APP API IMPLEMENTATION GUIDE

## 🌐 SERVER CONFIGURATION OPTIONS

### **Option 1: Production Server (Recommended) ✅**
```dart
// File: lib/core/config/env_config.dart
static const String baseUrl = 'https://api.nammaoorudelivary.in';
```
**✅ Pros**: 
- Already deployed and accessible
- SSL enabled  
- Works on any device/network
- No additional setup needed

**❌ Cons**:
- Changes affect live environment
- Need internet connection

### **Option 2: Local Development Alternatives**

#### **🔗 For Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:8082';
```

#### **🔗 For iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:8082';
```

#### **🔗 For Physical Device (Same WiFi):**
```dart
// Find your computer's IP address
// Windows: ipconfig
// Mac/Linux: ifconfig
static const String baseUrl = 'http://192.168.1.100:8082';
```

#### **🔗 Using ngrok (Universal Solution):**
```bash
# Install ngrok: https://ngrok.com/download
# Run your backend server
cd backend && mvn spring-boot:run

# In new terminal
ngrok http 8082
# Output: https://abc123.ngrok.io -> http://localhost:8082

# Use ngrok URL in Flutter
static const String baseUrl = 'https://abc123.ngrok.io';
```

---

## 📋 IMPLEMENTATION STEPS

### **Phase 1: API Setup (✅ COMPLETED)**

#### 1. **Environment Configuration**
- ✅ Updated `env_config.dart` with production API URL
- ✅ Added development alternatives with comments
- ✅ Configured timeout and retry settings

#### 2. **HTTP Client Setup**  
- ✅ Created `ApiService` with error handling
- ✅ Added authentication token management
- ✅ Implemented request/response logging
- ✅ Added timeout and error handling

#### 3. **API Service Classes**
- ✅ `AuthApiService` - Login, register, OTP
- ✅ `ShopApiService` - Shop discovery, products
- ✅ `CartApiService` - Cart management, promos
- ✅ `OrderApiService` - Orders, tracking, invoices
- ✅ `Logger` utility for debugging

### **Phase 2: Integration with UI Screens**

#### 1. **Update Auth Screens**
```dart
// In customer_login_screen.dart
import '../../services/auth_api_service.dart';

final _authApi = AuthApiService();

Future<void> _handleLogin() async {
  try {
    final response = await _authApi.login(
      emailOrPhone: _emailController.text,
      password: _passwordController.text,
    );
    
    // Handle success
    if (response['success'] == true) {
      Navigator.pushReplacementNamed(context, '/customer-dashboard');
    }
  } catch (e) {
    // Handle error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login failed: ${e.toString()}')),
    );
  }
}
```

#### 2. **Update Shop Screens**
```dart
// In shops_screen.dart  
import '../../services/shop_api_service.dart';

final _shopApi = ShopApiService();

Future<void> _loadShops() async {
  setState(() => _isLoading = true);
  
  try {
    final response = await _shopApi.getActiveShops(
      page: 0,
      size: 20,
      sortBy: _sortBy,
      city: _selectedCity,
    );
    
    setState(() {
      _shops = (response['data']['content'] as List)
          .map((json) => ShopModel.fromJson(json))
          .toList();
    });
  } catch (e) {
    Helpers.showSnackBar(context, 'Failed to load shops', isError: true);
  } finally {
    setState(() => _isLoading = false);
  }
}
```

#### 3. **Update Cart Provider**
```dart
// In cart_provider.dart
import '../services/cart_api_service.dart';

class CartProvider extends ChangeNotifier {
  final _cartApi = CartApiService();
  
  Future<void> addToCart(ProductModel product) async {
    try {
      final response = await _cartApi.addToCart(
        shopProductId: int.parse(product.id),
        quantity: 1,
      );
      
      if (response['success'] == true) {
        // Update local cart state
        _items.add(CartItem.fromProduct(product));
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to add to cart: $e');
    }
  }
}
```

---

## 🔧 TESTING PLAN

### **Step 1: Test API Connectivity**
```dart
// Add this test method to main.dart
void testApiConnection() async {
  final authApi = AuthApiService();
  
  try {
    // Test health check or any simple endpoint
    final response = await authApi.validateToken();
    print('✅ API Connection: SUCCESS');
    print('Response: $response');
  } catch (e) {
    print('❌ API Connection: FAILED');
    print('Error: $e');
  }
}

// Call in main()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API
  ApiService().initialize();
  
  // Test connection (only in debug mode)
  if (kDebugMode) {
    testApiConnection();
  }
  
  runApp(MyApp());
}
```

### **Step 2: Test Authentication Flow**
1. Start with customer registration
2. Test login with created account  
3. Verify token storage and validation
4. Test logout functionality

### **Step 3: Test Shop Discovery**
1. Load shops from API
2. Test search functionality
3. Verify filtering and sorting
4. Test shop details loading

### **Step 4: Test Complete Order Flow**
1. Browse products → Add to cart → Checkout → Place order
2. Verify order tracking
3. Test order history

---

## 🚀 DEPLOYMENT CHECKLIST

### **For Production Build:**
```dart
// Ensure production API URL
static const String baseUrl = 'https://api.nammaoorudelivary.in';

// Disable debug features
static const bool enableLogging = false;
static const bool showDebugInfo = false;
static const bool enableNetworkLogging = false;
```

### **Build Commands:**
```bash
# Android
flutter build apk --release

# iOS  
flutter build ios --release
```

### **Test APK Installation:**
```bash
# Install on connected device
flutter install

# Or manually install APK
adb install build/app/outputs/apk/release/app-release.apk
```

---

## 📞 API ENDPOINTS READY TO USE

All these endpoints are **already implemented** in your Spring Boot backend:

### **✅ Authentication**
- `POST /api/auth/login`
- `POST /api/auth/logout`  
- `GET /api/auth/validate`
- `POST /api/customers/register`

### **✅ Shops & Products**
- `GET /api/shops/active`
- `GET /api/shops/search`
- `GET /api/shops/nearby`
- `GET /api/shop-products`

### **✅ Orders**
- `POST /api/customers/orders`
- `GET /api/customers/orders`
- `GET /api/orders/{id}/tracking`

### **✅ Cart (If implemented)**
- `GET /api/customers/cart`
- `POST /api/customers/cart/add`

---

## 🎯 NEXT STEPS

1. **Choose API URL** (Production recommended)
2. **Update screens** to use API services
3. **Test authentication flow**
4. **Test shop browsing**
5. **Test order placement**
6. **Build and deploy APK**

Your mobile app is **ready for API integration**! The backend is fully functional and accessible. 🚀📱