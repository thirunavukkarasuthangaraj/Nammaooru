import { Component, OnInit, OnDestroy, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatTableModule, MatTableDataSource } from '@angular/material/table';
import { MatPaginatorModule, MatPaginator, PageEvent } from '@angular/material/paginator';
import { MatSortModule } from '@angular/material/sort';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatDialogModule, MatDialog } from '@angular/material/dialog';
import { MatSnackBarModule, MatSnackBar } from '@angular/material/snack-bar';
import { MatSelectModule } from '@angular/material/select';
import { MatCardModule } from '@angular/material/card';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTooltipModule } from '@angular/material/tooltip';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import Swal from 'sweetalert2';

import { ShopService, Shop, ShopResponse } from '../../../../core/services/shop.service';

@Component({
  selector: 'app-shop-master',
  templateUrl: './shop-master.component.html',
  styleUrls: ['./shop-master.component.scss']
})
export class ShopMasterComponent implements OnInit, OnDestroy {
  @ViewChild(MatPaginator) paginator!: MatPaginator;

  displayedColumns: string[] = [
    'shopId', 'image', 'name', 'ownerName', 'city', 'status', 
    'rating', 'createdAt', 'actions'
  ];
  
  dataSource = new MatTableDataSource<Shop>([]);
  
  // Pagination
  totalElements = 0;
  pageSize = 10;
  pageIndex = 0;
  
  // Search
  searchTerm = '';
  
  // Loading states
  isLoading = false;
  
  // Form
  shopForm: FormGroup;
  isEditMode = false;
  editingShopId: number | null = null;
  showForm = false;
  
  // Document upload workflow
  showDocumentUpload = false;
  createdShopId: number | null = null;
  createdShopBusinessType = '';

  private destroy$ = new Subject<void>();

  constructor(
    private shopService: ShopService,
    private fb: FormBuilder,
    private dialog: MatDialog,
    private snackBar: MatSnackBar
  ) {
    this.shopForm = this.createShopForm();
  }

  ngOnInit() {
    this.loadShops();
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  createShopForm(): FormGroup {
    return this.fb.group({
      name: ['', [Validators.required, Validators.minLength(2)]],
      description: [''],
      ownerName: ['', [Validators.required, Validators.minLength(2)]],
      ownerEmail: ['', [Validators.required, Validators.email]],
      ownerPhone: ['', Validators.required],
      businessName: ['', Validators.required],
      businessType: ['GROCERY', Validators.required],
      addressLine1: ['', Validators.required],
      city: ['', Validators.required],
      state: ['', Validators.required],
      postalCode: ['', Validators.required],
      country: ['India'],
      minOrderAmount: [0, [Validators.min(0)]],
      deliveryRadius: [5, [Validators.min(1)]],
      deliveryFee: [0, [Validators.min(0)]],
      freeDeliveryAbove: [500],
      commissionRate: [15],
      latitude: [13.0827],
      longitude: [80.2707]
    });
  }

  loadShops() {
    this.isLoading = true;
    
    const params = {
      page: this.pageIndex,
      size: this.pageSize
    };

    // If there's a search term, use search endpoint
    const request = this.searchTerm 
      ? this.shopService.searchShops(this.searchTerm, this.pageIndex, this.pageSize)
      : this.shopService.getShops(params);
    
    request.pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response: ShopResponse) => {
          this.dataSource.data = response.content;
          this.totalElements = response.totalElements;
          this.isLoading = false;
        },
        error: (error) => {
          console.error('Error loading shops:', error);
          this.showError('Failed to load shops');
          this.isLoading = false;
        }
      });
  }

  onPageChange(event: PageEvent) {
    this.pageIndex = event.pageIndex;
    this.pageSize = event.pageSize;
    this.loadShops();
  }

  onSearch() {
    this.pageIndex = 0;
    this.loadShops();
  }

  onSearchClear() {
    this.searchTerm = '';
    this.pageIndex = 0;
    this.loadShops();
  }

  onAddNew() {
    this.isEditMode = false;
    this.editingShopId = null;
    this.shopForm.reset();
    this.shopForm.patchValue({
      businessType: 'GROCERY',
      minOrderAmount: 0,
      deliveryRadius: 5,
      deliveryFee: 0,
      freeDeliveryAbove: 500,
      commissionRate: 15,
      country: 'India',
      latitude: 13.0827,
      longitude: 80.2707
    });
    this.showForm = true;
  }

  onEdit(shop: Shop) {
    this.isEditMode = true;
    this.editingShopId = shop.id;
    this.shopForm.patchValue(shop);
    this.showForm = true;
    // Also set shop ID for document upload
    this.createdShopId = shop.id;
    this.createdShopBusinessType = shop.businessType;
  }

  onManageDocuments(shop: Shop) {
    // Set shop details for document upload
    this.createdShopId = shop.id;
    this.createdShopBusinessType = shop.businessType;
    this.showDocumentUpload = true;
    this.showForm = false;
  }

  onDelete(shop: Shop) {
    Swal.fire({
      title: 'Delete Shop',
      html: `Are you sure you want to delete <strong>"${shop.name}"</strong>?<br><br><small>This action cannot be undone.</small>`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, delete it!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        this.shopService.deleteShop(shop.id)
          .pipe(takeUntil(this.destroy$))
          .subscribe({
            next: () => {
              Swal.fire({
                title: 'Deleted!',
                text: 'Shop deleted successfully',
                icon: 'success',
                confirmButtonColor: '#3085d6'
              });
              this.loadShops();
            },
            error: (error) => {
              console.error('Error deleting shop:', error);
              Swal.fire({
                title: 'Error!',
                text: 'Failed to delete shop',
                icon: 'error',
                confirmButtonColor: '#3085d6'
              });
            }
          });
      }
    });
  }

  onApprove(shop: Shop) {
    this.shopService.approveShop(shop.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.showSuccess('Shop approved successfully');
          this.loadShops();
        },
        error: (error) => {
          console.error('Error approving shop:', error);
          this.showError('Failed to approve shop');
        }
      });
  }

  onReject(shop: Shop) {
    Swal.fire({
      title: 'Reject Shop',
      text: 'Please provide a reason for rejection:',
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
        this.shopService.rejectShop(shop.id, result.value.trim())
          .pipe(takeUntil(this.destroy$))
          .subscribe({
            next: () => {
              Swal.fire({
                title: 'Rejected!',
                text: 'Shop rejected successfully',
                icon: 'success',
                confirmButtonColor: '#3085d6'
              });
              this.loadShops();
            },
            error: (error) => {
              console.error('Error rejecting shop:', error);
              Swal.fire({
                title: 'Error!',
                text: 'Failed to reject shop',
                icon: 'error',
                confirmButtonColor: '#3085d6'
              });
            }
          });
      }
    });
  }

  onSave() {
    if (this.shopForm.valid) {
      const shopData = this.shopForm.value;
      
      const request = this.isEditMode && this.editingShopId
        ? this.shopService.updateShop(this.editingShopId, shopData)
        : this.shopService.createShop(shopData);

      request.pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (response: any) => {
            if (this.isEditMode) {
              this.showSuccess('Shop updated successfully! You can now manage documents.');
              this.showForm = false;
              this.showDocumentUpload = true;
              this.loadShops();
            } else {
              // New shop created - show document upload
              this.showSuccess('Shop created successfully! Now upload required documents.');
              // Now response should contain the shop data directly
              this.createdShopId = response.id;
              this.createdShopBusinessType = shopData.businessType;
              this.showForm = false;
              this.showDocumentUpload = true;
              console.log('Created shop ID:', this.createdShopId); // Debug log
            }
          },
          error: (error) => {
            console.error('Error saving shop:', error);
            this.showError('Failed to save shop');
          }
        });
    } else {
      this.showError('Please fill all required fields correctly');
    }
  }

  onCancel() {
    this.showForm = false;
    this.shopForm.reset();
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'APPROVED': return 'green';
      case 'PENDING': return 'orange';
      case 'REJECTED': return 'red';
      case 'SUSPENDED': return 'grey';
      default: return 'black';
    }
  }

  getStatusBackgroundColor(status: string): string {
    switch (status) {
      case 'APPROVED': return '#d4edda';
      case 'PENDING': return '#fff3cd';
      case 'REJECTED': return '#f8d7da';
      case 'SUSPENDED': return '#e2e3e5';
      default: return '#f8f9fa';
    }
  }

  getStatusTextColor(status: string): string {
    switch (status) {
      case 'APPROVED': return '#155724';
      case 'PENDING': return '#856404';
      case 'REJECTED': return '#721c24';
      case 'SUSPENDED': return '#383d41';
      default: return '#495057';
    }
  }

  formatDate(dateString: string): string {
    return new Date(dateString).toLocaleDateString();
  }

  private showSuccess(message: string) {
    this.snackBar.open(message, 'Close', {
      duration: 3000,
      panelClass: ['success-snackbar']
    });
  }

  private showError(message: string) {
    this.snackBar.open(message, 'Close', {
      duration: 5000,
      panelClass: ['error-snackbar']
    });
  }

  onDocumentsChanged(documents: any[]) {
    console.log('Documents updated:', documents);
    // You can add logic here to update shop verification status based on documents
  }

  finishShopCreation() {
    this.showDocumentUpload = false;
    this.createdShopId = null;
    this.createdShopBusinessType = '';
    this.loadShops();
    this.showSuccess('Shop creation completed successfully!');
  }

  skipDocumentUpload() {
    Swal.fire({
      title: 'Skip Document Upload?',
      text: 'Documents can be uploaded later, but the shop will remain in PENDING status until documents are verified.',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#3085d6',
      cancelButtonColor: '#6c757d',
      confirmButtonText: 'Skip for Now',
      cancelButtonText: 'Continue Uploading'
    }).then((result) => {
      if (result.isConfirmed) {
        this.finishShopCreation();
      }
    });
  }

  /**
   * Get shop image URL - prioritize shop photo, fallback to owner photo, then default
   */
  getShopImageUrl(shop: Shop): string {
    // First try to find shop photo from documents
    if (shop.documents && shop.documents.length > 0) {
      const shopPhoto = shop.documents.find(doc => 
        doc.documentType === 'SHOP_PHOTO' && doc.downloadUrl && doc.downloadUrl.trim()
      );
      if (shopPhoto && shopPhoto.downloadUrl) {
        return `http://localhost:8082${shopPhoto.downloadUrl}`;
      }

      // Fallback to owner photo
      const ownerPhoto = shop.documents.find(doc => 
        doc.documentType === 'OWNER_PHOTO' && doc.downloadUrl && doc.downloadUrl.trim()
      );
      if (ownerPhoto && ownerPhoto.downloadUrl) {
        return `http://localhost:8082${ownerPhoto.downloadUrl}`;
      }
    }

    // Check if shop has images array (legacy support)
    if (shop.images && shop.images.length > 0 && shop.images[0].imageUrl) {
      const imageUrl = shop.images[0].imageUrl.trim();
      if (imageUrl) {
        return imageUrl;
      }
    }

    // Default placeholder based on business type
    return this.getDefaultShopImage(shop.businessType);
  }

  /**
   * Get default placeholder image based on business type
   */
  private getDefaultShopImage(businessType: string): string {
    // For now, return a professional SVG placeholder for each business type
    switch (businessType?.toUpperCase()) {
      case 'GROCERY':
        return this.createSvgPlaceholder('🛒', '#4CAF50');
      case 'PHARMACY':
        return this.createSvgPlaceholder('💊', '#2196F3');
      case 'RESTAURANT':
        return this.createSvgPlaceholder('🍽️', '#FF5722');
      case 'GENERAL':
        return this.createSvgPlaceholder('🏪', '#9C27B0');
      default:
        return this.createSvgPlaceholder('🏬', '#607D8B');
    }
  }

  /**
   * Create an SVG placeholder with emoji and color
   */
  private createSvgPlaceholder(emoji: string, color: string): string {
    const svg = `
      <svg width="50" height="50" viewBox="0 0 50 50" xmlns="http://www.w3.org/2000/svg">
        <rect width="50" height="50" fill="${color}" opacity="0.1" rx="8"/>
        <rect width="50" height="50" fill="none" stroke="${color}" stroke-width="1" rx="8"/>
        <text x="25" y="32" text-anchor="middle" font-size="20" fill="${color}">${emoji}</text>
      </svg>
    `;
    // Use encodeURIComponent instead of btoa to handle Unicode characters
    return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
  }

  /**
   * Handle image loading error - show default placeholder
   */
  onImageError(event: any): void {
    const img = event.target as HTMLImageElement;
    if (img && img.parentElement) {
      // Try to get business type from the shop row
      const row = img.closest('tr');
      let businessType = 'GENERAL';
      
      if (row) {
        const shopNameCell = row.querySelector('td:nth-child(3)'); // Name column
        if (shopNameCell) {
          const businessTypeElement = shopNameCell.querySelector('small');
          if (businessTypeElement) {
            businessType = businessTypeElement.textContent?.trim() || 'GENERAL';
          }
        }
      }
      
      // Set appropriate placeholder based on business type
      img.src = this.getDefaultShopImage(businessType);
      img.alt = 'Shop placeholder';
    }
  }
}