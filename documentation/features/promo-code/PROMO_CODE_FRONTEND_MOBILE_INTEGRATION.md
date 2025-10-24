# Promo Code Integration Guide - Frontend & Mobile

## 📱 MOBILE APP INTEGRATION (Flutter)

### ✅ Files Created:

1. **lib/core/services/promo_code_service.dart** - API integration service
2. **lib/core/services/device_info_service.dart** - Device UUID tracking
3. **lib/features/customer/widgets/promo_code_widget.dart** - Reusable promo UI widget

---

## 🔧 Step-by-Step Integration

### Step 1: Add Dependencies to pubspec.yaml

```yaml
dependencies:
  device_info_plus: ^10.1.2  # For device UUID
  uuid: ^4.5.1               # For generating UUIDs
  shared_preferences: ^2.3.4 # Already exists (for storing UUID)
  http: ^1.2.2               # Already exists (for API calls)
```

Run:
```bash
cd mobile/nammaooru_mobile_app
flutter pub get
```

---

### Step 2: Integrate in Checkout Screen

**File:** `lib/features/customer/orders/checkout_screen.dart`

Add these imports at the top:
```dart
import '../../../core/services/promo_code_service.dart';
import '../../../core/services/device_info_service.dart';
import '../widgets/promo_code_widget.dart';
```

Add these variables to `_CheckoutScreenState`:
```dart
class _CheckoutScreenState extends State<CheckoutScreen> {
  // ... existing variables ...

  // Promo Code variables
  PromoCodeValidationResult? _appliedPromo;
  double _promoDiscount = 0.0;
  String? _promoCode;

  // ... rest of code ...
}
```

Add promo code handling methods:
```dart
void _onPromoApplied(PromoCodeValidationResult result) {
  setState(() {
    _appliedPromo = result;
    _promoDiscount = result.discountAmount;
    _promoCode = result.promotionTitle; // or the code entered
  });
}

void _onPromoRemoved() {
  setState(() {
    _appliedPromo = null;
    _promoDiscount = 0.0;
    _promoCode = null;
  });
}

double get _finalTotal {
  final cart = Provider.of<CartProvider>(context, listen: false);
  final subtotal = cart.total;
  final delivery = _selectedDeliveryType == 'SELF_PICKUP' ? 0.0 : 20.0;
  return subtotal + delivery - _promoDiscount;
}
```

Add the PromoCodeWidget to your UI (in the payment summary section):
```dart
// Inside your build method, add this widget before the payment summary

PromoCodeWidget(
  orderAmount: Provider.of<CartProvider>(context).total,
  shopId: cart.items.first.product.shopId, // Get shop ID from cart
  customerId: _customerId, // Your customer ID
  customerPhone: _phoneController.text,
  onPromoApplied: _onPromoApplied,
  onPromoRemoved: _onPromoRemoved,
),

const SizedBox(height: 16),

// Payment Summary
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildSummaryRow('Subtotal', cart.total),
        if (_promoDiscount > 0)
          _buildSummaryRow(
            'Promo Discount',
            -_promoDiscount,
            color: Colors.green,
          ),
        _buildSummaryRow('Delivery Fee', deliveryFee),
        const Divider(),
        _buildSummaryRow('Total', _finalTotal, isBold: true),
      ],
    ),
  ),
),
```

Helper method for summary rows:
```dart
Widget _buildSummaryRow(String label, double amount, {Color? color, bool isBold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    ),
  );
}
```

### Step 3: Update Order Placement

In your `_placeOrder()` method, include promo code in the API request:

```dart
Future<void> _placeOrder() async {
  // ... existing validation ...

  // Get device UUID
  final deviceUuid = await DeviceInfoService().getDeviceUuid();

  final orderData = {
    'shopId': shopId,
    'items': items,
    'paymentMethod': _selectedPaymentMethod,
    'deliveryType': _selectedDeliveryType,
    'deliveryAddress': address,
    'deliveryPhone': _phoneController.text,
    'deliveryContactName': '${_nameController.text} ${_lastNameController.text}',
    'customerId': customerId,

    // Promo code fields
    'couponCode': _appliedPromo != null ? _promoCode : null,
    'discountAmount': _promoDiscount,

    // Device info for tracking
    'deviceUuid': deviceUuid,

    // ... other fields ...
  };

  // Send to API
  final response = await OrderService().placeOrder(orderData);
  // ... handle response ...
}
```

---

## 🎨 UI SCREENSHOTS

### Before Applying Promo:
```
┌─────────────────────────────────────────┐
│  💳 Checkout                            │
├─────────────────────────────────────────┤
│                                         │
│  ┌────────────────────────────────────┐│
│  │ 🎁 Have a promo code?         ▼   ││
│  └────────────────────────────────────┘│
│                                         │
│  ┌────────────────────────────────────┐│
│  │ Payment Summary                    ││
│  │                                    ││
│  │ Subtotal:          ₹530           ││
│  │ Delivery Fee:       ₹20           ││
│  │ ───────────────────────────────   ││
│  │ Total:             ₹550           ││
│  └────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

### Expanded Promo Section:
```
┌─────────────────────────────────────────┐
│  🎁 Have a promo code?         ▲       │
├─────────────────────────────────────────┤
│  ┌────────────────────┐                │
│  │ FIRST5             │  [Apply]       │
│  └────────────────────┘                │
│                                         │
│  Available Offers:                      │
│  ┌────────────────────────────────────┐│
│  │ FIRST5  First 5 Orders - ₹50 Off  →││
│  │         ₹50 OFF • Min order: ₹200  ││
│  └────────────────────────────────────┘│
│  ┌────────────────────────────────────┐│
│  │ SAVE20  20% Off on ₹500+ orders   →││
│  │         20% OFF • Min order: ₹500  ││
│  └────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

### After Applying Promo:
```
┌─────────────────────────────────────────┐
│  ┌────────────────────────────────────┐│
│  │ ✅ Promo Applied: FIRST5       ❌  ││
│  │ Promo code applied successfully!   ││
│  │ You saved ₹50                      ││
│  └────────────────────────────────────┘│
│                                         │
│  ┌────────────────────────────────────┐│
│  │ Payment Summary                    ││
│  │                                    ││
│  │ Subtotal:          ₹530           ││
│  │ Promo Discount:   -₹50  (green)   ││
│  │ Delivery Fee:       ₹20           ││
│  │ ───────────────────────────────   ││
│  │ Total:             ₹500           ││
│  └────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

---

## 🌐 ANGULAR ADMIN PANEL INTEGRATION

Now let's create Angular components for managing promo codes.

### Files to Create:

1. **services/promo-code.service.ts** - API service
2. **models/promo-code.model.ts** - TypeScript models
3. **components/promo-code-list/promo-code-list.component.ts** - List view
4. **components/promo-code-form/promo-code-form.component.ts** - Create/Edit form
5. **components/promo-code-stats/promo-code-stats.component.ts** - Statistics view

---

### File 1: Angular Model

**File:** `frontend/src/app/models/promo-code.model.ts`

```typescript
export interface PromoCode {
  id?: number;
  code: string;
  title: string;
  description?: string;
  type: PromoType;
  discountValue: number;
  minimumOrderAmount?: number;
  maximumDiscountAmount?: number;
  usageLimit?: number;
  usageLimitPerCustomer?: number;
  usedCount: number;
  startDate: Date | string;
  endDate: Date | string;
  status: PromoStatus;
  shopId?: number;
  targetAudience?: string;
  termsAndConditions?: string;
  isPublic: boolean;
  isFirstTimeOnly: boolean;
  stackable: boolean;
  imageUrl?: string;
  bannerUrl?: string;
  createdAt?: Date | string;
  updatedAt?: Date | string;
}

export enum PromoType {
  PERCENTAGE = 'PERCENTAGE',
  FIXED_AMOUNT = 'FIXED_AMOUNT',
  FREE_SHIPPING = 'FREE_SHIPPING',
  BUY_ONE_GET_ONE = 'BUY_ONE_GET_ONE'
}

export enum PromoStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  EXPIRED = 'EXPIRED',
  SUSPENDED = 'SUSPENDED'
}

export interface PromoCodeStats {
  totalUsageCount: number;
  uniqueCustomers: number;
  uniqueDevices: number;
  totalDiscountGiven: number;
  recentUsages: any[];
}
```

---

### File 2: Angular Service

**File:** `frontend/src/app/services/promo-code.service.ts`

```typescript
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { PromoCode, PromoCodeStats } from '../models/promo-code.model';

@Injectable({
  providedIn: 'root'
})
export class PromoCodeService {
  private apiUrl = `${environment.apiUrl}/api/promotions`;

  constructor(private http: HttpClient) {}

  // Get all promotions with pagination
  getAllPromotions(page: number = 0, size: number = 10): Observable<any> {
    return this.http.get(`${this.apiUrl}?page=${page}&size=${size}`);
  }

  // Get promotion by ID
  getPromotionById(id: number): Observable<PromoCode> {
    return this.http.get<PromoCode>(`${this.apiUrl}/${id}`);
  }

  // Create new promotion
  createPromotion(promo: PromoCode): Observable<PromoCode> {
    return this.http.post<PromoCode>(this.apiUrl, promo);
  }

  // Update promotion
  updatePromotion(id: number, promo: PromoCode): Observable<PromoCode> {
    return this.http.put<PromoCode>(`${this.apiUrl}/${id}`, promo);
  }

  // Delete promotion
  deletePromotion(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  // Get promotion statistics
  getPromotionStats(id: number): Observable<PromoCodeStats> {
    return this.http.get<PromoCodeStats>(`${this.apiUrl}/${id}/stats`);
  }

  // Get active promotions (public API)
  getActivePromotions(shopId?: number): Observable<any> {
    const url = shopId
      ? `${this.apiUrl}/active?shopId=${shopId}`
      : `${this.apiUrl}/active`;
    return this.http.get(url);
  }

  // Get enum values
  getEnums(): Observable<any> {
    return this.http.get(`${this.apiUrl}/enums`);
  }

  // Quick update (PATCH)
  quickUpdate(id: number, updates: Partial<PromoCode>): Observable<PromoCode> {
    return this.http.patch<PromoCode>(`${this.apiUrl}/${id}`, updates);
  }
}
```

---

### File 3: Angular List Component

**File:** `frontend/src/app/components/promo-code-list/promo-code-list.component.ts`

```typescript
import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { PromoCodeService } from '../../services/promo-code.service';
import { PromoCode, PromoStatus } from '../../models/promo-code.model';

@Component({
  selector: 'app-promo-code-list',
  templateUrl: './promo-code-list.component.html',
  styleUrls: ['./promo-code-list.component.scss']
})
export class PromoCodeListComponent implements OnInit {
  promos: PromoCode[] = [];
  loading = false;
  page = 0;
  size = 10;
  totalElements = 0;

  constructor(
    private promoService: PromoCodeService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadPromotions();
  }

  loadPromotions(): void {
    this.loading = true;
    this.promoService.getAllPromotions(this.page, this.size).subscribe({
      next: (response) => {
        this.promos = response.content;
        this.totalElements = response.totalElements;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading promotions:', error);
        this.loading = false;
      }
    });
  }

  createPromo(): void {
    this.router.navigate(['/admin/promos/new']);
  }

  editPromo(id: number): void {
    this.router.navigate(['/admin/promos/edit', id]);
  }

  viewStats(id: number): void {
    this.router.navigate(['/admin/promos/stats', id]);
  }

  toggleStatus(promo: PromoCode): void {
    const newStatus = promo.status === PromoStatus.ACTIVE
      ? PromoStatus.INACTIVE
      : PromoStatus.ACTIVE;

    this.promoService.quickUpdate(promo.id!, { status: newStatus }).subscribe({
      next: () => {
        promo.status = newStatus;
      },
      error: (error) => {
        console.error('Error updating status:', error);
      }
    });
  }

  deletePromo(id: number): void {
    if (confirm('Are you sure you want to delete this promo code?')) {
      this.promoService.deletePromotion(id).subscribe({
        next: () => {
          this.loadPromotions();
        },
        error: (error) => {
          console.error('Error deleting promotion:', error);
        }
      });
    }
  }

  getStatusColor(status: PromoStatus): string {
    switch (status) {
      case PromoStatus.ACTIVE: return 'green';
      case PromoStatus.INACTIVE: return 'gray';
      case PromoStatus.EXPIRED: return 'red';
      case PromoStatus.SUSPENDED: return 'orange';
      default: return 'gray';
    }
  }
}
```

---

### File 4: Angular List Template

**File:** `frontend/src/app/components/promo-code-list/promo-code-list.component.html`

```html
<div class="promo-list-container">
  <div class="header">
    <h2>Promo Codes</h2>
    <button mat-raised-button color="primary" (click)="createPromo()">
      <mat-icon>add</mat-icon>
      Create New Promo
    </button>
  </div>

  <div class="promo-cards" *ngIf="!loading">
    <mat-card *ngFor="let promo of promos" class="promo-card">
      <mat-card-header>
        <mat-card-title>
          <span class="promo-code">{{ promo.code }}</span>
          <mat-chip [style.background-color]="getStatusColor(promo.status)">
            {{ promo.status }}
          </mat-chip>
        </mat-card-title>
        <mat-card-subtitle>{{ promo.title }}</mat-card-subtitle>
      </mat-card-header>

      <mat-card-content>
        <div class="promo-details">
          <div class="detail-row">
            <span class="label">Type:</span>
            <span class="value">{{ promo.type }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Discount:</span>
            <span class="value">
              {{ promo.type === 'PERCENTAGE' ? promo.discountValue + '%' : '₹' + promo.discountValue }}
            </span>
          </div>
          <div class="detail-row">
            <span class="label">Min Order:</span>
            <span class="value">₹{{ promo.minimumOrderAmount || 0 }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Per Customer:</span>
            <span class="value">{{ promo.usageLimitPerCustomer || 'Unlimited' }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Used:</span>
            <span class="value">{{ promo.usedCount }} times</span>
          </div>
          <div class="detail-row">
            <span class="label">Valid Until:</span>
            <span class="value">{{ promo.endDate | date }}</span>
          </div>
        </div>
      </mat-card-content>

      <mat-card-actions>
        <button mat-button (click)="editPromo(promo.id!)">Edit</button>
        <button mat-button (click)="viewStats(promo.id!)">Stats</button>
        <button mat-button (click)="toggleStatus(promo)">
          {{ promo.status === 'ACTIVE' ? 'Deactivate' : 'Activate' }}
        </button>
        <button mat-button color="warn" (click)="deletePromo(promo.id!)">Delete</button>
      </mat-card-actions>
    </mat-card>
  </div>

  <div class="loading" *ngIf="loading">
    <mat-spinner></mat-spinner>
  </div>
</div>
```

---

## 🎯 Integration Checklist

### Mobile App:
- [ ] Add dependencies to pubspec.yaml
- [ ] Run `flutter pub get`
- [ ] Import promo widget in checkout screen
- [ ] Add promo state variables
- [ ] Add PromoCodeWidget to UI
- [ ] Update payment summary to show discount
- [ ] Include promo code in order placement API
- [ ] Test promo code validation
- [ ] Test device UUID generation

### Angular Admin:
- [ ] Create promo code model
- [ ] Create promo code service
- [ ] Create list component
- [ ] Create form component (create/edit)
- [ ] Create stats component
- [ ] Add routes for promo management
- [ ] Add menu item in sidebar
- [ ] Test CRUD operations

---

## 🚀 Next Steps

1. **Mobile:** Integrate the PromoCodeWidget into checkout_screen.dart
2. **Angular:** Create the components listed above
3. **Backend:** Run the V23 migration to create promotion_usage table
4. **Testing:** Create test promo codes and verify functionality

---

## 📝 Notes

- Device UUID persists in SharedPreferences
- Promo codes are case-insensitive
- All validation happens on backend
- Mobile app only displays results
- Angular admin has full CRUD capabilities

