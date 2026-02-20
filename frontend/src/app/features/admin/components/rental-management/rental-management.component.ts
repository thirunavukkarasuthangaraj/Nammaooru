import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { RentalAdminService } from '../../services/rental.service';
import { PostEditDialogComponent } from '../post-edit-dialog/post-edit-dialog.component';
import { getImageUrl } from '../../../../core/utils/image-url.util';

interface RentalPost {
  id: number;
  title: string;
  description: string;
  price: number | null;
  priceUnit: string | null;
  imageUrls: string | null;
  sellerUserId: number;
  sellerName: string;
  sellerPhone: string;
  category: string;
  location: string;
  featured: boolean;
  isPaid: boolean;
  status: string;
  reportCount: number;
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
  selector: 'app-rental-management',
  templateUrl: './rental-management.component.html',
  styleUrls: ['./rental-management.component.scss']
})
export class RentalManagementComponent implements OnInit {
  posts: RentalPost[] = [];
  loading = true;
  activeTab: 'pending' | 'all' = 'pending';
  currentPage = 0;
  totalPages = 0;
  totalItems = 0;
  pageSize = 20;

  statusOptions: StatusOption[] = [
    { value: 'APPROVED', label: 'Approve', icon: 'check_circle', color: '#4caf50' },
    { value: 'REJECTED', label: 'Reject', icon: 'cancel', color: '#f44336' },
    { value: 'RENTED', label: 'Mark Rented', icon: 'vpn_key', color: '#9c27b0' },
    { value: 'HOLD', label: 'Hold', icon: 'pause_circle', color: '#ff9800' },
    { value: 'HIDDEN', label: 'Hide', icon: 'visibility_off', color: '#9e9e9e' },
    { value: 'CORRECTION_REQUIRED', label: 'Correction Required', icon: 'edit_note', color: '#2196f3' },
    { value: 'REMOVED', label: 'Remove', icon: 'delete_forever', color: '#b71c1c' }
  ];

  constructor(
    private rentalService: RentalAdminService,
    private snackBar: MatSnackBar,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    this.loadPosts();
  }

  loadPosts(): void {
    this.loading = true;
    const request$ = this.activeTab === 'pending'
      ? this.rentalService.getPendingPosts(this.currentPage, this.pageSize)
      : this.rentalService.getAllPosts(this.currentPage, this.pageSize);

    request$.subscribe({
      next: (response) => {
        const data = response.data;
        this.posts = data?.content || [];
        this.totalPages = data?.totalPages || 0;
        this.totalItems = data?.totalItems || 0;
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading rental posts:', err);
        this.loading = false;
        this.snackBar.open('Failed to load posts', 'Close', { duration: 3000 });
      }
    });
  }

  switchTab(tab: 'pending' | 'all'): void {
    this.activeTab = tab;
    this.currentPage = 0;
    this.loadPosts();
  }

  approvePost(post: RentalPost): void {
    this.rentalService.approvePost(post.id).subscribe({
      next: () => {
        this.snackBar.open(`"${post.title}" approved`, 'OK', { duration: 3000 });
        this.loadPosts();
      },
      error: () => {
        this.snackBar.open('Failed to approve post', 'Close', { duration: 3000 });
      }
    });
  }

  rejectPost(post: RentalPost): void {
    if (confirm(`Reject "${post.title}"?`)) {
      this.rentalService.rejectPost(post.id).subscribe({
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

  deletePost(post: RentalPost): void {
    if (confirm(`Delete "${post.title}" permanently?`)) {
      this.rentalService.deletePost(post.id).subscribe({
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

  editPost(post: RentalPost): void {
    const dialogRef = this.dialog.open(PostEditDialogComponent, {
      width: '600px',
      maxHeight: '90vh',
      data: { postType: 'rental', post: { ...post } }
    });
    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.rentalService.adminUpdatePost(post.id, result).subscribe({
          next: () => {
            this.snackBar.open('Post updated', 'OK', { duration: 3000 });
            this.loadPosts();
          },
          error: () => {
            this.snackBar.open('Failed to update post', 'Close', { duration: 3000 });
          }
        });
      }
    });
  }

  getImageUrl(imageUrls: string | null): string {
    if (!imageUrls) return '';
    const first = imageUrls.split(',')[0]?.trim();
    return getImageUrl(first || null);
  }

  toggleFeatured(post: RentalPost): void {
    this.rentalService.toggleFeatured(post.id).subscribe({
      next: (response) => {
        const updated = response.data;
        const isFeatured = updated?.featured;
        post.featured = isFeatured;
        this.snackBar.open(
          isFeatured ? `"${post.title}" marked as featured` : `"${post.title}" removed from featured`,
          'OK',
          { duration: 3000 }
        );
      },
      error: () => {
        this.snackBar.open('Failed to toggle featured', 'Close', { duration: 3000 });
      }
    });
  }

  onStatusChange(post: RentalPost, newStatus: string): void {
    if (newStatus === 'REMOVED') {
      if (!confirm(`Remove "${post.title}" permanently?`)) return;
      this.rentalService.deletePost(post.id).subscribe({
        next: () => {
          this.snackBar.open(`"${post.title}" removed`, 'OK', { duration: 3000 });
          this.loadPosts();
        },
        error: () => this.snackBar.open('Failed to remove post', 'Close', { duration: 3000 })
      });
      return;
    }
    if (newStatus === 'RENTED') {
      this.rentalService.markAsRented(post.id).subscribe({
        next: () => {
          this.snackBar.open(`"${post.title}" marked as rented`, 'OK', { duration: 3000 });
          this.loadPosts();
        },
        error: () => this.snackBar.open('Failed to mark as rented', 'Close', { duration: 3000 })
      });
      return;
    }
    const label = this.statusOptions.find(o => o.value === newStatus)?.label || newStatus;
    this.rentalService.changePostStatus(post.id, newStatus).subscribe({
      next: () => {
        this.snackBar.open(`"${post.title}" → ${label}`, 'OK', { duration: 3000 });
        this.loadPosts();
      },
      error: () => this.snackBar.open(`Failed to change status`, 'Close', { duration: 3000 })
    });
  }

  getAvailableStatuses(post: RentalPost): StatusOption[] {
    return this.statusOptions.filter(o => o.value !== post.status);
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'PENDING_APPROVAL': return 'warn';
      case 'APPROVED': return 'primary';
      case 'REJECTED': return 'accent';
      case 'RENTED': return '';
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
      case 'RENTED': return 'Rented';
      case 'HOLD': return 'On Hold';
      case 'HIDDEN': return 'Hidden';
      case 'CORRECTION_REQUIRED': return 'Correction Required';
      case 'FLAGGED': return 'Flagged';
      case 'REMOVED': return 'Removed';
      default: return status;
    }
  }

  getCategoryLabel(category: string): string {
    switch (category) {
      case 'SHOP': return 'Shop';
      case 'AUTO': return 'Auto';
      case 'BIKE': return 'Bike';
      case 'HOUSE': return 'House';
      case 'LAND': return 'Land';
      case 'EQUIPMENT': return 'Equipment';
      case 'FURNITURE': return 'Furniture';
      default: return category;
    }
  }

  getPriceUnitLabel(priceUnit: string | null): string {
    switch (priceUnit) {
      case 'per_hour': return '/hr';
      case 'per_day': return '/day';
      case 'per_month': return '/mo';
      default: return '';
    }
  }

  formatPrice(price: number | null, priceUnit: string | null): string {
    if (price === null || price === undefined) return 'Negotiable';
    return '\u20B9' + price.toLocaleString('en-IN') + this.getPriceUnitLabel(priceUnit);
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
