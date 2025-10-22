import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { PromoCodeService } from '../../../../core/services/promo-code.service';
import { PromoCode } from '../../../../core/models/promo-code.model';
import { PromoCodeFormComponent } from './promo-code-form.component';
import { PromoCodeStatsComponent } from './promo-code-stats.component';

@Component({
  selector: 'app-promo-code-list',
  templateUrl: './promo-code-list.component.html',
  styleUrls: ['./promo-code-list.component.css']
})
export class PromoCodeListComponent implements OnInit {
  displayedColumns: string[] = ['code', 'title', 'type', 'discount', 'minOrder', 'usage', 'dates', 'status', 'actions'];
  dataSource: MatTableDataSource<PromoCode>;
  isLoading = false;
  filterStatus = 'ALL';

  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  constructor(
    private promoCodeService: PromoCodeService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar
  ) {
    this.dataSource = new MatTableDataSource<PromoCode>([]);
  }

  ngOnInit(): void {
    this.loadPromoCodes();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  loadPromoCodes(): void {
    this.isLoading = true;
    const filters = this.filterStatus !== 'ALL' ? { status: this.filterStatus } : undefined;

    this.promoCodeService.getAllPromoCodes(filters).subscribe({
      next: (promoCodes) => {
        this.dataSource.data = promoCodes;
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading promo codes:', error);
        this.showSnackBar('Failed to load promo codes', 'error');
        this.isLoading = false;
      }
    });
  }

  applyFilter(event: Event): void {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSource.filter = filterValue.trim().toLowerCase();

    if (this.dataSource.paginator) {
      this.dataSource.paginator.firstPage();
    }
  }

  filterByStatus(status: string): void {
    this.filterStatus = status;
    this.loadPromoCodes();
  }

  openCreateDialog(): void {
    const dialogRef = this.dialog.open(PromoCodeFormComponent, {
      width: '800px',
      maxHeight: '90vh',
      data: { mode: 'create' }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.loadPromoCodes();
        this.showSnackBar('Promo code created successfully', 'success');
      }
    });
  }

  openEditDialog(promoCode: PromoCode): void {
    const dialogRef = this.dialog.open(PromoCodeFormComponent, {
      width: '800px',
      maxHeight: '90vh',
      data: { mode: 'edit', promoCode }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.loadPromoCodes();
        this.showSnackBar('Promo code updated successfully', 'success');
      }
    });
  }

  openStatsDialog(promoCode: PromoCode): void {
    this.dialog.open(PromoCodeStatsComponent, {
      width: '900px',
      maxHeight: '90vh',
      data: { promoCode }
    });
  }

  toggleStatus(promoCode: PromoCode): void {
    const action = promoCode.status === 'ACTIVE' ? 'deactivate' : 'activate';
    const actionText = action === 'activate' ? 'activated' : 'deactivated';

    const serviceCall = action === 'activate'
      ? this.promoCodeService.activatePromoCode(promoCode.id)
      : this.promoCodeService.deactivatePromoCode(promoCode.id);

    serviceCall.subscribe({
      next: () => {
        this.loadPromoCodes();
        this.showSnackBar(`Promo code ${actionText} successfully`, 'success');
      },
      error: (error) => {
        console.error(`Error ${action}ing promo code:`, error);
        this.showSnackBar(`Failed to ${action} promo code`, 'error');
      }
    });
  }

  deletePromoCode(promoCode: PromoCode): void {
    if (confirm(`Are you sure you want to delete promo code "${promoCode.code}"?`)) {
      this.promoCodeService.deletePromoCode(promoCode.id).subscribe({
        next: () => {
          this.loadPromoCodes();
          this.showSnackBar('Promo code deleted successfully', 'success');
        },
        error: (error) => {
          console.error('Error deleting promo code:', error);
          this.showSnackBar('Failed to delete promo code', 'error');
        }
      });
    }
  }

  getFormattedDiscount(promo: PromoCode): string {
    return this.promoCodeService.getFormattedDiscount(promo);
  }

  getFormattedMinOrder(promo: PromoCode): string {
    return this.promoCodeService.getFormattedMinOrder(promo);
  }

  getStatusBadgeColor(status: string): string {
    return this.promoCodeService.getStatusBadgeColor(status);
  }

  isExpired(promo: PromoCode): boolean {
    return this.promoCodeService.isExpired(promo);
  }

  formatDate(date: string): string {
    return new Date(date).toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric'
    });
  }

  getUsageText(promo: PromoCode): string {
    if (promo.usageLimit) {
      const remaining = promo.usageLimit - (promo.currentUsageCount || 0);
      return `${promo.currentUsageCount || 0}/${promo.usageLimit} (${remaining} left)`;
    }
    return `${promo.currentUsageCount || 0} uses`;
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
