import { Injectable } from '@angular/core';

export interface CachedProduct {
  id: number;
  shopId?: number;  // Shop ID for the product
  name: string;
  nameTamil?: string;
  price: number;
  originalPrice?: number;  // MRP price for discount calculation
  stock: number;
  trackInventory: boolean;
  sku: string;
  barcode?: string;
  image?: string;
  imageBase64?: string;  // Cached image for offline use
  categoryId?: number;
  categoryName?: string;
  unit?: string;
  weight?: number;
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
  };
  previousValues: {
    price?: number;
    originalPrice?: number;
    stockQuantity?: number;
    barcode?: string;
  };
  createdAt: string;
  synced: boolean;
  syncError?: string;
}

const DB_NAME = 'NammaOoruPOS';
const DB_VERSION = 2;  // Incremented for offlineEdits store
const PRODUCTS_STORE = 'products';
const ORDERS_STORE = 'offlineOrders';
const EDITS_STORE = 'offlineEdits';
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
   * Initialize IndexedDB
   */
  private initializeDB(): Promise<IDBDatabase> {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION);

      request.onerror = () => {
        console.error('Failed to open IndexedDB:', request.error);
        reject(request.error);
      };

      request.onsuccess = () => {
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

        // Sync metadata store
        if (!db.objectStoreNames.contains(SYNC_META_STORE)) {
          db.createObjectStore(SYNC_META_STORE, { keyPath: 'key' });
        }
      };
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
      (p.barcode && p.barcode.toLowerCase().includes(lowerQuery))
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
}
