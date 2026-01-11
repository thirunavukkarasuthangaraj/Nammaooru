import { Component, OnInit, OnDestroy, ViewChild, ElementRef } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Subject } from 'rxjs';
import { takeUntil, debounceTime } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { OfflineStorageService, CachedProduct } from '../../../../core/services/offline-storage.service';
import { PosSyncService, SyncStatus } from '../../../../core/services/pos-sync.service';
import { AuthService } from '../../../../core/services/auth.service';
import { SwalService } from '../../../../core/services/swal.service';
import { ShopContextService } from '../../services/shop-context.service';
import { getImageUrl } from '../../../../core/utils/image-url.util';

interface CartItem {
  product: CachedProduct;
  quantity: number;
  unitPrice: number;
  total: number;
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

  // Products
  products: CachedProduct[] = [];
  filteredProducts: CachedProduct[] = [];
  searchTerm: string = '';
  barcodeBuffer: string = '';

  // Cart
  cart: CartItem[] = [];
  subtotal: number = 0;
  taxAmount: number = 0;
  totalAmount: number = 0;
  taxRate: number = 0; // No tax

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
    lastProductSync: null,
    isSyncing: false
  };

  // UI state
  isLoading: boolean = true;
  showCustomerForm: boolean = false;

  // Language toggle
  showTamil: boolean = false;

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
    this.initSyncStatus();
    this.initSearch();
    this.initBarcodeScanner();
    this.loadProducts();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
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
          console.log('POS Billing - Shop loaded:', this.shopId, this.shopName);
        }
      });

    // Also try immediate value from context
    const currentShop = this.shopContext.getCurrentShop();
    if (currentShop) {
      this.shopId = currentShop.id;
      this.shopName = currentShop.name || currentShop.businessName || 'My Shop';
    } else {
      // Fallback to localStorage
      const storedShopId = localStorage.getItem('current_shop_id');
      if (storedShopId) {
        this.shopId = parseInt(storedShopId, 10);
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
    if (this.showTamil && product.nameTamil) {
      return product.nameTamil;
    }
    return product.name;
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

    document.addEventListener('keypress', (event: KeyboardEvent) => {
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
    });
  }

  /**
   * Load products - first from local cache, then sync from server
   */
  async loadProducts(): Promise<void> {
    this.isLoading = true;
    console.log('Loading products for POS...');

    // Try to load from local cache first (instant)
    const cachedProducts = await this.offlineStorage.getProducts();
    if (cachedProducts.length > 0) {
      this.products = cachedProducts;
      this.filteredProducts = this.sortProductsWithCartFirst(this.products);
      console.log(`Loaded ${this.products.length} products from cache`);

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

      // Sync in background if online
      if (navigator.onLine) {
        this.syncProductsInBackground();
      }
      return;
    }

    // No cache - load from server
    this.loadProductsFromServer();
  }

  /**
   * Load products from server
   */
  private loadProductsFromServer(): void {
    this.http.get<any>(`${this.apiUrl}/shop-products/my-products?page=0&size=1000`)
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

          // Map to CachedProduct format
          this.products = rawProducts.map((p: any) => this.mapProduct(p));
          this.filteredProducts = this.sortProductsWithCartFirst(this.products);
          this.isLoading = false;

          // Cache images in background for offline use
          console.log('Caching product images...');
          await this.cacheProductImages();

          // Save to local cache for offline use
          await this.offlineStorage.saveProducts(this.products, this.shopId);
          console.log(`Loaded and cached ${this.products.length} products with images`);
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
    this.http.get<any>(`${this.apiUrl}/shop-products/my-products?page=0&size=1000`)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: async (response) => {
          let rawProducts: any[] = [];

          if (response?.data?.content) {
            rawProducts = response.data.content;
          } else if (response?.data && Array.isArray(response.data)) {
            rawProducts = response.data;
          }

          const newProducts = rawProducts.map((p: any) => this.mapProduct(p));

          // Update cache
          await this.offlineStorage.saveProducts(newProducts, this.shopId);

          // Update UI if products changed
          if (newProducts.length !== this.products.length) {
            this.products = newProducts;
            this.filteredProducts = this.sortProductsWithCartFirst(this.products);
          }

          console.log('Background sync complete');
        },
        error: (error) => {
          console.warn('Background sync failed:', error);
        }
      });
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
      stock: p.stockQuantity || 0,
      trackInventory: p.trackInventory ?? true,
      sku: p.sku || p.masterProduct?.sku || '',
      barcode: p.barcode || p.masterProduct?.barcode || '',
      image: p.primaryImageUrl || '',
      categoryId: p.categoryId || p.masterProduct?.category?.id,
      categoryName: p.categoryName || p.masterProduct?.category?.name || ''
    };
  }

  /**
   * Handle search input
   */
  onSearchChange(): void {
    this.searchSubject.next(this.searchTerm);
  }

  /**
   * Filter products by search term
   */
  private filterProducts(term: string): void {
    if (!term || term.length < 2) {
      this.filteredProducts = this.sortProductsWithCartFirst(this.products);
      return;
    }

    const lowerTerm = term.toLowerCase();
    const filtered = this.products.filter(p =>
      p.name.toLowerCase().includes(lowerTerm) ||
      (p.nameTamil && p.nameTamil.toLowerCase().includes(lowerTerm)) ||
      (p.sku && p.sku.toLowerCase().includes(lowerTerm)) ||
      (p.barcode && p.barcode.toLowerCase().includes(lowerTerm))
    );
    this.filteredProducts = this.sortProductsWithCartFirst(filtered);
  }

  /**
   * Handle barcode scan
   */
  handleBarcodeScan(barcode: string): void {
    console.log('Barcode scanned:', barcode);

    // Find in loaded products by barcode or SKU
    const product = this.products.find(p =>
      p.barcode === barcode || p.sku === barcode
    );

    if (product) {
      this.addToCart(product);
      this.playBeep(true);
    } else {
      this.swal.error('Not Found', `Product with barcode "${barcode}" not found`);
      this.playBeep(false);
    }
  }

  /**
   * Manual barcode input
   */
  onBarcodeSubmit(): void {
    if (this.barcodeBuffer.trim()) {
      this.handleBarcodeScan(this.barcodeBuffer.trim());
      this.barcodeBuffer = '';
    }
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

    if (existingItem) {
      // Check stock before increasing
      if (product.trackInventory && existingItem.quantity >= product.stock) {
        this.swal.warning('Stock Limit', `Only ${product.stock} available`);
        return;
      }
      existingItem.quantity++;
      existingItem.total = existingItem.quantity * existingItem.unitPrice;
    } else {
      this.cart.push({
        product,
        quantity: 1,
        unitPrice: product.price,
        total: product.price
      });
    }

    this.calculateTotals();

    // Clear search and re-sort to show cart items first
    this.searchTerm = '';
    this.filteredProducts = this.sortProductsWithCartFirst(this.products);
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
   * Sort products to show cart items first
   */
  private sortProductsWithCartFirst(products: CachedProduct[]): CachedProduct[] {
    return [...products].sort((a, b) => {
      const aInCart = this.isInCart(a);
      const bInCart = this.isInCart(b);
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
      // Re-sort products list since cart changed
      this.filteredProducts = this.sortProductsWithCartFirst(this.products);
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
          // Re-sort products list since cart is now empty
          this.filteredProducts = this.sortProductsWithCartFirst(this.products);
        }
      });
  }

  /**
   * Calculate totals
   */
  private calculateTotals(): void {
    this.subtotal = this.cart.reduce((sum, item) => sum + item.total, 0);
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

      const result = await this.syncService.createPosOrder(orderData, this.shopId);

      this.swal.close();

      if (result.success) {
        const offlineMsg = result.offline ? ' (Saved offline - will sync when online)' : '';

        this.swal.success(
          'Bill Created',
          `Order ${result.order?.orderNumber || ''} - ₹${this.totalAmount.toFixed(0)}${offlineMsg}`
        );

        // Print receipt
        this.printReceipt(result.order);

        // Clear cart
        this.cart = [];
        this.calculateTotals();
        this.customerName = '';
        this.customerPhone = '';
        this.orderNotes = '';

        // Refresh products if online
        if (!result.offline) {
          this.loadProducts();
        }
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
   * Generate receipt HTML
   */
  private generateReceiptHtml(order: any): string {
    const items = this.cart.map(item => `
      <tr>
        <td style="text-align:left;">${item.product.name}</td>
        <td style="text-align:center;">${item.quantity}</td>
        <td style="text-align:right;">₹${item.total.toFixed(0)}</td>
      </tr>
    `).join('');

    const isOffline = order.offlineOrderId && !order.id;

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <title>Receipt</title>
        <style>
          body {
            font-family: 'Courier New', monospace;
            font-size: 12px;
            width: 280px;
            margin: 0 auto;
            padding: 10px;
          }
          .header { text-align: center; margin-bottom: 10px; }
          .shop-name { font-size: 16px; font-weight: bold; }
          .divider { border-top: 1px dashed #000; margin: 8px 0; }
          table { width: 100%; border-collapse: collapse; }
          th, td { padding: 4px 2px; }
          .total-row { font-weight: bold; font-size: 14px; }
          .footer { text-align: center; margin-top: 10px; font-size: 10px; }
          .offline-badge { background: #ff9800; color: white; padding: 2px 6px; font-size: 10px; }
        </style>
      </head>
      <body>
        <div class="header">
          <div class="shop-name">${this.shopName}</div>
          <div>POS Receipt</div>
          ${isOffline ? '<span class="offline-badge">OFFLINE</span>' : ''}
        </div>

        <div class="divider"></div>

        <div>
          <strong>Order:</strong> ${order.orderNumber || order.offlineOrderId}<br>
          <strong>Date:</strong> ${new Date().toLocaleString('en-IN')}<br>
          ${this.customerName ? `<strong>Customer:</strong> ${this.customerName}<br>` : ''}
          ${this.customerPhone ? `<strong>Phone:</strong> ${this.customerPhone}<br>` : ''}
        </div>

        <div class="divider"></div>

        <table>
          <thead>
            <tr>
              <th style="text-align:left;">Item</th>
              <th style="text-align:center;">Qty</th>
              <th style="text-align:right;">Amount</th>
            </tr>
          </thead>
          <tbody>
            ${items}
          </tbody>
        </table>

        <div class="divider"></div>

        <table>
          <tr class="total-row">
            <td>TOTAL</td>
            <td style="text-align:right;">₹${this.totalAmount.toFixed(0)}</td>
          </tr>
        </table>

        <div class="divider"></div>

        <div style="text-align:center;">
          <strong>Payment: ${this.getPaymentLabel(this.selectedPaymentMethod)}</strong>
        </div>

        <div class="footer">
          <div class="divider"></div>
          Thank you for your purchase!<br>
          Visit again
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
   * Manual sync trigger
   */
  async manualSync(): Promise<void> {
    if (!this.syncStatus.isOnline) {
      this.swal.warning('Offline', 'Cannot sync while offline');
      return;
    }

    this.swal.loading('Syncing...');

    try {
      await this.syncService.forceSyncNow(this.shopId);
      await this.loadProducts();
      this.swal.close();
      this.swal.success('Synced', 'Data synchronized successfully');
    } catch (error) {
      this.swal.close();
      this.swal.error('Sync Failed', 'Failed to sync data');
    }
  }

  /**
   * Play beep sound
   */
  private playBeep(success: boolean): void {
    try {
      const context = new AudioContext();
      const oscillator = context.createOscillator();
      const gainNode = context.createGain();

      oscillator.connect(gainNode);
      gainNode.connect(context.destination);

      oscillator.frequency.value = success ? 800 : 300;
      oscillator.type = 'sine';

      gainNode.gain.value = 0.1;

      oscillator.start();
      setTimeout(() => oscillator.stop(), success ? 100 : 200);
    } catch (e) {
      // Audio not supported
    }
  }

  /**
   * Toggle customer form
   */
  toggleCustomerForm(): void {
    this.showCustomerForm = !this.showCustomerForm;
  }
}
