import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { RealEstateAdminService } from '../../services/real-estate.service';
import { PostEditDialogComponent } from '../post-edit-dialog/post-edit-dialog.component';
import { getImageUrl } from '../../../../core/utils/image-url.util';

interface RealEstatePost {
  id: number;
  title: string;
  description: string;
  propertyType: string;
  listingType: string;
  price: number | null;
  areaSqft: number | null;
  bedrooms: number | null;
  bathrooms: number | null;
  location: string;
  imageUrls: string | null;
  videoUrl: string | null;
  ownerUserId: number;
  ownerName: string;
  ownerPhone: string;
  viewsCount: number;
  isFeatured: boolean;
  status: string;
  createdAt: string;
  updatedAt: string;
}

@Component({
  selector: 'app-real-estate-management',
  templateUrl: './real-estate-management.component.html',
  styleUrls: ['./real-estate-management.component.scss']
})
export class RealEstateManagementComponent implements OnInit {
  posts: RealEstatePost[] = [];
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
    private realEstateService: RealEstateAdminService,
    private snackBar: MatSnackBar,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    this.loadPosts();
  }

  loadPosts(): void {
    this.loading = true;
    const request$ = this.activeTab === 'pending'
      ? this.realEstateService.getPendingPosts(this.currentPage, this.pageSize)
      : this.realEstateService.getAllPosts(this.currentPage, this.pageSize);

    request$.subscribe({
      next: (response) => {
        const data = response.data;
        this.posts = data?.content || [];
        this.totalPages = data?.totalPages || 0;
        this.totalItems = data?.totalItems || 0;
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading real estate posts:', err);
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

  approvePost(post: RealEstatePost): void {
    this.realEstateService.approvePost(post.id).subscribe({
      next: () => {
        this.snackBar.open(`"${post.title}" approved`, 'OK', { duration: 3000 });
        this.loadPosts();
      },
      error: () => {
        this.snackBar.open('Failed to approve post', 'Close', { duration: 3000 });
      }
    });
  }

  rejectPost(post: RealEstatePost): void {
    if (confirm(`Reject "${post.title}"?`)) {
      this.realEstateService.rejectPost(post.id).subscribe({
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

  deletePost(post: RealEstatePost): void {
    if (confirm(`Delete "${post.title}" permanently?`)) {
      this.realEstateService.deletePost(post.id).subscribe({
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

  editPost(post: RealEstatePost): void {
    const dialogRef = this.dialog.open(PostEditDialogComponent, {
      width: '600px',
      maxHeight: '90vh',
      data: { postType: 'realEstate', post: { ...post } }
    });
    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.realEstateService.adminUpdatePost(post.id, result).subscribe({
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

  openGallery(post: RealEstatePost): void {
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

  getPropertyTypeLabel(type: string): string {
    switch (type) {
      case 'LAND': return 'Land';
      case 'HOUSE': return 'House';
      case 'APARTMENT': return 'Apartment';
      case 'VILLA': return 'Villa';
      case 'COMMERCIAL': return 'Commercial';
      case 'PLOT': return 'Plot';
      case 'FARM_LAND': return 'Farm Land';
      case 'PG_HOSTEL': return 'PG/Hostel';
      default: return type;
    }
  }

  getListingTypeLabel(type: string): string {
    return type === 'FOR_RENT' ? 'For Rent' : 'For Sale';
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'PENDING_APPROVAL': return 'warn';
      case 'APPROVED': return 'primary';
      case 'REJECTED': return 'accent';
      case 'SOLD': return '';
      case 'RENTED': return '';
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
      case 'RENTED': return 'Rented';
      case 'FLAGGED': return 'Flagged';
      default: return status;
    }
  }

  formatPrice(price: number | null): string {
    if (price === null || price === undefined) return 'Negotiable';
    if (price >= 10000000) {
      return '\u20B9' + (price / 10000000).toFixed(2) + ' Cr';
    } else if (price >= 100000) {
      return '\u20B9' + (price / 100000).toFixed(2) + ' L';
    }
    return '\u20B9' + price.toLocaleString('en-IN');
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
