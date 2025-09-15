# 📱 HTML Mobile App Mockups

Interactive HTML mockups for the NammaOoru mobile applications. These can be viewed in any browser to preview the mobile app designs.

## 🚚 Delivery Partner App

**Location:** `delivery_partner/`

### Screens Created:
- **`login.html`** - Mobile OTP authentication with phone validation
- **`dashboard.html`** - Real-time order management with online/offline toggle
- **`earnings.html`** - Comprehensive earnings dashboard with withdrawal system

### Features Demonstrated:
- ✅ Professional mobile UI with iOS/Android design patterns
- ✅ Interactive OTP login flow with form validation
- ✅ Online/offline status toggle with order visibility
- ✅ Order acceptance/rejection workflow
- ✅ Real-time order status updates
- ✅ Earnings breakdown with period selection
- ✅ Withdrawal functionality with bank details
- ✅ Bottom navigation with active states
- ✅ Responsive design for mobile viewports

## 🏪 Shop Owner App

**Location:** `shop_owner/`

### Screens Created:
- **`login.html`** - Shop owner authentication with shop info preview
- **`dashboard.html`** - Complete order management dashboard
- **`products.html`** - Product inventory management system

### Features Demonstrated:
- ✅ Shop-specific branding and theming
- ✅ Open/closed shop toggle functionality
- ✅ New order notifications with accept/reject actions
- ✅ Order preparation workflow with time selection
- ✅ Delivery tracking integration
- ✅ Product CRUD operations with modal forms
- ✅ Inventory overview with stock management
- ✅ Product stats and analytics preview
- ✅ Category-based organization

## 🎯 Key Features

### Interactive Elements:
- **Form Validation** - Real-time validation for phone numbers and OTP
- **Dynamic Content** - Orders, products, and stats update dynamically
- **Modal Dialogs** - Product editing, time selection, withdrawal forms
- **Toggle States** - Online/offline, open/closed, enable/disable
- **Navigation** - Bottom navigation with active state management

### Visual Design:
- **Mobile-First** - Optimized for 375px width (iPhone standard)
- **Material Design** - Following modern mobile UI patterns
- **Color Coding** - Status-based color schemes (green=active, red=inactive, etc.)
- **Icons & Emojis** - Visual icons for better user experience
- **Animations** - Smooth transitions and loading states

### Mock Data Integration:
- **Realistic Data** - Sample orders, products, earnings with Indian pricing
- **API Structure** - Ready for backend integration
- **State Management** - LocalStorage simulation for persistent data

## 🚀 How to Use

### Option 1: Direct Browser Opening
```bash
# Open any HTML file directly in browser
open delivery_partner/login.html
open shop_owner/dashboard.html
```

### Option 2: Local Server (Recommended)
```bash
# Use Python simple server
python -m http.server 8000
# Then visit: http://localhost:8000/delivery_partner/login.html

# Or use Node.js serve
npx serve .
# Then navigate to the HTML files
```

### Option 3: Live Server (VS Code)
- Install "Live Server" extension
- Right-click any HTML file → "Open with Live Server"

## 📱 Mobile Testing

### Browser DevTools:
1. Open browser DevTools (F12)
2. Click mobile/responsive design mode
3. Set device to iPhone 12/13 (375x812px)
4. Test all interactive features

### Real Device Testing:
- Copy files to web server
- Access via mobile browser
- Test touch interactions and scrolling

## 🔄 Navigation Flow

### Delivery Partner App:
```
login.html → dashboard.html ⟷ earnings.html
```

### Shop Owner App:
```
login.html → dashboard.html ⟷ products.html
```

## 🛠️ Customization

### Color Themes:
- **Delivery Partner:** Green-based theme (`#4CAF50`)
- **Shop Owner:** Orange-based theme (`#FF9800`)

### Responsive Breakpoints:
- **Mobile:** 375px (default)
- **Large Mobile:** 414px
- **Tablet:** 768px+ (scales automatically)

### Font System:
- Primary: `-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto`
- Fallback: `sans-serif`

## 🔗 Integration Points

### Ready for API Connection:
- All forms include proper input validation
- JavaScript functions prepared for fetch() calls
- Mock data structured to match backend APIs
- Error handling patterns implemented

### Backend APIs Expected:
```javascript
// Authentication
POST /api/auth/send-otp
POST /api/auth/verify-otp

// Delivery Partner
GET /api/delivery/orders/available
POST /api/delivery/orders/{id}/accept
POST /api/delivery/orders/{id}/reject
GET /api/delivery/earnings

// Shop Owner
GET /api/shop-owner/orders-management
POST /api/shop-owner/orders-management/{id}/accept
POST /api/shop-owner/products
PUT /api/shop-owner/products/{id}
```

## 💡 Next Steps

1. **Flutter Implementation** - Convert these designs to Flutter widgets
2. **API Integration** - Connect to existing NammaOoru backend
3. **Push Notifications** - Add real-time order notifications
4. **Location Services** - Integrate Google Maps for delivery tracking
5. **Payment Gateway** - Add payment processing for withdrawals

**Ready for development! 🚀**