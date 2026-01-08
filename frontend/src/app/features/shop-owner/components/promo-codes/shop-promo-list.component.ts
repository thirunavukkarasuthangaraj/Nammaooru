import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';
import { AuthService } from '../../../../core/services/auth.service';

interface PromoCode {
  id: number;
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
  usageCount: number;
  usageLimitPerCustomer?: number;
  firstTimeOnly: boolean;
  applicableToAllShops: boolean;
  imageUrl?: string;
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
  displayedColumns = ['code', 'discount', 'validity', 'usage', 'status'];

  constructor(
    private http: HttpClient,
    private authService: AuthService,
    private snackBar: MatSnackBar
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
    // Get promo codes that apply to this shop (either shop-specific or all shops)
    this.http.get<any>(`${environment.apiUrl}/promotions`, {
      params: { shopId: this.shopId?.toString() || '' }
    }).subscribe({
      next: (response) => {
        this.promoCodes = response.content || response.data || response || [];
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading promo codes:', error);
        this.isLoading = false;
        // Don't show error - just show empty state
        this.promoCodes = [];
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

  private showSnackBar(message: string, type: 'success' | 'error'): void {
    this.snackBar.open(message, 'Close', {
      duration: 3000,
      horizontalPosition: 'end',
      verticalPosition: 'top',
      panelClass: type === 'success' ? 'snackbar-success' : 'snackbar-error'
    });
  }
}
