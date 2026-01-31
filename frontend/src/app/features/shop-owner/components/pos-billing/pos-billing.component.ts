import { Component, OnInit, OnDestroy, ViewChild, ElementRef } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Subject } from 'rxjs';
import { takeUntil, debounceTime } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { OfflineStorageService, CachedProduct, OfflineEdit } from '../../../../core/services/offline-storage.service';
import { PosSyncService, SyncStatus } from '../../../../core/services/pos-sync.service';
import { AuthService } from '../../../../core/services/auth.service';
import { SwalService } from '../../../../core/services/swal.service';
import { ShopContextService } from '../../services/shop-context.service';
import { getImageUrl } from '../../../../core/utils/image-url.util';

interface CartItem {
  product: CachedProduct;
  quantity: number;
  unitPrice: number;
  mrp: number;  // MRP price
  total: number;
  discount: number;  // Discount per item (mrp - unitPrice)
}

interface LabelConfig {
  showShopName: boolean;
  showTamilName: boolean;
  showEnglishName: boolean;
  showNetQty: boolean;
  showMrp: boolean;
  showPackedDate: boolean;
  showExpiryDate: boolean;
  showBarcode: boolean;
  showBarcodeNumber: boolean;
}

@Component({
  selector: 'app-pos-billing',
  templateUrl: './pos-billing.component.html',
  styleUrls: ['./pos-billing.component.scss']
})
export class PosBillingComponent implements OnInit, OnDestroy {
  @ViewChild('searchInput') searchInput!: ElementRef<HTMLInputElement>;
  @ViewChild('barcodeInput') barcodeInput!: ElementRef<HTMLInputElement>;

  private destroy$ = new Subject<void>();
  private searchSubject = new Subject<string>();

  // Shop info
  shopId: number = 0;
  shopName: string = '';
  shopUpiId: string = '';

  // Products
  products: CachedProduct[] = [];
  filteredProducts: CachedProduct[] = [];
  searchTerm: string = '';
  barcodeBuffer: string = '';

  // POS Mode: 'scanner' = only show searched items, 'browse' = show all products
  posMode: 'scanner' | 'browse' = 'browse';

  // Active Tab: 'quick' = Quick Bill (scan/search + cart only)
  activeTab: 'quick' | 'browse' = 'quick';

  // Temporary price/qty for Quick Bill (not saved to database, just for billing)
  private tempPrices: Map<number, number> = new Map();
  private tempQtys: Map<number, number> = new Map();

  // Barcode debounce to prevent duplicate scans
  private lastScannedBarcode: string = '';
  private lastScanTime: number = 0;

  // Barcode scanner keyboard handler (stored for cleanup)
  private barcodeKeyHandler: ((event: KeyboardEvent) => void) | null = null;

  // Beep cooldown to prevent continuous sound
  private lastBeepTime: number = 0;

  // Cart
  cart: CartItem[] = [];
  subtotal: number = 0;
  taxAmount: number = 0;
  totalAmount: number = 0;
  taxRate: number = 0; // No tax
  totalMrp: number = 0;  // Total MRP of all items
  totalDiscount: number = 0;  // Total discount (MRP - selling price)

  // Payment
  selectedPaymentMethod: string = 'CASH_ON_DELIVERY';
  paymentMethods = [
    { value: 'CASH_ON_DELIVERY', label: 'Cash', icon: 'payments' },
    { value: 'UPI', label: 'UPI', icon: 'qr_code_2' },
    { value: 'CARD', label: 'Card', icon: 'credit_card' }
  ];

  // Customer info (optional)
  customerName: string = '';
  customerPhone: string = '';
  orderNotes: string = '';

  // Sync status
  syncStatus: SyncStatus = {
    isOnline: true,
    pendingOrders: 0,
    pendingEdits: 0,
    pendingProductCreations: 0,
    lastProductSync: null,
    isSyncing: false
  };

  // Cache validity - only sync from server if cache is older than this
  private readonly CACHE_VALIDITY_MS = 5 * 60 * 1000; // 5 minutes
  private readonly POS_CACHE_TIMESTAMP_KEY = 'pos_products_last_sync';

  // UI state
  isLoading: boolean = true;
  showCustomerForm: boolean = false;

  // Language toggle
  showTamil: boolean = false;

  // Receipt language settings (saved to localStorage)
  showEnglishOnReceipt: boolean = true;
  showTamilOnReceipt: boolean = true;

  // Quick Edit state
  editingProduct: CachedProduct | null = null;
  editPrice: number = 0;
  editMrp: number = 0;
  editStock: number = 0;
  editBarcode: string = '';
  editSku: string = '';
  editBarcode1: string = '';
  editBarcode2: string = '';
  editBarcode3: string = '';
  editName: string = '';
  editNameTamil: string = '';
  editImageFile: File | null = null;
  editImagePreview: string = '';
  isSavingEdit: boolean = false;

  // Label Print state
  labelQuantity: number = 1;
  showLabelConfigDialog: boolean = false;
  labelConfig: LabelConfig = {
    showShopName: true,
    showTamilName: true,
    showEnglishName: true,
    showNetQty: true,
    showMrp: true,
    showPackedDate: true,
    showExpiryDate: true,
    showBarcode: true,
    showBarcodeNumber: true
  };
  labelPackedDate: string = '';
  labelExpiryDate: string = '';
  labelNetQty: string = '';

  // Quick Add Custom Product state
  showQuickAddDialog: boolean = false;
  customProductName: string = '';
  customProductPrice: number = 0;
  customProductMrp: number = 0;
  customProductQty: number = 1;
  private customProductIdCounter: number = -1; // Negative IDs for custom products

  // Add New Product (offline capable) state
  showAddProductDialog: boolean = false;
  newProductName: string = '';
  newProductNameTamil: string = '';
  newProductPrice: number = 0;
  newProductMrp: number = 0;
  newProductCostPrice: number = 0;
  newProductStock: number = 0;
  newProductBarcode1: string = '';
  newProductBarcode2: string = '';
  newProductBarcode3: string = '';
  newProductTrackInventory: boolean = true;
  isSavingNewProduct: boolean = false;

  private apiUrl = environment.apiUrl;

  constructor(
    private http: HttpClient,
    private offlineStorage: OfflineStorageService,
    private syncService: PosSyncService,
    private authService: AuthService,
    private swal: SwalService,
    private shopContext: ShopContextService
  ) {}

  ngOnInit(): void {
    this.loadShopInfo();
    this.loadLanguagePreference();
    this.loadLabelConfig();
    this.loadReceiptLanguageSettings();
    this.initSyncStatus();
    this.initSearch();
    this.initBarcodeScanner();
    this.loadProducts();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();

    // Remove barcode scanner keyboard listener to prevent memory leaks and duplicate handlers
    if (this.barcodeKeyHandler) {
      document.removeEventListener('keypress', this.barcodeKeyHandler);
      this.barcodeKeyHandler = null;
    }
  }

  /**
   * Load shop info from ShopContextService
   */
  private loadShopInfo(): void {
    // Subscribe to shop context to get shop info
    this.shopContext.shop$
      .pipe(takeUntil(this.destroy$))
      .subscribe(shop => {
        if (shop) {
          this.shopId = shop.id;
          this.shopName = shop.name || shop.businessName || 'My Shop';
          this.shopUpiId = shop.upiId || '';
          // Save shop info to localStorage for offline use
          localStorage.setItem('shop_name', this.shopName);
          if (this.shopUpiId) {
            localStorage.setItem('shop_upi_id', this.shopUpiId);
          }
          console.log('POS Billing - Shop loaded:', this.shopId, this.shopName);
        }
      });

    // Also try immediate value from context
    const currentShop = this.shopContext.getCurrentShop();
    if (currentShop) {
      this.shopId = currentShop.id;
      this.shopName = currentShop.name || currentShop.businessName || 'My Shop';
      this.shopUpiId = currentShop.upiId || '';
      // Save shop info to localStorage for offline use
      localStorage.setItem('shop_name', this.shopName);
      if (this.shopUpiId) {
        localStorage.setItem('shop_upi_id', this.shopUpiId);
      }
    } else {
      // Fallback to localStorage
      const storedShopId = localStorage.getItem('current_shop_id');
      if (storedShopId) {
        this.shopId = parseInt(storedShopId, 10);
      }
      // Try to get shop name from localStorage
      const storedShopName = localStorage.getItem('shop_name');
      if (storedShopName) {
        this.shopName = storedShopName;
      }
      // Try to get UPI ID from localStorage
      const storedUpiId = localStorage.getItem('shop_upi_id');
      if (storedUpiId) {
        this.shopUpiId = storedUpiId;
      }
    }

    console.log('POS Billing - shopId:', this.shopId, 'shopName:', this.shopName);
  }

  /**
   * Load language preference from localStorage
   */
  private loadLanguagePreference(): void {
    const saved = localStorage.getItem('pos_language');
    this.showTamil = saved === 'tamil';
  }

  /**
   * Load label configuration from localStorage
   */
  private loadLabelConfig(): void {
    const saved = localStorage.getItem('pos_label_config');
    if (saved) {
      try {
        this.labelConfig = { ...this.labelConfig, ...JSON.parse(saved) };
      } catch (e) {
        console.warn('Failed to parse saved label config:', e);
      }
    }
  }

  /**
   * Save label configuration to localStorage
   */
  saveLabelConfig(): void {
    localStorage.setItem('pos_label_config', JSON.stringify(this.labelConfig));
  }

  /**
   * Load receipt language settings from localStorage
   */
  private loadReceiptLanguageSettings(): void {
    const saved = localStorage.getItem('pos_receipt_language');
    if (saved) {
      try {
        const settings = JSON.parse(saved);
        this.showEnglishOnReceipt = settings.english !== false;
        this.showTamilOnReceipt = settings.tamil !== false;
      } catch (e) {
        console.warn('Failed to parse saved receipt language settings:', e);
      }
    }
  }

  /**
   * Toggle English name on receipt
   */
  toggleEnglishOnReceipt(): void {
    // Don't allow turning off both
    if (this.showEnglishOnReceipt && !this.showTamilOnReceipt) {
      return;
    }
    this.showEnglishOnReceipt = !this.showEnglishOnReceipt;
    this.saveReceiptLanguageSettings();
  }

  /**
   * Toggle Tamil name on receipt
   */
  toggleTamilOnReceipt(): void {
    // Don't allow turning off both
    if (this.showTamilOnReceipt && !this.showEnglishOnReceipt) {
      return;
    }
    this.showTamilOnReceipt = !this.showTamilOnReceipt;
    this.saveReceiptLanguageSettings();
  }

  /**
   * Save receipt language settings to localStorage
   */
  private saveReceiptLanguageSettings(): void {
    localStorage.setItem('pos_receipt_language', JSON.stringify({
      english: this.showEnglishOnReceipt,
      tamil: this.showTamilOnReceipt
    }));
    this.showLabelConfigDialog = false;
    this.swal.success('Saved', 'Label settings saved');
  }

  /**
   * Toggle between Tamil and English display
   */
  toggleLanguage(): void {
    this.showTamil = !this.showTamil;
    localStorage.setItem('pos_language', this.showTamil ? 'tamil' : 'english');
  }

  /**
   * Get product display name based on language setting
   */
  getProductName(product: CachedProduct): string {
    if (!product) return 'Unknown Product';
    if (this.showTamil && product.nameTamil) {
      return product.nameTamil;
    }
    // Try multiple name fields with fallback
    return product.name || (product as any).customName || 'Loading...';
  }

  /**
   * Get displayable barcode/SKU for product card.
   * Hides auto-generated CUSTOM- SKUs since they are not meaningful to the user.
   */
  getDisplayBarcode(product: CachedProduct): string {
    if (product.barcode1) return product.barcode1;
    if (product.barcode) return product.barcode;
    if (product.sku && !product.sku.startsWith('CUSTOM-')) return product.sku;
    return '';
  }

  /**
   * Handle image load error
   */
  onImageError(event: Event): void {
    const target = event.target as HTMLImageElement;
    if (target) {
      target.style.display = 'none';
    }
  }

  /**
   * TrackBy function for ngFor to optimize rendering
   */
  trackByProductId(index: number, product: CachedProduct): number {
    return product.id;
  }

  /**
   * Get full image URL
   */
  getImageUrl(path: string | undefined): string {
    return getImageUrl(path || '');
  }

  /**
   * Initialize sync status listener
   */
  private initSyncStatus(): void {
    this.syncService.getSyncStatus()
      .pipe(takeUntil(this.destroy$))
      .subscribe(status => {
        this.syncStatus = status;
      });
  }

  /**
   * Initialize search with debounce
   */
  private initSearch(): void {
    this.searchSubject
      .pipe(
        takeUntil(this.destroy$),
        debounceTime(300)
      )
      .subscribe(term => {
        this.filterProducts(term);
      });
  }

  /**
   * Initialize barcode scanner (keyboard input)
   * Only triggers for very fast input (barcode scanners type ~10ms between chars)
   */
  private initBarcodeScanner(): void {
    let lastKeyTime = 0;
    let buffer = '';

    // Store the handler reference so we can remove it on destroy
    this.barcodeKeyHandler = (event: KeyboardEvent) => {
      // Ignore if typing in an input field (search box, barcode input, etc.)
      const target = event.target as HTMLElement;
      if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') {
        return;
      }

      const currentTime = Date.now();

      // If typing very fast (< 30ms between keys), it's likely a scanner
      // Human typing is typically > 50ms between keys
      if (currentTime - lastKeyTime < 30) {
        buffer += event.key;
      } else {
        // Reset buffer if there's a pause
        buffer = event.key;
      }

      lastKeyTime = currentTime;

      // Enter key completes the barcode (need at least 5 chars for valid barcode)
      if (event.key === 'Enter' && buffer.length > 5) {
        event.preventDefault();
        const barcode = buffer.slice(0, -1); // Remove Enter
        this.handleBarcodeScan(barcode);
        buffer = '';
      }
    };

    document.addEventListener('keypress', this.barcodeKeyHandler);
  }

  /**
   * Load products - first from local cache, then sync from server
   */
  async loadProducts(): Promise<void> {
    this.isLoading = true;
    console.log('Loading products for POS...');

    try {
      // Try to load from local cache first (instant) with timeout
      const cachePromise = this.offlineStorage.getProducts();
      const timeoutPromise = new Promise<CachedProduct[]>((_, reject) =>
        setTimeout(() => reject(new Error('Cache timeout')), 3000)
      );

      let cachedProducts = await Promise.race([cachePromise, timeoutPromise]);

      // Filter cached products by current shop ID to prevent cross-shop mixing
      if (this.shopId) {
        cachedProducts = cachedProducts.filter(p => !p.shopId || p.shopId === this.shopId);
      }

      // Also load pending offline-created products and merge them
      // Only add if not already in the cached products (to avoid duplicates)
      try {
        const allPendingCreations = await this.offlineStorage.getPendingProductCreations();
        // Filter by current shop ID to prevent cross-shop product leaking
        const pendingCreations = this.shopId
          ? allPendingCreations.filter(c => c.shopId === this.shopId)
          : allPendingCreations;
        if (pendingCreations.length > 0) {
          console.log(`Found ${pendingCreations.length} pending offline products for shop ${this.shopId}`);
          // Filter out creations that are already in the cache (by matching name + barcode)
          const newCreations = pendingCreations.filter(creation => {
            const creationName = (creation.name || creation.customName || '').toLowerCase();
            const creationBarcode = (creation.barcode1 || '').toLowerCase();
            return !cachedProducts.some(p => {
              const nameMatch = p.name.toLowerCase() === creationName;
              const barcodeMatch = creationBarcode && p.barcode1 && p.barcode1.toLowerCase() === creationBarcode;
              return nameMatch || barcodeMatch;
            });
          });
          if (newCreations.length > 0) {
            const offlineProducts: CachedProduct[] = newCreations.map(creation => ({
              id: this.offlineStorage.generateTempProductId(),
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
            console.log(`Added ${newCreations.length} new offline products (skipped ${pendingCreations.length - newCreations.length} already in cache)`);
          }
        }
      } catch (err) {
        console.warn('Failed to load pending offline products:', err);
      }

      if (cachedProducts.length > 0) {
        // Filter out inactive products - only show active/available products in POS
        // Check both isAvailable flag and status field
        this.products = cachedProducts.filter(p =>
          p.isAvailable !== false &&
          (p as any).status !== 'INACTIVE'
        );
        this.filteredProducts = this.sortProductsWithCartFirst(this.products);
        console.log(`Loaded ${this.products.length} active products from cache (filtered from ${cachedProducts.length} total)`);

        // Extract shopId from cached products if not set
        if ((!this.shopId || this.shopId === 0) && cachedProducts.length > 0) {
          const firstProductWithShopId = cachedProducts.find(p => p.shopId);
          if (firstProductWithShopId && firstProductWithShopId.shopId) {
            this.shopId = firstProductWithShopId.shopId;
            localStorage.setItem('current_shop_id', String(this.shopId));
            console.log('POS: Extracted shopId from cached products:', this.shopId);
          }
        }

        this.isLoading = false;

        // Cache product images to IndexedDB for offline use
        this.cacheProductImagesToIndexedDB(this.products);

        // Only sync from server if cache is stale (older than 5 minutes)
        if (navigator.onLine) {
          const lastSync = localStorage.getItem(this.POS_CACHE_TIMESTAMP_KEY);
          const lastSyncTime = lastSync ? parseInt(lastSync, 10) : 0;
          const cacheAge = Date.now() - lastSyncTime;

          if (cacheAge > this.CACHE_VALIDITY_MS) {
            console.log(`POS cache is stale (age: ${Math.round(cacheAge / 1000)}s), syncing from server...`);
            this.syncProductsInBackground();
          } else {
            console.log(`POS using cached data (age: ${Math.round(cacheAge / 1000)}s, max: ${this.CACHE_VALIDITY_MS / 1000}s)`);
          }
        }
        return;
      }
    } catch (error) {
      console.warn('Failed to load from cache, loading from server:', error);
    }

    // No cache or cache failed - load from server
    this.loadProductsFromServer();
  }

  /**
   * Load products from server
   */
  private loadProductsFromServer(): void {
    this.http.get<any>(`${this.apiUrl}/shop-products/my-products?page=0&size=100000`)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: async (response) => {
          let rawProducts: any[] = [];

          if (response?.data?.content) {
            rawProducts = response.data.content;
          } else if (response?.data && Array.isArray(response.data)) {
            rawProducts = response.data;
          }

          // Extract shopId from first product if not set
          if (rawProducts.length > 0 && (!this.shopId || this.shopId === 0)) {
            const firstProduct = rawProducts[0];
            if (firstProduct.shopId) {
              this.shopId = firstProduct.shopId;
              localStorage.setItem('current_shop_id', String(this.shopId));
              console.log('POS: Extracted shopId from products:', this.shopId);
            }
          }

          // Map to CachedProduct format and filter out inactive products
          const allProducts = rawProducts.map((p: any) => this.mapProduct(p));
          // Filter out inactive - check both isAvailable and status
          this.products = allProducts.filter(p =>
            p.isAvailable !== false &&
            (p as any).status !== 'INACTIVE'
          );
          this.filteredProducts = this.sortProductsWithCartFirst(this.products);
          this.isLoading = false;
          console.log(`Loaded ${this.products.length} active products (filtered from ${allProducts.length} total)`);

          // Save ALL products to local cache (including inactive) for My Products page
          await this.offlineStorage.saveProducts(allProducts, this.shopId);
          // Save sync timestamp
          localStorage.setItem(this.POS_CACHE_TIMESTAMP_KEY, Date.now().toString());
          console.log(`Loaded and cached ${this.products.length} products`);

          // Cache images in background (non-blocking) - don't await
          this.cacheProductImages().then(() => {
            console.log('Background image caching complete');
          }).catch(err => console.warn('Image caching error:', err));
        },
        error: (error) => {
          console.error('Failed to load products:', error);
          this.swal.error('Error', 'Failed to load products');
          this.isLoading = false;
        }
      });
  }

  /**
   * Cache product images as base64 for offline use
   */
  private async cacheProductImages(): Promise<void> {
    const imagePromises = this.products.map(async (product, index) => {
      if (product.image && !product.imageBase64) {
        try {
          const imageUrl = this.getImageUrl(product.image);
          const base64 = await this.fetchImageAsBase64(imageUrl);
          if (base64) {
            this.products[index].imageBase64 = base64;
          }
        } catch (error) {
          // Silently fail for individual images
          console.warn(`Failed to cache image for product ${product.id}`);
        }
      }
    });

    // Process in batches of 10 to avoid overwhelming the browser
    const batchSize = 10;
    for (let i = 0; i < imagePromises.length; i += batchSize) {
      await Promise.all(imagePromises.slice(i, i + batchSize));
    }
  }

  /**
   * Fetch image and convert to base64
   */
  private fetchImageAsBase64(url: string): Promise<string | null> {
    return new Promise((resolve) => {
      const img = new Image();
      img.crossOrigin = 'Anonymous';

      img.onload = () => {
        try {
          const canvas = document.createElement('canvas');
          canvas.width = img.width;
          canvas.height = img.height;

          const ctx = canvas.getContext('2d');
          if (ctx) {
            ctx.drawImage(img, 0, 0);
            // Use lower quality for smaller storage
            const base64 = canvas.toDataURL('image/jpeg', 0.6);
            resolve(base64);
          } else {
            resolve(null);
          }
        } catch (e) {
          resolve(null);
        }
      };

      img.onerror = () => resolve(null);

      // Set timeout for slow images
      setTimeout(() => resolve(null), 5000);

      img.src = url;
    });
  }

  /**
   * Sync products in background
   */
  private syncProductsInBackground(): void {
    this.http.get<any>(`${this.apiUrl}/shop-products/my-products?page=0&size=100000`)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: async (response) => {
          let rawProducts: any[] = [];

          if (response?.data?.content) {
            rawProducts = response.data.content;
          } else if (response?.data && Array.isArray(response.data)) {
            rawProducts = response.data;
          }

          const allProducts = rawProducts.map((p: any) => this.mapProduct(p));
          // Filter out inactive - check both isAvailable and status
          const activeProducts = allProducts.filter(p =>
            p.isAvailable !== false &&
            (p as any).status !== 'INACTIVE'
          );

          // Update cache with ALL products (including inactive) for My Products page
          await this.offlineStorage.saveProducts(allProducts, this.shopId);

          // Save sync timestamp
          localStorage.setItem(this.POS_CACHE_TIMESTAMP_KEY, Date.now().toString());

          // Update UI with only active products
          if (activeProducts.length !== this.products.length) {
            this.products = activeProducts;
            this.filteredProducts = this.sortProductsWithCartFirst(this.products);
          }

          console.log(`Background sync complete: ${activeProducts.length} active products (${allProducts.length} total)`);
        },
        error: (error) => {
          console.warn('Background sync failed:', error);
        }
      });
  }

  /**
   * Cache product images to IndexedDB in background for offline use
   * Caches images as blobs, doesn't block UI
   */
  private cacheProductImagesToIndexedDB(products: CachedProduct[]): void {
    if (!navigator.onLine) return;

    // Get unique image URLs from products
    const imageUrls = products
      .filter(p => p.image || p.imageUrl)
      .map(p => getImageUrl(p.image || p.imageUrl || ''))
      .filter(url => url && url.length > 0);

    if (imageUrls.length === 0) return;

    console.log(`Caching ${imageUrls.length} product images to IndexedDB...`);

    // Cache images in batches of 10 to avoid overwhelming the network
    const batchSize = 10;
    let cached = 0;

    const cacheBatch = async (startIndex: number) => {
      const batch = imageUrls.slice(startIndex, startIndex + batchSize);
      if (batch.length === 0) {
        console.log(`Image caching complete: ${cached}/${imageUrls.length} cached`);
        return;
      }

      await Promise.all(batch.map(async (url) => {
        try {
          const isCached = await this.offlineStorage.isImageCached(url);
          if (!isCached) {
            const response = await fetch(url, { mode: 'cors', credentials: 'omit' });
            if (response.ok) {
              const blob = await response.blob();
              await this.offlineStorage.cacheImage(url, blob);
              cached++;
            }
          } else {
            cached++;
          }
        } catch (err) {
          // Silently ignore failed images
        }
      }));

      // Cache next batch after a small delay
      setTimeout(() => cacheBatch(startIndex + batchSize), 100);
    };

    // Start caching in background
    cacheBatch(0);
  }

  /**
   * Map API product to CachedProduct format
   */
  private mapProduct(p: any): CachedProduct {
    return {
      id: p.id,
      shopId: p.shopId,
      name: p.displayName || p.customName || p.name || 'Unknown',
      nameTamil: p.nameTamil || p.displayNameTamil || '',
      price: p.price || 0,
      originalPrice: p.originalPrice || p.mrp || p.price || 0,  // MRP for discount calculation
      stock: p.stockQuantity || 0,
      trackInventory: p.trackInventory ?? true,
      isAvailable: p.isAvailable !== false && p.status !== 'INACTIVE',  // Active check
      sku: p.sku || p.masterProduct?.sku || '',
      barcode: p.barcode || p.masterProduct?.barcode || '',
      barcode1: p.barcode1 || '',
      barcode2: p.barcode2 || '',
      barcode3: p.barcode3 || '',
      image: p.primaryImageUrl || '',
      categoryId: p.categoryId || p.masterProduct?.category?.id,
      categoryName: p.categoryName || p.masterProduct?.category?.name || '',
      tags: p.tags || p.masterProduct?.tags || []
    };
  }

  /**
   * Handle search input
   */
  onSearchChange(): void {
    this.searchSubject.next(this.searchTerm);
  }

  /**
   * Add the first search result to cart (on Enter key in Quick Bill tab)
   */
  addFirstSearchResult(): void {
    if (this.filteredProducts.length > 0) {
      this.addToCart(this.filteredProducts[0]);
      this.searchTerm = '';
      this.onSearchChange();
    }
  }

  /**
   * Handle Enter key in Quick Bill search - if exact barcode match, auto-add to cart
   */
  onQuickSearchEnter(): void {
    if (!this.searchTerm.trim()) return;

    // Check for exact barcode/SKU match
    const exactMatch = this.products.find(p =>
      p.barcode === this.searchTerm ||
      p.barcode1 === this.searchTerm ||
      p.barcode2 === this.searchTerm ||
      p.barcode3 === this.searchTerm ||
      p.sku === this.searchTerm
    );

    if (exactMatch) {
      // Exact barcode match - add to cart and clear
      this.addToCart(exactMatch);
      this.playBeep(true);
      this.searchTerm = '';
      this.filterProducts(''); // Direct filter - no debounce delay
    }
    // If no exact match, just keep showing filtered results
  }

  // ========== Temp Price/Qty Methods for Quick Bill (not saved to DB) ==========

  /**
   * Get temporary price for a product (defaults to cart price if in cart, else product's actual price)
   */
  getTempPrice(product: CachedProduct): number {
    // If temp price is set, use it
    if (this.tempPrices.has(product.id)) {
      return this.tempPrices.get(product.id)!;
    }
    // If product is in cart, use the cart item's unitPrice
    const cartItem = this.cart.find(item => item.product.id === product.id);
    if (cartItem) {
      return cartItem.unitPrice;
    }
    // Otherwise use product's price
    return product.price;
  }

  /**
   * Set temporary price for a product (billing only, not saved)
   */
  setTempPrice(product: CachedProduct, event: Event): void {
    const input = event.target as HTMLInputElement;
    const price = parseFloat(input.value) || 0;
    this.tempPrices.set(product.id, price);
  }

  /**
   * Get temporary quantity for a product (defaults to cart qty if in cart, else 1)
   */
  getTempQty(product: CachedProduct): number {
    if (this.tempQtys.has(product.id)) {
      return this.tempQtys.get(product.id)!;
    }
    // If product is in cart, show cart quantity
    const cartQty = this.getCartQuantity(product);
    return cartQty > 0 ? cartQty : 1;
  }

  /**
   * Increment temporary quantity
   */
  incrementTempQty(product: CachedProduct): void {
    const current = this.getTempQty(product);
    this.tempQtys.set(product.id, current + 1);
  }

  /**
   * Decrement temporary quantity
   */
  decrementTempQty(product: CachedProduct): void {
    const current = this.getTempQty(product);
    if (current > 0) {
      this.tempQtys.set(product.id, current - 1);
    }
  }

  /**
   * Add to cart with temporary price and quantity (Quick Bill mode)
   */
  addToCartWithTempValues(product: CachedProduct): void {
    const tempPrice = this.getTempPrice(product);
    const tempQty = this.getTempQty(product);

    if (tempQty <= 0) return;

    // Create a modified product with the temporary price
    const modifiedProduct = { ...product, price: tempPrice };

    // Add to cart with the specified quantity
    for (let i = 0; i < tempQty; i++) {
      this.addToCart(modifiedProduct);
    }

    // Reset temp qty after adding
    this.tempQtys.set(product.id, 1);
  }

  /**
   * Filter products by search term
   */
  private filterProducts(term: string): void {
    // In scanner mode, show empty list when no search term
    if (!term || term.length < 2) {
      if (this.posMode === 'scanner') {
        this.filteredProducts = [];
      } else {
        this.filteredProducts = this.sortProductsWithCartFirst(this.products);
      }
      return;
    }

    const lowerTerm = term.toLowerCase();

    // Fast path: exact barcode match (most common for scanner)
    if (term.length >= 5 && /^\d+$/.test(term)) {
      const exactMatch = this.products.find(p =>
        p.barcode === term || p.barcode1 === term || p.barcode2 === term || p.barcode3 === term
      );
      if (exactMatch) {
        this.filteredProducts = [exactMatch];
        return;
      }
    }

    // Regular search with limit for performance
    const filtered: CachedProduct[] = [];
    for (const p of this.products) {
      if (filtered.length >= 50) break; // Limit results for performance

      if (p.name.toLowerCase().includes(lowerTerm) ||
          (p.nameTamil && p.nameTamil.toLowerCase().includes(lowerTerm)) ||
          (p.sku && p.sku.toLowerCase().includes(lowerTerm)) ||
          (p.barcode && p.barcode.includes(term)) ||
          (p.barcode1 && p.barcode1.includes(term)) ||
          (p.barcode2 && p.barcode2.includes(term)) ||
          (p.barcode3 && p.barcode3.includes(term))) {
        filtered.push(p);
      }
    }
    this.filteredProducts = this.sortProductsWithCartFirst(filtered);
  }

  // Switch POS mode and refresh display
  onPosModeChange(): void {
    this.filterProducts(this.searchTerm);
  }

  /**
   * Handle barcode scan
   */
  handleBarcodeScan(barcode: string): void {
    const now = Date.now();

    // Prevent duplicate scans - ignore if same barcode within 500ms
    if (barcode === this.lastScannedBarcode && (now - this.lastScanTime) < 500) {
      console.log('Ignoring duplicate barcode scan:', barcode);
      return;
    }

    this.lastScannedBarcode = barcode;
    this.lastScanTime = now;

    console.log('Barcode scanned:', barcode);

    // Find in loaded products by barcode, barcode1, barcode2, barcode3, or SKU
    const product = this.products.find(p =>
      p.barcode === barcode ||
      p.barcode1 === barcode ||
      p.barcode2 === barcode ||
      p.barcode3 === barcode ||
      p.sku === barcode
    );

    if (product) {
      // In Quick Bill mode: show product card (so user can edit price/qty before adding)
      // In Browse mode: auto-add to cart
      if (this.activeTab === 'quick') {
        // Put barcode in search and filter immediately (bypass debounce for instant response)
        this.searchTerm = barcode;
        this.filterProducts(barcode); // Direct filter - no debounce delay
        this.playBeep(true);
      } else {
        // Browse mode - auto add to cart
        this.addToCart(product);
        this.playBeep(true);
      }
    } else {
      this.swal.error('Not Found', `Product with barcode "${barcode}" not found`, 2000);
      this.playBeep(false);
    }
  }

  /**
   * Manual barcode input - same fast approach as Quick Bill
   */
  onBarcodeSubmit(): void {
    const barcode = this.barcodeBuffer.trim();
    if (!barcode) return;

    // Find exact barcode match (same as Quick Bill)
    const exactMatch = this.products.find(p =>
      p.barcode === barcode ||
      p.barcode1 === barcode ||
      p.barcode2 === barcode ||
      p.barcode3 === barcode ||
      p.sku === barcode
    );

    if (exactMatch) {
      this.addToCart(exactMatch);
      this.playBeep(true);
    } else {
      this.swal.error('Not Found', `Product with barcode "${barcode}" not found`, 2000);
      this.playBeep(false);
    }

    this.barcodeBuffer = '';
  }

  /**
   * Add product to cart
   */
  addToCart(product: CachedProduct): void {
    // Check stock
    if (product.trackInventory && product.stock <= 0) {
      this.swal.error('Out of Stock', `${product.name} is out of stock`);
      return;
    }

    // Check if already in cart
    const existingItem = this.cart.find(item => item.product.id === product.id);

    const mrp = product.originalPrice || product.price;
    const discount = mrp - product.price;

    if (existingItem) {
      // Check stock before increasing
      if (product.trackInventory && existingItem.quantity >= product.stock) {
        this.swal.warning('Stock Limit', `Only ${product.stock} available`);
        return;
      }
      existingItem.quantity++;
      // Update price if different (for temp price changes in Quick Bill mode)
      if (existingItem.unitPrice !== product.price) {
        existingItem.unitPrice = product.price;
        existingItem.mrp = mrp;
        existingItem.discount = discount;
      }
      existingItem.total = existingItem.quantity * existingItem.unitPrice;
    } else {
      // Add new items at top of cart list
      this.cart.unshift({
        product,
        quantity: 1,
        unitPrice: product.price,
        mrp: mrp,
        total: product.price,
        discount: discount
      });
    }

    this.calculateTotals();

    // In Quick Bill mode, clear search to show empty state (user scans next item)
    // In Browse mode, keep showing all products sorted with cart items first
    if (this.activeTab === 'quick') {
      this.searchTerm = '';
      this.filteredProducts = [];
    } else {
      this.searchTerm = '';
      this.filteredProducts = this.sortProductsWithCartFirst(this.products);
    }
  }

  /**
   * Check if product is in cart
   */
  isInCart(product: CachedProduct): boolean {
    return this.cart.some(item => item.product.id === product.id);
  }

  /**
   * Get quantity of product in cart
   */
  getCartQuantity(product: CachedProduct): number {
    const item = this.cart.find(item => item.product.id === product.id);
    return item ? item.quantity : 0;
  }

  /**
   * Get products that are currently in the cart (for Quick Bill display)
   */
  getCartProducts(): CachedProduct[] {
    return this.cart.map(item => item.product);
  }

  /**
   * Get the price of a product in the cart
   */
  getCartItemPrice(product: CachedProduct): number {
    const item = this.cart.find(item => item.product.id === product.id);
    return item ? item.unitPrice : product.price;
  }

  /**
   * Get the MRP of a product in the cart
   */
  getCartItemMrp(product: CachedProduct): number {
    const item = this.cart.find(item => item.product.id === product.id);
    return item ? item.mrp : (product.mrp || product.price);
  }

  /**
   * Check if cart item price exceeds MRP
   */
  isPriceAboveMrp(product: CachedProduct): boolean {
    const item = this.cart.find(item => item.product.id === product.id);
    if (item) {
      return item.unitPrice > item.mrp;
    }
    return false;
  }

  /**
   * Update cart quantity directly by product (for cart products display)
   */
  updateCartQuantityByProduct(product: CachedProduct, delta: number): void {
    const item = this.cart.find(item => item.product.id === product.id);
    if (item) {
      this.updateQuantity(item, delta);
    }
  }

  /**
   * Update cart item price (for this bill only, not saved to product)
   */
  updateCartItemPrice(product: CachedProduct, event: Event): void {
    const input = event.target as HTMLInputElement;
    const newPrice = parseFloat(input.value) || 0;
    const item = this.cart.find(item => item.product.id === product.id);
    if (item && newPrice >= 0) {
      item.unitPrice = newPrice;
      item.total = item.unitPrice * item.quantity;
      // Recalculate discount based on new price
      item.discount = item.mrp - item.unitPrice;
      if (item.discount < 0) item.discount = 0;
      this.calculateTotals();
    }
  }

  /**
   * Sort products to show cart items first
   */
  private sortProductsWithCartFirst(products: CachedProduct[]): CachedProduct[] {
    // Use Set for O(1) lookup instead of O(n) find in loop
    const cartProductIds = new Set(this.cart.map(item => item.product.id));

    if (cartProductIds.size === 0) {
      return products; // No sorting needed if cart is empty
    }

    return [...products].sort((a, b) => {
      const aInCart = cartProductIds.has(a.id);
      const bInCart = cartProductIds.has(b.id);
      if (aInCart && !bInCart) return -1;
      if (!aInCart && bInCart) return 1;
      return 0;
    });
  }

  /**
   * Update item quantity
   */
  updateQuantity(item: CartItem, delta: number): void {
    const newQty = item.quantity + delta;

    if (newQty <= 0) {
      this.removeFromCart(item);
      return;
    }

    if (item.product.trackInventory && newQty > item.product.stock) {
      this.swal.warning('Stock Limit', `Only ${item.product.stock} available`);
      return;
    }

    item.quantity = newQty;
    item.total = item.quantity * item.unitPrice;
    this.calculateTotals();
  }

  /**
   * Remove item from cart
   */
  removeFromCart(item: CartItem): void {
    const index = this.cart.indexOf(item);
    if (index > -1) {
      this.cart.splice(index, 1);
      this.calculateTotals();
      // In Quick Bill mode, keep products list empty (user scans next item)
      // In Browse mode, re-sort to reflect cart changes
      if (this.activeTab !== 'quick') {
        this.filteredProducts = this.sortProductsWithCartFirst(this.products);
      }
    }
  }

  /**
   * Remove product from cart (by product reference)
   */
  removeProductFromCart(product: CachedProduct): void {
    const cartItem = this.cart.find(item => item.product.id === product.id);
    if (cartItem) {
      this.removeFromCart(cartItem);
    }
  }

  /**
   * Clear entire cart
   */
  clearCart(): void {
    if (this.cart.length === 0) return;

    this.swal.confirm('Clear Cart', 'Remove all items from cart?', 'Yes, Clear', 'Cancel')
      .then(result => {
        if (result.isConfirmed) {
          this.cart = [];
          this.calculateTotals();
          this.customerName = '';
          this.customerPhone = '';
          this.orderNotes = '';
          // In Quick Bill mode, keep products list empty
          // In Browse mode, show all products
          if (this.activeTab !== 'quick') {
            this.filteredProducts = this.sortProductsWithCartFirst(this.products);
          } else {
            this.filteredProducts = [];
          }
        }
      });
  }

  /**
   * Calculate totals
   */
  private calculateTotals(): void {
    this.subtotal = this.cart.reduce((sum, item) => sum + item.total, 0);
    this.totalMrp = this.cart.reduce((sum, item) => sum + (item.mrp * item.quantity), 0);
    this.totalDiscount = this.totalMrp - this.subtotal;
    // Ensure discount is never negative (when price > MRP)
    if (this.totalDiscount < 0) this.totalDiscount = 0;
    this.taxAmount = this.subtotal * this.taxRate;
    this.totalAmount = this.subtotal + this.taxAmount;
  }

  /**
   * Generate bill
   */
  async generateBill(): Promise<void> {
    if (this.cart.length === 0) {
      this.swal.warning('Empty Cart', 'Please add items to generate bill');
      return;
    }

    // Ensure shopId is set
    if (!this.shopId || this.shopId === 0) {
      console.log('POS: shopId not set, attempting to retrieve...');

      // Try to get from shop context again
      const currentShop = this.shopContext.getCurrentShop();
      if (currentShop) {
        this.shopId = currentShop.id;
        console.log('POS: Got shopId from shop context:', this.shopId);
      } else {
        // Try localStorage as last resort
        const storedShopId = localStorage.getItem('current_shop_id');
        if (storedShopId) {
          this.shopId = parseInt(storedShopId, 10);
          console.log('POS: Got shopId from localStorage:', this.shopId);
        }
      }

      // Try to get from products if still not set
      if ((!this.shopId || this.shopId === 0) && this.products.length > 0) {
        const productWithShopId = this.products.find(p => p.shopId);
        if (productWithShopId && productWithShopId.shopId) {
          this.shopId = productWithShopId.shopId;
          localStorage.setItem('current_shop_id', String(this.shopId));
          console.log('POS: Got shopId from products:', this.shopId);
        }
      }

      // If still no shopId, show error
      if (!this.shopId || this.shopId === 0) {
        console.error('POS: Failed to get shopId from any source');
        this.swal.error('Error', 'Shop not loaded. Please refresh the page.');
        return;
      }
    }

    console.log('Creating POS order for shopId:', this.shopId);
    this.swal.loading('Creating bill...');

    try {
      const orderData = {
        items: this.cart.map(item => ({
          shopProductId: item.product.id,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          productName: item.product.name
        })),
        paymentMethod: this.selectedPaymentMethod,
        customerName: this.customerName || undefined,
        customerPhone: this.customerPhone || undefined,
        notes: this.orderNotes || undefined,
        subtotal: this.subtotal,
        taxAmount: this.taxAmount,
        totalAmount: this.totalAmount
      };

      const result = await this.syncService.createPosOrder(orderData, this.shopId, this.shopName);

      this.swal.close();

      if (result.success) {
        const offlineMsg = result.offline ? ' (Saved offline)' : '';

        // Use toast notification instead of modal (doesn't block print)
        this.swal.toast(
          `Bill Created - ₹${this.totalAmount.toFixed(0)}${offlineMsg}`,
          'success'
        );

        // Print receipt
        this.printReceipt(result.order);

        // Update local stock immediately (no need to reload all products)
        await this.updateLocalStockAfterBill();

        // Clear cart
        this.cart = [];
        this.calculateTotals();
        this.customerName = '';
        this.customerPhone = '';
        this.orderNotes = '';
      }
    } catch (error) {
      this.swal.close();
      console.error('Failed to create bill:', error);
      this.swal.error('Error', 'Failed to create bill');
    }
  }

  /**
   * Print receipt
   */
  printReceipt(order: any): void {
    const receiptWindow = window.open('', '_blank', 'width=300,height=600');
    if (!receiptWindow) return;

    const receiptHtml = this.generateReceiptHtml(order);
    receiptWindow.document.write(receiptHtml);
    receiptWindow.document.close();

    setTimeout(() => {
      receiptWindow.print();
    }, 500);
  }

  /**
   * Generate receipt HTML - optimized for 58mm thermal paper
   * Same layout as Order Management small print
   */
  private generateReceiptHtml(order: any): string {
    const items = this.cart.map(item => {
      const englishName = item.product.name || '';
      const tamilName = item.product.nameTamil || '';
      const rate = item.unitPrice || 0;
      const mrp = item.mrp || rate;
      const hasDiscount = item.discount > 0;
      // Build name HTML based on receipt language settings
      let nameHtml = '';
      if (this.showEnglishOnReceipt && this.showTamilOnReceipt && tamilName) {
        // Both languages
        nameHtml = `${englishName}<br><span style="font-size: 9px; color: #333;">${tamilName}</span>`;
      } else if (this.showEnglishOnReceipt) {
        // English only
        nameHtml = englishName;
      } else if (this.showTamilOnReceipt && tamilName) {
        // Tamil only (use Tamil if available, fallback to English)
        nameHtml = tamilName;
      } else {
        // Fallback to English
        nameHtml = englishName;
      }
      // Show MRP with strikethrough if there's discount
      const rateHtml = hasDiscount
        ? `<span style="text-decoration: line-through; color: #666; font-size: 11px;">${mrp}</span><br>${rate}`
        : `${rate}`;
      return `
      <tr>
        <td style="font-size: 9px; padding: 2px 0; font-weight: 600; word-wrap: break-word; max-width: 60px;">${nameHtml}</td>
        <td style="font-size: 9px; text-align: right; padding: 2px 0; font-weight: 600; white-space: nowrap;">${rateHtml}</td>
        <td style="font-size: 9px; text-align: center; padding: 2px 0; font-weight: 700; white-space: nowrap;">${item.quantity}</td>
        <td style="font-size: 9px; text-align: right; padding: 2px 0; font-weight: 700; white-space: nowrap;">${item.total.toFixed(0)}</td>
      </tr>
    `;
    }).join('');

    const isOffline = order.offlineOrderId && !order.id;
    // Get shop name from order response (API), then localStorage, then component, then fallback
    // Check for truthy values (not empty strings)
    const storedShopName = localStorage.getItem('shop_name');
    const shopName = (order.shopName && order.shopName.trim()) ||
                     (storedShopName && storedShopName.trim()) ||
                     (this.shopName && this.shopName !== 'My Shop' ? this.shopName : null) ||
                     'Shop';
    const customerName = this.customerName || 'Walk-in Customer';
    const customerPhone = this.customerPhone || '';

    console.log('Receipt - shopName sources:', {
      orderShopName: order.shopName,
      localStorage: storedShopName,
      thisShopName: this.shopName,
      resolved: shopName
    });

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Receipt - ${order.orderNumber || order.offlineOrderId}</title>
        <style>
          @page {
            size: 58mm auto;
            margin: 1mm;
          }
          @media print {
            body {
              -webkit-print-color-adjust: exact;
              print-color-adjust: exact;
            }
            .no-print { display: none !important; }
          }
          body {
            font-family: 'Noto Sans Tamil', 'Latha', 'Tamil Sangam MN', Arial, sans-serif;
            font-size: 11px;
            width: 180px;
            max-width: 180px;
            margin: 0 auto;
            padding: 8px;
            line-height: 1.3;
          }
          .center { text-align: center; }
          .divider {
            border-top: 1px dashed #000;
            margin: 6px 0;
          }
          .divider-solid {
            border-top: 1px solid #000;
            margin: 6px 0;
          }
          table { width: 100%; border-collapse: collapse; }
          .shop-name {
            font-family: 'Noto Sans Tamil', 'Latha', 'Tamil Sangam MN', Arial, sans-serif;
            font-size: 14px;
            font-weight: 700;
            margin-bottom: 3px;
          }
          .order-number {
            font-size: 12px;
            font-weight: 700;
            background: #000;
            color: #fff;
            padding: 4px 8px;
            display: inline-block;
            border-radius: 3px;
            margin: 4px 0;
          }
          .customer-name {
            font-size: 12px;
            font-weight: 700;
          }
          .customer-phone {
            font-size: 10px;
            color: #333;
          }
          .item-header th {
            font-size: 10px;
            padding: 4px 0;
            border-bottom: 1px solid #000;
            text-transform: uppercase;
            font-weight: 700;
          }
          .payment-badge {
            font-size: 10px;
            font-weight: 700;
            padding: 4px 8px;
            background: #f0f0f0;
            border-radius: 3px;
            display: inline-block;
            margin: 4px 0;
          }
          .footer-text {
            font-size: 9px;
            color: #666;
            margin-top: 6px;
          }
          .offline-badge {
            background: #ff9800;
            color: white;
            padding: 2px 6px;
            font-size: 9px;
            border-radius: 3px;
          }
          .flex-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
          }
        </style>
      </head>
      <body>
        <div class="center shop-name">${shopName}</div>
        <div class="center" style="font-size: 9px; color: #666;">Order Receipt</div>
        ${isOffline ? '<div class="center"><span class="offline-badge">OFFLINE</span></div>' : ''}
        <div class="divider"></div>

        <div class="center">
          <div class="order-number">#${order.orderNumber || order.offlineOrderId}</div>
        </div>
        <div style="font-size: 9px; text-align: center; margin-bottom: 4px;">
          ${new Date().toLocaleDateString('en-IN', {day: '2-digit', month: 'short', year: 'numeric'})} | ${new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
        </div>
        <div class="divider"></div>

        <div style="margin-bottom: 4px;">
          <div class="customer-name">${customerName}</div>
          ${customerPhone ? `<div class="customer-phone">${customerPhone}</div>` : ''}
        </div>
        <div class="divider"></div>

        <table>
          <thead>
            <tr class="item-header">
              <th style="text-align: left;">ITEM</th>
              <th style="text-align: right;">RATE</th>
              <th style="text-align: center;">QTY</th>
              <th style="text-align: right;">AMT</th>
            </tr>
          </thead>
          <tbody>
            ${items}
          </tbody>
        </table>
        <div class="divider-solid"></div>

        <div class="flex-row" style="font-size: 10px; padding: 4px 0;">
          <span style="font-weight: 600;">Items: ${this.cart.length} (Qty: ${this.cart.reduce((sum, item) => sum + item.quantity, 0)})</span>
          <span style="font-weight: 700;">₹${this.totalAmount.toFixed(0)}</span>
        </div>

        ${this.totalDiscount > 0 ? `
        <div class="flex-row" style="font-size: 10px; padding: 2px 0;">
          <span style="font-weight: 600; color: #888;">MRP Total</span>
          <span style="text-decoration: line-through; color: #888;">₹${this.totalMrp.toFixed(0)}</span>
        </div>
        <div class="flex-row" style="font-size: 10px; padding: 2px 0; color: #4caf50;">
          <span style="font-weight: 600;">You Save</span>
          <span style="font-weight: 700;">₹${this.totalDiscount.toFixed(0)}</span>
        </div>
        ` : ''}

        <div class="flex-row" style="border-top: 1px solid #000; padding-top: 6px; margin-top: 4px;">
          <span style="font-size: 14px; font-weight: 700;">TOTAL</span>
          <span style="font-size: 16px; font-weight: 700;">₹${this.totalAmount.toFixed(0)}</span>
        </div>

        <div class="divider"></div>
        <div class="center">
          <span class="payment-badge">
            ${this.selectedPaymentMethod === 'CASH_ON_DELIVERY' ? '💵 CASH' : this.selectedPaymentMethod === 'UPI' ? '📱 UPI' : '💳 CARD'}
          </span>
        </div>

        <div class="divider"></div>

        <div class="center footer-text">
          Thank you for your order!<br>
          Printed: ${new Date().toLocaleString('en-IN')}
        </div>

        <!-- Print Button (hidden during print) -->
        <div class="no-print" style="margin-top: 15px; text-align: center;">
          <button onclick="window.print()" style="
            background: #4CAF50;
            color: white;
            border: none;
            padding: 12px 30px;
            font-size: 16px;
            font-weight: bold;
            border-radius: 5px;
            cursor: pointer;
            margin-right: 10px;
          ">🖨️ PRINT</button>
          <button onclick="window.close()" style="
            background: #666;
            color: white;
            border: none;
            padding: 12px 20px;
            font-size: 14px;
            border-radius: 5px;
            cursor: pointer;
          ">Close</button>
        </div>
      </body>
      </html>
    `;
  }

  /**
   * Get payment method label
   */
  getPaymentLabel(method: string): string {
    const found = this.paymentMethods.find(m => m.value === method);
    return found ? found.label : method;
  }

  /**
   * Generate UPI QR Code URL using QR Server API
   */
  getUpiQrCodeUrl(size: number = 150): string {
    if (!this.shopUpiId) return '';
    const upiUrl = `upi://pay?pa=${this.shopUpiId}&pn=${encodeURIComponent(this.shopName)}&am=${this.totalAmount}&cu=INR`;
    return `https://api.qrserver.com/v1/create-qr-code/?size=${size}x${size}&data=${encodeURIComponent(upiUrl)}`;
  }

  /**
   * Manual sync trigger
   */
  async manualSync(): Promise<void> {
    if (!this.syncStatus.isOnline) {
      this.swal.warning('Offline', 'Cannot sync while offline');
      return;
    }

    this.swal.loading('Syncing pending data...');

    try {
      // Sync pending orders
      const orderSyncResult = await this.syncService.syncPendingOrders();
      console.log('Order sync result:', orderSyncResult);

      // Sync pending product edits
      const editSyncResult = await this.syncService.syncPendingEdits();
      console.log('Edit sync result:', editSyncResult);

      // Sync pending product creations
      const productCreationResult = await this.syncService.syncPendingProductCreations();
      console.log('Product creation sync result:', productCreationResult);

      // Refresh products
      await this.loadProducts();
      this.swal.close();

      const totalSynced = orderSyncResult.synced + editSyncResult.synced + productCreationResult.synced;
      const totalFailed = orderSyncResult.failed + editSyncResult.failed + productCreationResult.failed;

      if (totalSynced > 0 || totalFailed > 0) {
        if (totalFailed > 0) {
          this.swal.warning('Sync Partial', `Synced: ${totalSynced}, Failed: ${totalFailed}`);
        } else {
          let message = '';
          if (orderSyncResult.synced > 0) message += `${orderSyncResult.synced} order(s)`;
          if (editSyncResult.synced > 0) {
            if (message) message += ', ';
            message += `${editSyncResult.synced} product edit(s)`;
          }
          if (productCreationResult.synced > 0) {
            if (message) message += ', ';
            message += `${productCreationResult.synced} product(s) created`;
          }
          this.swal.success('Synced', `${message} synced successfully`);
        }
      } else {
        this.swal.success('Synced', 'No pending data to sync. Products updated.');
      }
    } catch (error: any) {
      this.swal.close();
      console.error('Sync error:', error);
      this.swal.error('Sync Failed', error.message || 'Failed to sync data');
    }
  }

  /**
   * Play beep sound - DISABLED to fix continuous sound issue
   */
  private playBeep(success: boolean): void {
    // Sound disabled for now
    return;
  }

  /**
   * Toggle customer form
   */
  toggleCustomerForm(): void {
    this.showCustomerForm = !this.showCustomerForm;
  }

  /**
   * Open quick edit dialog for a product
   */
  openQuickEdit(product: CachedProduct, event: Event): void {
    event.stopPropagation(); // Prevent adding to cart
    this.editingProduct = product;
    this.editPrice = product.price;
    this.editMrp = product.originalPrice || product.price;
    this.editStock = product.stock;
    this.editSku = product.sku || '';
    // Use barcode fields only - never fallback to SKU (SKU is not a barcode)
    this.editBarcode = product.barcode || '';
    this.editBarcode1 = product.barcode1 || '';
    this.editBarcode2 = product.barcode2 || '';
    this.editBarcode3 = product.barcode3 || '';
    // Editable name fields
    this.editName = product.name || '';
    this.editNameTamil = product.nameTamil || '';
    // Reset image edit state
    this.editImageFile = null;
    this.editImagePreview = '';

    // Load saved label fields from product (if available)
    this.labelNetQty = product.netQty || '';
    this.labelPackedDate = product.packedDate || '';
    this.labelExpiryDate = product.expiryDate || '';
    this.labelQuantity = 1;
  }

  /**
   * Auto-format date input (MM/YY format)
   * Automatically adds "/" after 2 digits
   */
  formatDateInput(event: Event, field: 'pkd' | 'exp'): void {
    const input = event.target as HTMLInputElement;
    let value = input.value.replace(/[^0-9]/g, ''); // Remove non-digits

    // Limit to 4 digits max
    if (value.length > 4) {
      value = value.substring(0, 4);
    }

    // Auto-add "/" after 2 digits
    if (value.length >= 2) {
      value = value.substring(0, 2) + '/' + value.substring(2);
    }

    // Update the correct field
    if (field === 'pkd') {
      this.labelPackedDate = value;
    } else {
      this.labelExpiryDate = value;
    }

    // Update input value
    input.value = value;
  }

  /**
   * Close quick edit dialog
   */
  closeQuickEdit(): void {
    this.editingProduct = null;
    this.editPrice = 0;
    this.editMrp = 0;
    this.editStock = 0;
    this.editBarcode = '';
    this.editSku = '';
    this.editBarcode1 = '';
    this.editBarcode2 = '';
    this.editBarcode3 = '';
    this.editName = '';
    this.editNameTamil = '';
    this.editImageFile = null;
    this.editImagePreview = '';
    this.labelQuantity = 1;
  }

  /**
   * Handle image file selection for editing
   */
  onEditImageSelect(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files[0]) {
      const file = input.files[0];
      // Validate file type
      if (!file.type.startsWith('image/')) {
        this.swal.error('Invalid File', 'Please select an image file');
        return;
      }
      // Validate file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        this.swal.error('File Too Large', 'Image must be less than 5MB');
        return;
      }
      this.editImageFile = file;
      // Create preview
      const reader = new FileReader();
      reader.onload = (e) => {
        this.editImagePreview = e.target?.result as string;
      };
      reader.readAsDataURL(file);
    }
  }

  /**
   * Remove selected image
   */
  removeEditImage(): void {
    this.editImageFile = null;
    this.editImagePreview = '';
  }

  /**
   * Generate Code128B barcode as a PNG data URL using Canvas
   * Produces pixel-perfect bars that scanners can reliably read
   */
  private generateCode128DataUrl(text: string): string {
    // Code128 patterns indexed by VALUE (0-106), not by character
    // Values 0-94 = printable ASCII (space through ~)
    // Values 95-102 = special function codes (DEL, FNC3, FNC2, SHIFT, CODE C, CODE B, CODE A, FNC1)
    // Values 103-105 = Start codes (A, B, C)
    const PATTERNS: string[] = [
      '11011001100', '11001101100', '11001100110', '10010011000', '10010001100', // 0-4
      '10001001100', '10011001000', '10011000100', '10001100100', '11001001000', // 5-9
      '11001000100', '11000100100', '10110011100', '10011011100', '10011001110', // 10-14
      '10111001100', '10011101100', '10011100110', '11001110010', '11001011100', // 15-19
      '11001001110', '11011100100', '11001110100', '11101101110', '11101001100', // 20-24
      '11100101100', '11100100110', '11101100100', '11100110100', '11100110010', // 25-29
      '11011011000', '11011000110', '11000110110', '10100011000', '10001011000', // 30-34
      '10001000110', '10110001000', '10001101000', '10001100010', '11010001000', // 35-39
      '11000101000', '11000100010', '10110111000', '10110001110', '10001101110', // 40-44
      '10111011000', '10111000110', '10001110110', '11101110110', '11010001110', // 45-49
      '11000101110', '11011101000', '11011100010', '11011101110', '11101011000', // 50-54
      '11101000110', '11100010110', '11101101000', '11101100010', '11100011010', // 55-59
      '11101111010', '11001000010', '11110001010', '10100110000', '10100001100', // 60-64
      '10010110000', '10010000110', '10000101100', '10000100110', '10110010000', // 65-69
      '10110000100', '10011010000', '10011000010', '10000110100', '10000110010', // 70-74
      '11000010010', '11001010000', '11110111010', '11000010100', '10001111010', // 75-79
      '10100111100', '10010111100', '10010011110', '10111100100', '10011110100', // 80-84
      '10011110010', '11110100100', '11110010100', '11110010010', '11011011110', // 85-89
      '11011110110', '11110110110', '10101111000', '10100011110', '10001011110', // 90-94
      '10111101000', '10111100010', '11110101000', '11110100010', '10111011110', // 95-99
      '10111101110', '11101011110', '11110101110', '11010000100',               // 100-103 (103=Start A)
      '11010010000', '11010011100'                                              // 104-105 (Start B, Start C)
    ];
    const STOP = '1100011101011';

    let pattern = PATTERNS[104]; // Start Code B
    let checksum = 104;

    for (let i = 0; i < text.length; i++) {
      const value = text.charCodeAt(i) - 32;
      if (value >= 0 && value < 95) {
        pattern += PATTERNS[value];
        checksum += (i + 1) * value;
      }
    }

    // Checksum - use direct value index (works for ALL values 0-102)
    const checksumValue = checksum % 103;
    pattern += PATTERNS[checksumValue];
    pattern += STOP;

    // Canvas rendering - pixel perfect
    const moduleWidth = 2;       // 2 pixels per module
    const scale = 3;             // 3x for print quality
    const mw = moduleWidth * scale; // 6 actual pixels per module
    const quietZone = 10 * mw;  // 10 modules quiet zone
    const height = 100 * scale;  // bar height in pixels
    const canvasWidth = (pattern.length * mw) + (quietZone * 2);

    const canvas = document.createElement('canvas');
    canvas.width = canvasWidth;
    canvas.height = height;
    const ctx = canvas.getContext('2d');
    if (!ctx) return '';

    // White background
    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(0, 0, canvasWidth, height);

    // Draw bars - merge consecutive black modules into single rectangles
    ctx.fillStyle = '#000000';
    let idx = 0;
    while (idx < pattern.length) {
      if (pattern[idx] === '1') {
        const startX = quietZone + (idx * mw);
        let barWidth = 0;
        while (idx < pattern.length && pattern[idx] === '1') {
          barWidth += mw;
          idx++;
        }
        ctx.fillRect(startX, 0, barWidth, height);
      } else {
        idx++;
      }
    }

    return canvas.toDataURL('image/png');
  }

  /**
   * Print product label with barcode
   * Optimized for 50x25mm thermal labels
   */
  printLabel(): void {
    if (!this.editingProduct) return;

    const product = this.editingProduct;
    const barcode = this.editBarcode1 || this.editBarcode || product.sku || '';
    const quantity = this.labelQuantity || 1;

    if (!barcode) {
      this.swal.warning('No Barcode', 'Please add a barcode to print labels');
      return;
    }

    // Generate labels HTML
    const labelsHtml = this.generateLabelsHtml(product, barcode, quantity);

    // Open print window
    const printWindow = window.open('', '_blank', 'width=400,height=600');
    if (!printWindow) {
      this.swal.error('Error', 'Please allow popups to print labels');
      return;
    }

    printWindow.document.write(labelsHtml);
    printWindow.document.close();

    setTimeout(() => {
      printWindow.print();
    }, 300);
  }

  /**
   * Generate HTML for multiple labels
   */
  private generateLabelsHtml(product: CachedProduct, barcode: string, quantity: number): string {
    let labels = '';
    for (let i = 0; i < quantity; i++) {
      labels += this.generateSingleLabelHtml(product, barcode);
    }

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Label - ${product.name}</title>
        <style>
          @page {
            size: 50mm 25mm;
            margin: 0;
            padding: 0;
          }
          @media print {
            html, body {
              margin: 0 !important;
              padding: 0 !important;
              width: 50mm !important;
              -webkit-print-color-adjust: exact;
              print-color-adjust: exact;
            }
            .print-instructions { display: none !important; }
            .label {
              page-break-after: always;
              page-break-inside: avoid;
              border: none !important;
            }
            .label:last-child { page-break-after: auto; }
          }
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            font-family: 'Noto Sans Tamil', 'Segoe UI', Arial, sans-serif;
            width: 50mm;
          }
          .print-instructions {
            width: 320px;
            margin: 10px auto;
            padding: 12px 16px;
            background: #fffbeb;
            border: 1px solid #f59e0b;
            border-radius: 8px;
            font-family: Arial, sans-serif;
            font-size: 12px;
            color: #92400e;
            line-height: 1.6;
          }
          .print-instructions strong { color: #78350f; }
          .print-instructions ul { margin: 4px 0 0 16px; }
          .label {
            width: 50mm;
            height: 25mm;
            padding: 1mm 2mm;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: space-between;
            border: 1px dashed #ccc;
            background: white;
            overflow: hidden;
          }
          .label-top {
            width: 100%;
            text-align: center;
          }
          .shop-name {
            font-size: 6pt;
            font-weight: 800;
            color: #000;
            text-transform: uppercase;
            letter-spacing: 0.3px;
            line-height: 1.2;
            margin-bottom: 0.3mm;
          }
          .tamil-name {
            font-size: 5pt;
            font-weight: 600;
            color: #000;
            font-family: 'Noto Sans Tamil', 'Latha', 'Tamil Sangam MN', Arial, sans-serif;
            line-height: 1.2;
            margin-bottom: 0.3mm;
          }
          .english-name {
            font-size: 5pt;
            font-weight: 600;
            color: #000;
            line-height: 1.2;
            margin-bottom: 0.3mm;
          }
          .info-row {
            display: flex;
            justify-content: space-between;
            width: 100%;
            font-size: 5pt;
            font-weight: 700;
            color: #000;
            margin-top: 0.3mm;
            padding: 0 1mm;
          }
          .info-item {
            white-space: nowrap;
          }
          .info-item.info-left {
            text-align: left;
          }
          .info-item.info-right {
            text-align: right;
          }
          .date-row {
            display: flex;
            justify-content: space-between;
            width: 100%;
            font-size: 4.5pt;
            font-weight: 600;
            color: #333;
            margin-top: 0.3mm;
            padding: 0 1mm;
          }
          .date-item {
            white-space: nowrap;
          }
          .date-item.date-left {
            text-align: left;
          }
          .date-item.date-right {
            text-align: right;
          }
          .label-bottom {
            width: 100%;
            display: flex;
            flex-direction: column;
            align-items: center;
            margin-top: 0.5mm;
          }
          .barcode {
            display: flex;
            justify-content: center;
            align-items: center;
          }
          .barcode img {
            height: 8mm;
            width: auto;
            image-rendering: pixelated;
            image-rendering: -moz-crisp-edges;
            image-rendering: crisp-edges;
          }
          .barcode-text {
            font-size: 5pt;
            font-family: 'Courier New', monospace;
            font-weight: 700;
            letter-spacing: 1px;
            color: #000;
            text-align: center;
            margin-top: 0.3mm;
          }
        </style>
      </head>
      <body>
        <div class="print-instructions">
          <strong>Printer Settings (Important):</strong>
          <ul>
            <li>Paper size: <strong>50 x 25 mm</strong> (or custom)</li>
            <li>Margins: <strong>None</strong></li>
            <li>Scale: <strong>100%</strong> (not "Fit to page")</li>
          </ul>
        </div>
        ${labels}
      </body>
      </html>
    `;
  }

  /**
   * Generate HTML for a single label
   * Uses labelConfig for customizable label elements
   */
  private generateSingleLabelHtml(product: CachedProduct, barcode: string): string {
    const config = this.labelConfig;
    const price = this.editPrice || product.price || 0;
    const mrp = this.editMrp || product.originalPrice || price;

    let html = '<div class="label">';

    // Top section - text content
    html += '<div class="label-top">';

    // Shop name row
    if (config.showShopName && this.shopName) {
      html += `<div class="shop-name">${this.shopName}</div>`;
    }

    // Tamil name row
    if (config.showTamilName && product.nameTamil) {
      html += `<div class="tamil-name">${product.nameTamil}</div>`;
    }

    // English name row
    if (config.showEnglishName && product.name) {
      html += `<div class="english-name">${product.name}</div>`;
    }

    // Info row (NET QTY on left, MRP on right)
    const showNetQty = config.showNetQty && this.labelNetQty;
    const showMrp = config.showMrp;
    if (showNetQty || showMrp) {
      html += '<div class="info-row">';
      html += `<span class="info-item info-left">${showNetQty ? 'NET QTY: ' + this.labelNetQty : ''}</span>`;
      html += `<span class="info-item info-right">${showMrp ? 'MRP: ₹' + mrp : ''}</span>`;
      html += '</div>';
    }

    // Date row (PKD on left, EXP on right)
    const showPkd = config.showPackedDate && this.labelPackedDate;
    const showExp = config.showExpiryDate && this.labelExpiryDate;
    if (showPkd || showExp) {
      html += '<div class="date-row">';
      html += `<span class="date-item date-left">${showPkd ? 'PKD: ' + this.labelPackedDate : ''}</span>`;
      html += `<span class="date-item date-right">${showExp ? 'EXP: ' + this.labelExpiryDate : ''}</span>`;
      html += '</div>';
    }

    html += '</div>'; // close label-top

    // Bottom section - barcode
    html += '<div class="label-bottom">';

    // Barcode (Canvas-rendered PNG for pixel-perfect scanning)
    if (config.showBarcode) {
      const barcodeDataUrl = this.generateCode128DataUrl(barcode);
      html += `<div class="barcode"><img src="${barcodeDataUrl}" alt="${barcode}"></div>`;
    }

    // Barcode number
    if (config.showBarcodeNumber) {
      html += `<div class="barcode-text">${barcode}</div>`;
    }

    html += '</div>'; // close label-bottom
    html += '</div>'; // close label
    return html;
  }

  /**
   * Save quick edit changes (supports offline mode)
   */
  async saveQuickEdit(): Promise<void> {
    if (!this.editingProduct) return;

    // Validation
    if (this.editPrice <= 0) {
      this.swal.error('Invalid Price', 'Price must be greater than 0');
      return;
    }
    if (this.editMrp < this.editPrice) {
      this.swal.error('Invalid MRP', 'MRP cannot be less than selling price');
      return;
    }
    if (this.editStock < 0) {
      this.swal.error('Invalid Stock', 'Stock cannot be negative');
      return;
    }

    // Validate duplicate barcodes within same product
    const b1 = this.editBarcode1?.trim() || '';
    const b2 = this.editBarcode2?.trim() || '';
    const b3 = this.editBarcode3?.trim() || '';

    if (b1 && b2 && b1.toLowerCase() === b2.toLowerCase()) {
      this.swal.error('Duplicate Barcode', 'Barcode 1 and Barcode 2 cannot be the same.');
      return;
    }
    if (b1 && b3 && b1.toLowerCase() === b3.toLowerCase()) {
      this.swal.error('Duplicate Barcode', 'Barcode 1 and Barcode 3 cannot be the same.');
      return;
    }
    if (b2 && b3 && b2.toLowerCase() === b3.toLowerCase()) {
      this.swal.error('Duplicate Barcode', 'Barcode 2 and Barcode 3 cannot be the same.');
      return;
    }

    // Validate duplicate barcodes against other products
    // Get original barcodes from the editing product (to skip validation if unchanged)
    const originalBarcodes = [
      this.editingProduct?.barcode1?.toLowerCase(),
      this.editingProduct?.barcode2?.toLowerCase(),
      this.editingProduct?.barcode3?.toLowerCase(),
      this.editingProduct?.barcode?.toLowerCase(),
      this.editingProduct?.sku?.toLowerCase()
    ].filter(b => b);

    const barcodesToCheck = [
      { value: b1, label: 'Barcode 1' },
      { value: b2, label: 'Barcode 2' },
      { value: b3, label: 'Barcode 3' }
    ].filter(b => b.value && b.value.trim() !== '');

    for (const barcodeInfo of barcodesToCheck) {
      const barcodeValue = barcodeInfo.value.trim().toLowerCase();

      // Skip validation if this barcode is unchanged from the original product
      if (originalBarcodes.includes(barcodeValue)) {
        continue;
      }

      const duplicateProduct = this.products.find(p => {
        // Skip if same product by ID
        if (p.id === this.editingProduct!.id) return false;

        // Also skip if the product shares any original barcode with the editing product
        // This handles: temp ID vs real ID mismatch after background sync,
        // and offline products with different temp IDs
        const pBarcodes = [p.barcode1, p.barcode2, p.barcode3, p.barcode, p.sku]
          .filter(b => b).map(b => b!.toLowerCase());
        const hasCommonBarcode = pBarcodes.some(pb => originalBarcodes.includes(pb));
        if (hasCommonBarcode) return false;

        return (
          (p.sku && p.sku.toLowerCase() === barcodeValue) ||
          (p.barcode && p.barcode.toLowerCase() === barcodeValue) ||
          (p.barcode1 && p.barcode1.toLowerCase() === barcodeValue) ||
          (p.barcode2 && p.barcode2.toLowerCase() === barcodeValue) ||
          (p.barcode3 && p.barcode3.toLowerCase() === barcodeValue)
        );
      });

      if (duplicateProduct) {
        this.swal.error('Duplicate Barcode', `${barcodeInfo.label} "${barcodeInfo.value}" already exists for product "${duplicateProduct.name}". Please use a unique barcode.`);
        return;
      }
    }

    this.isSavingEdit = true;

    const productId = this.editingProduct.id;
    const updateData: any = {
      price: this.editPrice,
      originalPrice: this.editMrp,
      stockQuantity: this.editStock,
      sku: this.editSku,
      barcode1: this.editBarcode1,
      barcode2: this.editBarcode2,
      barcode3: this.editBarcode3,
      customName: this.editName,
      nameTamil: this.editNameTamil,
      netQty: this.labelNetQty,
      packedDate: this.labelPackedDate,
      expiryDate: this.labelExpiryDate
    };

    // Store previous values for potential rollback
    const previousValues = {
      price: this.editingProduct.price,
      originalPrice: this.editingProduct.originalPrice,
      stockQuantity: this.editingProduct.stock,
      barcode: this.editingProduct.barcode,
      barcode1: this.editingProduct.barcode1,
      barcode2: this.editingProduct.barcode2,
      barcode3: this.editingProduct.barcode3,
      name: this.editingProduct.name,
      nameTamil: this.editingProduct.nameTamil,
      netQty: this.editingProduct.netQty,
      packedDate: this.editingProduct.packedDate,
      expiryDate: this.editingProduct.expiryDate
    };

    try {
      // For offline-created products (negative temp ID), always save offline
      // They don't exist on the server yet, so API calls would fail
      const isOfflineProduct = productId < 0;

      // Try API call first (even if navigator.onLine is true, network might be down)
      if (navigator.onLine && !isOfflineProduct) {
        try {
          // Online mode - call API
          let response: any;

          // Use FormData if there's an image to upload
          if (this.editImageFile) {
            const formData = new FormData();
            formData.append('price', this.editPrice.toString());
            formData.append('originalPrice', this.editMrp.toString());
            formData.append('stockQuantity', this.editStock.toString());
            if (this.editBarcode1) formData.append('barcode1', this.editBarcode1);
            if (this.editBarcode2) formData.append('barcode2', this.editBarcode2);
            if (this.editBarcode3) formData.append('barcode3', this.editBarcode3);
            if (this.editName) formData.append('customName', this.editName);
            if (this.editNameTamil) formData.append('nameTamil', this.editNameTamil);
            if (this.labelNetQty) formData.append('netQty', this.labelNetQty);
            if (this.labelPackedDate) formData.append('packedDate', this.labelPackedDate);
            if (this.labelExpiryDate) formData.append('expiryDate', this.labelExpiryDate);
            formData.append('image', this.editImageFile);

            response = await this.http.patch<any>(
              `${this.apiUrl}/shop-products/${productId}/quick-update`,
              formData
            ).toPromise();
          } else {
            response = await this.http.patch<any>(
              `${this.apiUrl}/shop-products/${productId}/quick-update`,
              updateData
            ).toPromise();
          }

          // Check response statusCode (backend returns 200 even for errors)
          // statusCode "0000" = success, anything else = error
          if (response?.statusCode && response.statusCode !== '0000') {
            // Backend returned an error in the response body
            this.isSavingEdit = false;
            this.swal.error('Validation Error', response.message || 'Failed to update product');
            return;
          }

          // Update succeeded - update local data
          // Add image preview to updateData if image was uploaded
          if (this.editImagePreview) {
            updateData.imageBase64 = this.editImagePreview;
          }
          await this.updateLocalProductData(productId, updateData);
          this.swal.success('Updated', 'Product updated successfully');
          this.closeQuickEdit();
          return;
        } catch (apiError: any) {
          console.log('API Error caught:', apiError);

          // Check if it's a server error (not a network error)
          // Network errors have status 0 or no status
          const isNetworkError = !apiError?.status || apiError.status === 0;

          if (!isNetworkError) {
            // Server responded with an error - show to user and don't save offline
            this.isSavingEdit = false;
            const errorMsg = apiError?.error?.message || apiError?.message || 'Failed to update product';
            this.swal.error('Error', errorMsg);
            return;
          }

          // Network error (status 0) - fall through to offline save
          console.warn('Network error, saving offline:', apiError);
        }
      }

      // Offline mode OR API failed - validate barcodes against local data first
      // Only validate barcodes that have actually changed
      const origB1 = this.editingProduct?.barcode1?.toLowerCase() || '';
      const origB2 = this.editingProduct?.barcode2?.toLowerCase() || '';
      const origB3 = this.editingProduct?.barcode3?.toLowerCase() || '';

      const newB1 = (this.editBarcode1 || '').toLowerCase();
      const newB2 = (this.editBarcode2 || '').toLowerCase();
      const newB3 = (this.editBarcode3 || '').toLowerCase();

      // Only validate if barcodes have actually changed
      const b1Changed = newB1 !== origB1;
      const b2Changed = newB2 !== origB2;
      const b3Changed = newB3 !== origB3;

      if (b1Changed || b2Changed || b3Changed) {
        const barcodeValidationError = await this.offlineStorage.validateBarcodes(
          b1Changed ? this.editBarcode1 : null,
          b2Changed ? this.editBarcode2 : null,
          b3Changed ? this.editBarcode3 : null,
          productId
        );

        if (barcodeValidationError) {
          this.isSavingEdit = false;
          this.swal.error('Duplicate Barcode', barcodeValidationError);
          return;
        }
      }

      // Save to offline edits queue
      const offlineEdit: OfflineEdit = {
        editId: this.offlineStorage.generateOfflineEditId(),
        productId: productId,
        shopId: this.shopId,
        changes: {
          price: this.editPrice,
          originalPrice: this.editMrp,
          stockQuantity: this.editStock,
          sku: this.editSku,
          barcode: this.editBarcode,
          barcode1: this.editBarcode1,
          barcode2: this.editBarcode2,
          barcode3: this.editBarcode3,
          customName: this.editName,
          nameTamil: this.editNameTamil,
          netQty: this.labelNetQty,
          packedDate: this.labelPackedDate,
          expiryDate: this.labelExpiryDate
        },
        previousValues: previousValues,
        createdAt: new Date().toISOString(),
        synced: false
      };

      // Save to offline edits queue
      await this.offlineStorage.saveOfflineEdit(offlineEdit);

      // Add image preview to updateData if image was selected (for local display)
      if (this.editImagePreview) {
        updateData.imageBase64 = this.editImagePreview;
      }

      // Update local product immediately (optimistic update)
      await this.updateLocalProductData(productId, updateData);

      // Update local cache in IndexedDB
      await this.offlineStorage.updateLocalProduct(productId, {
        price: this.editPrice,
        originalPrice: this.editMrp,
        stock: this.editStock,
        sku: this.editSku,
        barcode: this.editBarcode,
        barcode1: this.editBarcode1,
        barcode2: this.editBarcode2,
        barcode3: this.editBarcode3,
        name: this.editName,
        nameTamil: this.editNameTamil,
        imageBase64: this.editImagePreview || undefined,
        netQty: this.labelNetQty,
        packedDate: this.labelPackedDate,
        expiryDate: this.labelExpiryDate
      });

      this.swal.success('Saved Offline', 'Changes saved locally. Will sync when online.');
      this.closeQuickEdit();

    } catch (error: any) {
      console.error('Failed to save product edit:', error);
      this.swal.error('Error', error.message || 'Failed to save product edit');
    } finally {
      this.isSavingEdit = false;
    }
  }

  /**
   * Update local product data in memory (for both online and offline modes)
   */
  private async updateLocalProductData(productId: number, updateData: any): Promise<void> {
    // Update local product in list
    const productIndex = this.products.findIndex(p => p.id === productId);
    if (productIndex !== -1) {
      this.products[productIndex].price = updateData.price;
      this.products[productIndex].originalPrice = updateData.originalPrice;
      this.products[productIndex].stock = updateData.stockQuantity;
      if (updateData.sku !== undefined) this.products[productIndex].sku = updateData.sku;
      this.products[productIndex].barcode = updateData.barcode;
      this.products[productIndex].barcode1 = updateData.barcode1;
      this.products[productIndex].barcode2 = updateData.barcode2;
      this.products[productIndex].barcode3 = updateData.barcode3;
      if (updateData.customName) this.products[productIndex].name = updateData.customName;
      if (updateData.nameTamil !== undefined) this.products[productIndex].nameTamil = updateData.nameTamil;
      if (updateData.imageBase64) this.products[productIndex].imageBase64 = updateData.imageBase64;
      if (updateData.netQty !== undefined) this.products[productIndex].netQty = updateData.netQty;
      if (updateData.packedDate !== undefined) this.products[productIndex].packedDate = updateData.packedDate;
      if (updateData.expiryDate !== undefined) this.products[productIndex].expiryDate = updateData.expiryDate;
    }

    // Update filtered products
    const filteredIndex = this.filteredProducts.findIndex(p => p.id === productId);
    if (filteredIndex !== -1) {
      this.filteredProducts[filteredIndex].price = updateData.price;
      this.filteredProducts[filteredIndex].originalPrice = updateData.originalPrice;
      this.filteredProducts[filteredIndex].stock = updateData.stockQuantity;
      if (updateData.sku !== undefined) this.filteredProducts[filteredIndex].sku = updateData.sku;
      this.filteredProducts[filteredIndex].barcode = updateData.barcode;
      this.filteredProducts[filteredIndex].barcode1 = updateData.barcode1;
      this.filteredProducts[filteredIndex].barcode2 = updateData.barcode2;
      this.filteredProducts[filteredIndex].barcode3 = updateData.barcode3;
      if (updateData.customName) this.filteredProducts[filteredIndex].name = updateData.customName;
      if (updateData.nameTamil !== undefined) this.filteredProducts[filteredIndex].nameTamil = updateData.nameTamil;
      if (updateData.imageBase64) this.filteredProducts[filteredIndex].imageBase64 = updateData.imageBase64;
      if (updateData.netQty !== undefined) this.filteredProducts[filteredIndex].netQty = updateData.netQty;
      if (updateData.packedDate !== undefined) this.filteredProducts[filteredIndex].packedDate = updateData.packedDate;
      if (updateData.expiryDate !== undefined) this.filteredProducts[filteredIndex].expiryDate = updateData.expiryDate;
    }

    // Update cart if product is in cart
    const cartItem = this.cart.find(item => item.product.id === productId);
    if (cartItem) {
      cartItem.product.price = updateData.price;
      cartItem.product.originalPrice = updateData.originalPrice;
      cartItem.product.stock = updateData.stockQuantity;
      if (updateData.customName) cartItem.product.name = updateData.customName;
      if (updateData.nameTamil !== undefined) cartItem.product.nameTamil = updateData.nameTamil;
      if (updateData.imageBase64) cartItem.product.imageBase64 = updateData.imageBase64;
      cartItem.unitPrice = updateData.price;
      cartItem.mrp = updateData.originalPrice;
      cartItem.discount = updateData.originalPrice - updateData.price;
      cartItem.total = cartItem.quantity * updateData.price;
      this.calculateTotals();
    }

    // Update local cache (for online mode)
    if (navigator.onLine) {
      await this.offlineStorage.saveProducts(this.products, this.shopId);
    }
  }

  /**
   * Update local stock after creating a bill (fast - no server reload needed)
   */
  private async updateLocalStockAfterBill(): Promise<void> {
    // Deduct stock for each cart item locally
    for (const cartItem of this.cart) {
      const productId = cartItem.product.id;
      const quantitySold = cartItem.quantity;

      // Update in products array
      const productIndex = this.products.findIndex(p => p.id === productId);
      if (productIndex !== -1 && this.products[productIndex].trackInventory) {
        const currentStock = this.products[productIndex].stock || 0;
        this.products[productIndex].stock = Math.max(0, currentStock - quantitySold);
      }

      // Update in filtered products array
      const filteredIndex = this.filteredProducts.findIndex(p => p.id === productId);
      if (filteredIndex !== -1 && this.filteredProducts[filteredIndex].trackInventory) {
        const currentStock = this.filteredProducts[filteredIndex].stock || 0;
        this.filteredProducts[filteredIndex].stock = Math.max(0, currentStock - quantitySold);
      }
    }

    // Save updated products to IndexedDB cache
    await this.offlineStorage.saveProducts(this.products, this.shopId);
  }

  /**
   * Open quick add dialog for custom product
   */
  openQuickAdd(): void {
    this.showQuickAddDialog = true;
    this.customProductName = '';
    this.customProductPrice = 0;
    this.customProductMrp = 0;
    this.customProductQty = 1;
  }

  /**
   * Close quick add dialog
   */
  closeQuickAdd(): void {
    this.showQuickAddDialog = false;
    this.customProductName = '';
    this.customProductPrice = 0;
    this.customProductMrp = 0;
    this.customProductQty = 1;
  }

  /**
   * Add custom product to cart
   */
  addCustomProduct(): void {
    if (!this.customProductName || this.customProductPrice <= 0) {
      this.swal.error('Invalid Input', 'Please enter product name and price');
      return;
    }

    const mrp = this.customProductMrp || this.customProductPrice;
    const qty = this.customProductQty || 1;

    // Create a custom product with negative ID (to identify as custom)
    const customProduct: CachedProduct = {
      id: this.customProductIdCounter--,
      shopId: this.shopId,
      name: this.customProductName,
      nameTamil: '',
      price: this.customProductPrice,
      originalPrice: mrp,
      stock: 9999, // Unlimited stock for custom products
      trackInventory: false,
      sku: 'CUSTOM',
      barcode: '',
      image: '',
      categoryId: undefined,
      categoryName: 'Custom'
    };

    const discount = mrp - this.customProductPrice;

    // Add to cart (at top)
    this.cart.unshift({
      product: customProduct,
      quantity: qty,
      unitPrice: this.customProductPrice,
      mrp: mrp,
      total: this.customProductPrice * qty,
      discount: discount
    });

    this.calculateTotals();
    this.closeQuickAdd();

    this.swal.success('Added', `${this.customProductName} added to cart`);
  }

  // ==================== ADD NEW PRODUCT (OFFLINE CAPABLE) ====================

  /**
   * Open add new product dialog
   */
  openAddProductDialog(): void {
    this.showAddProductDialog = true;
    this.newProductName = '';
    this.newProductNameTamil = '';
    this.newProductPrice = 0;
    this.newProductMrp = 0;
    this.newProductCostPrice = 0;
    this.newProductStock = 0;
    this.newProductBarcode1 = '';
    this.newProductBarcode2 = '';
    this.newProductBarcode3 = '';
    this.newProductTrackInventory = true;
  }

  /**
   * Close add new product dialog
   */
  closeAddProductDialog(): void {
    this.showAddProductDialog = false;
    this.newProductName = '';
    this.newProductNameTamil = '';
    this.newProductPrice = 0;
    this.newProductMrp = 0;
    this.newProductCostPrice = 0;
    this.newProductStock = 0;
    this.newProductBarcode1 = '';
    this.newProductBarcode2 = '';
    this.newProductBarcode3 = '';
    this.newProductTrackInventory = true;
    this.isSavingNewProduct = false;
  }

  /**
   * Save new product (works offline)
   */
  async saveNewProduct(): Promise<void> {
    // Validation
    if (!this.newProductName || this.newProductName.trim() === '') {
      this.swal.error('Required', 'Product name is required');
      return;
    }
    if (this.newProductPrice <= 0) {
      this.swal.error('Invalid Price', 'Price must be greater than 0');
      return;
    }

    // Validate duplicate barcodes within same product
    const b1 = this.newProductBarcode1?.trim() || '';
    const b2 = this.newProductBarcode2?.trim() || '';
    const b3 = this.newProductBarcode3?.trim() || '';

    if (b1 && b2 && b1.toLowerCase() === b2.toLowerCase()) {
      this.swal.error('Duplicate Barcode', 'Barcode 1 and Barcode 2 cannot be the same.');
      return;
    }
    if (b1 && b3 && b1.toLowerCase() === b3.toLowerCase()) {
      this.swal.error('Duplicate Barcode', 'Barcode 1 and Barcode 3 cannot be the same.');
      return;
    }
    if (b2 && b3 && b2.toLowerCase() === b3.toLowerCase()) {
      this.swal.error('Duplicate Barcode', 'Barcode 2 and Barcode 3 cannot be the same.');
      return;
    }

    // Check all barcodes against other products
    const barcodesToCheck = [
      { value: b1, label: 'Barcode 1' },
      { value: b2, label: 'Barcode 2' },
      { value: b3, label: 'Barcode 3' }
    ].filter(b => b.value !== '');

    for (const barcodeInfo of barcodesToCheck) {
      const duplicateProduct = this.products.find(p =>
        (p.barcode1 && p.barcode1.toLowerCase() === barcodeInfo.value.toLowerCase()) ||
        (p.barcode2 && p.barcode2.toLowerCase() === barcodeInfo.value.toLowerCase()) ||
        (p.barcode3 && p.barcode3.toLowerCase() === barcodeInfo.value.toLowerCase())
      );
      if (duplicateProduct) {
        this.swal.error('Duplicate Barcode', `${barcodeInfo.label} "${barcodeInfo.value}" already exists for "${duplicateProduct.name}"`);
        return;
      }
    }

    this.isSavingNewProduct = true;

    try {
      // Auto-generate SKU from product name
      const nameForSku = this.newProductName.trim();
      const skuPrefix = nameForSku.substring(0, 3).toUpperCase();
      const skuTimestamp = Date.now().toString().slice(-6);
      const generatedSku = `${skuPrefix}${skuTimestamp}`;

      const productData = {
        shopId: this.shopId,
        name: this.newProductName.trim(),
        nameTamil: this.newProductNameTamil?.trim() || '',
        price: this.newProductPrice,
        originalPrice: this.newProductMrp || this.newProductPrice,
        costPrice: this.newProductCostPrice || 0,
        stockQuantity: this.newProductStock || 0,
        trackInventory: this.newProductTrackInventory,
        barcode1: this.newProductBarcode1?.trim() || '',
        barcode2: this.newProductBarcode2?.trim() || '',
        barcode3: this.newProductBarcode3?.trim() || '',
        customName: this.newProductName.trim(),
        sku: generatedSku
      };

      // Use sync service to create product (handles both online and offline)
      const result = await this.syncService.createProductOffline(productData);

      if (result.success) {
        // Add to local products list for immediate use
        const newProduct: CachedProduct = {
          id: result.tempProductId,
          shopId: this.shopId,
          name: this.newProductName.trim(),
          nameTamil: this.newProductNameTamil?.trim(),
          price: this.newProductPrice,
          originalPrice: this.newProductMrp || this.newProductPrice,
          stock: this.newProductStock || 0,
          trackInventory: this.newProductTrackInventory,
          sku: generatedSku,
          barcode: this.newProductBarcode1?.trim() || '',
          barcode1: this.newProductBarcode1?.trim() || '',
          barcode2: this.newProductBarcode2?.trim(),
          barcode3: this.newProductBarcode3?.trim(),
          image: '',
          categoryId: undefined,
          categoryName: ''
        };

        this.products.push(newProduct);
        this.filteredProducts = this.sortProductsWithCartFirst(this.products);

        this.closeAddProductDialog();

        if (navigator.onLine) {
          this.swal.success('Product Added', 'Product has been added and will sync shortly.');
          // Trigger sync immediately when online
          this.syncService.syncPendingProductCreations().then(() => {
            console.log('Product creation synced after online create');
          }).catch(err => console.warn('Auto-sync after creation failed:', err));
        } else {
          this.swal.success('Saved Offline', result.message);
        }
      } else {
        this.swal.error('Error', result.message);
      }
    } catch (error: any) {
      console.error('Failed to save new product:', error);
      this.swal.error('Error', error.message || 'Failed to save product');
    } finally {
      this.isSavingNewProduct = false;
    }
  }

  /**
   * Get total pending items count (orders + edits + product creations)
   */
  getTotalPendingCount(): number {
    return this.syncStatus.pendingOrders +
           (this.syncStatus.pendingEdits || 0) +
           (this.syncStatus.pendingProductCreations || 0);
  }
}
