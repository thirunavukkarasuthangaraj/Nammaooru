import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { LocalShopsAdminService } from '../../services/local-shops.service';
import { PostEditDialogComponent } from '../post-edit-dialog/post-edit-dialog.component';
import { getImageUrl } from '../../../../core/utils/image-url.util';

interface LocalShopPost {
  id: number;
  shopName: string;
  phone: string;
  category: string;
  address: string | null;
  timings: string | null;
  description: string | null;
  imageUrls: string | null;
  sellerUserId: number;
  sellerName: string;
  reportCount: number;
  featured: boolean;
  isPaid: boolean;
  status: string;
  createdAt: string;
  updatedAt: string;
}

@Component({
  selector: 'app-local-shops-management',
  templateUrl: './local-shops-management.component.html',
  styleUrls: ['./local-shops-management.component.scss']
})
export class LocalShopsManagementComponent implements OnInit {
  posts: LocalShopPost[] = [];
  loading = true;
  activeTab: 'pending' | 'all' = 'pending';
  currentPage = 0;
  totalPages = 0;
  totalItems = 0;
  pageSize = 20;
  searchText = '';

  galleryOpen = false;
  galleryImages: string[] = [];
  galleryIndex = 0;
  galleryTitle = '';

  constructor(
    private service: LocalShopsAdminService,
    private snackBar: MatSnackBar,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    this.loadPosts();
  }

  loadPosts(): void {
    this.loading = true;
    const request$ = this.activeTab === 'pending'
      ? this.service.getPendingPosts(this.currentPage, this.pageSize)
      : this.service.getAllPosts(this.currentPage, this.pageSize, this.searchText);

    request$.subscribe({
      next: (response) => {
        const data = response.data;
        this.posts = data?.content || [];
        this.totalPages = data?.totalPages || 0;
        this.totalItems = data?.totalItems || 0;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.snackBar.open('Failed to load posts', 'Close', { duration: 3000 });
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

  approvePost(post: LocalShopPost): void {
    this.service.approvePost(post.id).subscribe({
      next: () => {
        this.snackBar.open(`"${post.shopName}" approved`, 'OK', { duration: 3000 });
        this.loadPosts();
      },
      error: () => this.snackBar.open('Failed to approve', 'Close', { duration: 3000 })
    });
  }

  rejectPost(post: LocalShopPost): void {
    if (confirm(`Reject "${post.shopName}"?`)) {
      this.service.rejectPost(post.id).subscribe({
        next: () => {
          this.snackBar.open(`"${post.shopName}" rejected`, 'OK', { duration: 3000 });
          this.loadPosts();
        },
        error: () => this.snackBar.open('Failed to reject', 'Close', { duration: 3000 })
      });
    }
  }

  deletePost(post: LocalShopPost): void {
    if (confirm(`Delete "${post.shopName}" permanently?`)) {
      this.service.deletePost(post.id).subscribe({
        next: () => {
          this.snackBar.open('Post deleted', 'OK', { duration: 3000 });
          this.loadPosts();
        },
        error: () => this.snackBar.open('Failed to delete', 'Close', { duration: 3000 })
      });
    }
  }

  editPost(post: LocalShopPost): void {
    const dialogRef = this.dialog.open(PostEditDialogComponent, {
      width: '600px',
      maxHeight: '90vh',
      data: { postType: 'localShop', post: { ...post } }
    });
    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.service.adminUpdatePost(post.id, result).subscribe({
          next: () => {
            this.snackBar.open('Post updated', 'OK', { duration: 3000 });
            this.loadPosts();
          },
          error: () => this.snackBar.open('Failed to update', 'Close', { duration: 3000 })
        });
      }
    });
  }

  toggleFeatured(post: LocalShopPost): void {
    this.service.toggleFeatured(post.id).subscribe({
      next: (response) => {
        const updated = response.data;
        post.featured = updated?.featured;
        this.snackBar.open(
          post.featured ? `"${post.shopName}" marked as featured` : `"${post.shopName}" removed from featured`,
          'OK', { duration: 3000 }
        );
      },
      error: () => this.snackBar.open('Failed to toggle featured', 'Close', { duration: 3000 })
    });
  }

  getCategoryLabel(category: string): string {
    const labels: Record<string, string> = {
      GROCERY: 'Grocery', MEDICAL: 'Medical', HARDWARE: 'Hardware',
      ELECTRONICS: 'Electronics', CLOTHING: 'Clothing', STATIONERY: 'Stationery',
      RESTAURANT: 'Restaurant', BAKERY: 'Bakery', VEGETABLES: 'Vegetables',
      MEAT_FISH: 'Meat / Fish', SALON: 'Salon', GYM: 'Gym',
      LAUNDRY: 'Laundry', TAILORING: 'Tailoring', PRINTING: 'Printing',
      MOBILE_SHOP: 'Mobile Shop', COMPUTER_SHOP: 'Computer Shop',
      AUTO_PARTS: 'Auto Parts', PETROL_BUNK: 'Petrol Bunk',
      JEWELLERY: 'Jewellery', COURIER: 'Courier', OTHER: 'Other'
    };
    return labels[category] || category;
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'PENDING_APPROVAL': return 'warn';
      case 'APPROVED': return 'primary';
      case 'REJECTED': return 'accent';
      case 'FLAGGED': return 'warn';
      default: return '';
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'PENDING_APPROVAL': return 'Pending';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      case 'SOLD': return 'Closed';
      case 'FLAGGED': return 'Flagged';
      default: return status;
    }
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

  openGallery(post: LocalShopPost): void {
    this.galleryImages = this.getAllImageUrls(post.imageUrls);
    if (this.galleryImages.length === 0) return;
    this.galleryIndex = 0;
    this.galleryTitle = post.shopName;
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

  formatDate(dateStr: string): string {
    if (!dateStr) return '';
    return new Date(dateStr).toLocaleDateString('en-IN', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  }

  onPageChange(page: number): void {
    this.currentPage = page;
    this.loadPosts();
  }
}
