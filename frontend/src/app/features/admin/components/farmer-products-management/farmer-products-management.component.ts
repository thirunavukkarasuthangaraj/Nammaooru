import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { FarmerProductsAdminService } from '../../services/farmer-products.service';
import { PostEditDialogComponent } from '../post-edit-dialog/post-edit-dialog.component';
import { getImageUrl } from '../../../../core/utils/image-url.util';
import { SwalService } from '../../../../core/services/swal.service';

interface FarmerProduct {
  id: number;
  title: string;
  description: string;
  price: number | null;
  unit: string | null;
  imageUrls: string | null;
  sellerUserId: number;
  sellerName: string;
  sellerPhone: string;
  category: string;
  location: string;
  status: string;
  featured: boolean;
  isPaid: boolean;
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
  searchText = '';

  // Gallery lightbox
  galleryOpen = false;
  galleryImages: string[] = [];
  galleryIndex = 0;
  galleryTitle = '';

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
    private dialog: MatDialog,
    private swal: SwalService
  ) {}

  ngOnInit(): void {
    this.loadPosts();
  }

  loadPosts(): void {
    this.loading = true;
    const request$ = this.activeTab === 'pending'
      ? this.farmerProductsService.getPendingPosts(this.currentPage, this.pageSize)
      : this.farmerProductsService.getAllPosts(this.currentPage, this.pageSize, this.searchText);

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
        this.swal.toast('Failed to load farmer products', 'error');
      }
    });
  }

  onSearchChange(): void {
    this.currentPage = 0;
    this.loadPosts();
  }

  switchTab(tab: 'pending' | 'all'): void {
    this.activeTab = tab;
    this.currentPage = 0;
    this.loadPosts();
  }

  approvePost(post: FarmerProduct): void {
    this.farmerProductsService.approvePost(post.id).subscribe({
      next: () => {
        this.swal.toast(`"${post.title}" approved`, 'success');
        this.loadPosts();
      },
      error: () => {
        this.swal.toast('Failed to approve post', 'error');
      }
    });
  }

  rejectPost(post: FarmerProduct): void {
    if (confirm(`Reject "${post.title}"?`)) {
      this.farmerProductsService.rejectPost(post.id).subscribe({
        next: () => {
          this.swal.toast(`"${post.title}" rejected`, 'success');
          this.loadPosts();
        },
        error: () => {
          this.swal.toast('Failed to reject post', 'error');
        }
      });
    }
  }

  deletePost(post: FarmerProduct): void {
    if (confirm(`Delete "${post.title}" permanently?`)) {
      this.farmerProductsService.deletePost(post.id).subscribe({
        next: () => {
          this.swal.toast('Post deleted', 'success');
          this.loadPosts();
        },
        error: () => {
          this.swal.toast('Failed to delete post', 'error');
        }
      });
    }
  }

  editPost(post: FarmerProduct): void {
    const dialogRef = this.dialog.open(PostEditDialogComponent, {
      width: '600px',
      maxHeight: '90vh',
      data: { postType: 'farmer', post: { ...post } }
    });
    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.farmerProductsService.adminUpdatePost(post.id, result).subscribe({
          next: () => {
            this.swal.toast('Post updated', 'success');
            this.loadPosts();
          },
          error: () => {
            this.swal.toast('Failed to update post', 'error');
          }
        });
      }
    });
  }

  getImageUrl(path: string | null): string {
    return getImageUrl(path);
  }

  getFirstImageUrl(imageUrls: string | null): string {
    if (!imageUrls) return '';
    const first = imageUrls.split(',')[0]?.trim();
    return getImageUrl(first || null);
  }

  getAllImageUrls(imageUrls: string | null): string[] {
    if (!imageUrls) return [];
    return imageUrls.split(',').map(url => getImageUrl(url.trim())).filter(url => !!url);
  }

  getImageCount(imageUrls: string | null): number {
    if (!imageUrls) return 0;
    return imageUrls.split(',').filter(url => url.trim()).length;
  }

  openGallery(post: FarmerProduct): void {
    this.galleryImages = this.getAllImageUrls(post.imageUrls);
    if (this.galleryImages.length === 0) return;
    this.galleryIndex = 0;
    this.galleryTitle = post.title;
    this.galleryOpen = true;
  }

  closeGallery(): void {
    this.galleryOpen = false;
    this.galleryImages = [];
    this.galleryIndex = 0;
  }

  prevImage(): void {
    this.galleryIndex = this.galleryIndex > 0 ? this.galleryIndex - 1 : this.galleryImages.length - 1;
  }

  nextImage(): void {
    this.galleryIndex = this.galleryIndex < this.galleryImages.length - 1 ? this.galleryIndex + 1 : 0;
  }

  toggleFeatured(post: FarmerProduct): void {
    this.farmerProductsService.toggleFeatured(post.id).subscribe({
      next: (response) => {
        const updated = response.data;
        const isFeatured = updated?.featured;
        post.featured = isFeatured;
        this.swal.toast(
          isFeatured ? `"${post.title}" marked as featured` : `"${post.title}" removed from featured`,
          'success'
        );
      },
      error: () => {
        this.swal.toast('Failed to toggle featured', 'error');
      }
    });
  }

  onStatusChange(post: FarmerProduct, newStatus: string): void {
    if (newStatus === 'REMOVED') {
      if (!confirm(`Remove "${post.title}" permanently?`)) return;
      this.farmerProductsService.deletePost(post.id).subscribe({
        next: () => {
          this.swal.toast(`"${post.title}" removed`, 'success');
          this.loadPosts();
        },
        error: () => this.swal.toast('Failed to remove post', 'error')
      });
      return;
    }
    const label = this.statusOptions.find(o => o.value === newStatus)?.label || newStatus;
    this.farmerProductsService.changePostStatus(post.id, newStatus).subscribe({
      next: () => {
        this.swal.toast(`"${post.title}" → ${label}`, 'success');
        this.loadPosts();
      },
      error: () => this.swal.toast(`Failed to change status`, 'error')
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
