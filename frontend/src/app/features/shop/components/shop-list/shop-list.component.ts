import { Component, OnInit } from '@angular/core';
import { Shop } from '../../../../core/models/shop.model';
import { ShopService } from '../../../../core/services/shop.service';
import { DocumentService } from '../../../../core/services/document.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-shop-list',
  template: `
    <div class="shop-list-container">
      <!-- Header -->
      <div class="header">
        <div class="header-left">
          <h1>Shop Verification</h1>
          <p class="subtitle">Verify shop details and approve registrations</p>
        </div>
        <button mat-stroked-button routerLink="/shops/master">
          <mat-icon>settings</mat-icon>
          Go to Shop Master
        </button>
      </div>

      <!-- Search and Filters -->
      <div class="filters-section">
        <div class="search-box">
          <mat-form-field appearance="outline">
            <mat-label>Search shops...</mat-label>
            <input matInput [(ngModel)]="searchQuery" (input)="onSearch()" placeholder="Enter shop name...">
            <mat-icon matSuffix>search</mat-icon>
          </mat-form-field>
        </div>
        
        <div class="filter-controls">
          <mat-form-field appearance="outline">
            <mat-label>Status</mat-label>
            <mat-select [(ngModel)]="selectedStatus" (selectionChange)="onStatusFilter()">
              <mat-option value="">All Status</mat-option>
              <mat-option value="PENDING">Pending</mat-option>
              <mat-option value="APPROVED">Approved</mat-option>
              <mat-option value="REJECTED">Rejected</mat-option>
              <mat-option value="SUSPENDED">Suspended</mat-option>
            </mat-select>
          </mat-form-field>

          <mat-form-field appearance="outline">
            <mat-label>Filter by City</mat-label>
            <mat-select [(ngModel)]="selectedCity" (selectionChange)="onCityFilter()">
              <mat-option value="">All Cities</mat-option>
              <mat-option *ngFor="let city of cities" [value]="city">{{city}}</mat-option>
            </mat-select>
          </mat-form-field>

          <mat-form-field appearance="outline">
            <mat-label>Business Type</mat-label>
            <mat-select [(ngModel)]="selectedBusinessType" (selectionChange)="onBusinessTypeFilter()">
              <mat-option value="">All Types</mat-option>
              <mat-option value="GROCERY">Grocery</mat-option>
              <mat-option value="PHARMACY">Pharmacy</mat-option>
              <mat-option value="RESTAURANT">Restaurant</mat-option>
              <mat-option value="GENERAL">General</mat-option>
            </mat-select>
          </mat-form-field>
        </div>
      </div>

      <!-- Loading -->
      <div class="loading" *ngIf="loading">
        <mat-progress-spinner mode="indeterminate"></mat-progress-spinner>
      </div>

      <!-- Shop Table -->
      <div class="table-container" *ngIf="!loading">
        <table mat-table [dataSource]="shops" class="shops-table" matSort>
          
          <!-- Shop ID Column -->
          <ng-container matColumnDef="shopId">
            <th mat-header-cell *matHeaderCellDef mat-sort-header>Shop ID</th>
            <td mat-cell *matCellDef="let shop">
              <div class="shop-id">{{ shop.shopId || shop.id }}</div>
            </td>
          </ng-container>

          <!-- Shop Name Column -->
          <ng-container matColumnDef="name">
            <th mat-header-cell *matHeaderCellDef mat-sort-header>Shop Name</th>
            <td mat-cell *matCellDef="let shop">
              <div class="shop-name">
                <strong>{{ shop.name }}</strong>
                <div class="shop-business">{{ shop.businessName }}</div>
              </div>
            </td>
          </ng-container>

          <!-- Owner Column -->
          <ng-container matColumnDef="owner">
            <th mat-header-cell *matHeaderCellDef>Owner</th>
            <td mat-cell *matCellDef="let shop">
              <div class="owner-info">
                <div>{{ shop.ownerName }}</div>
                <div class="owner-phone">{{ shop.ownerPhone }}</div>
              </div>
            </td>
          </ng-container>

          <!-- Location Column -->
          <ng-container matColumnDef="location">
            <th mat-header-cell *matHeaderCellDef>Location</th>
            <td mat-cell *matCellDef="let shop">
              <div class="location-info">
                <div>{{ shop.city }}, {{ shop.state }}</div>
                <div class="postal-code">{{ shop.postalCode }}</div>
              </div>
            </td>
          </ng-container>

          <!-- Business Type Column -->
          <ng-container matColumnDef="businessType">
            <th mat-header-cell *matHeaderCellDef>Type</th>
            <td mat-cell *matCellDef="let shop">
              <mat-chip [ngClass]="getBusinessTypeClass(shop.businessType)">
                {{ getBusinessTypeDisplay(shop.businessType) }}
              </mat-chip>
            </td>
          </ng-container>

          <!-- Status Column -->
          <ng-container matColumnDef="status">
            <th mat-header-cell *matHeaderCellDef>Status</th>
            <td mat-cell *matCellDef="let shop">
              <mat-chip [ngClass]="getStatusClass(shop.status)">
                {{ getStatusDisplay(shop.status) }}
              </mat-chip>
            </td>
          </ng-container>

          <!-- Rating Column -->
          <ng-container matColumnDef="rating">
            <th mat-header-cell *matHeaderCellDef>Rating</th>
            <td mat-cell *matCellDef="let shop">
              <div class="rating">
                <mat-icon class="star-icon">star</mat-icon>
                {{ shop.rating || 0 | number:'1.1-1' }}
              </div>
            </td>
          </ng-container>

          <!-- Created Column -->
          <ng-container matColumnDef="created">
            <th mat-header-cell *matHeaderCellDef mat-sort-header>Created</th>
            <td mat-cell *matCellDef="let shop">{{ shop.createdAt | date:'MMM dd, yyyy' }}</td>
          </ng-container>

          <!-- Actions Column -->
          <ng-container matColumnDef="actions">
            <th mat-header-cell *matHeaderCellDef>Actions</th>
            <td mat-cell *matCellDef="let shop; let i = index">
              <div class="actions">
                <button mat-icon-button [matMenuTriggerFor]="actionsMenu" class="action-button" 
                        [id]="'action-' + i">
                  <mat-icon>more_vert</mat-icon>
                </button>
                <mat-menu #actionsMenu="matMenu">
                  <button mat-menu-item (click)="viewShop(shop)">
                    <mat-icon>fact_check</mat-icon>
                    <span>Verify Details</span>
                  </button>
                  <button mat-menu-item (click)="editShop(shop)">
                    <mat-icon>edit</mat-icon>
                    <span>Edit</span>
                  </button>
                  <button mat-menu-item (click)="approveShop(shop)" *ngIf="shop.status === 'PENDING'">
                    <mat-icon>check_circle</mat-icon>
                    <span>Quick Approve</span>
                  </button>
                  <button mat-menu-item (click)="rejectShop(shop)" *ngIf="shop.status === 'PENDING'">
                    <mat-icon>cancel</mat-icon>
                    <span>Quick Reject</span>
                  </button>
                  <mat-divider *ngIf="shop.status === 'PENDING'"></mat-divider>
                  <button mat-menu-item (click)="deleteShop(shop)" class="delete-action">
                    <mat-icon>delete</mat-icon>
                    <span>Delete</span>
                  </button>
                </mat-menu>
              </div>
            </td>
          </ng-container>

          <!-- Table Header and Rows -->
          <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
          <tr mat-row *matRowDef="let row; columns: displayedColumns;" class="shop-row"></tr>
        </table>
      </div>

      <!-- No Results -->
      <div class="no-results" *ngIf="!loading && shops.length === 0">
        <mat-icon>store</mat-icon>
        <h3>No shops found</h3>
        <p>Try adjusting your search criteria or add a new shop.</p>
      </div>

      <!-- Pagination -->
      <mat-paginator 
        *ngIf="!loading && shops.length > 0"
        [length]="totalElements"
        [pageSize]="pageSize"
        [pageSizeOptions]="[10, 20, 50]"
        (page)="onPageChange($event)">
      </mat-paginator>
    </div>
  `,
  styles: [`
    .shop-list-container {
      padding: 0;
    }

    .header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 24px;
      padding: 0 4px;
    }

    .header-left h1 {
      margin: 0 0 4px 0;
      color: #1f2937;
      font-size: 28px;
      font-weight: 600;
    }

    .subtitle {
      margin: 0;
      color: #6b7280;
      font-size: 14px;
    }

    .filters-section {
      display: flex;
      gap: 16px;
      margin-bottom: 24px;
      align-items: flex-end;
      flex-wrap: wrap;
    }

    .search-box mat-form-field {
      width: 300px;
    }

    .filter-controls {
      display: flex;
      gap: 16px;
    }

    .filter-controls mat-form-field {
      width: 200px;
    }

    .table-container {
      background: white;
      border-radius: 8px;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      overflow: hidden;
    }

    .shops-table {
      width: 100%;
    }

    .shop-row:hover {
      background-color: #f8fafc;
    }

    .shop-id {
      font-family: 'Courier New', monospace;
      font-weight: 600;
      color: #374151;
    }

    .shop-name strong {
      color: #1f2937;
      font-size: 16px;
    }

    .shop-business {
      color: #6b7280;
      font-size: 13px;
      margin-top: 2px;
    }

    .owner-info div:first-child {
      font-weight: 500;
      color: #374151;
    }

    .owner-phone {
      color: #6b7280;
      font-size: 13px;
      margin-top: 2px;
    }

    .location-info div:first-child {
      color: #374151;
    }

    .postal-code {
      color: #6b7280;
      font-size: 13px;
      margin-top: 2px;
    }

    .rating {
      display: flex;
      align-items: center;
      gap: 4px;
    }

    .star-icon {
      color: #fbbf24;
      font-size: 18px;
      width: 18px;
      height: 18px;
    }

    .actions {
      display: flex;
      justify-content: center;
    }

    .action-button {
      color: #6b7280;
    }

    .delete-action {
      color: #ef4444 !important;
    }

    // Status chips
    mat-chip {
      font-size: 12px;
      font-weight: 500;
      border-radius: 12px;
      padding: 4px 12px;
    }

    .status-pending {
      background-color: #fff3cd;
      color: #856404;
      border: 1px solid #ffeaa7;
    }

    .status-approved {
      background-color: #d4edda;
      color: #155724;
      border: 1px solid #00b894;
    }

    .status-rejected {
      background-color: #f8d7da;
      color: #721c24;
      border: 1px solid #e74c3c;
    }

    .status-suspended {
      background-color: #e2e3e5;
      color: #383d41;
      border: 1px solid #6c757d;
    }

    .type-grocery {
      background-color: #d1f2eb;
      color: #0e6b47;
      border: 1px solid #00b894;
    }

    .type-pharmacy {
      background-color: #cce5ff;
      color: #0056b3;
      border: 1px solid #007bff;
    }

    .type-restaurant {
      background-color: #f3e5f5;
      color: #6f42c1;
      border: 1px solid #6f42c1;
    }

    .type-general {
      background-color: #f8f9fa;
      color: #495057;
      border: 1px solid #6c757d;
    }

    .loading {
      display: flex;
      justify-content: center;
      align-items: center;
      height: 200px;
    }

    .no-results {
      text-align: center;
      padding: 60px 20px;
      color: #6b7280;
      background: white;
      border-radius: 8px;
    }

    .no-results mat-icon {
      font-size: 64px;
      height: 64px;
      width: 64px;
      color: #d1d5db;
    }

    .no-results h3 {
      margin: 16px 0 8px 0;
      color: #374151;
    }

    mat-paginator {
      background: transparent;
      margin-top: 16px;
    }
  `]
})
export class ShopListComponent implements OnInit {
  shops: Shop[] = [];
  loading = false;
  searchQuery = '';
  selectedCity = '';
  selectedBusinessType = '';
  selectedStatus = '';
  cities: string[] = [];
  
  // Table columns
  displayedColumns: string[] = ['shopId', 'name', 'owner', 'location', 'businessType', 'status', 'rating', 'created', 'actions'];
  
  // Pagination
  currentPage = 0;
  pageSize = 20;
  totalElements = 0;

  constructor(
    private shopService: ShopService,
    private documentService: DocumentService
  ) {}

  ngOnInit() {
    // Default to PENDING shops for approval workflow
    this.selectedStatus = 'PENDING';
    this.loadShops();
    this.loadCities();
  }

  loadShops() {
    this.loading = true;
    const params = {
      page: this.currentPage,
      size: this.pageSize,
      city: this.selectedCity,
      businessType: this.selectedBusinessType,
      status: this.selectedStatus
    };

    this.shopService.getShops(params).subscribe({
      next: (response) => {
        this.shops = response.content;
        this.totalElements = response.totalElements;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading shops:', error);
        this.loading = false;
      }
    });
  }

  loadCities() {
    this.shopService.getCities().subscribe({
      next: (cities) => {
        this.cities = cities;
      },
      error: (error) => {
        console.error('Error loading cities:', error);
      }
    });
  }

  onSearch() {
    if (this.searchQuery.trim()) {
      this.loading = true;
      this.shopService.searchShops(this.searchQuery, this.currentPage, this.pageSize).subscribe({
        next: (response) => {
          this.shops = response.content;
          this.totalElements = response.totalElements;
          this.loading = false;
        },
        error: (error) => {
          console.error('Error searching shops:', error);
          this.loading = false;
        }
      });
    } else {
      this.loadShops();
    }
  }

  onCityFilter() {
    this.currentPage = 0;
    this.loadShops();
  }

  onBusinessTypeFilter() {
    this.currentPage = 0;
    this.loadShops();
  }

  onStatusFilter() {
    this.currentPage = 0;
    this.loadShops();
  }

  onPageChange(event: any) {
    this.currentPage = event.pageIndex;
    this.pageSize = event.pageSize;
    this.loadShops();
  }

  editShop(shop: Shop) {
    // Navigate to edit form - implement routing
    Swal.fire({
      title: 'Edit Shop',
      text: `Edit functionality will be implemented for ${shop.name}`,
      icon: 'info',
      confirmButtonText: 'OK',
      confirmButtonColor: '#3085d6'
    });
    console.log('Edit shop:', shop);
    // TODO: this.router.navigate(['/shops/edit', shop.id]);
  }

  deleteShop(shop: Shop) {
    Swal.fire({
      title: 'Delete Shop',
      text: `Are you sure you want to delete "${shop.name}"?`,
      html: `Are you sure you want to delete <strong>"${shop.name}"</strong>?<br><br><small>This action cannot be undone.</small>`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, delete it!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.shopService.deleteShop(shop.id).subscribe({
          next: () => {
            Swal.fire({
              title: 'Deleted!',
              text: `Shop "${shop.name}" has been deleted successfully.`,
              icon: 'success',
              confirmButtonColor: '#3085d6'
            });
            this.loadShops(); // Reload the list
          },
          error: (error) => {
            console.error('Error deleting shop:', error);
            Swal.fire({
              title: 'Error!',
              text: `Failed to delete shop "${shop.name}". Please try again.`,
              icon: 'error',
              confirmButtonColor: '#3085d6'
            });
          }
        });
      }
    });
  }

  viewShop(shop: Shop) {
    // First fetch the documents for this shop
    this.documentService.getShopDocuments(shop.id).subscribe({
      next: (documents) => {
        // Show detailed verification form with actual documents
        Swal.fire({
          title: `Verify Shop: ${shop.name}`,
          html: `
            <div class="verification-details" style="text-align: left; max-height: 400px; overflow-y: auto;">
              <h4>📋 Basic Information</h4>
              <table style="width: 100%; margin-bottom: 20px;">
                <tr><td><strong>Shop Name:</strong></td><td>${shop.name}</td></tr>
                <tr><td><strong>Business Name:</strong></td><td>${shop.businessName || 'N/A'}</td></tr>
                <tr><td><strong>Business Type:</strong></td><td>${shop.businessType}</td></tr>
                <tr><td><strong>Status:</strong></td><td><span style="color: ${this.getStatusColorCode(shop.status)}">${shop.status}</span></td></tr>
              </table>
              
              <h4>👤 Owner Information</h4>
              <table style="width: 100%; margin-bottom: 20px;">
                <tr><td><strong>Owner Name:</strong></td><td>${shop.ownerName}</td></tr>
                <tr><td><strong>Email:</strong></td><td>${shop.ownerEmail || 'N/A'}</td></tr>
                <tr><td><strong>Phone:</strong></td><td>${shop.ownerPhone || 'N/A'}</td></tr>
              </table>
              
              <h4>📍 Location Details</h4>
              <table style="width: 100%; margin-bottom: 20px;">
                <tr><td><strong>Address:</strong></td><td>${shop.addressLine1 || 'N/A'}</td></tr>
                <tr><td><strong>City:</strong></td><td>${shop.city}</td></tr>
                <tr><td><strong>State:</strong></td><td>${shop.state}</td></tr>
                <tr><td><strong>Postal Code:</strong></td><td>${shop.postalCode || 'N/A'}</td></tr>
              </table>
              
              <h4>💼 Business Details</h4>
              <table style="width: 100%; margin-bottom: 20px;">
                <tr><td><strong>Min Order:</strong></td><td>₹${shop.minOrderAmount || 0}</td></tr>
                <tr><td><strong>Delivery Fee:</strong></td><td>₹${shop.deliveryFee || 0}</td></tr>
                <tr><td><strong>Delivery Radius:</strong></td><td>${shop.deliveryRadius || 0} km</td></tr>
                <tr><td><strong>Free Delivery Above:</strong></td><td>₹${shop.freeDeliveryAbove || 0}</td></tr>
                <tr><td><strong>Rating:</strong></td><td>${shop.rating || 'Not Rated'}</td></tr>
                <tr><td><strong>Created:</strong></td><td>${shop.createdAt ? new Date(shop.createdAt).toLocaleDateString() : 'N/A'}</td></tr>
              </table>
              
              <h4>📄 Required Documents</h4>
              <div class="documents-section">
                ${this.getDocumentStatusHtmlWithActualDocs(shop, documents)}
              </div>
            </div>
          `,
          icon: 'info',
          showCancelButton: shop.status === 'PENDING',
          showDenyButton: shop.status === 'PENDING',
          confirmButtonText: shop.status === 'PENDING' ? '✅ Approve' : 'Close',
          denyButtonText: '❌ Reject',
          cancelButtonText: 'Close',
          confirmButtonColor: '#28a745',
          denyButtonColor: '#dc3545',
          cancelButtonColor: '#6c757d',
          width: 700,
          customClass: {
            htmlContainer: 'text-left'
          }
        }).then((result) => {
          if (result.isConfirmed && shop.status === 'PENDING') {
            this.approveShop(shop);
          } else if (result.isDenied && shop.status === 'PENDING') {
            this.rejectShop(shop);
          }
        });
      },
      error: (error) => {
        console.error('Error fetching documents:', error);
        // Show the dialog anyway without documents
        this.showVerificationDialogWithoutDocs(shop);
      }
    });
  }

  private showVerificationDialogWithoutDocs(shop: Shop) {
    Swal.fire({
      title: `Verify Shop: ${shop.name}`,
      html: `
        <div class="verification-details" style="text-align: left; max-height: 400px; overflow-y: auto;">
          <h4>📋 Basic Information</h4>
          <table style="width: 100%; margin-bottom: 20px;">
            <tr><td><strong>Shop Name:</strong></td><td>${shop.name}</td></tr>
            <tr><td><strong>Business Name:</strong></td><td>${shop.businessName || 'N/A'}</td></tr>
            <tr><td><strong>Business Type:</strong></td><td>${shop.businessType}</td></tr>
            <tr><td><strong>Status:</strong></td><td><span style="color: ${this.getStatusColorCode(shop.status)}">${shop.status}</span></td></tr>
          </table>
          
          <h4>👤 Owner Information</h4>
          <table style="width: 100%; margin-bottom: 20px;">
            <tr><td><strong>Owner Name:</strong></td><td>${shop.ownerName}</td></tr>
            <tr><td><strong>Email:</strong></td><td>${shop.ownerEmail || 'N/A'}</td></tr>
            <tr><td><strong>Phone:</strong></td><td>${shop.ownerPhone || 'N/A'}</td></tr>
          </table>
          
          <h4>📍 Location Details</h4>
          <table style="width: 100%; margin-bottom: 20px;">
            <tr><td><strong>Address:</strong></td><td>${shop.addressLine1 || 'N/A'}</td></tr>
            <tr><td><strong>City:</strong></td><td>${shop.city}</td></tr>
            <tr><td><strong>State:</strong></td><td>${shop.state}</td></tr>
            <tr><td><strong>Postal Code:</strong></td><td>${shop.postalCode || 'N/A'}</td></tr>
          </table>
          
          <h4>💼 Business Details</h4>
          <table style="width: 100%; margin-bottom: 20px;">
            <tr><td><strong>Min Order:</strong></td><td>₹${shop.minOrderAmount || 0}</td></tr>
            <tr><td><strong>Delivery Fee:</strong></td><td>₹${shop.deliveryFee || 0}</td></tr>
            <tr><td><strong>Delivery Radius:</strong></td><td>${shop.deliveryRadius || 0} km</td></tr>
            <tr><td><strong>Free Delivery Above:</strong></td><td>₹${shop.freeDeliveryAbove || 0}</td></tr>
            <tr><td><strong>Rating:</strong></td><td>${shop.rating || 'Not Rated'}</td></tr>
            <tr><td><strong>Created:</strong></td><td>${shop.createdAt ? new Date(shop.createdAt).toLocaleDateString() : 'N/A'}</td></tr>
          </table>
          
          <h4>📄 Required Documents</h4>
          <div class="documents-section">
            <div style="padding: 10px; background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 4px;">
              <strong>⚠️ No documents uploaded</strong><br>
              <small>Shop owner needs to upload required documents for verification</small>
            </div>
          </div>
        </div>
      `,
      icon: 'info',
      showCancelButton: shop.status === 'PENDING',
      showDenyButton: shop.status === 'PENDING',
      confirmButtonText: shop.status === 'PENDING' ? '✅ Approve' : 'Close',
      denyButtonText: '❌ Reject',
      cancelButtonText: 'Close',
      confirmButtonColor: '#28a745',
      denyButtonColor: '#dc3545',
      cancelButtonColor: '#6c757d',
      width: 700,
      customClass: {
        htmlContainer: 'text-left'
      }
    }).then((result) => {
      if (result.isConfirmed && shop.status === 'PENDING') {
        this.approveShop(shop);
      } else if (result.isDenied && shop.status === 'PENDING') {
        this.rejectShop(shop);
      }
    });
  }

  approveShop(shop: Shop) {
    Swal.fire({
      title: 'Approve Shop',
      text: `Are you sure you want to approve "${shop.name}"?`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonColor: '#28a745',
      cancelButtonColor: '#6c757d',
      confirmButtonText: 'Yes, approve it!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.shopService.approveShop(shop.id).subscribe({
          next: () => {
            Swal.fire({
              title: 'Approved!',
              text: `Shop "${shop.name}" has been approved successfully.`,
              icon: 'success',
              confirmButtonColor: '#3085d6'
            });
            this.loadShops(); // Reload to show updated status
          },
          error: (error) => {
            console.error('Error approving shop:', error);
            Swal.fire({
              title: 'Error!',
              text: `Failed to approve shop "${shop.name}". Please try again.`,
              icon: 'error',
              confirmButtonColor: '#3085d6'
            });
          }
        });
      }
    });
  }

  rejectShop(shop: Shop) {
    Swal.fire({
      title: 'Reject Shop',
      text: `Enter rejection reason for "${shop.name}":`,
      input: 'textarea',
      inputPlaceholder: 'Enter the reason for rejection...',
      inputAttributes: {
        'aria-label': 'Rejection reason'
      },
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#dc3545',
      cancelButtonColor: '#6c757d',
      confirmButtonText: 'Reject Shop',
      cancelButtonText: 'Cancel',
      inputValidator: (value) => {
        if (!value || !value.trim()) {
          return 'Rejection reason is required!';
        }
        return null;
      }
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        this.shopService.rejectShop(shop.id, result.value.trim()).subscribe({
          next: () => {
            Swal.fire({
              title: 'Rejected!',
              text: `Shop "${shop.name}" has been rejected.`,
              icon: 'success',
              confirmButtonColor: '#3085d6'
            });
            this.loadShops(); // Reload to show updated status
          },
          error: (error) => {
            console.error('Error rejecting shop:', error);
            Swal.fire({
              title: 'Error!',
              text: `Failed to reject shop "${shop.name}". Please try again.`,
              icon: 'error',
              confirmButtonColor: '#3085d6'
            });
          }
        });
      }
    });
  }

  getBusinessTypeDisplay(type: string): string {
    switch(type?.toUpperCase()) {
      case 'GROCERY': return 'Grocery';
      case 'PHARMACY': return 'Pharmacy';
      case 'RESTAURANT': return 'Restaurant';
      case 'GENERAL': return 'General';
      default: return type || 'Unknown';
    }
  }

  getBusinessTypeClass(type: string): string {
    switch(type?.toUpperCase()) {
      case 'GROCERY': return 'type-grocery';
      case 'PHARMACY': return 'type-pharmacy';
      case 'RESTAURANT': return 'type-restaurant';
      case 'GENERAL': return 'type-general';
      default: return 'type-general';
    }
  }

  getStatusDisplay(status: string): string {
    switch(status?.toUpperCase()) {
      case 'PENDING': return 'Pending';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      case 'SUSPENDED': return 'Suspended';
      default: return status || 'Unknown';
    }
  }

  getStatusClass(status: string): string {
    switch(status?.toUpperCase()) {
      case 'PENDING': return 'status-pending';
      case 'APPROVED': return 'status-approved';
      case 'REJECTED': return 'status-rejected';
      case 'SUSPENDED': return 'status-suspended';
      default: return 'status-pending';
    }
  }

  getStatusColorCode(status: string): string {
    switch(status?.toUpperCase()) {
      case 'PENDING': return '#856404';
      case 'APPROVED': return '#155724';
      case 'REJECTED': return '#721c24';
      case 'SUSPENDED': return '#383d41';
      default: return '#856404';
    }
  }

  getDocumentStatusHtmlWithActualDocs(shop: Shop, documents: any[]): string {
    const requiredDocs = [
      { type: 'OWNER_PHOTO', name: 'Owner Photo' },
      { type: 'SHOP_PHOTO', name: 'Shop Photo' },
      { type: 'BUSINESS_LICENSE', name: 'Business License' },
      { type: 'GST_CERTIFICATE', name: 'GST Certificate' },
      { type: 'PAN_CARD', name: 'PAN Card' },
      { type: 'AADHAR_CARD', name: 'Aadhar Card' },
      { type: 'ADDRESS_PROOF', name: 'Address Proof' }
    ];

    // Add business-specific documents
    if (shop.businessType === 'RESTAURANT' || shop.businessType === 'GROCERY') {
      requiredDocs.push({ type: 'FSSAI_CERTIFICATE', name: 'FSSAI Certificate' });
    }
    if (shop.businessType === 'RESTAURANT') {
      requiredDocs.push({ type: 'FOOD_LICENSE', name: 'Food License' });
    }
    if (shop.businessType === 'PHARMACY') {
      requiredDocs.push({ type: 'DRUG_LICENSE', name: 'Drug License' });
    }

    if (!documents || documents.length === 0) {
      return `
        <div style="padding: 10px; background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 4px;">
          <strong>⚠️ No documents uploaded</strong><br>
          <small>Shop owner needs to upload required documents for verification</small>
        </div>
      `;
    }

    const docStatusHtml = requiredDocs.map(reqDoc => {
      const doc = documents.find(d => d.documentType === reqDoc.type);
      if (doc) {
        const statusColor = doc.verificationStatus === 'VERIFIED' || doc.verificationStatus === 'APPROVED' ? '#28a745' : 
                          doc.verificationStatus === 'REJECTED' ? '#dc3545' : '#ffc107';
        const statusIcon = doc.verificationStatus === 'VERIFIED' || doc.verificationStatus === 'APPROVED' ? '✅' : 
                          doc.verificationStatus === 'REJECTED' ? '❌' : '⏳';
        
        return `
          <div style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee;">
            <span><strong>${reqDoc.name}:</strong></span>
            <span style="color: ${statusColor}; font-weight: bold;">
              ${statusIcon} ${doc.verificationStatus}
              ${doc.downloadUrl ? `<a href="#" onclick="window.open('http://localhost:8082${doc.downloadUrl}', '_blank'); return false;" style="margin-left: 10px; color: #007bff;">📥 View</a>` : ''}
            </span>
          </div>
        `;
      } else {
        return `
          <div style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee;">
            <span><strong>${reqDoc.name}:</strong></span>
            <span style="color: #dc3545; font-weight: bold;">❌ Not Uploaded</span>
          </div>
        `;
      }
    }).join('');

    const uploadedCount = documents.length;
    const verifiedCount = documents.filter(d => d.verificationStatus === 'VERIFIED' || d.verificationStatus === 'APPROVED').length;
    const totalRequired = requiredDocs.length;
    const completionPercentage = Math.round((uploadedCount / totalRequired) * 100);

    return `
      <div style="margin-bottom: 15px; padding: 10px; background: #f8f9fa; border-radius: 4px;">
        <strong>📊 Document Status: ${uploadedCount}/${totalRequired} uploaded (${verifiedCount} verified)</strong>
        <div style="background: #e9ecef; border-radius: 4px; height: 10px; margin: 8px 0;">
          <div style="background: ${completionPercentage === 100 ? '#28a745' : '#ffc107'}; height: 100%; width: ${completionPercentage}%; border-radius: 4px;"></div>
        </div>
      </div>
      <div style="max-height: 200px; overflow-y: auto;">
        ${docStatusHtml}
      </div>
      ${documents.length > 0 ? `
        <div style="margin-top: 10px; padding: 8px; background: #e7f3ff; border-radius: 4px; font-size: 12px;">
          <strong>💡 Tip:</strong> Click on "📥 View" to download and review the document
        </div>
      ` : ''}
    `;
  }

  getDocumentStatusHtml(shop: Shop): string {
    const requiredDocs = [
      'Business License',
      'GST Certificate', 
      'PAN Card',
      'Aadhar Card',
      'Address Proof',
      'Owner Photo',
      'Shop Photo'
    ];

    // Add business-specific documents
    if (shop.businessType === 'RESTAURANT') {
      requiredDocs.push('Food License');
      requiredDocs.push('FSSAI Certificate');
    } else if (shop.businessType === 'GROCERY') {
      requiredDocs.push('FSSAI Certificate');
    } else if (shop.businessType === 'PHARMACY') {
      requiredDocs.push('Drug License');
    }

    if (!shop.documents || shop.documents.length === 0) {
      return `
        <div style="padding: 10px; background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 4px;">
          <strong>⚠️ No documents uploaded</strong><br>
          <small>Shop owner needs to upload required documents for verification</small>
        </div>
      `;
    }

    const docStatusHtml = requiredDocs.map(docName => {
      const doc = shop.documents?.find(d => d.documentName.toLowerCase().includes(docName.toLowerCase()));
      if (doc) {
        const statusColor = doc.verificationStatus === 'VERIFIED' ? '#28a745' : 
                          doc.verificationStatus === 'REJECTED' ? '#dc3545' : '#ffc107';
        const statusIcon = doc.verificationStatus === 'VERIFIED' ? '✅' : 
                          doc.verificationStatus === 'REJECTED' ? '❌' : '⏳';
        
        return `
          <div style="display: flex; justify-content: space-between; padding: 5px 0; border-bottom: 1px solid #eee;">
            <span>${docName}</span>
            <span style="color: ${statusColor}; font-weight: bold;">${statusIcon} ${doc.verificationStatus}</span>
          </div>
        `;
      } else {
        return `
          <div style="display: flex; justify-content: space-between; padding: 5px 0; border-bottom: 1px solid #eee;">
            <span>${docName}</span>
            <span style="color: #dc3545; font-weight: bold;">❌ Missing</span>
          </div>
        `;
      }
    }).join('');

    const verifiedCount = shop.documents?.filter(d => d.verificationStatus === 'VERIFIED').length || 0;
    const totalRequired = requiredDocs.length;
    const completionPercentage = Math.round((verifiedCount / totalRequired) * 100);

    return `
      <div style="margin-bottom: 10px;">
        <strong>Document Verification Progress: ${verifiedCount}/${totalRequired} (${completionPercentage}%)</strong>
        <div style="background: #e9ecef; border-radius: 4px; height: 8px; margin: 5px 0;">
          <div style="background: #28a745; height: 100%; width: ${completionPercentage}%; border-radius: 4px;"></div>
        </div>
      </div>
      ${docStatusHtml}
    `;
  }
}