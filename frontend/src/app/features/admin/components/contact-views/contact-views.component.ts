import { Component, OnInit } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { ContactViewsService } from '../../services/contact-views.service';

interface ContactView {
  id: number;
  viewerUserId: number;
  viewerName: string;
  viewerPhone: string;
  postType: string;
  postId: number;
  postTitle: string;
  sellerPhone: string;
  viewedAt: string;
}

@Component({
  selector: 'app-contact-views',
  templateUrl: './contact-views.component.html',
  styleUrls: ['./contact-views.component.css']
})
export class ContactViewsComponent implements OnInit {
  views: ContactView[] = [];
  loading = true;
  currentPage = 0;
  totalPages = 0;
  totalItems = 0;
  pageSize = 20;

  filterPostType = '';
  postTypeOptions = [
    { value: '', label: 'All Types' },
    { value: 'MARKETPLACE', label: 'Buy & Sell' },
    { value: 'FARM_PRODUCTS', label: 'Farm Products' },
    { value: 'LABOUR', label: 'Labour' },
    { value: 'TRAVEL', label: 'Travel' },
    { value: 'PARCEL_SERVICE', label: 'Parcel Service' },
    { value: 'RENTAL', label: 'Rental' },
    { value: 'REAL_ESTATE', label: 'Real Estate' },
    { value: 'WOMENS_CORNER', label: "Women's Corner" },
    { value: 'JOBS', label: 'Jobs' }
  ];

  displayedColumns = ['viewerName', 'viewerPhone', 'postType', 'postTitle', 'sellerPhone', 'viewedAt', 'actions'];

  constructor(
    private contactViewsService: ContactViewsService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadViews();
  }

  loadViews(): void {
    this.loading = true;
    this.contactViewsService.getAllViews(this.currentPage, this.pageSize).subscribe({
      next: (response) => {
        const data = response.data;
        const allViews: ContactView[] = data?.content || [];
        this.views = this.filterPostType
          ? allViews.filter(v => v.postType === this.filterPostType)
          : allViews;
        this.totalPages = data?.totalPages || 0;
        this.totalItems = data?.totalElements || 0;
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading contact views:', err);
        this.loading = false;
        this.snackBar.open('Failed to load contact views', 'Close', { duration: 3000 });
      }
    });
  }

  onFilterChange(): void {
    this.currentPage = 0;
    this.loadViews();
  }

  onPageChange(page: number): void {
    this.currentPage = page;
    this.loadViews();
  }

  blockUser(view: ContactView): void {
    const confirmed = confirm(
      `Block user "${view.viewerName || view.viewerPhone}" (ID: ${view.viewerUserId})?\n\nThis will suspend their account and prevent further access.`
    );
    if (!confirmed) return;

    this.contactViewsService.blockUser(view.viewerUserId).subscribe({
      next: () => {
        this.snackBar.open(`User "${view.viewerName || view.viewerUserId}" has been blocked`, 'OK', { duration: 3000 });
        this.loadViews();
      },
      error: (err) => {
        console.error('Error blocking user:', err);
        this.snackBar.open('Failed to block user', 'Close', { duration: 3000 });
      }
    });
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

  getPostTypeLabel(postType: string): string {
    const option = this.postTypeOptions.find(o => o.value === postType);
    return option ? option.label : postType;
  }

  getPages(): number[] {
    return Array.from({ length: this.totalPages }, (_, i) => i);
  }
}
