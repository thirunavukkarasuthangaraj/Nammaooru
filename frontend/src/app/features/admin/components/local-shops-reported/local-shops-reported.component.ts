import { Component, OnInit } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { LocalShopsAdminService } from '../../services/local-shops.service';
import { getImageUrl } from '../../../../core/utils/image-url.util';

interface LocalShopPost {
  id: number;
  shopName: string;
  phone: string;
  category: string;
  address: string | null;
  description: string | null;
  imageUrls: string | null;
  sellerUserId: number;
  sellerName: string;
  reportCount: number;
  status: string;
  createdAt: string;
}

interface StatusOption {
  value: string;
  label: string;
  icon: string;
  color: string;
}

@Component({
  selector: 'app-local-shops-reported',
  templateUrl: './local-shops-reported.component.html',
  styleUrls: ['./local-shops-reported.component.scss']
})
export class LocalShopsReportedComponent implements OnInit {
  posts: LocalShopPost[] = [];
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
    private service: LocalShopsAdminService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadReportedPosts();
  }

  loadReportedPosts(): void {
    this.loading = true;
    this.service.getReportedPosts(this.currentPage, this.pageSize).subscribe({
      next: (response) => {
        const data = response.data;
        this.posts = data?.content || [];
        this.totalPages = data?.totalPages || 0;
        this.totalItems = data?.totalItems || 0;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
        this.snackBar.open('Failed to load reported posts', 'Close', { duration: 3000 });
      }
    });
  }

  onStatusChange(post: LocalShopPost, newStatus: string): void {
    if (newStatus === 'REMOVED') {
      if (!confirm(`Remove "${post.shopName}" permanently?`)) return;
      this.service.deletePost(post.id).subscribe({
        next: () => {
          this.snackBar.open(`"${post.shopName}" removed`, 'OK', { duration: 3000 });
          this.loadReportedPosts();
        },
        error: () => this.snackBar.open('Failed to remove post', 'Close', { duration: 3000 })
      });
      return;
    }

    const option = this.statusOptions.find(o => o.value === newStatus);
    this.service.changePostStatus(post.id, newStatus).subscribe({
      next: () => {
        this.snackBar.open(`"${post.shopName}" → ${option?.label || newStatus}`, 'OK', { duration: 3000 });
        this.loadReportedPosts();
      },
      error: () => this.snackBar.open(`Failed to change status`, 'Close', { duration: 3000 })
    });
  }

  getImageUrl(imageUrls: string | null): string {
    if (!imageUrls) return '';
    return getImageUrl(imageUrls.split(',')[0]?.trim() || null);
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

  getStatusLabel(status: string): string {
    const labels: Record<string, string> = {
      FLAGGED: 'Flagged', PENDING_APPROVAL: 'Pending', APPROVED: 'Approved',
      REJECTED: 'Rejected', SOLD: 'Closed', HOLD: 'On Hold',
      HIDDEN: 'Hidden', CORRECTION_REQUIRED: 'Correction Required', REMOVED: 'Removed'
    };
    return labels[status] || status;
  }

  getAvailableStatuses(post: LocalShopPost): StatusOption[] {
    return this.statusOptions.filter(o => o.value !== post.status);
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
    this.loadReportedPosts();
  }
}
