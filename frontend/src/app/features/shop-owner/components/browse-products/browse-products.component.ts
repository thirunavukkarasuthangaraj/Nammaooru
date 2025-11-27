import { Component, OnInit, OnDestroy } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatDialog } from '@angular/material/dialog';
import { Subject } from 'rxjs';
import { takeUntil, debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { ShopContextService } from '../../services/shop-context.service';
import { ShopOwnerProductService } from '../../services/shop-owner-product.service';
import { ProductAssignmentDialogComponent, ProductAssignmentData } from '../product-assignment-dialog/product-assignment-dialog.component';
import { getImageUrl as getImageUrlUtil } from '../../../../core/utils/image-url.util';

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
  isNew?: boolean;
  rating?: number;
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
  sortBy = 'name';
  activeFilters: string[] = [];
  categories: string[] = [];
  
  // Selected products for assignment
  selectedProducts: MasterProduct[] = [];
  
  currentShopId: number | null = null;

  constructor(
    private http: HttpClient,
    private snackBar: MatSnackBar,
    private shopContext: ShopContextService,
    private dialog: MatDialog,
    private productService: ShopOwnerProductService
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
    console.log('Loading available master products (excluding already assigned)...');
    
    // Use the new filtered endpoint that excludes products already assigned to the shop
    this.productService.getAvailableMasterProducts(
      this.currentPage, 
      this.pageSize, 
      this.searchTerm || undefined,
      undefined, // categoryId - will implement later
      undefined  // brand - will implement later
    ).pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          const products = response.content || [];
          
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
            isNew: product.isNew,
            rating: product.rating,
            primaryImageUrl: this.getProductImageUrl(product),
            shopCount: product.shopCount,
            minPrice: product.minPrice,
            maxPrice: product.maxPrice
          }));
          
          this.filteredProducts = [...this.masterProducts];
          this.totalProducts = response.totalElements || this.masterProducts.length;
          this.totalPages = Math.ceil(this.totalProducts / this.pageSize);
          
          // Extract categories
          this.categories = [...new Set(this.masterProducts.map(p => p.category?.name).filter(Boolean) as string[])];
          
          this.loading = false;
          console.log('Loaded available master products:', this.masterProducts.length);
        },
        error: (error) => {
          console.error('Error loading available master products:', error);
          // Fallback mock data
          this.masterProducts = [
            {
              id: 1, name: 'Organic Basmati Rice', description: 'Premium quality organic basmati rice',
              sku: 'ORG-RICE-001', category: { id: 1, name: 'Grains' }, brand: 'Organic Valley',
              baseUnit: 'kg', baseWeight: 1, status: 'ACTIVE', isFeatured: true, isGlobal: true,
              primaryImageUrl: '/assets/images/products/rice.jpg', shopCount: 25, minPrice: 80, maxPrice: 120
            },
            {
              id: 2, name: 'Fresh Red Apples', description: 'Crisp and sweet red apples',
              sku: 'FRUIT-APP-001', category: { id: 2, name: 'Fruits' }, brand: 'Fresh Farm',
              baseUnit: 'kg', baseWeight: 1, status: 'ACTIVE', isFeatured: true, isGlobal: true,
              primaryImageUrl: '/assets/images/products/apples.jpg', shopCount: 42, minPrice: 120, maxPrice: 180
            },
            {
              id: 3, name: 'Whole Wheat Bread', description: 'Freshly baked whole wheat bread',
              sku: 'BAKERY-WWB-001', category: { id: 3, name: 'Bakery' }, brand: 'Daily Fresh',
              baseUnit: 'piece', baseWeight: 0.5, status: 'ACTIVE', isFeatured: false, isGlobal: true,
              primaryImageUrl: '/assets/images/products/bread.jpg', shopCount: 18, minPrice: 35, maxPrice: 55
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

    this.loading = true;
    let successCount = 0;
    let errorCount = 0;

    console.log('Assigning products to shop:', this.selectedProducts);

    // Create products one by one using the shop owner endpoint
    const createProduct$ = (product: MasterProduct) => {
      const productData = {
        masterProductId: product.id,
        price: product.minPrice || product.maxPrice || 100, // Use min price or fallback
        stockQuantity: 0, // Start with 0 stock
        isAvailable: true,
        customName: product.name,
        customDescription: product.description
      };

      return this.http.post<any>(`${this.apiUrl}/shop-products/create`, productData);
    };

    // Process all selected products
    const assignments = this.selectedProducts.map(product => 
      createProduct$(product).pipe(
        takeUntil(this.destroy$)
      ).subscribe({
        next: (response) => {
          successCount++;
          console.log(`Successfully assigned product: ${product.name}`);
          
          // Check if all assignments are complete
          if (successCount + errorCount === this.selectedProducts.length) {
            this.handleAssignmentComplete(successCount, errorCount);
          }
        },
        error: (error) => {
          errorCount++;
          console.error(`Error assigning product ${product.name}:`, error);
          
          // Check if all assignments are complete
          if (successCount + errorCount === this.selectedProducts.length) {
            this.handleAssignmentComplete(successCount, errorCount);
          }
        }
      })
    );
  }

  private handleAssignmentComplete(successCount: number, errorCount: number): void {
    this.loading = false;
    
    if (successCount > 0) {
      this.snackBar.open(
        `Successfully assigned ${successCount} products to your shop` + 
        (errorCount > 0 ? ` (${errorCount} failed)` : ''),
        'Close',
        { duration: 4000 }
      );
    } else {
      this.snackBar.open(
        'Failed to assign products. Please try again.',
        'Close',
        { duration: 3000 }
      );
    }
    
    this.clearSelection();
  }

  openAssignmentDialog(product: MasterProduct): void {
    const dialogData: ProductAssignmentData = {
      product: {
        id: product.id,
        name: product.name,
        description: product.description,
        sku: product.sku,
        category: product.category,
        brand: product.brand,
        baseUnit: product.baseUnit,
        primaryImageUrl: product.primaryImageUrl,
        minPrice: product.minPrice,
        maxPrice: product.maxPrice
      }
    };

    const dialogRef = this.dialog.open(ProductAssignmentDialogComponent, {
      width: '600px',
      maxWidth: '90vw',
      data: dialogData,
      disableClose: false
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result?.success) {
        // Refresh the product list to remove assigned product
        this.loadMasterProducts();
      }
    });
  }

  // Sort functionality
  onSortChange(): void {
    this.currentPage = 0;
    this.loadMasterProducts();
  }

  // Filter by tags functionality
  filterByTag(tag: string): void {
    const index = this.activeFilters.indexOf(tag);
    if (index > -1) {
      this.activeFilters.splice(index, 1);
    } else {
      this.activeFilters.push(tag);
    }
    this.currentPage = 0;
    this.loadMasterProducts();
  }

  // Track by function for ngFor performance
  trackByProductId(index: number, product: MasterProduct): number {
    return product.id;
  }

  // Quick view functionality
  quickView(product: MasterProduct): void {
    console.log('Quick view for:', product.name);
    this.snackBar.open('Quick view dialog will be implemented', 'Close', { duration: 2000 });
  }

  // Load products with enhanced functionality
  loadProducts(): void {
    this.loadMasterProducts();
  }

  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR'
    }).format(amount);
  }

  private getProductImageUrl(product: any): string | undefined {
    return getImageUrlUtil(this.getImageUrlFromProduct(product));
  }

  private getImageUrlFromProduct(product: any): string | undefined {
    // Check for primary image from images array
    if (product.images && product.images.length > 0) {
      const primaryImage = product.images.find((img: any) => img.isPrimary);
      if (primaryImage?.imageUrl) {
        return primaryImage.imageUrl;
      }
      // Fallback to first image
      if (product.images[0]?.imageUrl) {
        return product.images[0].imageUrl;
      }
    }

    // Check for primaryImageUrl field
    if (product.primaryImageUrl) {
      return product.primaryImageUrl;
    }

    return undefined;
  }
}