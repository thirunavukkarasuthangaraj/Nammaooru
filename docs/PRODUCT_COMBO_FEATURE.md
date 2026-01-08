# Product Combo / Bundle Feature

## Document Information
| Field | Value |
|-------|-------|
| Version | 1.0 |
| Created | 08-Jan-2026 |
| Author | Development Team |
| Status | Proposed |

---

## 1. Overview

### 1.1 Purpose
Allow shop owners to create product combos/bundles (e.g., "Pongal Special Combo - 15 items @ ₹2000") that customers can purchase as a single unit with a discounted price.

### 1.2 Use Cases
- **Festival Combos**: Pongal, Diwali, Christmas special bundles
- **Daily Essentials**: Weekly grocery combo
- **Meal Kits**: Breakfast combo, Dinner combo
- **Gift Hampers**: Birthday combo, Wedding combo

### 1.3 Benefits
| Stakeholder | Benefit |
|-------------|---------|
| Shop Owner | Increase average order value, clear inventory |
| Customer | Save money, convenience of buying related items together |
| Platform | Higher GMV, better engagement |

---

## 2. Database Schema

### 2.1 New Tables

#### Table: `product_combos`
```sql
CREATE TABLE product_combos (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    shop_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    name_tamil VARCHAR(255),
    description TEXT,
    description_tamil TEXT,
    banner_image_url VARCHAR(500),
    combo_price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2) NOT NULL,
    discount_percentage DECIMAL(5,2),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    max_quantity_per_order INT DEFAULT 5,
    total_quantity_available INT,
    total_sold INT DEFAULT 0,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    updated_by VARCHAR(255),

    FOREIGN KEY (shop_id) REFERENCES shops(id),
    INDEX idx_shop_active (shop_id, is_active),
    INDEX idx_dates (start_date, end_date)
);
```

#### Table: `combo_items`
```sql
CREATE TABLE combo_items (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    combo_id BIGINT NOT NULL,
    shop_product_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (combo_id) REFERENCES product_combos(id) ON DELETE CASCADE,
    FOREIGN KEY (shop_product_id) REFERENCES shop_products(id),
    UNIQUE KEY uk_combo_product (combo_id, shop_product_id)
);
```

### 2.2 Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│     shops       │       │ product_combos  │       │  combo_items    │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ id (PK)         │──────<│ id (PK)         │──────<│ id (PK)         │
│ name            │       │ shop_id (FK)    │       │ combo_id (FK)   │
│ ...             │       │ name            │       │ shop_product_id │
└─────────────────┘       │ combo_price     │       │ quantity        │
                          │ original_price  │       └─────────────────┘
                          │ start_date      │               │
                          │ end_date        │               │
                          │ is_active       │               │
                          └─────────────────┘               │
                                                            │
                          ┌─────────────────┐               │
                          │  shop_products  │<──────────────┘
                          ├─────────────────┤
                          │ id (PK)         │
                          │ product_name    │
                          │ price           │
                          └─────────────────┘
```

---

## 3. Backend API Endpoints

### 3.1 Shop Owner APIs

#### Create Combo
```
POST /api/shops/{shopId}/combos
Authorization: Bearer {token}
Content-Type: application/json

Request Body:
{
    "name": "Pongal Special Combo",
    "nameTamil": "பொங்கல் சிறப்பு கூடை",
    "description": "Complete Pongal celebration kit with 15 essential items",
    "descriptionTamil": "15 அத்தியாவசிய பொருட்களுடன் முழுமையான பொங்கல் கொண்டாட்ட தொகுப்பு",
    "bannerImageUrl": "/uploads/combos/pongal-banner.jpg",
    "comboPrice": 2000.00,
    "startDate": "2026-01-12",
    "endDate": "2026-01-16",
    "maxQuantityPerOrder": 3,
    "totalQuantityAvailable": 100,
    "isActive": true,
    "items": [
        { "shopProductId": 101, "quantity": 1 },
        { "shopProductId": 102, "quantity": 1 },
        { "shopProductId": 103, "quantity": 2 },
        ...
    ]
}

Response: 201 Created
{
    "statusCode": "0000",
    "message": "Combo created successfully",
    "data": {
        "id": 1,
        "name": "Pongal Special Combo",
        "comboPrice": 2000.00,
        "originalPrice": 2500.00,
        "discountPercentage": 20.0,
        "itemCount": 15,
        ...
    }
}
```

#### Get Shop Combos
```
GET /api/shops/{shopId}/combos?status=active&page=0&size=20
Authorization: Bearer {token}

Response: 200 OK
{
    "statusCode": "0000",
    "data": {
        "content": [
            {
                "id": 1,
                "name": "Pongal Special Combo",
                "nameTamil": "பொங்கல் சிறப்பு கூடை",
                "comboPrice": 2000.00,
                "originalPrice": 2500.00,
                "discountPercentage": 20.0,
                "bannerImageUrl": "/uploads/combos/pongal-banner.jpg",
                "startDate": "2026-01-12",
                "endDate": "2026-01-16",
                "isActive": true,
                "itemCount": 15,
                "totalSold": 25
            }
        ],
        "totalElements": 1,
        "totalPages": 1
    }
}
```

#### Update Combo
```
PUT /api/shops/{shopId}/combos/{comboId}
Authorization: Bearer {token}
Content-Type: application/json

Request Body: (same as create)

Response: 200 OK
```

#### Delete Combo
```
DELETE /api/shops/{shopId}/combos/{comboId}
Authorization: Bearer {token}

Response: 200 OK
{
    "statusCode": "0000",
    "message": "Combo deleted successfully"
}
```

#### Get Combo Details (with items)
```
GET /api/shops/{shopId}/combos/{comboId}
Authorization: Bearer {token}

Response: 200 OK
{
    "statusCode": "0000",
    "data": {
        "id": 1,
        "name": "Pongal Special Combo",
        "description": "Complete Pongal celebration kit",
        "comboPrice": 2000.00,
        "originalPrice": 2500.00,
        "discountPercentage": 20.0,
        "bannerImageUrl": "/uploads/combos/pongal-banner.jpg",
        "startDate": "2026-01-12",
        "endDate": "2026-01-16",
        "isActive": true,
        "items": [
            {
                "id": 1,
                "shopProductId": 101,
                "productName": "Raw Rice",
                "productNameTamil": "பச்சரிசி",
                "quantity": 1,
                "unitPrice": 80.00,
                "unit": "1kg",
                "imageUrl": "/uploads/products/rice.jpg"
            },
            {
                "id": 2,
                "shopProductId": 102,
                "productName": "Jaggery",
                "productNameTamil": "வெல்லம்",
                "quantity": 1,
                "unitPrice": 60.00,
                "unit": "500g",
                "imageUrl": "/uploads/products/jaggery.jpg"
            },
            ...
        ]
    }
}
```

### 3.2 Customer APIs

#### Get Active Combos for Shop
```
GET /api/customer/shops/{shopId}/combos
Authorization: Bearer {token} (optional)

Response: 200 OK
{
    "statusCode": "0000",
    "data": [
        {
            "id": 1,
            "name": "Pongal Special Combo",
            "nameTamil": "பொங்கல் சிறப்பு கூடை",
            "description": "Complete Pongal celebration kit with 15 essential items",
            "comboPrice": 2000.00,
            "originalPrice": 2500.00,
            "savings": 500.00,
            "discountPercentage": 20.0,
            "bannerImageUrl": "/uploads/combos/pongal-banner.jpg",
            "validTill": "2026-01-16",
            "itemCount": 15,
            "isAvailable": true
        }
    ]
}
```

#### Get Combo Details for Customer
```
GET /api/customer/combos/{comboId}
Authorization: Bearer {token} (optional)

Response: 200 OK
{
    "statusCode": "0000",
    "data": {
        "id": 1,
        "name": "Pongal Special Combo",
        "nameTamil": "பொங்கல் சிறப்பு கூடை",
        "description": "Complete Pongal celebration kit",
        "comboPrice": 2000.00,
        "originalPrice": 2500.00,
        "savings": 500.00,
        "discountPercentage": 20.0,
        "bannerImageUrl": "/uploads/combos/pongal-banner.jpg",
        "validTill": "2026-01-16",
        "isAvailable": true,
        "shopId": 1,
        "shopName": "Murugasan Store",
        "items": [
            {
                "productName": "Raw Rice",
                "productNameTamil": "பச்சரிசி",
                "quantity": 1,
                "unit": "1kg",
                "imageUrl": "/uploads/products/rice.jpg",
                "individualPrice": 80.00
            },
            ...
        ]
    }
}
```

#### Add Combo to Cart
```
POST /api/customer/cart/combo
Authorization: Bearer {token}
Content-Type: application/json

Request Body:
{
    "comboId": 1,
    "quantity": 1
}

Response: 200 OK
{
    "statusCode": "0000",
    "message": "Combo added to cart",
    "data": {
        "cartId": 123,
        "comboId": 1,
        "comboName": "Pongal Special Combo",
        "quantity": 1,
        "price": 2000.00,
        "itemCount": 15
    }
}
```

---

## 4. Shop Owner Mobile App (Flutter)

### 4.1 Screen Flow

```
Dashboard
    │
    └── Combos (New Menu Item)
            │
            ├── Combo List Screen
            │       │
            │       ├── [+ Create] → Create Combo Flow
            │       │
            │       └── [Combo Card] → Combo Detail Screen
            │               │
            │               ├── [Edit] → Edit Combo Flow
            │               │
            │               └── [Delete] → Confirmation Dialog
            │
            └── Create/Edit Combo Flow
                    │
                    ├── Step 1: Basic Info
                    │   - Name (English & Tamil)
                    │   - Description
                    │   - Banner Image Upload
                    │
                    ├── Step 2: Select Products
                    │   - Search/Filter Products
                    │   - Select Multiple Products
                    │   - Set Quantity for Each
                    │
                    └── Step 3: Pricing & Validity
                        - Original Price (Auto-calculated)
                        - Combo Price (Manual)
                        - Start Date
                        - End Date
                        - Active/Inactive Toggle
```

### 4.2 UI Screens

#### 4.2.1 Combo List Screen
```dart
// File: lib/features/combos/screens/combo_list_screen.dart

class ComboListScreen extends StatefulWidget {
  // Displays list of all combos for the shop
  // FAB to create new combo
  // Each card shows: name, item count, price, validity, status
  // Swipe actions: Edit, Delete
}
```

#### 4.2.2 Create Combo Screen (Stepper)
```dart
// File: lib/features/combos/screens/create_combo_screen.dart

class CreateComboScreen extends StatefulWidget {
  // 3-step stepper form
  // Step 1: Basic info (name, description, image)
  // Step 2: Product selection (multi-select with quantities)
  // Step 3: Pricing and validity dates
}
```

#### 4.2.3 Product Selection Screen
```dart
// File: lib/features/combos/screens/product_selection_screen.dart

class ProductSelectionScreen extends StatefulWidget {
  // Search bar to filter products
  // Checkbox list of shop products
  // Quantity selector for each selected product
  // Running total display at bottom
}
```

### 4.3 Widgets

```dart
// Combo Card Widget
class ComboCard extends StatelessWidget {
  final Combo combo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
}

// Combo Item Tile
class ComboItemTile extends StatelessWidget {
  final ComboItem item;
  final VoidCallback onQuantityChanged;
  final VoidCallback onRemove;
}

// Combo Summary Widget
class ComboSummaryWidget extends StatelessWidget {
  final double originalPrice;
  final double comboPrice;
  final int itemCount;
}
```

### 4.4 State Management
```dart
// Combo Provider
class ComboProvider extends ChangeNotifier {
  List<Combo> _combos = [];
  bool _isLoading = false;

  Future<void> loadCombos(int shopId);
  Future<void> createCombo(CreateComboRequest request);
  Future<void> updateCombo(int comboId, UpdateComboRequest request);
  Future<void> deleteCombo(int comboId);
  Future<void> toggleComboStatus(int comboId);
}
```

---

## 5. Customer Mobile App (Flutter)

### 5.1 Screen Flow

```
Shop Details Screen
    │
    └── Combo Banner Section (New)
            │
            └── [Tap Banner] → Combo Detail Bottom Sheet
                    │
                    ├── View all items included
                    │
                    └── [Add to Cart] → Cart Screen
                            │
                            └── Combo shown as single line item
                                    │
                                    └── Checkout → Order with combo
```

### 5.2 UI Components

#### 5.2.1 Combo Banner Widget
```dart
// File: lib/features/customer/widgets/combo_banner_widget.dart

class ComboBannerWidget extends StatelessWidget {
  final List<Combo> combos;
  final Function(Combo) onComboTapped;

  // Horizontal scrolling banner cards
  // Each card shows:
  //   - Banner image
  //   - Combo name
  //   - Price with strikethrough original
  //   - "X items" badge
  //   - Validity countdown
}
```

#### 5.2.2 Combo Detail Bottom Sheet
```dart
// File: lib/features/customer/widgets/combo_detail_sheet.dart

class ComboDetailSheet extends StatelessWidget {
  final Combo combo;
  final VoidCallback onAddToCart;

  // Full-screen bottom sheet showing:
  //   - Large banner image
  //   - Combo name (English & Tamil)
  //   - Description
  //   - Scrollable list of all items
  //   - Price breakdown
  //   - "Add to Cart" button
}
```

#### 5.2.3 Cart Combo Item
```dart
// File: lib/features/customer/widgets/cart_combo_item.dart

class CartComboItem extends StatelessWidget {
  final CartCombo combo;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  // Shows combo as single expandable item in cart
  // Expand to see all included products
  // Quantity +/- controls
}
```

### 5.3 Integration Points

```dart
// In shop_details_screen.dart

Widget _buildShopDetailsContent() {
  return CustomScrollView(
    slivers: [
      // NEW: Combo Banner Section
      SliverToBoxAdapter(child: _buildComboBannerSection()),

      // Existing sections
      SliverToBoxAdapter(child: _buildCouponSection()),
      SliverToBoxAdapter(child: _buildHorizontalCategories()),
      SliverToBoxAdapter(child: _buildSearchBar()),
      _buildProductGrid(),
    ],
  );
}

Widget _buildComboBannerSection() {
  if (_combos.isEmpty) return SizedBox.shrink();

  return ComboBannerWidget(
    combos: _combos,
    onComboTapped: (combo) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => ComboDetailSheet(
          combo: combo,
          onAddToCart: () => _addComboToCart(combo),
        ),
      );
    },
  );
}
```

---

## 6. Angular Admin Panel (Optional)

### 6.1 New Components

```
src/app/features/shop-owner/
├── combo-management/
│   ├── combo-list.component.ts
│   ├── combo-list.component.html
│   ├── combo-form.component.ts
│   ├── combo-form.component.html
│   ├── combo-item-selector.component.ts
│   └── combo-item-selector.component.html
```

### 6.2 Routing
```typescript
// Add to shop-owner-routing.module.ts
{
  path: 'combos',
  component: ComboListComponent,
  canActivate: [AuthGuard]
},
{
  path: 'combos/create',
  component: ComboFormComponent,
  canActivate: [AuthGuard]
},
{
  path: 'combos/:id/edit',
  component: ComboFormComponent,
  canActivate: [AuthGuard]
}
```

---

## 7. Order Processing

### 7.1 Order Structure with Combo

```json
{
  "orderId": 12345,
  "orderNumber": "ORD1234567890",
  "items": [
    {
      "type": "COMBO",
      "comboId": 1,
      "comboName": "Pongal Special Combo",
      "quantity": 1,
      "unitPrice": 2000.00,
      "totalPrice": 2000.00,
      "comboItems": [
        { "productName": "Raw Rice", "quantity": 1, "unit": "1kg" },
        { "productName": "Jaggery", "quantity": 1, "unit": "500g" },
        ...
      ]
    },
    {
      "type": "PRODUCT",
      "productId": 201,
      "productName": "Milk",
      "quantity": 2,
      "unitPrice": 30.00,
      "totalPrice": 60.00
    }
  ],
  "subtotal": 2060.00,
  "deliveryFee": 0.00,
  "total": 2060.00
}
```

### 7.2 Stock Management
- When combo is ordered, decrease stock for each item in the combo
- If any item is out of stock, mark combo as unavailable
- Real-time stock check before adding combo to cart

---

## 8. Implementation Timeline

| Phase | Task | Duration |
|-------|------|----------|
| Phase 1 | Database schema + Entity classes | 1 day |
| Phase 2 | Backend APIs (CRUD + Customer) | 2 days |
| Phase 3 | Shop Owner Mobile App screens | 2 days |
| Phase 4 | Customer Mobile App integration | 1 day |
| Phase 5 | Testing & Bug fixes | 1 day |
| **Total** | | **7 days** |

---

## 9. Future Enhancements

1. **Auto-Combo Suggestions**: AI-powered combo recommendations based on purchase patterns
2. **Combo Analytics**: Dashboard showing combo performance metrics
3. **Limited Time Combos**: Flash sale combos with countdown timer
4. **Personalized Combos**: Customer-specific combo recommendations
5. **Combo Reviews**: Allow customers to rate and review combos

---

## 10. Appendix

### 10.1 Sample Pongal Combo Items

| # | Item | Quantity | Unit | Price |
|---|------|----------|------|-------|
| 1 | Raw Rice | 1 | kg | ₹80 |
| 2 | Jaggery | 500 | g | ₹60 |
| 3 | Ghee | 200 | ml | ₹150 |
| 4 | Cashew Nuts | 100 | g | ₹120 |
| 5 | Raisins | 100 | g | ₹80 |
| 6 | Cardamom | 10 | g | ₹40 |
| 7 | Moong Dal | 250 | g | ₹50 |
| 8 | Sugar | 500 | g | ₹30 |
| 9 | Coconut | 1 | pc | ₹40 |
| 10 | Banana | 6 | pcs | ₹50 |
| 11 | Turmeric Powder | 50 | g | ₹30 |
| 12 | Sugarcane | 2 | pcs | ₹60 |
| 13 | Milk | 500 | ml | ₹30 |
| 14 | Camphor | 1 | pack | ₹20 |
| 15 | Flowers | 1 | bunch | ₹60 |
| | **Original Total** | | | **₹2,500** |
| | **Combo Price** | | | **₹2,000** |
| | **Savings** | | | **₹500 (20%)** |

### 10.2 Status Codes

| Code | Description |
|------|-------------|
| ACTIVE | Combo is live and available |
| INACTIVE | Combo is disabled by shop owner |
| SCHEDULED | Combo will activate on start date |
| EXPIRED | Combo end date has passed |
| OUT_OF_STOCK | One or more items unavailable |

---

**Document End**
