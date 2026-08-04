import { Component, OnInit, OnDestroy, AfterViewInit, ViewChild, ElementRef } from '@angular/core';
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
import { LabelTemplateService } from '../../../../core/services/label-template.service';
import { LabelPrintService } from '../../../../core/services/label-print.service';
import {
  LabelDesign,
  LabelProductData,
  LabelTemplate,
  defaultLabelTemplate,
  templateWithFieldsShown
} from '../../../../core/models/label-template.model';
// @ts-ignore - qrcode library doesn't have proper type definitions
import * as QRCode from 'qrcode';

interface CartItem {
  product: CachedProduct;
  quantity: number;
  unitPrice: number;
  mrp: number;  // MRP price
  total: number;
  discount: number;  // Discount per item (mrp - unitPrice)
}

interface CustomField {
  label: string;
  value: string;
  enabled: boolean;
  position: 'header' | 'footer';  // Where to show in receipt
}

interface BillSettings {
  // Shop Header Info
  shopName: string;
  shopPhone: string;
  shopAddress: string;
  gstNumber: string;
  fssaiNumber: string;
  fssaiName: string;

  // Bill Format
  dateFormat: 'DD/MM/YYYY' | 'MM/DD/YYYY' | 'YYYY-MM-DD';
  billNumberPrefix: string;
  showBillNumber: boolean;
  paperWidth: '58mm' | '80mm' | 'A4';

  // Font Sizes (in pixels)
  headerFontSize: number;  // default: 16
  bodyFontSize: number;    // default: 12
  footerFontSize: number;  // default: 10

  // Show/Hide Elements - Header
  showShopName: boolean;
  showShopPhone: boolean;
  showShopAddress: boolean;
  showGstNumber: boolean;
  showFssaiInfo: boolean;
  showDateTime: boolean;
  showCustomerDetails: boolean;
  showThankYouMessage: boolean;

  // Show/Hide Elements - Item Details
  showItemSku: boolean;
  showItemBarcode: boolean;
  showItemMrp: boolean;
  showItemDiscount: boolean;
  showItemTax: boolean;

  // Show/Hide Elements - Summary
  showSubtotal: boolean;
  showTotalSavings: boolean;
  showTaxBreakdown: boolean;
  showPaymentMethod: boolean;

  // Receipt Language
  showEnglish: boolean;
  showTamil: boolean;

  // Footer
  thankYouMessage: string;
  footerNote: string;

  // Separator Style
  separatorStyle: 'solid' | 'dashed' | 'dotted' | 'none';

  // UPI Payment
  upiId: string;
  showUpiQrCode: boolean;

  // Custom Fields (user can add their own fields)
  customFields: CustomField[];

  // Section Order (for reordering receipt sections)
  sectionOrder: string[];
}

@Component({
  selector: 'app-pos-billing',
  templateUrl: './pos-billing.component.html',
  styleUrls: ['./pos-billing.component.scss']
})
export class PosBillingComponent implements OnInit, OnDestroy, AfterViewInit {
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
  // Full filtered list stays in memory; only `displayedProducts` is rendered.
  // Rendering the whole catalog (~2500 cards) freezes the browser ("Page Unresponsive").
  private _filteredProducts: CachedProduct[] = [];
  displayedProducts: CachedProduct[] = [];
  private readonly DISPLAY_PAGE_SIZE = 50;
  private displayLimit = 50;
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
  // O(1) lookup for template bindings — rebuilt in calculateTotals(). Template
  // methods run for every rendered card on every change-detection cycle, so
  // they must not scan the cart array.
  private cartIndex = new Map<number, CartItem>();
  cartProducts: CachedProduct[] = [];
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
  customerEmail: string = '';
  orderNotes: string = '';

  // Saved-customer autocomplete (suggestions from past bills, matched by phone or name)
  customerSuggestions: any[] = [];
  showCustomerSuggestions: boolean = false;
  private customerSearchTimer: any = null;

  // Last bill created - needed to send it via WhatsApp/email
  lastOrder: any = null;
  sendingWhatsAppBill: boolean = false;
  sendingEmailBill: boolean = false;

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
  // Delta sync: stale-cache refreshes fetch only changed products; a heavy full
  // re-download happens at most once a day (catches hard-deleted rows the delta can't see)
  private readonly POS_FULL_SYNC_KEY = 'pos_products_last_full_sync';
  private readonly FULL_SYNC_VALIDITY_MS = 24 * 60 * 60 * 1000; // 24 hours
  private readonly DELTA_OVERLAP_MS = 2 * 60 * 1000; // overlap to absorb client/server clock skew
  // Throttle background image re-caching so opening POS doesn't re-scan all images every time
  private readonly POS_IMAGES_CACHED_KEY = 'pos_images_last_cached';
  private readonly IMAGE_CACHE_VALIDITY_MS = 60 * 60 * 1000; // 1 hour

  // UI state
  isLoading: boolean = true;
  showCustomerModal: boolean = false;

  // Language toggle
  showTamil: boolean = false;

  // Receipt language settings (saved to localStorage)
  showEnglishOnReceipt: boolean = true;
  showTamilOnReceipt: boolean = true;

  // Bill Settings Dialog
  showBillSettingsDialog: boolean = false;
  billSettings: BillSettings = {
    // Shop Header Info
    shopName: '',
    shopPhone: '',
    shopAddress: '',
    gstNumber: '',
    fssaiNumber: '',
    fssaiName: '',
    // Bill Format
    dateFormat: 'DD/MM/YYYY',
    billNumberPrefix: '',
    showBillNumber: true,
    paperWidth: '80mm',
    // Font Sizes
    headerFontSize: 16,
    bodyFontSize: 12,
    footerFontSize: 10,
    // Show/Hide - Header
    showShopName: true,
    showShopPhone: true,
    showShopAddress: false,
    showGstNumber: false,
    showFssaiInfo: false,
    showDateTime: true,
    showCustomerDetails: true,
    showThankYouMessage: true,
    // Show/Hide - Item Details
    showItemSku: false,
    showItemBarcode: false,
    showItemMrp: true,
    showItemDiscount: true,
    showItemTax: false,
    // Show/Hide - Summary
    showSubtotal: true,
    showTotalSavings: true,
    showTaxBreakdown: false,
    showPaymentMethod: true,
    // Language
    showEnglish: true,
    showTamil: true,
    // Footer
    thankYouMessage: 'Thank you for your order!',
    footerNote: '',
    // Separator
    separatorStyle: 'dashed',
    // UPI Payment
    upiId: '',
    showUpiQrCode: false,
    // Custom Fields
    customFields: [
      { label: '', value: '', enabled: false, position: 'header' },
      { label: '', value: '', enabled: false, position: 'header' },
      { label: '', value: '', enabled: false, position: 'footer' },
      { label: '', value: '', enabled: false, position: 'footer' }
    ],
    // Section Order
    sectionOrder: ['header', 'billInfo', 'items', 'summary', 'payment', 'qrCode', 'footer']
  };

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

  // Label Print state (design comes from the shared Label Designer template)
  labelQuantity: number = 1;
  showLabelConfigDialog: boolean = false;
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
    private shopContext: ShopContextService,
    private labelTemplateService: LabelTemplateService,
    private labelPrintService: LabelPrintService
  ) {}

  /**
   * All assignments to filteredProducts go through this setter so the
   * rendered window (displayedProducts) is always capped at displayLimit.
   */
  get filteredProducts(): CachedProduct[] {
    return this._filteredProducts;
  }

  set filteredProducts(list: CachedProduct[]) {
    this._filteredProducts = list;
    this.displayLimit = this.DISPLAY_PAGE_SIZE;
    this.updateDisplayedProducts();
  }

  private updateDisplayedProducts(): void {
    this.displayedProducts = this._filteredProducts.slice(0, this.displayLimit);
  }

  get hasMoreProducts(): boolean {
    return this._filteredProducts.length > this.displayLimit;
  }

  get remainingProductsCount(): number {
    return Math.max(this._filteredProducts.length - this.displayLimit, 0);
  }

  loadMoreProducts(): void {
    this.displayLimit += this.DISPLAY_PAGE_SIZE;
    this.updateDisplayedProducts();
  }

  ngOnInit(): void {
    this.loadShopInfo();
    this.loadLanguagePreference();
    this.loadReceiptLanguageSettings();
    this.loadBillSettings();
    this.initSyncStatus();
    this.initSearch();
    this.initBarcodeScanner();
    this.loadProducts();

    // Check if products were added while away - force reload from IndexedDB
    this.checkForProductChanges();

    this.autoSyncOnStartup();
  }

  /**
   * The 'online' listener only fires on a network transition, so a PC booted
   * with internet already up never auto-syncs — catch that case on page open.
   */
  private async autoSyncOnStartup(): Promise<void> {
    if (!navigator.onLine) return;

    try {
      await this.syncService.updatePendingCount();
      const status = this.syncService.getCurrentStatus();
      const pending = status.pendingOrders + status.pendingEdits + status.pendingProductCreations;
      if (pending === 0) return;

      console.log(`Startup sync: ${pending} pending offline record(s) found, syncing...`);
      // Same guarded sequence as the online listener: edits -> creations -> orders
      const { synced } = await this.syncService.runSyncSequence();

      if (synced > 0) {
        await this.loadProducts();
        this.swal.toast(`${synced} offline record(s) synced to server`, 'success');
      }
    } catch (error) {
      console.error('Startup sync failed (will retry on manual sync):', error);
    }
  }

  /**
   * Check if products were added/changed while user was on another screen
   * This handles cases where ngOnInit doesn't re-run (component reuse)
   */
  private checkForProductChanges(): void {
    const productsChanged = localStorage.getItem('pos_products_changed');
    if (productsChanged === 'true') {
      console.log('POS: Products were changed, reloading from IndexedDB...');
      localStorage.removeItem('pos_products_changed');
      // Force reload from IndexedDB to pick up new products
      this.loadProducts();
    }
  }

  ngAfterViewInit(): void {
    // Auto-focus search input for immediate product search/barcode scan
    setTimeout(() => {
      if (this.searchInput?.nativeElement) {
        this.searchInput.nativeElement.focus();
      }
    }, 300);
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
   * Close the label settings dialog. The label data fields (net qty, PKD, EXP)
   * bind live; the design itself is managed in the shared Label Designer.
   */
  saveLabelConfig(): void {
    this.showLabelConfigDialog = false;
    this.swal.success('Saved', 'Label data saved for printing');
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
   * Load bill settings from localStorage
   */
  private loadBillSettings(): void {
    const saved = localStorage.getItem('pos_bill_settings');
    if (saved) {
      try {
        const settings = JSON.parse(saved);
        this.billSettings = { ...this.billSettings, ...settings };
        // Sync language settings with existing receipt language flags
        this.showEnglishOnReceipt = this.billSettings.showEnglish;
        this.showTamilOnReceipt = this.billSettings.showTamil;
      } catch (e) {
        console.warn('Failed to parse saved bill settings:', e);
      }
    }
  }

  /**
   * Open bill settings dialog
   */
  openBillSettingsDialog(): void {
    // Pre-fill shop info from context if not already set
    if (!this.billSettings.shopName) {
      this.billSettings.shopName = this.shopName || '';
    }
    // Pre-fill from shop context if available
    const currentShop = this.shopContext.getCurrentShop();
    if (currentShop) {
      if (!this.billSettings.shopName) {
        this.billSettings.shopName = currentShop.name || currentShop.businessName || '';
      }
      if (!this.billSettings.shopPhone && (currentShop as any).phone) {
        this.billSettings.shopPhone = (currentShop as any).phone || '';
      }
    }
    this.showBillSettingsDialog = true;
  }

  /**
   * Close bill settings dialog without saving
   */
  closeBillSettingsDialog(): void {
    this.showBillSettingsDialog = false;
    // Reload settings to discard unsaved changes
    this.loadBillSettings();
  }

  /**
   * Save bill settings to localStorage
   */
  saveBillSettings(): void {
    // Sync language settings
    this.showEnglishOnReceipt = this.billSettings.showEnglish;
    this.showTamilOnReceipt = this.billSettings.showTamil;

    localStorage.setItem('pos_bill_settings', JSON.stringify(this.billSettings));
    this.showBillSettingsDialog = false;
    this.swal.success('Saved', 'Bill settings saved');
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
          // Filter out creations that are already in the cache (by matching tempProductId, barcode, or name)
          const newCreations = pendingCreations.filter(creation => {
            const creationName = (creation.name || creation.customName || '').toLowerCase();
            const creationBarcode = (creation.barcode1 || '').toLowerCase();
            const creationTempId = creation.tempProductId;
            return !cachedProducts.some(p => {
              // Match by tempProductId (most reliable for edited offline products)
              const tempIdMatch = creationTempId && p.id === creationTempId;
              // Match by barcode (handles renamed products)
              const barcodeMatch = creationBarcode && p.barcode1 && p.barcode1.toLowerCase() === creationBarcode;
              // Match by name
              const nameMatch = p.name.toLowerCase() === creationName;
              return tempIdMatch || barcodeMatch || nameMatch;
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

        // Cache product images to IndexedDB for offline use.
        // Throttled: re-scanning ~2500 images on every POS open is wasteful, so only
        // run if we haven't cached within the last hour (server-refresh path caches fresh ones anyway).
        if (this.products.length > 0) {
          const lastImgCache = parseInt(localStorage.getItem(this.POS_IMAGES_CACHED_KEY) || '0', 10);
          if (Date.now() - lastImgCache > this.IMAGE_CACHE_VALIDITY_MS) {
            this.cacheProductImagesToIndexedDB(this.products);
            localStorage.setItem(this.POS_IMAGES_CACHED_KEY, Date.now().toString());
          }
        }

        // Sync from server if: cache is stale OR no active products found
        if (navigator.onLine) {
          const lastSync = localStorage.getItem(this.POS_CACHE_TIMESTAMP_KEY);
          const lastSyncTime = lastSync ? parseInt(lastSync, 10) : 0;
          const cacheAge = Date.now() - lastSyncTime;
          const hasNoActiveProducts = this.products.length === 0;

          if (hasNoActiveProducts) {
            // No active products - force load from server immediately
            console.log('POS: No active products in cache, loading from server...');
            this.loadProductsFromServer();
            return;
          } else if (cacheAge > this.CACHE_VALIDITY_MS) {
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
  private async loadProductsFromServer(): Promise<void> {
    const pageSize = 500;
    const rawProducts: any[] = [];
    let page = 0;
    let totalPages = 1;

    try {
      while (page < totalPages) {
        const response: any = await this.http.get<any>(
          `${this.apiUrl}/shop-products/my-products?page=${page}&size=${pageSize}`
        ).pipe(takeUntil(this.destroy$)).toPromise();

        const data = response?.data;
        let content: any[] = [];
        if (data?.content) {
          content = data.content;
          totalPages = data.totalPages || 1;
        } else if (Array.isArray(data)) {
          content = data;
          totalPages = 1;
        }
        if (content.length === 0) break;
        rawProducts.push(...content);

        // Progressive render: show products as they arrive so user doesn't see a frozen spinner
        const mappedSoFar = rawProducts.map((p: any) => this.mapProduct(p));
        this.products = mappedSoFar.filter(p => p.isAvailable !== false && (p as any).status !== 'INACTIVE');
        this.filteredProducts = this.sortProductsWithCartFirst(this.products);

        page++;
        if (page > 200) {
          console.warn('loadProductsFromServer: page guard hit (200) — stopping');
          break;
        }
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

      const allProducts = rawProducts.map((p: any) => this.mapProduct(p));
      this.isLoading = false;
      console.log(`Loaded ${this.products.length} active products across ${page} page(s) (${allProducts.length} total)`);

      // Save ALL products (including inactive) to IndexedDB for offline use
      await this.offlineStorage.saveProducts(allProducts, this.shopId);
      localStorage.setItem(this.POS_CACHE_TIMESTAMP_KEY, Date.now().toString());
      localStorage.setItem(this.POS_FULL_SYNC_KEY, Date.now().toString());

      // Cache images in background (non-blocking)
      this.cacheProductImages().then(() => {
        console.log('Background image caching complete');
      }).catch(err => console.warn('Image caching error:', err));
    } catch (error) {
      console.error('Failed to load products:', error);
      this.swal.error('Error', 'Failed to load products');
      this.isLoading = false;
    }
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
   * Sync products in background.
   * Normally fetches ONLY products changed since the last sync (delta) — re-downloading
   * the whole ~2500-product catalog every 5 minutes caused latency and screen hangs.
   * A full re-download still runs at most once a day to catch hard deletes.
   */
  private async syncProductsInBackground(): Promise<void> {
    const lastSync = parseInt(localStorage.getItem(this.POS_CACHE_TIMESTAMP_KEY) || '0', 10);
    const lastFullSync = parseInt(localStorage.getItem(this.POS_FULL_SYNC_KEY) || '0', 10);

    if (!lastSync || Date.now() - lastFullSync > this.FULL_SYNC_VALIDITY_MS) {
      return this.fullSyncInBackground();
    }

    const updatedAfter = Math.max(0, lastSync - this.DELTA_OVERLAP_MS);
    const pageSize = 500;
    const rawProducts: any[] = [];
    let page = 0;
    let totalPages = 1;

    try {
      while (page < totalPages) {
        const response: any = await this.http.get<any>(
          `${this.apiUrl}/shop-products/my-products?page=${page}&size=${pageSize}&updatedAfter=${updatedAfter}`
        ).pipe(takeUntil(this.destroy$)).toPromise();

        const data = response?.data;
        let content: any[] = [];
        if (data?.content) {
          content = data.content;
          totalPages = data.totalPages || 1;
        } else if (Array.isArray(data)) {
          content = data;
          totalPages = 1;
        }
        if (content.length === 0) break;
        rawProducts.push(...content);

        page++;
        if (page > 200) {
          console.warn('syncProductsInBackground: page guard hit (200) — stopping');
          break;
        }
      }

      localStorage.setItem(this.POS_CACHE_TIMESTAMP_KEY, Date.now().toString());

      if (rawProducts.length === 0) {
        console.log('Delta sync: no product changes since last sync');
        return;
      }

      const changed = rawProducts.map((p: any) => this.mapProduct(p));

      // put() upserts by id — only the changed rows are written, cache stays intact
      await this.offlineStorage.putProducts(changed);

      // Merge into the on-screen list: upsert active items, drop deactivated ones
      const byId = new Map(this.products.map(p => [p.id, p]));
      for (const p of changed) {
        const isActive = p.isAvailable !== false && (p as any).status !== 'INACTIVE';
        if (isActive) {
          byId.set(p.id, p);
        } else {
          byId.delete(p.id);
        }
      }
      this.products = Array.from(byId.values());
      this.filterProducts(this.searchTerm);

      console.log(`Delta sync: merged ${changed.length} changed product(s)`);
    } catch (error) {
      console.warn('Delta sync failed:', error);
    }
  }

  /**
   * Full background re-download of the catalog (heavy — runs at most once a day
   * or when there is no sync watermark yet)
   */
  private async fullSyncInBackground(): Promise<void> {
    const pageSize = 500;
    const rawProducts: any[] = [];
    let page = 0;
    let totalPages = 1;

    try {
      while (page < totalPages) {
        const response: any = await this.http.get<any>(
          `${this.apiUrl}/shop-products/my-products?page=${page}&size=${pageSize}`
        ).pipe(takeUntil(this.destroy$)).toPromise();

        const data = response?.data;
        let content: any[] = [];
        if (data?.content) {
          content = data.content;
          totalPages = data.totalPages || 1;
        } else if (Array.isArray(data)) {
          content = data;
          totalPages = 1;
        }
        if (content.length === 0) break;
        rawProducts.push(...content);

        page++;
        if (page > 200) {
          console.warn('fullSyncInBackground: page guard hit (200) — stopping');
          break;
        }
      }

      const allProducts = rawProducts.map((p: any) => this.mapProduct(p));
      const activeProducts = allProducts.filter(p =>
        p.isAvailable !== false && (p as any).status !== 'INACTIVE'
      );

      // Update cache with ALL products (including inactive) for My Products page
      await this.offlineStorage.saveProducts(allProducts, this.shopId);
      localStorage.setItem(this.POS_CACHE_TIMESTAMP_KEY, Date.now().toString());
      localStorage.setItem(this.POS_FULL_SYNC_KEY, Date.now().toString());

      // Update UI with only active products
      if (activeProducts.length !== this.products.length) {
        this.products = activeProducts;
        this.filteredProducts = this.sortProductsWithCartFirst(this.products);
      }

      console.log(`Background sync complete: ${activeProducts.length} active products (${allProducts.length} total) across ${page} page(s)`);
    } catch (error) {
      console.warn('Background sync failed:', error);
    }
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
    const cartItem = this.cartIndex.get(product.id);
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

    // Dedupe scans within 1s — some scanners re-fire faster than 500ms
    // and the Enter key from some models triggers two events
    if (barcode === this.lastScannedBarcode && (now - this.lastScanTime) < 1000) {
      return;
    }

    this.lastScannedBarcode = barcode;
    this.lastScanTime = now;

    // Find in loaded products by barcode, barcode1, barcode2, barcode3, or SKU.
    // O(n) lookup over in-memory IndexedDB-backed list — instant for up to ~10k products.
    const product = this.products.find(p =>
      p.barcode === barcode ||
      p.barcode1 === barcode ||
      p.barcode2 === barcode ||
      p.barcode3 === barcode ||
      p.sku === barcode
    );

    if (product) {
      if (this.activeTab === 'quick') {
        // Show the scanned product immediately. Bypass filterProducts() entirely —
        // assigning a 1-item array is instantly rendered by Angular's next CD cycle,
        // and we avoid scanning the whole products array + re-sorting.
        this.searchTerm = barcode;
        this.filteredProducts = [product];
      } else {
        this.addToCart(product);
      }
      this.playBeep(true);
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
    // Out of stock: offer to restock on the spot and continue billing
    if (product.trackInventory && product.stock <= 0) {
      this.promptRestockAndAdd(product);
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
   * Out-of-stock product during billing: ask for the new stock quantity,
   * update it (server or offline queue) and add the product to the cart.
   */
  async promptRestockAndAdd(product: CachedProduct): Promise<void> {
    const { value } = await this.swal.prompt(
      'Out of Stock',
      `${product.name} is out of stock. Enter new stock quantity to update and continue billing:`,
      'number'
    );
    if (!value) return;
    const newStock = parseInt(String(value), 10);
    if (isNaN(newStock) || newStock <= 0) {
      this.swal.error('Invalid Stock', 'Enter a stock quantity greater than 0');
      return;
    }
    const updated = await this.updateProductStock(product, newStock);
    if (updated) {
      this.addToCart(product);
    }
  }

  /**
   * Update just the stock of a product: server first, offline queue on
   * network failure, then local caches so POS reflects it immediately.
   */
  private async updateProductStock(product: CachedProduct, newStock: number): Promise<boolean> {
    const productId = product.id;
    try {
      const isOfflineProduct = productId < 0;
      if (navigator.onLine && !isOfflineProduct) {
        try {
          const response: any = await this.http.patch<any>(
            `${this.apiUrl}/shop-products/${productId}/quick-update`,
            { stockQuantity: newStock }
          ).toPromise();
          if (response?.statusCode && response.statusCode !== '0000') {
            this.swal.error('Error', response.message || 'Failed to update stock');
            return false;
          }
        } catch (apiError: any) {
          const isNetworkError = !apiError?.status || apiError.status === 0;
          if (!isNetworkError) {
            this.swal.error('Error', apiError?.error?.message || apiError?.message || 'Failed to update stock');
            return false;
          }
          await this.queueOfflineStockEdit(product, newStock);
        }
      } else {
        await this.queueOfflineStockEdit(product, newStock);
      }

      // Optimistic local update everywhere POS reads stock from
      product.stock = newStock;
      const idx = this.products.findIndex(p => p.id === productId);
      if (idx !== -1) this.products[idx].stock = newStock;
      const fidx = this.filteredProducts.findIndex(p => p.id === productId);
      if (fidx !== -1) this.filteredProducts[fidx].stock = newStock;
      await this.offlineStorage.updateLocalProduct(productId, { stock: newStock })
        .catch(err => console.warn('Failed to update stock in cache:', err));
      localStorage.setItem(this.POS_CACHE_TIMESTAMP_KEY, Date.now().toString());

      this.swal.toast(`Stock updated: ${product.name} - ${newStock}`, 'success');
      return true;
    } catch (error) {
      console.error('Stock update failed:', error);
      this.swal.error('Error', 'Failed to update stock');
      return false;
    }
  }

  private async queueOfflineStockEdit(product: CachedProduct, newStock: number): Promise<void> {
    const offlineEdit: OfflineEdit = {
      editId: this.offlineStorage.generateOfflineEditId(),
      productId: product.id,
      shopId: this.shopId,
      changes: { stockQuantity: newStock },
      previousValues: { stockQuantity: product.stock },
      createdAt: new Date().toISOString(),
      synced: false
    };
    await this.offlineStorage.saveOfflineEdit(offlineEdit);
    if (product.id < 0) {
      await this.offlineStorage.applyEditToProductCreation(product.id, { stockQuantity: newStock });
    }
  }

  /**
   * Check if product is in cart
   */
  isInCart(product: CachedProduct): boolean {
    return this.cartIndex.has(product.id);
  }

  /**
   * Get quantity of product in cart
   */
  getCartQuantity(product: CachedProduct): number {
    const item = this.cartIndex.get(product.id);
    return item ? item.quantity : 0;
  }

  /**
   * Get products that are currently in the cart (for Quick Bill display).
   * Returns the cached array (rebuilt on cart change) — returning a fresh
   * array here forced Angular to rebuild the cart cards every CD cycle.
   */
  getCartProducts(): CachedProduct[] {
    return this.cartProducts;
  }

  /**
   * Get the price of a product in the cart
   */
  getCartItemPrice(product: CachedProduct): number {
    const item = this.cartIndex.get(product.id);
    return item ? item.unitPrice : product.price;
  }

  /**
   * Get the MRP of a product in the cart
   */
  getCartItemMrp(product: CachedProduct): number {
    const item = this.cartIndex.get(product.id);
    return item ? item.mrp : (product.originalPrice || product.price);
  }

  /**
   * Check if cart item price exceeds MRP
   */
  isPriceAboveMrp(product: CachedProduct): boolean {
    const item = this.cartIndex.get(product.id);
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

  setCartQuantityByProduct(product: CachedProduct, event: Event): void {
    const input = event.target as HTMLInputElement;
    const newQty = parseInt(input.value, 10);
    const item = this.cart.find(item => item.product.id === product.id);
    if (item && newQty > 0) {
      if (item.product.trackInventory && newQty > item.product.stock) {
        this.swal.warning('Stock Limit', `Only ${item.product.stock} available`);
        input.value = String(item.quantity);
        return;
      }
      item.quantity = newQty;
      item.total = item.quantity * item.unitPrice;
      this.calculateTotals();
    } else if (item && newQty <= 0) {
      this.removeFromCart(item);
    }
  }

  setCartItemQuantity(item: CartItem, event: Event): void {
    const input = event.target as HTMLInputElement;
    const newQty = parseInt(input.value, 10);
    if (newQty > 0) {
      if (item.product.trackInventory && newQty > item.product.stock) {
        this.swal.warning('Stock Limit', `Only ${item.product.stock} available`);
        input.value = String(item.quantity);
        return;
      }
      item.quantity = newQty;
      item.total = item.quantity * item.unitPrice;
      this.calculateTotals();
    } else if (newQty <= 0) {
      this.removeFromCart(item);
    }
  }

  setTempQty(product: CachedProduct, event: Event): void {
    const input = event.target as HTMLInputElement;
    const newQty = parseInt(input.value, 10);
    if (!isNaN(newQty) && newQty >= 0) {
      this.tempQtys.set(product.id, newQty);
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
          this.resetCart();
        }
      });
  }

  /**
   * Start a new bill - clears cart and resets customer info
   */
  startNewBill(): void {
    if (this.cart.length === 0) return;

    this.swal.confirm('Start New Bill', 'Clear current cart and start a new bill?', 'Yes, New Bill', 'Cancel')
      .then(result => {
        if (result.isConfirmed) {
          this.resetCart();
          this.swal.toast('Ready for new bill', 'success');
        }
      });
  }

  /**
   * Reset cart and customer info (internal method)
   */
  private resetCart(): void {
    this.cart = [];
    this.calculateTotals();
    this.customerName = '';
    this.customerPhone = '';
    this.customerEmail = '';
    this.orderNotes = '';
    this.lastOrder = null;
    // In Quick Bill mode, keep products list empty
    // In Browse mode, show all products
    if (this.activeTab !== 'quick') {
      this.filteredProducts = this.sortProductsWithCartFirst(this.products);
    } else {
      this.filteredProducts = [];
    }
  }

  /**
   * Calculate totals
   */
  private calculateTotals(): void {
    // Rebuild O(1) lookups used by template bindings (every cart mutation ends here)
    this.cartIndex = new Map(this.cart.map(item => [item.product.id, item]));
    this.cartProducts = this.cart.map(item => item.product);

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
      // Resolve any negative temp IDs to real server IDs (for offline-created products that have synced)
      const resolvedItems = await this.resolveCartProductIds();

      // Check if any items still have negative IDs (not yet synced)
      const unsyncedItems = resolvedItems.filter(item => item.shopProductId < 0);
      if (unsyncedItems.length > 0 && navigator.onLine) {
        // Try to sync pending product creations first
        console.log('Found unsynced products in cart, attempting sync...');
        await this.syncService.syncPendingProductCreations();
        // Re-resolve after sync
        const reResolvedItems = await this.resolveCartProductIds();
        const stillUnsynced = reResolvedItems.filter(item => item.shopProductId < 0);
        if (stillUnsynced.length > 0) {
          console.warn('Some products still have temp IDs after sync:', stillUnsynced);
        }
        resolvedItems.length = 0;
        resolvedItems.push(...reResolvedItems);
      }

      const orderData = {
        items: resolvedItems,
        paymentMethod: this.selectedPaymentMethod,
        customerName: this.customerName || undefined,
        customerPhone: this.customerPhone || undefined,
        customerEmail: this.customerEmail || undefined,
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

        // Remember the created order so it can be sent via WhatsApp afterwards.
        // Offline orders don't have a server id yet, so WhatsApp send stays disabled until synced.
        this.lastOrder = result.order;

        // Print receipt
        this.printReceipt(result.order);

        // Update local stock immediately (no need to reload all products)
        await this.updateLocalStockAfterBill();

        // Don't clear cart - allow adding more products and reprinting
        // User can click "New Bill" when they want to start fresh
      }
    } catch (error: any) {
      this.swal.close();
      console.error('Failed to create bill:', error);
      // Show the real reason (e.g. insufficient stock) instead of a generic message
      const message = error?.error?.message || error?.message || 'Failed to create bill';
      this.swal.error('Error', message);
    }
  }

  /**
   * Send the last generated bill to the customer on WhatsApp as a PDF.
   */
  async sendBillOnWhatsApp(): Promise<void> {
    if (!this.lastOrder) {
      this.swal.warning('No Bill Yet', 'Print a bill first before sending it on WhatsApp');
      return;
    }

    if (!this.lastOrder.id) {
      this.swal.warning('Not Synced Yet', 'This bill was saved offline and needs to sync before it can be sent on WhatsApp');
      return;
    }

    // Prefer the number typed in the form NOW — covers "billed first, added the
    // customer after printing". The order's own phone may be the shared walk-in
    // placeholder (90000 + shop id) when billed without a customer: never send to it.
    const isWalkInPlaceholder = (p: string) => /^90000\d{5}$/.test(p || '');
    let phone = [this.customerPhone, this.lastOrder.customerPhone]
      .find(p => p && !isWalkInPlaceholder(p)) || '';
    if (!phone) {
      const { value } = await this.swal.prompt(
        'Customer Phone Number',
        'Enter the customer\'s WhatsApp number to send the bill',
        'tel'
      );
      if (!value) return;
      phone = value;
    }

    this.sendingWhatsAppBill = true;
    this.swal.loading('Sending bill on WhatsApp...');

    try {
      // Prefer the name typed in the form NOW; the order's stored name may be the
      // "Walk-in Customer" placeholder when the bill was printed before adding the customer
      const orderName = this.lastOrder.customerName && !/walk-?in/i.test(this.lastOrder.customerName)
        ? this.lastOrder.customerName : '';
      await this.syncService.sendWhatsAppBill(this.lastOrder.id, phone, this.customerName || orderName);
      this.swal.close();
      this.swal.toast('Bill sent on WhatsApp', 'success');
    } catch (error: any) {
      this.swal.close();
      const message = error?.error?.message || error?.message || 'Failed to send bill on WhatsApp';
      this.swal.error('Error', message);
    } finally {
      this.sendingWhatsAppBill = false;
    }
  }

  /**
   * Send the last generated bill to the customer by email as a PDF.
   */
  async sendBillOnEmail(): Promise<void> {
    if (!this.lastOrder) {
      this.swal.warning('No Bill Yet', 'Print a bill first before emailing it');
      return;
    }

    if (!this.lastOrder.id) {
      this.swal.warning('Not Synced Yet', 'This bill was saved offline and needs to sync before it can be emailed');
      return;
    }

    // Use the email typed in the customer popup if present; ask only when missing
    let email = this.customerEmail || '';
    if (!email) {
      const { value } = await this.swal.prompt(
        'Customer Email',
        'Enter the customer\'s email address to send the bill',
        'email'
      );
      if (!value) return;
      email = value;
    }

    this.sendingEmailBill = true;
    this.swal.loading('Sending bill by email...');

    try {
      // Prefer the name typed in the form NOW; the order's stored name may be the
      // "Walk-in Customer" placeholder when the bill was printed before adding the customer
      const orderName = this.lastOrder.customerName && !/walk-?in/i.test(this.lastOrder.customerName)
        ? this.lastOrder.customerName : '';
      await this.syncService.sendEmailBill(this.lastOrder.id, email, this.customerName || orderName);
      this.swal.close();
      this.swal.toast('Bill sent by email', 'success');
    } catch (error: any) {
      this.swal.close();
      const message = error?.error?.message || error?.message || 'Failed to send bill by email';
      this.swal.error('Error', message);
    } finally {
      this.sendingEmailBill = false;
    }
  }

  /**
   * Print receipt (async for QR code generation)
   */
  async printReceipt(order: any): Promise<void> {
    const paperConfig = this.getPaperConfig(this.billSettings.paperWidth || '80mm');
    const receiptWindow = window.open('', '_blank', `width=${paperConfig.windowWidth},height=600`);
    if (!receiptWindow) return;

    // Show loading message while generating QR
    receiptWindow.document.write('<html><body style="display:flex;justify-content:center;align-items:center;height:100vh;font-family:sans-serif;"><p>Generating receipt...</p></body></html>');

    const receiptHtml = await this.generateReceiptHtml(order);
    receiptWindow.document.open();
    receiptWindow.document.write(receiptHtml);
    receiptWindow.document.close();

    setTimeout(() => {
      receiptWindow.onafterprint = () => receiptWindow.close();
      receiptWindow.print();
    }, 500);
  }

  /**
   * Get paper configuration based on paper width setting
   */
  private getPaperConfig(paperWidth: string): { pageSize: string; bodyWidth: string; maxWidth: string; windowWidth: number } {
    switch (paperWidth) {
      case '58mm':
        return { pageSize: '58mm auto', bodyWidth: '180px', maxWidth: '180px', windowWidth: 300 };
      case '80mm':
        return { pageSize: '80mm auto', bodyWidth: '260px', maxWidth: '260px', windowWidth: 350 };
      case 'A4':
        return { pageSize: 'A4', bodyWidth: '100%', maxWidth: '600px', windowWidth: 700 };
      default:
        return { pageSize: '80mm auto', bodyWidth: '260px', maxWidth: '260px', windowWidth: 350 };
    }
  }

  /**
   * Get separator style CSS based on setting
   */
  private getSeparatorStyle(style: string): string {
    switch (style) {
      case 'solid':
        return 'border-top: 1px solid #000; margin: 6px 0;';
      case 'dashed':
        return 'border-top: 1px dashed #000; margin: 6px 0;';
      case 'dotted':
        return 'border-top: 1px dotted #000; margin: 6px 0;';
      case 'none':
        return 'margin: 6px 0;';
      default:
        return 'border-top: 1px dashed #000; margin: 6px 0;';
    }
  }

  /**
   * Generate receipt HTML - supports 58mm, 80mm thermal paper and A4
   * Uses billSettings for customization (async for QR code generation)
   */
  private async generateReceiptHtml(order: any): Promise<string> {
    const bs = this.billSettings;
    const bodyFontSize = bs.bodyFontSize || 12;
    const headerFontSize = bs.headerFontSize || 16;
    const footerFontSize = bs.footerFontSize || 10;

    // Paper width configuration
    const paperConfig = this.getPaperConfig(bs.paperWidth || '80mm');

    // Generate QR code (works offline)
    let qrCodeDataUrl = '';
    if (bs.showUpiQrCode && bs.upiId) {
      const qrSize = bs.paperWidth === '58mm' ? 100 : 140;
      qrCodeDataUrl = await this.generateUpiQrCode(qrSize, this.totalAmount);
    }

    const items = this.cart.map(item => {
      const englishName = item.product.name || '';
      const tamilName = item.product.nameTamil || '';
      const rate = item.unitPrice || 0;
      const mrp = item.mrp || rate;
      // Build name HTML based on receipt language settings from billSettings
      let nameHtml = '';
      if (bs.showEnglish && bs.showTamil && tamilName && tamilName.trim() !== englishName.trim()) {
        // Both languages
        nameHtml = `${englishName}<br><span style="font-size: ${Math.max(bodyFontSize - 3, 8)}px; color: #000;">${tamilName}</span>`;
      } else if (bs.showEnglish) {
        // English only
        nameHtml = englishName;
      } else if (bs.showTamil && tamilName) {
        // Tamil only (use Tamil if available, fallback to English)
        nameHtml = tamilName;
      } else {
        // Fallback to English
        nameHtml = englishName;
      }
      return `
      <tr>
        <td style="font-size: ${bodyFontSize}px; padding: 2px 0; font-weight: 600; word-wrap: break-word; max-width: 60px;">${nameHtml}</td>
        <td style="font-size: ${bodyFontSize}px; text-align: right; padding: 2px 0; font-weight: 600; white-space: nowrap;">${mrp}</td>
        <td style="font-size: ${bodyFontSize}px; text-align: right; padding: 2px 0; font-weight: 600; white-space: nowrap;">${rate}</td>
        <td style="font-size: ${bodyFontSize}px; text-align: center; padding: 2px 0; font-weight: 700; white-space: nowrap;">${item.quantity}</td>
        <td style="font-size: ${bodyFontSize}px; text-align: right; padding: 2px 0; font-weight: 700; white-space: nowrap;">${item.total.toFixed(0)}</td>
      </tr>
    `;
    }).join('');

    const isOffline = order.offlineOrderId && !order.id;

    // Get shop name: billSettings first, then order, then localStorage, then component
    const storedShopName = localStorage.getItem('shop_name');
    const shopName = (bs.shopName && bs.shopName.trim()) ||
                     (order.shopName && order.shopName.trim()) ||
                     (storedShopName && storedShopName.trim()) ||
                     (this.shopName && this.shopName !== 'My Shop' ? this.shopName : null) ||
                     'Shop';
    const shopPhone = bs.shopPhone || '';
    const customerName = this.customerName || '';
    const customerPhone = this.customerPhone || '';

    // Format date based on billSettings
    const now = new Date();
    let formattedDate = '';
    switch (bs.dateFormat) {
      case 'MM/DD/YYYY':
        formattedDate = `${String(now.getMonth() + 1).padStart(2, '0')}/${String(now.getDate()).padStart(2, '0')}/${now.getFullYear()}`;
        break;
      case 'YYYY-MM-DD':
        formattedDate = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
        break;
      case 'DD/MM/YYYY':
      default:
        formattedDate = `${String(now.getDate()).padStart(2, '0')}/${String(now.getMonth() + 1).padStart(2, '0')}/${now.getFullYear()}`;
    }
    const formattedTime = now.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});

    // Bill number with prefix
    const billNumber = bs.billNumberPrefix
      ? `${bs.billNumberPrefix}${order.orderNumber || order.offlineOrderId}`
      : `#${order.orderNumber || order.offlineOrderId}`;

    console.log('Receipt - shopName sources:', {
      billSettings: bs.shopName,
      orderShopName: order.shopName,
      localStorage: storedShopName,
      thisShopName: this.shopName,
      resolved: shopName
    });

    // Get separator style
    const separatorStyle = this.getSeparatorStyle(bs.separatorStyle || 'dashed');

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Receipt - ${order.orderNumber || order.offlineOrderId}</title>
        <style>
          @page {
            size: ${paperConfig.pageSize};
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
            font-size: ${bodyFontSize}px;
            width: ${paperConfig.bodyWidth};
            max-width: ${paperConfig.maxWidth};
            margin: 0 auto;
            padding: 8px;
            line-height: 1.3;
          }
          .center { text-align: center; }
          .divider {
            ${separatorStyle}
          }
          .divider-solid {
            border-top: 1px solid #000;
            margin: 6px 0;
          }
          table { width: 100%; border-collapse: collapse; }
          .shop-name {
            font-family: 'Noto Sans Tamil', 'Latha', 'Tamil Sangam MN', Arial, sans-serif;
            font-size: ${headerFontSize}px;
            font-weight: 700;
            margin-bottom: 3px;
          }
          .shop-phone {
            font-size: ${Math.max(headerFontSize - 4, 10)}px;
            color: #000;
            font-weight: 700;
            margin-bottom: 2px;
          }
          .fssai-info {
            font-size: ${Math.max(footerFontSize, 8)}px;
            color: #000;
            margin-bottom: 2px;
          }
          .order-number {
            font-size: ${Math.max(bodyFontSize, 12)}px;
            font-weight: 700;
            margin: 4px 0;
          }
          .customer-name {
            font-size: ${bodyFontSize}px;
            font-weight: 700;
          }
          .customer-phone {
            font-size: ${Math.max(bodyFontSize - 2, 10)}px;
            color: #000;
          }
          .item-header th {
            font-size: ${Math.max(bodyFontSize - 2, 10)}px;
            padding: 4px 0;
            border-bottom: 1px solid #000;
            text-transform: uppercase;
            font-weight: 700;
          }
          .payment-badge {
            font-size: ${Math.max(bodyFontSize - 2, 10)}px;
            font-weight: 700;
            padding: 4px 8px;
            background: #f0f0f0;
            border-radius: 3px;
            display: inline-block;
            margin: 4px 0;
          }
          .footer-text {
            font-size: ${footerFontSize}px;
            color: #000;
            font-weight: 600;
            margin-top: 6px;
          }
          .offline-badge {
            background: #ff9800;
            color: white;
            padding: 2px 6px;
            font-size: ${Math.max(footerFontSize, 9)}px;
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
        ${bs.showShopName ? `<div class="center shop-name">${shopName}</div>` : ''}
        ${bs.showShopAddress && bs.shopAddress ? `<div class="center" style="font-size: ${Math.max(footerFontSize, 9)}px; color: #000; font-weight: 600;">${bs.shopAddress}</div>` : ''}
        ${bs.showShopPhone && shopPhone ? `<div class="center shop-phone">📞 ${shopPhone}</div>` : ''}
        ${bs.showGstNumber && bs.gstNumber ? `<div class="center" style="font-size: ${Math.max(footerFontSize, 9)}px;">GST: ${bs.gstNumber}</div>` : ''}
        ${bs.showFssaiInfo && bs.fssaiNumber ? `
          <div class="center fssai-info">
            FSSAI: ${bs.fssaiNumber}
            ${bs.fssaiName ? `<br>${bs.fssaiName}` : ''}
          </div>
        ` : ''}
        ${this.getCustomFieldsHtml('header', Math.max(footerFontSize, 9))}
        <div class="center" style="font-size: ${Math.max(footerFontSize, 9)}px; color: #000; font-weight: 600;">Order Receipt</div>
        <div class="divider"></div>

        ${bs.showBillNumber || bs.showDateTime ? `
        <div class="center order-number" style="margin-bottom: 4px;">
          ${[
            bs.showBillNumber ? billNumber : '',
            bs.showDateTime ? `${formattedDate} ${formattedTime}` : ''
          ].filter(Boolean).join(' | ')}
        </div>
        ` : ''}
        <div class="divider"></div>

        ${bs.showCustomerDetails && (customerName || customerPhone) ? `
        <div style="margin-bottom: 4px;">
          ${customerName ? `<div class="customer-name">${customerName}</div>` : ''}
          ${customerPhone ? `<div class="customer-phone">${customerPhone}</div>` : ''}
        </div>
        <div class="divider"></div>
        ` : ''}

        <table>
          <thead>
            <tr class="item-header">
              <th style="text-align: left;">ITEM</th>
              <th style="text-align: right;">MRP</th>
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

        <div class="flex-row" style="font-size: ${bodyFontSize}px; padding: 4px 0;">
          <span style="font-weight: 600;">Items: ${this.cart.length} (Qty: ${this.cart.reduce((sum, item) => sum + item.quantity, 0)})</span>
          <span style="font-weight: 700;">₹${this.totalAmount.toFixed(0)}</span>
        </div>

        ${this.totalDiscount > 0 ? `
        <div class="flex-row" style="font-size: ${bodyFontSize}px; padding: 2px 0;">
          <span style="font-weight: 600;">MRP Total</span>
          <span style="font-weight: 600;">₹${this.totalMrp.toFixed(0)}</span>
        </div>
        <div class="flex-row" style="font-size: ${bodyFontSize}px; padding: 2px 0;">
          <span style="font-weight: 600;">You Save</span>
          <span style="font-weight: 700;">₹${this.totalDiscount.toFixed(0)}</span>
        </div>
        ` : ''}

        <div class="flex-row" style="border-top: 1px solid #000; padding-top: 6px; margin-top: 4px;">
          <span style="font-size: ${headerFontSize}px; font-weight: 700;">TOTAL</span>
          <span style="font-size: ${headerFontSize + 2}px; font-weight: 700;">₹${this.totalAmount.toFixed(0)}</span>
        </div>

        ${bs.showPaymentMethod ? `
        <div class="divider"></div>
        <div class="center">
          <span class="payment-badge">
            ${this.selectedPaymentMethod === 'CASH_ON_DELIVERY' ? '💵 CASH' : this.selectedPaymentMethod === 'UPI' ? '📱 UPI' : '💳 CARD'}
          </span>
        </div>
        ` : ''}

        ${bs.showUpiQrCode && bs.upiId && qrCodeDataUrl ? `
        <div class="divider"></div>
        <div class="center" style="padding: 8px 0;">
          <div style="font-size: ${footerFontSize}px; margin-bottom: 4px; font-weight: 600;">Scan to Pay</div>
          <img src="${qrCodeDataUrl}"
               alt="UPI QR Code"
               style="width: ${bs.paperWidth === '58mm' ? '100px' : '140px'}; height: ${bs.paperWidth === '58mm' ? '100px' : '140px'}; margin: 4px 0;">
          <div style="font-size: ${Math.max(footerFontSize - 1, 7)}px; color: #000;">${bs.upiId}</div>
        </div>
        ` : ''}

        <div class="divider"></div>

        ${this.getCustomFieldsHtml('footer', footerFontSize)}

        ${bs.footerNote ? `
        <div class="center" style="font-size: ${footerFontSize}px; color: #000; font-weight: 600; margin: 4px 0;">
          ${bs.footerNote}
        </div>
        ` : ''}

        ${bs.showThankYouMessage ? `
        <div class="center footer-text">
          ${bs.thankYouMessage || 'Thank you for your order!'}<br>
          Printed: ${new Date().toLocaleString('en-IN')}
        </div>
        ` : ''}

        <!-- Print Button (hidden during print) -->
        <div class="no-print" style="margin-top: 15px; text-align: center;">
          <button onclick="window.onafterprint=function(){window.close()};window.print()" style="
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
   * Get human-readable section label
   */
  getSectionLabel(section: string): string {
    const labels: { [key: string]: string } = {
      'header': 'Shop Header',
      'billInfo': 'Bill Info (Date, Number)',
      'items': 'Item List',
      'summary': 'Summary (Total, Savings)',
      'payment': 'Payment Method',
      'qrCode': 'UPI QR Code',
      'footer': 'Footer & Thank You'
    };
    return labels[section] || section;
  }

  /**
   * Move section up in order
   */
  moveSectionUp(index: number): void {
    if (index > 0) {
      const temp = this.billSettings.sectionOrder[index];
      this.billSettings.sectionOrder[index] = this.billSettings.sectionOrder[index - 1];
      this.billSettings.sectionOrder[index - 1] = temp;
    }
  }

  /**
   * Move section down in order
   */
  moveSectionDown(index: number): void {
    if (index < this.billSettings.sectionOrder.length - 1) {
      const temp = this.billSettings.sectionOrder[index];
      this.billSettings.sectionOrder[index] = this.billSettings.sectionOrder[index + 1];
      this.billSettings.sectionOrder[index + 1] = temp;
    }
  }

  /**
   * Add new custom field
   */
  addCustomField(): void {
    if (this.billSettings.customFields.length < 6) {
      this.billSettings.customFields.push({
        label: '',
        value: '',
        enabled: false,
        position: 'footer'
      });
    }
  }

  /**
   * Remove custom field
   */
  removeCustomField(index: number): void {
    this.billSettings.customFields.splice(index, 1);
  }

  /**
   * Get enabled custom fields by position
   */
  private getCustomFieldsHtml(position: 'header' | 'footer', fontSize: number): string {
    const fields = this.billSettings.customFields
      .filter(f => f.enabled && f.label && f.value && f.position === position);

    if (fields.length === 0) return '';

    return fields.map(f => `
      <div style="font-size: ${fontSize}px; text-align: center; margin: 2px 0;">
        <span style="color: #000;">${f.label}:</span> <span style="font-weight: 600;">${f.value}</span>
      </div>
    `).join('');
  }

  /**
   * Generate UPI QR Code as base64 data URL (works offline)
   */
  async generateUpiQrCode(size: number = 150, amount?: number): Promise<string> {
    const upiId = this.billSettings.upiId || this.shopUpiId;
    if (!upiId) return '';

    const shopName = (this.billSettings.shopName || this.shopName || 'Shop').replace(/[^a-zA-Z0-9 ]/g, '');
    const finalAmount = amount ?? this.totalAmount;
    // UPI deep link format
    const upiUrl = `upi://pay?pa=${upiId}&pn=${shopName}&am=${finalAmount}&cu=INR`;

    try {
      // Generate QR code as data URL (base64) - works offline
      const qrDataUrl = await QRCode.toDataURL(upiUrl, {
        width: size,
        margin: 1,
        color: { dark: '#000000', light: '#ffffff' }
      });
      return qrDataUrl;
    } catch (error) {
      console.error('Error generating QR code:', error);
      return '';
    }
  }

  /**
   * Fallback: Get UPI QR Code URL using external API (online only)
   */
  getUpiQrCodeUrl(size: number = 150, amount?: number): string {
    const upiId = this.billSettings.upiId || this.shopUpiId;
    if (!upiId) return '';
    const shopName = (this.billSettings.shopName || this.shopName || 'Shop').replace(/[^a-zA-Z0-9 ]/g, '');
    const finalAmount = amount ?? this.totalAmount;
    const upiUrl = `upi://pay?pa=${upiId}&pn=${shopName}&am=${finalAmount}&cu=INR`;
    return `https://chart.googleapis.com/chart?cht=qr&chs=${size}x${size}&chl=${encodeURIComponent(upiUrl)}&choe=UTF-8`;
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
      // Guarded sequence in the correct order: edits -> creations -> orders
      // (orders LAST so offline-created products have real server IDs first)
      const { synced: totalSynced, failed: totalFailed } = await this.syncService.runSyncSequence();

      // Refresh products
      await this.loadProducts();
      this.swal.close();

      if (totalSynced > 0 || totalFailed > 0) {
        if (totalFailed > 0) {
          this.swal.warning('Sync Partial', `Synced: ${totalSynced}, Failed: ${totalFailed}`);
        } else {
          this.swal.success('Synced', `${totalSynced} record(s) synced successfully`);
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
   * Called as the shop owner types in the customer name/phone fields.
   * Debounced lookup of customers previously billed at this shop.
   */
  onCustomerFieldInput(query: string): void {
    if (this.customerSearchTimer) {
      clearTimeout(this.customerSearchTimer);
    }
    const q = (query || '').trim();
    if (q.length < 2 || !this.shopId || !this.syncStatus.isOnline) {
      this.customerSuggestions = [];
      this.showCustomerSuggestions = false;
      return;
    }
    this.customerSearchTimer = setTimeout(async () => {
      try {
        const results = await this.syncService.searchCustomers(this.shopId, q);
        this.customerSuggestions = results || [];
        this.showCustomerSuggestions = this.customerSuggestions.length > 0;
      } catch (error) {
        console.error('Customer lookup failed:', error);
        this.customerSuggestions = [];
        this.showCustomerSuggestions = false;
      }
    }, 300);
  }

  /**
   * Fill name + phone from a picked suggestion
   */
  selectCustomerSuggestion(suggestion: any): void {
    this.customerName = suggestion.customerName || '';
    this.customerPhone = suggestion.customerPhone || '';
    this.customerEmail = suggestion.customerEmail || '';
    this.customerSuggestions = [];
    this.showCustomerSuggestions = false;
  }

  /**
   * Delay hiding so a click on a suggestion still registers
   */
  hideCustomerSuggestions(): void {
    setTimeout(() => {
      this.showCustomerSuggestions = false;
    }, 200);
  }

  /**
   * Toggle customer form
   */
  hasCustomer(): boolean {
    return !!((this.customerName && this.customerName.trim()) || (this.customerPhone && this.customerPhone.trim()));
  }

  openCustomerModal(): void {
    this.showCustomerModal = true;
    this.showCustomerSuggestions = false;
  }

  closeCustomerModal(): void {
    this.showCustomerModal = false;
    this.showCustomerSuggestions = false;
  }

  clearCustomer(): void {
    this.customerName = '';
    this.customerPhone = '';
    this.customerEmail = '';
    this.orderNotes = '';
    this.customerSuggestions = [];
    this.showCustomerSuggestions = false;
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

    // Clear search/filter and reset product list after update
    this.searchTerm = '';
    this.filteredProducts = this.sortProductsWithCartFirst(this.products);

    // Re-focus search input for next action
    setTimeout(() => {
      if (this.searchInput?.nativeElement) {
        this.searchInput.nativeElement.focus();
      }
    }, 100);
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
   * Print product labels using the shop's saved Label Designer template, so
   * POS labels match the design (size, fonts, barcode width/height) configured
   * in Shop Owner -> Label Designer. Values just typed in the quick-edit
   * (net qty, PKD, EXP) are forced onto the label even if the template hides them.
   */
  printLabel(): void {
    if (!this.editingProduct) return;

    const product = this.editingProduct;
    const barcode = this.editBarcode1 || this.editBarcode || product.sku || '';
    const quantity = Math.max(1, Math.floor(this.labelQuantity || 1));

    if (!barcode) {
      this.swal.warning('No Barcode', 'Please add a barcode to print labels');
      return;
    }

    const labelProduct: LabelProductData = {
      name: this.editName || product.name || '',
      tamilName: this.editNameTamil || product.nameTamil || '',
      sku: this.editSku || product.sku || '',
      barcode,
      price: this.editPrice || product.price,
      mrp: (this.editMrp && this.editMrp > 0) ? this.editMrp : undefined,
      netQty: this.labelNetQty || undefined,
      packedDate: this.labelPackedDate || undefined,
      expiryDate: this.labelExpiryDate || undefined,
      shopName: this.shopName || ''
    };
    const labels = Array(quantity).fill(labelProduct);

    const printWith = (template: LabelTemplate) => {
      const forced: (keyof LabelDesign['fields'])[] = [];
      if (this.labelNetQty) forced.push('netQty');
      if (this.labelPackedDate) forced.push('packedDate');
      if (this.labelExpiryDate) forced.push('expiryDate');
      this.labelPrintService.print(templateWithFieldsShown(template, forced), labels)
        .catch((err) => this.swal.error('Error', err?.message || 'Failed to print labels'));
    };

    this.labelTemplateService.getDefault().subscribe({
      next: (template) => printWith(template || defaultLabelTemplate()),
      error: () => printWith(defaultLabelTemplate())
    });
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

          // Also update IndexedDB cache to prevent stale data on background sync
          await this.offlineStorage.updateLocalProduct(productId, {
            price: updateData.price,
            originalPrice: updateData.originalPrice,
            stock: updateData.stockQuantity,
            sku: updateData.sku,
            barcode: updateData.barcode,
            barcode1: updateData.barcode1,
            barcode2: updateData.barcode2,
            barcode3: updateData.barcode3,
            name: updateData.customName,
            nameTamil: updateData.nameTamil,
            imageBase64: updateData.imageBase64,
            netQty: updateData.netQty,
            packedDate: updateData.packedDate,
            expiryDate: updateData.expiryDate
          }).catch(err => console.warn('Failed to update cache:', err));

          // Update cache timestamp to prevent immediate background sync overwriting
          localStorage.setItem(this.POS_CACHE_TIMESTAMP_KEY, Date.now().toString());

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

      // For offline-created products (negative IDs), also update pending creation
      if (productId < 0) {
        await this.offlineStorage.applyEditToProductCreation(productId, {
          price: this.editPrice,
          originalPrice: this.editMrp,
          stockQuantity: this.editStock,
          sku: this.editSku,
          barcode1: this.editBarcode1,
          barcode2: this.editBarcode2,
          barcode3: this.editBarcode3,
          customName: this.editName,
          nameTamil: this.editNameTamil
        });
      }

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
   * Resolve cart product IDs - convert negative temp IDs to real server IDs by looking up in cache
   */
  private async resolveCartProductIds(): Promise<Array<{ shopProductId: number; quantity: number; unitPrice: number; productName: string }>> {
    // Refresh products from cache to get latest IDs after sync
    const cachedProducts = await this.offlineStorage.getProducts();

    return this.cart.map(item => {
      let resolvedId = item.product.id;

      // If product has negative temp ID, try to find real ID in cache
      if (resolvedId < 0) {
        // First try to find by barcode (most reliable)
        const barcode = item.product.barcode1 || item.product.barcode || '';
        if (barcode) {
          const matchByBarcode = cachedProducts.find(p =>
            p.id > 0 && (p.barcode1 === barcode || p.barcode === barcode)
          );
          if (matchByBarcode) {
            console.log(`Resolved temp ID ${resolvedId} to ${matchByBarcode.id} via barcode ${barcode}`);
            resolvedId = matchByBarcode.id;
          }
        }

        // If still negative, try by name
        if (resolvedId < 0) {
          const productName = item.product.name.toLowerCase();
          const matchByName = cachedProducts.find(p =>
            p.id > 0 && p.name.toLowerCase() === productName
          );
          if (matchByName) {
            console.log(`Resolved temp ID ${resolvedId} to ${matchByName.id} via name ${productName}`);
            resolvedId = matchByName.id;
          }
        }
      }

      return {
        shopProductId: resolvedId,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        productName: item.product.name
      };
    });
  }

  /**
   * Update local stock after creating a bill (fast - no server reload needed)
   */
  private async updateLocalStockAfterBill(): Promise<void> {
    // Track only the products whose stock actually changed so we persist just those,
    // instead of rewriting the entire ~2500-product IndexedDB store on every sale.
    const changedProducts: CachedProduct[] = [];

    // Deduct stock for each cart item locally
    for (const cartItem of this.cart) {
      const productId = cartItem.product.id;
      const quantitySold = cartItem.quantity;

      // Update in products array
      const productIndex = this.products.findIndex(p => p.id === productId);
      if (productIndex !== -1 && this.products[productIndex].trackInventory) {
        const currentStock = this.products[productIndex].stock || 0;
        this.products[productIndex].stock = Math.max(0, currentStock - quantitySold);
        changedProducts.push(this.products[productIndex]);
      }

      // Update in filtered products array
      const filteredIndex = this.filteredProducts.findIndex(p => p.id === productId);
      if (filteredIndex !== -1 && this.filteredProducts[filteredIndex].trackInventory) {
        const currentStock = this.filteredProducts[filteredIndex].stock || 0;
        this.filteredProducts[filteredIndex].stock = Math.max(0, currentStock - quantitySold);
      }
    }

    // Persist ONLY the changed products (fast) rather than clearing + rewriting all products
    if (changedProducts.length > 0) {
      await this.offlineStorage.putProducts(changedProducts);
    }
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
