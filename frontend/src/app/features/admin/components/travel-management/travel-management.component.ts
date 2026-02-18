import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { TravelAdminService } from '../../services/travel.service';
import { PostEditDialogComponent } from '../post-edit-dialog/post-edit-dialog.component';
import { getImageUrl } from '../../../../core/utils/image-url.util';

interface TravelPost {
  id: number;
  title: string;
  phone: string;
  vehicleType: string;
  fromLocation: string | null;
  toLocation: string | null;
  price: string | null;
  seatsAvailable: number | null;
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
  selector: 'app-travel-management',
  templateUrl: './travel-management.component.html',
  styleUrls: ['./travel-management.component.scss']
})
export class TravelManagementComponent implements OnInit {
  posts: TravelPost[] = [];
  loading = true;
  activeTab: 'pending' | 'all' = 'pending';
  currentPage = 0;
  totalPages = 0;
  totalItems = 0;
  pageSize = 20;

  // Gallery lightbox
  galleryOpen = false;
  galleryImages: string[] = [];
  galleryIndex = 0;
  galleryTitle = '';

  constructor(
    private travelService: TravelAdminService,
    private snackBar: MatSnackBar,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    this.loadPosts();
  }

  loadPosts(): void {
    this.loading = true;
    const request$ = this.activeTab === 'pending'
      ? this.travelService.getPendingPosts(this.currentPage, this.pageSize)
      : this.travelService.getAllPosts(this.currentPage, this.pageSize);

    request$.subscribe({
      next: (response) => {
        const data = response.data;
        this.posts = data?.content || [];
        this.totalPages = data?.totalPages || 0;
        this.totalItems = data?.totalItems || 0;
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading travel posts:', err);
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

  approvePost(post: TravelPost): void {
    this.travelService.approvePost(post.id).subscribe({
      next: () => {
        this.snackBar.open(`"${post.title}" approved`, 'OK', { duration: 3000 });
        this.loadPosts();
      },
      error: () => {
        this.snackBar.open('Failed to approve post', 'Close', { duration: 3000 });
      }
    });
  }

  rejectPost(post: TravelPost): void {
    if (confirm(`Reject "${post.title}"?`)) {
      this.travelService.rejectPost(post.id).subscribe({
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

  deletePost(post: TravelPost): void {
    if (confirm(`Delete "${post.title}" permanently?`)) {
      this.travelService.deletePost(post.id).subscribe({
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

  editPost(post: TravelPost): void {
    const dialogRef = this.dialog.open(PostEditDialogComponent, {
      width: '600px',
      maxHeight: '90vh',
      data: { postType: 'travel', post: { ...post } }
    });
    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.travelService.adminUpdatePost(post.id, result).subscribe({
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

  toggleFeatured(post: TravelPost): void {
    this.travelService.toggleFeatured(post.id).subscribe({
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

  openGallery(post: TravelPost): void {
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

  getVehicleTypeLabel(type: string): string {
    switch (type) {
      case 'CAR': return 'Car';
      case 'SMALL_BUS': return 'Small Bus';
      case 'BUS': return 'Bus';
      default: return type;
    }
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'PENDING_APPROVAL': return 'warn';
      case 'APPROVED': return 'primary';
      case 'REJECTED': return 'accent';
      case 'SOLD': return '';
      case 'FLAGGED': return 'warn';
      default: return '';
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'PENDING_APPROVAL': return 'Pending';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      case 'SOLD': return 'Unavailable';
      case 'FLAGGED': return 'Flagged';
      default: return status;
    }
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
