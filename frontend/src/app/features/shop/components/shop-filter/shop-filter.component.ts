import { Component, EventEmitter, Output } from '@angular/core';

@Component({
  selector: 'app-shop-filter',
  template: `
    <mat-card class="filter-card">
      <mat-card-header>
        <mat-card-title>Filters</mat-card-title>
      </mat-card-header>
      <mat-card-content>
        <div class="filter-grid">
          <mat-form-field>
            <mat-label>Business Type</mat-label>
            <mat-select [(value)]="selectedBusinessType" (selectionChange)="onFilterChange()">
              <mat-option value="">All Types</mat-option>
              <mat-option value="GROCERY">Grocery</mat-option>
              <mat-option value="PHARMACY">Pharmacy</mat-option>
              <mat-option value="RESTAURANT">Restaurant</mat-option>
              <mat-option value="GENERAL">General</mat-option>
            </mat-select>
          </mat-form-field>

          <mat-form-field>
            <mat-label>Status</mat-label>
            <mat-select [(value)]="selectedStatus" (selectionChange)="onFilterChange()">
              <mat-option value="">All Status</mat-option>
              <mat-option value="PENDING">Pending</mat-option>
              <mat-option value="APPROVED">Approved</mat-option>
              <mat-option value="REJECTED">Rejected</mat-option>
              <mat-option value="SUSPENDED">Suspended</mat-option>
            </mat-select>
          </mat-form-field>

          <mat-form-field>
            <mat-label>City</mat-label>
            <input matInput [(ngModel)]="selectedCity" (input)="onFilterChange()" placeholder="Enter city">
          </mat-form-field>

          <div class="checkbox-group">
            <mat-checkbox [(ngModel)]="isVerifiedOnly" (change)="onFilterChange()">
              Verified Only
            </mat-checkbox>
            <mat-checkbox [(ngModel)]="isFeaturedOnly" (change)="onFilterChange()">
              Featured Only
            </mat-checkbox>
            <mat-checkbox [(ngModel)]="isActiveOnly" (change)="onFilterChange()">
              Active Only
            </mat-checkbox>
          </div>
        </div>

        <div class="filter-actions">
          <button mat-button (click)="clearFilters()">Clear All</button>
          <button mat-raised-button color="primary" (click)="applyFilters()">Apply Filters</button>
        </div>
      </mat-card-content>
    </mat-card>
  `,
  styles: [`
    .filter-card {
      margin-bottom: 20px;
    }

    .filter-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 15px;
      margin: 20px 0;
    }

    .checkbox-group {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }

    .filter-actions {
      display: flex;
      justify-content: flex-end;
      gap: 10px;
      margin-top: 20px;
    }
  `]
})
export class ShopFilterComponent {
  @Output() filterChange = new EventEmitter<any>();

  selectedBusinessType = '';
  selectedStatus = '';
  selectedCity = '';
  isVerifiedOnly = false;
  isFeaturedOnly = false;
  isActiveOnly = false;

  onFilterChange() {
    // Emit filter changes immediately for real-time filtering
    this.emitFilters();
  }

  applyFilters() {
    this.emitFilters();
  }

  clearFilters() {
    this.selectedBusinessType = '';
    this.selectedStatus = '';
    this.selectedCity = '';
    this.isVerifiedOnly = false;
    this.isFeaturedOnly = false;
    this.isActiveOnly = false;
    this.emitFilters();
  }

  private emitFilters() {
    const filters = {
      businessType: this.selectedBusinessType,
      status: this.selectedStatus,
      city: this.selectedCity,
      isVerified: this.isVerifiedOnly || undefined,
      isFeatured: this.isFeaturedOnly || undefined,
      isActive: this.isActiveOnly || undefined
    };

    // Remove undefined values
    Object.keys(filters).forEach(key => {
      if ((filters as any)[key] === undefined) {
        delete (filters as any)[key];
      }
    });

    this.filterChange.emit(filters);
  }
}