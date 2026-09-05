import { Component, OnInit, OnDestroy, AfterViewInit, ViewChild, ElementRef, NgZone } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Subject } from 'rxjs';
import { takeUntil, debounceTime } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { OfflineStorageService, CachedProduct, OfflineEdit } from '../../../../core/services/offline-storage.service';
import { PosProductCacheService } from '../../../../core/services/pos-product-cache.service';
import { PosSyncService, SyncStatus } from '../../../../core/services/pos-sync.service';
import { AuthService } from '../../../../core/services/auth.service';
import { SwalService } from '../../../../core/services/swal.service';
import { ShopContextService } from '../../services/shop-context.service';
import { getImageUrl } from '../../../../core/utils/image-url.util';
import { LabelTemplateService } from '../../../../core/services/label-template.service';
import { LabelPrintService } from '../../../../core/services/label-print.service';
import { ReceiptTemplateService } from '../../../../core/services/receipt-template.service';
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
  // Weight-sold items (product.unit === 'kg'): billed as one line whose
  // unitPrice IS the line total; grams and rate are kept for display/edit
  weightGrams?: number;
  pricePerKg?: number;
}

type PosProfile = 'grocery' | 'fashion' | 'medical' | 'general';

interface PosProfileConfig {
  label: string;
  icon: string;
  searchPlaceholder: string;
  emptyTitle: string;
  emptyHint: string;
  quickFilters: string[];
  browseFirst: boolean;
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
  templateStyle: 'current' | 'classic' | 'minimal' | 'bold' | 'compact' | 'invoice' | 'bordered';

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
  showSellingPrice: boolean;
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

  // Auto send the bill when it is printed (manual share buttons always remain)
  autoSendWhatsAppOnPrint: boolean;
  autoSendEmailOnPrint: boolean;

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
  posProfile: PosProfile = 'general';
  readonly posProfiles: Record<PosProfile, PosProfileConfig> = {
    grocery: { label: 'Quick Bill', icon: 'qr_code_scanner', searchPlaceholder: 'Search or scan barcode...', emptyTitle: 'Scan or search to add products', emptyHint: 'Search by name, SKU, or scan a barcode', quickFilters: [], browseFirst: false },
    fashion: { label: 'Fashion counter', icon: 'checkroom', searchPlaceholder: 'Search style, size, colour, SKU or barcode...', emptyTitle: 'Browse the collection', emptyHint: 'Choose the right style and variant before adding it', quickFilters: ['Saree', 'Shirt', 'Pant', 'Women', 'Men', 'Kids'], browseFirst: true },
    medical: { label: 'Pharmacy counter', icon: 'medication', searchPlaceholder: 'Search medicine, generic name, brand or barcode...', emptyTitle: 'Find a medicine', emptyHint: 'Check the correct product, pack and stock before billing', quickFilters: ['Tablet', 'Capsule', 'Syrup', 'Cream', 'Injection'], browseFirst: true },
    general: { label: 'Quick Bill', icon: 'point_of_sale', searchPlaceholder: 'Search product, SKU or barcode...', emptyTitle: 'Search to add products', emptyHint: 'Find a product by name, SKU or barcode', quickFilters: [], browseFirst: false }
  };

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

  // Gemini fallback for Tamil/voice search: cache resolved term -> English
  // keywords so we ask the AI at most once per word, and track in-flight calls.
  private aiKeywordCache: Map<string, string[]> = new Map();
  private aiResolveInFlight: Set<string> = new Set();

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
  billDiscount: number = 0;  // Extra discount the owner gives on the whole bill (₹)
  billDiscountInput: number = 0;
  billDiscountMode: 'amount' | 'percentage' = 'amount';

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
  // Quantity already billed on lastOrder per cart line, so a re-print after
  // adding a missed item appends only the new/increased quantity to the SAME
  // order instead of creating a brand-new bill. Cleared on resetCart().
  private billedQuantities = new WeakMap<CartItem, number>();
  sendingWhatsAppBill: boolean = false;
  sendingEmailBill: boolean = false;
  sharingOwnWhatsApp: boolean = false;

  // Sync status
  syncStatus: SyncStatus = {
    isOnline: true,
    pendingOrders: 0,
    pendingEdits: 0,
    pendingProductCreations: 0,
    lastProductSync: null,
    isSyncing: false,
    failedOrders: 0
  };
  private lastKnownFailedOrders = 0;

  private readonly POS_CACHE_TIMESTAMP_KEY = 'pos_products_last_sync';
  // Delta sync: stale-cache refreshes fetch only changed products; a heavy full
  // re-download happens at most once a day (catches hard-deleted rows the delta can't see)
  private readonly POS_FULL_SYNC_KEY = 'pos_products_last_full_sync';
  private readonly FULL_SYNC_VALIDITY_MS = 24 * 60 * 60 * 1000; // 24 hours
  private readonly DELTA_OVERLAP_MS = 2 * 60 * 1000; // overlap to absorb client/server clock skew
  // Throttle background image re-caching so opening POS doesn't re-scan all images every time
  private readonly POS_IMAGES_CACHED_KEY = 'pos_images_last_cached';
  // In-progress bill survives page refreshes (PWA auto-update reloads, accidental F5)
  private readonly POS_CART_BACKUP_KEY = 'pos_cart_backup';
  // One-shot handoff from Order Management's "Add Cart Again" button
  private readonly POS_READD_ORDER_KEY = 'pos_readd_order';
  private readonly IMAGE_CACHE_VALIDITY_MS = 60 * 60 * 1000; // 1 hour
  // Image caching used to start the moment POS opened, and its ~2500 IndexedDB
  // lookups + downloads competed with the search box — the freeze owners felt.
  // Now it starts only after this idle delay and pauses while the owner types.
  private readonly IMAGE_CACHE_START_DELAY_MS = 45 * 1000;
  private imageCacheTimer: any = null;
  private lastTypingAt = 0;

  // UI state
  isLoading: boolean = true;
  showCustomerModal: boolean = false;

  // Product browse display preferences (persisted per browser)
  viewMode: 'card' | 'list' = 'card';
  showImages: boolean = true;
  private readonly POS_VIEW_MODE_KEY = 'pos-billing-view-mode';
  private readonly POS_SHOW_IMAGES_KEY = 'pos-billing-show-images';

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
    templateStyle: 'current',
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
    showSellingPrice: true,
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
    // Auto send on print
    autoSendWhatsAppOnPrint: false,
    autoSendEmailOnPrint: false,
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
  newProductUnit: 'piece' | 'kg' = 'piece';
  isSavingNewProduct: boolean = false;

  // Weight picker state (products sold by kg)
  weightProduct: CachedProduct | null = null;
  weightGrams: number = 0;
  weightPricePerKg: number = 0;
  readonly weightChips: number[] = [100, 250, 500, 750, 1000, 2000];

  private apiUrl = environment.apiUrl;

  constructor(
    private http: HttpClient,
    private offlineStorage: OfflineStorageService,
    private syncService: PosSyncService,
    private authService: AuthService,
    private swal: SwalService,
    private shopContext: ShopContextService,
    private labelTemplateService: LabelTemplateService,
    private labelPrintService: LabelPrintService,
    private ngZone: NgZone,
    private router: Router,
    private posProductCache: PosProductCacheService,
    private receiptTemplate: ReceiptTemplateService
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
    this.listViewCacheDirty = true;
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

  /**
   * Products to render in the browse grid, list-view only: the full filtered
   * catalog (no pagination cap, unlike card view's displayedProducts window)
   * with any product already in the cart moved to the top and highlighted.
   * Card view is untouched — it keeps using displayedProducts as before.
   *
   * Cached and rebuilt only when the cart or filter changes: a getter that
   * allocates a fresh array made every change-detection cycle re-diff ~2000
   * rows and turned scrolling to jank on large catalogs.
   */
  private listViewCacheDirty = true;
  private listViewCache: CachedProduct[] = [];

  get listViewProducts(): CachedProduct[] {
    if (!this.listViewCacheDirty) return this.listViewCache;
    if (this.cart.length === 0) {
      this.listViewCache = this._filteredProducts;
    } else {
      const inCart: CachedProduct[] = [];
      const rest: CachedProduct[] = [];
      for (const p of this._filteredProducts) {
        (this.cartIndex.has(p.id) ? inCart : rest).push(p);
      }
      this.listViewCache = [...inCart, ...rest];
    }
    this.listViewCacheDirty = false;
    return this.listViewCache;
  }

  get posProfileConfig(): PosProfileConfig { return this.posProfiles[this.posProfile]; }
  get browseProductsByDefault(): boolean { return this.posProfileConfig.browseFirst; }

  applyProfileFilter(filter: string): void {
    this.searchTerm = filter;
    this.onSearchChange();
    requestAnimationFrame(() => this.searchInput?.nativeElement.focus());
  }

  private setPosProfile(businessType?: string): void {
    switch ((businessType || '').toUpperCase()) {
      case 'GROCERY': this.posProfile = 'grocery'; break;
      case 'FASHION': this.posProfile = 'fashion'; break;
      case 'PHARMACY':
      case 'MEDICINE': this.posProfile = 'medical'; break;
      default: this.posProfile = 'general';
    }
    if (this.products.length > 0) this.filterProducts(this.searchTerm);
  }

  ngOnInit(): void {
    this.loadShopInfo();
    this.loadViewPreferences();
    this.loadLanguagePreference();
    this.loadReceiptLanguageSettings();
    this.loadBillSettings();
    this.initSyncStatus();
    this.initSearch();
    this.initBarcodeScanner();

    // Products may have been added/edited on another screen (e.g. Add Product)
    // since the in-memory warm cache was populated - bypass it and read the
    // freshly-updated IndexedDB just this once instead of firing a second,
    // overlapping loadProducts() call after the fact.
    const productsChangedElsewhere = localStorage.getItem('pos_products_changed') === 'true';
    if (productsChangedElsewhere) {
      localStorage.removeItem('pos_products_changed');
    }
    this.loadProducts(productsChangedElsewhere).then(async () => {
      // Order Management handoff first: when it fills the cart, the refresh
      // backup restore below skips itself (it never overwrites a non-empty cart)
      await this.applyReAddOrder();
      this.restoreCartBackup();
    });
    window.addEventListener('beforeunload', this.beforeUnloadHandler);

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
        await this.syncProductsInBackground();
        this.swal.toast(`${synced} offline record(s) synced to server`, 'success');
      }
    } catch (error) {
      console.error('Startup sync failed (will retry on manual sync):', error);
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

    // Keep the in-progress bill if the owner navigates away and comes back
    this.saveCartBackup();
    window.removeEventListener('beforeunload', this.beforeUnloadHandler);

    // Remove barcode scanner keyboard listener to prevent memory leaks and duplicate handlers
    if (this.barcodeKeyHandler) {
      document.removeEventListener('keypress', this.barcodeKeyHandler);
      this.barcodeKeyHandler = null;
    }

    // Cancel a pending image-cache run scheduled for after the idle delay
    if (this.imageCacheTimer) {
      clearTimeout(this.imageCacheTimer);
      this.imageCacheTimer = null;
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
          this.setPosProfile(shop.businessType);
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
      this.setPosProfile(currentShop.businessType);
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
   * Load product-browse view preferences (card/list, show/hide images) from localStorage
   */
  private loadViewPreferences(): void {
    const savedMode = localStorage.getItem(this.POS_VIEW_MODE_KEY);
    this.viewMode = savedMode === 'list' ? 'list' : 'card';
    const savedImages = localStorage.getItem(this.POS_SHOW_IMAGES_KEY);
    this.showImages = savedImages !== 'false';
  }

  /**
   * Switch between card and list layout for the product browse grid, persisted per browser.
   */
  setViewMode(mode: 'card' | 'list'): void {
    this.viewMode = mode;
    localStorage.setItem(this.POS_VIEW_MODE_KEY, mode);
  }

  /**
   * Toggle showing product images in the browse grid, persisted per browser.
   */
  toggleShowImages(): void {
    this.showImages = !this.showImages;
    localStorage.setItem(this.POS_SHOW_IMAGES_KEY, String(this.showImages));
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
    this.router.navigate(['/shop-owner/bill-settings']);
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
    // Baseline to already-known failures: getSyncStatus() is a BehaviorSubject
    // and replays its current value immediately on subscribe. Without this,
    // any pre-existing failed order (even from days ago) looked like a brand
    // new one on every single visit to this screen, popping the same warning
    // dialog over and over.
    this.lastKnownFailedOrders = this.syncService.getCurrentStatus().failedOrders;

    this.syncService.getSyncStatus()
      .pipe(takeUntil(this.destroy$))
      .subscribe(status => {
        this.syncStatus = status;

        // A bill can fail to sync from a background/automatic retry (network
        // reconnect, periodic timer) with no one actively watching for it.
        // Catch that transition here so it's never silent - real cash was
        // already collected for these bills.
        if (status.failedOrders > this.lastKnownFailedOrders) {
          this.swal.warning(
            'A bill could not be synced',
            `${status.failedOrders} bill(s) were rejected by the server (e.g. item sold out on another device) and need review. Tap the red "Failed" badge to see details.`
          );
        }
        this.lastKnownFailedOrders = status.failedOrders;
      });
  }

  /**
   * Initialize search with debounce
   */
  private initSearch(): void {
    this.searchSubject
      .pipe(
        takeUntil(this.destroy$),
        // In-memory filter; rendering is cheap now (cached list + content-visibility),
        // so a short debounce keeps results feeling immediate while typing.
        debounceTime(150)
      )
      .subscribe(term => {
        this.filterProducts(term);
        // Local search (incl. the offline Tamil dictionary) found nothing — try
        // the Gemini fallback to resolve an unknown Tamil/voice word to English.
        if (this.filteredProducts.length === 0) {
          this.aiResolveKeyword(term);
        }
      });
  }

  /**
   * Gemini fallback for Tamil / voice search. When the local filter (and the
   * built-in Tamil dictionary) find nothing, ask the backend to resolve the
   * spoken/typed word to English keyword(s), cache them, and re-run the local
   * filter so the shop's own product list is what actually gets matched.
   * Guarded so we call the AI at most once per word and only when online.
   */
  private aiResolveKeyword(term: string): void {
    const q = (term || '').trim();
    const key = q.toLowerCase();
    // Skip: too short, pure barcode/number, offline, already resolved or in flight.
    if (q.length < 2 || /^\d+$/.test(q)) return;
    if (!navigator.onLine) return;
    if (this.aiKeywordCache.has(key) || this.aiResolveInFlight.has(key)) return;

    this.aiResolveInFlight.add(key);
    this.http.get<any>(`${this.apiUrl}/v1/products/search/resolve-keyword`, { params: { q } })
      .subscribe({
        next: (res) => {
          this.aiResolveInFlight.delete(key);
          const keywords: string[] = (res?.data?.keywords || res?.keywords || [])
            .map((k: string) => String(k).toLowerCase().trim())
            .filter((k: string) => k && k !== key); // drop the unchanged input
          this.aiKeywordCache.set(key, keywords);
          // Only re-filter if the user is still looking at this same term.
          if (keywords.length && this.searchTerm.trim().toLowerCase() === key) {
            this.filterProducts(this.searchTerm);
          }
        },
        error: () => {
          this.aiResolveInFlight.delete(key);
          // Cache empty so we don't hammer the API for a word it can't resolve.
          this.aiKeywordCache.set(key, []);
        }
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
      const target = event.target as HTMLElement;
      // The main search box already has its own scan handling via onQuickSearchEnter
      // (ngModel + keyup.enter), so let it work normally - don't double-handle here.
      if (target.classList?.contains('quick-search-input')) {
        return;
      }

      const currentTime = Date.now();
      const isInput = target.tagName === 'INPUT' || target.tagName === 'TEXTAREA';
      const gapMs = currentTime - lastKeyTime;
      lastKeyTime = currentTime;

      // Enter key completes the barcode (need at least 5 chars for valid barcode).
      // NOTE: on 'keypress', event.key for Enter is the literal string "Enter", not
      // a single character - it must never be appended to the buffer (a previous
      // version did `buffer += event.key` unconditionally, which appended the word
      // "Enter" and then only sliced off the trailing "r", leaving every scanned
      // barcode ending in garbage "Ente" and never matching a real product - this
      // is why scans silently failed as "not found").
      if (event.key === 'Enter') {
        if (buffer.length > 5) {
          const barcode = buffer;
          buffer = '';

          // A scan landed while focus was sitting in some other field (qty, customer
          // name, notes, etc.) - it would otherwise silently type the barcode digits
          // into that field instead of adding a product, which looks like "scan
          // stopped working". Redirect it: clear what got typed and process the scan.
          if (isInput) {
            const el = target as HTMLInputElement | HTMLTextAreaElement;
            const before = el.value.slice(0, Math.max(0, el.value.length - barcode.length));
            this.ngZone.run(() => {
              el.value = before;
              el.dispatchEvent(new Event('input', { bubbles: true }));
              this.handleBarcodeScan(barcode);
            });
            return;
          }

          event.preventDefault();
          // Re-enter Angular only for an actual scan (see runOutsideAngular below)
          this.ngZone.run(() => this.handleBarcodeScan(barcode));
        } else {
          buffer = '';
        }
        return;
      }

      // Only accumulate single printable characters (ignore other multi-char key
      // names like "Shift", "Tab", "Backspace", etc.)
      if (event.key.length !== 1) {
        return;
      }

      // If typing very fast (< 30ms between keys), it's likely a scanner
      // Human typing is typically > 50ms between keys
      buffer = gapMs < 30 ? buffer + event.key : event.key;
    };

    // Listen outside Angular's zone: this handler fires on EVERY keypress on the
    // page, and inside the zone each one forced change detection over the whole
    // POS screen, making typing feel heavy. Scans re-enter the zone above.
    this.ngZone.runOutsideAngular(() => {
      document.addEventListener('keypress', this.barcodeKeyHandler!);
    });
  }

  /**
   * Load products - first from local cache, then sync from server.
   * Offline-first: once a catalog is cached, simply re-opening this screen
   * must never trigger a network call on its own - a shop owner switching
   * screens while billing was re-triggering a server sync every few minutes,
   * which is what made POS feel slow. The server is only asked for data when
   * there is truly nothing cached yet, or the caller explicitly requests it
   * (manual sync, or a product changed on another screen).
   */
  async loadProducts(bypassWarmCache: boolean = false): Promise<void> {
    this.isLoading = true;
    console.log('Loading products for POS...');

    // Instant re-entry: reuse the in-memory catalog kept by PosProductCacheService
    // from the previous visit instead of re-reading IndexedDB. In-place edits
    // (stock, price) share the same array, so nothing is lost across navigation.
    const warmProducts = (!bypassWarmCache && this.shopId) ? this.posProductCache.getFor(this.shopId) : null;
    if (warmProducts && warmProducts.length > 0) {
      this.products = warmProducts;
      this.filteredProducts = this.sortProductsWithCartFirst(this.products);
      this.isLoading = false;
      console.log(`POS: reusing ${this.products.length} products from memory`);
      return;
    }

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
        if (this.shopId) this.posProductCache.set(this.shopId, this.products);

        // Cache product images to IndexedDB for offline use.
        // Throttled: re-scanning ~2500 images on every POS open is wasteful, so only
        // run if we haven't cached within the last hour (server-refresh path caches fresh ones anyway).
        if (this.products.length > 0) {
          const lastImgCache = parseInt(localStorage.getItem(this.POS_IMAGES_CACHED_KEY) || '0', 10);
          if (Date.now() - lastImgCache > this.IMAGE_CACHE_VALIDITY_MS) {
            this.scheduleImageCaching();
          }
        }

        // Only hit the server if the cache genuinely has nothing usable in it.
        if (navigator.onLine && this.products.length === 0) {
          console.log('POS: No active products in cache, loading from server...');
          this.loadProductsFromServer();
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

    const fetchPage = (page: number) =>
      this.http.get<any>(
        `${this.apiUrl}/shop-products/my-products?page=${page}&size=${pageSize}`
      ).pipe(takeUntil(this.destroy$)).toPromise();

    const renderProgress = () => {
      const mappedSoFar = rawProducts.map((p: any) => this.mapProduct(p));
      this.products = mappedSoFar.filter(p => p.isAvailable !== false && (p as any).status !== 'INACTIVE');
      this.filteredProducts = this.sortProductsWithCartFirst(this.products);
    };

    try {
      // Fetch page 0 first to learn totalPages, then fetch every remaining page
      // in parallel instead of one-at-a-time - a multi-page catalog used to take
      // (pages x per-page latency) sequentially, which is what stretched a fresh
      // login/refresh into ~30s of "not found" barcode scans while it loaded.
      const first: any = await fetchPage(0);
      const firstData = first?.data;
      let totalPages = 1;
      if (firstData?.content) {
        rawProducts.push(...firstData.content);
        totalPages = firstData.totalPages || 1;
      } else if (Array.isArray(firstData)) {
        rawProducts.push(...firstData);
        totalPages = 1;
      }
      renderProgress();

      if (totalPages > 1) {
        const maxPage = Math.min(totalPages, 200);
        if (totalPages > 200) {
          console.warn('loadProductsFromServer: page guard hit (200) — stopping');
        }
        const remainingPages = Array.from({ length: maxPage - 1 }, (_, i) => i + 1);
        const responses = await Promise.all(remainingPages.map(fetchPage));
        for (const response of responses) {
          const data = (response as any)?.data;
          const content: any[] = data?.content || (Array.isArray(data) ? data : []);
          rawProducts.push(...content);
        }
        renderProgress();
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
      if (this.shopId) this.posProductCache.set(this.shopId, this.products);
      console.log(`Loaded ${this.products.length} active products across ${totalPages} page(s) (${allProducts.length} total)`);

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
      if (this.shopId) this.posProductCache.set(this.shopId, this.products);

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
      if (this.shopId) this.posProductCache.set(this.shopId, this.products);

      console.log(`Background sync complete: ${activeProducts.length} active products (${allProducts.length} total) across ${page} page(s)`);
    } catch (error) {
      console.warn('Background sync failed:', error);
    }
  }

  /**
   * Start the hourly image-cache scan only after the POS has been open for a
   * while, outside Angular's zone so none of it triggers change detection.
   * The "last cached" stamp is written when the run actually starts, so closing
   * POS before the delay simply retries on the next open.
   */
  private scheduleImageCaching(): void {
    this.ngZone.runOutsideAngular(() => {
      this.imageCacheTimer = setTimeout(() => {
        localStorage.setItem(this.POS_IMAGES_CACHED_KEY, Date.now().toString());
        this.cacheProductImagesToIndexedDB(this.products);
      }, this.IMAGE_CACHE_START_DELAY_MS);
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
      // Back off while the owner is typing — caching must never compete with search
      if (Date.now() - this.lastTypingAt < 2000) {
        setTimeout(() => cacheBatch(startIndex), 1500);
        return;
      }

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
    this.lastTypingAt = Date.now();
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

    if (this.isLoading) {
      this.swal.toast('Products still loading, please wait...', 'info');
      return;
    }

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

  // ========== Weight-based selling (products with unit 'kg') ==========

  /** Product is sold by weight: unit starts with 'kg' (covers 'kg', 'Kg', 'kgs') */
  isWeightProduct(product: CachedProduct): boolean {
    return String(product.unit || '').toLowerCase().startsWith('kg');
  }

  /** 250 -> "250g", 1000 -> "1kg", 1500 -> "1.5kg" */
  formatWeight(grams: number): string {
    if (grams >= 1000) {
      const kg = Math.round((grams / 1000) * 100) / 100;
      return `${kg}kg`;
    }
    return `${grams}g`;
  }

  /** Weight label for the in-cart badge / product row ("" when not in cart) */
  getCartWeightLabel(product: CachedProduct): string {
    const item = this.cartIndex.get(product.id);
    return item && item.weightGrams ? this.formatWeight(item.weightGrams) : '';
  }

  get weightTotal(): number {
    if (this.weightGrams <= 0 || this.weightPricePerKg <= 0) return 0;
    return Math.round(this.weightPricePerKg * this.weightGrams / 10) / 100;
  }

  openWeightPicker(product: CachedProduct): void {
    const existing = this.cartIndex.get(product.id);
    this.weightProduct = product;
    this.weightPricePerKg = existing?.pricePerKg || product.price || 0;
    this.weightGrams = existing?.weightGrams || 0;
  }

  closeWeightPicker(): void {
    this.weightProduct = null;
    this.weightGrams = 0;
    this.weightPricePerKg = 0;
  }

  selectWeightChip(grams: number): void {
    this.weightGrams = grams;
  }

  setWeightRate(event: Event): void {
    const value = parseFloat((event.target as HTMLInputElement).value);
    this.weightPricePerKg = isNaN(value) || value < 0 ? 0 : value;
  }

  setWeightGrams(event: Event): void {
    const value = parseInt((event.target as HTMLInputElement).value, 10);
    this.weightGrams = isNaN(value) || value < 0 ? 0 : value;
  }

  /** Customer asks by money ("₹20 thakkali") — convert amount to grams */
  setWeightAmount(event: Event): void {
    const amount = parseFloat((event.target as HTMLInputElement).value);
    if (isNaN(amount) || amount <= 0 || this.weightPricePerKg <= 0) return;
    // Round to the nearest 5g so the scale weight is practical
    this.weightGrams = Math.max(5, Math.round(amount / this.weightPricePerKg * 1000 / 5) * 5);
  }

  confirmWeight(): void {
    const product = this.weightProduct;
    if (!product) return;
    if (this.weightGrams <= 0) {
      this.swal.error('Weight Required', 'Select or enter the weight');
      return;
    }
    if (this.weightPricePerKg <= 0) {
      this.swal.error('Rate Required', 'Enter the price per kg');
      return;
    }

    const total = this.weightTotal;
    const existing = this.cart.find(item => item.product.id === product.id);
    if (existing) {
      existing.weightGrams = this.weightGrams;
      existing.pricePerKg = this.weightPricePerKg;
      existing.quantity = 1;
      existing.unitPrice = total;
      existing.mrp = total;
      existing.discount = 0;
      existing.total = total;
    } else {
      this.cart.unshift({
        product,
        quantity: 1,
        unitPrice: total,
        mrp: total,
        total,
        discount: 0,
        weightGrams: this.weightGrams,
        pricePerKg: this.weightPricePerKg
      });
    }

    this.calculateTotals();
    this.closeWeightPicker();

    // Same post-add list behaviour as addToCart()
    if (this.activeTab === 'quick' && !this.browseProductsByDefault) {
      this.searchTerm = '';
      this.filteredProducts = [];
    } else {
      this.searchTerm = '';
      this.filteredProducts = this.sortProductsWithCartFirst(this.products);
    }
  }

  /** +/- steppers on a weight cart line (step 100g; below/at zero removes) */
  adjustCartWeight(item: CartItem, deltaGrams: number): void {
    if (!item.weightGrams || !item.pricePerKg) return;
    const newGrams = item.weightGrams + deltaGrams;
    if (newGrams <= 0) {
      this.removeFromCart(item);
      return;
    }
    // Same reasoning as updateQuantity: reducing a weight line that was
    // already printed/billed would desync the next reprint from what the
    // server order actually charged - break the link, next Print starts fresh.
    if (deltaGrams < 0 && (this.billedQuantities.get(item) || 0) > 0) {
      this.lastOrder = null;
      this.billedQuantities = new WeakMap<CartItem, number>();
    }
    item.weightGrams = newGrams;
    const total = Math.round(item.pricePerKg * newGrams / 10) / 100;
    item.unitPrice = total;
    item.mrp = total;
    item.discount = 0;
    item.total = total;
    this.calculateTotals();
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
    if (this.isWeightProduct(product)) {
      this.openWeightPicker(product);
      return;
    }
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
   * Tamil grocery words -> English keywords, so a shopkeeper can SPEAK (voice
   * search) or type the Tamil name and still match English product names.
   * Keys include Tamil script AND common romanizations; all keys are lowercase.
   * This is the offline, instant first pass; the Gemini fallback (resolveViaAi)
   * handles words not in this list when online.
   */
  private static readonly TAMIL_SEARCH_MAP: Record<string, string[]> = {
    // Dairy & eggs
    'முட்டை': ['egg'], 'muttai': ['egg'], 'mutta': ['egg'], 'mutai': ['egg'],
    'பால்': ['milk'], 'paal': ['milk'], 'pal': ['milk'],
    'தயிர்': ['curd'], 'thayir': ['curd'], 'thayiru': ['curd'],
    'வெண்ணெய்': ['butter'], 'venney': ['butter'], 'vennai': ['butter'],
    'நெய்': ['ghee'], 'nei': ['ghee'], 'ney': ['ghee'],
    'பன்னீர்': ['paneer'], 'panneer': ['paneer'],
    // Staples
    'அரிசி': ['rice'], 'arisi': ['rice'],
    'கோதுமை': ['wheat', 'atta'], 'kothumai': ['wheat', 'atta'], 'godhumai': ['wheat', 'atta'],
    'மைதா': ['maida'], 'maida': ['maida'],
    'பருப்பு': ['dal', 'dhall', 'lentil'], 'paruppu': ['dal', 'dhall', 'lentil'],
    'ரவை': ['rava', 'sooji'], 'ravai': ['rava', 'sooji'],
    // Cooking basics
    'சர்க்கரை': ['sugar'], 'sarkkarai': ['sugar'], 'sakkarai': ['sugar'], 'chakkarai': ['sugar'],
    'உப்பு': ['salt'], 'uppu': ['salt'],
    'எண்ணெய்': ['oil'], 'ennai': ['oil'], 'enney': ['oil'], 'enn ai': ['oil'],
    'தண்ணீர்': ['water'], 'thanneer': ['water'], 'thanni': ['water'], 'tanni': ['water'],
    'மஞ்சள்': ['turmeric'], 'manjal': ['turmeric'],
    'மிளகாய்': ['chilli', 'chili'], 'milagai': ['chilli', 'chili'], 'milakai': ['chilli', 'chili'],
    'மிளகு': ['pepper'], 'milagu': ['pepper'],
    'கடுகு': ['mustard'], 'kadugu': ['mustard'],
    'சீரகம்': ['cumin', 'jeera'], 'seeragam': ['cumin', 'jeera'],
    'புளி': ['tamarind'], 'puli': ['tamarind'],
    'கொத்தமல்லி': ['coriander'], 'kothamalli': ['coriander'],
    'கறிவேப்பிலை': ['curry leaves'], 'karuveppilai': ['curry leaves'], 'kariveppilai': ['curry leaves'],
    // Vegetables
    'வெங்காயம்': ['onion'], 'vengayam': ['onion'],
    'தக்காளி': ['tomato'], 'thakkali': ['tomato'], 'takkali': ['tomato'],
    'உருளைக்கிழங்கு': ['potato'], 'urulaikizhangu': ['potato'], 'urulai': ['potato'],
    'பூண்டு': ['garlic'], 'poondu': ['garlic'],
    'இஞ்சி': ['ginger'], 'inji': ['ginger'],
    'தேங்காய்': ['coconut'], 'thengai': ['coconut'], 'thenga': ['coconut'],
    'எலுமிச்சை': ['lemon', 'lime'], 'elumichai': ['lemon', 'lime'], 'elumichampazham': ['lemon', 'lime'],
    'நிலக்கடலை': ['groundnut', 'peanut'], 'nilakadalai': ['groundnut', 'peanut'], 'kadalai': ['groundnut', 'peanut', 'gram'],
    // Beverages
    'தேயிலை': ['tea'], 'theyilai': ['tea'], 'dee': ['tea'],
    'காபி': ['coffee'], 'kaapi': ['coffee'], 'kaappi': ['coffee'],
    // Bakery & packaged
    'ரொட்டி': ['bread', 'roti'], 'rotti': ['bread', 'roti'],
    'பிஸ்கட்': ['biscuit'], 'biscuit': ['biscuit'], 'bisket': ['biscuit'],
    'சோப்பு': ['soap'], 'soppu': ['soap'],
    // Meat & fish
    'கோழி': ['chicken'], 'kozhi': ['chicken'],
    'மீன்': ['fish'], 'meen': ['fish'],
    'மட்டன்': ['mutton'], 'aatirachi': ['mutton'], 'aattirachi': ['mutton'],
    // Fruits
    'வாழைப்பழம்': ['banana'], 'vazhaipazham': ['banana'], 'vazhapazham': ['banana'],
    'ஆப்பிள்': ['apple'], 'apple': ['apple'],
  };

  /**
   * Filter products by search term
   */
  private filterProducts(term: string): void {
    // Normalize the term first. Voice/speech-to-text input yields a trailing
    // space (and sometimes double spaces) that plain typing never does, e.g.
    // "egg ". A substring match then drops single-word products - "Egg".includes
    // ("egg ") is false, while "Egg Masala".includes("egg ") is true - so voice
    // searching "egg" showed "Egg Masala" but hid "Egg". Trim + collapse spaces
    // so voice and typed search behave identically.
    term = (term || '').trim().replace(/\s+/g, ' ');

    // In scanner mode, show empty list when no search term
    if (!term || term.length < 2) {
      if (this.browseProductsByDefault) {
        this.filteredProducts = this.sortProductsWithCartFirst(this.products);
      } else if (this.posMode === 'scanner') {
        this.filteredProducts = [];
      } else {
        this.filteredProducts = this.sortProductsWithCartFirst(this.products);
      }
      return;
    }

    const lowerTerm = term.toLowerCase();

    // Expand Tamil grocery words to their English equivalents so speaking/typing
    // "முட்டை" or "muttai" also finds the English "Egg". The original term is
    // always kept, and each space-separated token is looked up in TAMIL_SEARCH_MAP.
    const searchTerms = [lowerTerm];
    for (const tok of lowerTerm.split(' ')) {
      const mapped = PosBillingComponent.TAMIL_SEARCH_MAP[tok];
      if (mapped) {
        for (const m of mapped) if (!searchTerms.includes(m)) searchTerms.push(m);
      }
    }
    // Also fold in any English keywords the Gemini fallback previously resolved
    // for this exact term (populated asynchronously by aiResolveKeyword).
    const cachedAi = this.aiKeywordCache.get(lowerTerm);
    if (cachedAi) {
      for (const m of cachedAi) if (!searchTerms.includes(m)) searchTerms.push(m);
    }

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

      const name = p.name.toLowerCase();
      const nameTa = p.nameTamil ? p.nameTamil.toLowerCase() : '';
      const sku = p.sku ? p.sku.toLowerCase() : '';
      const textMatch = searchTerms.some(t =>
        name.includes(t) || (nameTa && nameTa.includes(t)) || (sku && sku.includes(t))
      );

      if (textMatch ||
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

    // Product list is still loading (fresh login/refresh) — a scan right now would
    // wrongly show "Not Found" just because the catalog isn't in memory yet.
    if (this.isLoading) {
      this.swal.toast('Products still loading, please wait...', 'info');
      this.playBeep(false);
      return;
    }

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

    if (this.isLoading) {
      this.swal.toast('Products still loading, please wait...', 'info');
      this.barcodeBuffer = '';
      return;
    }

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
    // Weight-sold products go through the weight picker instead of qty steps
    if (this.isWeightProduct(product)) {
      this.openWeightPicker(product);
      return;
    }

    // Out of stock: don't interrupt billing with the restock modal. Add the item
    // and just warn (non-blocking). The shopkeeper reconciles stock later; stock
    // may go negative. (Previously this popped a blocking "enter new stock
    // quantity" prompt, which broke the scan-and-bill flow.)
    const outOfStock = product.trackInventory && product.stock <= 0;
    if (outOfStock) {
      this.swal.toast(`${product.name} is out of stock — added anyway`, 'warning');
    }

    // Check if already in cart
    const existingItem = this.cart.find(item => item.product.id === product.id);

    const mrp = product.originalPrice || product.price;
    const discount = mrp - product.price;

    if (existingItem) {
      // Enforce the stock ceiling only when there IS stock. Out-of-stock items are
      // allowed to go negative so scanning the same item repeatedly still bills.
      if (product.trackInventory && product.stock > 0 && existingItem.quantity >= product.stock) {
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
    // In Browse mode, keep showing the same list - re-sorting the whole catalog
    // (up to ~10k products) after every single scan was the actual cause of the
    // "app gets slow while scanning" complaint. The cart badge on each row already
    // reflects membership via a Set lookup, so skipping the re-sort here doesn't
    // lose any information - it just stops floating items to the top on every add.
    if (this.activeTab === 'quick' && !this.browseProductsByDefault) {
      this.searchTerm = '';
      this.filteredProducts = [];
    } else {
      this.searchTerm = '';
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
   * Inline list-view edit: persist a single field (sell price, MRP or stock)
   * straight from the row inputs. Server first, offline queue on network
   * failure, then optimistic local update — same contract as updateProductStock.
   */
  async saveInlineField(product: CachedProduct, field: 'price' | 'mrp' | 'stock', event: Event): Promise<void> {
    const input = event.target as HTMLInputElement;
    const value = parseFloat(input.value);
    const currentMrp = product.originalPrice || product.price;

    const revert = () => {
      input.value = String(field === 'price' ? product.price : field === 'mrp' ? currentMrp : product.stock);
    };

    if (isNaN(value) || value < 0) {
      this.swal.error('Invalid Value', 'Enter a valid number');
      revert();
      return;
    }
    if (field === 'price' && value <= 0) {
      this.swal.error('Invalid Price', 'Price must be greater than 0');
      revert();
      return;
    }
    if (field === 'price' && currentMrp > 0 && value > currentMrp) {
      this.swal.error('Invalid Price', `Selling price cannot be above MRP (₹${currentMrp})`);
      revert();
      return;
    }
    if (field === 'mrp' && value < product.price) {
      this.swal.error('Invalid MRP', `MRP cannot be less than selling price (₹${product.price})`);
      revert();
      return;
    }

    const newValue = field === 'stock' ? Math.round(value) : value;
    const apiField = field === 'price' ? 'price' : field === 'mrp' ? 'originalPrice' : 'stockQuantity';
    const changes: any = { [apiField]: newValue };
    const previousValues: any = {
      price: product.price,
      originalPrice: product.originalPrice,
      stockQuantity: product.stock
    };

    try {
      const isOfflineProduct = product.id < 0;
      if (navigator.onLine && !isOfflineProduct) {
        try {
          const response: any = await this.http.patch<any>(
            `${this.apiUrl}/shop-products/${product.id}/quick-update`,
            changes
          ).toPromise();
          if (response?.statusCode && response.statusCode !== '0000') {
            this.swal.error('Error', response.message || 'Failed to save');
            revert();
            return;
          }
        } catch (apiError: any) {
          const isNetworkError = !apiError?.status || apiError.status === 0;
          if (!isNetworkError) {
            this.swal.error('Error', apiError?.error?.message || apiError?.message || 'Failed to save');
            revert();
            return;
          }
          await this.queueInlineOfflineEdit(product, changes, previousValues);
        }
      } else {
        await this.queueInlineOfflineEdit(product, changes, previousValues);
      }

      // Optimistic local update everywhere POS reads this field from
      const localField = field === 'price' ? 'price' : field === 'mrp' ? 'originalPrice' : 'stock';
      const apply = (p: CachedProduct) => { (p as any)[localField] = newValue; };
      apply(product);
      const idx = this.products.findIndex(p => p.id === product.id);
      if (idx !== -1) apply(this.products[idx]);
      const fidx = this.filteredProducts.findIndex(p => p.id === product.id);
      if (fidx !== -1) apply(this.filteredProducts[fidx]);
      const cartItem = this.cartIndex.get(product.id);
      if (cartItem) apply(cartItem.product);
      // A saved sell price replaces any temporary billing price for the row
      if (field === 'price') this.tempPrices.delete(product.id);
      await this.offlineStorage.updateLocalProduct(product.id, { [localField]: newValue } as any)
        .catch(err => console.warn('Failed to update cache:', err));
      localStorage.setItem(this.POS_CACHE_TIMESTAMP_KEY, Date.now().toString());

      const label = field === 'price' ? 'Price' : field === 'mrp' ? 'MRP' : 'Stock';
      this.swal.toast(`${label} updated: ${product.name}`, 'success');
    } catch (error) {
      console.error('Inline edit failed:', error);
      this.swal.error('Error', 'Failed to save change');
      revert();
    }
  }

  private async queueInlineOfflineEdit(product: CachedProduct, changes: any, previousValues: any): Promise<void> {
    const offlineEdit: OfflineEdit = {
      editId: this.offlineStorage.generateOfflineEditId(),
      productId: product.id,
      shopId: this.shopId,
      changes,
      previousValues,
      createdAt: new Date().toISOString(),
      synced: false
    };
    await this.offlineStorage.saveOfflineEdit(offlineEdit);
    if (product.id < 0) {
      await this.offlineStorage.applyEditToProductCreation(product.id, changes);
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
    // Weight lines step by 100g instead of pieces
    if (item.weightGrams) {
      this.adjustCartWeight(item, delta * 100);
      return;
    }
    const newQty = item.quantity + delta;

    if (newQty <= 0) {
      this.removeFromCart(item);
      return;
    }

    if (item.product.trackInventory && newQty > item.product.stock) {
      this.swal.warning('Stock Limit', `Only ${item.product.stock} available`);
      return;
    }

    // Reducing a quantity that was already printed/billed would make the next
    // reprint (built from the live cart) show less than what the server order
    // actually charged - stop treating this as the same bill and let the next
    // Print start a fresh, honest order for whatever remains.
    if ((this.billedQuantities.get(item) || 0) > newQty) {
      this.lastOrder = null;
      this.billedQuantities = new WeakMap<CartItem, number>();
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
      // Removing an item that was already printed/billed breaks the link to
      // that order (its reprint would no longer match what was actually
      // charged) - stop appending to it, next Print starts a fresh bill.
      if ((this.billedQuantities.get(item) || 0) > 0) {
        this.lastOrder = null;
        this.billedQuantities = new WeakMap<CartItem, number>();
      }

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
    this.billDiscount = 0;
    this.billDiscountInput = 0;
    this.billDiscountMode = 'amount';
    this.customerAskedForThisBill = false;
    this.printAfterCustomerModal = false;
    this.calculateTotals();
    this.customerName = '';
    this.customerPhone = '';
    this.customerEmail = '';
    this.orderNotes = '';
    this.lastOrder = null;
    this.billedQuantities = new WeakMap<CartItem, number>();
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
    this.listViewCacheDirty = true;

    this.subtotal = this.cart.reduce((sum, item) => sum + item.total, 0);
    this.totalMrp = this.cart.reduce((sum, item) => sum + (item.mrp * item.quantity), 0);
    this.totalDiscount = this.totalMrp - this.subtotal;
    // Ensure discount is never negative (when price > MRP)
    if (this.totalDiscount < 0) this.totalDiscount = 0;
    this.taxAmount = this.subtotal * this.taxRate;
    const discountBase = this.subtotal + this.taxAmount;
    const enteredDiscount = Math.max(0, Number(this.billDiscountInput) || 0);
    if (this.billDiscountMode === 'percentage') {
      this.billDiscountInput = Math.min(100, enteredDiscount);
      this.billDiscount = Math.round(discountBase * this.billDiscountInput) / 100;
    } else {
      this.billDiscountInput = Math.min(discountBase, enteredDiscount);
      this.billDiscount = this.billDiscountInput;
    }
    this.totalAmount = discountBase - this.billDiscount;

    this.saveCartBackup();
  }

  /** Bill discount input changed - re-clamp and recalculate the total */
  onBillDiscountChange(): void {
    this.calculateTotals();
  }

  setBillDiscountMode(mode: 'amount' | 'percentage'): void {
    if (mode === this.billDiscountMode) return;
    const discountBase = this.subtotal + this.taxAmount;
    this.billDiscountInput = mode === 'percentage' && discountBase > 0
      ? Math.round((this.billDiscount / discountBase) * 10000) / 100
      : this.billDiscount;
    this.billDiscountMode = mode;
    this.calculateTotals();
  }

  /**
   * Persist the in-progress bill so it survives a page refresh (the PWA
   * auto-updater force-reloads all tabs when a new version is deployed).
   * imageBase64 is stripped — it would blow the localStorage quota; images
   * are re-linked from the product cache on restore.
   */
  private saveCartBackup(): void {
    try {
      // Empty cart, or the cart was already billed (kept on screen only for
      // reprint/WhatsApp) — restoring it after a refresh could double-bill
      if (this.cart.length === 0 || this.lastOrder) {
        localStorage.removeItem(this.POS_CART_BACKUP_KEY);
        return;
      }
      const slimCart = this.cart.map(item => ({
        ...item,
        product: { ...item.product, imageBase64: undefined }
      }));
      localStorage.setItem(this.POS_CART_BACKUP_KEY, JSON.stringify({
        shopId: this.shopId,
        cart: slimCart,
        customerName: this.customerName,
        customerPhone: this.customerPhone,
        customerEmail: this.customerEmail,
        orderNotes: this.orderNotes,
        billDiscount: this.billDiscount,
        billDiscountInput: this.billDiscountInput,
        billDiscountMode: this.billDiscountMode,
        savedAt: Date.now()
      }));
    } catch (e) {
      // Quota exceeded or storage unavailable — losing the backup is acceptable
      console.warn('Failed to save cart backup:', e);
    }
  }

  /**
   * "Add Cart Again" handoff from the Order Management screen: rebuild the cart
   * from a past order's items. Runs after products are cached so each item can
   * be matched to a live product (by shop product id, falling back to name).
   * Weight-sold items (unit 'kg') need the weight picker, so they are reported
   * for manual adding instead of being guessed.
   */
  private async applyReAddOrder(): Promise<void> {
    let handoff: any = null;
    try {
      const raw = localStorage.getItem(this.POS_READD_ORDER_KEY);
      if (!raw) return;
      localStorage.removeItem(this.POS_READD_ORDER_KEY);  // one-shot
      handoff = JSON.parse(raw);
    } catch (e) {
      console.warn('Failed to read re-add order handoff:', e);
      return;
    }

    // Customer-only handoffs (empty items) come from the admin WhatsApp inbox:
    // the customer is prefilled and staff add products while reading the order text
    const hasCustomer = !!(handoff?.customerPhone || handoff?.customerName);
    if (!handoff?.items?.length && !hasCustomer) return;
    // Stale handoff (>10 min old) or another shop's order — ignore. WhatsApp
    // orders are exempt from the shop check: the assigning admin may bill from
    // a different shop's POS, and the customer/order text is still wanted.
    if (Date.now() - (handoff.savedAt || 0) > 10 * 60 * 1000) return;
    if (handoff.shopId && this.shopId && handoff.shopId !== this.shopId
        && !handoff.whatsappOrderText) return;

    const normalizeName = (name: string) => name.trim().toLowerCase();
    const findProduct = (it: any) =>
      this.products.find(p => it.shopProductId && p.id === it.shopProductId)
      || this.products.find(p => it.name && normalizeName(p.name) === normalizeName(String(it.name)));

    const items: any[] = handoff.items || [];

    // A product added/updated on a different device (or since this terminal's
    // cache was last synced) may genuinely exist but not be in this device's
    // local catalog yet. Before reporting any such item as "not added", pull
    // a fresh delta sync once and re-check - only a true weight-based item or
    // one truly missing from the catalog should end up in the skipped list.
    const initiallyMissing = items.filter(it => !findProduct(it));
    if (initiallyMissing.length > 0 && navigator.onLine) {
      try {
        await this.syncProductsInBackground();
      } catch (e) {
        console.warn('Re-add order: catch-up sync failed:', e);
      }
    }

    // A WhatsApp order is a new sale. Do not mix it with an unfinished cart
    // restored from localStorage or with cart state retained by route reuse.
    if (handoff.replaceCart) {
      this.cart = [];
      localStorage.removeItem(this.POS_CART_BACKUP_KEY);
    }

    const skipped: string[] = [];
    for (const it of items) {
      const product = findProduct(it);
      if (!product || this.isWeightProduct(product)) {
        skipped.push(it.name || `#${it.shopProductId}`);
        continue;
      }

      // Bill at the CURRENT price/stock, not the old order's; clamp to stock
      let qty = Math.max(1, Math.round(it.quantity || 1));
      if (product.trackInventory && product.stock < qty) {
        if (product.stock <= 0) {
          skipped.push(product.name);
          continue;
        }
        qty = product.stock;
      }

      const existing = this.cart.find(item => item.product.id === product.id);
      const mrp = product.originalPrice || product.price;
      if (existing) {
        existing.quantity += qty;
        existing.total = existing.quantity * existing.unitPrice;
      } else {
        this.cart.unshift({
          product,
          quantity: qty,
          unitPrice: product.price,
          mrp,
          total: qty * product.price,
          discount: mrp - product.price
        });
      }
    }

    // The original order's customer comes along so the re-bill can be sent
    // on WhatsApp/email without retyping their details
    if (!this.customerName && handoff.customerName) this.customerName = handoff.customerName;
    if (!this.customerPhone && handoff.customerPhone) this.customerPhone = handoff.customerPhone;
    if (!this.customerEmail && handoff.customerEmail) this.customerEmail = handoff.customerEmail;

    this.calculateTotals();
    this.saveCartBackup();

    const added = this.cart.length;
    if (added > 0) {
      this.swal.toast(`Order ${handoff.orderNumber || ''} loaded: ${added} item${added > 1 ? 's' : ''} added to cart`, 'success');
      // WhatsApp order lines the inbox couldn't match to a product — remind
      // staff to add them by hand so half the order isn't silently dropped
      if (handoff.whatsappUnmatchedText) {
        this.swal.info('Add these manually', handoff.whatsappUnmatchedText);
      }
    } else if (hasCustomer && handoff.whatsappOrderText) {
      // WhatsApp order: leave the customer's message on screen so staff can
      // add the products they asked for
      this.swal.info(
        `WhatsApp order from ${handoff.customerName || handoff.customerPhone}`,
        handoff.whatsappOrderText
      );
    } else if (hasCustomer) {
      this.swal.toast(`Customer ${handoff.customerName || handoff.customerPhone} loaded`, 'success');
    }
    if (skipped.length > 0) {
      this.swal.warning('Some Items Not Added',
        `Add these manually (out of stock, weight-based, or no longer in the catalog): ${skipped.join(', ')}`);
    }
  }

  /**
   * Restore an unsaved bill after a refresh. Called once products are loaded
   * so cart items can be re-linked to full cached products (images, stock).
   */
  private restoreCartBackup(): void {
    try {
      const raw = localStorage.getItem(this.POS_CART_BACKUP_KEY);
      if (!raw || this.cart.length > 0) return;

      const backup = JSON.parse(raw);
      if (!backup?.cart?.length) return;

      // Ignore stale backups (older than 12 hours) and other shops' carts
      const twelveHours = 12 * 60 * 60 * 1000;
      if (Date.now() - (backup.savedAt || 0) > twelveHours) {
        localStorage.removeItem(this.POS_CART_BACKUP_KEY);
        return;
      }
      if (backup.shopId && this.shopId && backup.shopId !== this.shopId) return;

      this.cart = backup.cart
        .map((item: CartItem) => {
          const fullProduct = this.products.find(p => p.id === item.product?.id);
          return fullProduct ? { ...item, product: fullProduct } : item;
        })
        // A snapshot without a usable name/price renders as a broken empty row
        // (seen when the catalog changed since backup) — drop it instead.
        .filter((item: CartItem) => !!item.product?.name && item.product.price != null);
      if (this.cart.length === 0) {
        localStorage.removeItem(this.POS_CART_BACKUP_KEY);
        return;
      }
      this.customerName = backup.customerName || '';
      this.customerPhone = backup.customerPhone || '';
      this.customerEmail = backup.customerEmail || '';
      this.orderNotes = backup.orderNotes || '';
      this.billDiscount = backup.billDiscount || 0;
      this.billDiscountMode = backup.billDiscountMode === 'percentage' ? 'percentage' : 'amount';
      this.billDiscountInput = backup.billDiscountInput ?? this.billDiscount;
      this.calculateTotals();

      this.swal.toast(`Restored unsaved bill (${this.cart.length} item${this.cart.length > 1 ? 's' : ''})`, 'info');
    } catch (e) {
      console.warn('Failed to restore cart backup:', e);
    }
  }

  /**
   * Customer fields are typed after the last cart change, so back them up
   * right before the page unloads (covers the auto-update reload too).
   */
  private beforeUnloadHandler = (): void => this.saveCartBackup();

  /**
   * Generate bill
   */
  async generateBill(): Promise<void> {
    if (this.cart.length === 0) {
      this.swal.warning('Empty Cart', 'Please add items to generate bill');
      return;
    }

    // First Print click with no customer: offer to capture their details
    // (needed for WhatsApp bills). Skip continues as an anonymous walk-in;
    // either way the question is asked only once per bill.
    if (!this.hasCustomer() && !this.customerAskedForThisBill) {
      this.customerAskedForThisBill = true;
      this.printAfterCustomerModal = true;
      this.openCustomerModal();
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

    // A real (synced) order already exists for this cart session — only the
    // item/quantity added since that print needs to reach the server; append
    // it to the SAME bill instead of minting a new bill number. Cleared only
    // by Clear Cart / New Bill (resetCart() nulls lastOrder + billedQuantities).
    const isAppend = !!this.lastOrder?.id;
    const deltaPairs: Array<{ item: CartItem; quantity: number }> = [];
    if (isAppend) {
      for (const item of this.cart) {
        const billedQty = this.billedQuantities.get(item) || 0;
        const delta = item.quantity - billedQty;
        if (delta > 0) deltaPairs.push({ item, quantity: delta });
      }
      if (deltaPairs.length === 0) {
        // Nothing new since the last print - just reprint, no server call needed
        this.printReceipt(this.lastOrder);
        return;
      }
    }

    this.swal.loading(isAppend ? 'Adding item to bill...' : 'Creating bill...');

    try {
      // Resolve any negative temp IDs to real server IDs (for offline-created products that have synced)
      let resolvedItems = await this.resolveCartProductIds(isAppend ? deltaPairs : undefined);

      // Check if any items still have negative IDs (not yet synced).
      // Custom items (null ID) are fine - the server bills them without a product.
      const unsyncedItems = resolvedItems.filter(item => item.shopProductId !== null && item.shopProductId < 0);
      if (unsyncedItems.length > 0 && navigator.onLine) {
        // Try to sync pending product creations first
        console.log('Found unsynced products in cart, attempting sync...');
        await this.syncService.syncPendingProductCreations();
        // Re-resolve after sync
        const reResolvedItems = await this.resolveCartProductIds(isAppend ? deltaPairs : undefined);
        const stillUnsynced = reResolvedItems.filter(item => item.shopProductId !== null && item.shopProductId < 0);
        if (stillUnsynced.length > 0) {
          console.warn('Some products still have temp IDs after sync:', stillUnsynced);
        }
        resolvedItems = reResolvedItems;
      }

      let result: { success: boolean; order?: any; offline?: boolean };

      if (isAppend) {
        const appendResult = await this.syncService.addItemsToOrder(this.lastOrder.id, resolvedItems);
        result = { success: appendResult.success, order: appendResult.order, offline: false };
      } else {
        const orderData = {
          items: resolvedItems,
          paymentMethod: this.selectedPaymentMethod,
          customerName: this.customerName || undefined,
          customerPhone: this.customerPhone || undefined,
          customerEmail: this.customerEmail || undefined,
          notes: this.orderNotes || undefined,
          subtotal: this.subtotal,
          taxAmount: this.taxAmount,
          discountAmount: this.billDiscount > 0 ? this.billDiscount : undefined,
          totalAmount: this.totalAmount
        };

        result = await this.syncService.createPosOrder(orderData, this.shopId, this.shopName);
      }

      this.swal.close();

      if (result.success) {
        const offlineMsg = result.offline ? ' (Saved offline)' : '';

        // Use toast notification instead of modal (doesn't block print)
        this.swal.toast(
          isAppend
            ? `Item added to Bill #${result.order?.orderNumber || ''} - ₹${this.totalAmount.toFixed(0)}`
            : `Bill Created - ₹${this.totalAmount.toFixed(0)}${offlineMsg}`,
          'success'
        );

        // Remember the created/updated order so it can be sent via WhatsApp afterwards.
        // Offline orders don't have a server id yet, so WhatsApp send stays disabled until synced.
        this.lastOrder = result.order;

        // Mark everything currently in the cart as billed up to its current
        // quantity, so the next print only sends whatever gets added after this.
        for (const item of this.cart) {
          this.billedQuantities.set(item, item.quantity);
        }

        // Bill is saved — drop the backup so a refresh can't restore an
        // already-billed cart and cause double billing. If the owner keeps
        // adding items afterwards, the next cart change re-creates it.
        localStorage.removeItem(this.POS_CART_BACKUP_KEY);

        // Print receipt
        this.printReceipt(result.order);

        // Auto-send the bill (WhatsApp/email) if enabled in bill settings
        this.autoSendBillAfterPrint();

        // Update local stock immediately (no need to reload all products) —
        // an append must only deduct the newly-added quantity, not the whole cart
        await this.updateLocalStockAfterBill(isAppend ? deltaPairs : undefined);

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
   * Auto-send the bill after printing, when enabled in bill settings.
   * Fire-and-forget with toasts only - never blocks the billing flow.
   * Manual WhatsApp/email share buttons keep working independently.
   */
  private autoSendBillAfterPrint(): void {
    const bs = this.billSettings;
    if (!bs.autoSendWhatsAppOnPrint && !bs.autoSendEmailOnPrint) return;

    // Anonymous walk-in bill (no customer added) - nothing to send to,
    // stay silent instead of nagging on every counter sale
    if (!this.canShareBill) return;

    if (!this.lastOrder?.id) {
      this.swal.toast('Bill saved offline - send it manually after it syncs', 'info');
      return;
    }
    const orderId = this.lastOrder.id;

    // Never auto-send to the shared walk-in placeholder number (90000 + shop id)
    const isWalkInPlaceholder = (p: string) => /^90000\d{5}$/.test(p || '');
    const orderName = this.lastOrder.customerName && !/walk-?in/i.test(this.lastOrder.customerName)
      ? this.lastOrder.customerName : '';
    const name = this.customerName || orderName;

    if (bs.autoSendWhatsAppOnPrint) {
      const phone = [this.customerPhone, this.lastOrder.customerPhone]
        .find(p => p && !isWalkInPlaceholder(p)) || '';
      if (phone) {
        this.syncService.sendWhatsAppBill(orderId, phone, name)
          .then(() => this.swal.toast('Bill sent on WhatsApp', 'success'))
          .catch(() => this.swal.toast('WhatsApp auto-send failed - use the Share button', 'warning'));
      } else {
        this.swal.toast('Add customer phone to auto-send bill on WhatsApp', 'info');
      }
    }

    if (bs.autoSendEmailOnPrint) {
      if (this.customerEmail) {
        this.syncService.sendEmailBill(orderId, this.customerEmail, name)
          .then(() => this.swal.toast('Bill sent by email', 'success'))
          .catch(() => this.swal.toast('Email auto-send failed - use the Email button', 'warning'));
      } else {
        this.swal.toast('Add customer email to auto-send the bill by email', 'info');
      }
    }
  }

  /**
   * Share is only possible when the bill has a real customer contact -
   * a phone number (not the walk-in placeholder) or an email.
   */
  get canShareBill(): boolean {
    const isWalkInPlaceholder = (p: string) => /^90000\d{5}$/.test(p || '');
    const phone = [this.customerPhone, this.lastOrder?.customerPhone]
      .find(p => p && !isWalkInPlaceholder(p));
    const isPlaceholderEmail = (e: string) => (e || '').endsWith('@pos.local');
    const email = [this.customerEmail, this.lastOrder?.customerEmail]
      .find(e => e && !isPlaceholderEmail(e));
    return !!(phone || email);
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
   * Share the last bill from the shop owner's OWN WhatsApp account: fetch the
   * bill links (image + PDF) from the server, show an editable message preview,
   * then open wa.me directly in the customer's chat. The owner taps send in
   * WhatsApp, so the customer receives the bill from the shop's number and can
   * reply straight to the shop.
   */
  async shareBillFromMyWhatsApp(): Promise<void> {
    if (!this.lastOrder) {
      this.swal.warning('No Bill Yet', 'Print a bill first before sharing it on WhatsApp');
      return;
    }
    if (!this.lastOrder.id) {
      this.swal.warning('Not Synced Yet', 'This bill was saved offline and needs to sync before it can be shared');
      return;
    }

    // Same phone resolution as sendBillOnWhatsApp: prefer the number typed in
    // the form now, never the shared walk-in placeholder (90000 + shop id)
    const isWalkInPlaceholder = (p: string) => /^90000\d{5}$/.test(p || '');
    let phone = [this.customerPhone, this.lastOrder.customerPhone]
      .find(p => p && !isWalkInPlaceholder(p)) || '';
    if (!phone) {
      const { value } = await this.swal.prompt(
        'Customer Phone Number',
        'Enter the customer\'s WhatsApp number to share the bill',
        'tel'
      );
      if (!value) return;
      phone = value;
    }

    this.sharingOwnWhatsApp = true;
    this.swal.loading('Preparing bill...');

    try {
      const links = await this.syncService.getBillShareLinks(this.lastOrder.id);
      this.swal.close();

      // Short text only — the bill goes as an actual FILE, not links. No emojis:
      // they arrived as broken characters (�) on WhatsApp desktop via wa.me.
      const shopName = this.billSettings.shopName || this.shopName || links.shopName || '';
      const lines = [
        `*${shopName}*`,
        `Bill No: ${links.orderNumber || this.lastOrder.orderNumber || ''}`,
        `Amount: Rs.${links.amount || ''}`,
        '',
        'நன்றி! Thank you for shopping with us'
      ];

      const digits = phone.replace(/\D/g, '');
      const waNumber = digits.length === 10 ? '91' + digits : digits;

      // Download the actual bill file to attach
      const fileUrl = links.imageUrl || links.pdfUrl;
      const isPdf = !links.imageUrl;
      let file: File | null = null;
      try {
        const resp = await fetch(fileUrl, { mode: 'cors', credentials: 'omit' });
        if (resp.ok) {
          const blob = await resp.blob();
          file = new File(
            [blob],
            `Bill-${links.orderNumber || this.lastOrder.orderNumber || 'receipt'}.${isPdf ? 'pdf' : 'jpg'}`,
            { type: blob.type || (isPdf ? 'application/pdf' : 'image/jpeg') }
          );
        }
      } catch {
        // fall through to text-only chat below
      }

      // Mobile/tablet ONLY: system share sheet sends the real file into WhatsApp,
      // with the text as the image CAPTION — one single message. Never on desktop:
      // the Windows share dialog can't preselect the customer's chat.
      const nav = navigator as any;
      const isMobileDevice = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
      if (isMobileDevice && file && nav.canShare && nav.canShare({ files: [file] })) {
        const { value: caption, isConfirmed } = await this.swal.promptTextarea(
          'Preview WhatsApp Message', lines.join('\n'), 'Send Bill'
        );
        if (!isConfirmed) return;
        await nav.share({ files: [file], text: caption || '' });
        return;
      }

      // Desktop: ONE message — the bill image itself. Copy it to the clipboard and
      // open the customer's chat with NO prefilled text (a separate text message
      // just duplicated what the bill image already shows); owner does Ctrl+V, Send.
      let copied = false;
      if (file && !isPdf && navigator.clipboard && (window as any).ClipboardItem) {
        try {
          const pngBlob = await this.imageFileToPng(file);
          await navigator.clipboard.write([
            new (window as any).ClipboardItem({ 'image/png': pngBlob })
          ]);
          copied = true;
        } catch {
          copied = false;
        }
      }

      if (copied) {
        window.open(`https://wa.me/${waNumber}`, '_blank');
        this.swal.success('Bill Copied',
          'In the WhatsApp chat press Ctrl+V to attach the bill image, then Send');
        return;
      }

      // Fallback (image missing or clipboard unsupported): editable text message
      const { value: message, isConfirmed } = await this.swal.promptTextarea(
        'Preview WhatsApp Message', lines.join('\n'), 'Send Bill'
      );
      if (!isConfirmed || !message) return;
      window.open(`https://wa.me/${waNumber}?text=${encodeURIComponent(message)}`, '_blank');
    } catch (error: any) {
      this.swal.close();
      const message = error?.error?.message || error?.message || 'Failed to prepare the bill for sharing';
      this.swal.error('Error', message);
    } finally {
      this.sharingOwnWhatsApp = false;
    }
  }

  /**
   * Convert the bill JPEG to PNG via canvas — the async Clipboard API only
   * accepts image/png, and the bill is rendered as JPEG on the server.
   */
  private async imageFileToPng(file: File): Promise<Blob> {
    const bitmap = await createImageBitmap(file);
    const canvas = document.createElement('canvas');
    canvas.width = bitmap.width;
    canvas.height = bitmap.height;
    canvas.getContext('2d')!.drawImage(bitmap, 0, 0);
    bitmap.close();
    return new Promise<Blob>((resolve, reject) =>
      canvas.toBlob(b => b ? resolve(b) : reject(new Error('PNG conversion failed')), 'image/png')
    );
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
    // Bill settings are edited on a separate route. Always reload the latest
    // saved values immediately before building the printable receipt.
    this.loadBillSettings();
    const paperConfig = this.receiptTemplate.getPaperConfig(this.billSettings.paperWidth || '80mm');
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
   * Generate receipt HTML via the shared ReceiptTemplateService so the
   * print output matches the Bill Settings live preview exactly
   * (async for QR code generation)
   */
  private async generateReceiptHtml(order: any): Promise<string> {
    const bs = this.billSettings;
    let qrCodeDataUrl = '';
    if (bs.showUpiQrCode && bs.upiId) {
      const qrSize = bs.paperWidth === '58mm' ? 80 : (bs.paperWidth === 'A4' ? 120 : 100);
      qrCodeDataUrl = await this.generateUpiQrCode(qrSize, this.totalAmount);
    }
    const storedShopName = localStorage.getItem('shop_name');
    const shopNameFallback = (order.shopName && order.shopName.trim()) ||
      (storedShopName && storedShopName.trim()) ||
      (this.shopName && this.shopName !== 'My Shop' ? this.shopName : '') || 'Shop';
    return this.receiptTemplate.generateReceiptHtml(bs, {
      orderRef: order.orderNumber || order.offlineOrderId || '',
      items: this.cart.map(item => ({
        name: item.product.name || '',
        nameTamil: item.product.nameTamil || '',
        mrp: item.mrp || item.unitPrice || 0,
        rate: item.unitPrice || 0,
        quantity: item.quantity,
        total: item.total
      })),
      subtotal: this.subtotal,
      totalMrp: this.totalMrp,
      totalDiscount: this.totalDiscount,
      billDiscount: this.billDiscount,
      totalAmount: this.totalAmount,
      paymentLabel: this.selectedPaymentMethod === 'CASH_ON_DELIVERY' ? 'CASH' : this.selectedPaymentMethod === 'UPI' ? 'UPI' : 'CARD',
      customerName: this.customerName || '',
      customerPhone: this.customerPhone || '',
      qrCodeDataUrl,
      shopNameFallback,
      includePrintButton: true
    });
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

      // Explicit refresh: this is the one place a shop owner asks to hit the
      // server on demand, so pull real changes rather than reusing the cache.
      await this.syncProductsInBackground();
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
   * Show bills the server permanently rejected on sync (e.g. insufficient
   * stock because another device sold the same units first). Cash was
   * already collected for these - lets the owner retry (after fixing stock)
   * or discard (if reconciled some other way, e.g. a manual refund).
   */
  async viewFailedOrders(): Promise<void> {
    const failed = await this.syncService.getFailedOrders();
    if (failed.length === 0) {
      this.swal.success('All Clear', 'No failed bills to review.');
      return;
    }

    const rows = failed.map(o => `
      <div style="text-align:left;border:1px solid #eee;border-radius:8px;padding:10px;margin-bottom:8px;">
        <div style="display:flex;justify-content:space-between;">
          <strong>${o.offlineOrderId}</strong>
          <span>₹${o.totalAmount}</span>
        </div>
        <div style="color:#666;font-size:0.85em;">${o.customerName || 'Walk-in'} &bull; ${new Date(o.createdAt).toLocaleString()}</div>
        <div style="color:#ef4444;font-size:0.85em;margin-top:4px;">${o.syncError || 'Rejected by server'}</div>
      </div>
    `).join('');

    const result = await this.swal.custom({
      title: `${failed.length} bill(s) need review`,
      html: `<div style="max-height:300px;overflow-y:auto;">${rows}</div>
             <p style="font-size:0.85em;color:#666;margin-top:8px;">These bills were paid by the customer but could not be recorded on the server. Retry after fixing stock, or discard if you've already reconciled it manually.</p>`,
      showCancelButton: true,
      showDenyButton: true,
      confirmButtonText: 'Retry All',
      denyButtonText: 'Discard All',
      cancelButtonText: 'Close',
      confirmButtonColor: '#22c55e',
      denyButtonColor: '#ef4444'
    });

    if (result.isConfirmed) {
      this.swal.loading('Retrying...');
      let succeeded = 0;
      let stillFailed = 0;
      for (const o of failed) {
        const r = await this.syncService.retryFailedOrder(o.offlineOrderId);
        if (r.success) {
          succeeded++;
        } else {
          stillFailed++;
        }
      }
      this.swal.close();
      if (stillFailed > 0) {
        this.swal.warning('Retry complete', `${succeeded} synced, ${stillFailed} still failing - review again.`);
      } else {
        this.swal.success('All synced', `${succeeded} bill(s) synced successfully.`);
      }
      // Retried orders may have changed stock on the server - pull that now.
      await this.syncProductsInBackground();
    } else if (result.isDenied) {
      const confirmResult = await this.swal.confirmDelete(`${failed.length} failed bill(s)`);
      if (confirmResult.isConfirmed) {
        for (const o of failed) {
          await this.syncService.discardFailedOrder(o.offlineOrderId);
        }
        this.swal.success('Discarded', 'Failed bills removed from the queue.');
      }
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

  // Print-flow state: ask for customer details once per bill when Print is
  // clicked with no customer set
  customerAskedForThisBill = false;
  printAfterCustomerModal = false;

  openCustomerModal(): void {
    this.showCustomerModal = true;
    this.showCustomerSuggestions = false;
  }

  closeCustomerModal(): void {
    this.showCustomerModal = false;
    this.showCustomerSuggestions = false;
    // Closed without choosing print: don't auto-print, don't re-ask this bill
    this.printAfterCustomerModal = false;
  }

  /** "Skip & Print" from the pre-print customer ask - anonymous walk-in bill */
  skipCustomerAndPrint(): void {
    this.clearCustomer();
    this.showCustomerModal = false;
    this.showCustomerSuggestions = false;
    this.printAfterCustomerModal = false;
    this.generateBill();
  }

  /** "Save & Print" from the pre-print customer ask */
  saveCustomerAndPrint(): void {
    this.showCustomerModal = false;
    this.showCustomerSuggestions = false;
    this.printAfterCustomerModal = false;
    this.generateBill();
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
  private async resolveCartProductIds(
    pairs?: Array<{ item: CartItem; quantity: number }>
  ): Promise<Array<{ shopProductId: number | null; quantity: number; unitPrice: number; productName: string }>> {
    // Refresh products from cache to get latest IDs after sync
    const cachedProducts = await this.offlineStorage.getProducts();

    const source = pairs ?? this.cart.map(item => ({ item, quantity: item.quantity }));

    return source.map(({ item, quantity }) => {
      let resolvedId: number | null = item.product.id;

      // Weight lines: the server's quantity is a whole number, so a 250g sale is
      // billed as one line whose unit price is the computed total, with the
      // weight in the printed name ("Tomato 250g"). No product link / stock move.
      if (item.weightGrams && item.weightGrams > 0) {
        return {
          shopProductId: null,
          quantity: 1,
          unitPrice: item.total,
          productName: `${item.product.name} ${this.formatWeight(item.weightGrams)}`
        };
      }

      // Custom "Quick Add" items have no catalog product - the server bills them
      // by the typed name and price (null product ID)
      if (item.product.sku === 'CUSTOM') {
        return {
          shopProductId: null,
          quantity,
          unitPrice: item.unitPrice,
          productName: item.product.name
        };
      }

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
        quantity,
        unitPrice: item.unitPrice,
        productName: item.product.name
      };
    });
  }

  /**
   * Update local stock after creating a bill (fast - no server reload needed)
   */
  private async updateLocalStockAfterBill(pairs?: Array<{ item: CartItem; quantity: number }>): Promise<void> {
    // Track only the products whose stock actually changed so we persist just those,
    // instead of rewriting the entire ~2500-product IndexedDB store on every sale.
    const changedProducts: CachedProduct[] = [];

    // Deduct stock for each billed item locally - defaults to the whole cart, but an
    // append (only the newly added quantity) must pass its own delta pairs, or the
    // items already deducted on the first print would be deducted again here.
    const source = pairs ?? this.cart.map(item => ({ item, quantity: item.quantity }));
    for (const { item: cartItem, quantity: quantitySold } of source) {
      // Weight lines are billed without a product link — no stock movement
      if (cartItem.weightGrams) continue;
      const productId = cartItem.product.id;

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
    this.newProductUnit = 'piece';
  }

  /** Sell-by toggle: weight items skip piece-count inventory tracking */
  setNewProductUnit(unit: 'piece' | 'kg'): void {
    this.newProductUnit = unit;
    if (unit === 'kg') {
      this.newProductTrackInventory = false;
      this.newProductStock = 0;
    } else {
      this.newProductTrackInventory = true;
    }
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
    this.newProductUnit = 'piece';
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
        stockQuantity: this.newProductUnit === 'kg' ? 0 : (this.newProductStock || 0),
        trackInventory: this.newProductUnit === 'kg' ? false : this.newProductTrackInventory,
        unit: this.newProductUnit,
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
          stock: this.newProductUnit === 'kg' ? 0 : (this.newProductStock || 0),
          trackInventory: this.newProductUnit === 'kg' ? false : this.newProductTrackInventory,
          unit: this.newProductUnit,
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
