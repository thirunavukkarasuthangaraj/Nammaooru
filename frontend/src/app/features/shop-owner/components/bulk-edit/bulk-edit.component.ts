import { Component, OnInit, OnDestroy } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatDialog } from '@angular/material/dialog';
import { HttpClient } from '@angular/common/http';
import { Subject } from 'rxjs';
import { takeUntil, debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { OfflineStorageService, CachedProduct } from '../../../../core/services/offline-storage.service';
import { VersionService } from '../../../../core/services/version.service';
import { getImageUrl as getImageUrlUtil } from '../../../../core/utils/image-url.util';
import { CategoryCreateDialogComponent, CategoryCreateDialogResult, syncOfflineCategories } from '../category-create-dialog/category-create-dialog.component';

interface BulkEditProduct {
  id: number;
  customName: string;
  nameTamil?: string;
  description?: string;
  sku?: string;
  barcode1?: string;
  barcode2?: string;
  barcode3?: string;
  price: number;
  originalPrice?: number;
  stockQuantity: number;
  status: string;
  isAvailable: boolean;
  tags?: string;
  category?: string;
  imageUrl?: string;
  // Track original values for change detection
  originalValues: {
    customName: string;
    category?: string;
    price: number;
    originalPrice?: number;
    stockQuantity: number;
    status: string;
    isAvailable: boolean;
    tags?: string;
    sku?: string;
    barcode1?: string;
    barcode2?: string;
    barcode3?: string;
    nameTamil?: string;
  };
}

@Component({
  selector: 'app-bulk-edit',
  templateUrl: './bulk-edit.component.html',
  styleUrls: ['./bulk-edit.component.scss']
})
export class BulkEditComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  private searchSubject$ = new Subject<string>();
  private apiUrl = environment.apiUrl;

  // Product data
  products: BulkEditProduct[] = [];
  filteredProducts: BulkEditProduct[] = [];
  categories: string[] = [];
  loading = false;
  saving = false;

  // Filter controls
  searchTerm = '';
  selectedCategory = '';
  selectedStatus = '';

  // Pagination
  totalProducts = 0;
  pageSize = 100;
  pageSizeOptions = [50, 100, 200, 500];
  currentPageIndex = 0;

  // Track modifications
  modifiedProducts: Map<number, BulkEditProduct> = new Map();

  // Version info
  clientVersion = '';

  // Offline support
  isOffline = false;
  lastSyncTime: Date | null = null;

  constructor(
    private http: HttpClient,
    private snackBar: MatSnackBar,
    private offlineStorage: OfflineStorageService,
    private versionService: VersionService,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    this.clientVersion = this.versionService.getVersion().replace('v', '');

    // Set up online/offline detection
    this.isOffline = !navigator.onLine;
    window.addEventListener('online', this.handleOnline.bind(this));
    window.addEventListener('offline', this.handleOffline.bind(this));

    this.loadProducts();
    this.loadLastSyncTime();

    // Setup search with debounce
    this.searchSubject$.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      takeUntil(this.destroy$)
    ).subscribe(searchTerm => {
      this.searchTerm = searchTerm;
      this.applyFilters();
    });
  }

  private handleOnline = (): void => {
    console.log('Network online - syncing categories first, then products');
    this.isOffline = false;
    this.snackBar.open('Back online! Syncing changes...', 'Close', { duration: 3000 });
    // Sync offline categories first, then load products
    syncOfflineCategories(this.http, this.apiUrl).then(() => {
      this.loadProducts(true);
    });
  }

  private handleOffline = (): void => {
    console.log('Network offline - using cached data');
    this.isOffline = true;
    this.snackBar.open('You are offline. Changes will be saved locally.', 'Close', { duration: 3000 });
  }

  private async loadLastSyncTime(): Promise<void> {
    try {
      this.lastSyncTime = await this.offlineStorage.getProductsSyncTime(0);
    } catch (error) {
      console.warn('Error loading last sync time:', error);
    }
  }

  getTimeSinceSync(): string {
    if (!this.lastSyncTime) return 'Never synced';

    const now = new Date();
    const diffMs = now.getTime() - this.lastSyncTime.getTime();
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 1) return 'Just now';
    if (diffMins === 1) return '1 minute ago';
    if (diffMins < 60) return `${diffMins} minutes ago`;

    const diffHours = Math.floor(diffMins / 60);
    if (diffHours === 1) return '1 hour ago';
    if (diffHours < 24) return `${diffHours} hours ago`;

    const diffDays = Math.floor(diffHours / 24);
    if (diffDays === 1) return '1 day ago';
    return `${diffDays} days ago`;
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    window.removeEventListener('online', this.handleOnline.bind(this));
    window.removeEventListener('offline', this.handleOffline.bind(this));
  }

  async loadProducts(forceRefresh: boolean = false): Promise<void> {
    this.loading = true;

    // Step 1: Load from local cache first (instant) - skip if force refresh
    if (!forceRefresh) {
      try {
        const cachedProducts = await this.offlineStorage.getProducts();
        if (cachedProducts.length > 0) {
          this.mapCachedProducts(cachedProducts);
          this.loading = false;
        }
      } catch (error) {
        console.warn('Error loading from cache:', error);
      }
    }

    // Step 2: Always sync from server when online to get latest data
    if (navigator.onLine) {
      this.syncProductsFromServer();
    }
  }

  private mapCachedProducts(cachedProducts: CachedProduct[]): void {
    this.products = cachedProducts.map((p: CachedProduct) => ({
      id: p.id,
      customName: p.name,
      nameTamil: p.nameTamil || '',
      description: p.description || '',
      sku: p.sku || '',
      barcode1: p.barcode1 || '',
      barcode2: p.barcode2 || '',
      barcode3: p.barcode3 || '',
      price: p.price,
      originalPrice: p.originalPrice,
      stockQuantity: p.stock,
      status: p.isAvailable !== false ? 'ACTIVE' : 'INACTIVE',
      isAvailable: p.isAvailable !== false,
      tags: Array.isArray(p.tags) ? p.tags.join(', ') : (p.tags || ''),
      category: p.category || '',
      imageUrl: p.imageUrl || '',
      originalValues: {
        customName: p.name,
        category: p.category || '',
        price: p.price,
        originalPrice: p.originalPrice,
        stockQuantity: p.stock,
        status: p.isAvailable !== false ? 'ACTIVE' : 'INACTIVE',
        isAvailable: p.isAvailable !== false,
        tags: Array.isArray(p.tags) ? p.tags.join(', ') : (p.tags || ''),
        sku: p.sku || '',
        barcode1: p.barcode1 || '',
        barcode2: p.barcode2 || '',
        barcode3: p.barcode3 || '',
        nameTamil: p.nameTamil || ''
      }
    }));

    this.applyFilters();
    this.extractCategories();
  }

  private async syncProductsFromServer(): Promise<void> {
    const pageSize = 500;
    let allProducts: any[] = [];
    let currentPage = 0;
    let totalPages = 1;

    try {
      // Fetch all pages
      while (currentPage < totalPages) {
        const response: any = await this.http.get<any>(
          `${this.apiUrl}/shop-products/my-products?page=${currentPage}&size=${pageSize}`
        ).toPromise();

        let products = [];
        let totalElements = 0;
        if (response?.data?.content) {
          products = response.data.content;
          totalPages = response.data.totalPages || 1;
          totalElements = response.data.totalElements || 0;
        } else if (Array.isArray(response?.data)) {
          products = response.data;
          totalPages = 1;
        } else if (Array.isArray(response)) {
          products = response;
          totalPages = 1;
        }

        allProducts = allProducts.concat(products);
        console.log(`Page ${currentPage + 1}/${totalPages}: fetched ${products.length}, total so far: ${allProducts.length}, server says totalElements: ${totalElements}`);
        currentPage++;

        // Safety: prevent infinite loop
        if (currentPage > 100) break;
      }

      console.log(`Loaded ${allProducts.length} products from ${currentPage} pages`);

      this.products = allProducts.map((p: any) => ({
        id: p.id,
        customName: p.displayName || p.customName || p.masterProduct?.name,
        nameTamil: p.masterProduct?.nameTamil || '',
        description: p.displayDescription || p.customDescription || p.masterProduct?.description,
        sku: p.sku || p.masterProduct?.sku || '',
        barcode1: p.barcode1 || '',
        barcode2: p.barcode2 || '',
        barcode3: p.barcode3 || '',
        price: p.price,
        originalPrice: p.originalPrice,
        stockQuantity: p.stockQuantity,
        status: p.status || (p.isAvailable ? 'ACTIVE' : 'INACTIVE'),
        isAvailable: p.isAvailable,
        tags: p.masterProduct?.tags || '',
        category: p.masterProduct?.category?.name || '',
        imageUrl: p.primaryImageUrl || '',
        originalValues: {
          customName: p.displayName || p.customName || p.masterProduct?.name,
          category: p.masterProduct?.category?.name || '',
          price: p.price,
          originalPrice: p.originalPrice,
          stockQuantity: p.stockQuantity,
          status: p.status || (p.isAvailable ? 'ACTIVE' : 'INACTIVE'),
          isAvailable: p.isAvailable,
          tags: p.masterProduct?.tags || '',
          sku: p.sku || p.masterProduct?.sku || '',
          barcode1: p.barcode1 || '',
          barcode2: p.barcode2 || '',
          barcode3: p.barcode3 || '',
          nameTamil: p.masterProduct?.nameTamil || ''
        }
      }));

      this.applyFilters();
      this.extractCategories();
      this.loading = false;
    } catch (error) {
      console.error('Failed to sync products:', error);
      this.loading = false;
      if (this.products.length === 0) {
        this.snackBar.open('Failed to load products', 'Close', { duration: 3000 });
      }
    }
  }

  private extractCategories(): void {
    this.categories = [...new Set(this.products.map(p => p.category).filter(Boolean) as string[])];
  }

  applyFilters(): void {
    const searchLower = this.searchTerm?.toLowerCase().trim() || '';

    this.filteredProducts = this.products.filter(product => {
      const matchesSearch = !searchLower ||
        (product.customName || '').toLowerCase().includes(searchLower) ||
        (product.nameTamil || '').toLowerCase().includes(searchLower) ||
        (product.sku || '').toLowerCase().includes(searchLower) ||
        (product.tags || '').toLowerCase().includes(searchLower);

      const matchesCategory = !this.selectedCategory || product.category === this.selectedCategory;
      const matchesStatus = !this.selectedStatus ||
        product.status === this.selectedStatus ||
        (this.selectedStatus === 'available' && product.isAvailable) ||
        (this.selectedStatus === 'unavailable' && !product.isAvailable);

      return matchesSearch && matchesCategory && matchesStatus;
    });

    this.totalProducts = this.filteredProducts.length;
    this.currentPageIndex = 0;
  }

  onSearchChange(event: any): void {
    this.searchSubject$.next(event.target.value);
  }

  onCategoryChange(category: string): void {
    this.selectedCategory = category;
    this.applyFilters();
  }

  onStatusChange(status: string): void {
    this.selectedStatus = status;
    this.applyFilters();
  }

  onPageChange(event: any): void {
    this.currentPageIndex = event.pageIndex;
    this.pageSize = event.pageSize;
  }

  // Get paginated products
  get paginatedProducts(): BulkEditProduct[] {
    const start = this.currentPageIndex * this.pageSize;
    const end = start + this.pageSize;
    return this.filteredProducts.slice(start, end);
  }

  // Cell edit handlers
  onPriceChange(product: BulkEditProduct, value: string): void {
    const newPrice = parseFloat(value);
    if (!isNaN(newPrice) && newPrice >= 0) {
      product.price = newPrice;
      this.markModified(product);
    }
  }

  onMrpChange(product: BulkEditProduct, value: string): void {
    const newMrp = parseFloat(value);
    if (!isNaN(newMrp) && newMrp >= 0) {
      product.originalPrice = newMrp;
      this.markModified(product);
    }
  }

  onStockChange(product: BulkEditProduct, value: string): void {
    const newStock = parseInt(value, 10);
    if (!isNaN(newStock) && newStock >= 0) {
      product.stockQuantity = newStock;
      this.markModified(product);
    }
  }

  onStatusDropdownChange(product: BulkEditProduct, value: string): void {
    product.status = value;
    product.isAvailable = value === 'ACTIVE';
    this.markModified(product);
  }

  onTagsChange(product: BulkEditProduct, value: string): void {
    product.tags = value;
    this.markModified(product);
  }

  onSkuChange(product: BulkEditProduct, value: string): void {
    product.sku = value;
    this.markModified(product);
  }

  onBarcode1Change(product: BulkEditProduct, value: string): void {
    product.barcode1 = value;
    this.markModified(product);
  }

  onBarcode2Change(product: BulkEditProduct, value: string): void {
    product.barcode2 = value;
    this.markModified(product);
  }

  onBarcode3Change(product: BulkEditProduct, value: string): void {
    product.barcode3 = value;
    this.markModified(product);
  }

  onTamilNameChange(product: BulkEditProduct, value: string): void {
    product.nameTamil = value;
    this.markModified(product);
  }

  onProductNameChange(product: BulkEditProduct, value: string): void {
    product.customName = value;
    this.markModified(product);
  }

  onCategoryFieldChange(product: BulkEditProduct, value: string): void {
    product.category = value;
    this.markModified(product);
  }

  onCategoryDropdownChange(product: BulkEditProduct, selectElement: HTMLSelectElement): void {
    const value = selectElement.value;
    if (value === '__NEW__') {
      // Reset dropdown to previous value
      selectElement.value = product.category || '';

      const dialogRef = this.dialog.open(CategoryCreateDialogComponent, {
        width: '420px',
        maxWidth: '95vw',
        data: { existingCategories: this.categories },
        disableClose: false
      });

      dialogRef.afterClosed().subscribe((result: CategoryCreateDialogResult) => {
        if (result?.name) {
          if (!this.categories.includes(result.name)) {
            this.categories.push(result.name);
            this.categories.sort();
          }
          product.category = result.name;
          this.markModified(product);
          // Update cache
          try {
            localStorage.setItem('cached_product_category_names', JSON.stringify(this.categories));
          } catch (e) {}
        }
      });
    } else {
      this.onCategoryFieldChange(product, value);
    }
  }

  private markModified(product: BulkEditProduct): void {
    const orig = product.originalValues;
    const isModified =
      product.customName !== orig.customName ||
      product.category !== orig.category ||
      product.price !== orig.price ||
      product.originalPrice !== orig.originalPrice ||
      product.stockQuantity !== orig.stockQuantity ||
      product.status !== orig.status ||
      product.isAvailable !== orig.isAvailable ||
      product.tags !== orig.tags ||
      product.sku !== orig.sku ||
      product.barcode1 !== orig.barcode1 ||
      product.barcode2 !== orig.barcode2 ||
      product.barcode3 !== orig.barcode3 ||
      product.nameTamil !== orig.nameTamil;

    if (isModified) {
      this.modifiedProducts.set(product.id, product);
    } else {
      this.modifiedProducts.delete(product.id);
    }
  }

  isModified(product: BulkEditProduct): boolean {
    return this.modifiedProducts.has(product.id);
  }

  isCellModified(product: BulkEditProduct, field: string): boolean {
    if (!this.isModified(product)) return false;
    const orig = product.originalValues;
    switch (field) {
      case 'customName': return product.customName !== orig.customName;
      case 'category': return product.category !== orig.category;
      case 'price': return product.price !== orig.price;
      case 'mrp': return product.originalPrice !== orig.originalPrice;
      case 'stock': return product.stockQuantity !== orig.stockQuantity;
      case 'status': return product.status !== orig.status;
      case 'tags': return product.tags !== orig.tags;
      case 'sku': return product.sku !== orig.sku;
      case 'barcode1': return product.barcode1 !== orig.barcode1;
      case 'barcode2': return product.barcode2 !== orig.barcode2;
      case 'barcode3': return product.barcode3 !== orig.barcode3;
      case 'nameTamil': return product.nameTamil !== orig.nameTamil;
      default: return false;
    }
  }

  // Validation
  isValidPrice(value: number | undefined): boolean {
    return value !== undefined && !isNaN(value) && value >= 0;
  }

  isValidStock(value: number | undefined): boolean {
    return value !== undefined && !isNaN(value) && value >= 0 && Number.isInteger(value);
  }

  // Check if a barcode/SKU is duplicate across all products
  isDuplicateBarcode(product: BulkEditProduct, field: string): boolean {
    const value = (product as any)[field]?.trim().toLowerCase();
    if (!value) return false;

    return this.products.some(p => {
      if (p.id === product.id) return false; // Skip same product

      // Check against all barcode fields and SKU
      const fieldsToCheck = ['sku', 'barcode1', 'barcode2', 'barcode3'];
      return fieldsToCheck.some(f => {
        const otherValue = (p as any)[f]?.trim().toLowerCase();
        return otherValue && otherValue === value;
      });
    });
  }

  // Check if barcode is duplicate within same product
  isDuplicateWithinProduct(product: BulkEditProduct, field: string): boolean {
    const value = (product as any)[field]?.trim().toLowerCase();
    if (!value) return false;

    const fieldsToCheck = ['sku', 'barcode1', 'barcode2', 'barcode3'].filter(f => f !== field);
    return fieldsToCheck.some(f => {
      const otherValue = (product as any)[f]?.trim().toLowerCase();
      return otherValue && otherValue === value;
    });
  }

  // Combined duplicate check
  hasDuplicateError(product: BulkEditProduct, field: string): boolean {
    return this.isDuplicateBarcode(product, field) || this.isDuplicateWithinProduct(product, field);
  }

  // Get duplicate error message
  getDuplicateErrorMessage(product: BulkEditProduct, field: string): string {
    const value = (product as any)[field]?.trim();
    if (!value) return '';

    if (this.isDuplicateWithinProduct(product, field)) {
      return `'${value}' is used in another field of same product`;
    }
    if (this.isDuplicateBarcode(product, field)) {
      return `'${value}' already exists in another product`;
    }
    return '';
  }

  // Save changes
  async saveChanges(): Promise<void> {
    if (this.modifiedProducts.size === 0) {
      this.snackBar.open('No changes to save', 'Close', { duration: 2000 });
      return;
    }

    // Validate all modified products
    const invalidProducts: string[] = [];
    this.modifiedProducts.forEach((product, id) => {
      // Check for empty product name
      if (!product.customName?.trim()) {
        invalidProducts.push(`Row ${id}: Product name is required`);
        return;
      }
      if (!this.isValidPrice(product.price)) {
        invalidProducts.push(`${product.customName}: Invalid price`);
      }
      if (product.originalPrice !== undefined && !this.isValidPrice(product.originalPrice)) {
        invalidProducts.push(`${product.customName}: Invalid MRP`);
      }
      if (!this.isValidStock(product.stockQuantity)) {
        invalidProducts.push(`${product.customName}: Invalid stock`);
      }
      // Check for duplicate barcodes/SKU
      const barcodeFields = ['sku', 'barcode1', 'barcode2', 'barcode3'];
      barcodeFields.forEach(field => {
        if (this.hasDuplicateError(product, field)) {
          const value = (product as any)[field];
          invalidProducts.push(`${product.customName}: Duplicate ${field.toUpperCase()} '${value}'`);
        }
      });
    });

    if (invalidProducts.length > 0) {
      this.snackBar.open(`Please fix errors: ${invalidProducts.slice(0, 3).join(', ')}`, 'Close', { duration: 5000 });
      return;
    }

    this.saving = true;
    const modifiedArray = Array.from(this.modifiedProducts.values());
    let successCount = 0;
    let errorCount = 0;

    // Save all modified products in parallel for speed
    const savePromises = modifiedArray.map(async (product) => {
      try {
        if (!navigator.onLine) {
          await this.saveEditOffline(product);
        } else {
          await this.saveProductToServer(product);
        }

        // Update original values after successful save
        product.originalValues = {
          customName: product.customName,
          category: product.category,
          price: product.price,
          originalPrice: product.originalPrice,
          stockQuantity: product.stockQuantity,
          status: product.status,
          isAvailable: product.isAvailable,
          tags: product.tags,
          sku: product.sku,
          barcode1: product.barcode1,
          barcode2: product.barcode2,
          barcode3: product.barcode3,
          nameTamil: product.nameTamil
        };
        this.modifiedProducts.delete(product.id);
        return { success: true, product };
      } catch (error) {
        console.error(`Failed to save product ${product.id}:`, error);
        return { success: false, product, error };
      }
    });

    const results = await Promise.all(savePromises);
    successCount = results.filter(r => r.success).length;
    errorCount = results.filter(r => !r.success).length;

    this.saving = false;

    if (errorCount === 0) {
      this.snackBar.open(`${successCount} products saved successfully`, 'Close', { duration: 3000 });
    } else {
      this.snackBar.open(`Saved ${successCount} products, ${errorCount} failed`, 'Close', { duration: 5000 });
    }

    // Update local cache only - no need to reload from server
    this.updateLocalCache();
  }

  private saveProductToServer(product: BulkEditProduct): Promise<void> {
    return new Promise((resolve, reject) => {
      const updateData = {
        customName: product.customName,
        category: product.category,
        price: product.price,
        originalPrice: product.originalPrice,
        stockQuantity: product.stockQuantity,
        isAvailable: product.isAvailable,
        status: product.status,
        sku: product.sku,
        barcode1: product.barcode1,
        barcode2: product.barcode2,
        barcode3: product.barcode3,
        nameTamil: product.nameTamil
      };

      this.http.put(`${this.apiUrl}/shop-products/${product.id}`, updateData)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: () => resolve(),
          error: (error) => reject(error)
        });
    });
  }

  private async saveEditOffline(product: BulkEditProduct): Promise<void> {
    const offlineEdit = {
      editId: this.offlineStorage.generateOfflineEditId(),
      productId: product.id,
      shopId: 0,
      changes: {
        customName: product.customName,
        price: product.price,
        originalPrice: product.originalPrice,
        stockQuantity: product.stockQuantity,
        isAvailable: product.isAvailable,
        sku: product.sku,
        barcode1: product.barcode1,
        barcode2: product.barcode2,
        barcode3: product.barcode3,
        nameTamil: product.nameTamil
      },
      previousValues: {
        name: product.originalValues.customName,
        price: product.originalValues.price,
        originalPrice: product.originalValues.originalPrice,
        stockQuantity: product.originalValues.stockQuantity,
        isAvailable: product.originalValues.isAvailable,
        sku: product.originalValues.sku,
        barcode1: product.originalValues.barcode1,
        barcode2: product.originalValues.barcode2,
        barcode3: product.originalValues.barcode3,
        nameTamil: product.originalValues.nameTamil
      },
      createdAt: new Date().toISOString(),
      synced: false
    };

    await this.offlineStorage.saveOfflineEdit(offlineEdit);
  }

  private async updateLocalCache(): Promise<void> {
    try {
      for (const product of this.products) {
        await this.offlineStorage.updateLocalProduct(product.id, {
          name: product.customName,
          nameTamil: product.nameTamil,
          price: product.price,
          originalPrice: product.originalPrice,
          stock: product.stockQuantity,
          isAvailable: product.isAvailable,
          sku: product.sku,
          barcode1: product.barcode1,
          barcode2: product.barcode2,
          barcode3: product.barcode3
        });
      }
    } catch (error) {
      console.warn('Failed to update local cache:', error);
    }
  }

  // Discard all changes
  discardChanges(): void {
    if (this.modifiedProducts.size === 0) return;

    const confirmed = confirm(`Discard all ${this.modifiedProducts.size} unsaved changes?`);
    if (!confirmed) return;

    // Restore original values
    this.modifiedProducts.forEach((product) => {
      product.customName = product.originalValues.customName;
      product.category = product.originalValues.category;
      product.price = product.originalValues.price;
      product.originalPrice = product.originalValues.originalPrice;
      product.stockQuantity = product.originalValues.stockQuantity;
      product.status = product.originalValues.status;
      product.isAvailable = product.originalValues.isAvailable;
      product.tags = product.originalValues.tags;
      product.sku = product.originalValues.sku;
      product.barcode1 = product.originalValues.barcode1;
      product.barcode2 = product.originalValues.barcode2;
      product.barcode3 = product.originalValues.barcode3;
      product.nameTamil = product.originalValues.nameTamil;
    });

    this.modifiedProducts.clear();
    this.snackBar.open('All changes discarded', 'Close', { duration: 2000 });
  }

  // Get product image
  getProductImageUrl(product: BulkEditProduct): string {
    if (!product.imageUrl) {
      return 'assets/images/product-placeholder.svg';
    }
    return getImageUrlUtil(product.imageUrl) || 'assets/images/product-placeholder.svg';
  }

  // Get row number
  getRowNumber(index: number): number {
    return this.currentPageIndex * this.pageSize + index + 1;
  }

  // Helper for min in template
  min(a: number, b: number): number {
    return Math.min(a, b);
  }

  // Image upload handling
  uploadingImageFor: number | null = null;

  triggerImageUpload(product: BulkEditProduct, fileInput: HTMLInputElement): void {
    this.uploadingImageFor = product.id;
    fileInput.click();
  }

  async onImageSelected(event: Event, product: BulkEditProduct): Promise<void> {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) {
      this.uploadingImageFor = null;
      return;
    }

    const file = input.files[0];

    // Validate file type
    if (!file.type.startsWith('image/')) {
      this.snackBar.open('Please select an image file', 'Close', { duration: 3000 });
      this.uploadingImageFor = null;
      return;
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      this.snackBar.open('Image must be less than 5MB', 'Close', { duration: 3000 });
      this.uploadingImageFor = null;
      return;
    }

    try {
      const formData = new FormData();
      formData.append('file', file);

      const response: any = await this.http.post(
        `${this.apiUrl}/shop-products/${product.id}/image`,
        formData
      ).toPromise();

      // Update local image URL
      if (response?.data?.imageUrl || response?.imageUrl) {
        product.imageUrl = response?.data?.imageUrl || response?.imageUrl;
        this.snackBar.open('Image updated successfully', 'Close', { duration: 2000 });
      } else {
        // Reload products to get new image
        this.loadProducts(true);
        this.snackBar.open('Image uploaded', 'Close', { duration: 2000 });
      }
    } catch (error: any) {
      console.error('Failed to upload image:', error);
      this.snackBar.open(error?.error?.message || 'Failed to upload image', 'Close', { duration: 3000 });
    } finally {
      this.uploadingImageFor = null;
      input.value = ''; // Reset file input
    }
  }

  isUploadingImage(product: BulkEditProduct): boolean {
    return this.uploadingImageFor === product.id;
  }

  // Get Google Image search URL for product
  getImageSearchUrl(product: BulkEditProduct): string {
    const searchQuery = encodeURIComponent(product.customName + ' product');
    return `https://www.google.com/search?q=${searchQuery}&udm=2`;
  }

  // Get Google Translate URL (English to Tamil)
  getTranslateUrl(product: BulkEditProduct): string {
    const text = encodeURIComponent(product.customName);
    return `https://translate.google.com/?sl=en&tl=ta&text=${text}&op=translate`;
  }

  // Tamil to English transliteration map
  private tamilToEnglish: { [key: string]: string } = {
    // Vowels
    'அ': 'a', 'ஆ': 'aa', 'இ': 'i', 'ஈ': 'ee', 'உ': 'u', 'ஊ': 'oo',
    'எ': 'e', 'ஏ': 'ae', 'ஐ': 'ai', 'ஒ': 'o', 'ஓ': 'oo', 'ஔ': 'au',
    // Consonants
    'க': 'ka', 'கா': 'kaa', 'கி': 'ki', 'கீ': 'kee', 'கு': 'ku', 'கூ': 'koo', 'கெ': 'ke', 'கே': 'kae', 'கை': 'kai', 'கொ': 'ko', 'கோ': 'koo', 'கௌ': 'kau', 'க்': 'k',
    'ங': 'nga', 'ஙா': 'ngaa', 'ஙி': 'ngi', 'ஙீ': 'ngee', 'ஙு': 'ngu', 'ஙூ': 'ngoo', 'ங்': 'ng',
    'ச': 'sa', 'சா': 'saa', 'சி': 'si', 'சீ': 'see', 'சு': 'su', 'சூ': 'soo', 'செ': 'se', 'சே': 'sae', 'சை': 'sai', 'சொ': 'so', 'சோ': 'soo', 'சௌ': 'sau', 'ச்': 's',
    'ஞ': 'nya', 'ஞா': 'nyaa', 'ஞி': 'nyi', 'ஞீ': 'nyee', 'ஞு': 'nyu', 'ஞூ': 'nyoo', 'ஞ்': 'ny',
    'ட': 'da', 'டா': 'daa', 'டி': 'di', 'டீ': 'dee', 'டு': 'du', 'டூ': 'doo', 'டெ': 'de', 'டே': 'dae', 'டை': 'dai', 'டொ': 'do', 'டோ': 'doo', 'டௌ': 'dau', 'ட்': 'd',
    'ண': 'na', 'ணா': 'naa', 'ணி': 'ni', 'ணீ': 'nee', 'ணு': 'nu', 'ணூ': 'noo', 'ணெ': 'ne', 'ணே': 'nae', 'ணை': 'nai', 'ணொ': 'no', 'ணோ': 'noo', 'ணௌ': 'nau', 'ண்': 'n',
    'த': 'tha', 'தா': 'thaa', 'தி': 'thi', 'தீ': 'thee', 'து': 'thu', 'தூ': 'thoo', 'தெ': 'the', 'தே': 'thae', 'தை': 'thai', 'தொ': 'tho', 'தோ': 'thoo', 'தௌ': 'thau', 'த்': 'th',
    'ந': 'na', 'நா': 'naa', 'நி': 'ni', 'நீ': 'nee', 'நு': 'nu', 'நூ': 'noo', 'நெ': 'ne', 'நே': 'nae', 'நை': 'nai', 'நொ': 'no', 'நோ': 'noo', 'நௌ': 'nau', 'ந்': 'n',
    'ப': 'pa', 'பா': 'paa', 'பி': 'pi', 'பீ': 'pee', 'பு': 'pu', 'பூ': 'poo', 'பெ': 'pe', 'பே': 'pae', 'பை': 'pai', 'பொ': 'po', 'போ': 'poo', 'பௌ': 'pau', 'ப்': 'p',
    'ம': 'ma', 'மா': 'maa', 'மி': 'mi', 'மீ': 'mee', 'மு': 'mu', 'மூ': 'moo', 'மெ': 'me', 'மே': 'mae', 'மை': 'mai', 'மொ': 'mo', 'மோ': 'moo', 'மௌ': 'mau', 'ம்': 'm',
    'ய': 'ya', 'யா': 'yaa', 'யி': 'yi', 'யீ': 'yee', 'யு': 'yu', 'யூ': 'yoo', 'யெ': 'ye', 'யே': 'yae', 'யை': 'yai', 'யொ': 'yo', 'யோ': 'yoo', 'யௌ': 'yau', 'ய்': 'y',
    'ர': 'ra', 'ரா': 'raa', 'ரி': 'ri', 'ரீ': 'ree', 'ரு': 'ru', 'ரூ': 'roo', 'ரெ': 're', 'ரே': 'rae', 'ரை': 'rai', 'ரொ': 'ro', 'ரோ': 'roo', 'ரௌ': 'rau', 'ர்': 'r',
    'ல': 'la', 'லா': 'laa', 'லி': 'li', 'லீ': 'lee', 'லு': 'lu', 'லூ': 'loo', 'லெ': 'le', 'லே': 'lae', 'லை': 'lai', 'லொ': 'lo', 'லோ': 'loo', 'லௌ': 'lau', 'ல்': 'l',
    'வ': 'va', 'வா': 'vaa', 'வி': 'vi', 'வீ': 'vee', 'வு': 'vu', 'வூ': 'voo', 'வெ': 've', 'வே': 'vae', 'வை': 'vai', 'வொ': 'vo', 'வோ': 'voo', 'வௌ': 'vau', 'வ்': 'v',
    'ழ': 'zha', 'ழா': 'zhaa', 'ழி': 'zhi', 'ழீ': 'zhee', 'ழு': 'zhu', 'ழூ': 'zhoo', 'ழெ': 'zhe', 'ழே': 'zhae', 'ழை': 'zhai', 'ழொ': 'zho', 'ழோ': 'zhoo', 'ழௌ': 'zhau', 'ழ்': 'zh',
    'ள': 'la', 'ளா': 'laa', 'ளி': 'li', 'ளீ': 'lee', 'ளு': 'lu', 'ளூ': 'loo', 'ளெ': 'le', 'ளே': 'lae', 'ளை': 'lai', 'ளொ': 'lo', 'ளோ': 'loo', 'ளௌ': 'lau', 'ள்': 'l',
    'ற': 'ra', 'றா': 'raa', 'றி': 'ri', 'றீ': 'ree', 'று': 'ru', 'றூ': 'roo', 'றெ': 're', 'றே': 'rae', 'றை': 'rai', 'றொ': 'ro', 'றோ': 'roo', 'றௌ': 'rau', 'ற்': 'r',
    'ன': 'na', 'னா': 'naa', 'னி': 'ni', 'னீ': 'nee', 'னு': 'nu', 'னூ': 'noo', 'னெ': 'ne', 'னே': 'nae', 'னை': 'nai', 'னொ': 'no', 'னோ': 'noo', 'னௌ': 'nau', 'ன்': 'n',
    // Grantha consonants
    'ஜ': 'ja', 'ஜா': 'jaa', 'ஜி': 'ji', 'ஜீ': 'jee', 'ஜு': 'ju', 'ஜூ': 'joo', 'ஜெ': 'je', 'ஜே': 'jae', 'ஜை': 'jai', 'ஜொ': 'jo', 'ஜோ': 'joo', 'ஜௌ': 'jau', 'ஜ்': 'j',
    'ஷ': 'sha', 'ஷா': 'shaa', 'ஷி': 'shi', 'ஷீ': 'shee', 'ஷு': 'shu', 'ஷூ': 'shoo', 'ஷெ': 'she', 'ஷே': 'shae', 'ஷை': 'shai', 'ஷொ': 'sho', 'ஷோ': 'shoo', 'ஷௌ': 'shau', 'ஷ்': 'sh',
    'ஸ': 'sa', 'ஸா': 'saa', 'ஸி': 'si', 'ஸீ': 'see', 'ஸு': 'su', 'ஸூ': 'soo', 'ஸெ': 'se', 'ஸே': 'sae', 'ஸை': 'sai', 'ஸொ': 'so', 'ஸோ': 'soo', 'ஸௌ': 'sau', 'ஸ்': 's',
    'ஹ': 'ha', 'ஹா': 'haa', 'ஹி': 'hi', 'ஹீ': 'hee', 'ஹு': 'hu', 'ஹூ': 'hoo', 'ஹெ': 'he', 'ஹே': 'hae', 'ஹை': 'hai', 'ஹொ': 'ho', 'ஹோ': 'hoo', 'ஹௌ': 'hau', 'ஹ்': 'h',
    'க்ஷ': 'ksha', 'ஸ்ரீ': 'shri'
  };

  // Convert Tamil text to English phonetic
  transliterateTamil(text: string): string {
    if (!text) return '';

    let result = '';
    let i = 0;

    while (i < text.length) {
      // Try 3-char, 2-char, then 1-char matches
      let matched = false;

      for (let len = 3; len >= 1; len--) {
        const chunk = text.substring(i, i + len);
        if (this.tamilToEnglish[chunk]) {
          result += this.tamilToEnglish[chunk];
          i += len;
          matched = true;
          break;
        }
      }

      if (!matched) {
        // Keep English letters, skip other characters
        const char = text[i];
        if (/[a-zA-Z0-9]/.test(char)) {
          result += char.toLowerCase();
        } else if (char === ' ') {
          result += ' ';
        }
        i++;
      }
    }

    return result.trim();
  }

  // Auto-generate tags from product name, Tamil phonetic, and category
  autoGenerateTags(product: BulkEditProduct): void {
    const tags: Set<string> = new Set();

    // Extract keywords from product name (English letters only)
    const skipWords = ['and', 'or', 'the', 'a', 'an', 'of', 'for', 'with', 'in', 'to', 'is', 'by', 'pack', 'pcs', 'piece', 'pieces', 'gm', 'gms', 'kg', 'ml', 'ltr', 'lt'];
    const productWords = product.customName
      .toLowerCase()
      .replace(/[^a-z\s]/g, ' ')
      .split(/\s+/)
      .filter(word => word.length > 1 && !skipWords.includes(word));

    productWords.forEach(word => tags.add(word));

    // Add Tamil phonetic transliteration
    if (product.nameTamil) {
      const phonetic = this.transliterateTamil(product.nameTamil);
      if (phonetic) {
        // Add full phonetic name
        const phoneticClean = phonetic.replace(/\s+/g, '');
        if (phoneticClean.length > 1) {
          tags.add(phoneticClean);
        }
        // Add individual phonetic words
        phonetic.split(/\s+/).forEach(word => {
          if (word.length > 1) tags.add(word);
        });
      }
    }

    // Add category as tag
    if (product.category) {
      const categoryLower = product.category.toLowerCase().replace(/[^a-z\s]/g, '');
      if (categoryLower.length > 1) {
        tags.add(categoryLower);
      }
    }

    // Convert to comma-separated string
    product.tags = Array.from(tags).join(', ');
    this.markModified(product);

    this.snackBar.open(`Generated ${tags.size} tags`, 'Close', { duration: 2000 });
  }

  // Remove image
  async removeImage(product: BulkEditProduct): Promise<void> {
    const confirmed = confirm('Remove this product image?');
    if (!confirmed) return;

    this.uploadingImageFor = product.id;

    try {
      // Call API to remove image
      await this.http.delete(`${this.apiUrl}/shop-products/${product.id}/image`).toPromise();

      // Clear local image URL
      product.imageUrl = '';
      this.snackBar.open('Image removed', 'Close', { duration: 2000 });
    } catch (error: any) {
      console.error('Failed to remove image:', error);
      // Even if API fails, clear locally
      product.imageUrl = '';
      this.snackBar.open('Image removed locally', 'Close', { duration: 2000 });
    } finally {
      this.uploadingImageFor = null;
    }
  }
}
