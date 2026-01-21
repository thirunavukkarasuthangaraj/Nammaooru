import { Injectable, OnDestroy } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, Subject, fromEvent, merge } from 'rxjs';
import { takeUntil, debounceTime } from 'rxjs/operators';
import { environment } from '../../../environments/environment';
import { OfflineStorageService, CachedProduct, OfflineOrder } from './offline-storage.service';

export interface SyncStatus {
  isOnline: boolean;
  pendingOrders: number;
  lastProductSync: Date | null;
  isSyncing: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class PosSyncService implements OnDestroy {
  private apiUrl = environment.apiUrl;
  private destroy$ = new Subject<void>();

  private syncStatus$ = new BehaviorSubject<SyncStatus>({
    isOnline: navigator.onLine,
    pendingOrders: 0,
    lastProductSync: null,
    isSyncing: false
  });

  constructor(
    private http: HttpClient,
    private offlineStorage: OfflineStorageService
  ) {
    this.initNetworkListener();
  }

  /**
   * Get sync status observable
   */
  getSyncStatus(): Observable<SyncStatus> {
    return this.syncStatus$.asObservable();
  }

  /**
   * Get current sync status
   */
  getCurrentStatus(): SyncStatus {
    return this.syncStatus$.getValue();
  }

  /**
   * Initialize network status listener
   */
  private initNetworkListener(): void {
    const online$ = fromEvent(window, 'online');
    const offline$ = fromEvent(window, 'offline');

    merge(online$, offline$)
      .pipe(
        takeUntil(this.destroy$),
        debounceTime(1000)
      )
      .subscribe(() => {
        const isOnline = navigator.onLine;
        this.updateStatus({ isOnline });

        if (isOnline) {
          console.log('Network online - triggering sync');
          this.syncPendingOrders();
        } else {
          console.log('Network offline');
        }
      });

    // Initial status update
    this.updatePendingCount();
  }

  /**
   * Update sync status
   */
  private updateStatus(partial: Partial<SyncStatus>): void {
    const current = this.syncStatus$.getValue();
    this.syncStatus$.next({ ...current, ...partial });
  }

  /**
   * Update pending orders count
   */
  async updatePendingCount(): Promise<void> {
    const count = await this.offlineStorage.getPendingOrdersCount();
    this.updateStatus({ pendingOrders: count });
  }

  // ==================== PRODUCT SYNC ====================

  /**
   * Refresh product cache from server
   */
  async refreshProductCache(shopId: number): Promise<void> {
    if (!navigator.onLine) {
      console.log('Offline - using cached products');
      return;
    }

    try {
      this.updateStatus({ isSyncing: true });
      console.log('Fetching products for cache, shopId:', shopId);

      // Use the existing my-products endpoint which works with auth token
      const response = await this.http.get<any>(
        `${this.apiUrl}/shop-products/my-products?page=0&size=100000`
      ).toPromise();

      console.log('Products API response:', response);

      // Handle paginated response: response.data.content or response.data (array)
      let products: CachedProduct[] = [];

      if (response?.data?.content) {
        // Paginated response
        products = response.data.content.map((p: any) => this.mapToCache(p));
      } else if (response?.data && Array.isArray(response.data)) {
        // Array response
        products = response.data.map((p: any) => this.mapToCache(p));
      }

      if (products.length > 0) {
        await this.offlineStorage.saveProducts(products, shopId);
        this.updateStatus({
          lastProductSync: new Date(),
          isSyncing: false
        });
        console.log(`Cached ${products.length} products`);
      } else {
        console.warn('No products in response:', response);
        this.updateStatus({ isSyncing: false });
      }
    } catch (error) {
      console.error('Failed to refresh product cache:', error);
      this.updateStatus({ isSyncing: false });
    }
  }

  /**
   * Map shop product response to cached product format
   */
  private mapToCache(product: any): CachedProduct {
    return {
      id: product.id,
      name: product.displayName || product.customName || product.masterProduct?.name || 'Unknown',
      nameTamil: product.nameTamil || product.displayNameTamil || product.masterProduct?.nameTamil,
      price: product.price,
      stock: product.stockQuantity || 0,
      trackInventory: product.trackInventory ?? true,
      sku: product.masterProduct?.sku || product.sku || '',
      barcode: product.masterProduct?.barcode || product.barcode || '',
      image: product.primaryImageUrl || product.masterProduct?.primaryImageUrl || '',
      categoryId: product.masterProduct?.category?.id || product.categoryId,
      categoryName: product.masterProduct?.category?.name || product.categoryName || ''
    };
  }

  /**
   * Check if products need refresh (stale after 1 hour)
   */
  async shouldRefreshProducts(shopId: number): Promise<boolean> {
    const lastSync = await this.offlineStorage.getProductsSyncTime(shopId);
    if (!lastSync) return true;

    const oneHour = 60 * 60 * 1000;
    return Date.now() - lastSync.getTime() > oneHour;
  }

  /**
   * Initialize product cache if needed
   */
  async initializeProductCache(shopId: number): Promise<CachedProduct[]> {
    // Check if we need to refresh
    const shouldRefresh = await this.shouldRefreshProducts(shopId);

    if (shouldRefresh && navigator.onLine) {
      await this.refreshProductCache(shopId);
    }

    // Return cached products
    return this.offlineStorage.getProducts();
  }

  // ==================== ORDER SYNC ====================

  /**
   * Create POS order (online or offline)
   */
  async createPosOrder(orderData: any, shopId: number, shopName?: string): Promise<{ success: boolean; order?: any; offline?: boolean }> {
    // Try to get shop name from localStorage if not provided
    const resolvedShopName = shopName || localStorage.getItem('shop_name') || 'Shop';
    if (navigator.onLine) {
      // Online - send directly to server
      try {
        const response = await this.http.post<{ data: any }>(
          `${this.apiUrl}/pos/orders`,
          { ...orderData, shopId }
        ).toPromise();

        return { success: true, order: response?.data, offline: false };
      } catch (error) {
        console.error('Failed to create online order, saving offline:', error);
        // Fall through to offline save
      }
    }

    // Offline - save locally
    const offlineOrder: OfflineOrder = {
      offlineOrderId: this.offlineStorage.generateOfflineOrderId(),
      shopId,
      items: orderData.items,
      paymentMethod: orderData.paymentMethod,
      customerName: orderData.customerName,
      customerPhone: orderData.customerPhone,
      notes: orderData.notes,
      totalAmount: orderData.totalAmount,
      subtotal: orderData.subtotal,
      taxAmount: orderData.taxAmount,
      createdAt: new Date().toISOString(),
      synced: false
    };

    await this.offlineStorage.saveOfflineOrder(offlineOrder);

    // Update local stock
    for (const item of orderData.items) {
      await this.offlineStorage.updateLocalStock(item.shopProductId, item.quantity);
    }

    await this.updatePendingCount();

    return {
      success: true,
      order: {
        orderNumber: offlineOrder.offlineOrderId,
        shopName: resolvedShopName,
        customerName: orderData.customerName || 'Walk-in Customer',
        customerPhone: orderData.customerPhone || '',
        ...offlineOrder
      },
      offline: true
    };
  }

  /**
   * Sync all pending orders to server
   */
  async syncPendingOrders(): Promise<{ synced: number; failed: number }> {
    if (!navigator.onLine) {
      console.log('Cannot sync - offline');
      return { synced: 0, failed: 0 };
    }

    const pendingOrders = await this.offlineStorage.getPendingOrders();
    if (pendingOrders.length === 0) {
      console.log('No pending orders to sync');
      return { synced: 0, failed: 0 };
    }

    this.updateStatus({ isSyncing: true });
    console.log(`Syncing ${pendingOrders.length} pending orders...`);

    let synced = 0;
    let failed = 0;

    for (const order of pendingOrders) {
      try {
        const requestData = {
          shopId: order.shopId,
          items: order.items.map(item => ({
            shopProductId: item.shopProductId,
            quantity: item.quantity,
            unitPrice: item.unitPrice
          })),
          paymentMethod: order.paymentMethod,
          customerName: order.customerName,
          customerPhone: order.customerPhone,
          notes: order.notes,
          offlineOrderId: order.offlineOrderId
        };

        await this.http.post(
          `${this.apiUrl}/pos/orders`,
          requestData
        ).toPromise();

        // Mark as synced
        await this.offlineStorage.markOrderSynced(order.offlineOrderId);
        synced++;
        console.log(`Synced order: ${order.offlineOrderId}`);
      } catch (error) {
        console.error(`Failed to sync order ${order.offlineOrderId}:`, error);
        failed++;
      }
    }

    await this.updatePendingCount();
    this.updateStatus({ isSyncing: false });

    console.log(`Sync complete: ${synced} synced, ${failed} failed`);
    return { synced, failed };
  }

  /**
   * Force sync now
   */
  async forceSyncNow(shopId: number): Promise<void> {
    if (!navigator.onLine) {
      throw new Error('Cannot sync while offline');
    }

    // Sync orders first
    await this.syncPendingOrders();

    // Then refresh products
    await this.refreshProductCache(shopId);
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
