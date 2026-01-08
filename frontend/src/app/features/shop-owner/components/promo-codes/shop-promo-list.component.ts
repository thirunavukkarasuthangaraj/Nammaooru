import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';
import { AuthService } from '../../../../core/services/auth.service';
import { ShopPromoFormComponent } from './shop-promo-form.component';

export interface PromoCode {
  id?: number;
  code: string;
  title: string;
  description?: string;
  type: 'PERCENTAGE' | 'FIXED_AMOUNT' | 'FREE_SHIPPING';
  discountValue: number;
  minimumOrderAmount?: number;
  maximumDiscountAmount?: number;
  startDate: string;
  endDate: string;
  status: 'ACTIVE' | 'INACTIVE' | 'EXPIRED';
  usageLimit?: number;
  usageCount?: number;
  usageLimitPerCustomer?: number;
  firstTimeOnly: boolean;
  applicableToAllShops?: boolean;
  imageUrl?: string;
  shopId?: number;
}

@Component({
  selector: 'app-shop-promo-list',
  templateUrl: './shop-promo-list.component.html',
  styleUrls: ['./shop-promo-list.component.css']
})
export class ShopPromoListComponent implements OnInit {
  promoCodes: PromoCode[] = [];
  isLoading = false;
  shopId: number | null = null;

  constructor(
    private http: HttpClient,
    private authService: AuthService,
    private snackBar: MatSnackBar,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    this.loadShopId();
  }

  private loadShopId(): void {
    const user = this.authService.getCurrentUser();
    if (user?.shopId) {
      this.shopId = user.shopId;
      this.loadPromoCodes();
    } else {
      this.http.get<any>(`${environment.apiUrl}/shops/my-shop`).subscribe({
        next: (response) => {
          this.shopId = response.data?.id || response.id;
          this.loadPromoCodes();
        },
        error: () => {
          this.showSnackBar('Failed to load shop info', 'error');
        }
      });
    }
  }

  loadPromoCodes(): void {
    this.isLoading = true;
    // Get promo codes for this shop owner
    this.http.get<any>(`${environment.apiUrl}/shop-owner/promotions`).subscribe({
      next: (response) => {
        const data = response.data?.content || response.data || response.content || response || [];
        this.promoCodes = Array.isArray(data) ? data : [];
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading promo codes:', error);
        this.isLoading = false;
        this.promoCodes = [];
      }
    });
  }

  openCreateDialog(): void {
    const dialogRef = this.dialog.open(ShopPromoFormComponent, {
      width: '600px',
      maxHeight: '90vh',
      data: { mode: 'create', shopId: this.shopId }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.loadPromoCodes();
      }
    });
  }

  openEditDialog(promo: PromoCode): void {
    const dialogRef = this.dialog.open(ShopPromoFormComponent, {
      width: '600px',
      maxHeight: '90vh',
      data: { mode: 'edit', promo: promo, shopId: this.shopId }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.loadPromoCodes();
      }
    });
  }

  toggleStatus(promo: PromoCode): void {
    const newStatus = promo.status === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    this.http.patch<any>(`${environment.apiUrl}/shop-owner/promotions/${promo.id}/status?status=${newStatus}`, {}).subscribe({
      next: () => {
        promo.status = newStatus;
        this.showSnackBar(`Promo code ${newStatus.toLowerCase()}`, 'success');
      },
      error: (error) => {
        this.showSnackBar(error.error?.message || 'Failed to update status', 'error');
      }
    });
  }

  deletePromo(promo: PromoCode): void {
    if (!confirm(`Are you sure you want to delete "${promo.title}"?`)) {
      return;
    }

    this.http.delete(`${environment.apiUrl}/shop-owner/promotions/${promo.id}`).subscribe({
      next: () => {
        this.promoCodes = this.promoCodes.filter(p => p.id !== promo.id);
        this.showSnackBar('Promo code deleted', 'success');
      },
      error: (error) => {
        this.showSnackBar(error.error?.message || 'Failed to delete promo code', 'error');
      }
    });
  }

  getDiscountText(promo: PromoCode): string {
    switch (promo.type) {
      case 'PERCENTAGE':
        return `${promo.discountValue}% OFF`;
      case 'FIXED_AMOUNT':
        return `₹${promo.discountValue} OFF`;
      case 'FREE_SHIPPING':
        return 'FREE DELIVERY';
      default:
        return 'SPECIAL OFFER';
    }
  }

  getMinOrderText(promo: PromoCode): string {
    if (promo.minimumOrderAmount && promo.minimumOrderAmount > 0) {
      return `Min: ₹${promo.minimumOrderAmount}`;
    }
    return 'No minimum';
  }

  isExpired(promo: PromoCode): boolean {
    return new Date(promo.endDate) < new Date();
  }

  isUpcoming(promo: PromoCode): boolean {
    return new Date(promo.startDate) > new Date();
  }

  getStatusClass(promo: PromoCode): string {
    if (promo.status === 'INACTIVE') return 'status-inactive';
    if (this.isExpired(promo)) return 'status-expired';
    if (this.isUpcoming(promo)) return 'status-upcoming';
    return 'status-active';
  }

  getStatusText(promo: PromoCode): string {
    if (promo.status === 'INACTIVE') return 'Inactive';
    if (this.isExpired(promo)) return 'Expired';
    if (this.isUpcoming(promo)) return 'Upcoming';
    return 'Active';
  }

  copyCode(code: string): void {
    navigator.clipboard.writeText(code).then(() => {
      this.showSnackBar('Code copied!', 'success');
    });
  }

  getImageUrl(imageUrl: string | undefined): string {
    if (!imageUrl) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    // Prepend the imageBaseUrl for relative paths
    const cleanPath = imageUrl.startsWith('/') ? imageUrl : '/' + imageUrl;
    return `${environment.imageBaseUrl}${cleanPath}`;
  }

  private showSnackBar(message: string, type: 'success' | 'error'): void {
    this.snackBar.open(message, 'Close', {
      duration: 3000,
      horizontalPosition: 'end',
      verticalPosition: 'top',
      panelClass: type === 'success' ? 'snackbar-success' : 'snackbar-error'
    });
  }
}
