import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { FormControl } from '@angular/forms';
import { Router } from '@angular/router';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { Customer, CustomerService, CustomerSearchParams } from '../../../../core/services/customer.service';

@Component({
  selector: 'app-customer-list',
  template: `
    <div class="customer-list-container">
      <!-- Modern Header -->
      <div class="page-header">
        <div class="header-content">
          <div class="breadcrumb">
            <span class="breadcrumb-item">
              <mat-icon>dashboard</mat-icon>
              Dashboard
            </span>
            <mat-icon class="breadcrumb-separator">chevron_right</mat-icon>
            <span class="breadcrumb-item">Customer Management</span>
            <mat-icon class="breadcrumb-separator">chevron_right</mat-icon>
            <span class="breadcrumb-item active">Customers</span>
          </div>
          <h1 class="page-title">Customer Management</h1>
          <p class="page-description">
            Manage customer information, communications, and analytics
          </p>
        </div>
        <div class="header-actions">
          <button mat-raised-button class="action-button" (click)="openAddCustomerDialog()">
            <mat-icon>person_add</mat-icon>
            Add Customer
          </button>
          <button mat-stroked-button (click)="exportCustomers()">
            <mat-icon>file_download</mat-icon>
            Export
          </button>
        </div>
      </div>

      <!-- Statistics Cards -->
      <div class="stats-row">
        <div class="stat-card">
          <div class="stat-icon">
            <mat-icon>people</mat-icon>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ stats.totalCustomers }}</div>
            <div class="stat-label">Total Customers</div>
          </div>
        </div>
        
        <div class="stat-card active">
          <div class="stat-icon">
            <mat-icon>verified_user</mat-icon>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ stats.activeCustomers }}</div>
            <div class="stat-label">Active Customers</div>
          </div>
        </div>
        
        <div class="stat-card">
          <div class="stat-icon">
            <mat-icon>check_circle</mat-icon>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ stats.verifiedCustomers }}</div>
            <div class="stat-label">Verified</div>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon">
            <mat-icon>currency_rupee</mat-icon>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ formatCurrency(stats.totalSpending) }}</div>
            <div class="stat-label">Total Spending</div>
          </div>
        </div>
      </div>

      <!-- Filters and Search -->
      <mat-card class="filters-card">
        <mat-card-content>
          <div class="filters-section">
            <div class="search-filters">
              <mat-form-field appearance="outline" class="search-field">
                <mat-label>Search customers</mat-label>
                <input matInput [formControl]="searchControl" placeholder="Search by name, email, mobile...">
                <mat-icon matPrefix>search</mat-icon>
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>Status</mat-label>
                <mat-select [(value)]="selectedStatus" (selectionChange)="applyFilters()">
                  <mat-option value="">All Status</mat-option>
                  <mat-option *ngFor="let status of statusOptions" [value]="status.value">
                    {{ status.label }}
                  </mat-option>
                </mat-select>
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>Verification</mat-label>
                <mat-select [(value)]="selectedVerification" (selectionChange)="applyFilters()">
                  <mat-option value="">All</mat-option>
                  <mat-option value="verified">Verified</mat-option>
                  <mat-option value="unverified">Unverified</mat-option>
                </mat-select>
              </mat-form-field>
            </div>

            <div class="view-options">
              <mat-button-toggle-group [(value)]="viewMode">
                <mat-button-toggle value="table">
                  <mat-icon>table_view</mat-icon>
                </mat-button-toggle>
                <mat-button-toggle value="grid">
                  <mat-icon>grid_view</mat-icon>
                </mat-button-toggle>
              </mat-button-toggle-group>
            </div>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Customers Table View -->
      <mat-card class="customers-table-card" *ngIf="viewMode === 'table'">
        <mat-card-content>
          <div class="table-container">
            <table mat-table [dataSource]="dataSource" matSort class="customers-table">
              <!-- Customer Column -->
              <ng-container matColumnDef="customer">
                <th mat-header-cell *matHeaderCellDef>Customer</th>
                <td mat-cell *matCellDef="let customer">
                  <div class="customer-cell">
                    <div class="customer-avatar">
                      <mat-icon>person</mat-icon>
                    </div>
                    <div class="customer-info">
                      <h4>{{ customer.fullName || customer.firstName + ' ' + customer.lastName }}</h4>
                      <p>{{ customer.email }}</p>
                      <p>{{ customer.mobileNumber }}</p>
                    </div>
                  </div>
                </td>
              </ng-container>

              <!-- Status Column -->
              <ng-container matColumnDef="status">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Status</th>
                <td mat-cell *matCellDef="let customer">
                  <span class="status-badge" [class]="'status-' + customer.status?.toLowerCase()">
                    {{ customer.statusLabel || customer.status }}
                  </span>
                </td>
              </ng-container>

              <!-- Verification Column -->
              <ng-container matColumnDef="verification">
                <th mat-header-cell *matHeaderCellDef>Verification</th>
                <td mat-cell *matCellDef="let customer">
                  <div class="verification-badges">
                    <mat-chip-set>
                      <mat-chip class="verification-chip" [class.verified]="customer.emailVerified">
                        <mat-icon>{{ customer.emailVerified ? 'mark_email_read' : 'email' }}</mat-icon>
                        Email
                      </mat-chip>
                      <mat-chip class="verification-chip" [class.verified]="customer.mobileVerified">
                        <mat-icon>{{ customer.mobileVerified ? 'verified' : 'phone' }}</mat-icon>
                        Mobile
                      </mat-chip>
                    </mat-chip-set>
                  </div>
                </td>
              </ng-container>

              <!-- Orders Column -->
              <ng-container matColumnDef="orders">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Orders</th>
                <td mat-cell *matCellDef="let customer">
                  <div class="orders-cell">
                    <span class="orders-count">{{ customer.totalOrders || 0 }}</span>
                    <span class="orders-value">{{ formatCurrency(customer.totalSpent || 0) }}</span>
                  </div>
                </td>
              </ng-container>

              <!-- Location Column -->
              <ng-container matColumnDef="location">
                <th mat-header-cell *matHeaderCellDef>Location</th>
                <td mat-cell *matCellDef="let customer">
                  <div class="location-cell">
                    <span>{{ getLocationText(customer) }}</span>
                  </div>
                </td>
              </ng-container>

              <!-- Joined Column -->
              <ng-container matColumnDef="joined">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Joined</th>
                <td mat-cell *matCellDef="let customer">
                  <span class="joined-date">{{ formatDate(customer.createdAt) }}</span>
                </td>
              </ng-container>

              <!-- Actions Column -->
              <ng-container matColumnDef="actions">
                <th mat-header-cell *matHeaderCellDef>Actions</th>
                <td mat-cell *matCellDef="let customer">
                  <div class="action-buttons">
                    <button mat-icon-button [matMenuTriggerFor]="actionMenu" [matMenuTriggerData]="{customer: customer}">
                      <mat-icon>more_vert</mat-icon>
                    </button>
                  </div>
                </td>
              </ng-container>

              <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
              <tr mat-row *matRowDef="let row; columns: displayedColumns;" (click)="viewCustomerDetails(row)"></tr>
            </table>

            <mat-paginator 
              [pageSizeOptions]="[10, 25, 50, 100]" 
              [pageSize]="pageSize"
              [length]="totalElements"
              (page)="onPageChange($event)"
              showFirstLastButtons>
            </mat-paginator>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Customers Grid View -->
      <div class="customers-grid" *ngIf="viewMode === 'grid'">
        <mat-card class="customer-card" *ngFor="let customer of dataSource.data">
          <div class="customer-card-header">
            <div class="customer-avatar-large">
              <mat-icon>person</mat-icon>
            </div>
            <div class="customer-badges">
              <span class="status-badge" [class]="'status-' + customer.status?.toLowerCase()">
                {{ customer.statusLabel || customer.status }}
              </span>
              <span class="verification-badge" *ngIf="customer.isVerified">
                <mat-icon>verified</mat-icon>
                Verified
              </span>
            </div>
          </div>
          <mat-card-content>
            <h3 class="customer-name">{{ customer.fullName || customer.firstName + ' ' + customer.lastName }}</h3>
            <p class="customer-email">{{ customer.email }}</p>
            <p class="customer-mobile">{{ customer.mobileNumber }}</p>
            
            <div class="customer-stats">
              <div class="stat-item">
                <mat-icon>shopping_cart</mat-icon>
                <span>{{ customer.totalOrders || 0 }} orders</span>
              </div>
              <div class="stat-item">
                <mat-icon>currency_rupee</mat-icon>
                <span>{{ formatCurrency(customer.totalSpent || 0) }}</span>
              </div>
              <div class="stat-item">
                <mat-icon>location_on</mat-icon>
                <span>{{ getLocationText(customer) }}</span>
              </div>
            </div>
          </mat-card-content>
          <mat-card-actions>
            <button mat-button color="primary" (click)="viewCustomerDetails(customer)">
              <mat-icon>visibility</mat-icon>
              View
            </button>
            <button mat-button (click)="editCustomer(customer)">
              <mat-icon>edit</mat-icon>
              Edit
            </button>
            <button mat-icon-button [matMenuTriggerFor]="gridActionMenu" [matMenuTriggerData]="{customer: customer}">
              <mat-icon>more_vert</mat-icon>
            </button>
          </mat-card-actions>
        </mat-card>
      </div>

      <!-- Loading State -->
      <div *ngIf="loading" class="loading-state">
        <mat-spinner diameter="60"></mat-spinner>
        <h3>Loading Customers</h3>
        <p>Please wait while we fetch customer data...</p>
      </div>
    </div>

    <!-- Action Menu -->
    <mat-menu #actionMenu="matMenu">
      <ng-template matMenuContent let-customer="customer">
        <button mat-menu-item (click)="viewCustomerDetails(customer)">
          <mat-icon>visibility</mat-icon>
          <span>View Details</span>
        </button>
        <button mat-menu-item (click)="editCustomer(customer)">
          <mat-icon>edit</mat-icon>
          <span>Edit Customer</span>
        </button>
        <button mat-menu-item (click)="sendEmail(customer)">
          <mat-icon>email</mat-icon>
          <span>Send Email</span>
        </button>
        <button mat-menu-item (click)="viewOrders(customer)">
          <mat-icon>shopping_cart</mat-icon>
          <span>View Orders</span>
        </button>
        <mat-divider></mat-divider>
        <button mat-menu-item (click)="verifyCustomer(customer)" *ngIf="!customer.isVerified">
          <mat-icon>verified_user</mat-icon>
          <span>Verify Customer</span>
        </button>
        <button mat-menu-item (click)="toggleStatus(customer)">
          <mat-icon>{{ customer.isActive ? 'block' : 'check_circle' }}</mat-icon>
          <span>{{ customer.isActive ? 'Deactivate' : 'Activate' }}</span>
        </button>
      </ng-template>
    </mat-menu>

    <mat-menu #gridActionMenu="matMenu">
      <ng-template matMenuContent let-customer="customer">
        <button mat-menu-item (click)="sendEmail(customer)">
          <mat-icon>email</mat-icon>
          <span>Send Email</span>
        </button>
        <button mat-menu-item (click)="viewOrders(customer)">
          <mat-icon>shopping_cart</mat-icon>
          <span>View Orders</span>
        </button>
        <button mat-menu-item (click)="toggleStatus(customer)">
          <mat-icon>{{ customer.isActive ? 'block' : 'check_circle' }}</mat-icon>
          <span>{{ customer.isActive ? 'Deactivate' : 'Activate' }}</span>
        </button>
      </ng-template>
    </mat-menu>
  `,
  styles: [`
    .customer-list-container {
      background: #f5f5f7;
      min-height: 100vh;
      padding-bottom: 32px;
    }

    /* Header Styles */
    .page-header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      padding: 48px 32px;
      color: white;
      display: flex;
      justify-content: space-between;
      align-items: center;
      box-shadow: 0 4px 20px rgba(102, 126, 234, 0.2);
    }

    .breadcrumb {
      display: flex;
      align-items: center;
      margin-bottom: 16px;
      font-size: 14px;
      opacity: 0.9;
    }

    .breadcrumb-item {
      display: flex;
      align-items: center;
      gap: 6px;
    }

    .breadcrumb-separator {
      margin: 0 8px;
      opacity: 0.6;
    }

    .breadcrumb-item.active {
      font-weight: 500;
    }

    .page-title {
      font-size: 36px;
      font-weight: 700;
      margin: 0 0 8px 0;
      letter-spacing: -0.5px;
    }

    .page-description {
      font-size: 16px;
      opacity: 0.95;
      margin: 0;
    }

    .action-button {
      background: white;
      color: #667eea;
      font-weight: 600;
      padding: 10px 24px;
      border-radius: 8px;
      font-size: 15px;
      margin-right: 12px;
    }

    /* Statistics Row */
    .stats-row {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 24px;
      padding: 32px;
      padding-bottom: 0;
    }

    .stat-card {
      background: white;
      border-radius: 16px;
      padding: 24px;
      display: flex;
      align-items: center;
      gap: 20px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
      transition: all 0.3s ease;
      border: 2px solid transparent;
    }

    .stat-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
    }

    .stat-card.active {
      border-color: #4caf50;
      background: linear-gradient(135deg, #f1f8e9 0%, #fff 100%);
    }

    .stat-icon {
      width: 56px;
      height: 56px;
      background: linear-gradient(135deg, #667eea20 0%, #764ba220 100%);
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .stat-card.active .stat-icon {
      background: linear-gradient(135deg, #4caf5020 0%, #81c78420 100%);
    }

    .stat-icon mat-icon {
      font-size: 28px;
      color: #667eea;
    }

    .stat-card.active .stat-icon mat-icon {
      color: #4caf50;
    }

    .stat-value {
      font-size: 32px;
      font-weight: 700;
      line-height: 1;
      margin-bottom: 4px;
      color: #1a1a1a;
    }

    .stat-label {
      font-size: 14px;
      color: #888;
      font-weight: 500;
    }

    /* Filters */
    .filters-card {
      margin: 32px;
      margin-bottom: 16px;
      border-radius: 16px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
    }

    .filters-section {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
    }

    .search-filters {
      display: flex;
      gap: 16px;
      align-items: center;
      flex: 1;
    }

    .search-field {
      min-width: 300px;
    }

    /* Table Styles */
    .customers-table-card {
      margin: 16px 32px;
      border-radius: 16px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
    }

    .table-container {
      overflow-x: auto;
    }

    .customers-table {
      width: 100%;
      min-width: 800px;
    }

    .customer-cell {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .customer-avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: #f0f0f0;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .customer-info h4 {
      margin: 0 0 2px 0;
      font-size: 14px;
      font-weight: 600;
      color: #1f2937;
    }

    .customer-info p {
      margin: 0;
      font-size: 12px;
      color: #6b7280;
    }

    .status-badge {
      padding: 4px 12px;
      border-radius: 16px;
      font-size: 12px;
      font-weight: 500;
      text-transform: uppercase;
    }

    .status-badge.status-active {
      background: #dcfce7;
      color: #16a34a;
    }

    .status-badge.status-inactive {
      background: #f3f4f6;
      color: #6b7280;
    }

    .status-badge.status-blocked {
      background: #fef2f2;
      color: #dc2626;
    }

    .status-badge.status-pending_verification {
      background: #fef3c7;
      color: #d97706;
    }

    .verification-badges mat-chip-set {
      display: flex;
      gap: 4px;
    }

    .verification-chip {
      font-size: 11px;
      height: 24px;
    }

    .verification-chip.verified {
      background: #dcfce7;
      color: #16a34a;
    }

    .orders-cell {
      display: flex;
      flex-direction: column;
    }

    .orders-count {
      font-weight: 600;
      color: #1f2937;
    }

    .orders-value {
      font-size: 12px;
      color: #6b7280;
    }

    /* Grid Styles */
    .customers-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
      gap: 24px;
      padding: 32px;
    }

    .customer-card {
      border-radius: 16px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
      transition: all 0.3s ease;
      border: 2px solid transparent;
    }

    .customer-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
      border-color: #667eea;
    }

    .customer-card-header {
      padding: 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1px solid #f0f0f0;
      background: linear-gradient(135deg, #f8f9fa 0%, #fff 100%);
    }

    .customer-avatar-large {
      width: 60px;
      height: 60px;
      border-radius: 50%;
      background: linear-gradient(135deg, #667eea20 0%, #764ba220 100%);
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .customer-avatar-large mat-icon {
      font-size: 32px;
      color: #667eea;
    }

    .customer-badges {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .customer-name {
      font-size: 18px;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: #1a1a1a;
    }

    .customer-email {
      font-size: 14px;
      color: #666;
      margin: 0 0 4px 0;
    }

    .customer-mobile {
      font-size: 14px;
      color: #666;
      margin: 0 0 16px 0;
    }

    .customer-stats {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .stat-item {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 13px;
      color: #666;
    }

    .stat-item mat-icon {
      font-size: 16px !important;
      width: 16px !important;
      height: 16px !important;
      color: #999;
    }

    /* Loading State */
    .loading-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 80px 20px;
      text-align: center;
    }

    .loading-state h3 {
      margin: 24px 0 8px 0;
      font-size: 20px;
      color: #333;
    }

    .loading-state p {
      color: #888;
      margin: 0;
    }

    /* Responsive */
    @media (max-width: 768px) {
      .page-header {
        flex-direction: column;
        text-align: center;
        gap: 24px;
      }
      
      .stats-row {
        grid-template-columns: 1fr;
        padding: 16px;
      }
      
      .filters-section {
        flex-direction: column;
        align-items: stretch;
      }
      
      .search-filters {
        flex-direction: column;
        gap: 12px;
      }
      
      .search-field {
        min-width: auto;
        width: 100%;
      }
      
      .customers-grid {
        grid-template-columns: 1fr;
        padding: 16px;
      }
    }
  `]
})
export class CustomerListComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = ['customer', 'status', 'verification', 'orders', 'location', 'joined', 'actions'];
  dataSource = new MatTableDataSource<Customer>();
  searchControl = new FormControl();
  
  viewMode: 'table' | 'grid' = 'table';
  selectedStatus = '';
  selectedVerification = '';
  loading = false;

  // Pagination
  pageSize = 10;
  currentPage = 0;
  totalElements = 0;

  // Statistics
  stats = {
    totalCustomers: 0,
    activeCustomers: 0,
    verifiedCustomers: 0,
    totalSpending: 0,
    averageOrdersPerCustomer: 0
  };

  statusOptions = [
    { value: 'ACTIVE', label: 'Active' },
    { value: 'INACTIVE', label: 'Inactive' },
    { value: 'BLOCKED', label: 'Blocked' },
    { value: 'PENDING_VERIFICATION', label: 'Pending Verification' }
  ];

  constructor(
    private customerService: CustomerService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadCustomers();
    this.loadStats();
    this.setupSearch();
  }

  private setupSearch(): void {
    this.searchControl.valueChanges
      .pipe(
        debounceTime(300),
        distinctUntilChanged()
      )
      .subscribe(value => {
        if (value && value.trim()) {
          this.searchCustomers(value.trim());
        } else {
          this.loadCustomers();
        }
      });
  }

  loadCustomers(): void {
    this.loading = true;
    const params: CustomerSearchParams = {
      page: this.currentPage,
      size: this.pageSize,
      sortBy: 'createdAt',
      sortDirection: 'desc'
    };

    this.customerService.getAllCustomers(params).subscribe({
      next: (response) => {
        this.dataSource.data = response.content;
        this.totalElements = response.totalElements;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading customers:', error);
        this.loading = false;
        this.snackBar.open('Failed to load customers', 'Close', { duration: 3000 });
      }
    });
  }

  searchCustomers(searchTerm: string): void {
    this.loading = true;
    this.customerService.searchCustomers(searchTerm, this.currentPage, this.pageSize).subscribe({
      next: (response) => {
        this.dataSource.data = response.content;
        this.totalElements = response.totalElements;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error searching customers:', error);
        this.loading = false;
      }
    });
  }

  loadStats(): void {
    this.customerService.getCustomerStats().subscribe({
      next: (stats) => {
        this.stats = stats;
      },
      error: (error) => {
        console.error('Error loading stats:', error);
      }
    });
  }

  applyFilters(): void {
    // Implementation for applying filters
    this.loadCustomers();
  }

  onPageChange(event: any): void {
    this.currentPage = event.pageIndex;
    this.pageSize = event.pageSize;
    this.loadCustomers();
  }

  openAddCustomerDialog(): void {
    // Open add customer dialog
    console.log('Open add customer dialog');
  }

  viewCustomerDetails(customer: Customer): void {
    // Navigate to customer details
    this.router.navigate(['/customers', customer.id]);
  }

  editCustomer(customer: Customer): void {
    // Navigate to edit customer
    this.router.navigate(['/customers', customer.id, 'edit']);
  }

  sendEmail(customer: Customer): void {
    // Open email dialog
    console.log('Send email to:', customer.email);
  }

  viewOrders(customer: Customer): void {
    // Navigate to customer orders
    this.router.navigate(['/customers', customer.id, 'orders']);
  }

  verifyCustomer(customer: Customer): void {
    // Verify customer
    console.log('Verify customer:', customer.id);
  }

  toggleStatus(customer: Customer): void {
    // Toggle customer status
    console.log('Toggle status for:', customer.id);
  }

  exportCustomers(): void {
    // Export customers
    console.log('Export customers');
  }

  // Helper methods
  formatCurrency(amount: number): string {
    return this.customerService.formatCurrency(amount);
  }

  formatDate(dateString: string): string {
    return this.customerService.formatDate(dateString);
  }

  getLocationText(customer: Customer): string {
    if (customer.city && customer.state) {
      return `${customer.city}, ${customer.state}`;
    } else if (customer.city) {
      return customer.city;
    } else if (customer.state) {
      return customer.state;
    }
    return 'Not specified';
  }
}