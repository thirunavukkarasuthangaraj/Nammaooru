import { Component, Inject, OnInit, ViewChild } from '@angular/core';
import { MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { PromoCodeService } from '../../../../core/services/promo-code.service';
import { PromoCode, PromoCodeStats, PromoCodeUsage } from '../../../../core/models/promo-code.model';

@Component({
  selector: 'app-promo-code-stats',
  templateUrl: './promo-code-stats.component.html',
  styleUrls: ['./promo-code-stats.component.css']
})
export class PromoCodeStatsComponent implements OnInit {
  stats: PromoCodeStats | null = null;
  dataSource: MatTableDataSource<PromoCodeUsage>;
  isLoading = true;
  displayedColumns = ['customer', 'order', 'discount', 'orderAmount', 'usedAt'];

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  constructor(
    private promoCodeService: PromoCodeService,
    @Inject(MAT_DIALOG_DATA) public data: { promoCode: PromoCode }
  ) {
    this.dataSource = new MatTableDataSource<PromoCodeUsage>([]);
  }

  ngOnInit(): void {
    this.loadStats();
    this.loadUsageHistory();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
  }

  loadStats(): void {
    this.promoCodeService.getPromoCodeStats(this.data.promoCode.id).subscribe({
      next: (stats) => {
        this.stats = stats;
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading stats:', error);
        this.isLoading = false;
      }
    });
  }

  loadUsageHistory(): void {
    this.promoCodeService.getPromoCodeUsageHistory(this.data.promoCode.id, 0, 100).subscribe({
      next: (response) => {
        this.dataSource.data = response.content;
      },
      error: (error) => {
        console.error('Error loading usage history:', error);
      }
    });
  }

  formatDate(dateString: string): string {
    return new Date(dateString).toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  formatCurrency(amount: number): string {
    return `₹${amount.toFixed(2)}`;
  }

  getFormattedDiscount(): string {
    return this.promoCodeService.getFormattedDiscount(this.data.promoCode);
  }

  getRemainingUses(): number | null {
    if (this.data.promoCode.usageLimit && this.stats) {
      return this.data.promoCode.usageLimit - this.stats.totalUsage;
    }
    return null;
  }

  getUsagePercentage(): number {
    if (this.data.promoCode.usageLimit && this.stats) {
      return (this.stats.totalUsage / this.data.promoCode.usageLimit) * 100;
    }
    return 0;
  }
}
