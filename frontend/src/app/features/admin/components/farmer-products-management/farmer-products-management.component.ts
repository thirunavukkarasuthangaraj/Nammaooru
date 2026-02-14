import { Component, OnInit } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { FarmerProductsAdminService } from '../../services/farmer-products.service';
import { getImageUrl } from '../../../../core/utils/image-url.util';

interface FarmerProduct {
  id: number;
  title: string;
  description: string;
  price: number | null;
  unit: string | null;
  imageUrl: string | null;
  sellerUserId: number;
  sellerName: string;
  sellerPhone: string;
  category: string;
  location: string;
  status: string;
  createdAt: string;
  updatedAt: string;
}

interface StatusOption {
  value: string;
  label: string;
  icon: string;
  color: string;
}

@Component({
  selector: 'app-farmer-products-management',
  templateUrl: './farmer-products-management.component.html',
  styleUrls: ['./farmer-products-management.component.scss']
})
export class FarmerProductsManagementComponent implements OnInit {
  posts: FarmerProduct[] = [];
  loading = true;
  activeTab: 'pending' | 'all' = 'pending';
  currentPage = 0;
  totalPages = 0;
  totalItems = 0;
  pageSize = 20;

  statusOptions: StatusOption[] = [
    { value: 'APPROVED', label: 'Approve', icon: 'check_circle', color: '#4caf50' },
    { value: 'REJECTED', label: 'Reject', icon: 'cancel', color: '#f44336' },
    { value: 'HOLD', label: 'Hold', icon: 'pause_circle', color: '#ff9800' },
    { value: 'HIDDEN', label: 'Hide', icon: 'visibility_off', color: '#9e9e9e' },
    { value: 'CORRECTION_REQUIRED', label: 'Correction Required', icon: 'edit_note', color: '#2196f3' },
    { value: 'REMOVED', label: 'Remove', icon: 'delete_forever', color: '#b71c1c' }
  ];

  constructor(
    private farmerProductsService: FarmerProductsAdminService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadPosts();
  }

  loadPosts(): void {
    this.loading = true;
    const request$ = this.activeTab === 'pending'
      ? this.farmerProductsService.getPendingPosts(this.currentPage, this.pageSize)
      : this.farmerProductsService.getAllPosts(this.currentPage, this.pageSize);

    request$.subscribe({
      next: (response) => {
        const data = response.data;
        this.posts = data?.content || [];
        this.totalPages = data?.totalPages || 0;
        this.totalItems = data?.totalItems || 0;
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading farmer products:', err);
        this.loading = false;
        this.snackBar.open('Failed to load farmer products', 'Close', { duration: 3000 });
      }
    });
  }

  switchTab(tab: 'pending' | 'all'): void {
    this.activeTab = tab;
    this.currentPage = 0;
    this.loadPosts();
  }

  approvePost(post: FarmerProduct): void {
    this.farmerProductsService.approvePost(post.id).subscribe({
      next: () => {
        this.snackBar.open(`"${post.title}" approved`, 'OK', { duration: 3000 });
        this.loadPosts();
      },
      error: () => {
        this.snackBar.open('Failed to approve post', 'Close', { duration: 3000 });
      }
    });
  }

  rejectPost(post: FarmerProduct): void {
    if (confirm(`Reject "${post.title}"?`)) {
      this.farmerProductsService.rejectPost(post.id).subscribe({
        next: () => {
          this.snackBar.open(`"${post.title}" rejected`, 'OK', { duration: 3000 });
          this.loadPosts();
        },
        error: () => {
          this.snackBar.open('Failed to reject post', 'Close', { duration: 3000 });
        }
      });
    }
  }

  deletePost(post: FarmerProduct): void {
    if (confirm(`Delete "${post.title}" permanently?`)) {
      this.farmerProductsService.deletePost(post.id).subscribe({
        next: () => {
          this.snackBar.open('Post deleted', 'OK', { duration: 3000 });
          this.loadPosts();
        },
        error: () => {
          this.snackBar.open('Failed to delete post', 'Close', { duration: 3000 });
        }
      });
    }
  }

  getImageUrl(path: string | null): string {
    return getImageUrl(path);
  }

  onStatusChange(post: FarmerProduct, newStatus: string): void {
    if (newStatus === 'REMOVED') {
      if (!confirm(`Remove "${post.title}" permanently?`)) return;
      this.farmerProductsService.deletePost(post.id).subscribe({
        next: () => {
          this.snackBar.open(`"${post.title}" removed`, 'OK', { duration: 3000 });
          this.loadPosts();
        },
        error: () => this.snackBar.open('Failed to remove post', 'Close', { duration: 3000 })
      });
      return;
    }
    const label = this.statusOptions.find(o => o.value === newStatus)?.label || newStatus;
    this.farmerProductsService.changePostStatus(post.id, newStatus).subscribe({
      next: () => {
        this.snackBar.open(`"${post.title}" → ${label}`, 'OK', { duration: 3000 });
        this.loadPosts();
      },
      error: () => this.snackBar.open(`Failed to change status`, 'Close', { duration: 3000 })
    });
  }

  getAvailableStatuses(post: FarmerProduct): StatusOption[] {
    return this.statusOptions.filter(o => o.value !== post.status);
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'PENDING_APPROVAL': return 'warn';
      case 'APPROVED': return 'primary';
      case 'REJECTED': return 'accent';
      case 'SOLD': return '';
      case 'HOLD': return 'warn';
      case 'HIDDEN': return '';
      case 'CORRECTION_REQUIRED': return 'primary';
      case 'FLAGGED': return 'warn';
      default: return '';
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'PENDING_APPROVAL': return 'Pending';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      case 'SOLD': return 'Sold';
      case 'HOLD': return 'On Hold';
      case 'HIDDEN': return 'Hidden';
      case 'CORRECTION_REQUIRED': return 'Correction Required';
      case 'FLAGGED': return 'Flagged';
      case 'REMOVED': return 'Removed';
      default: return status;
    }
  }

  formatPrice(price: number | null, unit: string | null): string {
    if (price === null || price === undefined) return 'Negotiable';
    const formatted = '\u20B9' + price.toLocaleString('en-IN');
    return unit ? `${formatted}/${unit}` : formatted;
  }

  formatDate(dateStr: string): string {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  onPageChange(page: number): void {
    this.currentPage = page;
    this.loadPosts();
  }
}
