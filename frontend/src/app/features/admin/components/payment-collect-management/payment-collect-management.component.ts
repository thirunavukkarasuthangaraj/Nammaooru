import { Component, OnInit } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { PaymentCollectService, ShopPaymentRow } from '../../../../core/services/payment-collect.service';

@Component({
  selector: 'app-payment-collect-management',
  templateUrl: './payment-collect-management.component.html',
  styleUrls: ['./payment-collect-management.component.scss']
})
export class PaymentCollectManagementComponent implements OnInit {
  shops: ShopPaymentRow[] = [];
  loading = false;
  savingShopId: number | null = null;

  durationDays = 30;
  durationLoading = false;
  durationSaving = false;

  durationValue = 1;
  durationUnit: 'days' | 'months' | 'years' = 'months';
  private readonly UNIT_DAYS: { [key: string]: number } = { days: 1, months: 30, years: 365 };

  editAmounts: { [shopId: number]: number } = {};
  editDurations: { [shopId: number]: number | null } = {};

  // Per-shop duration choices; null = follow the global billing duration
  readonly durationOptions: { value: number | null; label: string }[] = [
    { value: null, label: 'Default' },
    { value: 30, label: '1 Month' },
    { value: 90, label: '3 Months' },
    { value: 180, label: '6 Months' },
    { value: 365, label: '1 Year' }
  ];

  constructor(
    private paymentCollectService: PaymentCollectService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadShops();
    this.loadDuration();
  }

  loadShops(): void {
    this.loading = true;
    this.paymentCollectService.listShops(0, 100).subscribe({
      next: result => {
        this.shops = result.content;
        this.shops.forEach(s => {
          this.editAmounts[s.shopId] = s.amount;
          this.editDurations[s.shopId] = s.durationDays ?? null;
        });
        this.loading = false;
      },
      error: err => {
        this.loading = false;
        this.snackBar.open(err.message || 'Failed to load shops', 'Close', { duration: 4000 });
      }
    });
  }

  get totalShops(): number {
    return this.shops.length;
  }

  get activeCount(): number {
    return this.shops.filter(s => !s.paymentBlocked).length;
  }

  get dueCount(): number {
    return this.shops.filter(s => s.paymentBlocked).length;
  }

  get monthlyRevenue(): number {
    return this.shops.filter(s => s.amount > 0).reduce((sum, s) => sum + s.amount, 0);
  }

  isDirty(shop: ShopPaymentRow): boolean {
    return this.editAmounts[shop.shopId] !== shop.amount
      || (this.editDurations[shop.shopId] ?? null) !== (shop.durationDays ?? null);
  }

  isValidAmount(shop: ShopPaymentRow): boolean {
    const amount = this.editAmounts[shop.shopId];
    return amount != null && !isNaN(amount) && amount >= 0;
  }

  statusLabel(shop: ShopPaymentRow): string {
    if (shop.amount <= 0) return 'No price set';
    return shop.paymentBlocked ? 'Payment due' : 'Active';
  }

  statusClass(shop: ShopPaymentRow): string {
    if (shop.amount <= 0) return 'neutral';
    return shop.paymentBlocked ? 'blocked' : 'active';
  }

  initial(name: string): string {
    return name?.charAt(0)?.toUpperCase() || '?';
  }

  loadDuration(): void {
    this.durationLoading = true;
    this.paymentCollectService.getDuration().subscribe({
      next: days => {
        this.durationDays = days;
        this.setUnitFromDays(days);
        this.durationLoading = false;
      },
      error: () => {
        this.durationLoading = false;
      }
    });
  }

  /** Picks the largest whole unit that reconstructs the stored day count, so "365" shows as "1 year" not "365 days". */
  private setUnitFromDays(days: number): void {
    if (days % this.UNIT_DAYS['years'] === 0) {
      this.durationUnit = 'years';
      this.durationValue = days / this.UNIT_DAYS['years'];
    } else if (days % this.UNIT_DAYS['months'] === 0) {
      this.durationUnit = 'months';
      this.durationValue = days / this.UNIT_DAYS['months'];
    } else {
      this.durationUnit = 'days';
      this.durationValue = days;
    }
  }

  onDurationInputChange(): void {
    this.durationDays = Math.max(1, Math.round(this.durationValue * this.UNIT_DAYS[this.durationUnit]));
  }

  saveDuration(): void {
    if (this.durationValue == null || isNaN(this.durationValue) || this.durationValue < 1) {
      this.snackBar.open('Enter a duration of at least 1', 'Close', { duration: 3000 });
      return;
    }
    this.onDurationInputChange();
    if (this.durationDays < 1) {
      this.snackBar.open('Duration must be at least 1 day', 'Close', { duration: 3000 });
      return;
    }
    this.durationSaving = true;
    this.paymentCollectService.setDuration(this.durationDays).subscribe({
      next: () => {
        this.durationSaving = false;
        this.snackBar.open(`Billing duration updated to ${this.durationDays} days`, 'Close', { duration: 3000 });
      },
      error: err => {
        this.durationSaving = false;
        this.snackBar.open(err.message || 'Failed to update duration', 'Close', { duration: 4000 });
      }
    });
  }

  savePrice(shop: ShopPaymentRow): void {
    const amount = this.editAmounts[shop.shopId];
    if (amount == null || amount < 0) {
      this.snackBar.open('Enter a valid amount', 'Close', { duration: 3000 });
      return;
    }
    this.savingShopId = shop.shopId;
    const durationDays = this.editDurations[shop.shopId] ?? null;
    this.paymentCollectService.setPrice(shop.shopId, amount, durationDays).subscribe({
      next: () => {
        this.savingShopId = null;
        shop.amount = amount;
        shop.durationDays = durationDays;
        this.snackBar.open(`Price updated for ${shop.shopName}`, 'Close', { duration: 3000 });
        this.loadShops();
      },
      error: err => {
        this.savingShopId = null;
        this.snackBar.open(err.message || 'Failed to update price', 'Close', { duration: 4000 });
      }
    });
  }
}
