import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { ShopService } from '../../../../core/services/shop.service';
import { Shop } from '../../../../core/models/shop.model';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-shop-approvals-list',
  templateUrl: './shop-approvals-list.component.html',
  styleUrls: ['./shop-approvals-list.component.scss']
})
export class ShopApprovalsListComponent implements OnInit {
  shops: Shop[] = [];
  stats: any = null;
  loading = true;
  
  // Pagination
  totalElements = 0;
  pageSize = 10;
  currentPage = 0;
  
  // Filters
  searchQuery = '';
  statusFilter = 'PENDING';
  businessTypeFilter = '';

  constructor(
    private shopService: ShopService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadData();
    this.loadStats();
  }

  loadData(): void {
    this.loading = true;
    
    const params = {
      page: this.currentPage,
      size: this.pageSize,
      search: this.searchQuery || undefined,
      status: this.statusFilter || undefined,
      businessType: this.businessTypeFilter || undefined
    };

    this.shopService.getPendingShops(params).subscribe({
      next: (response) => {
        this.shops = response.content;
        this.totalElements = response.totalElements;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading shops:', error);
        this.loading = false;
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load shops. Please try again.',
          icon: 'error',
          confirmButtonColor: '#667eea'
        });
      }
    });
  }

  loadStats(): void {
    this.shopService.getApprovalStats().subscribe({
      next: (stats) => {
        this.stats = stats;
      },
      error: (error) => {
        console.error('Error loading stats:', error);
      }
    });
  }

  applyFilters(): void {
    this.currentPage = 0;
    this.loadData();
  }

  clearFilters(): void {
    this.searchQuery = '';
    this.statusFilter = 'PENDING';
    this.businessTypeFilter = '';
    this.currentPage = 0;
    this.loadData();
  }

  onPageChange(event: any): void {
    this.currentPage = event.pageIndex;
    this.pageSize = event.pageSize;
    this.loadData();
  }

  refreshData(): void {
    this.loadData();
    this.loadStats();
  }

  viewShop(shop: Shop): void {
    this.router.navigate(['/shops', shop.id, 'approval']);
  }

  editShop(shop: Shop): void {
    this.router.navigate(['/shops', shop.id, 'edit']);
  }

  approveShop(shop: Shop): void {
    Swal.fire({
      title: 'Approve Shop',
      text: `Are you sure you want to approve "${shop.name}"?`,
      input: 'textarea',
      inputLabel: 'Approval Notes (Optional)',
      inputPlaceholder: 'Enter any notes for the approval...',
      icon: 'question',
      showCancelButton: true,
      confirmButtonColor: '#10b981',
      cancelButtonColor: '#6b7280',
      confirmButtonText: 'Yes, approve it!',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed) {
        const notes = result.value?.trim();
        this.shopService.approveShop(shop.id, notes).subscribe({
          next: () => {
            Swal.fire({
              title: 'Approved!',
              text: `Shop "${shop.name}" has been approved successfully.`,
              icon: 'success',
              confirmButtonColor: '#667eea'
            });
            this.refreshData();
          },
          error: (error) => {
            console.error('Error approving shop:', error);
            Swal.fire({
              title: 'Error!',
              text: `Failed to approve shop "${shop.name}". Please try again.`,
              icon: 'error',
              confirmButtonColor: '#667eea'
            });
          }
        });
      }
    });
  }

  rejectShop(shop: Shop): void {
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
      confirmButtonColor: '#ef4444',
      cancelButtonColor: '#6b7280',
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
              confirmButtonColor: '#667eea'
            });
            this.refreshData();
          },
          error: (error) => {
            console.error('Error rejecting shop:', error);
            Swal.fire({
              title: 'Error!',
              text: `Failed to reject shop "${shop.name}". Please try again.`,
              icon: 'error',
              confirmButtonColor: '#667eea'
            });
          }
        });
      }
    });
  }

  getShopLogo(shop: Shop): string | null {
    if (!shop.images || shop.images.length === 0) {
      return null;
    }
    
    const logoImage = shop.images.find(img => img.imageType === 'LOGO' && img.isPrimary);
    if (logoImage) {
      const imageUrl = logoImage.imageUrl;
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return imageUrl;
      }
      return `http://localhost:8082${imageUrl}`;
    }
    
    return null;
  }

  getStatusClass(status: string): string {
    switch(status?.toUpperCase()) {
      case 'PENDING': return 'status-pending';
      case 'APPROVED': return 'status-approved';
      case 'REJECTED': return 'status-rejected';
      default: return 'status-pending';
    }
  }

  getStatusIcon(status: string): string {
    switch(status?.toUpperCase()) {
      case 'PENDING': return 'schedule';
      case 'APPROVED': return 'check_circle';
      case 'REJECTED': return 'cancel';
      default: return 'schedule';
    }
  }

  getStatusDisplay(status: string): string {
    switch(status?.toUpperCase()) {
      case 'PENDING': return 'Pending';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      default: return status || 'Unknown';
    }
  }

  getBusinessTypeDisplay(type: string): string {
    switch(type?.toUpperCase()) {
      case 'GROCERY': return 'Grocery';
      case 'PHARMACY': return 'Pharmacy';
      case 'RESTAURANT': return 'Restaurant';
      case 'GENERAL': return 'General';
      default: return type || 'General';
    }
  }

  getBusinessTypeClass(type: string): string {
    switch(type?.toUpperCase()) {
      case 'GROCERY': return 'business-type-grocery';
      case 'PHARMACY': return 'business-type-pharmacy';
      case 'RESTAURANT': return 'business-type-restaurant';
      case 'GENERAL': return 'business-type-general';
      default: return 'business-type-general';
    }
  }
}