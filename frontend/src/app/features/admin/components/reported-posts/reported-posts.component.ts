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

  approvePost(post: ReportedPost): void {
    this.marketplaceService.approvePost(post.id).subscribe({
      next: () => {
        this.snackBar.open(`"${post.title}" approved`, 'OK', { duration: 3000 });
        this.loadReportedPosts();
      },
      error: () => {
        this.snackBar.open('Failed to approve post', 'Close', { duration: 3000 });
      }
    });
  }

  rejectPost(post: ReportedPost): void {
    if (confirm(`Reject "${post.title}"?`)) {
      this.marketplaceService.rejectPost(post.id).subscribe({
        next: () => {
          this.snackBar.open(`"${post.title}" rejected`, 'OK', { duration: 3000 });
          this.loadReportedPosts();
        },
        error: () => {
          this.snackBar.open('Failed to reject post', 'Close', { duration: 3000 });
        }
      });
    }
  }

  deletePost(post: ReportedPost): void {
    if (confirm(`Delete "${post.title}" permanently?`)) {
      this.marketplaceService.deletePost(post.id).subscribe({
        next: () => {
          this.snackBar.open('Post deleted', 'OK', { duration: 3000 });
          this.loadReportedPosts();
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

  getStatusColor(status: string): string {
    switch (status) {
      case 'FLAGGED': return 'warn';
      case 'PENDING_APPROVAL': return 'warn';
      case 'APPROVED': return 'primary';
      case 'REJECTED': return 'accent';
      case 'SOLD': return '';
      default: return '';
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'FLAGGED': return 'Flagged';
      case 'PENDING_APPROVAL': return 'Pending';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      case 'SOLD': return 'Sold';
      default: return status;
    }
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
