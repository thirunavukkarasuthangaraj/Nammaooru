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
    lastProductSync: null,
    isSyncing: false
  };

  // UI state
  isLoading: boolean = true;
  showCustomerForm: boolean = false;

  // Language toggle
  showTamil: boolean = false;

  // Quick Edit state
  editingProduct: CachedProduct | null = null;
  editPrice: number = 0;
  editMrp: number = 0;
  editStock: number = 0;
  editBarcode: string = '';
  isSavingEdit: boolean = false;

  // Quick Add Custom Product state
  showQuickAddDialog: boolean = false;
  customProductName: string = '';
  customProductPrice: number = 0;
  customProductMrp: number = 0;
  customProductQty: number = 1;
  private customProductIdCounter: number = -1; // Negative IDs for custom products

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
          // Save shop name to localStorage for offline receipt use
          localStorage.setItem('shop_name', this.shopName);
          console.log('POS Billing - Shop loaded:', this.shopId, this.shopName);
        }
      });

    // Also try immediate value from context
    const currentShop = this.shopContext.getCurrentShop();
    if (currentShop) {
      this.shopId = currentShop.id;
      this.shopName = currentShop.name || currentShop.businessName || 'My Shop';
      // Save shop name to localStorage for offline receipt use
      localStorage.setItem('shop_name', this.shopName);
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

          // Save to local cache immediately (fast)
          await this.offlineStorage.saveProducts(this.products, this.shopId);
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
      originalPrice: p.originalPrice || p.mrp || p.price || 0,  // MRP for discount calculation
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

    const mrp = product.originalPrice || product.price;
    const discount = mrp - product.price;

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
        mrp: mrp,
        total: product.price,
        discount: discount
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
    this.totalMrp = this.cart.reduce((sum, item) => sum + (item.mrp * item.quantity), 0);
    this.totalDiscount = this.totalMrp - this.subtotal;
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
        const offlineMsg = result.offline ? ' (Saved offline - will sync when online)' : '';

        this.swal.success(
          'Bill Created',
          `Order ${result.order?.orderNumber || ''} - ₹${this.totalAmount.toFixed(0)}${offlineMsg}`
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
      // Show Tamil name below English name if available
      const nameHtml = tamilName
        ? `${englishName}<br><span style="font-size: 9px; color: #333;">${tamilName}</span>`
        : englishName;
      // Show MRP with strikethrough if there's discount
      const rateHtml = hasDiscount
        ? `<span style="text-decoration: line-through; color: #000; font-size: 9px; font-weight: 900;">${mrp}</span><br>${rate}`
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
          <span style="font-weight: 700;">MRP Total</span>
          <span style="text-decoration: line-through; color: #000; font-weight: 900;">₹${this.totalMrp.toFixed(0)}</span>
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

    this.swal.loading('Syncing pending data...');

    try {
      // Sync pending orders
      const orderSyncResult = await this.syncService.syncPendingOrders();
      console.log('Order sync result:', orderSyncResult);

      // Sync pending product edits
      const editSyncResult = await this.syncService.syncPendingEdits();
      console.log('Edit sync result:', editSyncResult);

      // Refresh products
      await this.loadProducts();
      this.swal.close();

      const totalSynced = orderSyncResult.synced + editSyncResult.synced;
      const totalFailed = orderSyncResult.failed + editSyncResult.failed;

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

  /**
   * Open quick edit dialog for a product
   */
  openQuickEdit(product: CachedProduct, event: Event): void {
    event.stopPropagation(); // Prevent adding to cart
    this.editingProduct = product;
    this.editPrice = product.price;
    this.editMrp = product.originalPrice || product.price;
    this.editStock = product.stock;
    // Use barcode if available, otherwise fallback to SKU
    this.editBarcode = product.barcode || product.sku || '';
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

    // Validate duplicate barcode (check local products)
    if (this.editBarcode && this.editBarcode.trim() !== '') {
      const duplicateProduct = this.products.find(p =>
        p.id !== this.editingProduct!.id &&
        p.barcode &&
        p.barcode.toLowerCase() === this.editBarcode.trim().toLowerCase()
      );
      if (duplicateProduct) {
        this.swal.error('Duplicate Barcode', `Barcode "${this.editBarcode}" already exists for product "${duplicateProduct.name}". Please use a unique barcode.`);
        return;
      }
    }

    this.isSavingEdit = true;

    const productId = this.editingProduct.id;
    const updateData = {
      price: this.editPrice,
      originalPrice: this.editMrp,
      stockQuantity: this.editStock,
      barcode: this.editBarcode
    };

    // Store previous values for potential rollback
    const previousValues = {
      price: this.editingProduct.price,
      originalPrice: this.editingProduct.originalPrice,
      stockQuantity: this.editingProduct.stock,
      barcode: this.editingProduct.barcode
    };

    try {
      // Try API call first (even if navigator.onLine is true, network might be down)
      if (navigator.onLine) {
        try {
          // Online mode - call API
          await this.http.patch<any>(
            `${this.apiUrl}/shop-products/${productId}/quick-update`,
            updateData
          ).toPromise();

          // Update succeeded - update local data
          await this.updateLocalProductData(productId, updateData);
          this.swal.success('Updated', 'Product updated successfully');
          this.closeQuickEdit();
          return;
        } catch (apiError) {
          // API failed - fall through to offline save
          console.warn('API call failed, saving offline:', apiError);
        }
      }

      // Offline mode OR API failed - save to offline edits queue
      const offlineEdit: OfflineEdit = {
        editId: this.offlineStorage.generateOfflineEditId(),
        productId: productId,
        shopId: this.shopId,
        changes: {
          price: this.editPrice,
          originalPrice: this.editMrp,
          stockQuantity: this.editStock,
          barcode: this.editBarcode
        },
        previousValues: previousValues,
        createdAt: new Date().toISOString(),
        synced: false
      };

      // Save to offline edits queue
      await this.offlineStorage.saveOfflineEdit(offlineEdit);

      // Update local product immediately (optimistic update)
      await this.updateLocalProductData(productId, updateData);

      // Update local cache in IndexedDB
      await this.offlineStorage.updateLocalProduct(productId, {
        price: this.editPrice,
        originalPrice: this.editMrp,
        stock: this.editStock,
        barcode: this.editBarcode
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
      this.products[productIndex].barcode = updateData.barcode;
    }

    // Update filtered products
    const filteredIndex = this.filteredProducts.findIndex(p => p.id === productId);
    if (filteredIndex !== -1) {
      this.filteredProducts[filteredIndex].price = updateData.price;
      this.filteredProducts[filteredIndex].originalPrice = updateData.originalPrice;
      this.filteredProducts[filteredIndex].stock = updateData.stockQuantity;
      this.filteredProducts[filteredIndex].barcode = updateData.barcode;
    }

    // Update cart if product is in cart
    const cartItem = this.cart.find(item => item.product.id === productId);
    if (cartItem) {
      cartItem.product.price = updateData.price;
      cartItem.product.originalPrice = updateData.originalPrice;
      cartItem.product.stock = updateData.stockQuantity;
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

    // Add to cart
    this.cart.push({
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
}
