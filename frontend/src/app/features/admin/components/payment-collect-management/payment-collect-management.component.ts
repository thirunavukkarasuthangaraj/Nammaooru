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

  editAmounts: { [shopId: number]: number } = {};

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
        this.shops.forEach(s => this.editAmounts[s.shopId] = s.amount);
        this.loading = false;
      },
      error: err => {
        this.loading = false;
        this.snackBar.open(err.message || 'Failed to load shops', 'Close', { duration: 4000 });
      }
    });
  }

  loadDuration(): void {
    this.durationLoading = true;
    this.paymentCollectService.getDuration().subscribe({
      next: days => {
        this.durationDays = days;
        this.durationLoading = false;
      },
      error: () => {
        this.durationLoading = false;
      }
    });
  }

  saveDuration(): void {
    if (this.durationDays < 1) {
      this.snackBar.open('Duration must be at least 1 day', 'Close', { duration: 3000 });
      return;
    }
    this.durationSaving = true;
    this.paymentCollectService.setDuration(this.durationDays).subscribe({
      next: () => {
        this.durationSaving = false;
        this.snackBar.open('Billing duration updated', 'Close', { duration: 3000 });
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
    this.paymentCollectService.setPrice(shop.shopId, amount).subscribe({
      next: () => {
        this.savingShopId = null;
        shop.amount = amount;
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
