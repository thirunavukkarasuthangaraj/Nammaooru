import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { FormControl } from '@angular/forms';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';

interface Order {
  id: string;
  customerName: string;
  customerPhone: string;
  customerAddress: string;
  items: OrderItem[];
  totalAmount: number;
  orderDate: Date;
  status: 'pending' | 'confirmed' | 'preparing' | 'ready' | 'dispatched' | 'delivered' | 'cancelled';
  paymentStatus: 'pending' | 'paid' | 'failed' | 'refunded';
  deliveryType: 'pickup' | 'delivery';
  estimatedTime: string;
  notes: string;
}

interface OrderItem {
  productName: string;
  quantity: number;
  unit: string;
  price: number;
  total: number;
}

@Component({
  selector: 'app-orders-management',
  template: `
    <div class="orders-container">
      <!-- Header -->
      <div class="page-header">
        <div class="header-content">
          <h1 class="page-title">Orders Management</h1>
          <p class="page-subtitle">Track and manage your customer orders</p>
        </div>
        <div class="header-actions">
          <button mat-raised-button color="primary" (click)="createOrder()">
            <mat-icon>add</mat-icon>
            New Order
          </button>
          <button mat-stroked-button (click)="exportOrders()">
            <mat-icon>download</mat-icon>
            Export
          </button>
        </div>
      </div>

      <!-- Order Stats -->
      <div class="stats-cards">
        <mat-card class="stat-card pending">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon">
                <mat-icon>schedule</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getPendingOrders() }}</h3>
                <p>Pending Orders</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="stat-card processing">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon">
                <mat-icon>hourglass_empty</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getProcessingOrders() }}</h3>
                <p>Processing</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="stat-card ready">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon">
                <mat-icon>check_circle</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getReadyOrders() }}</h3>
                <p>Ready for Delivery</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="stat-card revenue">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon">
                <mat-icon>currency_rupee</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getTodayRevenue() | currency:'INR':'symbol':'1.0-0' }}</h3>
                <p>Today's Revenue</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Filters -->
      <mat-card class="filters-card">
        <mat-card-content>
          <div class="filters-section">
            <div class="search-filters">
              <mat-form-field appearance="outline" class="search-field">
                <mat-label>Search orders</mat-label>
                <input matInput [formControl]="searchControl" placeholder="Search by ID, customer name...">
                <mat-icon matPrefix>search</mat-icon>
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>Status</mat-label>
                <mat-select [(value)]="selectedStatus" (selectionChange)="applyFilters()">
                  <mat-option value="">All Status</mat-option>
                  <mat-option value="pending">Pending</mat-option>
                  <mat-option value="confirmed">Confirmed</mat-option>
                  <mat-option value="preparing">Preparing</mat-option>
                  <mat-option value="ready">Ready</mat-option>
                  <mat-option value="dispatched">Dispatched</mat-option>
                  <mat-option value="delivered">Delivered</mat-option>
                  <mat-option value="cancelled">Cancelled</mat-option>
                </mat-select>
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>Payment Status</mat-label>
                <mat-select [(value)]="selectedPaymentStatus" (selectionChange)="applyFilters()">
                  <mat-option value="">All Payments</mat-option>
                  <mat-option value="pending">Pending</mat-option>
                  <mat-option value="paid">Paid</mat-option>
                  <mat-option value="failed">Failed</mat-option>
                  <mat-option value="refunded">Refunded</mat-option>
                </mat-select>
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>Delivery Type</mat-label>
                <mat-select [(value)]="selectedDeliveryType" (selectionChange)="applyFilters()">
                  <mat-option value="">All Types</mat-option>
                  <mat-option value="pickup">Pickup</mat-option>
                  <mat-option value="delivery">Delivery</mat-option>
                </mat-select>
              </mat-form-field>
            </div>

            <div class="date-filters">
              <mat-form-field appearance="outline">
                <mat-label>From Date</mat-label>
                <input matInput [matDatepicker]="fromPicker" [(ngModel)]="fromDate" (dateChange)="applyFilters()">
                <mat-datepicker-toggle matSuffix [for]="fromPicker"></mat-datepicker-toggle>
                <mat-datepicker #fromPicker></mat-datepicker>
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>To Date</mat-label>
                <input matInput [matDatepicker]="toPicker" [(ngModel)]="toDate" (dateChange)="applyFilters()">
                <mat-datepicker-toggle matSuffix [for]="toPicker"></mat-datepicker-toggle>
                <mat-datepicker #toPicker></mat-datepicker>
              </mat-form-field>
            </div>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Orders Table -->
      <mat-card class="table-card">
        <mat-card-content>
          <div class="table-container">
            <table mat-table [dataSource]="dataSource" matSort class="orders-table">
              
              <!-- Order ID Column -->
              <ng-container matColumnDef="orderId">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Order ID</th>
                <td mat-cell *matCellDef="let order">
                  <div class="order-id-cell">
                    <span class="order-id">{{ order.id }}</span>
                    <span class="order-date">{{ order.orderDate | date:'short' }}</span>
                  </div>
                </td>
              </ng-container>

              <!-- Customer Column -->
              <ng-container matColumnDef="customer">
                <th mat-header-cell *matHeaderCellDef>Customer</th>
                <td mat-cell *matCellDef="let order">
                  <div class="customer-cell">
                    <h4>{{ order.customerName }}</h4>
                    <p>{{ order.customerPhone }}</p>
                    <p class="address">{{ order.customerAddress }}</p>
                  </div>
                </td>
              </ng-container>

              <!-- Items Column -->
              <ng-container matColumnDef="items">
                <th mat-header-cell *matHeaderCellDef>Items</th>
                <td mat-cell *matCellDef="let order">
                  <div class="items-cell">
                    <span class="items-count">{{ order.items.length }} items</span>
                    <div class="items-preview">
                      <span *ngFor="let item of order.items.slice(0, 2); let last = last">
                        {{ item.productName }} ({{ item.quantity }}){{ !last ? ',' : '' }}
                      </span>
                      <span *ngIf="order.items.length > 2" class="more-items">
                        +{{ order.items.length - 2 }} more
                      </span>
                    </div>
                  </div>
                </td>
              </ng-container>

              <!-- Amount Column -->
              <ng-container matColumnDef="amount">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Amount</th>
                <td mat-cell *matCellDef="let order">
                  <div class="amount-cell">
                    <span class="amount">₹{{ order.totalAmount }}</span>
                    <span class="payment-status" [class]="'payment-' + order.paymentStatus">
                      {{ getPaymentStatusLabel(order.paymentStatus) }}
                    </span>
                  </div>
                </td>
              </ng-container>

              <!-- Status Column -->
              <ng-container matColumnDef="status">
                <th mat-header-cell *matHeaderCellDef>Status</th>
                <td mat-cell *matCellDef="let order">
                  <div class="status-cell">
                    <span class="status-badge" [class]="'status-' + order.status">
                      <mat-icon>{{ getStatusIcon(order.status) }}</mat-icon>
                      {{ getStatusLabel(order.status) }}
                    </span>
                    <span class="delivery-type">{{ order.deliveryType | titlecase }}</span>
                  </div>
                </td>
              </ng-container>

              <!-- Estimated Time Column -->
              <ng-container matColumnDef="estimatedTime">
                <th mat-header-cell *matHeaderCellDef>Est. Time</th>
                <td mat-cell *matCellDef="let order">
                  <span class="estimated-time">{{ order.estimatedTime }}</span>
                </td>
              </ng-container>

              <!-- Actions Column -->
              <ng-container matColumnDef="actions">
                <th mat-header-cell *matHeaderCellDef>Actions</th>
                <td mat-cell *matCellDef="let order">
                  <div class="action-buttons">
                    <button mat-icon-button color="primary" (click)="viewOrder(order)" matTooltip="View Details">
                      <mat-icon>visibility</mat-icon>
                    </button>
                    <button mat-icon-button color="accent" (click)="updateStatus(order)" matTooltip="Update Status">
                      <mat-icon>edit</mat-icon>
                    </button>
                    <button mat-icon-button [matMenuTriggerFor]="actionMenu" [matMenuTriggerData]="{order: order}">
                      <mat-icon>more_vert</mat-icon>
                    </button>
                  </div>
                </td>
              </ng-container>

              <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
              <tr mat-row *matRowDef="let row; columns: displayedColumns;" 
                  [class.urgent-order]="isUrgentOrder(row)"></tr>
            </table>

            <mat-paginator [pageSizeOptions]="[10, 25, 50]" showFirstLastButtons></mat-paginator>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Quick Actions Panel -->
      <div class="quick-actions-panel" *ngIf="selectedOrders.length > 0">
        <div class="panel-content">
          <span class="selection-info">{{ selectedOrders.length }} orders selected</span>
          <div class="bulk-actions">
            <button mat-button (click)="bulkUpdateStatus()">
              <mat-icon>update</mat-icon>
              Update Status
            </button>
            <button mat-button (click)="bulkPrint()">
              <mat-icon>print</mat-icon>
              Print Bills
            </button>
            <button mat-button (click)="clearSelection()">
              <mat-icon>clear</mat-icon>
              Clear
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Action Menu -->
    <mat-menu #actionMenu="matMenu">
      <ng-template matMenuContent let-order="order">
        <button mat-menu-item (click)="viewOrder(order)">
          <mat-icon>visibility</mat-icon>
          <span>View Details</span>
        </button>
        <button mat-menu-item (click)="updateStatus(order)">
          <mat-icon>edit</mat-icon>
          <span>Update Status</span>
        </button>
        <button mat-menu-item (click)="printBill(order)">
          <mat-icon>print</mat-icon>
          <span>Print Bill</span>
        </button>
        <button mat-menu-item (click)="contactCustomer(order)">
          <mat-icon>phone</mat-icon>
          <span>Contact Customer</span>
        </button>
        <mat-divider></mat-divider>
        <button mat-menu-item (click)="duplicateOrder(order)">
          <mat-icon>content_copy</mat-icon>
          <span>Duplicate Order</span>
        </button>
        <button mat-menu-item (click)="cancelOrder(order)" class="warn-menu-item" 
                *ngIf="order.status !== 'delivered' && order.status !== 'cancelled'">
          <mat-icon>cancel</mat-icon>
          <span>Cancel Order</span>
        </button>
      </ng-template>
    </mat-menu>
  `,
  styles: [`
    .orders-container {
      padding: 24px;
      background-color: #f5f5f5;
      min-height: calc(100vh - 64px);
    }

    .page-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }

    .page-title {
      font-size: 2rem;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: #1f2937;
    }

    .page-subtitle {
      font-size: 1rem;
      color: #6b7280;
      margin: 0;
    }

    .header-actions {
      display: flex;
      gap: 12px;
    }

    .stats-cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .stat-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      overflow: hidden;
    }

    .stat-card.pending { border-left: 4px solid #f59e0b; }
    .stat-card.processing { border-left: 4px solid #2563eb; }
    .stat-card.ready { border-left: 4px solid #10b981; }
    .stat-card.revenue { border-left: 4px solid #8b5cf6; }

    .stat-content {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .stat-icon {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
    }

    .stat-card.pending .stat-icon { background: #f59e0b; }
    .stat-card.processing .stat-icon { background: #2563eb; }
    .stat-card.ready .stat-icon { background: #10b981; }
    .stat-card.revenue .stat-icon { background: #8b5cf6; }

    .stat-details h3 {
      font-size: 1.5rem;
      font-weight: 600;
      margin: 0;
      color: #1f2937;
    }

    .stat-details p {
      font-size: 0.9rem;
      color: #6b7280;
      margin: 0;
    }

    .filters-card {
      margin-bottom: 16px;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .filters-section {
      display: flex;
      justify-content: space-between;
      gap: 16px;
    }

    .search-filters {
      display: flex;
      gap: 16px;
      align-items: center;
      flex: 1;
    }

    .search-field {
      min-width: 250px;
    }

    .date-filters {
      display: flex;
      gap: 16px;
    }

    .table-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      margin-bottom: 16px;
    }

    .table-container {
      overflow-x: auto;
    }

    .orders-table {
      width: 100%;
      min-width: 1200px;
    }

    .urgent-order {
      background-color: #fef3c7 !important;
    }

    .order-id-cell {
      display: flex;
      flex-direction: column;
    }

    .order-id {
      font-weight: 600;
      color: #1f2937;
      font-size: 0.9rem;
    }

    .order-date {
      font-size: 0.8rem;
      color: #6b7280;
    }

    .customer-cell h4 {
      margin: 0 0 2px 0;
      font-size: 0.9rem;
      font-weight: 600;
      color: #1f2937;
    }

    .customer-cell p {
      margin: 0 0 2px 0;
      font-size: 0.8rem;
      color: #6b7280;
    }

    .customer-cell .address {
      font-size: 0.7rem;
      color: #9ca3af;
      max-width: 150px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .items-cell {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .items-count {
      font-weight: 600;
      color: #1f2937;
      font-size: 0.8rem;
    }

    .items-preview {
      font-size: 0.7rem;
      color: #6b7280;
      max-width: 200px;
    }

    .more-items {
      color: #2563eb;
      font-weight: 500;
    }

    .amount-cell {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .amount {
      font-weight: 600;
      color: #1f2937;
      font-size: 0.9rem;
    }

    .payment-status {
      font-size: 0.7rem;
      padding: 2px 6px;
      border-radius: 10px;
      font-weight: 500;
      text-align: center;
    }

    .payment-status.payment-paid {
      background: #dcfce7;
      color: #16a34a;
    }

    .payment-status.payment-pending {
      background: #fef3c7;
      color: #92400e;
    }

    .payment-status.payment-failed {
      background: #fef2f2;
      color: #dc2626;
    }

    .payment-status.payment-refunded {
      background: #f3f4f6;
      color: #6b7280;
    }

    .status-cell {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .status-badge {
      display: flex;
      align-items: center;
      gap: 4px;
      padding: 4px 8px;
      border-radius: 16px;
      font-size: 0.8rem;
      font-weight: 500;
      width: fit-content;
    }

    .status-badge.status-pending {
      background: #fef3c7;
      color: #92400e;
    }

    .status-badge.status-confirmed {
      background: #e0f2fe;
      color: #0277bd;
    }

    .status-badge.status-preparing {
      background: #ede9fe;
      color: #7c3aed;
    }

    .status-badge.status-ready {
      background: #dcfce7;
      color: #16a34a;
    }

    .status-badge.status-dispatched {
      background: #dbeafe;
      color: #2563eb;
    }

    .status-badge.status-delivered {
      background: #d1fae5;
      color: #065f46;
    }

    .status-badge.status-cancelled {
      background: #fef2f2;
      color: #dc2626;
    }

    .delivery-type {
      font-size: 0.7rem;
      color: #6b7280;
    }

    .estimated-time {
      font-size: 0.8rem;
      color: #6b7280;
      font-weight: 500;
    }

    .action-buttons {
      display: flex;
      gap: 4px;
    }

    .quick-actions-panel {
      position: fixed;
      bottom: 24px;
      left: 50%;
      transform: translateX(-50%);
      background: white;
      padding: 16px 24px;
      border-radius: 12px;
      box-shadow: 0 8px 24px rgba(0,0,0,0.2);
      z-index: 1000;
    }

    .panel-content {
      display: flex;
      align-items: center;
      gap: 24px;
    }

    .selection-info {
      font-weight: 500;
      color: #1f2937;
    }

    .bulk-actions {
      display: flex;
      gap: 8px;
    }

    .warn-menu-item {
      color: #dc2626 !important;
    }

    /* Mobile Responsive */
    @media (max-width: 768px) {
      .orders-container {
        padding: 16px;
      }

      .page-header {
        flex-direction: column;
        gap: 16px;
        text-align: center;
      }

      .stats-cards {
        grid-template-columns: 1fr 1fr;
      }

      .filters-section {
        flex-direction: column;
      }

      .search-filters {
        flex-direction: column;
        gap: 12px;
      }

      .search-field {
        min-width: auto;
        width: 100%;
      }

      .date-filters {
        flex-direction: column;
        gap: 12px;
      }

      .quick-actions-panel {
        left: 16px;
        right: 16px;
        transform: none;
      }

      .panel-content {
        flex-direction: column;
        gap: 12px;
        text-align: center;
      }
    }
  `]
})
export class OrdersManagementComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = ['orderId', 'customer', 'items', 'amount', 'status', 'estimatedTime', 'actions'];
  dataSource = new MatTableDataSource<Order>();
  searchControl = new FormControl();
  
  selectedStatus = '';
  selectedPaymentStatus = '';
  selectedDeliveryType = '';
  fromDate: Date | null = null;
  toDate: Date | null = null;
  selectedOrders: Order[] = [];

  // Mock data
  orders: Order[] = [
    {
      id: 'ORD-001',
      customerName: 'Rajesh Kumar',
      customerPhone: '+91 9876543210',
      customerAddress: '123 Main Street, Bangalore',
      items: [
        { productName: 'Rice', quantity: 2, unit: 'kg', price: 120, total: 240 },
        { productName: 'Dal', quantity: 1, unit: 'kg', price: 150, total: 150 }
      ],
      totalAmount: 390,
      orderDate: new Date(),
      status: 'pending',
      paymentStatus: 'pending',
      deliveryType: 'delivery',
      estimatedTime: '30 mins',
      notes: 'Please deliver to front door'
    },
    {
      id: 'ORD-002',
      customerName: 'Priya Sharma',
      customerPhone: '+91 9876543211',
      customerAddress: '456 Park Avenue, Bangalore',
      items: [
        { productName: 'Bread', quantity: 2, unit: 'piece', price: 35, total: 70 },
        { productName: 'Milk', quantity: 1, unit: 'liter', price: 60, total: 60 },
        { productName: 'Eggs', quantity: 12, unit: 'piece', price: 5, total: 60 }
      ],
      totalAmount: 190,
      orderDate: new Date(Date.now() - 2 * 60 * 60 * 1000),
      status: 'preparing',
      paymentStatus: 'paid',
      deliveryType: 'pickup',
      estimatedTime: '15 mins',
      notes: ''
    },
    {
      id: 'ORD-003',
      customerName: 'Amit Singh',
      customerPhone: '+91 9876543212',
      customerAddress: '789 Gandhi Road, Bangalore',
      items: [
        { productName: 'Vegetables', quantity: 2, unit: 'kg', price: 80, total: 160 },
        { productName: 'Fruits', quantity: 1, unit: 'kg', price: 120, total: 120 }
      ],
      totalAmount: 280,
      orderDate: new Date(Date.now() - 4 * 60 * 60 * 1000),
      status: 'ready',
      paymentStatus: 'paid',
      deliveryType: 'delivery',
      estimatedTime: 'Ready',
      notes: 'Customer prefers organic produce'
    }
  ];

  constructor(
    private dialog: MatDialog,
    private snackBar: MatSnackBar
  ) {
    this.dataSource.data = this.orders;
  }

  ngOnInit(): void {
    this.setupFilters();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  private setupFilters(): void {
    this.searchControl.valueChanges
      .pipe(
        debounceTime(300),
        distinctUntilChanged()
      )
      .subscribe(() => {
        this.applyFilters();
      });
  }

  applyFilters(): void {
    this.dataSource.filterPredicate = (data: Order, filter: string) => {
      const searchTerm = this.searchControl.value?.toLowerCase() || '';
      const matchesSearch = data.id.toLowerCase().includes(searchTerm) || 
                           data.customerName.toLowerCase().includes(searchTerm) ||
                           data.customerPhone.includes(searchTerm);
      
      const matchesStatus = !this.selectedStatus || data.status === this.selectedStatus;
      const matchesPayment = !this.selectedPaymentStatus || data.paymentStatus === this.selectedPaymentStatus;
      const matchesDelivery = !this.selectedDeliveryType || data.deliveryType === this.selectedDeliveryType;
      
      let matchesDate = true;
      if (this.fromDate) {
        matchesDate = matchesDate && data.orderDate >= this.fromDate;
      }
      if (this.toDate) {
        const toDateEnd = new Date(this.toDate);
        toDateEnd.setHours(23, 59, 59, 999);
        matchesDate = matchesDate && data.orderDate <= toDateEnd;
      }
      
      return matchesSearch && matchesStatus && matchesPayment && matchesDelivery && matchesDate;
    };
    
    this.dataSource.filter = Math.random().toString();
  }

  getPendingOrders(): number {
    return this.orders.filter(order => order.status === 'pending').length;
  }

  getProcessingOrders(): number {
    return this.orders.filter(order => 
      order.status === 'confirmed' || order.status === 'preparing'
    ).length;
  }

  getReadyOrders(): number {
    return this.orders.filter(order => 
      order.status === 'ready' || order.status === 'dispatched'
    ).length;
  }

  getTodayRevenue(): number {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    return this.orders
      .filter(order => {
        const orderDate = new Date(order.orderDate);
        orderDate.setHours(0, 0, 0, 0);
        return orderDate.getTime() === today.getTime() && 
               (order.status === 'delivered' || order.paymentStatus === 'paid');
      })
      .reduce((total, order) => total + order.totalAmount, 0);
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'pending': return 'schedule';
      case 'confirmed': return 'check_circle_outline';
      case 'preparing': return 'hourglass_empty';
      case 'ready': return 'check_circle';
      case 'dispatched': return 'local_shipping';
      case 'delivered': return 'done_all';
      case 'cancelled': return 'cancel';
      default: return 'help';
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'preparing': return 'Preparing';
      case 'ready': return 'Ready';
      case 'dispatched': return 'Dispatched';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  getPaymentStatusLabel(status: string): string {
    switch (status) {
      case 'pending': return 'Pending';
      case 'paid': return 'Paid';
      case 'failed': return 'Failed';
      case 'refunded': return 'Refunded';
      default: return status;
    }
  }

  isUrgentOrder(order: Order): boolean {
    const orderTime = new Date(order.orderDate);
    const now = new Date();
    const diffMinutes = (now.getTime() - orderTime.getTime()) / (1000 * 60);
    
    return order.status === 'pending' && diffMinutes > 30;
  }

  createOrder(): void {
    console.log('Create new order');
    // Navigate to order creation page
  }

  viewOrder(order: Order): void {
    console.log('View order:', order);
    // Open order details dialog
  }

  updateStatus(order: Order): void {
    console.log('Update status for:', order);
    // Open status update dialog
  }

  printBill(order: Order): void {
    console.log('Print bill for:', order);
    // Generate and print bill
  }

  contactCustomer(order: Order): void {
    console.log('Contact customer:', order.customerPhone);
    // Open contact options
  }

  duplicateOrder(order: Order): void {
    console.log('Duplicate order:', order);
    // Create new order with same items
  }

  cancelOrder(order: Order): void {
    if (confirm('Are you sure you want to cancel this order?')) {
      order.status = 'cancelled';
      this.dataSource.data = [...this.orders];
      this.snackBar.open('Order cancelled successfully', 'Close', { duration: 3000 });
    }
  }

  exportOrders(): void {
    console.log('Export orders');
    // Export orders to Excel/CSV
  }

  bulkUpdateStatus(): void {
    console.log('Bulk update status for:', this.selectedOrders);
    // Open bulk status update dialog
  }

  bulkPrint(): void {
    console.log('Bulk print bills for:', this.selectedOrders);
    // Print bills for selected orders
  }

  clearSelection(): void {
    this.selectedOrders = [];
  }
}