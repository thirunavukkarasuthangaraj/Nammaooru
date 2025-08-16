import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatSnackBar } from '@angular/material/snack-bar';
import { CustomerService } from '@core/services/customer.service';
import { AuthService } from '@core/services/auth.service';
import { finalize } from 'rxjs/operators';

interface ShopCustomer {
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  totalOrders: number;
  totalSpent: number;
  lastOrderDate: Date | null;
  status: 'active' | 'inactive';
  loyaltyPoints: number;
  averageOrderValue: number;
  joinDate: Date;
}

@Component({
  selector: 'app-customer-management',
  template: `
    <div class="customer-management-container">
      <!-- Header -->
      <div class="page-header">
        <div class="header-content">
          <h1 class="page-title">Customer Management</h1>
          <p class="page-subtitle">View and manage your shop's customers</p>
        </div>
        <div class="header-actions">
          <button mat-stroked-button (click)="exportCustomers()">
            <mat-icon>download</mat-icon>
            Export Data
          </button>
        </div>
      </div>

      <!-- Stats Cards -->
      <div class="stats-cards">
        <mat-card class="stat-card">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon total">
                <mat-icon>people</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getTotalCustomers() }}</h3>
                <p>Total Customers</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="stat-card">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon active">
                <mat-icon>person_check</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getActiveCustomers() }}</h3>
                <p>Active Customers</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="stat-card">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon revenue">
                <mat-icon>monetization_on</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getAverageOrderValue() | currency:'INR':'symbol':'1.0-0' }}</h3>
                <p>Avg Order Value</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="stat-card">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon loyal">
                <mat-icon>loyalty</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getLoyalCustomers() }}</h3>
                <p>Loyal Customers</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Loading State -->
      <div *ngIf="loading" class="loading-container">
        <mat-spinner></mat-spinner>
        <p>Loading customer data...</p>
      </div>

      <!-- Customers Table -->
      <mat-card class="customers-table-card" *ngIf="!loading">
        <mat-card-header>
          <mat-card-title>Customer List</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="table-container">
            <table mat-table [dataSource]="dataSource" matSort class="customers-table">
              <!-- Name Column -->
              <ng-container matColumnDef="name">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Customer Name</th>
                <td mat-cell *matCellDef="let customer">
                  <div class="customer-info">
                    <span class="customer-name">{{ customer.firstName }} {{ customer.lastName }}</span>
                    <span class="customer-email">{{ customer.email }}</span>
                  </div>
                </td>
              </ng-container>

              <!-- Phone Column -->
              <ng-container matColumnDef="phone">
                <th mat-header-cell *matHeaderCellDef>Phone</th>
                <td mat-cell *matCellDef="let customer">{{ customer.phoneNumber }}</td>
              </ng-container>

              <!-- Orders Column -->
              <ng-container matColumnDef="orders">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Total Orders</th>
                <td mat-cell *matCellDef="let customer">{{ customer.totalOrders }}</td>
              </ng-container>

              <!-- Spent Column -->
              <ng-container matColumnDef="spent">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Total Spent</th>
                <td mat-cell *matCellDef="let customer">{{ customer.totalSpent | currency:'INR':'symbol':'1.0-0' }}</td>
              </ng-container>

              <!-- Average Order Value Column -->
              <ng-container matColumnDef="avgOrder">
                <th mat-header-cell *matHeaderCellDef>Avg Order</th>
                <td mat-cell *matCellDef="let customer">{{ customer.averageOrderValue | currency:'INR':'symbol':'1.0-0' }}</td>
              </ng-container>

              <!-- Last Order Column -->
              <ng-container matColumnDef="lastOrder">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Last Order</th>
                <td mat-cell *matCellDef="let customer">
                  <span *ngIf="customer.lastOrderDate">{{ customer.lastOrderDate | date:'shortDate' }}</span>
                  <span *ngIf="!customer.lastOrderDate" class="no-orders">No orders</span>
                </td>
              </ng-container>

              <!-- Status Column -->
              <ng-container matColumnDef="status">
                <th mat-header-cell *matHeaderCellDef>Status</th>
                <td mat-cell *matCellDef="let customer">
                  <span class="status-badge" [class]="'status-' + customer.status">
                    {{ customer.status | titlecase }}
                  </span>
                </td>
              </ng-container>

              <!-- Actions Column -->
              <ng-container matColumnDef="actions">
                <th mat-header-cell *matHeaderCellDef>Actions</th>
                <td mat-cell *matCellDef="let customer">
                  <button mat-icon-button [matMenuTriggerFor]="actionMenu">
                    <mat-icon>more_vert</mat-icon>
                  </button>
                  <mat-menu #actionMenu="matMenu">
                    <button mat-menu-item (click)="viewCustomerDetails(customer)">
                      <mat-icon>visibility</mat-icon>
                      View Details
                    </button>
                    <button mat-menu-item (click)="viewCustomerOrders(customer)">
                      <mat-icon>receipt_long</mat-icon>
                      View Orders
                    </button>
                  </mat-menu>
                </td>
              </ng-container>

              <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
              <tr mat-row *matRowDef="let row; columns: displayedColumns;"></tr>
            </table>

            <mat-paginator #paginator 
                          [pageSizeOptions]="[10, 25, 50]" 
                          [pageSize]="10"
                          showFirstLastButtons>
            </mat-paginator>
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .customer-management-container {
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
      color: #6b7280;
      margin: 0;
    }

    .header-actions {
      display: flex;
      gap: 12px;
    }

    .stats-cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .stat-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

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

    .stat-icon.total { background: #3b82f6; }
    .stat-icon.active { background: #10b981; }
    .stat-icon.revenue { background: #f59e0b; }
    .stat-icon.loyal { background: #8b5cf6; }

    .stat-details h3 {
      font-size: 1.5rem;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: #1f2937;
    }

    .stat-details p {
      color: #6b7280;
      margin: 0;
      font-size: 0.9rem;
    }

    .loading-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 200px;
    }

    .customers-table-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .table-container {
      width: 100%;
      overflow-x: auto;
    }

    .customers-table {
      width: 100%;
    }

    .customer-info {
      display: flex;
      flex-direction: column;
    }

    .customer-name {
      font-weight: 500;
      color: #1f2937;
    }

    .customer-email {
      font-size: 0.8rem;
      color: #6b7280;
    }

    .no-orders {
      color: #9ca3af;
      font-style: italic;
    }

    .status-badge {
      padding: 4px 8px;
      border-radius: 12px;
      font-size: 0.8rem;
      font-weight: 500;
      text-transform: uppercase;
    }

    .status-badge.status-active {
      background: #d1fae5;
      color: #065f46;
    }

    .status-badge.status-inactive {
      background: #fee2e2;
      color: #991b1b;
    }

    @media (max-width: 768px) {
      .customer-management-container {
        padding: 16px;
      }

      .page-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 16px;
      }

      .stats-cards {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class CustomerManagementComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  dataSource = new MatTableDataSource<ShopCustomer>();
  displayedColumns = ['name', 'phone', 'orders', 'spent', 'avgOrder', 'lastOrder', 'status', 'actions'];
  loading = false;

  customers: ShopCustomer[] = [
    {
      id: 1,
      firstName: 'Rajesh',
      lastName: 'Kumar',
      email: 'rajesh.kumar@email.com',
      phoneNumber: '+91 9876543213',
      totalOrders: 15,
      totalSpent: 4500,
      lastOrderDate: new Date('2024-01-10'),
      status: 'active',
      loyaltyPoints: 450,
      averageOrderValue: 300,
      joinDate: new Date('2023-06-15')
    },
    {
      id: 2,
      firstName: 'Priya',
      lastName: 'Sharma',
      email: 'priya.sharma@email.com',
      phoneNumber: '+91 9876543214',
      totalOrders: 8,
      totalSpent: 2400,
      lastOrderDate: new Date('2024-01-05'),
      status: 'active',
      loyaltyPoints: 240,
      averageOrderValue: 300,
      joinDate: new Date('2023-08-20')
    }
  ];

  constructor(
    private snackBar: MatSnackBar,
    private customerService: CustomerService,
    private authService: AuthService
  ) {
    this.dataSource.data = [];
  }

  ngOnInit(): void {
    this.loadCustomers();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  loadCustomers(): void {
    this.loading = true;
    const currentUser = this.authService.getCurrentUser();
    
    if (!currentUser || !currentUser.shopId) {
      this.snackBar.open('Shop information not found', 'Close', { duration: 3000 });
      this.loading = false;
      // Fallback to mock data
      this.dataSource.data = this.customers;
      return;
    }

    this.customerService.getShopCustomers(currentUser.shopId)
      .pipe(
        finalize(() => this.loading = false)
      )
      .subscribe({
        next: (response) => {
          // Map API response to ShopCustomer interface
          this.customers = response.map((customer: any) => ({
            id: customer.id,
            firstName: customer.firstName,
            lastName: customer.lastName,
            email: customer.email,
            phoneNumber: customer.phoneNumber,
            totalOrders: customer.totalOrders || 0,
            totalSpent: customer.totalSpent || 0,
            lastOrderDate: customer.lastOrderDate ? new Date(customer.lastOrderDate) : null,
            status: customer.status || 'active',
            loyaltyPoints: customer.loyaltyPoints || 0,
            averageOrderValue: customer.averageOrderValue || 0,
            joinDate: new Date(customer.createdAt)
          }));
          
          this.dataSource.data = this.customers;
        },
        error: (error) => {
          console.error('Error loading customers:', error);
          this.snackBar.open('Failed to load customers. Showing sample data.', 'Close', { duration: 3000 });
          // Fallback to mock data on error
          this.dataSource.data = this.customers;
        }
      });
  }

  getTotalCustomers(): number {
    return this.customers.length;
  }

  getActiveCustomers(): number {
    return this.customers.filter(c => c.status === 'active').length;
  }

  getAverageOrderValue(): number {
    const total = this.customers.reduce((sum, c) => sum + c.averageOrderValue, 0);
    return this.customers.length > 0 ? total / this.customers.length : 0;
  }

  getLoyalCustomers(): number {
    return this.customers.filter(c => c.totalOrders >= 10).length;
  }

  viewCustomerDetails(customer: ShopCustomer): void {
    this.snackBar.open(`Viewing details for ${customer.firstName} ${customer.lastName}`, 'Close', { duration: 2000 });
  }

  viewCustomerOrders(customer: ShopCustomer): void {
    this.snackBar.open(`Viewing orders for ${customer.firstName} ${customer.lastName}`, 'Close', { duration: 2000 });
  }

  exportCustomers(): void {
    const data = {
      customers: this.customers,
      exportedAt: new Date().toISOString(),
      totalCustomers: this.getTotalCustomers(),
      activeCustomers: this.getActiveCustomers()
    };
    
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `customers-export-${new Date().toISOString().split('T')[0]}.json`;
    link.click();
    window.URL.revokeObjectURL(url);
    
    this.snackBar.open('Customer data exported successfully', 'Close', { duration: 2000 });
  }
}