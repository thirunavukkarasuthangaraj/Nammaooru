import { Component, OnInit, Inject, ViewChild, ElementRef } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { Subject } from 'rxjs';
import { takeUntil, debounceTime, distinctUntilChanged, switchMap } from 'rxjs/operators';
import { ShopOwnerProductService } from '../../services/shop-owner-product.service';

export interface BrowseMasterProductsDialogData {
  shopId: number;
}

export interface MasterProduct {
  id: number;
  name: string;
  nameTamil?: string;
  description: string;
  sku: string;
  brand: string;
  category: {
    id: number;
    name: string;
  };
  baseUnit: string;
  baseWeight: number;
  status: string;
  isFeatured: boolean;
  primaryImageUrl?: string;
  tags?: string;
}

export interface ProductAssignmentResult {
  masterProduct: MasterProduct;
  customName?: string;
  customDescription?: string;
  sellingPrice: number;
  initialStock: number;
}

@Component({
  selector: 'app-browse-master-products-dialog',
  templateUrl: './browse-master-products-dialog.component.html',
  styleUrls: ['./browse-master-products-dialog.component.scss']
})
export class BrowseMasterProductsDialogComponent implements OnInit {
  private destroy$ = new Subject<void>();
  private searchSubject = new Subject<string>();

  masterProducts: MasterProduct[] = [];
  selectedProduct: MasterProduct | null = null;
  loading = false;
  searchTerm = '';

  // Assignment form fields
  customName = '';
  customDescription = '';
  sellingPrice: number | null = null;
  initialStock = 0;

  constructor(
    public dialogRef: MatDialogRef<BrowseMasterProductsDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: BrowseMasterProductsDialogData,
    private shopOwnerProductService: ShopOwnerProductService
  ) {}

  ngOnInit(): void {
    this.loadMasterProducts();
    
    // Set up search debouncing
    this.searchSubject.pipe(
      takeUntil(this.destroy$),
      debounceTime(300),
      distinctUntilChanged()
    ).subscribe(searchTerm => {
      this.loadMasterProducts(searchTerm);
    });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadMasterProducts(search?: string): void {
    this.loading = true;
    
    this.shopOwnerProductService.getMasterProducts(0, 50, search)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (products) => {
          this.masterProducts = products;
          this.loading = false;
        },
        error: (error) => {
          console.error('Error loading master products:', error);
          this.loading = false;
        }
      });
  }

  onSearchChange(): void {
    this.searchSubject.next(this.searchTerm);
  }

  selectProduct(product: MasterProduct): void {
    this.selectedProduct = product;
    // Pre-fill form with master product data
    this.customName = '';
    this.customDescription = '';
    this.sellingPrice = null;
    this.initialStock = 0;
  }

  assignProduct(): void {
    if (!this.selectedProduct || !this.sellingPrice || this.sellingPrice <= 0) {
      return;
    }

    const result: ProductAssignmentResult = {
      masterProduct: this.selectedProduct,
      customName: this.customName || undefined,
      customDescription: this.customDescription || undefined,
      sellingPrice: this.sellingPrice,
      initialStock: this.initialStock
    };

    this.dialogRef.close(result);
  }

  cancel(): void {
    this.dialogRef.close();
  }
}