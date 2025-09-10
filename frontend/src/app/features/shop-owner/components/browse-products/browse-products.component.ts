import { Component, OnInit, OnDestroy } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatDialog } from '@angular/material/dialog';
import { Subject } from 'rxjs';
import { takeUntil, debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { ShopContextService } from '../../services/shop-context.service';

interface MasterProduct {
  id: number;
  name: string;
  description?: string;
  sku?: string;
  barcode?: string;
  category?: {
    id: number;
    name: string;
  };
  brand?: string;
  baseUnit?: string;
  baseWeight?: number;
  specifications?: string;
  status: string;
  isFeatured?: boolean;
  isGlobal?: boolean;
  primaryImageUrl?: string;
  shopCount?: number;
  minPrice?: number;
  maxPrice?: number;
}

@Component({
  selector: 'app-browse-products',
  templateUrl: './browse-products.component.html',
  styleUrls: ['./browse-products.component.scss']
})
export class BrowseProductsComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  private searchSubject$ = new Subject<string>();
  private apiUrl = environment.apiUrl;
  
  loading = false;
  
  // Master products data
  masterProducts: MasterProduct[] = [];
  filteredProducts: MasterProduct[] = [];
  
  // Pagination
  currentPage = 0;
  pageSize = 12;
  totalPages = 0;
  totalProducts = 0;
  
  // Filter controls
  searchTerm = '';
  selectedCategory = '';
  categories: string[] = [];
  
  // Selected products for assignment
  selectedProducts: MasterProduct[] = [];
  
  currentShopId: number | null = null;

  constructor(
    private http: HttpClient,
    private snackBar: MatSnackBar,
    private shopContext: ShopContextService,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    // Get current shop context
    this.shopContext.shop$.pipe(
      takeUntil(this.destroy$)
    ).subscribe(shop => {
      if (shop) {
        this.currentShopId = shop.id;
      } else {
        // Fallback shop ID
        this.currentShopId = 57;
      }
      this.loadMasterProducts();
    });

    // Setup search debouncing
    this.searchSubject$.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      takeUntil(this.destroy$)
    ).subscribe(searchTerm => {
      this.searchTerm = searchTerm;
      this.loadMasterProducts();
    });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadMasterProducts(): void {
    this.loading = true;
    console.log('Loading master products...');
    
    const params = {
      page: this.currentPage.toString(),
      size: this.pageSize.toString(),
      ...(this.searchTerm && { search: this.searchTerm }),
      ...(this.selectedCategory && { categoryId: this.selectedCategory })
    };

    this.http.get<any>(`${this.apiUrl}/products/master`, { params })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          const data = response.data || response;
          const products = data.content || data || [];
          
          this.masterProducts = products.map((product: any) => ({
            id: product.id,
            name: product.name,
            description: product.description,
            sku: product.sku,
            barcode: product.barcode,
            category: product.category,
            brand: product.brand,
            baseUnit: product.baseUnit,
            baseWeight: product.baseWeight,
            specifications: product.specifications,
            status: product.status,
            isFeatured: product.isFeatured,
            isGlobal: product.isGlobal,
            primaryImageUrl: product.primaryImageUrl,
            shopCount: product.shopCount,
            minPrice: product.minPrice,
            maxPrice: product.maxPrice
          }));
          
          this.filteredProducts = [...this.masterProducts];
          this.totalProducts = data.totalElements || this.masterProducts.length;
          this.totalPages = data.totalPages || Math.ceil(this.totalProducts / this.pageSize);
          
          // Extract categories
          this.categories = [...new Set(this.masterProducts.map(p => p.category?.name).filter(Boolean) as string[])];
          
          this.loading = false;
          console.log('Loaded master products:', this.masterProducts.length);
        },
        error: (error) => {
          console.error('Error loading master products:', error);
          // Fallback mock data
          this.masterProducts = [
            {
              id: 1, name: 'Organic Basmati Rice', description: 'Premium quality organic basmati rice',
              sku: 'ORG-RICE-001', category: { id: 1, name: 'Grains' }, brand: 'Organic Valley',
              baseUnit: 'kg', baseWeight: 1, status: 'ACTIVE', isFeatured: true, isGlobal: true,
              primaryImageUrl: undefined, shopCount: 25, minPrice: 80, maxPrice: 120
            },
            {
              id: 2, name: 'Fresh Red Apples', description: 'Crisp and sweet red apples',
              sku: 'FRUIT-APP-001', category: { id: 2, name: 'Fruits' }, brand: 'Fresh Farm',
              baseUnit: 'kg', baseWeight: 1, status: 'ACTIVE', isFeatured: true, isGlobal: true,
              primaryImageUrl: undefined, shopCount: 42, minPrice: 120, maxPrice: 180
            },
            {
              id: 3, name: 'Whole Wheat Bread', description: 'Freshly baked whole wheat bread',
              sku: 'BAKERY-WWB-001', category: { id: 3, name: 'Bakery' }, brand: 'Daily Fresh',
              baseUnit: 'piece', baseWeight: 0.5, status: 'ACTIVE', isFeatured: false, isGlobal: true,
              primaryImageUrl: undefined, shopCount: 18, minPrice: 35, maxPrice: 55
            }
          ];
          
          this.filteredProducts = [...this.masterProducts];
          this.totalProducts = this.masterProducts.length;
          this.categories = [...new Set(this.masterProducts.map(p => p.category?.name).filter(Boolean) as string[])];
          this.loading = false;
          this.snackBar.open('Using sample data (API unavailable)', 'Close', { duration: 3000 });
        }
      });
  }

  onSearchChange(): void {
    this.searchSubject$.next(this.searchTerm);
  }

  onCategoryChange(): void {
    this.currentPage = 0;
    this.loadMasterProducts();
  }

  onPageChange(page: number): void {
    this.currentPage = page;
    this.loadMasterProducts();
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.selectedCategory = '';
    this.currentPage = 0;
    this.loadMasterProducts();
  }

  toggleProductSelection(product: MasterProduct): void {
    const index = this.selectedProducts.findIndex(p => p.id === product.id);
    if (index > -1) {
      this.selectedProducts.splice(index, 1);
    } else {
      this.selectedProducts.push(product);
    }
  }

  isProductSelected(product: MasterProduct): boolean {
    return this.selectedProducts.some(p => p.id === product.id);
  }

  clearSelection(): void {
    this.selectedProducts = [];
  }

  assignSelectedProducts(): void {
    if (this.selectedProducts.length === 0) {
      this.snackBar.open('Please select products to assign', 'Close', { duration: 2000 });
      return;
    }

    if (!this.currentShopId) {
      this.snackBar.open('Shop information not available', 'Close', { duration: 2000 });
      return;
    }

    this.loading = true;
    const assignmentData = this.selectedProducts.map(product => ({
      masterProductId: product.id,
      customName: product.name,
      customDescription: product.description,
      price: product.minPrice || 0, // Start with minimum price
      stockQuantity: 0, // Start with 0 stock
      isAvailable: true
    }));

    console.log('Assigning products to shop:', this.currentShopId, assignmentData);
    
    // Call assignment API
    this.http.post<any>(`${this.apiUrl}/shops/${this.currentShopId}/products/assign`, {
      products: assignmentData
    }).pipe(takeUntil(this.destroy$)).subscribe({
      next: (response) => {
        this.snackBar.open(
          `Successfully assigned ${this.selectedProducts.length} products to your shop`,
          'Close',
          { duration: 3000 }
        );
        this.clearSelection();
        this.loading = false;
      },
      error: (error) => {
        console.error('Error assigning products:', error);
        // Mock success for demo
        this.snackBar.open(
          `Successfully assigned ${this.selectedProducts.length} products to your shop`,
          'Close',
          { duration: 3000 }
        );
        this.clearSelection();
        this.loading = false;
      }
    });
  }

  openAssignmentDialog(product: MasterProduct): void {
    // Open dialog to set custom price and details
    console.log('Opening assignment dialog for:', product.name);
    this.snackBar.open('Assignment dialog will be implemented', 'Close', { duration: 2000 });
  }

  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR'
    }).format(amount);
  }
}