import { Component, OnInit } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { JobAdminService } from '../../services/job.service';
import { getImageUrl } from '../../../../core/utils/image-url.util';

interface JobPost {
  id: number;
  jobTitle: string;
  companyName: string;
  phone: string;
  category: string;
  jobType: string;
  salary: string | null;
  salaryType: string | null;
  vacancies: number;
  location: string | null;
  description: string | null;
  requirements: string | null;
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
  selector: 'app-job-management',
  templateUrl: './job-management.component.html',
  styleUrls: ['./job-management.component.scss']
})
export class JobManagementComponent implements OnInit {
  posts: JobPost[] = [];
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
    private jobService: JobAdminService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadPosts();
  }

  loadPosts(): void {
    this.loading = true;
    const request$ = this.activeTab === 'pending'
      ? this.jobService.getPendingPosts(this.currentPage, this.pageSize)
      : this.jobService.getAllPosts(this.currentPage, this.pageSize);

    request$.subscribe({
      next: (response) => {
        const data = response.data;
        this.posts = data?.content || [];
        this.totalPages = data?.totalPages || 0;
        this.totalItems = data?.totalElements || data?.totalItems || 0;
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading job posts:', err);
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

  approvePost(post: JobPost): void {
    this.jobService.approvePost(post.id).subscribe({
      next: () => {
        this.snackBar.open(`"${post.jobTitle}" approved`, 'OK', { duration: 3000 });
        this.loadPosts();
      },
      error: () => {
        this.snackBar.open('Failed to approve post', 'Close', { duration: 3000 });
      }
    });
  }

  rejectPost(post: JobPost): void {
    const reason = prompt(`Reason for rejecting "${post.jobTitle}"? (optional)`);
    if (reason === null) return; // cancelled
    this.jobService.rejectPost(post.id, reason).subscribe({
      next: () => {
        this.snackBar.open(`"${post.jobTitle}" rejected`, 'OK', { duration: 3000 });
        this.loadPosts();
      },
      error: () => {
        this.snackBar.open('Failed to reject post', 'Close', { duration: 3000 });
      }
    });
  }

  deletePost(post: JobPost): void {
    if (confirm(`Delete "${post.jobTitle}" by ${post.companyName} permanently?`)) {
      this.jobService.deletePost(post.id).subscribe({
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

  openGallery(post: JobPost): void {
    this.galleryImages = this.getAllImageUrls(post.imageUrls);
    if (this.galleryImages.length === 0) return;
    this.galleryIndex = 0;
    this.galleryTitle = `${post.jobTitle} - ${post.companyName}`;
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
    const labels: Record<string, string> = {
      'SHOP_WORKER': 'Shop Worker', 'SALES_PERSON': 'Sales Person',
      'DELIVERY_BOY': 'Delivery Boy', 'SECURITY': 'Security',
      'CASHIER': 'Cashier', 'RECEPTIONIST': 'Receptionist',
      'ACCOUNTANT': 'Accountant', 'DRIVER': 'Driver',
      'COOK': 'Cook', 'HELPER': 'Helper',
      'TEACHER': 'Teacher', 'NURSE': 'Nurse',
      'TAILOR': 'Tailor', 'CLEANER': 'Cleaner',
      'WATCHMAN': 'Watchman', 'FARM_WORKER': 'Farm Worker',
      'COMPUTER_OPERATOR': 'Computer Operator', 'MANAGER': 'Manager',
      'ELECTRICIAN': 'Electrician', 'OTHER': 'Other'
    };
    return labels[category] || category;
  }

  getJobTypeLabel(jobType: string): string {
    const labels: Record<string, string> = {
      'FULL_TIME': 'Full Time', 'PART_TIME': 'Part Time',
      'CONTRACT': 'Contract', 'DAILY_WAGE': 'Daily Wage',
      'INTERNSHIP': 'Internship'
    };
    return labels[jobType] || jobType;
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'PENDING_APPROVAL': return 'Pending';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      case 'EXPIRED': return 'Expired';
      case 'DELETED': return 'Deleted';
      default: return status;
    }
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
