import { Component, OnInit } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MarketplaceAdminService } from '../../services/marketplace.service';
import { getImageUrl } from '../../../../core/utils/image-url.util';

interface ReportedPost {
  id: number;
  title: string;
  description: string;
  price: number | null;
  imageUrl: string | null;
  voiceUrl: string | null;
  sellerUserId: number;
  sellerName: string;
  sellerPhone: string;
  category: string;
  location: string;
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
  selector: 'app-reported-posts',
  templateUrl: './reported-posts.component.html',
  styleUrls: ['./reported-posts.component.scss']
})
export class ReportedPostsComponent implements OnInit {
  posts: ReportedPost[] = [];
  loading = true;
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
    private marketplaceService: MarketplaceAdminService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadReportedPosts();
  }

  loadReportedPosts(): void {
    this.loading = true;
    this.marketplaceService.getReportedPosts(this.currentPage, this.pageSize).subscribe({
      next: (response) => {
        const data = response.data;
        this.posts = data?.content || [];
        this.totalPages = data?.totalPages || 0;
        this.totalItems = data?.totalItems || 0;
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading reported posts:', err);
        this.loading = false;
        this.snackBar.open('Failed to load reported posts', 'Close', { duration: 3000 });
      }
    });
  }

  onStatusChange(post: ReportedPost, newStatus: string): void {
    if (newStatus === 'REMOVED') {
      if (!confirm(`Remove "${post.title}" permanently? This will delete the post.`)) {
        return;
      }
      this.marketplaceService.deletePost(post.id).subscribe({
        next: () => {
          this.snackBar.open(`"${post.title}" removed`, 'OK', { duration: 3000 });
          this.loadReportedPosts();
        },
        error: () => {
          this.snackBar.open('Failed to remove post', 'Close', { duration: 3000 });
        }
      });
      return;
    }

    const option = this.statusOptions.find(o => o.value === newStatus);
    const label = option?.label || newStatus;

    this.marketplaceService.changePostStatus(post.id, newStatus).subscribe({
      next: () => {
        this.snackBar.open(`"${post.title}" → ${label}`, 'OK', { duration: 3000 });
        this.loadReportedPosts();
      },
      error: () => {
        this.snackBar.open(`Failed to change status to ${label}`, 'Close', { duration: 3000 });
      }
    });
  }

  getImageUrl(path: string | null): string {
    return getImageUrl(path);
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'FLAGGED': return 'Flagged';
      case 'PENDING_APPROVAL': return 'Pending';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      case 'SOLD': return 'Sold';
      case 'HOLD': return 'On Hold';
      case 'HIDDEN': return 'Hidden';
      case 'CORRECTION_REQUIRED': return 'Correction Required';
      case 'REMOVED': return 'Removed';
      default: return status;
    }
  }

  getAvailableStatuses(post: ReportedPost): StatusOption[] {
    return this.statusOptions.filter(o => o.value !== post.status);
  }

  formatPrice(price: number | null): string {
    if (price === null || price === undefined) return 'Negotiable';
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
    this.loadReportedPosts();
  }
}
