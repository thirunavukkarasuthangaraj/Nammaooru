import { Component, OnInit, OnDestroy } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';
import { Subject } from 'rxjs';
import { takeUntil, debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { OfflineStorageService, CachedProduct } from '../../../../core/services/offline-storage.service';
import { VersionService } from '../../../../core/services/version.service';
import { getImageUrl as getImageUrlUtil } from '../../../../core/utils/image-url.util';

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
  pageSize = 50;
  pageSizeOptions = [25, 50, 100, 200];
  currentPageIndex = 0;

  // Track modifications
  modifiedProducts: Map<number, BulkEditProduct> = new Map();

  // Version info
  clientVersion = '';

  constructor(
    private http: HttpClient,
    private snackBar: MatSnackBar,
    private offlineStorage: OfflineStorageService,
    private versionService: VersionService
  ) {}

  ngOnInit(): void {
    this.clientVersion = this.versionService.getVersion().replace('v', '');
    this.loadProducts();

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

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  async loadProducts(): Promise<void> {
    this.loading = true;

    // Step 1: Load from local cache first (instant)
    try {
      const cachedProducts = await this.offlineStorage.getProducts();
      if (cachedProducts.length > 0) {
        this.mapCachedProducts(cachedProducts);
        this.loading = false;
      }
    } catch (error) {
      console.warn('Error loading from cache:', error);
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

    // Update local cache and refresh display
    this.updateLocalCache();

    // Force refresh to show updated data
    if (navigator.onLine) {
      this.loadProducts(true);
    }
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
}
