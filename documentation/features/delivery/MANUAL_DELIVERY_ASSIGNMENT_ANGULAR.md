# 📋 Manual Delivery Partner Assignment - Angular Frontend

## Overview
When no delivery partners are available for auto-assignment, the admin will receive an email alert after 3 minutes. The admin can then manually assign a delivery partner using the Angular admin dashboard.

---

## 🔄 Complete Flow

### 1. Auto-Assignment Fails
```
Order Status: READY_FOR_PICKUP
↓
System tries auto-assignment
↓
NO PARTNERS AVAILABLE
↓
Retry every 1 minute
↓
After 3 minutes (3 attempts) → Email sent to admin
```

### 2. Admin Receives Email

**Subject**: ⚠️ URGENT: No Delivery Partners Available - Order #ORD1759815295

**Email Content**:
```
⚠️ URGENT ALERT: No Delivery Partners Available

The system has been trying to assign a delivery partner for 3 minutes
but no partners are available.

Order Details:
- Order ID: 15
- Order Number: ORD1759815295
- Shop: Thirunavukarasu Store
- Time: 2025-01-15 14:30:00
- Retry Attempts: 3

Current Status: READY_FOR_PICKUP (waiting for delivery partner assignment)

⚡ ACTION REQUIRED:
1. Check if delivery partners are online in the system
2. Manually assign a delivery partner to this order
3. Contact delivery partners to come online immediately
4. Use admin panel to check partner availability

🔗 Admin Dashboard: http://localhost:4200/orders
```

### 3. Admin Logs into Angular Dashboard

---

## 🖥️ Angular Admin Dashboard - Manual Assignment Screen

### Screen Location
**Route**: `/orders` or `/orders/unassigned`

### UI Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│  📋 Orders Management                              [Admin Dashboard] │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Tabs: [All Orders] [Pending] [Unassigned ⚠️  3] [Delivered]        │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ ⚠️  Unassigned Orders Requiring Immediate Attention             ││
│  │                                                                  ││
│  │ These orders are ready for pickup but have no delivery partner  ││
│  │ assigned. Please assign a partner manually.                     ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ 🚨 Order #ORD1759815295                      [READY_FOR_PICKUP] ││
│  │                                                                  ││
│  │ 🏪 Shop: Thirunavukarasu Store                                  ││
│  │ 👤 Customer: Test Customer (9876543210)                         ││
│  │ 📍 Address: 123 Main St, Chennai - 635601                       ││
│  │ 💰 Total: ₹318.00 (₹268 + ₹50 delivery)                        ││
│  │ ⏰ Waiting: 5 minutes (3 retry attempts)                         ││
│  │                                                                  ││
│  │ Items:                                                           ││
│  │  • 2x Basmati Rice - ₹268.00                                    ││
│  │                                                                  ││
│  │ ┌────────────────────────────────────────────────────────────┐ ││
│  │ │ 🚴 Assign Delivery Partner                                 │ ││
│  │ │                                                             │ ││
│  │ │ Select Partner: [Dropdown ▼]                               │ ││
│  │ │  ┌──────────────────────────────────────────────────────┐ │ ││
│  │ │  │ 🟢 Ravi Kumar (Available) - 5 orders today          │ │ ││
│  │ │  │ 🟢 Suresh M (Available) - 3 orders today            │ │ ││
│  │ │  │ 🔴 Arun P (Busy - On delivery)                      │ │ ││
│  │ │  │ ⚫ Vijay S (Offline)                                 │ │ ││
│  │ │  └──────────────────────────────────────────────────────┘ │ ││
│  │ │                                                             │ ││
│  │ │ [  ASSIGN PARTNER  ]                                        │ ││
│  │ └────────────────────────────────────────────────────────────┘ ││
│  │                                                                  ││
│  │ [View Details]  [Contact Customer]  [Contact Shop]              ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Backend API Endpoints

### 1. Get Available Delivery Partners

**Endpoint**: `GET /api/mobile/delivery-partner/admin/partners`

**Headers**:
```
Authorization: Bearer <admin_token>
```

**Response**:
```json
{
  "success": true,
  "partners": [
    {
      "partnerId": 5,
      "name": "Ravi Kumar",
      "email": "ravi@example.com",
      "phone": "9876543210",
      "isActive": true,
      "isOnline": true,
      "isAvailable": true,
      "rideStatus": "AVAILABLE",
      "lastActivity": "2025-01-15T14:25:00",
      "fcmToken": "Present"
    },
    {
      "partnerId": 6,
      "name": "Suresh M",
      "email": "suresh@example.com",
      "phone": "9876543211",
      "isActive": true,
      "isOnline": true,
      "isAvailable": true,
      "rideStatus": "AVAILABLE",
      "lastActivity": "2025-01-15T14:20:00",
      "fcmToken": "Present"
    }
  ],
  "statistics": {
    "total": 10,
    "active": 8,
    "online": 5,
    "available": 2,
    "offline": 5
  }
}
```

### 2. Get Unassigned Orders

**Endpoint**: `GET /api/orders?status=READY_FOR_PICKUP&assigned=false`

**Headers**:
```
Authorization: Bearer <admin_token>
```

**Response**:
```json
{
  "orders": [
    {
      "orderId": 15,
      "orderNumber": "ORD1759815295",
      "status": "READY_FOR_PICKUP",
      "deliveryType": "HOME_DELIVERY",
      "assignedToDeliveryPartner": false,
      "customer": {
        "name": "Test Customer",
        "phone": "9876543210"
      },
      "shop": {
        "name": "Thirunavukarasu Store",
        "address": "Shop Address"
      },
      "deliveryAddress": "123 Main St, Chennai - 635601",
      "totalAmount": 318.00,
      "createdAt": "2025-01-15T14:25:00"
    }
  ]
}
```

### 3. Manual Assignment

**Endpoint**: `POST /api/order-assignments/orders/{orderId}/manual-assign`

**Headers**:
```
Authorization: Bearer <admin_token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "deliveryPartnerId": 5
}
```

**Response**:
```json
{
  "assignmentId": 123,
  "orderId": 15,
  "orderNumber": "ORD1759815295",
  "deliveryPartner": {
    "id": 5,
    "name": "Ravi Kumar",
    "email": "ravi@example.com",
    "phone": "9876543210"
  },
  "status": "ASSIGNED",
  "deliveryFee": 50.00,
  "partnerCommission": 35.00,
  "assignedBy": "admin@example.com",
  "assignedAt": "2025-01-15T14:30:00"
}
```

---

## 💻 Angular Implementation

### 1. Service - `order.service.ts`

```typescript
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class OrderService {
  private apiUrl = 'http://localhost:8080/api';

  constructor(private http: HttpClient) {}

  // Get unassigned orders
  getUnassignedOrders(): Observable<any> {
    return this.http.get(`${this.apiUrl}/orders`, {
      params: {
        status: 'READY_FOR_PICKUP',
        assigned: 'false'
      }
    });
  }

  // Get available delivery partners
  getAvailablePartners(): Observable<any> {
    return this.http.get(`${this.apiUrl}/mobile/delivery-partner/admin/partners`);
  }

  // Manually assign order
  manuallyAssignOrder(orderId: number, partnerId: number): Observable<any> {
    return this.http.post(
      `${this.apiUrl}/order-assignments/orders/${orderId}/manual-assign`,
      { deliveryPartnerId: partnerId }
    );
  }
}
```

### 2. Component - `unassigned-orders.component.ts`

```typescript
import { Component, OnInit } from '@angular/core';
import { OrderService } from '../services/order.service';
import { MatSnackBar } from '@angular/material/snack-bar';

@Component({
  selector: 'app-unassigned-orders',
  templateUrl: './unassigned-orders.component.html',
  styleUrls: ['./unassigned-orders.component.css']
})
export class UnassignedOrdersComponent implements OnInit {
  unassignedOrders: any[] = [];
  availablePartners: any[] = [];
  selectedPartner: { [orderId: number]: number } = {};
  loading = false;

  constructor(
    private orderService: OrderService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadUnassignedOrders();
    this.loadAvailablePartners();

    // Auto-refresh every 30 seconds
    setInterval(() => {
      this.loadUnassignedOrders();
      this.loadAvailablePartners();
    }, 30000);
  }

  loadUnassignedOrders(): void {
    this.orderService.getUnassignedOrders().subscribe({
      next: (response) => {
        this.unassignedOrders = response.orders;
        console.log('Unassigned orders:', this.unassignedOrders);
      },
      error: (error) => {
        console.error('Error loading unassigned orders:', error);
      }
    });
  }

  loadAvailablePartners(): void {
    this.orderService.getAvailablePartners().subscribe({
      next: (response) => {
        // Filter only available partners
        this.availablePartners = response.partners.filter(
          (p: any) => p.isOnline && p.isAvailable
        );
        console.log('Available partners:', this.availablePartners);
      },
      error: (error) => {
        console.error('Error loading partners:', error);
      }
    });
  }

  assignPartner(order: any): void {
    const partnerId = this.selectedPartner[order.orderId];

    if (!partnerId) {
      this.snackBar.open('Please select a delivery partner', 'Close', {
        duration: 3000
      });
      return;
    }

    this.loading = true;

    this.orderService.manuallyAssignOrder(order.orderId, partnerId).subscribe({
      next: (response) => {
        this.snackBar.open(
          `✅ Order assigned to ${response.deliveryPartner.name}!`,
          'Close',
          { duration: 5000 }
        );

        // Remove from unassigned list
        this.unassignedOrders = this.unassignedOrders.filter(
          o => o.orderId !== order.orderId
        );

        this.loading = false;
      },
      error: (error) => {
        this.snackBar.open(
          `❌ Failed to assign order: ${error.error.message || error.message}`,
          'Close',
          { duration: 5000 }
        );
        this.loading = false;
      }
    });
  }

  getPartnerStatusIcon(partner: any): string {
    if (partner.isOnline && partner.isAvailable) return '🟢';
    if (partner.isOnline && !partner.isAvailable) return '🟠';
    return '⚫';
  }

  getWaitingTime(order: any): string {
    const createdAt = new Date(order.createdAt);
    const now = new Date();
    const minutes = Math.floor((now.getTime() - createdAt.getTime()) / 60000);
    return `${minutes} minute${minutes !== 1 ? 's' : ''}`;
  }
}
```

### 3. Template - `unassigned-orders.component.html`

```html
<div class="unassigned-container">
  <mat-card class="alert-card" *ngIf="unassignedOrders.length > 0">
    <mat-card-content>
      <mat-icon color="warn">warning</mat-icon>
      <strong>⚠️ {{ unassignedOrders.length }} Unassigned Orders</strong>
      <p>These orders require immediate delivery partner assignment</p>
    </mat-card-content>
  </mat-card>

  <mat-card *ngFor="let order of unassignedOrders" class="order-card">
    <mat-card-header>
      <mat-card-title>
        🚨 Order #{{ order.orderNumber }}
        <mat-chip color="warn">{{ order.status }}</mat-chip>
      </mat-card-title>
      <mat-card-subtitle>
        Waiting: {{ getWaitingTime(order) }}
      </mat-card-subtitle>
    </mat-card-header>

    <mat-card-content>
      <div class="order-details">
        <div class="detail-row">
          <mat-icon>store</mat-icon>
          <span><strong>Shop:</strong> {{ order.shop.name }}</span>
        </div>

        <div class="detail-row">
          <mat-icon>person</mat-icon>
          <span>
            <strong>Customer:</strong> {{ order.customer.name }}
            ({{ order.customer.phone }})
          </span>
        </div>

        <div class="detail-row">
          <mat-icon>location_on</mat-icon>
          <span><strong>Address:</strong> {{ order.deliveryAddress }}</span>
        </div>

        <div class="detail-row">
          <mat-icon>payments</mat-icon>
          <span><strong>Total:</strong> ₹{{ order.totalAmount }}</span>
        </div>
      </div>

      <mat-divider></mat-divider>

      <div class="assignment-section">
        <h4>🚴 Assign Delivery Partner</h4>

        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Select Delivery Partner</mat-label>
          <mat-select [(ngModel)]="selectedPartner[order.orderId]">
            <mat-option
              *ngFor="let partner of availablePartners"
              [value]="partner.partnerId"
            >
              {{ getPartnerStatusIcon(partner) }} {{ partner.name }}
              ({{ partner.phone }})
            </mat-option>
          </mat-select>
          <mat-hint *ngIf="availablePartners.length === 0">
            No partners available - please contact delivery partners
          </mat-hint>
        </mat-form-field>

        <button
          mat-raised-button
          color="primary"
          (click)="assignPartner(order)"
          [disabled]="loading || !selectedPartner[order.orderId]"
        >
          <mat-icon>person_add</mat-icon>
          ASSIGN PARTNER
        </button>
      </div>
    </mat-card-content>
  </mat-card>

  <div *ngIf="unassignedOrders.length === 0" class="empty-state">
    <mat-icon>check_circle</mat-icon>
    <h3>✅ All orders are assigned!</h3>
    <p>No unassigned orders at the moment</p>
  </div>
</div>
```

### 4. Styles - `unassigned-orders.component.css`

```css
.unassigned-container {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

.alert-card {
  background-color: #fff3cd;
  border-left: 4px solid #ffc107;
  margin-bottom: 20px;
}

.alert-card mat-icon {
  vertical-align: middle;
  margin-right: 10px;
  color: #ffc107;
}

.order-card {
  margin-bottom: 20px;
  border-left: 4px solid #f44336;
}

.order-details {
  margin: 15px 0;
}

.detail-row {
  display: flex;
  align-items: center;
  margin-bottom: 10px;
}

.detail-row mat-icon {
  margin-right: 10px;
  color: #666;
}

.assignment-section {
  margin-top: 20px;
  padding: 15px;
  background-color: #f5f5f5;
  border-radius: 8px;
}

.assignment-section h4 {
  margin-top: 0;
}

.full-width {
  width: 100%;
}

button {
  width: 100%;
  height: 48px;
  font-size: 16px;
  font-weight: 500;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #4caf50;
}

.empty-state mat-icon {
  font-size: 80px;
  width: 80px;
  height: 80px;
}
```

---

## 📧 Email Configuration

Add to `application.properties`:

```properties
# Admin email for alerts
app.admin.email=thirunacse75@gmail.com

# Assignment retry configuration
app.assignment.retry.max-attempts=3
app.assignment.retry.max-age-minutes=10

# Email configuration (if not already present)
spring.mail.host=smtp.gmail.com
spring.mail.port=587
spring.mail.username=your-email@gmail.com
spring.mail.password=your-app-password
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
```

---

## 🧪 Testing the Complete Flow

### 1. Create Test Order
```bash
# Create order with HOME_DELIVERY type
curl -X POST http://localhost:8080/api/customer/orders \
  -H "Authorization: Bearer <customer_token>" \
  -d '{"deliveryType":"HOME_DELIVERY",...}'
```

### 2. Make Sure No Partners Available
```bash
# Check partners
curl -X GET http://localhost:8080/api/mobile/delivery-partner/admin/partners \
  -H "Authorization: Bearer <admin_token>"

# If partners exist but not available, set them offline
curl -X POST "http://localhost:8080/api/mobile/delivery-partner/admin/partners/5/set-available?available=false&online=false" \
  -H "Authorization: Bearer <admin_token>"
```

### 3. Shop Owner Marks Order Ready
```bash
# This triggers auto-assignment (which will fail)
curl -X POST http://localhost:8080/api/orders/15/ready \
  -H "Authorization: Bearer <shop_token>"
```

### 4. Wait 3 Minutes
- System retries every 1 minute
- After 3 attempts, email sent to admin

### 5. Admin Opens Angular Dashboard
- Navigate to `/orders/unassigned`
- See the unassigned order
- Select an available partner
- Click "ASSIGN PARTNER"

### 6. Verify Assignment
```bash
curl -X GET http://localhost:8080/api/orders/15 \
  -H "Authorization: Bearer <admin_token>"

# Should show:
# "assignedToDeliveryPartner": true
# "deliveryPartnerId": 5
```

---

## 🎉 Success Indicators

✅ Order assigned successfully
✅ Email sent to delivery partner (FCM notification)
✅ Order status updated
✅ Partner marked as busy
✅ Admin receives confirmation

---

## 📞 Support

If issues occur:
1. Check backend logs for errors
2. Verify email configuration
3. Confirm delivery partners exist in database
4. Test API endpoints directly with curl

**Contact**: thirunacse75@gmail.com
