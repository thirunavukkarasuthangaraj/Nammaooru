import { Component, OnInit, ViewChild, OnDestroy, ElementRef, AfterViewInit, AfterViewChecked } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatTabChangeEvent } from '@angular/material/tabs';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Router, ActivatedRoute } from '@angular/router';
import { Subject } from 'rxjs';
import { takeUntil, debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { ShopContextService } from '../../services/shop-context.service';
import { OfflineStorageService, CachedProduct, OfflineEdit } from '../../../../core/services/offline-storage.service';
import { getImageUrl as getImageUrlUtil } from '../../../../core/utils/image-url.util';
import { PriceUpdateDialogComponent, PriceUpdateData } from '../price-update-dialog/price-update-dialog.component';
import { StockUpdateDialogComponent, StockUpdateData } from '../stock-update-dialog/stock-update-dialog.component';
import { BulkPriceUpdateDialogComponent } from '../bulk-price-update-dialog/bulk-price-update-dialog.component';
import { BrowseMasterProductsDialogComponent, ProductAssignmentResult } from '../browse-master-products-dialog/browse-master-products-dialog.component';
import { ProductEditDialogComponent } from '../product-edit-dialog/product-edit-dialog.component';
import { ShopOwnerProductService } from '../../services/shop-owner-product.service';
import { SwalService } from '../../../../core/services/swal.service';
import { ProductCategoryService } from '../../../../core/services/product-category.service';

interface MasterProduct {
  id?: number;
  name?: string;
  nameTamil?: string;
  description?: string;
  baseUnit?: string;
  sku?: string;
  tags?: string;
  category?: {
    id?: number;
    name?: string;
  };
}

interface ShopProduct {
  id: number;
  customName: string;
  description?: string;
  price: number;
  originalPrice?: number;
  costPrice?: number;
  stockQuantity: number;
  isAvailable: boolean;
  status: string;
  imageUrl?: string;
  category?: string;
  unit?: string;
  sku?: string;
  // Barcode fields for search
  barcode?: string;
  barcode1?: string;
  barcode2?: string;
  barcode3?: string;
  masterProductId?: number;
  masterProductName?: string;
  masterProduct?: MasterProduct;
  createdAt: string;
  updatedAt: string;
}


@Component({
  selector: 'app-my-products',
  templateUrl: './my-products.component.html',
  styleUrls: ['./my-products.component.scss']
})
export class MyProductsComponent implements OnInit, OnDestroy, AfterViewInit {
  private destroy$ = new Subject<void>();
  private searchSubject$ = new Subject<string>();
  private apiUrl = environment.apiUrl;

  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;
  @ViewChild('scrollableContent') scrollableContent!: ElementRef;
  @ViewChild('searchInput') searchInput!: ElementRef<HTMLInputElement>;

  // Product data
  products: ShopProduct[] = [];
  filteredProducts: ShopProduct[] = [];
  categories: string[] = [];
  filteredCategories: string[] = [];
  categoryFilterText = '';
  loading = false;
  searching = false;
  usingFallbackData = false;


  shopId: number | null = null;

  // Filter controls
  searchTerm = '';
  selectedCategory = '';
  selectedStatus = '';
  // Stock filter driven by dashboard tiles (?stock=out / ?stock=low)
  stockFilter: '' | 'low' | 'out' = '';
  
  // Bulk selection
  selectedProducts: ShopProduct[] = [];
  selectAll = false;
  
  // Pagination
  totalProducts = 0;
  pageSize = 20;
  pageSizeOptions = [20, 50, 100, 200];
  currentPageIndex = 0;

  // Infinite scroll
  displayLimit = 20;
  loadingMore = false;
  private readonly LOAD_INCREMENT = 20;

  // Check if user is searching (to show/hide paginator)
  get isSearching(): boolean {
    return !!(this.searchTerm && this.searchTerm.trim().length > 0);
  }

  // Getter for displayed products (infinite scroll or paginated based on search)
  get paginatedProducts(): ShopProduct[] {
    if (this.isSearching) {
      // When searching, use traditional pagination
      const start = this.currentPageIndex * this.pageSize;
      const end = start + this.pageSize;
      return this.filteredProducts.slice(start, end);
    } else {
      // When not searching, use infinite scroll (show up to displayLimit)
      return this.filteredProducts.slice(0, this.displayLimit);
    }
  }

  // Check if there are more products to load
  get hasMoreProducts(): boolean {
    return !this.isSearching && this.displayLimit < this.filteredProducts.length;
  }
  
  // Table columns
  displayedColumns: string[] = ['select', 'image', 'name', 'price', 'stock', 'status', 'actions'];

  // Track if loaded from cache
  loadedFromCache = false;

  private readonly CACHE_TIMESTAMP_KEY = 'my_products_last_sync';

  constructor(
    private router: Router,
    private route: ActivatedRoute,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private http: HttpClient,
    private shopContext: ShopContextService,
    private shopOwnerProductService: ShopOwnerProductService,
    private offlineStorage: OfflineStorageService,
    private elementRef: ElementRef,
    private swalService: SwalService,
    private categoryService: ProductCategoryService
  ) {}

  // Scroll event handler for infinite scroll (called from template)
  onContentScroll(event: Event): void {
    if (this.isSearching || this.loading || this.loadingMore || !this.hasMoreProducts) {
      return;
    }

    const element = event.target as HTMLElement;
    const scrollPosition = element.scrollTop + element.clientHeight;
    const scrollHeight = element.scrollHeight;
    const threshold = 200; // Load more when within 200px of bottom

    if (scrollPosition >= scrollHeight - threshold) {
      this.loadMoreProducts();
    }
  }

  // Load more products for infinite scroll
  loadMoreProducts(): void {
    if (this.loadingMore || !this.hasMoreProducts) {
      return;
    }

    this.loadingMore = true;

    // Simulate a slight delay for smoother UX
    setTimeout(() => {
      this.displayLimit += this.LOAD_INCREMENT;
      this.loadingMore = false;
    }, 100);
  }

  ngAfterViewInit(): void {
    // Auto-focus search box when page loads (e.g., after creating a product)
    setTimeout(() => {
      this.searchInput?.nativeElement?.focus();
    }, 300);
  }

  ngOnInit(): void {
    // Stock filter from dashboard tiles: /my-products?stock=out or ?stock=low
    this.route.queryParams.pipe(takeUntil(this.destroy$)).subscribe(params => {
      const stock = params['stock'];
      this.stockFilter = stock === 'out' || stock === 'low' ? stock : '';
      const category = params['category'];
      if (category) {
        this.selectedCategory = category;
        this.categoryFilterText = category;
      }
      if (this.products.length > 0) {
        this.applyFilters();
      }
    });

    // Always load products immediately - /my-products uses JWT token to identify user's shop
    console.log('Loading products for current authenticated user');
    this.loadProducts();
    this.loadCategories();

    // Subscribe to search input with minimal debounce for instant client-side filtering
    this.searchSubject$.pipe(
      debounceTime(50), // Reduced from 300ms for instant feel
      distinctUntilChanged(),
      takeUntil(this.destroy$)
    ).subscribe(searchTerm => {
      this.searchTerm = searchTerm;
      this.applyFilters(); // Filter locally (instant)
    });

    // Then also subscribe to shop context for updates
    this.shopContext.shop$.pipe(
      takeUntil(this.destroy$)
    ).subscribe(shop => {
      if (shop && shop.id && shop.id !== this.shopId) {
        // Update shop ID if we get a different one from context
        this.shopId = shop.id;
        localStorage.setItem('current_shop_id', shop.id.toString());
        console.log('Updated shop ID from context:', this.shopId);
        this.loadProducts();
        this.loadCategories();
      }
    });

    // Trigger shop context refresh in background
    setTimeout(() => {
      this.shopContext.refreshShop();
    }, 100);
  }
  
  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  async loadProducts(force: boolean = false): Promise<void> {
    this.loading = true;
    this.searching = false;
    console.log('Loading ALL products for authenticated user');

    // Step 1: Load from local cache first (instant)
    try {
      let cachedProducts = await this.offlineStorage.getProducts();

      // Also load pending offline-created products and merge them (avoid duplicates)
      try {
        const pendingCreations = await this.offlineStorage.getPendingProductCreations();
        if (pendingCreations.length > 0) {
          console.log(`Found ${pendingCreations.length} pending offline products`);

          // Filter out creations that already exist in cache (by tempProductId, barcode, or name match)
          const newCreations = pendingCreations.filter(creation => {
            const creationBarcode = creation.barcode1?.toLowerCase();
            const creationName = (creation.name || creation.customName)?.toLowerCase();
            const creationTempId = creation.tempProductId;

            return !cachedProducts.some(p => {
              // Match by tempProductId (most reliable for edited offline products)
              if (creationTempId && p.id === creationTempId) {
                return true;
              }
              // Match by barcode (handles renamed products)
              if (creationBarcode && (
                p.barcode1?.toLowerCase() === creationBarcode ||
                p.barcode?.toLowerCase() === creationBarcode
              )) {
                return true;
              }
              // Match by name (for products without barcode)
              if (!creationBarcode && creationName && p.name?.toLowerCase() === creationName) {
                return true;
              }
              return false;
            });
          });

          if (newCreations.length > 0) {
            const offlineProducts: CachedProduct[] = newCreations.map(creation => ({
              // Use stored tempProductId if available to maintain consistency
              id: creation.tempProductId || this.offlineStorage.generateTempProductId(),
              shopId: creation.shopId,
              name: creation.name || creation.customName || 'New Product',
              nameTamil: creation.nameTamil,
              price: creation.price,
              originalPrice: creation.originalPrice,
              costPrice: creation.costPrice,
              stock: creation.stockQuantity,
              trackInventory: creation.trackInventory,
              isAvailable: true,
              sku: creation.sku || '',
              barcode: creation.barcode1,
              barcode1: creation.barcode1,
              barcode2: creation.barcode2,
              barcode3: creation.barcode3,
              category: creation.categoryName,
              unit: creation.unit,
              masterProductId: creation.masterProductId
            }));
            cachedProducts = [...offlineProducts, ...cachedProducts];
          }
        }
      } catch (err) {
        console.warn('Failed to load pending offline products:', err);
      }

      if (cachedProducts.length > 0) {
        console.log(`Loaded ${cachedProducts.length} products from local cache (including offline)`);
        this.loadedFromCache = true;
        this.mapCachedProducts(cachedProducts);
        this.loading = false;
      }
    } catch (error) {
      console.warn('Error loading from cache:', error);
    }

    // Step 2: Sync from server only when there's genuinely nothing cached yet,
    // or the caller explicitly asked for a refresh. Offline-first: re-opening
    // this screen must never trigger a network call on its own - that was
    // firing on every visit once 5 minutes had passed, making it feel slow.
    if (navigator.onLine && (!this.loadedFromCache || force)) {
      this.syncProductsFromServer();
    } else {
      this.loading = false;
    }
  }

  /**
   * Force refresh products from server (ignores cache)
   */
  forceRefreshProducts(): void {
    this.loadProducts(true);
  }

  /**
   * Map cached products to ShopProduct format
   */
  private mapCachedProducts(cachedProducts: CachedProduct[]): void {
    this.products = cachedProducts.map((p: CachedProduct) => ({
      id: p.id,
      customName: p.name,
      description: p.description || '',
      price: p.price,
      originalPrice: p.originalPrice,
      costPrice: p.costPrice,
      stockQuantity: p.stock,
      isAvailable: p.isAvailable !== false,
      status: p.isAvailable !== false ? 'ACTIVE' : 'INACTIVE',
      category: p.category || '',
      unit: p.unit || 'piece',
      sku: p.sku || '',
      barcode: p.barcode || '',
      barcode1: p.barcode1 || '',
      barcode2: p.barcode2 || '',
      barcode3: p.barcode3 || '',
      imageUrl: p.imageUrl || '',
      masterProductId: p.masterProductId,
      masterProductName: p.name,
      masterProduct: undefined,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    }));

    this.usingFallbackData = false;
    this.selectedProducts = [];
    this.selectAll = false;
    this.applyFilters();
    this.loadCategories();
    this.updateSelectAllState();
    this.currentPageIndex = 0;
  }

  /**
   * Sync products from server (background)
   */
  private async syncProductsFromServer(): Promise<void> {
    const pageSize = 500;
    const allRaw: any[] = [];
    let currentPage = 0;
    let totalPages = 1;
    let totalElements = -1;

    try {
      while (currentPage < totalPages) {
        const params = new HttpParams()
          .set('page', String(currentPage))
          .set('size', String(pageSize));

        const response: any = await this.http.get<any>(
          `${this.apiUrl}/shop-products/my-products`, { params }
        ).pipe(takeUntil(this.destroy$)).toPromise();

        // takeUntil fired (navigation/destroy) — the request was cancelled, not empty.
        // Abort without touching cache or UI so a partial list is never saved as truth.
        if (response === undefined || response === null) {
          console.warn('syncProductsFromServer: sync cancelled mid-flight, keeping existing data');
          return;
        }

        let content: any[] = [];
        if (response?.data?.content) {
          content = response.data.content;
          totalPages = response.data.totalPages || 1;
          if (typeof response.data.totalElements === 'number') {
            totalElements = response.data.totalElements;
          }
        } else if (Array.isArray(response?.data)) {
          content = response.data;
          totalPages = 1;
        } else if (Array.isArray(response)) {
          content = response;
          totalPages = 1;
        }
        if (content.length === 0) break;
        allRaw.push(...content);

        currentPage++;
        if (currentPage > 200) {
          console.warn('syncProductsFromServer: page guard hit (200) — stopping');
          break;
        }
      }

      // Incomplete sync (a page failed or came back short): never overwrite good
      // cached data with a partial list — that's what caused wrong product counts.
      const syncComplete = totalElements < 0 || allRaw.length >= totalElements;
      if (!syncComplete && this.loadedFromCache) {
        console.warn(`syncProductsFromServer: incomplete sync (${allRaw.length}/${totalElements}), keeping cached data`);
        this.loading = false;
        return;
      }

      const products = allRaw;
      console.log(`Loaded ${products.length} products across ${currentPage} page(s)`);

          // Map API response to component interface
          const serverProducts = products.map((p: any) => {
            return {
              id: p.id,
              customName: p.displayName || p.customName || p.masterProduct?.name,
              description: p.displayDescription || p.customDescription || p.masterProduct?.description,
              price: p.price,
              originalPrice: p.originalPrice,
              costPrice: p.costPrice,
              stockQuantity: p.stockQuantity,
              isAvailable: p.isAvailable,
              status: p.status,
              category: p.masterProduct?.category?.name,
              unit: p.baseUnit || p.masterProduct?.baseUnit,
              sku: p.sku || p.masterProduct?.sku,
              // Barcode fields for search
              barcode: p.barcode || p.masterProduct?.barcode || '',
              barcode1: p.barcode1 || '',
              barcode2: p.barcode2 || '',
              barcode3: p.barcode3 || '',
              imageUrl: p.primaryImageUrl,
              masterProductId: p.masterProduct?.id,
              masterProductName: p.masterProduct?.name,
              masterProduct: p.masterProduct ? {
                id: p.masterProduct.id,
                name: p.masterProduct.name,
                nameTamil: p.masterProduct.nameTamil,
                description: p.masterProduct.description,
                baseUnit: p.masterProduct.baseUnit,
                sku: p.masterProduct.sku,
                tags: p.masterProduct.tags,
                category: p.masterProduct.category
              } : undefined,
              createdAt: p.createdAt,
              updatedAt: p.updatedAt
            };
          });

          // Set products from server immediately (before async merge)
          this.products = serverProducts;

          // Save to IndexedDB only when the sync is complete — caching a partial
          // list would show a low product count for the next 5 minutes.
          if (syncComplete) {
            this.saveProductsToCache(serverProducts);
          } else {
            this.snackBar.open(`Only ${serverProducts.length} of ${totalElements} products loaded. Pull to refresh or retry.`, 'Retry', {
              duration: 10000,
              panelClass: ['warning-snackbar']
            }).onAction().subscribe(() => this.forceRefreshProducts());
          }

          this.usingFallbackData = false;
          this.loadedFromCache = false;
          // Clear previous selections when reloading products
          this.selectedProducts = [];
          this.selectAll = false;
          // Apply client-side filters (like mobile app does)
          this.applyFilters();
          this.loadCategories();
          this.updateSelectAllState();
          this.currentPageIndex = 0;
          this.loading = false;
          console.log('Synced products from server:', this.products.length, 'items');

          // Merge pending offline-created products (async - will re-apply filters if any found)
          this.mergeOfflineProducts(serverProducts);
    } catch (error: any) {
          console.error('Product API error:', error);
          this.loading = false;

          // If we already loaded from cache, don't show error or use fallback
          if (this.loadedFromCache) {
            console.log('Using cached data - server sync failed');
            return;
          }

          console.error('Error details:', {
            status: error?.status,
            statusText: error?.statusText,
            message: error?.message,
            url: error?.url
          });
          // No cache and the sync failed: show an honest empty state with retry
          // instead of fake sample products (which read as a "low product count").
          this.products = [];
          this.filteredProducts = [];
          this.totalProducts = 0;
          this.usingFallbackData = false;
          this.selectedProducts = [];
          this.selectAll = false;
          this.loadCategories();
          this.updateSelectAllState();
          this.currentPageIndex = 0;
          this.loading = false;
          this.searching = false;

          this.snackBar.open('Could not load products. Check your connection and try again.', 'Retry', {
            duration: 10000,
            panelClass: ['warning-snackbar']
          }).onAction().subscribe(() => this.forceRefreshProducts());
    }
  }

  loadCategories(): void {
    // Master category list (includes newly created categories with no products assigned yet)
    this.categoryService.getCategories(undefined, true, undefined, 0, 500).subscribe({
      next: (page) => {
        const masterNames = (page.content || []).map(c => c.name);
        const productNames = this.products.map(p => p.category).filter(Boolean) as string[];
        this.categories = [...new Set([...masterNames, ...productNames])].sort();
        this.filteredCategories = this.categories;
      },
      error: () => {
        // Fall back to categories in use if the master list can't be fetched
        this.categories = [...new Set(this.products.map(p => p.category).filter(Boolean) as string[])];
        this.filteredCategories = this.categories;
      }
    });
  }

  /** Filters the Category autocomplete options as the user types directly in the field. */
  filterCategoryOptions(): void {
    const term = this.categoryFilterText.toLowerCase().trim();
    this.filteredCategories = !term
      ? this.categories
      : this.categories.filter(c => c.toLowerCase().includes(term));
  }

  applyFilter(): void {
    this.applyFilters();
  }

  /** Remove the dashboard stock filter and show the full list again */
  clearStockFilter(): void {
    this.stockFilter = '';
    this.router.navigate([], { relativeTo: this.route, queryParams: {}, replaceUrl: true });
    this.applyFilters();
  }

  getActiveCount(): number {
    return this.products.filter(p => p.status === 'ACTIVE' || p.isAvailable === true).length;
  }

  getInactiveCount(): number {
    return this.products.filter(p => p.status === 'INACTIVE' || p.isAvailable === false).length;
  }

  applyFilters(): void {
    const searchLower = this.searchTerm?.toLowerCase().trim() || '';

    this.filteredProducts = this.products.filter(product => {
      // Search matching by name, SKU only (not category - use dropdown for that)
      const matchesName = !searchLower ||
        (product.customName || '').toLowerCase().includes(searchLower) ||
        (product.masterProductName || '').toLowerCase().includes(searchLower) ||
        (product.sku || '').toLowerCase().includes(searchLower);

      // Search matching by barcode fields
      const matchesBarcode = !searchLower ||
        (product.barcode && product.barcode.toLowerCase().includes(searchLower)) ||
        (product.barcode1 && product.barcode1.toLowerCase().includes(searchLower)) ||
        (product.barcode2 && product.barcode2.toLowerCase().includes(searchLower)) ||
        (product.barcode3 && product.barcode3.toLowerCase().includes(searchLower));

      const matchesSearch = matchesName || matchesBarcode;

      const matchesCategory = !this.selectedCategory || product.category === this.selectedCategory;
      const matchesStatus = !this.selectedStatus ||
        product.status === this.selectedStatus ||
        (this.selectedStatus === 'available' && product.isAvailable) ||
        (this.selectedStatus === 'unavailable' && !product.isAvailable);

      // Stock filter from dashboard: out = zero stock, low = below 10 (matches getStockClass)
      const qty = product.stockQuantity ?? 0;
      const matchesStock = !this.stockFilter ||
        (this.stockFilter === 'out' && qty === 0) ||
        (this.stockFilter === 'low' && qty > 0 && qty < 10);

      return matchesSearch && matchesCategory && matchesStatus && matchesStock;
    });

    // Sort: offline products (negative IDs) first, then by ID descending
    this.filteredProducts.sort((a, b) => {
      const aIsOffline = a.id < 0;
      const bIsOffline = b.id < 0;
      // Offline products come first
      if (aIsOffline && !bIsOffline) return -1;
      if (!aIsOffline && bIsOffline) return 1;
      // Within same category, sort by ID descending (newest first)
      return b.id - a.id;
    });

    this.totalProducts = this.filteredProducts.length;

    // Reset to first page when filters change
    this.currentPageIndex = 0;

    // Reset infinite scroll display limit when filters change
    this.displayLimit = this.LOAD_INCREMENT;

    // Clean up selection - remove products that are no longer in filtered results
    this.selectedProducts = this.selectedProducts.filter(selected =>
      this.filteredProducts.some(filtered => filtered.id === selected.id)
    );

    // Update select all state after filtering
    this.updateSelectAllState();

    this.loadCategories(); // Update categories based on filtered products
  }

  onStatusDropdownChange(product: ShopProduct, event: Event): void {
    const newStatus = (event.target as HTMLSelectElement).value;
    const isAvailable = newStatus === 'ACTIVE';
    product.status = newStatus;
    product.isAvailable = isAvailable;

    // Always update local cache
    this.offlineStorage.updateLocalProduct(product.id, { isAvailable }).catch(err =>
      console.warn('Failed to update offline cache:', err)
    );

    if (this.usingFallbackData) {
      this.swalService.toast(`Product ${isAvailable ? 'activated' : 'deactivated'} (demo mode)`, 'success');
      return;
    }

    if (!navigator.onLine) {
      // Save as offline edit so it syncs when internet returns
      this.saveEditOffline(product.id, { isAvailable }, { isAvailable: !isAvailable });
      this.swalService.toast(`Product ${isAvailable ? 'activated' : 'deactivated'} (saved offline)`, 'success');
      return;
    }

    this.http.patch(`${this.apiUrl}/shop-products/${product.id}/availability`, {
      isAvailable: isAvailable
    }).pipe(takeUntil(this.destroy$))
    .subscribe({
      next: () => {
        this.swalService.toast(`Product ${isAvailable ? 'activated' : 'deactivated'} successfully`, 'success');
      },
      error: (error) => {
        console.error('Error updating product status:', error);
        product.isAvailable = !isAvailable;
        product.status = isAvailable ? 'INACTIVE' : 'ACTIVE';
        this.swalService.toast('Failed to update product status', 'error');
      }
    });
  }

  getStatusClass(status: string): string {
    switch (status?.toUpperCase()) {
      case 'ACTIVE': return 'status-active';
      case 'INACTIVE': return 'status-inactive';
      case 'OUT_OF_STOCK': return 'status-out-of-stock';
      default: return 'status-unknown';
    }
  }

  getStockClass(quantity: number): string {
    if (quantity === 0) return 'stock-out';
    if (quantity < 10) return 'stock-low';
    return 'stock-good';
  }

  getProductImageUrl(product: ShopProduct): string {
    if (!product.imageUrl) {
      return 'assets/images/product-placeholder.svg';
    }

    return getImageUrlUtil(product.imageUrl) || 'assets/images/product-placeholder.svg';
  }

  toggleAvailability(product: ShopProduct): void {
    product.isAvailable = !product.isAvailable;
    product.status = product.isAvailable ? 'ACTIVE' : 'INACTIVE';
    
    if (this.usingFallbackData) {
      this.swalService.toast(`Product ${product.isAvailable ? 'activated' : 'deactivated'} (demo mode)`, 'success');
      return;
    }

    // Make API call to update product availability
    this.http.patch(`${this.apiUrl}/shop-products/${product.id}/availability`, {
      isAvailable: product.isAvailable
    }).pipe(takeUntil(this.destroy$))
    .subscribe({
      next: () => {
        this.swalService.toast(`Product ${product.isAvailable ? 'activated' : 'deactivated'} successfully`, 'success');
      },
      error: (error) => {
        console.error('Error updating product availability:', error);
        // Revert the change
        product.isAvailable = !product.isAvailable;
        product.status = product.isAvailable ? 'ACTIVE' : 'INACTIVE';
        this.swalService.toast('Failed to update product availability', 'error');
      }
    });
  }

  updateStockDialog(product: ShopProduct): void {
    const dialogData: StockUpdateData = {
      productName: product.customName,
      currentStock: product.stockQuantity,
      unit: product.unit
    };

    const dialogRef = this.dialog.open(StockUpdateDialogComponent, {
      width: '500px',
      data: dialogData
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.updateProductStock(product, result.stockQuantity, result.reason);
      }
    });
  }

  updatePrice(product: ShopProduct): void {
    const dialogData: PriceUpdateData = {
      productName: product.customName,
      currentPrice: product.price,
      costPrice: product.costPrice
    };

    const dialogRef = this.dialog.open(PriceUpdateDialogComponent, {
      width: '500px',
      data: dialogData
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.updateProductPrice(product, result.price, result.costPrice);
      }
    });
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.selectedCategory = '';
    this.categoryFilterText = '';
    this.filteredCategories = this.categories;
    this.selectedStatus = '';
    this.applyFilters(); // Clear filters locally (like mobile app)
  }

  onSearchChange(event: any): void {
    this.searchTerm = event.target.value;
    // Filter locally - instant, no debounce needed for client-side filtering
    this.applyFilters();
  }

  onCategoryChange(category: string): void {
    this.selectedCategory = category;
    this.applyFilters(); // Client-side filtering (like mobile app)
  }

  onStatusChange(status: string): void {
    this.selectedStatus = status;
    this.applyFilters(); // Client-side filtering (like mobile app)
  }

  updateProductStatus(product: ShopProduct, status: boolean): void {
    if (this.usingFallbackData) {
      // Update locally for demo
      product.isAvailable = status;
      this.swalService.toast(`Product ${status ? 'enabled' : 'disabled'} (demo mode)`, 'success');
      return;
    }

    console.log('Updating product status:', product.id, status);
    
    const updateData = { isAvailable: status };
    
    this.http.put(`${this.apiUrl}/shop-products/${product.id}`, updateData)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          // Update the product in our local array
          const index = this.products.findIndex(p => p.id === product.id);
          if (index !== -1) {
            this.products[index] = { ...this.products[index], isAvailable: status };
            this.applyFilters();
          }
          this.swalService.toast(`Product ${status ? 'enabled' : 'disabled'}`, 'success');
        },
        error: (error) => {
          console.error('Error updating product status:', error);
          // Revert the toggle
          product.isAvailable = !status;
          this.handleError('Failed to update product status');
        }
      });
  }

  updateProductPrice(product: ShopProduct, newPrice: number, newCostPrice?: number): void {
    if (this.usingFallbackData) {
      // Update locally for demo
      product.price = newPrice;
      if (newCostPrice !== undefined) {
        product.costPrice = newCostPrice;
      }
      this.swalService.toast('Price updated (demo mode)', 'success');
      return;
    }

    console.log('Updating product price:', product.id, newPrice, newCostPrice);
    
    const updateData: any = { price: newPrice };
    if (newCostPrice !== undefined) {
      updateData.costPrice = newCostPrice;
    }
    
    this.http.put(`${this.apiUrl}/shop-products/${product.id}`, updateData)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          // Update the product in our local array
          const index = this.products.findIndex(p => p.id === product.id);
          if (index !== -1) {
            this.products[index] = {
              ...this.products[index],
              price: newPrice,
              ...(newCostPrice !== undefined && { costPrice: newCostPrice })
            };
            this.applyFilters();
          }

          // Update the IndexedDB cache to prevent stale data on reload
          this.offlineStorage.updateLocalProduct(product.id, {
            price: newPrice,
            ...(newCostPrice !== undefined && { costPrice: newCostPrice })
          }).catch(err => console.warn('Failed to update price in cache:', err));

          this.swalService.toast('Price updated successfully', 'success');
        },
        error: (error) => {
          console.error('Error updating product price:', error);
          this.handleError('Failed to update product price');
        }
      });
  }

  updateProductStock(product: ShopProduct, newStock: number, reason?: string): void {
    if (this.usingFallbackData) {
      // Update locally for demo
      product.stockQuantity = newStock;
      this.swalService.toast('Stock updated (demo mode)', 'success');
      return;
    }

    console.log('Updating product stock:', product.id, newStock, reason);

    // Use the PATCH inventory endpoint with query params
    // operation: SET = set exact value, ADD = add to current, SUBTRACT = subtract from current
    this.http.patch(`${this.apiUrl}/shop-products/${product.id}/inventory?quantity=${newStock}&operation=SET`, {})
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          // Update the product in our local array
          const index = this.products.findIndex(p => p.id === product.id);
          if (index !== -1) {
            this.products[index] = {
              ...this.products[index],
              stockQuantity: newStock
            };
            this.applyFilters();
          }

          // Update the IndexedDB cache to prevent stale data on reload
          this.offlineStorage.updateLocalProduct(product.id, {
            stock: newStock
          }).catch(err => console.warn('Failed to update stock in cache:', err));

          this.swalService.toast('Stock updated successfully', 'success');
        },
        error: (error) => {
          console.error('Error updating product stock:', error);
          this.handleError('Failed to update product stock');
        }
      });
  }

  editProduct(product: ShopProduct): void {
    console.log('Editing product:', product);
    console.log('Product ID:', product.id);
    console.log('Shop ID:', this.shopId);

    const dialogRef = this.dialog.open(ProductEditDialogComponent, {
      width: '600px',
      data: {
        id: product.id,
        customName: product.customName,
        description: product.description,
        price: product.price,
        originalPrice: product.originalPrice,
        costPrice: product.costPrice,
        stockQuantity: product.stockQuantity,
        category: product.category,
        unit: product.unit,
        sku: product.sku,
        status: product.status,
        isAvailable: product.isAvailable,
        imageUrl: product.imageUrl,
        nameTamil: product.masterProduct?.nameTamil || '',
        tags: product.masterProduct?.tags || '',
        masterProductId: product.masterProduct?.id,
        // Shop-level multiple barcodes
        barcode1: product.barcode1 || '',
        barcode2: product.barcode2 || '',
        barcode3: product.barcode3 || ''
      }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        console.log('Dialog result:', result);
        console.log('Passing product ID to updateProductDetails:', product.id);
        this.updateProductDetails(product.id, result);
      }
    });
  }
  
  private updateProductDetails(productId: number, updatedData: any): void {
    console.log('updateProductDetails called with productId:', productId);
    console.log('Shop ID:', this.shopId);
    console.log('Updated data:', updatedData);
    console.log('Using fallback data?:', this.usingFallbackData);

    // Image is already uploaded in the dialog component
    // The updatedData already contains the new imageUrl from server

    // Get previous values before updating for offline edit record
    const currentProduct = this.products.find(p => p.id === productId);
    const previousValues = currentProduct ? {
      price: currentProduct.price,
      originalPrice: (currentProduct as any).originalPrice,
      stockQuantity: currentProduct.stockQuantity,
      sku: currentProduct.sku,
      barcode1: currentProduct.barcode1,
      barcode2: currentProduct.barcode2,
      barcode3: currentProduct.barcode3,
      name: currentProduct.customName,
      nameTamil: (currentProduct as any).nameTamil
    } : {};

    // If using fallback data, just update locally without API calls
    if (this.usingFallbackData) {
      const index = this.products.findIndex(p => p.id === productId);
      if (index !== -1) {
        this.products[index] = { ...this.products[index], ...updatedData };
        this.applyFilters();
      }
      this.saveEditOffline(productId, updatedData, previousValues);
      this.swalService.toast('Product updated (saved offline)', 'success');
      return;
    }

    // For real products, update locally first
    const index = this.products.findIndex(p => p.id === productId);
    if (index !== -1) {
      this.products[index] = { ...this.products[index], ...updatedData };
      this.applyFilters();
    }

    // For offline-created products (negative temp ID), save offline only
    if (productId < 0) {
      this.saveEditOffline(productId, updatedData, previousValues);
      this.swalService.toast('Product updated (saved offline)', 'success');
      return;
    }

    // Try to update in backend if online
    if (!navigator.onLine) {
      this.saveEditOffline(productId, updatedData, previousValues);
      this.swalService.toast('Product updated (saved offline, will sync when online)', 'success');
      return;
    }

    this.http.put(`${this.apiUrl}/shop-products/${productId}`, updatedData)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          // Update local array instead of reloading from server (prevents stale data)
          const index = this.products.findIndex(p => p.id === productId);
          if (index !== -1) {
            this.products[index] = {
              ...this.products[index],
              customName: updatedData.customName || this.products[index].customName,
              price: updatedData.price ?? this.products[index].price,
              originalPrice: updatedData.originalPrice ?? this.products[index].originalPrice,
              costPrice: updatedData.costPrice ?? this.products[index].costPrice,
              stockQuantity: updatedData.stockQuantity ?? this.products[index].stockQuantity,
              barcode1: updatedData.barcode1 ?? this.products[index].barcode1,
              barcode2: updatedData.barcode2 ?? this.products[index].barcode2,
              barcode3: updatedData.barcode3 ?? this.products[index].barcode3,
              category: updatedData.categoryName ?? this.products[index].category
            };
            this.applyFilters();
          }

          // Update IndexedDB cache
          this.offlineStorage.updateLocalProduct(productId, {
            name: updatedData.customName,
            price: updatedData.price,
            originalPrice: updatedData.originalPrice,
            costPrice: updatedData.costPrice,
            stock: updatedData.stockQuantity,
            barcode1: updatedData.barcode1,
            barcode2: updatedData.barcode2,
            barcode3: updatedData.barcode3,
            category: updatedData.categoryName,
            categoryName: updatedData.categoryName
          }).catch(err => console.warn('Failed to update cache:', err));

          // Clear search filter after successful update
          this.searchTerm = '';
          this.applyFilters();

          this.swalService.toast('Product updated successfully', 'success');
        },
        error: (error) => {
          console.warn('Backend update failed, saving offline:', error);
          const isNetworkError = !error?.status || error.status === 0;
          if (isNetworkError) {
            this.saveEditOffline(productId, updatedData, previousValues);
            // Clear search filter after offline update
            this.searchTerm = '';
            this.applyFilters();
            this.swalService.toast('Product updated (saved offline, will sync when online)', 'success');
          } else {
            // Server error - still update locally since we already did optimistic update
            this.searchTerm = '';
            this.applyFilters();
            this.swalService.toast('Product updated', 'success');
          }
        }
      });
  }

  private async saveEditOffline(productId: number, updatedData: any, previousValues: any): Promise<void> {
    try {
      const offlineEdit: OfflineEdit = {
        editId: this.offlineStorage.generateOfflineEditId(),
        productId: productId,
        shopId: this.shopId || 0,
        changes: {
          price: updatedData.price,
          originalPrice: updatedData.originalPrice,
          stockQuantity: updatedData.stockQuantity,
          sku: updatedData.sku,
          barcode1: updatedData.barcode1,
          barcode2: updatedData.barcode2,
          barcode3: updatedData.barcode3,
          customName: updatedData.customName,
          nameTamil: updatedData.nameTamil,
          category: updatedData.categoryName,
          voiceSearchTags: updatedData.voiceSearchTags
        },
        previousValues: previousValues,
        createdAt: new Date().toISOString(),
        synced: false
      };

      await this.offlineStorage.saveOfflineEdit(offlineEdit);

      // Update IndexedDB cache
      await this.offlineStorage.updateLocalProduct(productId, {
        price: updatedData.price,
        originalPrice: updatedData.originalPrice,
        stock: updatedData.stockQuantity,
        sku: updatedData.sku,
        barcode1: updatedData.barcode1,
        barcode2: updatedData.barcode2,
        barcode3: updatedData.barcode3,
        name: updatedData.customName,
        nameTamil: updatedData.nameTamil,
        category: updatedData.categoryName,
        categoryName: updatedData.categoryName
      });

      console.log('Edit saved offline for product:', productId);
    } catch (err) {
      console.error('Failed to save edit offline:', err);
    }
  }

  private updateProductWithoutImage(productId: number, updatedData: any): void {
    // Always update locally first
    const index = this.products.findIndex(p => p.id === productId);
    if (index !== -1) {
      this.products[index] = { ...this.products[index], ...updatedData };
      this.applyFilters();
    }

    if (this.usingFallbackData) {
      // Update locally for demo
      this.swalService.toast('Product updated (demo mode)', 'success');
      return;
    }

    // Try to send update to backend, but don't fail if it errors
    this.http.put(`${this.apiUrl}/shop-products/${productId}`, updatedData)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          // Refresh from database to get the latest data
          this.loadProducts();
          this.swalService.toast('Product updated successfully', 'success');
        },
        error: (error) => {
          console.warn('Backend update failed, but local update successful:', error);
          // Still show success since we updated locally
          this.swalService.toast('Product updated locally', 'success');
        }
      });
  }

  async deleteProduct(product: ShopProduct): Promise<void> {
    if (this.usingFallbackData) {
      // Remove from local array for demo
      this.products = this.products.filter(p => p.id !== product.id);
      this.applyFilters();
      this.swalService.toast('Product deleted (demo mode)', 'success');
      return;
    }

    const result = await this.swalService.confirmDelete(product.customName);
    if (result.isConfirmed) {
      console.log('Deleting product:', product.id);

      // Check if this is an offline-created product (negative ID)
      if (product.id < 0) {
        this.deleteOfflineProduct(product);
        return;
      }

      this.http.delete(`${this.apiUrl}/shop-products/${product.id}`)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: () => {
            console.log('Product deleted successfully');
            this.products = this.products.filter(p => p.id !== product.id);
            this.applyFilters();
            // Also remove from IndexedDB cache
            this.offlineStorage.removeProductFromCache(product.id).catch(err =>
              console.warn('Failed to remove product from cache:', err)
            );
            this.swalService.success('Deleted!', 'Product deleted successfully');
          },
          error: (error) => {
            console.error('Error deleting product:', error);
            this.swalService.error('Error', 'Failed to delete product');
          }
        });
    }
  }

  /**
   * Merge pending offline-created products with server products
   */
  private async mergeOfflineProducts(serverProducts: ShopProduct[]): Promise<void> {
    try {
      const pendingCreations = await this.offlineStorage.getPendingProductCreations();

      if (pendingCreations.length > 0) {
        console.log(`Merging ${pendingCreations.length} pending offline products with server products`);

        const offlineProducts: ShopProduct[] = pendingCreations.map(creation => ({
          id: this.offlineStorage.generateTempProductId(),
          customName: creation.name || creation.customName || 'New Product',
          description: creation.customDescription || '',
          price: creation.price,
          originalPrice: creation.originalPrice,
          costPrice: creation.costPrice,
          stockQuantity: creation.stockQuantity,
          isAvailable: true,
          status: 'ACTIVE',
          category: creation.categoryName || '',
          unit: creation.unit || 'piece',
          sku: creation.sku || '',
          barcode: creation.barcode1 || '',
          barcode1: creation.barcode1 || '',
          barcode2: creation.barcode2 || '',
          barcode3: creation.barcode3 || '',
          imageUrl: '',
          masterProductId: creation.masterProductId,
          masterProductName: creation.name || creation.customName,
          masterProduct: undefined,
          createdAt: creation.createdAt,
          updatedAt: creation.createdAt
        }));

        // Prepend offline products to server products
        this.products = [...offlineProducts, ...serverProducts];
        // Re-apply filters to include offline products in filtered results
        this.applyFilters();
        this.loadCategories();
        console.log('Merged offline products, total:', this.products.length);
      }
      // If no pending creations, products are already set to serverProducts
    } catch (error) {
      console.warn('Failed to merge offline products:', error);
      // If error, products are already set to serverProducts
    }
  }

  /**
   * Save products to IndexedDB cache for fast loading next time
   */
  private saveProductsToCache(serverProducts: ShopProduct[]): void {
    const cachedProducts: CachedProduct[] = serverProducts.map(p => ({
      id: p.id,
      shopId: this.shopId || 0,
      name: p.customName || '',
      nameTamil: p.masterProduct?.nameTamil,
      description: p.description,
      price: p.price,
      originalPrice: p.originalPrice,
      costPrice: p.costPrice,
      stock: p.stockQuantity,
      trackInventory: true,
      isAvailable: p.isAvailable,
      sku: p.sku || '',
      barcode: p.barcode,
      barcode1: p.barcode1,
      barcode2: p.barcode2,
      barcode3: p.barcode3,
      category: p.category,
      unit: p.unit,
      imageUrl: p.imageUrl,
      masterProductId: p.masterProductId
    }));

    this.offlineStorage.saveProducts(cachedProducts, this.shopId || 0).then(() => {
      // Record when we last actually synced with the server (informational only)
      localStorage.setItem(this.CACHE_TIMESTAMP_KEY, Date.now().toString());
      console.log(`Saved ${cachedProducts.length} products to IndexedDB cache`);
    }).catch(err => {
      console.warn('Failed to save products to cache:', err);
    });
  }

  /**
   * Delete an offline-created product from IndexedDB
   */
  private async deleteOfflineProduct(product: ShopProduct): Promise<void> {
    try {
      // Get all pending creations and find the one matching this product
      const pendingCreations = await this.offlineStorage.getPendingProductCreations();
      console.log('Looking for offline product to delete:', product.customName);
      console.log('Pending creations:', pendingCreations);

      // Find by matching name or barcode since temp IDs change on each load
      const matchingCreation = pendingCreations.find(c =>
        (c.name && c.name === product.customName) ||
        (c.customName && c.customName === product.customName) ||
        (c.barcode1 && product.barcode1 && c.barcode1 === product.barcode1)
      );

      if (matchingCreation) {
        await this.offlineStorage.removeOfflineProductCreation(matchingCreation.offlineProductId);
        console.log('Offline product creation removed:', matchingCreation.offlineProductId);
      } else {
        console.log('No matching offline creation found for product:', product.customName);
      }

      // Remove from local array regardless
      this.products = this.products.filter(p => p.id !== product.id);
      this.applyFilters();
      this.swalService.toast(matchingCreation ? 'Offline product deleted' : 'Product removed from list', 'success');
    } catch (error) {
      console.error('Error deleting offline product:', error);
      this.swalService.toast('Failed to delete offline product', 'error');
    }
  }

  async bulkDeleteProducts(): Promise<void> {
    if (this.selectedProducts.length === 0) {
      this.swalService.warning('No Selection', 'Please select products to delete');
      return;
    }

    const count = this.selectedProducts.length;
    const productNames = this.selectedProducts.slice(0, 3).map(p => p.customName).join(', ');
    const displayNames = count > 3 ? `${productNames} and ${count - 3} more` : productNames;

    // Confirmation 1: Initial warning with product names
    const step1 = await this.swalService.custom({
      title: `Delete ${count} Product(s)?`,
      html: `<p>You are about to delete:</p><p><strong>${displayNames}</strong></p>`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Yes, proceed',
      cancelButtonText: 'Cancel',
      confirmButtonColor: '#ef4444',
      cancelButtonColor: '#6b7280',
      reverseButtons: true
    });
    if (!step1.isConfirmed) return;

    // Confirmation 2: Final warning
    const step2 = await this.swalService.custom({
      title: 'FINAL WARNING',
      html: `<p>This will <strong>permanently delete ${count} product(s)</strong> from your shop.</p><p style="color:#ef4444;font-weight:bold;">This action CANNOT be undone.</p>`,
      icon: 'error',
      showCancelButton: true,
      confirmButtonText: 'Delete permanently',
      cancelButtonText: 'Cancel',
      confirmButtonColor: '#ef4444',
      cancelButtonColor: '#6b7280',
      reverseButtons: true
    });
    if (!step2.isConfirmed) return;

    // Confirmation 3: For large deletions (50+), require typing DELETE
    if (count >= 50) {
      const step3 = await this.swalService.custom({
        title: `Type "DELETE" to confirm`,
        html: `<p>You are deleting <strong>${count} products</strong>. This is a large operation.</p>`,
        icon: 'warning',
        input: 'text',
        inputPlaceholder: 'Type DELETE here',
        showCancelButton: true,
        confirmButtonText: 'Confirm Delete',
        confirmButtonColor: '#ef4444',
        cancelButtonColor: '#6b7280',
        reverseButtons: true,
        inputValidator: (value) => {
          if (value !== 'DELETE') {
            return 'You must type DELETE to confirm';
          }
          return null;
        }
      });
      if (!step3.isConfirmed) {
        this.swalService.info('Cancelled', 'Deletion cancelled.');
        return;
      }
    }

    if (this.usingFallbackData) {
      // Remove from local array for demo
      const selectedIds = this.selectedProducts.map(p => p.id);
      this.products = this.products.filter(p => !selectedIds.includes(p.id));
      this.clearProductSelection();
      this.applyFilters();
      this.swalService.success('Deleted!', `${count} products deleted (demo mode)`);
      return;
    }

    // Delete products via API
    const productIds = this.selectedProducts.map(p => p.id);
    console.log('Bulk deleting products:', productIds);

    this.swalService.loading('Deleting...', `Removing ${count} products`);

    this.http.post(`${this.apiUrl}/shop-products/bulk-delete`, { productIds })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          console.log('Products deleted successfully');
          this.products = this.products.filter(p => !productIds.includes(p.id));
          this.clearProductSelection();
          this.applyFilters();
          // Also remove from IndexedDB cache
          productIds.forEach(id => {
            this.offlineStorage.removeProductFromCache(id).catch(err =>
              console.warn('Failed to remove product from cache:', err)
            );
          });
          this.swalService.success('Deleted!', `${count} products deleted successfully`);
        },
        error: (error) => {
          console.error('Error bulk deleting products:', error);
          this.swalService.close();
          // Fallback: delete one by one
          this.bulkDeleteOneByOne(productIds);
        }
      });
  }

  private bulkDeleteOneByOne(productIds: number[]): void {
    let successCount = 0;
    let errorCount = 0;
    const total = productIds.length;

    const deleteNext = (index: number) => {
      if (index >= productIds.length) {
        // All done
        this.products = this.products.filter(p => !productIds.slice(0, successCount).includes(p.id));
        this.clearProductSelection();
        this.applyFilters();

        if (errorCount === 0) {
          this.swalService.toast(`${successCount} products deleted successfully`, 'success');
        } else {
          this.swalService.toast(`Deleted ${successCount} products, ${errorCount} failed`, 'warning');
        }
        return;
      }

      this.http.delete(`${this.apiUrl}/shop-products/${productIds[index]}`)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: () => {
            successCount++;
            deleteNext(index + 1);
          },
          error: () => {
            errorCount++;
            deleteNext(index + 1);
          }
        });
    };

    deleteNext(0);
  }

  addNewProduct(): void {
    this.router.navigate(['/shop-owner/my-products/add']);
  }

  refreshProducts(): void {
    this.loadProducts(true);
    this.swalService.toast('Products refreshed from server', 'success');
  }
  
  private handleError(message: string): void {
    this.swalService.toast(message, 'error');
  }
  
  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR'
    }).format(amount);
  }

  getStockStatusClass(quantity: number): string {
    if (quantity <= 5) return 'low-stock';
    if (quantity <= 10) return 'medium-stock';
    return 'high-stock';
  }

  getStockStatusText(quantity: number): string {
    if (quantity <= 5) return 'Low Stock';
    if (quantity <= 10) return 'Medium Stock';
    return 'In Stock';
  }

  bulkUpload(): void {
    this.swalService.toast('Bulk upload feature coming soon', 'info');
  }

  duplicateProduct(productId: number): void {
    this.swalService.toast('Duplicate product feature coming soon', 'info');
  }

  toggleProductStatus(productId: number): void {
    const product = this.products.find(p => p.id === productId);
    if (product) {
      this.updateProductStatus(product, !product.isAvailable);
    }
  }

  viewAnalytics(productId: number): void {
    this.swalService.toast('Product analytics feature coming soon', 'info');
  }

  updateStock(productId: number): void {
    this.swalService.toast('Update stock feature coming soon', 'info');
  }

  get dynamicPageSizeOptions(): number[] {
    const options = [12, 24, 48, 96];
    if (this.totalProducts > 96 && !options.includes(this.totalProducts)) {
      options.push(this.totalProducts);
    }
    return options;
  }

  onPageChange(event: any): void {
    this.currentPageIndex = event.pageIndex;
    this.pageSize = event.pageSize;
    console.log('Page changed:', event.pageIndex, 'Page size:', event.pageSize);
  }


  // Bulk selection methods
  toggleProductSelection(product: ShopProduct): void {
    const index = this.selectedProducts.findIndex(p => p.id === product.id);
    if (index > -1) {
      this.selectedProducts.splice(index, 1);
    } else {
      this.selectedProducts.push(product);
    }
    this.updateSelectAllState();
  }

  isProductSelected(product: ShopProduct): boolean {
    return this.selectedProducts.some(p => p.id === product.id);
  }

  toggleSelectAll(): void {
    // Toggle: if all selected, deselect all; otherwise select all
    if (this.selectedProducts.length === this.filteredProducts.length) {
      this.selectedProducts = [];
      this.selectAll = false;
    } else {
      this.selectedProducts = [...this.filteredProducts];
      this.selectAll = true;
    }
  }

  updateSelectAllState(): void {
    this.selectAll = this.filteredProducts.length > 0 && 
                   this.selectedProducts.length === this.filteredProducts.length;
  }

  clearProductSelection(): void {
    this.selectedProducts = [];
    this.selectAll = false;
  }

  bulkPriceUpdate(): void {
    if (this.selectedProducts.length === 0) {
      this.swalService.toast('Please select products to update prices', 'warning');
      return;
    }

    // Open bulk price update dialog
    this.dialog.open(BulkPriceUpdateDialogComponent, {
      width: '600px',
      data: {
        products: this.selectedProducts,
        usingFallbackData: this.usingFallbackData
      }
    }).afterClosed().subscribe(result => {
      if (result) {
        this.applyBulkPriceUpdate(result);
      }
    });
  }

  private applyBulkPriceUpdate(updateData: any): void {
    if (this.usingFallbackData) {
      // Update locally for demo
      this.selectedProducts.forEach(product => {
        if (updateData.priceType === 'fixed') {
          product.price = updateData.newPrice;
        } else if (updateData.priceType === 'percentage') {
          product.price = product.price * (1 + updateData.percentage / 100);
        }
      });
      this.swalService.toast(`Updated prices for ${this.selectedProducts.length} products (demo mode)`, 'success');
      this.clearProductSelection();
      return;
    }

    // Apply bulk price update via API
    const bulkUpdateRequest = {
      productIds: this.selectedProducts.map(p => p.id),
      updateType: updateData.priceType,
      newPrice: updateData.newPrice,
      percentage: updateData.percentage
    };

    this.http.patch(`${this.apiUrl}/shop-products/bulk-price-update`, bulkUpdateRequest)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.swalService.toast(`Updated prices for ${this.selectedProducts.length} products`, 'success');
          this.loadProducts(); // Reload to get updated data
          this.clearProductSelection();
        },
        error: (error) => {
          console.error('Error updating bulk prices:', error);
          this.swalService.toast('Failed to update prices', 'error');
        }
      });
  }

  browseMasterProducts(): void {
    // Try to get shop ID from multiple sources - use string shopId directly
    let effectiveShopId: any = this.shopId;

    if (!effectiveShopId) {
      // Try from localStorage - use numeric ID
      const cachedShopId = localStorage.getItem('current_shop_id');
      if (cachedShopId) {
        effectiveShopId = parseInt(cachedShopId, 10);
      }
    }

    if (!effectiveShopId) {
      // No shop ID available - user needs to login again
      console.error('No shop ID found - user needs to login again');
      this.swalService.toast('Please logout and login again to refresh your shop data', 'warning');
      return;
    }

    // Update component's shopId if it was null
    if (!this.shopId) {
      this.shopId = effectiveShopId;
    }

    console.log('Opening browse dialog with shop ID:', effectiveShopId);

    const dialogRef = this.dialog.open(BrowseMasterProductsDialogComponent, {
      width: '900px',
      maxWidth: '95vw',
      maxHeight: '90vh',
      data: { shopId: effectiveShopId }
    });

    dialogRef.afterClosed().subscribe((result: ProductAssignmentResult) => {
      if (result) {
        this.assignProductToShop(result);
      }
    });
  }

  private assignProductToShop(assignmentData: ProductAssignmentResult): void {
    if (!this.shopId) return;

    console.log('Assigning product to shop:', assignmentData);

    this.shopOwnerProductService.assignProductToShop(this.shopId, {
      masterProductId: assignmentData.masterProduct.id,
      price: assignmentData.sellingPrice,
      stockQuantity: assignmentData.initialStock,
      customName: assignmentData.customName,
      customDescription: assignmentData.customDescription
    }).pipe(takeUntil(this.destroy$))
    .subscribe({
      next: async (newProduct: any) => {
        console.log('Product assigned successfully:', newProduct);

        // Add to IndexedDB cache immediately for POS Billing search
        try {
          const cachedProduct: CachedProduct = {
            id: newProduct.id,
            shopId: this.shopId!,
            name: newProduct.customName || assignmentData.masterProduct.name || '',
            nameTamil: newProduct.nameTamil || assignmentData.masterProduct.nameTamil || '',
            price: newProduct.price || assignmentData.sellingPrice,
            originalPrice: newProduct.originalPrice || assignmentData.sellingPrice,
            costPrice: newProduct.costPrice || 0,
            stock: newProduct.stockQuantity || assignmentData.initialStock || 0,
            trackInventory: true,
            isAvailable: newProduct.isAvailable !== false,
            sku: newProduct.sku || assignmentData.masterProduct.sku || '',
            barcode: newProduct.barcode1 || '',
            barcode1: newProduct.barcode1 || '',
            barcode2: newProduct.barcode2 || '',
            barcode3: newProduct.barcode3 || '',
            category: newProduct.category || '',
            unit: newProduct.unit || 'piece',
            imageUrl: newProduct.imageUrl || newProduct.primaryImageUrl || '',
            tags: newProduct.tags ? (Array.isArray(newProduct.tags) ? newProduct.tags : newProduct.tags.split(',').map((t: string) => t.trim())) : (assignmentData.masterProduct.tags ? assignmentData.masterProduct.tags.split(',').map(t => t.trim()) : [])
          };
          await this.offlineStorage.addProductToCache(cachedProduct);
          console.log('Added new product to IndexedDB cache:', cachedProduct);
        } catch (err) {
          console.warn('Failed to add product to cache:', err);
        }

        this.swalService.toast(`Product "${assignmentData.masterProduct.name}" assigned to your shop!`, 'success');

        // Reload products to show the new assignment
        this.loadProducts();
      },
      error: (error) => {
        console.error('Error assigning product:', error);
        let errorMessage = 'Failed to assign product to shop';

        // Check for specific error messages
        if (error?.error?.message) {
          errorMessage = error.error.message;
        } else if (error?.message) {
          errorMessage = error.message;
        }

        this.swalService.toast(errorMessage, 'error');
      }
    });
  }
}