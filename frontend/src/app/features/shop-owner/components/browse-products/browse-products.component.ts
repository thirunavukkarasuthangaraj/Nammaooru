import { Component, OnInit, OnDestroy } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { ShopContextService } from '../../services/shop-context.service';

interface Shop {
  id: number;
  name: string;
  description?: string;
  category?: string;
  rating?: number;
  location?: string;
  isActive: boolean;
}

interface ShopProduct {
  id: number;
  customName: string;
  description?: string;
  price: number;
  stockQuantity: number;
  isAvailable: boolean;
  status: string;
  imageUrl?: string;
  category?: string;
  unit?: string;
  sku?: string;
  shopId: number;
  shopName: string;
  masterProductId?: number;
  masterProductName?: string;
}

@Component({
  selector: 'app-browse-products',
  templateUrl: './browse-products.component.html',
  styleUrls: ['./browse-products.component.scss']
})
export class BrowseProductsComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  private apiUrl = environment.apiUrl;
  
  loading = false;
  selectedShop: Shop | null = null;
  
  // Shops data
  shops: Shop[] = [];
  filteredShops: Shop[] = [];
  
  // Products data
  products: ShopProduct[] = [];
  filteredProducts: ShopProduct[] = [];
  
  // Filter controls
  searchTerm = '';
  selectedCategory = '';
  categories: string[] = [];
  
  // Selected products for import
  selectedProducts: ShopProduct[] = [];
  
  currentShopId: number | null = null;

  constructor(
    private http: HttpClient,
    private snackBar: MatSnackBar,
    private shopContext: ShopContextService
  ) {}

  ngOnInit(): void {
    // Get current shop context
    this.shopContext.shop$.pipe(
      takeUntil(this.destroy$)
    ).subscribe(shop => {
      if (shop) {
        this.currentShopId = shop.id;
        this.loadShops();
      }
    });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadShops(): void {
    this.loading = true;
    console.log('Loading shops...');
    
    this.http.get<any>(`${this.apiUrl}/shops/active`)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          const data = response.data || response;
          const shopList = data.content || data || [];
          
          // Filter out current shop
          this.shops = shopList
            .filter((shop: any) => shop.id !== this.currentShopId)
            .map((shop: any) => ({
              id: shop.id,
              name: shop.name,
              description: shop.description,
              category: shop.category?.name,
              rating: shop.rating || 0,
              location: shop.address,
              isActive: shop.isActive
            }));
          
          this.filteredShops = [...this.shops];
          this.loading = false;
          console.log('Loaded shops:', this.shops);
        },
        error: (error) => {
          console.error('Error loading shops:', error);
          // Fallback data
          this.shops = [
            { id: 1, name: 'Green Valley Organics', description: 'Fresh organic products', category: 'Grocery', rating: 4.5, location: 'HSR Layout', isActive: true },
            { id: 2, name: 'Tech Hub Electronics', description: 'Latest electronics and gadgets', category: 'Electronics', rating: 4.2, location: 'Koramangala', isActive: true },
            { id: 3, name: 'Fashion Forward', description: 'Trendy clothing and accessories', category: 'Fashion', rating: 4.0, location: 'Brigade Road', isActive: true }
          ].filter(shop => shop.id !== this.currentShopId);
          
          this.filteredShops = [...this.shops];
          this.loading = false;
          this.snackBar.open('Using sample data (API unavailable)', 'Close', { duration: 3000 });
        }
      });
  }

  selectShop(shop: Shop): void {
    this.selectedShop = shop;
    this.loadShopProducts(shop.id);
  }

  loadShopProducts(shopId: number): void {
    this.loading = true;
    console.log('Loading products for shop:', shopId);
    
    this.http.get<any>(`${this.apiUrl}/shop-products/shop/${shopId}/public`)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          const data = response.data || response;
          const products = data.content || data || [];
          
          this.products = products.map((p: any) => ({
            id: p.id,
            customName: p.displayName || p.customName || p.masterProduct?.name,
            description: p.displayDescription || p.customDescription || p.masterProduct?.description,
            price: p.price,
            stockQuantity: p.stockQuantity,
            isAvailable: p.isAvailable,
            status: p.status,
            category: p.masterProduct?.category?.name,
            unit: p.masterProduct?.baseUnit,
            sku: p.masterProduct?.sku,
            imageUrl: p.primaryImageUrl,
            shopId: shopId,
            shopName: this.selectedShop?.name || '',
            masterProductId: p.masterProduct?.id,
            masterProductName: p.masterProduct?.name
          }));
          
          this.filteredProducts = [...this.products];
          this.categories = [...new Set(this.products.map(p => p.category).filter(Boolean) as string[])];
          this.applyFilters();
          this.loading = false;
        },
        error: (error) => {
          console.error('Error loading shop products:', error);
          // Fallback data
          this.products = [
            { id: 101, customName: 'Organic Apples', description: 'Fresh red apples', price: 120, stockQuantity: 50, isAvailable: true, status: 'ACTIVE', category: 'Fruits', unit: 'kg', sku: 'ORG-APP-001', shopId, shopName: this.selectedShop?.name || '', masterProductId: 1 },
            { id: 102, customName: 'Brown Rice', description: 'Healthy brown rice', price: 80, stockQuantity: 30, isAvailable: true, status: 'ACTIVE', category: 'Grains', unit: 'kg', sku: 'BR-RICE-001', shopId, shopName: this.selectedShop?.name || '', masterProductId: 2 },
            { id: 103, customName: 'Whole Wheat Bread', description: 'Fresh baked bread', price: 45, stockQuantity: 20, isAvailable: true, status: 'ACTIVE', category: 'Bakery', unit: 'piece', sku: 'WW-BREAD-001', shopId, shopName: this.selectedShop?.name || '', masterProductId: 3 }
          ];
          
          this.filteredProducts = [...this.products];
          this.categories = [...new Set(this.products.map(p => p.category).filter(Boolean) as string[])];
          this.loading = false;
          this.snackBar.open('Using sample data (API unavailable)', 'Close', { duration: 3000 });
        }
      });
  }

  applyFilters(): void {
    this.filteredProducts = this.products.filter(product => {
      const matchesSearch = !this.searchTerm || 
        product.customName.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        product.description?.toLowerCase().includes(this.searchTerm.toLowerCase());
      
      const matchesCategory = !this.selectedCategory || product.category === this.selectedCategory;
      
      return matchesSearch && matchesCategory && product.isAvailable;
    });
  }

  onSearchChange(): void {
    this.applyFilters();
  }

  onCategoryChange(): void {
    this.applyFilters();
  }

  toggleProductSelection(product: ShopProduct): void {
    const index = this.selectedProducts.findIndex(p => p.id === product.id);
    if (index > -1) {
      this.selectedProducts.splice(index, 1);
    } else {
      this.selectedProducts.push(product);
    }
  }

  isProductSelected(product: ShopProduct): boolean {
    return this.selectedProducts.some(p => p.id === product.id);
  }

  clearSelection(): void {
    this.selectedProducts = [];
  }

  importSelectedProducts(): void {
    if (this.selectedProducts.length === 0) {
      this.snackBar.open('Please select products to import', 'Close', { duration: 2000 });
      return;
    }

    this.loading = true;
    const importData = this.selectedProducts.map(product => ({
      masterProductId: product.masterProductId,
      customName: product.customName,
      customDescription: product.description,
      price: product.price,
      stockQuantity: 0, // Start with 0 stock, shop owner can update later
      isAvailable: true
    }));

    console.log('Importing products:', importData);
    
    // Mock API call
    setTimeout(() => {
      this.snackBar.open(
        `Successfully imported ${this.selectedProducts.length} products to your shop`,
        'Close',
        { duration: 3000 }
      );
      this.clearSelection();
      this.loading = false;
    }, 2000);
  }

  goBack(): void {
    this.selectedShop = null;
    this.products = [];
    this.filteredProducts = [];
    this.categories = [];
    this.clearSelection();
  }

  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR'
    }).format(amount);
  }
}