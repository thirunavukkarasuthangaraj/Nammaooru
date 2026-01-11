import { Injectable } from '@angular/core';

export interface CachedProduct {
  id: number;
  shopId?: number;  // Shop ID for the product
  name: string;
  nameTamil?: string;
  price: number;
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

const DB_NAME = 'NammaOoruPOS';
const DB_VERSION = 1;
const PRODUCTS_STORE = 'products';
const ORDERS_STORE = 'offlineOrders';
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
    const db = await this.getDB();
    const transaction = db.transaction(ORDERS_STORE, 'readonly');
    const store = transaction.objectStore(ORDERS_STORE);
    const index = store.index('synced');

    return new Promise((resolve, reject) => {
      const request = index.getAll(IDBKeyRange.only(false));
      request.onsuccess = () => resolve(request.result || []);
      request.onerror = () => reject(request.error);
    });
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
   */
  generateOfflineOrderId(): string {
    return `OFFLINE-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
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
