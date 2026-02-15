import { Component, OnInit } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { ParcelAdminService } from '../../services/parcel.service';
import { getImageUrl } from '../../../../core/utils/image-url.util';

interface ParcelPost {
  id: number;
  serviceName: string;
  phone: string;
  serviceType: string;
  fromLocation: string | null;
  toLocation: string | null;
  priceInfo: string | null;
  address: string | null;
  timings: string | null;
  description: string | null;
  imageUrls: string | null;
  sellerUserId: number;
  sellerName: string;
  reportCount: number;
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
  selector: 'app-parcel-reported',
  templateUrl: './parcel-reported.component.html',
  styleUrls: ['./parcel-reported.component.scss']
})
export class ParcelReportedComponent implements OnInit {
  posts: ParcelPost[] = [];
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
    private parcelService: ParcelAdminService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadReportedPosts();
  }

  loadReportedPosts(): void {
    this.loading = true;
    this.parcelService.getReportedPosts(this.currentPage, this.pageSize).subscribe({
      next: (response) => {
        const data = response.data;
        this.posts = data?.content || [];
        this.totalPages = data?.totalPages || 0;
        this.totalItems = data?.totalItems || 0;
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading reported parcel posts:', err);
        this.loading = false;
        this.snackBar.open('Failed to load reported posts', 'Close', { duration: 3000 });
      }
    });
  }

  onStatusChange(post: ParcelPost, newStatus: string): void {
    if (newStatus === 'REMOVED') {
      if (!confirm(`Remove "${post.serviceName}" permanently? This will delete the post.`)) {
        return;
      }
      this.parcelService.deletePost(post.id).subscribe({
        next: () => {
          this.snackBar.open(`"${post.serviceName}" removed`, 'OK', { duration: 3000 });
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

    this.parcelService.changePostStatus(post.id, newStatus).subscribe({
      next: () => {
        this.snackBar.open(`"${post.serviceName}" → ${label}`, 'OK', { duration: 3000 });
        this.loadReportedPosts();
      },
      error: () => {
        this.snackBar.open(`Failed to change status to ${label}`, 'Close', { duration: 3000 });
      }
    });
  }

  getImageUrl(imageUrls: string | null): string {
    if (!imageUrls) return '';
    const first = imageUrls.split(',')[0]?.trim();
    return getImageUrl(first || null);
  }

  getServiceTypeLabel(type: string): string {
    switch (type) {
      case 'DOOR_TO_DOOR': return 'Door to Door';
      case 'PICKUP_POINT': return 'Pickup Point';
      case 'BOTH': return 'Both';
      default: return type;
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'FLAGGED': return 'Flagged';
      case 'PENDING_APPROVAL': return 'Pending';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      case 'SOLD': return 'Unavailable';
      case 'HOLD': return 'On Hold';
      case 'HIDDEN': return 'Hidden';
      case 'CORRECTION_REQUIRED': return 'Correction Required';
      case 'REMOVED': return 'Removed';
      default: return status;
    }
  }

  getAvailableStatuses(post: ParcelPost): StatusOption[] {
    return this.statusOptions.filter(o => o.value !== post.status);
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
