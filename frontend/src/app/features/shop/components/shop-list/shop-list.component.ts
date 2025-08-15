import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Shop } from '../../../../core/models/shop.model';
import { ShopService } from '../../../../core/services/shop.service';
import { DocumentService } from '../../../../core/services/document.service';
import { AuthService } from '../../../../core/services/auth.service';
import { UserRole } from '../../../../core/models/auth.model';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-shop-list',
  templateUrl: './shop-list.component.html',
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

    /* Shop List Layout */
    .shops-list-container {
      margin-top: 0;
    }

    .shop-list-header {
      display: grid;
      grid-template-columns: 40px 2fr 1fr 1.5fr 1fr 100px 1fr 80px 40px;
      align-items: center;
      gap: 16px;
      padding: 12px 20px;
      background: #f8f9fa;
      border: 1px solid #e9ecef;
      border-bottom: 2px solid #dee2e6;
      font-weight: 600;
      font-size: 12px;
      color: #495057;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .shop-list-header > div {
      display: flex;
      align-items: center;
    }

    .header-name,
    .header-location {
      justify-content: flex-start;
    }

    .header-type,
    .header-products,
    .header-date,
    .header-status {
      justify-content: center;
    }

    .header-price {
      justify-content: flex-end;
    }

    .header-actions {
      justify-content: center;
    }

    .shops-list {
      display: flex;
      flex-direction: column;
      gap: 0;
      background: white;
      border: 1px solid #e9ecef;
      border-top: none;
      border-radius: 0 0 8px 8px;
      overflow: hidden;
    }

    .shop-list-item {
      background: white;
      border: none;
      border-bottom: 1px solid #f1f3f4;
      padding: 14px 20px;
      display: grid;
      grid-template-columns: 40px 2fr 1fr 1.5fr 1fr 100px 1fr 80px 40px;
      align-items: center;
      gap: 16px;
      transition: all 0.2s ease;
      cursor: pointer;
      min-height: 56px;
    }

    .shop-list-item:last-child {
      border-bottom: none;
    }

    .shop-list-item:hover {
      background: #f8f9fa;
      transform: none;
      box-shadow: none;
    }

    .shop-avatar {
      width: 40px;
      height: 40px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      flex-shrink: 0;
    }

    .shop-avatar mat-icon {
      font-size: 20px;
      width: 20px;
      height: 20px;
    }

    .shop-name-section {
      display: flex;
      flex-direction: column;
      gap: 2px;
      min-width: 0;
    }

    .shop-name {
      font-size: 14px;
      font-weight: 600;
      color: #1f2937;
      line-height: 1.3;
      margin: 0;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .shop-business {
      font-size: 12px;
      color: #6b7280;
      font-weight: 400;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .business-type-section {
      display: flex;
      justify-content: flex-start;
    }

    .location-section {
      display: flex;
      flex-direction: column;
      gap: 2px;
      min-width: 0;
    }

    .location {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 12px;
      color: #6b7280;
    }

    .location-icon {
      font-size: 14px;
      width: 14px;
      height: 14px;
      color: #9ca3af;
    }

    .postal-code {
      font-size: 11px;
      color: #9ca3af;
    }

    .product-count-section {
      display: flex;
      flex-direction: column;
      align-items: flex-start;
      gap: 2px;
    }

    .product-count {
      font-size: 12px;
      color: #6b7280;
      background: #f1f5f9;
      padding: 2px 6px;
      border-radius: 4px;
      white-space: nowrap;
    }

    .rating {
      display: flex;
      align-items: center;
      gap: 2px;
      font-size: 11px;
      color: #6b7280;
    }

    .star-icon {
      font-size: 12px;
      width: 12px;
      height: 12px;
      color: #fbbf24;
    }

    .date-section {
      font-size: 12px;
      color: #6b7280;
      text-align: center;
    }

    .status-section {
      display: flex;
      justify-content: center;
    }

    .price-section {
      text-align: right;
    }

    .delivery-fee {
      font-size: 14px;
      font-weight: 600;
      color: #1f2937;
    }

    .shop-actions {
      display: flex;
      justify-content: center;
    }

    .action-button {
      color: #6b7280;
      transition: all 0.2s ease;
      width: 32px;
      height: 32px;
    }

    .action-button:hover {
      color: #3b82f6;
      background: #f3f4f6;
    }

    // Status chips
    mat-chip {
      font-size: 11px;
      font-weight: 500;
      border-radius: 16px;
      padding: 4px 8px;
      min-height: auto;
      line-height: 1.2;
    }

    .status-pending {
      background-color: #fef3c7;
      color: #92400e;
      border: none;
    }

    .status-approved {
      background-color: #d1fae5;
      color: #065f46;
      border: none;
    }

    .status-rejected {
      background-color: #fee2e2;
      color: #991b1b;
      border: none;
    }

    .status-suspended {
      background-color: #f3f4f6;
      color: #4b5563;
      border: none;
    }

    .type-grocery {
      background-color: #ecfdf5;
      color: #065f46;
      border: none;
    }

    .type-pharmacy {
      background-color: #dbeafe;
      color: #1e40af;
      border: none;
    }

    .type-restaurant {
      background-color: #faf5ff;
      color: #7c2d12;
      border: none;
    }

    .type-general {
      background-color: #f8fafc;
      color: #64748b;
      border: none;
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
      border-top: 1px solid #e5e7eb;
      padding-top: 16px;
    }

    @media (max-width: 768px) {
      .shop-list-container {
        padding: 12px;
        margin: 0 -12px;
      }

      .shop-list-header {
        grid-template-columns: 32px 1fr auto;
        gap: 8px;
        padding: 12px 16px;
      }

      .header-type,
      .header-location,
      .header-products,
      .header-date,
      .header-status,
      .header-price {
        display: none;
      }

      .shops-list {
        gap: 1px;
        margin: 0;
        border-radius: 0;
      }

      .shop-list-item {
        grid-template-columns: 32px 1fr auto;
        gap: 8px;
        padding: 12px 16px;
        min-height: 50px;
      }

      .shop-avatar {
        width: 32px;
        height: 32px;
      }

      .shop-avatar mat-icon {
        font-size: 16px;
        width: 16px;
        height: 16px;
      }

      .business-type-section,
      .location-section,
      .product-count-section,
      .date-section,
      .status-section,
      .price-section {
        display: none;
      }

      .shop-name-section {
        flex: 1;
        min-width: 0;
      }

      .shop-name {
        font-size: 14px;
      }

      .shop-business {
        font-size: 11px;
      }

      .shop-actions {
        flex-shrink: 0;
      }

      .header {
        flex-direction: column;
        align-items: stretch;
        gap: 16px;
        padding: 0 4px;
      }

      .header-left h1 {
        font-size: 24px;
      }

      .filters-section {
        flex-direction: column;
        gap: 12px;
      }

      .search-box mat-form-field {
        width: 100%;
      }

      .filter-controls {
        flex-direction: column;
        gap: 12px;
      }

      .filter-controls mat-form-field {
        width: 100%;
      }

      .shop-list-item {
        flex-direction: row;
        align-items: flex-start;
        gap: 12px;
        padding: 16px;
        min-height: auto;
        position: relative;
      }

      .shop-image-container {
        width: 50px;
        height: 50px;
        margin-right: 0;
        align-self: flex-start;
      }

      .shop-avatar {
        width: 50px;
        height: 50px;
      }

      .shop-avatar mat-icon {
        font-size: 20px;
        width: 20px;
        height: 20px;
      }

      .shop-content {
        width: 100%;
        gap: 6px;
      }

      .shop-name {
        font-size: 16px;
      }

      .shop-details-info {
        flex-direction: column;
        align-items: flex-start;
        gap: 6px;
      }

      .shop-status-info {
        flex-direction: column;
        align-items: flex-start;
        gap: 6px;
      }

      .shop-actions {
        align-self: flex-start;
        margin-left: 0;
        position: absolute;
        top: 12px;
        right: 12px;
      }

      .shop-location-info {
        flex-direction: column;
        align-items: flex-start;
        gap: 4px;
      }
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
  
  // Remove table columns as we're using list view now
  // displayedColumns: string[] = ['shopId', 'name', 'owner', 'location', 'businessType', 'status', 'rating', 'created', 'actions'];
  
  // Pagination
  currentPage = 0;
  pageSize = 20;
  totalElements = 0;

  constructor(
    private shopService: ShopService,
    private documentService: DocumentService,
    private router: Router,
    private authService: AuthService
  ) {}

  ngOnInit() {
    // Check if password change is required first
    if (this.authService.isPasswordChangeRequired()) {
      this.router.navigate(['/auth/change-password']);
      return;
    }

    // Check user role and load appropriate content
    if (this.authService.isShopOwner()) {
      // Shop owners should see their own shop
      this.loadMyShop();
    } else {
      // Admins can see all shops
      this.selectedStatus = '';
      this.loadShops();
      this.loadCities();
    }
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

  loadMyShop() {
    this.loading = true;
    this.shopService.getMyShop().subscribe({
      next: (shop) => {
        this.shops = [shop]; // Show only the owner's shop
        this.totalElements = 1;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading my shop:', error);
        this.loading = false;
        // If shop not found, redirect to create shop
        if (error.status === 404) {
          Swal.fire({
            title: 'No Shop Found',
            text: 'You don\'t have a shop yet. Would you like to create one?',
            icon: 'info',
            showCancelButton: true,
            confirmButtonText: 'Create Shop',
            cancelButtonText: 'Later'
          }).then((result) => {
            if (result.isConfirmed) {
              this.router.navigate(['/shops/create']);
            }
          });
        }
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

  viewShopProducts(shop: Shop) {
    this.router.navigate(['/products/shop', shop.id]);
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

  getShopProductCount(shop: Shop): number {
    // This would ideally come from the backend API
    // For now, return a placeholder value
    return shop.productCount || 0;
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