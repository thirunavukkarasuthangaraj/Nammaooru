import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { MatDialog } from '@angular/material/dialog';
import { HttpClient } from '@angular/common/http';
import { Subject, forkJoin, of } from 'rxjs';
import { takeUntil, debounceTime, distinctUntilChanged, catchError } from 'rxjs/operators';
import { ProductCategory } from '../../../../core/models/product.model';
import { environment } from '../../../../../environments/environment';
import { OfflineStorageService, CachedProduct } from '../../../../core/services/offline-storage.service';
import { VersionService } from '../../../../core/services/version.service';
import { SwalService } from '../../../../core/services/swal.service';
import { getImageUrl as getImageUrlUtil } from '../../../../core/utils/image-url.util';
import { CategoryCreateDialogComponent, CategoryCreateDialogResult, syncOfflineCategories } from '../category-create-dialog/category-create-dialog.component';
import { ProductCategoryService } from '../../../../core/services/product-category.service';
import Swal from 'sweetalert2';

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
  // True = priced per 250g; customer app shows a weight picker
  // (250g/500g/1kg... as plain quantities of this product).
  sellByWeight?: boolean;
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
    sellByWeight?: boolean;
  };
}

interface ImageSuggestion {
  label: string;
  thumb: string;
  url: string;
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
  filteredCategories: string[] = [];
  // Toolbar's Category filter shows root names only (subgroups get their own
  // cascading dropdown below) - categories/filteredCategories above stay the
  // full flat list, still used for duplicate-name checks in the create dialog.
  filteredRootCategories: string[] = [];
  categoryFilterText = '';
  // Subgroup name -> "Parent > Subgroup" for display, so the dropdown shows
  // hierarchy while the stored value stays the plain category name the
  // backend matches against.
  categoryDisplayMap: Map<string, string> = new Map();
  // Category and Subcategory render as two separate short dropdowns per row
  // instead of one combined list, mirroring Add Product.
  rootCategoryOptions: { id: number; name: string }[] = [];
  categoryChildrenMap: Map<string, string[]> = new Map();
  categoryParentMap: Map<string, string> = new Map();
  loading = false;
  saving = false;

  // Filter controls
  searchTerm = '';
  selectedCategory = '';
  selectedSubcategory = '';
  selectedStatus = '';
  // Cascading like country->state: populated from categoryChildrenMap once a
  // root Category is picked in the top filter bar.
  subcategoryFilterOptions: string[] = [];

  // Pagination
  totalProducts = 0;
  pageSize = 100;
  pageSizeOptions = [50, 100, 200, 500];
  currentPageIndex = 0;

  // IDs passed from My Products checkboxes (sessionStorage).
  private readonly BULK_EDIT_IDS_KEY = 'shopOwnerBulkEditProductIds';
  selectedProductIds: number[] | null = null;

  get selectedProductCount(): number {
    return this.selectedProductIds?.length ?? 0;
  }

  get copySuffixCount(): number {
    return this.filteredProducts.filter(p => /(-COPY(-\d+)?)+$/i.test(p.sku || '')).length;
  }

  stripCopyFromSkus(): void {
    let changed = 0;
    for (const product of this.filteredProducts) {
      const stripped = (product.sku || '').replace(/(-COPY(-\d+)?)+$/i, '');
      if (stripped && stripped !== product.sku) {
        product.sku = stripped;
        this.markModified(product);
        changed++;
      }
    }
    if (changed === 0) {
      this.swalService.toast('No -COPY suffix on these SKUs', 'info');
      return;
    }
    this.recomputeDuplicateErrors();
    this.swalService.toast(`Removed -COPY from ${changed} SKU${changed === 1 ? '' : 's'}. Click Save Changes.`, 'success');
  }

  // Track modifications
  modifiedProducts: Map<number, BulkEditProduct> = new Map();

  // Precomputed duplicate-validation errors keyed by product id -> field -> message.
  // Computed once on load / on barcode-sku edits instead of scanning all products on
  // every change-detection cycle from the template (which froze navigation for seconds).
  private duplicateErrorMap: Map<number, { [field: string]: string }> = new Map();

  // Version info
  clientVersion = '';

  // Offline support
  isOffline = false;
  lastSyncTime: Date | null = null;

  constructor(
    private http: HttpClient,
    private offlineStorage: OfflineStorageService,
    private versionService: VersionService,
    private dialog: MatDialog,
    private swalService: SwalService,
    private categoryService: ProductCategoryService,
    private router: Router
  ) {}

  // Same route My Products' "Add Custom Product" button uses, so bulk-edit
  // doesn't need its own duplicate add-product form.
  addNewProduct(): void {
    this.router.navigate(['/shop-owner/my-products/add']);
  }

  ngOnInit(): void {
    this.clientVersion = this.versionService.getVersion().replace('v', '');
    this.readSelectedProductIds();

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
    this.swalService.toast('Back online! Syncing changes...', 'success');
    // Sync offline categories first, then load products
    syncOfflineCategories(this.http, this.apiUrl).then(() => {
      this.loadProducts(true);
    });
  }

  private handleOffline = (): void => {
    console.log('Network offline - using cached data');
    this.isOffline = true;
    this.swalService.toast('You are offline. Changes will be saved locally.', 'warning');
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
    this.recomputeDuplicateErrors();
  }

  private async syncProductsFromServer(): Promise<void> {
    const pageSize = 500;
    let allProducts: any[] = [];
    let currentPage = 0;
    let totalPages = 1;

    try {
      // Fetch all pages
      while (currentPage < totalPages) {
        // Newest-added products first, so items just created show up at the
        // top instead of being buried by the endpoint's updatedAt default.
        const response: any = await this.http.get<any>(
          `${this.apiUrl}/shop-products/my-products?page=${currentPage}&size=${pageSize}&sortBy=createdAt&sortDirection=DESC`
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
        sku: this.storedSku(p),
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
        sellByWeight: p.baseUnit === 'g' && Number(p.baseWeight) === 250,
        originalValues: {
          customName: p.displayName || p.customName || p.masterProduct?.name,
          category: p.masterProduct?.category?.name || '',
          price: p.price,
          originalPrice: p.originalPrice,
          stockQuantity: p.stockQuantity,
          status: p.status || (p.isAvailable ? 'ACTIVE' : 'INACTIVE'),
          isAvailable: p.isAvailable,
          tags: p.masterProduct?.tags || '',
          sku: this.storedSku(p),
          barcode1: p.barcode1 || '',
          barcode2: p.barcode2 || '',
          barcode3: p.barcode3 || '',
          nameTamil: p.masterProduct?.nameTamil || '',
          sellByWeight: p.baseUnit === 'g' && Number(p.baseWeight) === 250
        }
      }));

      this.applyFilters();
      this.extractCategories();
      this.recomputeDuplicateErrors();
      this.loading = false;
    } catch (error) {
      console.error('Failed to sync products:', error);
      this.loading = false;
      if (this.products.length === 0) {
        this.swalService.toast('Failed to load products', 'error');
      }
    }
  }

  private extractCategories(): void {
    // Master category list (includes newly created categories with no products assigned yet)
    this.categoryService.getCategories(undefined, true, undefined, 0, 500).subscribe({
      next: (page) => {
        const roots = page.content || [];
        const productNames = this.products.map(p => p.category).filter(Boolean) as string[];
        this.buildCategoryOptions(roots, productNames);
      },
      error: () => {
        // Fall back to categories in use if the master list can't be fetched
        this.categories = [...new Set(this.products.map(p => p.category).filter(Boolean) as string[])];
        this.filteredCategories = this.categories;
        this.filteredRootCategories = this.categories;
      }
    });
  }

  // Fetches subgroups for every root category that has them, so subgroups a
  // shop owner created (e.g. Rice Bag under Rice) are selectable here too.
  private buildCategoryOptions(roots: ProductCategory[], productNames: string[]): void {
    const displayMap = new Map<string, string>();
    roots.forEach(c => displayMap.set(c.name, c.fullPath || c.name));
    this.rootCategoryOptions = roots.map(c => ({ id: c.id, name: c.name })).sort((a, b) => a.name.localeCompare(b.name));

    const withSubs = roots.filter(c => c.hasSubcategories);
    const finish = (subLists: ProductCategory[][]) => {
      const childrenMap = new Map<string, string[]>();
      const parentMap = new Map<string, string>();

      withSubs.forEach((root, i) => {
        const subNames = subLists[i].map(s => s.name);
        subLists[i].forEach(sub => displayMap.set(sub.name, sub.fullPath || sub.name));
        if (subNames.length) childrenMap.set(root.name, subNames);
        subNames.forEach(subName => parentMap.set(subName, root.name));
      });

      productNames.forEach(name => {
        if (!displayMap.has(name)) displayMap.set(name, name);
      });

      this.categoryChildrenMap = childrenMap;
      this.categoryParentMap = parentMap;
      this.categoryDisplayMap = displayMap;
      this.categories = [...displayMap.keys()].sort((a, b) =>
        (displayMap.get(a) || a).localeCompare(displayMap.get(b) || b));
      this.filteredCategories = this.categories;
      this.filteredRootCategories = this.rootCategoryOptions.map(r => r.name);
    };

    if (withSubs.length === 0) {
      finish([]);
      return;
    }

    forkJoin(
      withSubs.map(root =>
        this.categoryService.getSubcategories(root.id, true).pipe(
          catchError(() => of([] as ProductCategory[]))
        )
      )
    ).subscribe(finish);
  }

  getRootCategoryOf(product: BulkEditProduct): string {
    const cat = product.category || '';
    return this.categoryParentMap.get(cat) || cat;
  }

  getSubcategoryOptions(product: BulkEditProduct): string[] {
    return this.categoryChildrenMap.get(this.getRootCategoryOf(product)) || [];
  }

  getSubcategoryValue(product: BulkEditProduct): string {
    const cat = product.category || '';
    return this.categoryParentMap.has(cat) ? cat : '';
  }

  categoryLabel(name: string): string {
    return this.categoryDisplayMap.get(name) || name;
  }

  /** Filters the Category autocomplete options (root categories only) as the user types. */
  filterCategoryOptions(): void {
    const term = this.categoryFilterText.toLowerCase().trim();
    const roots = this.rootCategoryOptions.map(r => r.name);
    this.filteredRootCategories = !term
      ? roots
      : roots.filter(c => c.toLowerCase().includes(term));
  }

  private readSelectedProductIds(): void {
    try {
      const raw = sessionStorage.getItem(this.BULK_EDIT_IDS_KEY);
      if (!raw) {
        this.selectedProductIds = null;
        return;
      }
      const parsed = JSON.parse(raw);
      const ids = Array.isArray(parsed)
        ? parsed.map((id: unknown) => Number(id)).filter((id: number) => Number.isFinite(id) && id > 0)
        : [];
      this.selectedProductIds = ids.length > 0 ? ids : null;
    } catch {
      this.selectedProductIds = null;
    }
  }

  showAllProducts(): void {
    sessionStorage.removeItem(this.BULK_EDIT_IDS_KEY);
    this.selectedProductIds = null;
    this.applyFilters();
  }

  applyFilters(): void {
    const searchLower = this.searchTerm?.toLowerCase().trim() || '';
    const selectedSet = this.selectedProductIds ? new Set(this.selectedProductIds) : null;

    this.filteredProducts = this.products.filter(product => {
      const matchesSelection = !selectedSet || selectedSet.has(product.id);
      const matchesSearch = !searchLower ||
        (product.customName || '').toLowerCase().includes(searchLower) ||
        (product.nameTamil || '').toLowerCase().includes(searchLower) ||
        (product.sku || '').toLowerCase().includes(searchLower) ||
        (product.tags || '').toLowerCase().includes(searchLower);

      // A root Category alone matches it AND every one of its subgroups
      // (e.g. picking "Beverages" also shows Tea/Coffee products); picking a
      // specific Subcategory narrows to just that subgroup.
      const matchesCategory = this.selectedSubcategory
        ? product.category === this.selectedSubcategory
        : !this.selectedCategory ||
          product.category === this.selectedCategory ||
          this.categoryParentMap.get(product.category || '') === this.selectedCategory;
      const matchesStatus = !this.selectedStatus ||
        product.status === this.selectedStatus ||
        (this.selectedStatus === 'available' && product.isAvailable) ||
        (this.selectedStatus === 'unavailable' && !product.isAvailable);

      return matchesSelection && matchesSearch && matchesCategory && matchesStatus;
    });

    if (this.selectedProductIds?.length) {
      const order = new Map(this.selectedProductIds.map((id, index) => [id, index]));
      this.filteredProducts.sort((a, b) => (order.get(a.id) ?? 0) - (order.get(b.id) ?? 0));
    }

    this.totalProducts = this.filteredProducts.length;
    this.currentPageIndex = 0;
  }

  onSearchChange(event: any): void {
    this.searchSubject$.next(event.target.value);
  }

  onCategoryChange(category: string): void {
    this.selectedCategory = category;
    this.selectedSubcategory = '';
    this.subcategoryFilterOptions = this.categoryChildrenMap.get(category) || [];
    this.applyFilters();
  }

  onSubcategoryFilterChange(subcategory: string): void {
    this.selectedSubcategory = subcategory;
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
    this.recomputeDuplicateErrors();
  }

  onBarcode1Change(product: BulkEditProduct, value: string): void {
    product.barcode1 = value;
    this.markModified(product);
    this.recomputeDuplicateErrors();
  }

  onBarcode2Change(product: BulkEditProduct, value: string): void {
    product.barcode2 = value;
    this.markModified(product);
    this.recomputeDuplicateErrors();
  }

  onBarcode3Change(product: BulkEditProduct, value: string): void {
    product.barcode3 = value;
    this.markModified(product);
    this.recomputeDuplicateErrors();
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

  // One click converts a per-kg product to weight-selling: price /4 (250g),
  // stock x4 (250g units), "1kg" stripped from the name - so the owner keeps
  // one product and one stock number, and the customer app offers
  // 250g/500g/1kg/2kg with exact billing. Reversible.
  async onSellByWeightChange(product: BulkEditProduct, selectElement: HTMLSelectElement): Promise<void> {
    const toWeight = selectElement.value === '250g';
    if (toWeight === !!product.sellByWeight) return;

    if (toWeight) {
      const newPrice = +(product.price / 4).toFixed(2);
      const newStock = product.stockQuantity * 4;
      const result = await Swal.fire({
        title: 'Sell by weight?',
        html:
          `Price becomes <b>₹${newPrice} per 250g</b> (1kg still ₹${product.price})<br>` +
          `Stock becomes <b>${newStock}</b> × 250g units (= ${product.stockQuantity}kg)<br>` +
          `Customers will pick 250g / 500g / 750g / 1kg / 2kg in the app.`,
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Convert',
        cancelButtonText: 'Cancel'
      });
      if (!result.isConfirmed) {
        selectElement.value = 'normal';
        return;
      }
      product.price = newPrice;
      if (product.originalPrice) {
        product.originalPrice = +(product.originalPrice / 4).toFixed(2);
      }
      product.stockQuantity = newStock;
      const stripped = (product.customName || '').replace(/\s*1\s*kg\s*$/i, '').trim();
      if (stripped) product.customName = stripped;
      product.sellByWeight = true;
    } else {
      product.price = +(product.price * 4).toFixed(2);
      if (product.originalPrice) {
        product.originalPrice = +(product.originalPrice * 4).toFixed(2);
      }
      product.stockQuantity = Math.round(product.stockQuantity / 4);
      product.sellByWeight = false;
    }
    this.markModified(product);
  }

  onRootCategoryDropdownChange(product: BulkEditProduct, selectElement: HTMLSelectElement): void {
    const value = selectElement.value;
    if (value === '__NEW__') {
      selectElement.value = this.getRootCategoryOf(product);
      this.openCategoryDialogForRow(product);
      return;
    }
    // Switching the category clears any subgroup that belonged to the old one.
    this.onCategoryFieldChange(product, value);
  }

  onSubcategoryDropdownChange(product: BulkEditProduct, selectElement: HTMLSelectElement): void {
    const value = selectElement.value;
    if (value === '__NEW__') {
      selectElement.value = this.getSubcategoryValue(product);
      this.openCategoryDialogForRow(product, this.getRootCategoryOf(product));
      return;
    }
    this.onCategoryFieldChange(product, value || this.getRootCategoryOf(product));
  }

  // Shared by both the Category and Subcategory "+ Add New" options.
  // presetRootName scopes the new entry under that root (subgroup creation);
  // omit it to create a new top-level category.
  private openCategoryDialogForRow(product: BulkEditProduct, presetRootName?: string): void {
    const presetRoot = presetRootName ? this.rootCategoryOptions.find(r => r.name === presetRootName) : undefined;

    const dialogRef = this.dialog.open(CategoryCreateDialogComponent, {
      width: '420px',
      maxWidth: '95vw',
      data: {
        existingCategories: this.categories,
        parentOptions: this.rootCategoryOptions,
        defaultParentId: presetRoot?.id ?? null
      },
      disableClose: false
    });

    dialogRef.afterClosed().subscribe((result: CategoryCreateDialogResult) => {
      if (!result?.name) return;

      const parent = result.parentId ? this.rootCategoryOptions.find(r => r.id === result.parentId) : undefined;

      if (!this.categories.includes(result.name)) {
        this.categories.push(result.name);
      }
      this.categoryDisplayMap.set(result.name, parent ? `${parent.name} > ${result.name}` : result.name);
      this.categories.sort((a, b) => (this.categoryDisplayMap.get(a) || a).localeCompare(this.categoryDisplayMap.get(b) || b));
      this.filteredCategories = this.categories;

      if (parent) {
        const children = this.categoryChildrenMap.get(parent.name) || [];
        children.push(result.name);
        this.categoryChildrenMap.set(parent.name, children);
        this.categoryParentMap.set(result.name, parent.name);
      } else {
        this.rootCategoryOptions.push({ id: result.id || -(Date.now()), name: result.name });
        this.rootCategoryOptions.sort((a, b) => a.name.localeCompare(b.name));
      }

      this.onCategoryFieldChange(product, result.name);

      try {
        localStorage.setItem('cached_product_category_names', JSON.stringify(this.categories));
      } catch (e) {}
    });
  }

  // Prefer nested master SKU: the list API's top-level `sku` is a display
  // value that strips "-COPY". Shop owners need the stored value in this grid
  // so they can edit or remove that suffix themselves.
  private storedSku(p: any): string {
    return p?.masterProduct?.sku || p?.sku || '';
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
      product.nameTamil !== orig.nameTamil ||
      product.sellByWeight !== orig.sellByWeight;

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
      case 'sellByWeight': return product.sellByWeight !== orig.sellByWeight;
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

  // Combined duplicate check - O(1) lookup into the precomputed map.
  // (Called from the template per cell, so it MUST be cheap.)
  hasDuplicateError(product: BulkEditProduct, field: string): boolean {
    return !!this.duplicateErrorMap.get(product.id)?.[field];
  }

  // Get duplicate error message - O(1) lookup into the precomputed map.
  getDuplicateErrorMessage(product: BulkEditProduct, field: string): string {
    return this.duplicateErrorMap.get(product.id)?.[field] || '';
  }

  /**
   * Recompute duplicate SKU/barcode errors for ALL products in a single O(products) pass
   * and cache them. The template then only does O(1) map reads per cell, so change
   * detection (triggered by clicks, navigation, etc.) no longer re-scans 1000 products
   * per cell and freezes the UI. Call this on data load and after a SKU/barcode edit.
   */
  private recomputeDuplicateErrors(): void {
    const fields = ['sku', 'barcode1', 'barcode2', 'barcode3'];

    // 1. Build a global count of each normalized value across every product/field.
    const globalCounts = new Map<string, number>();
    for (const p of this.products) {
      for (const f of fields) {
        const v = ((p as any)[f] || '').trim().toLowerCase();
        if (v) globalCounts.set(v, (globalCounts.get(v) || 0) + 1);
      }
    }

    // 2. Per product, derive any per-field error message.
    const newMap = new Map<number, { [field: string]: string }>();
    for (const p of this.products) {
      let errs: { [field: string]: string } | null = null;

      for (const f of fields) {
        const raw = ((p as any)[f] || '').trim();
        if (!raw) continue;
        const v = raw.toLowerCase();

        // How many times this value appears within THIS product's own fields.
        const selfCount = fields.filter(o => (((p as any)[o] || '').trim().toLowerCase() === v)).length;

        if (selfCount > 1 && f !== 'sku' && !f.startsWith('barcode')) {
          (errs ||= {})[f] = `'${raw}' is used in another field of same product`;
        } else if (f.startsWith('barcode') && selfCount > 1) {
          const otherBarcodeSelf = ['barcode1', 'barcode2', 'barcode3']
            .filter(o => o !== f && (((p as any)[o] || '').trim().toLowerCase() === v)).length;
          if (otherBarcodeSelf > 0) {
            (errs ||= {})[f] = `'${raw}' is used in another field of same product`;
          } else if ((globalCounts.get(v) || 0) > selfCount) {
            (errs ||= {})[f] = `'${raw}' already exists in another product`;
          }
        } else if ((globalCounts.get(v) || 0) > selfCount) {
          (errs ||= {})[f] = `'${raw}' already exists in another product`;
        }
      }

      if (errs) newMap.set(p.id, errs);
    }

    this.duplicateErrorMap = newMap;
  }

  // Save changes
  async saveChanges(): Promise<void> {
    if (this.modifiedProducts.size === 0) {
      this.swalService.toast('No changes to save', 'info');
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
      this.swalService.toast(`Please fix errors: ${invalidProducts.slice(0, 3).join(', ')}`, 'warning');
      return;
    }

    this.saving = true;
    const modifiedArray = Array.from(this.modifiedProducts.values());
    let successCount = 0;
    let errorCount = 0;

    // Save in small batches so 500+ SKU updates do not freeze the browser.
    const batchSize = 8;
    for (let i = 0; i < modifiedArray.length; i += batchSize) {
      const batch = modifiedArray.slice(i, i + batchSize);
      const results = await Promise.all(batch.map(async (product) => {
        try {
          if (!navigator.onLine) {
            await this.saveEditOffline(product);
          } else {
            await this.saveProductToServer(product);
          }

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
            nameTamil: product.nameTamil,
            sellByWeight: product.sellByWeight
          };
          this.modifiedProducts.delete(product.id);
          return { success: true, product };
        } catch (error) {
          console.error(`Failed to save product ${product.id}:`, error);
          return { success: false, product, error };
        }
      }));
      successCount += results.filter(r => r.success).length;
      errorCount += results.filter(r => !r.success).length;
    }

    this.saving = false;

    if (errorCount === 0) {
      this.swalService.toast(`${successCount} products saved successfully`, 'success');
    } else {
      this.swalService.toast(`Saved ${successCount} products, ${errorCount} failed`, 'warning');
    }

    // Update local cache only - no need to reload from server
    this.updateLocalCache();
  }

  private saveProductToServer(product: BulkEditProduct): Promise<void> {
    return new Promise((resolve, reject) => {
      const updateData = {
        customName: product.customName,
        category: product.category,
        // Backend's ShopProductRequest has no "category" field (only categoryName/categoryId) -
        // sending just "category" was being silently dropped and never persisted.
        categoryName: product.category,
        price: product.price,
        originalPrice: product.originalPrice,
        stockQuantity: product.stockQuantity,
        isAvailable: product.isAvailable,
        status: product.status,
        sku: product.sku,
        barcode1: product.barcode1,
        barcode2: product.barcode2,
        barcode3: product.barcode3,
        nameTamil: product.nameTamil,
        // Backend stores these on masterProduct.tags (used by voice/AI search)
        voiceSearchTags: product.tags,
        // Only sent when toggled, so offline-cached rows (which don't carry
        // baseUnit/baseWeight) can never accidentally clear the flag.
        ...(product.sellByWeight !== product.originalValues.sellByWeight
            ? {
                baseUnit: product.sellByWeight ? 'g' : 'piece',
                baseWeight: product.sellByWeight ? 250 : 0
              }
            : {})
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
        nameTamil: product.nameTamil,
        voiceSearchTags: product.tags,
        category: product.category
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
          barcode3: product.barcode3,
          category: product.category,
          categoryName: product.category
        });
      }
    } catch (error) {
      console.warn('Failed to update local cache:', error);
    }
  }

  // Discard all changes
  async discardChanges(): Promise<void> {
    if (this.modifiedProducts.size === 0) return;

    const result = await this.swalService.confirm(
      'Discard Changes?',
      `Discard all ${this.modifiedProducts.size} unsaved changes?`,
      'Yes, discard',
      'Cancel'
    );
    if (!result.isConfirmed) return;

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
    this.swalService.success('Discarded', 'All changes discarded');
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
    const file = input.files?.[0];
    input.value = ''; // Reset file input
    if (!file) {
      this.uploadingImageFor = null;
      return;
    }
    await this.uploadImageFile(file, product);
  }

  private async uploadImageFile(file: File, product: BulkEditProduct): Promise<void> {
    // Validate file type
    if (!file.type.startsWith('image/')) {
      this.swalService.toast('Please select an image file', 'warning');
      this.uploadingImageFor = null;
      return;
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      this.swalService.toast('Image must be less than 5MB', 'warning');
      this.uploadingImageFor = null;
      return;
    }

    this.uploadingImageFor = product.id;

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
        this.swalService.toast('Image updated successfully', 'success');
      } else {
        // Reload products to get new image
        this.loadProducts(true);
        this.swalService.toast('Image uploaded', 'success');
      }
    } catch (error: any) {
      console.error('Failed to upload image:', error);
      this.swalService.toast(error?.error?.message || 'Failed to upload image', 'error');
    } finally {
      this.uploadingImageFor = null;
    }
  }

  // Paste image copied from another tab (e.g. BigBasket: right-click photo -> Copy image)
  async pasteImageFromClipboard(product: BulkEditProduct): Promise<void> {
    if (!navigator.clipboard?.read) {
      this.swalService.toast('Clipboard paste not supported in this browser', 'warning');
      return;
    }
    try {
      const items = await navigator.clipboard.read();
      for (const item of items) {
        const type = item.types.find(t => t.startsWith('image/'));
        if (type) {
          const blob = await item.getType(type);
          const ext = type.split('/')[1] || 'png';
          const file = new File([blob], `pasted-image.${ext}`, { type });
          if (this.imageSuggestProduct === product) {
            this.closeImageSuggestions();
          }
          await this.uploadImageFile(file, product);
          return;
        }
      }
      this.swalService.toast('No image in clipboard. On BigBasket, right-click the photo and choose "Copy image" first', 'warning');
    } catch (error) {
      console.error('Clipboard read failed:', error);
      this.swalService.toast('Clipboard access blocked. Allow clipboard permission for this site and try again', 'warning');
    }
  }

  onImageDragOver(event: DragEvent): void {
    event.preventDefault();
  }

  async onImageDrop(event: DragEvent, product: BulkEditProduct): Promise<void> {
    event.preventDefault();
    const file = event.dataTransfer?.files?.[0];
    if (file && file.type.startsWith('image/')) {
      await this.uploadImageFile(file, product);
    } else {
      this.swalService.toast('Drop an image file here, or use Copy image + Paste Image for photos from another tab', 'warning');
    }
  }

  isUploadingImage(product: BulkEditProduct): boolean {
    return this.uploadingImageFor === product.id;
  }

  // Strip parentheticals, Tamil text and local price-pack markers like "RS5"
  // that won't match external catalogs
  private cleanProductName(name: string): string {
    return (name || '')
      .replace(/\(.*?\)/g, ' ')
      .replace(/[஀-௿]+/g, ' ')
      .replace(/\bRS\.?\s*\d+\b/gi, ' ')
      .replace(/\b\d+\s*RS\b/gi, ' ')
      .replace(/\b\d+(?:\.\d+)?\s*(?:kg|kgs|g|gm|gms|mg|l|ltr|litre|litres|ml|pcs?|pieces?)\b/gi, ' ')
      .replace(/\b(?:packet|pack|pouch|bottle|box|jar|tin|can)\b/gi, ' ')
      .replace(/[+_]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  // Get BigBasket search URL for product (fallback when no suggestions found)
  getImageSearchUrl(product: BulkEditProduct): string {
    const searchQuery = encodeURIComponent(this.cleanProductName(product.customName) || product.customName);
    return `https://www.bigbasket.com/ps/?q=${searchQuery}`;
  }

  // --- In-screen image suggestions (Google image search via backend) ---
  imageSuggestProduct: BulkEditProduct | null = null;
  imageSuggestions: ImageSuggestion[] = [];
  loadingSuggestions = false;
  suggestError: string | null = null;
  downloadingSuggestionUrl: string | null = null;

  async openImageSuggestions(product: BulkEditProduct): Promise<void> {
    this.imageSuggestProduct = product;
    this.imageSuggestions = [];
    this.suggestError = null;
    this.loadingSuggestions = true;

    const query = this.cleanProductName(product.customName) || product.customName;
    try {
      const response: any = await this.http.get(
        `${this.apiUrl}/shop-products/image-search`,
        { params: { q: query } }
      ).toPromise();
      if (this.imageSuggestProduct === product) {
        this.imageSuggestions = response?.data || [];
      }
    } catch (error: any) {
      console.error('Image search failed:', error);
      if (this.imageSuggestProduct === product) {
        this.suggestError = error?.error?.message || 'Image search failed — try again';
      }
    } finally {
      if (this.imageSuggestProduct === product) {
        this.loadingSuggestions = false;
      }
    }
  }

  async useSuggestedImage(suggestion: ImageSuggestion): Promise<void> {
    const product = this.imageSuggestProduct;
    if (!product) return;
    this.downloadingSuggestionUrl = suggestion.url;
    try {
      const response: any = await this.http.post(
        `${this.apiUrl}/shop-products/${product.id}/image-from-url`,
        { url: suggestion.url }
      ).toPromise();
      const imageUrl = response?.data?.imageUrl || response?.imageUrl;
      if (imageUrl) {
        product.imageUrl = imageUrl;
      } else {
        this.loadProducts(true);
      }
      this.closeImageSuggestions();
      this.swalService.toast('Image updated successfully', 'success');
    } catch (error: any) {
      console.error('Failed to download suggested image:', error);
      this.swalService.toast(error?.error?.message || 'Could not download this image — try another one', 'error');
    } finally {
      this.downloadingSuggestionUrl = null;
    }
  }

  closeImageSuggestions(): void {
    this.imageSuggestProduct = null;
    this.imageSuggestions = [];
    this.suggestError = null;
    this.loadingSuggestions = false;
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

    this.swalService.toast(`Generated ${tags.size} tags`, 'success');
  }

  // Remove image
  async removeImage(product: BulkEditProduct): Promise<void> {
    const result = await this.swalService.confirm('Remove Image?', 'Remove this product image?', 'Yes, remove', 'Cancel');
    if (!result.isConfirmed) return;

    this.uploadingImageFor = product.id;

    try {
      // Call API to remove image
      await this.http.delete(`${this.apiUrl}/shop-products/${product.id}/image`).toPromise();

      // Clear local image URL
      product.imageUrl = '';
      this.swalService.toast('Image removed', 'success');
    } catch (error: any) {
      console.error('Failed to remove image:', error);
      // Even if API fails, clear locally
      product.imageUrl = '';
      this.swalService.toast('Image removed locally', 'success');
    } finally {
      this.uploadingImageFor = null;
    }
  }
}
