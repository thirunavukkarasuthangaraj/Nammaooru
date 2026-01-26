import { Injectable } from '@angular/core';

export interface CachedProduct {
  id: number;
  shopId?: number;  // Shop ID for the product
  name: string;
  nameTamil?: string;
  description?: string;
  price: number;
  originalPrice?: number;  // MRP price for discount calculation
  costPrice?: number;  // Cost price for profit calculation
  stock: number;
  minStockLevel?: number;  // Minimum stock level for alerts
  maxStockLevel?: number;  // Maximum stock level
  trackInventory: boolean;
  isAvailable?: boolean;  // Product availability status
  sku: string;
  barcode?: string;
  // Shop-level multiple barcodes
  barcode1?: string;
  barcode2?: string;
  barcode3?: string;
  image?: string;
  imageUrl?: string;  // Full image URL
  imageBase64?: string;  // Cached image for offline use
  categoryId?: number;
  categoryName?: string;
  category?: string;  // Category name shorthand
  // Label printing fields (saved with product)
  netQty?: string;  // e.g. "250g", "1kg"
  packedDate?: string;  // MM/YY format
  expiryDate?: string;  // MM/YY format
  unit?: string;
  weight?: number;
  masterProductId?: number;  // Reference to master product
}

export interface OfflineOrder {
  offlineOrderId: string;
  shopId: number;
  items: {
    shopProductId: number;
    quantity: number;
    unitPrice: number;
    productName: string;
  }[];
  paymentMethod: string;
  customerName?: string;
  customerPhone?: string;
  notes?: string;
  totalAmount: number;
  subtotal: number;
  taxAmount: number;
  createdAt: string;
  synced: boolean;
}

export interface OfflineEdit {
  editId: string;
  productId: number;
  shopId: number;
  changes: {
    price?: number;
    originalPrice?: number;
    stockQuantity?: number;
    barcode?: string;
    barcode1?: string;
    barcode2?: string;
    barcode3?: string;
    customName?: string;
    nameTamil?: string;
    netQty?: string;
    packedDate?: string;
    expiryDate?: string;
  };
  previousValues: {
    price?: number;
    originalPrice?: number;
    stockQuantity?: number;
    barcode?: string;
    barcode1?: string;
    barcode2?: string;
    barcode3?: string;
    name?: string;
    nameTamil?: string;
    netQty?: string;
    packedDate?: string;
    expiryDate?: string;
  };
  createdAt: string;
  synced: boolean;
  syncError?: string;
}

// Offline product creation (for adding new products when offline)
export interface OfflineProductCreation {
  offlineProductId: string;  // Temporary ID for offline product
  shopId: number;
  masterProductId?: number;  // If adding from master catalog
  // Product details
  name: string;
  nameTamil?: string;
  price: number;
  originalPrice?: number;
  costPrice?: number;
  stockQuantity: number;
  minStockLevel?: number;
  trackInventory: boolean;
  // Barcodes
  barcode1: string;  // Required
  barcode2?: string;
  barcode3?: string;
  // Other fields
  customName?: string;
  customDescription?: string;
  isFeatured?: boolean;
  tags?: string;
  sku?: string;
  categoryName?: string;
  categoryId?: number;
  unit?: string;
  // Image (base64 for offline, will be uploaded when syncing)
  imageBase64?: string;
  imagePendingUpload?: boolean;
  // Sync status
  tempProductId?: number;  // Negative temp ID used in local cache
  createdAt: string;
  synced: boolean;
  syncedProductId?: number;  // Actual product ID after sync
  syncError?: string;
}

const DB_NAME = 'NammaOoruPOS';
const DB_VERSION = 3;  // Incremented for offlineProductCreations store
const PRODUCTS_STORE = 'products';
const ORDERS_STORE = 'offlineOrders';
const EDITS_STORE = 'offlineEdits';
const PRODUCT_CREATIONS_STORE = 'offlineProductCreations';
const SYNC_META_STORE = 'syncMeta';

@Injectable({
  providedIn: 'root'
})
export class OfflineStorageService {
  private db: IDBDatabase | null = null;
  private dbReady: Promise<IDBDatabase>;

  constructor() {
    this.dbReady = this.initializeDB();
  }

  /**
   * Initialize IndexedDB with timeout
   */
  private initializeDB(): Promise<IDBDatabase> {
    return new Promise((resolve, reject) => {
      // Timeout after 5 seconds to prevent hanging
      const timeout = setTimeout(() => {
        console.error('IndexedDB initialization timed out');
        reject(new Error('IndexedDB initialization timed out'));
      }, 5000);

      try {
        const request = indexedDB.open(DB_NAME, DB_VERSION);

        request.onerror = () => {
          clearTimeout(timeout);
          console.error('Failed to open IndexedDB:', request.error);
          reject(request.error);
        };

        request.onsuccess = () => {
          clearTimeout(timeout);
          this.db = request.result;
          console.log('IndexedDB initialized successfully');
          resolve(this.db);
        };

        request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;

        // Products store - indexed by id, barcode, sku for fast lookup
        if (!db.objectStoreNames.contains(PRODUCTS_STORE)) {
          const productStore = db.createObjectStore(PRODUCTS_STORE, { keyPath: 'id' });
          productStore.createIndex('barcode', 'barcode', { unique: false });
          productStore.createIndex('sku', 'sku', { unique: false });
          productStore.createIndex('name', 'name', { unique: false });
        }

        // Offline orders store
        if (!db.objectStoreNames.contains(ORDERS_STORE)) {
          const orderStore = db.createObjectStore(ORDERS_STORE, { keyPath: 'offlineOrderId' });
          orderStore.createIndex('synced', 'synced', { unique: false });
          orderStore.createIndex('createdAt', 'createdAt', { unique: false });
        }

        // Offline edits store (for product updates when offline)
        if (!db.objectStoreNames.contains(EDITS_STORE)) {
          const editsStore = db.createObjectStore(EDITS_STORE, { keyPath: 'editId' });
          editsStore.createIndex('productId', 'productId', { unique: false });
          editsStore.createIndex('synced', 'synced', { unique: false });
          editsStore.createIndex('createdAt', 'createdAt', { unique: false });
        }

        // Offline product creations store (for new products when offline)
        if (!db.objectStoreNames.contains(PRODUCT_CREATIONS_STORE)) {
          const creationsStore = db.createObjectStore(PRODUCT_CREATIONS_STORE, { keyPath: 'offlineProductId' });
          creationsStore.createIndex('shopId', 'shopId', { unique: false });
          creationsStore.createIndex('synced', 'synced', { unique: false });
          creationsStore.createIndex('createdAt', 'createdAt', { unique: false });
          creationsStore.createIndex('barcode1', 'barcode1', { unique: false });
        }

        // Sync metadata store
        if (!db.objectStoreNames.contains(SYNC_META_STORE)) {
          db.createObjectStore(SYNC_META_STORE, { keyPath: 'key' });
        }
      };
      } catch (e) {
        clearTimeout(timeout);
        console.error('IndexedDB not available:', e);
        reject(e);
      }
    });
  }

  /**
   * Get database instance
   */
  private async getDB(): Promise<IDBDatabase> {
    if (this.db) return this.db;
    return this.dbReady;
  }

  // ==================== PRODUCTS ====================

  /**
   * Save products to cache
   */
  async saveProducts(products: CachedProduct[], shopId: number): Promise<void> {
    const db = await this.getDB();
    const transaction = db.transaction([PRODUCTS_STORE, SYNC_META_STORE], 'readwrite');
    const store = transaction.objectStore(PRODUCTS_STORE);
    const metaStore = transaction.objectStore(SYNC_META_STORE);

    // Clear old products first
    await this.clearStore(store);

    // Add new products
    for (const product of products) {
      store.put(product);
    }

    // Update sync timestamp
    metaStore.put({
      key: `products_sync_${shopId}`,
      timestamp: new Date().toISOString(),
      count: products.length
    });

    return new Promise((resolve, reject) => {
      transaction.oncomplete = () => {
        console.log(`Cached ${products.length} products for shop ${shopId}`);
        resolve();
      };
      transaction.onerror = () => reject(transaction.error);
    });
  }

  /**
   * Add a single product to cache (for newly created products)
   */
  async addProductToCache(product: Partial<CachedProduct>): Promise<void> {
    const db = await this.getDB();
    const transaction = db.transaction(PRODUCTS_STORE, 'readwrite');
    const store = transaction.objectStore(PRODUCTS_STORE);

    return new Promise((resolve, reject) => {
      const request = store.put(product);
      request.onsuccess = () => {
        console.log('Product added to cache:', product.id);
        resolve();
      };
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get all cached products
   */
  async getProducts(): Promise<CachedProduct[]> {
    const db = await this.getDB();
    const transaction = db.transaction(PRODUCTS_STORE, 'readonly');
    const store = transaction.objectStore(PRODUCTS_STORE);

    return new Promise((resolve, reject) => {
      const request = store.getAll();
      request.onsuccess = () => resolve(request.result || []);
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Find product by barcode
   */
  async findByBarcode(barcode: string): Promise<CachedProduct | null> {
    const db = await this.getDB();
    const transaction = db.transaction(PRODUCTS_STORE, 'readonly');
    const store = transaction.objectStore(PRODUCTS_STORE);
    const index = store.index('barcode');

    return new Promise((resolve, reject) => {
      const request = index.get(barcode);
      request.onsuccess = () => resolve(request.result || null);
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Find product by SKU
   */
  async findBySku(sku: string): Promise<CachedProduct | null> {
    const db = await this.getDB();
    const transaction = db.transaction(PRODUCTS_STORE, 'readonly');
    const store = transaction.objectStore(PRODUCTS_STORE);
    const index = store.index('sku');

    return new Promise((resolve, reject) => {
      const request = index.get(sku);
      request.onsuccess = () => resolve(request.result || null);
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Search products by name (local search)
   */
  async searchProducts(query: string): Promise<CachedProduct[]> {
    const products = await this.getProducts();
    const lowerQuery = query.toLowerCase();

    return products.filter(p =>
      p.name.toLowerCase().includes(lowerQuery) ||
      (p.nameTamil && p.nameTamil.toLowerCase().includes(lowerQuery)) ||
      (p.sku && p.sku.toLowerCase().includes(lowerQuery)) ||
      (p.barcode && p.barcode.toLowerCase().includes(lowerQuery)) ||
      (p.barcode1 && p.barcode1.toLowerCase().includes(lowerQuery)) ||
      (p.barcode2 && p.barcode2.toLowerCase().includes(lowerQuery)) ||
      (p.barcode3 && p.barcode3.toLowerCase().includes(lowerQuery))
    );
  }

  /**
   * Get last sync timestamp for products
   */
  async getProductsSyncTime(shopId: number): Promise<Date | null> {
    const db = await this.getDB();
    const transaction = db.transaction(SYNC_META_STORE, 'readonly');
    const store = transaction.objectStore(SYNC_META_STORE);

    return new Promise((resolve, reject) => {
      const request = store.get(`products_sync_${shopId}`);
      request.onsuccess = () => {
        const result = request.result;
        resolve(result ? new Date(result.timestamp) : null);
      };
      request.onerror = () => reject(request.error);
    });
  }

  // ==================== OFFLINE ORDERS ====================

  /**
   * Save offline order
   */
  async saveOfflineOrder(order: OfflineOrder): Promise<void> {
    const db = await this.getDB();
    const transaction = db.transaction(ORDERS_STORE, 'readwrite');
    const store = transaction.objectStore(ORDERS_STORE);

    return new Promise((resolve, reject) => {
      const request = store.put(order);
      request.onsuccess = () => {
        console.log('Offline order saved:', order.offlineOrderId);
        resolve();
      };
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get all pending (unsynced) orders
   */
  async getPendingOrders(): Promise<OfflineOrder[]> {
    // Get all orders and filter - IndexedDB doesnt support boolean keys
    const allOrders = await this.getAllOfflineOrders();
    return allOrders.filter(order => order.synced === false);
  }

  /**
   * Get all offline orders
   */
  async getAllOfflineOrders(): Promise<OfflineOrder[]> {
    const db = await this.getDB();
    const transaction = db.transaction(ORDERS_STORE, 'readonly');
    const store = transaction.objectStore(ORDERS_STORE);

    return new Promise((resolve, reject) => {
      const request = store.getAll();
      request.onsuccess = () => resolve(request.result || []);
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Mark order as synced
   */
  async markOrderSynced(offlineOrderId: string): Promise<void> {
    const db = await this.getDB();
    const transaction = db.transaction(ORDERS_STORE, 'readwrite');
    const store = transaction.objectStore(ORDERS_STORE);

    return new Promise((resolve, reject) => {
      const getRequest = store.get(offlineOrderId);
      getRequest.onsuccess = () => {
        const order = getRequest.result;
        if (order) {
          order.synced = true;
          const putRequest = store.put(order);
          putRequest.onsuccess = () => resolve();
          putRequest.onerror = () => reject(putRequest.error);
        } else {
          resolve();
        }
      };
      getRequest.onerror = () => reject(getRequest.error);
    });
  }

  /**
   * Remove synced order
   */
  async removeOfflineOrder(offlineOrderId: string): Promise<void> {
    const db = await this.getDB();
    const transaction = db.transaction(ORDERS_STORE, 'readwrite');
    const store = transaction.objectStore(ORDERS_STORE);

    return new Promise((resolve, reject) => {
      const request = store.delete(offlineOrderId);
      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get pending orders count
   */
  async getPendingOrdersCount(): Promise<number> {
    const pending = await this.getPendingOrders();
    return pending.length;
  }

  // ==================== OFFLINE EDITS ====================

  /**
   * Save offline product edit
   */
  async saveOfflineEdit(edit: OfflineEdit): Promise<void> {
    const db = await this.getDB();
    const transaction = db.transaction(EDITS_STORE, 'readwrite');
    const store = transaction.objectStore(EDITS_STORE);

    return new Promise((resolve, reject) => {
      const request = store.put(edit);
      request.onsuccess = () => {
        console.log('Offline edit saved:', edit.editId);
        resolve();
      };
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get all pending (unsynced) edits
   */
  async getPendingEdits(): Promise<OfflineEdit[]> {
    const allEdits = await this.getAllOfflineEdits();
    return allEdits.filter(edit => edit.synced === false);
  }

  /**
   * Get all offline edits
   */
  async getAllOfflineEdits(): Promise<OfflineEdit[]> {
    const db = await this.getDB();
    const transaction = db.transaction(EDITS_STORE, 'readonly');
    const store = transaction.objectStore(EDITS_STORE);

    return new Promise((resolve, reject) => {
      const request = store.getAll();
      request.onsuccess = () => resolve(request.result || []);
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Mark edit as synced
   */
  async markEditSynced(editId: string): Promise<void> {
    const db = await this.getDB();
    const transaction = db.transaction(EDITS_STORE, 'readwrite');
    const store = transaction.objectStore(EDITS_STORE);

    return new Promise((resolve, reject) => {
      const getRequest = store.get(editId);
      getRequest.onsuccess = () => {
        const edit = getRequest.result;
        if (edit) {
          edit.synced = true;
          const putRequest = store.put(edit);
          putRequest.onsuccess = () => resolve();
          putRequest.onerror = () => reject(putRequest.error);
        } else {
          resolve();
        }
      };
      getRequest.onerror = () => reject(getRequest.error);
    });
  }

  /**
   * Remove synced edit
   */
  async removeOfflineEdit(editId: string): Promise<void> {
    const db = await this.getDB();
    const transaction = db.transaction(EDITS_STORE, 'readwrite');
    const store = transaction.objectStore(EDITS_STORE);

    return new Promise((resolve, reject) => {
      const request = store.delete(editId);
      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get pending edits count
   */
  async getPendingEditsCount(): Promise<number> {
    const pending = await this.getPendingEdits();
    return pending.length;
  }

  /**
   * Update local product in cache (for offline edits)
   */
  async updateLocalProduct(productId: number, changes: Partial<CachedProduct>): Promise<void> {
    const db = await this.getDB();
    const transaction = db.transaction(PRODUCTS_STORE, 'readwrite');
    const store = transaction.objectStore(PRODUCTS_STORE);

    return new Promise((resolve, reject) => {
      const getRequest = store.get(productId);
      getRequest.onsuccess = () => {
        const product = getRequest.result;
        if (product) {
          // Apply changes
          if (changes.price !== undefined) product.price = changes.price;
          if (changes.originalPrice !== undefined) product.originalPrice = changes.originalPrice;
          if (changes.stock !== undefined) product.stock = changes.stock;
          if (changes.barcode !== undefined) product.barcode = changes.barcode;
          if (changes.barcode1 !== undefined) product.barcode1 = changes.barcode1;
          if (changes.barcode2 !== undefined) product.barcode2 = changes.barcode2;
          if (changes.barcode3 !== undefined) product.barcode3 = changes.barcode3;
          if (changes.name !== undefined) product.name = changes.name;
          if (changes.nameTamil !== undefined) product.nameTamil = changes.nameTamil;
          if (changes.imageBase64 !== undefined) product.imageBase64 = changes.imageBase64;
          if (changes.netQty !== undefined) product.netQty = changes.netQty;
          if (changes.packedDate !== undefined) product.packedDate = changes.packedDate;
          if (changes.expiryDate !== undefined) product.expiryDate = changes.expiryDate;

          const putRequest = store.put(product);
          putRequest.onsuccess = () => {
            console.log('Local product updated:', productId);
            resolve();
          };
          putRequest.onerror = () => reject(putRequest.error);
        } else {
          resolve();
        }
      };
      getRequest.onerror = () => reject(getRequest.error);
    });
  }

  /**
   * Generate unique offline edit ID
   */
  generateOfflineEditId(): string {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 8);
    return `EDIT-${timestamp}-${random}`;
  }

  // ==================== UTILITIES ====================

  /**
   * Check if online
   */
  isOnline(): boolean {
    return navigator.onLine;
  }

  /**
   * Clear a store
   */
  private clearStore(store: IDBObjectStore): Promise<void> {
    return new Promise((resolve, reject) => {
      const request = store.clear();
      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Generate unique offline order ID
   * Format: POS-XXXX (short, sequential counter with date prefix)
   */
  generateOfflineOrderId(): string {
    // Get current date in DDMM format
    const now = new Date();
    const day = now.getDate().toString().padStart(2, '0');
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const datePrefix = `${day}${month}`;

    // Get current counter from localStorage (resets daily)
    const counterKey = `pos_order_counter_${datePrefix}`;
    let counter = parseInt(localStorage.getItem(counterKey) || '0', 10);
    counter++;

    // Save updated counter
    localStorage.setItem(counterKey, counter.toString());

    // Format: POS-1301-001 (date + sequential)
    const paddedCounter = counter.toString().padStart(3, '0');
    return `POS-${datePrefix}-${paddedCounter}`;
  }

  /**
   * Update local stock after order (for offline mode)
   */
  async updateLocalStock(productId: number, quantitySold: number): Promise<void> {
    const db = await this.getDB();
    const transaction = db.transaction(PRODUCTS_STORE, 'readwrite');
    const store = transaction.objectStore(PRODUCTS_STORE);

    return new Promise((resolve, reject) => {
      const getRequest = store.get(productId);
      getRequest.onsuccess = () => {
        const product = getRequest.result;
        if (product && product.trackInventory) {
          product.stock = Math.max(0, product.stock - quantitySold);
          const putRequest = store.put(product);
          putRequest.onsuccess = () => resolve();
          putRequest.onerror = () => reject(putRequest.error);
        } else {
          resolve();
        }
      };
      getRequest.onerror = () => reject(getRequest.error);
    });
  }

  // ==================== OFFLINE PRODUCT CREATIONS ====================

  /**
   * Generate unique offline product ID
   * Format: OFFPROD-timestamp-random (negative to distinguish from real IDs)
   */
  generateOfflineProductId(): string {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 8);
    return `OFFPROD-${timestamp}-${random}`;
  }

  /**
   * Generate a temporary numeric ID for local product cache
   * Uses negative numbers to avoid collision with real product IDs
   */
  generateTempProductId(): number {
    return -Math.floor(Date.now() + Math.random() * 1000);
  }

  /**
   * Check if a barcode already exists in products or pending creations
   * Checks against: SKU, master barcode, barcode1, barcode2, barcode3
   */
  async isBarcodeExists(barcode: string, excludeProductId?: number): Promise<boolean> {
    if (!barcode || barcode.trim() === '') return false;

    const trimmedBarcode = barcode.trim().toLowerCase();

    // Check in cached products (including SKU)
    const products = await this.getProducts();
    const existsInProducts = products.some(p => {
      if (excludeProductId && p.id === excludeProductId) return false;
      return (
        (p.sku && p.sku.toLowerCase() === trimmedBarcode) ||
        (p.barcode && p.barcode.toLowerCase() === trimmedBarcode) ||
        (p.barcode1 && p.barcode1.toLowerCase() === trimmedBarcode) ||
        (p.barcode2 && p.barcode2.toLowerCase() === trimmedBarcode) ||
        (p.barcode3 && p.barcode3.toLowerCase() === trimmedBarcode)
      );
    });

    if (existsInProducts) return true;

    // Check in pending offline creations
    // If excludeProductId is provided, also skip pending creations that match
    // (the product being edited might be in the pending creations store)
    const pendingCreations = await this.getPendingProductCreations();
    const existsInPending = pendingCreations.some(c => {
      // Skip if this pending creation is for the product being edited
      // Match by checking if the excluded product's barcodes overlap with this creation's barcodes
      if (excludeProductId) {
        const excludedProduct = products.find(p => p.id === excludeProductId);
        if (excludedProduct) {
          const excludedBarcodes = [excludedProduct.barcode1, excludedProduct.barcode2, excludedProduct.barcode3]
            .filter(b => b).map(b => b!.toLowerCase());
          const creationBarcodes = [c.barcode1, c.barcode2, c.barcode3]
            .filter(b => b).map(b => b!.toLowerCase());
          const isMatch = creationBarcodes.some(cb => excludedBarcodes.includes(cb));
          if (isMatch) return false;
        }
      }
      return (
        (c.sku && c.sku.toLowerCase() === trimmedBarcode) ||
        (c.barcode1 && c.barcode1.toLowerCase() === trimmedBarcode) ||
        (c.barcode2 && c.barcode2.toLowerCase() === trimmedBarcode) ||
        (c.barcode3 && c.barcode3.toLowerCase() === trimmedBarcode)
      );
    });

    return existsInPending;
  }

  /**
   * Validate barcodes for a product (used for both create and edit)
   * Returns error message if validation fails, null if valid
   */
  async validateBarcodes(barcode1: string | null, barcode2: string | null, barcode3: string | null, excludeProductId?: number): Promise<string | null> {
    const b1 = barcode1?.trim() || null;
    const b2 = barcode2?.trim() || null;
    const b3 = barcode3?.trim() || null;

    // Check for duplicate barcodes within same product
    if (b1 && b2 && b1.toLowerCase() === b2.toLowerCase()) {
      return 'Barcode 1 and Barcode 2 cannot be the same.';
    }
    if (b1 && b3 && b1.toLowerCase() === b3.toLowerCase()) {
      return 'Barcode 1 and Barcode 3 cannot be the same.';
    }
    if (b2 && b3 && b2.toLowerCase() === b3.toLowerCase()) {
      return 'Barcode 2 and Barcode 3 cannot be the same.';
    }

    // Check for duplicate barcodes against other products
    if (b1 && await this.isBarcodeExists(b1, excludeProductId)) {
      return `Barcode '${b1}' already exists. Please use a unique barcode.`;
    }
    if (b2 && await this.isBarcodeExists(b2, excludeProductId)) {
      return `Barcode '${b2}' already exists. Please use a unique barcode.`;
    }
    if (b3 && await this.isBarcodeExists(b3, excludeProductId)) {
      return `Barcode '${b3}' already exists. Please use a unique barcode.`;
    }

    return null; // Validation passed
  }

  /**
   * Save offline product creation with duplicate barcode validation
   */
  async saveOfflineProductCreation(creation: OfflineProductCreation): Promise<void> {
    const b1 = creation.barcode1?.trim() || null;
    const b2 = creation.barcode2?.trim() || null;
    const b3 = creation.barcode3?.trim() || null;

    // Check for duplicate barcodes within same product
    if (b1 && b2 && b1.toLowerCase() === b2.toLowerCase()) {
      throw new Error('Barcode 1 and Barcode 2 cannot be the same.');
    }
    if (b1 && b3 && b1.toLowerCase() === b3.toLowerCase()) {
      throw new Error('Barcode 1 and Barcode 3 cannot be the same.');
    }
    if (b2 && b3 && b2.toLowerCase() === b3.toLowerCase()) {
      throw new Error('Barcode 2 and Barcode 3 cannot be the same.');
    }

    // Validate duplicate barcodes against other products
    const barcodesToCheck = [b1, b2, b3].filter(b => b && b.trim() !== '');

    for (const barcode of barcodesToCheck) {
      if (barcode && await this.isBarcodeExists(barcode)) {
        throw new Error(`Barcode '${barcode}' already exists. Please use a unique barcode.`);
      }
    }

    const db = await this.getDB();
    const transaction = db.transaction(PRODUCT_CREATIONS_STORE, 'readwrite');
    const store = transaction.objectStore(PRODUCT_CREATIONS_STORE);

    return new Promise((resolve, reject) => {
      const request = store.put(creation);
      request.onsuccess = () => {
        console.log('Offline product creation saved:', creation.offlineProductId);
        resolve();
      };
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get all pending (unsynced) product creations
   */
  async getPendingProductCreations(): Promise<OfflineProductCreation[]> {
    const allCreations = await this.getAllOfflineProductCreations();
    return allCreations.filter(creation => creation.synced === false);
  }

  /**
   * Get all offline product creations
   */
  async getAllOfflineProductCreations(): Promise<OfflineProductCreation[]> {
    const db = await this.getDB();
    const transaction = db.transaction(PRODUCT_CREATIONS_STORE, 'readonly');
    const store = transaction.objectStore(PRODUCT_CREATIONS_STORE);

    return new Promise((resolve, reject) => {
      const request = store.getAll();
      request.onsuccess = () => resolve(request.result || []);
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Mark product creation as synced
   */
  async markProductCreationSynced(offlineProductId: string, syncedProductId: number): Promise<void> {
    const db = await this.getDB();
    const transaction = db.transaction(PRODUCT_CREATIONS_STORE, 'readwrite');
    const store = transaction.objectStore(PRODUCT_CREATIONS_STORE);

    return new Promise((resolve, reject) => {
      const getRequest = store.get(offlineProductId);
      getRequest.onsuccess = () => {
        const creation = getRequest.result;
        if (creation) {
          creation.synced = true;
          creation.syncedProductId = syncedProductId;
          const putRequest = store.put(creation);
          putRequest.onsuccess = () => resolve();
          putRequest.onerror = () => reject(putRequest.error);
        } else {
          resolve();
        }
      };
      getRequest.onerror = () => reject(getRequest.error);
    });
  }

  /**
   * Update product creation sync error
   */
  async updateProductCreationError(offlineProductId: string, error: string): Promise<void> {
    const db = await this.getDB();
    const transaction = db.transaction(PRODUCT_CREATIONS_STORE, 'readwrite');
    const store = transaction.objectStore(PRODUCT_CREATIONS_STORE);

    return new Promise((resolve, reject) => {
      const getRequest = store.get(offlineProductId);
      getRequest.onsuccess = () => {
        const creation = getRequest.result;
        if (creation) {
          creation.syncError = error;
          const putRequest = store.put(creation);
          putRequest.onsuccess = () => resolve();
          putRequest.onerror = () => reject(putRequest.error);
        } else {
          resolve();
        }
      };
      getRequest.onerror = () => reject(getRequest.error);
    });
  }

  /**
   * Remove offline product creation
   */
  async removeOfflineProductCreation(offlineProductId: string): Promise<void> {
    const db = await this.getDB();
    const transaction = db.transaction(PRODUCT_CREATIONS_STORE, 'readwrite');
    const store = transaction.objectStore(PRODUCT_CREATIONS_STORE);

    return new Promise((resolve, reject) => {
      const request = store.delete(offlineProductId);
      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get pending product creations count
   */
  async getPendingProductCreationsCount(): Promise<number> {
    const pending = await this.getPendingProductCreations();
    return pending.length;
  }

  /**
   * Apply edit changes to a pending offline product creation record.
   * Used when a product is created offline, then edited offline before sync.
   * The edit values are merged into the creation so the server gets the latest data.
   */
  async applyEditToProductCreation(tempProductId: number, changes: {
    price?: number;
    originalPrice?: number;
    stockQuantity?: number;
    barcode?: string;
    barcode1?: string;
    barcode2?: string;
    barcode3?: string;
    customName?: string;
    nameTamil?: string;
  }): Promise<boolean> {
    const pendingCreations = await this.getPendingProductCreations();
    // Find creation by matching against the cached temp product
    const products = await this.getProducts();
    const tempProduct = products.find(p => p.id === tempProductId);
    if (!tempProduct) return false;

    // Match by name + shopId since barcode might be empty at creation time
    const creation = pendingCreations.find(c => {
      const nameMatch = (c.customName || c.name) === tempProduct.name;
      const shopMatch = c.shopId === tempProduct.shopId;
      // Also try barcode match if both have barcodes
      const barcodeMatch = c.barcode1 && tempProduct.barcode1 && c.barcode1 === tempProduct.barcode1;
      return (nameMatch && shopMatch) || barcodeMatch;
    });
    if (!creation) return false;

    // Merge changes into creation
    if (changes.price !== undefined) creation.price = changes.price;
    if (changes.originalPrice !== undefined) creation.originalPrice = changes.originalPrice;
    if (changes.stockQuantity !== undefined) creation.stockQuantity = changes.stockQuantity;
    if (changes.barcode1 !== undefined) creation.barcode1 = changes.barcode1;
    if (changes.barcode2 !== undefined) creation.barcode2 = changes.barcode2;
    if (changes.barcode3 !== undefined) creation.barcode3 = changes.barcode3;
    if (changes.customName !== undefined) creation.customName = changes.customName;
    if (changes.nameTamil !== undefined) creation.nameTamil = changes.nameTamil;

    // Save updated creation back
    const db = await this.getDB();
    const transaction = db.transaction(PRODUCT_CREATIONS_STORE, 'readwrite');
    const store = transaction.objectStore(PRODUCT_CREATIONS_STORE);

    return new Promise((resolve, reject) => {
      const request = store.put(creation);
      request.onsuccess = () => {
        console.log('Applied edit changes to offline creation:', creation.offlineProductId);
        resolve(true);
      };
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Add offline-created product to local products cache
   * This allows the product to be used immediately for billing
   */
  async addOfflineProductToLocalCache(creation: OfflineProductCreation, tempId: number): Promise<void> {
    const db = await this.getDB();
    const transaction = db.transaction(PRODUCTS_STORE, 'readwrite');
    const store = transaction.objectStore(PRODUCTS_STORE);

    const cachedProduct: CachedProduct = {
      id: tempId,
      shopId: creation.shopId,
      name: creation.customName || creation.name,
      nameTamil: creation.nameTamil,
      price: creation.price,
      originalPrice: creation.originalPrice || creation.price,
      stock: creation.stockQuantity,
      trackInventory: creation.trackInventory,
      sku: '',
      barcode: creation.barcode1,
      barcode1: creation.barcode1,
      barcode2: creation.barcode2,
      barcode3: creation.barcode3,
      image: '',
      imageBase64: creation.imageBase64,
      categoryId: undefined,
      categoryName: ''
    };

    return new Promise((resolve, reject) => {
      const request = store.put(cachedProduct);
      request.onsuccess = () => {
        console.log('Offline product added to local cache:', tempId);
        resolve();
      };
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Update local product ID after sync (replace temp ID with real ID)
   */
  async updateLocalProductId(tempId: number, realId: number): Promise<void> {
    const db = await this.getDB();
    const transaction = db.transaction(PRODUCTS_STORE, 'readwrite');
    const store = transaction.objectStore(PRODUCTS_STORE);

    return new Promise((resolve, reject) => {
      const getRequest = store.get(tempId);
      getRequest.onsuccess = () => {
        const product = getRequest.result;
        if (product) {
          // Delete the old entry
          const deleteRequest = store.delete(tempId);
          deleteRequest.onsuccess = () => {
            // Add with new ID
            product.id = realId;
            const putRequest = store.put(product);
            putRequest.onsuccess = () => {
              console.log(`Updated product ID from ${tempId} to ${realId}`);
              resolve();
            };
            putRequest.onerror = () => reject(putRequest.error);
          };
          deleteRequest.onerror = () => reject(deleteRequest.error);
        } else {
          resolve();
        }
      };
      getRequest.onerror = () => reject(getRequest.error);
    });
  }

  /**
   * Check if barcode already exists in local cache
   */
  async isBarcodeExistsLocally(barcode: string, excludeProductId?: number): Promise<boolean> {
    if (!barcode || barcode.trim() === '') return false;

    const trimmedBarcode = barcode.trim().toLowerCase();
    const products = await this.getProducts();
    return products.some(p =>
      p.id !== excludeProductId && (
        (p.barcode && p.barcode.toLowerCase() === trimmedBarcode) ||
        (p.barcode1 && p.barcode1.toLowerCase() === trimmedBarcode) ||
        (p.barcode2 && p.barcode2.toLowerCase() === trimmedBarcode) ||
        (p.barcode3 && p.barcode3.toLowerCase() === trimmedBarcode)
      )
    );
  }
}
