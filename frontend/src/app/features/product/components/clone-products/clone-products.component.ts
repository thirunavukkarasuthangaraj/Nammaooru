import { Component, OnInit } from '@angular/core';
import { ShopProductService, CloneProductsResponse } from '../../../../core/services/shop-product.service';
import { ShopService } from '../../../../core/services/shop.service';
import { ShopProduct } from '../../../../core/models/product.model';
import { Shop } from '../../../../core/models/shop.model';
import Swal from 'sweetalert2';
import { getImageUrl as getImageUrlUtil } from '../../../../core/utils/image-url.util';

interface CloneSelection {
  product: ShopProduct;
  selected: boolean;
}

@Component({
  selector: 'app-clone-products',
  template: `
    <div class="clone-container">
      <div class="page-header">
        <h1 class="page-title"><mat-icon>content_copy</mat-icon> Clone Products to Another Shop</h1>
        <p class="page-description">
          Copy products (with their price, stock and images) from an existing shop into a new or
          different shop. Each cloned product is fully independent afterwards &mdash; changing the
          price or image on one shop never affects the other.
        </p>
      </div>

      <mat-card class="modern-card selector-card">
        <mat-card-content>
          <div class="selector-row">
            <mat-form-field appearance="outline" class="selector-field">
              <mat-label>Source Shop (copy from)</mat-label>
              <mat-select [(value)]="sourceShopId" (selectionChange)="onSourceShopChange()">
                <mat-option *ngFor="let shop of shops" [value]="shop.id" [disabled]="shop.id === targetShopId">
                  {{ shop.name }} ({{ shop.businessType }})
                </mat-option>
              </mat-select>
            </mat-form-field>

            <mat-icon class="arrow-icon">arrow_forward</mat-icon>

            <mat-form-field appearance="outline" class="selector-field">
              <mat-label>Target Shop (copy into)</mat-label>
              <mat-select [(value)]="targetShopId">
                <mat-option *ngFor="let shop of shops" [value]="shop.id" [disabled]="shop.id === sourceShopId">
                  {{ shop.name }} ({{ shop.businessType }})
                </mat-option>
              </mat-select>
            </mat-form-field>
          </div>
        </mat-card-content>
      </mat-card>

      <div class="products-section" *ngIf="sourceShopId">
        <div class="toolbar" *ngIf="!isLoading">
          <mat-checkbox [checked]="allSelected" [indeterminate]="someSelected" (change)="toggleSelectAll($event.checked)">
            Select All ({{ selections.length }} products)
          </mat-checkbox>
          <span class="selected-count">{{ getSelectedCount() }} selected</span>
        </div>

        <div class="loading-row" *ngIf="isLoading">
          <mat-spinner diameter="32"></mat-spinner>
          <span>Loading products from source shop...</span>
        </div>

        <div class="product-grid" *ngIf="!isLoading">
          <div class="product-row" *ngFor="let sel of selections" [class.selected]="sel.selected" (click)="sel.selected = !sel.selected">
            <mat-checkbox [(ngModel)]="sel.selected" (click)="$event.stopPropagation()"></mat-checkbox>
            <img [src]="getImageUrl(sel.product.primaryImageUrl)" class="product-thumb" onerror="this.style.visibility='hidden'" />
            <div class="product-info">
              <div class="product-name">{{ sel.product.displayName }}</div>
              <div class="product-meta">₹{{ sel.product.price }} &middot; Stock: {{ sel.product.stockQuantity }}</div>
            </div>
          </div>
        </div>

        <div class="submit-bar" *ngIf="!isLoading">
          <button mat-raised-button color="primary" [disabled]="!canClone() || isCloning" (click)="cloneSelected()">
            <mat-icon *ngIf="isCloning">refresh</mat-icon>
            Clone {{ getSelectedCount() }} Product(s) to Target Shop
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .clone-container { padding: 24px; max-width: 1000px; margin: 0 auto; }
    .page-header { margin-bottom: 20px; }
    .page-title { display: flex; align-items: center; gap: 10px; font-size: 24px; font-weight: 700; margin: 0 0 8px; }
    .page-description { color: #666; margin: 0; }
    .selector-card { margin-bottom: 20px; }
    .selector-row { display: flex; align-items: center; gap: 16px; }
    .selector-field { flex: 1; }
    .arrow-icon { color: #999; }
    .toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 4px; }
    .selected-count { color: #666; font-size: 14px; }
    .loading-row { display: flex; align-items: center; gap: 12px; padding: 40px; justify-content: center; color: #666; }
    .product-grid { max-height: 520px; overflow-y: auto; border: 1px solid #e0e0e0; border-radius: 8px; }
    .product-row {
      display: flex; align-items: center; gap: 12px; padding: 10px 14px;
      border-bottom: 1px solid #f0f0f0; cursor: pointer;
    }
    .product-row:hover { background: #fafafa; }
    .product-row.selected { background: #e8f5e9; }
    .product-thumb { width: 40px; height: 40px; border-radius: 6px; object-fit: cover; background: #eee; }
    .product-info { flex: 1; min-width: 0; }
    .product-name { font-weight: 600; font-size: 14px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .product-meta { font-size: 12px; color: #777; }
    .submit-bar { display: flex; justify-content: flex-end; padding: 16px 4px; }
  `]
})
export class CloneProductsComponent implements OnInit {
  shops: Shop[] = [];
  sourceShopId: number | null = null;
  targetShopId: number | null = null;

  selections: CloneSelection[] = [];
  isLoading = false;
  isCloning = false;

  constructor(
    private shopProductService: ShopProductService,
    private shopService: ShopService
  ) {}

  ngOnInit(): void {
    this.shopService.getShops({ page: 0, size: 500 }).subscribe({
      next: (response) => {
        this.shops = response.content || [];
      },
      error: (error) => console.error('Error loading shops:', error)
    });
  }

  onSourceShopChange(): void {
    if (!this.sourceShopId) {
      this.selections = [];
      return;
    }
    this.isLoading = true;
    this.shopProductService.getShopProducts(this.sourceShopId, 0, 5000).subscribe({
      next: (page) => {
        this.selections = (page.content || []).map(product => ({ product, selected: false }));
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading source shop products:', error);
        this.isLoading = false;
        Swal.fire('Error', 'Could not load products for that shop', 'error');
      }
    });
  }

  get allSelected(): boolean {
    return this.selections.length > 0 && this.selections.every(s => s.selected);
  }

  get someSelected(): boolean {
    return this.selections.some(s => s.selected) && !this.allSelected;
  }

  toggleSelectAll(checked: boolean): void {
    this.selections.forEach(s => s.selected = checked);
  }

  getSelectedCount(): number {
    return this.selections.filter(s => s.selected).length;
  }

  canClone(): boolean {
    return !!this.sourceShopId && !!this.targetShopId && this.getSelectedCount() > 0;
  }

  getImageUrl(url?: string): string {
    return getImageUrlUtil(url);
  }

  cloneSelected(): void {
    if (!this.canClone() || !this.sourceShopId || !this.targetShopId) return;

    const shopProductIds = this.selections.filter(s => s.selected).map(s => s.product.id);
    this.isCloning = true;

    this.shopProductService.cloneProducts(this.targetShopId, this.sourceShopId, shopProductIds, false).subscribe({
      next: (result: CloneProductsResponse) => {
        this.isCloning = false;
        const skipped = result.skippedCount > 0
          ? `<br><br><b>${result.skippedCount} skipped:</b><br>${result.skippedReasons.join('<br>')}`
          : '';
        Swal.fire({
          icon: 'success',
          title: 'Products Cloned',
          html: `${result.clonedCount} product(s) cloned into the target shop.${skipped}`
        });
      },
      error: (error) => {
        this.isCloning = false;
        console.error('Error cloning products:', error);
        Swal.fire('Error', error?.error?.message || 'Could not clone products', 'error');
      }
    });
  }
}
