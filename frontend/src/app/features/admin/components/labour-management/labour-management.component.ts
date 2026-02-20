import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { LabourAdminService } from '../../services/labour.service';
import { PostEditDialogComponent } from '../post-edit-dialog/post-edit-dialog.component';
import { getImageUrl } from '../../../../core/utils/image-url.util';

interface LabourPost {
  id: number;
  name: string;
  phone: string;
  category: string;
  experience: string | null;
  location: string | null;
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
  selector: 'app-labour-management',
  templateUrl: './labour-management.component.html',
  styleUrls: ['./labour-management.component.scss']
})
export class LabourManagementComponent implements OnInit {
  posts: LabourPost[] = [];
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

  constructor(
    private labourService: LabourAdminService,
    private snackBar: MatSnackBar,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    this.loadPosts();
  }

  loadPosts(): void {
    this.loading = true;
    const request$ = this.activeTab === 'pending'
      ? this.labourService.getPendingPosts(this.currentPage, this.pageSize)
      : this.labourService.getAllPosts(this.currentPage, this.pageSize, this.searchText);

    request$.subscribe({
      next: (response) => {
        const data = response.data;
        this.posts = data?.content || [];
        this.totalPages = data?.totalPages || 0;
        this.totalItems = data?.totalItems || 0;
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading labour posts:', err);
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

  approvePost(post: LabourPost): void {
    this.labourService.approvePost(post.id).subscribe({
      next: () => {
        this.snackBar.open(`"${post.name}" approved`, 'OK', { duration: 3000 });
        this.loadPosts();
      },
      error: () => {
        this.snackBar.open('Failed to approve post', 'Close', { duration: 3000 });
      }
    });
  }

  rejectPost(post: LabourPost): void {
    if (confirm(`Reject "${post.name}"?`)) {
      this.labourService.rejectPost(post.id).subscribe({
        next: () => {
          this.snackBar.open(`"${post.name}" rejected`, 'OK', { duration: 3000 });
          this.loadPosts();
        },
        error: () => {
          this.snackBar.open('Failed to reject post', 'Close', { duration: 3000 });
        }
      });
    }
  }

  deletePost(post: LabourPost): void {
    if (confirm(`Delete "${post.name}" permanently?`)) {
      this.labourService.deletePost(post.id).subscribe({
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

  editPost(post: LabourPost): void {
    const dialogRef = this.dialog.open(PostEditDialogComponent, {
      width: '600px',
      maxHeight: '90vh',
      data: { postType: 'labour', post: { ...post } }
    });
    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.labourService.adminUpdatePost(post.id, result).subscribe({
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

  toggleFeatured(post: LabourPost): void {
    this.labourService.toggleFeatured(post.id).subscribe({
      next: (response) => {
        const updated = response.data;
        const isFeatured = updated?.featured;
        post.featured = isFeatured;
        this.snackBar.open(
          isFeatured ? `"${post.name}" marked as featured` : `"${post.name}" removed from featured`,
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

  openGallery(post: LabourPost): void {
    this.galleryImages = this.getAllImageUrls(post.imageUrls);
    if (this.galleryImages.length === 0) return;
    this.galleryIndex = 0;
    this.galleryTitle = post.name;
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

  getCategoryLabel(category: string): string {
    switch (category) {
      case 'PAINTER': return 'Painter';
      case 'ELECTRICIAN': return 'Electrician';
      case 'PLUMBER': return 'Plumber';
      case 'CARPENTER': return 'Carpenter';
      case 'CONTRACTOR': return 'Contractor';
      case 'MASON': return 'Mason';
      case 'WELDER': return 'Welder';
      case 'MECHANIC': return 'Mechanic';
      case 'DRIVER': return 'Driver';
      case 'CLEANER': return 'Cleaner';
      case 'GARDENER': return 'Gardener';
      case 'COOK': return 'Cook';
      case 'TAILOR': return 'Tailor';
      case 'AC_TECHNICIAN': return 'AC Technician';
      case 'CCTV_TECHNICIAN': return 'CCTV Technician';
      case 'COMPUTER_TECHNICIAN': return 'Computer Technician';
      case 'MOBILE_TECHNICIAN': return 'Mobile Technician';
      case 'HELPER': return 'Helper';
      case 'BIKE_REPAIR': return 'Bike Repair';
      case 'CAR_REPAIR': return 'Car Repair';
      case 'TYRE_PUNCTURE': return 'Tyre Puncture';
      case 'GENERAL_LABOUR': return 'General Labour';
      case 'OTHER': return 'Other';
      default: return category;
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
