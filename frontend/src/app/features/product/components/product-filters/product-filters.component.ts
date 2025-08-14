import { Component, Output, EventEmitter, OnInit } from '@angular/core';
import { FormBuilder, FormGroup } from '@angular/forms';
import { ProductFilters, ProductStatus } from '../../../../core/models/product.model';
import { ProductCategoryService } from '../../../../core/services/product-category.service';
import { ProductService } from '../../../../core/services/product.service';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';

@Component({
  selector: 'app-product-filters',
  template: `
    <form [formGroup]="filterForm" class="filters-form">
      <div class="filters-row">
        <mat-form-field appearance="outline" class="search-field">
          <mat-label>Search products...</mat-label>
          <input matInput formControlName="search" placeholder="Name, SKU, description">
          <mat-icon matSuffix>search</mat-icon>
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Category</mat-label>
          <mat-select formControlName="categoryId">
            <mat-option [value]="null">All Categories</mat-option>
            <mat-option *ngFor="let category of categories" [value]="category.id">
              {{ category.name }}
            </mat-option>
          </mat-select>
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Brand</mat-label>
          <mat-select formControlName="brand">
            <mat-option [value]="null">All Brands</mat-option>
            <mat-option *ngFor="let brand of brands" [value]="brand">
              {{ brand }}
            </mat-option>
          </mat-select>
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Status</mat-label>
          <mat-select formControlName="status">
            <mat-option [value]="null">All Status</mat-option>
            <mat-option value="ACTIVE">Active</mat-option>
            <mat-option value="INACTIVE">Inactive</mat-option>
            <mat-option value="DISCONTINUED">Discontinued</mat-option>
          </mat-select>
        </mat-form-field>

        <mat-slide-toggle formControlName="isFeatured" class="featured-toggle">
          Featured Only
        </mat-slide-toggle>

        <button mat-button type="button" (click)="clearFilters()" class="clear-btn">
          <mat-icon>clear</mat-icon>
          Clear
        </button>
      </div>
    </form>
  `,
  styles: [`
    .filters-form {
      padding: 16px;
    }

    .filters-row {
      display: grid;
      grid-template-columns: 2fr 1fr 1fr 1fr auto auto;
      gap: 16px;
      align-items: start;
    }

    .search-field {
      min-width: 200px;
    }

    .featured-toggle {
      margin-top: 8px;
    }

    .clear-btn {
      margin-top: 8px;
      color: #666;
    }

    @media (max-width: 1024px) {
      .filters-row {
        grid-template-columns: 1fr 1fr;
        gap: 12px;
      }
    }

    @media (max-width: 768px) {
      .filters-row {
        grid-template-columns: 1fr;
        gap: 8px;
      }
    }
  `]
})
export class ProductFiltersComponent implements OnInit {
  @Output() filtersChange = new EventEmitter<ProductFilters>();
  
  filterForm: FormGroup;
  categories: any[] = [];
  brands: string[] = [];

  constructor(
    private fb: FormBuilder,
    private categoryService: ProductCategoryService,
    private productService: ProductService
  ) {
    this.filterForm = this.fb.group({
      search: [''],
      categoryId: [null],
      brand: [null],
      status: [null],
      isFeatured: [false]
    });
  }

  ngOnInit(): void {
    this.loadFilterOptions();
    this.setupFilterSubscription();
  }

  private loadFilterOptions(): void {
    this.categoryService.getRootCategories().subscribe(categories => {
      this.categories = categories;
    });

    this.productService.getAllBrands().subscribe(brands => {
      this.brands = brands;
    });
  }

  private setupFilterSubscription(): void {
    this.filterForm.valueChanges.pipe(
      debounceTime(300),
      distinctUntilChanged()
    ).subscribe(filters => {
      const cleanFilters: ProductFilters = {};
      
      Object.keys(filters).forEach(key => {
        if (filters[key] !== null && filters[key] !== '' && filters[key] !== false) {
          (cleanFilters as any)[key] = filters[key];
        }
      });

      this.filtersChange.emit(cleanFilters);
    });
  }

  clearFilters(): void {
    this.filterForm.reset();
    this.filtersChange.emit({});
  }
}