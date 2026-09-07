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
                <mat-option *ngFor="let shop of activeShops" [value]="shop.id" [disabled]="shop.id === targetShopId">
                  {{ shop.name }} ({{ shop.businessType }})
                </mat-option>
              </mat-select>
            </mat-form-field>

            <mat-icon class="arrow-icon">arrow_forward</mat-icon>

            <mat-form-field appearance="outline" class="selector-field">
              <mat-label>Target Shop (copy into)</mat-label>
              <mat-select [(value)]="targetShopId">
                <mat-option *ngFor="let shop of targetShopOptions" [value]="shop.id" [disabled]="shop.id === sourceShopId">
                  {{ shop.name }} ({{ shop.businessType }})
                </mat-option>
              </mat-select>
              <mat-hint *ngIf="sourceShop">Showing {{ sourceShop.businessType }} shops first</mat-hint>
            </mat-form-field>
          </div>
        </mat-card-content>
      </mat-card>

      <div class="products-section" *ngIf="sourceShopId">
        <div class="toolbar" *ngIf="!isLoading">
          <mat-checkbox [checked]="allVisibleSelected" [indeterminate]="someVisibleSelected" (change)="toggleSelectVisible($event.checked)">
            Select All Shown ({{ visibleSelections.length }})
          </mat-checkbox>

          <mat-form-field appearance="outline" class="category-filter">
            <mat-label>Category</mat-label>
            <mat-select [(value)]="categoryFilter">
              <mat-option [value]="null">All categories ({{ selections.length }})</mat-option>
              <mat-option *ngFor="let cat of categories" [value]="cat">
                {{ cat }} ({{ countInCategory(cat) }})
              </mat-option>
            </mat-select>
          </mat-form-field>

          <span class="selected-count">{{ getSelectedCount() }} of {{ selections.length }} selected overall</span>
        </div>

        <p class="filter-hint" *ngIf="!isLoading">
          Tip: pick a category above, then use "Select All Shown" to include or exclude just that
          category &mdash; e.g. filter to "Vegetables" and uncheck it to clone everything except vegetables.
        </p>

        <div class="loading-row" *ngIf="isLoading">
          <mat-spinner diameter="32"></mat-spinner>
          <span>Loading products from source shop...</span>
        </div>

        <div class="product-grid" *ngIf="!isLoading">
          <div class="product-row" *ngFor="let sel of visibleSelections" [class.selected]="sel.selected" (click)="sel.selected = !sel.selected">
            <mat-checkbox [(ngModel)]="sel.selected" (click)="$event.stopPropagation()"></mat-checkbox>
            <img [src]="getImageUrl(sel.product.primaryImageUrl)" class="product-thumb" onerror="this.style.visibility='hidden'" />
            <div class="product-info">
              <div class="product-name">{{ sel.product.displayName }}</div>
              <div class="product-meta">₹{{ sel.product.price }} &middot; Stock: {{ sel.product.stockQuantity }} &middot; {{ categoryOf(sel.product) }}</div>
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
    .toolbar { display: flex; align-items: center; gap: 20px; padding: 12px 4px; flex-wrap: wrap; }
    .category-filter { width: 220px; margin-bottom: -1.25em; }
    .selected-count { color: #666; font-size: 14px; margin-left: auto; }
    .filter-hint { color: #888; font-size: 12px; margin: 0 4px 10px; }
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
  categoryFilter: string | null = null;
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

  // Suspended/inactive shops aren't valid clone sources or targets.
  get activeShops(): Shop[] {
    return this.shops.filter(s => s.isActive !== false && s.status !== ('SUSPENDED' as any));
  }

  get sourceShop(): Shop | undefined {
    return this.shops.find(s => s.id === this.sourceShopId);
  }

  // Same business type as the source shop first (e.g. Grocery -> Grocery),
  // then everything else, so the common case doesn't require scrolling.
  get targetShopOptions(): Shop[] {
    const source = this.sourceShop;
    if (!source) return this.activeShops;
    const matching = this.activeShops.filter(s => s.businessType === source.businessType);
    const rest = this.activeShops.filter(s => s.businessType !== source.businessType);
    return [...matching, ...rest];
  }

  onSourceShopChange(): void {
    this.categoryFilter = null;
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

  categoryOf(product: ShopProduct): string {
    return product.masterProduct?.category?.name || 'Uncategorized';
  }

  get categories(): string[] {
    const names = new Set(this.selections.map(s => this.categoryOf(s.product)));
    return Array.from(names).sort();
  }

  countInCategory(category: string): number {
    return this.selections.filter(s => this.categoryOf(s.product) === category).length;
  }

  get visibleSelections(): CloneSelection[] {
    if (!this.categoryFilter) return this.selections;
    return this.selections.filter(s => this.categoryOf(s.product) === this.categoryFilter);
  }

  get allVisibleSelected(): boolean {
    const visible = this.visibleSelections;
    return visible.length > 0 && visible.every(s => s.selected);
  }

  get someVisibleSelected(): boolean {
    const visible = this.visibleSelections;
    return visible.some(s => s.selected) && !this.allVisibleSelected;
  }

  toggleSelectVisible(checked: boolean): void {
    this.visibleSelections.forEach(s => s.selected = checked);
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

  // Cloning copies each product's images on disk, which can take a while for
  // hundreds/thousands of items — one giant request risks the browser or a
  // reverse proxy timing out (which shows up as a misleading "CORS"/network
  // error, not a real server error). Send it in smaller batches instead.
  private static readonly CLONE_BATCH_SIZE = 100;

  cloneProgress = '';

  cloneSelected(): void {
    if (!this.canClone() || !this.sourceShopId || !this.targetShopId) return;

    const shopProductIds = this.selections.filter(s => s.selected).map(s => s.product.id);
    const batches: number[][] = [];
    for (let i = 0; i < shopProductIds.length; i += CloneProductsComponent.CLONE_BATCH_SIZE) {
      batches.push(shopProductIds.slice(i, i + CloneProductsComponent.CLONE_BATCH_SIZE));
    }

    this.isCloning = true;
    this.runCloneBatches(batches, 0, { clonedCount: 0, skippedCount: 0, skippedReasons: [] });
  }

  private runCloneBatches(batches: number[][], index: number, totals: CloneProductsResponse): void {
    if (!this.sourceShopId || !this.targetShopId) return;

    if (index >= batches.length) {
      this.isCloning = false;
      this.cloneProgress = '';
      const skipped = totals.skippedCount > 0
        ? `<br><br><b>${totals.skippedCount} skipped:</b><br>${totals.skippedReasons.join('<br>')}`
        : '';
      Swal.fire({
        icon: 'success',
        title: 'Products Cloned',
        html: `${totals.clonedCount} product(s) cloned into the target shop.${skipped}`
      });
      return;
    }

    this.cloneProgress = `Cloning ${index + 1} of ${batches.length} batches...`;

    this.shopProductService.cloneProducts(this.targetShopId, this.sourceShopId, batches[index], false).subscribe({
      next: (result: CloneProductsResponse) => {
        totals.clonedCount += result.clonedCount;
        totals.skippedCount += result.skippedCount;
        totals.skippedReasons.push(...(result.skippedReasons || []));
        this.runCloneBatches(batches, index + 1, totals);
      },
      error: (error) => {
        this.isCloning = false;
        this.cloneProgress = '';
        console.error('Error cloning products (batch failed):', error);
        Swal.fire({
          icon: 'error',
          title: 'Clone Stopped',
          html: `${totals.clonedCount} product(s) were cloned before this batch failed: `
              + `${error?.error?.message || 'Could not reach the server'}.<br><br>You can select the remaining products and try again.`
        });
      }
    });
  }
}
