import { Component, OnInit } from '@angular/core';
import { PaymentCollectService, ShopPaymentRow, UsageSummary } from '../../../../core/services/payment-collect.service';
import { SwalService } from '../../../../core/services/swal.service';

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
  editWhatsappRates: { [shopId: number]: number | null } = {};

  // WhatsApp usage billing config (paise/percent), superadmin-editable
  billRatePaise = 45;
  marketingRatePaise = 100;
  gstPercent = 18;
  billingConfigLoading = false;
  billingConfigSaving = false;
  usageSummary: UsageSummary | null = null;

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
    private swal: SwalService
  ) {}

  ngOnInit(): void {
    this.loadShops();
    this.loadDuration();
    this.loadBillingConfig();
    this.loadUsageSummary();
  }

  loadShops(): void {
    this.loading = true;
    this.paymentCollectService.listShops(0, 100).subscribe({
      next: result => {
        this.shops = result.content;
        this.shops.forEach(s => {
          this.editAmounts[s.shopId] = s.amount;
          this.editDurations[s.shopId] = s.durationDays ?? null;
          this.editWhatsappRates[s.shopId] = s.whatsappRatePaise ?? null;
        });
        this.loading = false;
      },
      error: err => {
        this.loading = false;
        this.swal.toast(err.message || 'Failed to load shops', 'error');
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
      || (this.editDurations[shop.shopId] ?? null) !== (shop.durationDays ?? null)
      || (this.editWhatsappRates[shop.shopId] ?? null) !== (shop.whatsappRatePaise ?? null);
  }

  formatPaise(paise: number): string {
    return (paise / 100).toFixed(2);
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
      this.swal.toast('Enter a duration of at least 1', 'warning');
      return;
    }
    this.onDurationInputChange();
    if (this.durationDays < 1) {
      this.swal.toast('Duration must be at least 1 day', 'warning');
      return;
    }
    this.durationSaving = true;
    this.paymentCollectService.setDuration(this.durationDays).subscribe({
      next: () => {
        this.durationSaving = false;
        this.swal.toast(`Billing duration updated to ${this.durationDays} days`, 'success');
      },
      error: err => {
        this.durationSaving = false;
        this.swal.toast(err.message || 'Failed to update duration', 'error');
      }
    });
  }

  savePrice(shop: ShopPaymentRow): void {
    const amount = this.editAmounts[shop.shopId];
    if (amount == null || amount < 0) {
      this.swal.toast('Enter a valid amount', 'warning');
      return;
    }
    this.savingShopId = shop.shopId;
    const durationDays = this.editDurations[shop.shopId] ?? null;
    const whatsappRatePaise = this.editWhatsappRates[shop.shopId] ?? null;
    this.paymentCollectService.setPrice(shop.shopId, amount, durationDays, whatsappRatePaise).subscribe({
      next: () => {
        this.savingShopId = null;
        shop.amount = amount;
        shop.durationDays = durationDays;
        shop.whatsappRatePaise = whatsappRatePaise;
        this.swal.toast(`Price updated for ${shop.shopName}`, 'success');
        this.loadShops();
      },
      error: err => {
        this.savingShopId = null;
        this.swal.toast(err.message || 'Failed to update price', 'error');
      }
    });
  }

  loadBillingConfig(): void {
    this.billingConfigLoading = true;
    this.paymentCollectService.getBillingConfig().subscribe({
      next: config => {
        this.billRatePaise = config.billRatePaise;
        this.marketingRatePaise = config.marketingRatePaise;
        this.gstPercent = config.gstPercent;
        this.billingConfigLoading = false;
      },
      error: () => { this.billingConfigLoading = false; }
    });
  }

  loadUsageSummary(): void {
    this.paymentCollectService.getUsageSummary().subscribe({
      next: summary => { this.usageSummary = summary; },
      error: () => { /* non-critical dashboard stat */ }
    });
  }

  saveBillingConfig(): void {
    if ([this.billRatePaise, this.marketingRatePaise, this.gstPercent].some(v => v == null || isNaN(v) || v < 0)) {
      this.swal.toast('Enter valid, non-negative values', 'warning');
      return;
    }
    this.billingConfigSaving = true;
    this.paymentCollectService.updateBillingConfig(this.billRatePaise, this.marketingRatePaise, this.gstPercent).subscribe({
      next: () => {
        this.billingConfigSaving = false;
        this.swal.toast('WhatsApp usage pricing updated', 'success');
        this.loadShops();
      },
      error: err => {
        this.billingConfigSaving = false;
        this.swal.toast(err.message || 'Failed to update pricing', 'error');
      }
    });
  }
}
