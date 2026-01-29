import { Injectable, OnDestroy } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, Subject, fromEvent, merge } from 'rxjs';
import { takeUntil, debounceTime } from 'rxjs/operators';
import { environment } from '../../../environments/environment';
import { OfflineStorageService, CachedProduct, OfflineOrder, OfflineEdit, OfflineProductCreation } from './offline-storage.service';

export interface SyncStatus {
  isOnline: boolean;
  pendingOrders: number;
  pendingEdits: number;
  pendingProductCreations: number;
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
    pendingEdits: 0,
    pendingProductCreations: 0,
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
          // Edits must sync before creations so offline edits merge into creation records first
          this.syncPendingEdits().then(() => this.syncPendingProductCreations());
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
   * Update pending orders and edits count
   */
  async updatePendingCount(): Promise<void> {
    const ordersCount = await this.offlineStorage.getPendingOrdersCount();
    const editsCount = await this.offlineStorage.getPendingEditsCount();
    const productCreationsCount = await this.offlineStorage.getPendingProductCreationsCount();
    this.updateStatus({
      pendingOrders: ordersCount,
      pendingEdits: editsCount,
      pendingProductCreations: productCreationsCount
    });
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
      shopId: product.shopId,
      name: product.displayName || product.customName || product.masterProduct?.name || 'Unknown',
      nameTamil: product.nameTamil || product.displayNameTamil || product.masterProduct?.nameTamil,
      description: product.displayDescription || product.customDescription || product.masterProduct?.description || '',
      price: product.price,
      originalPrice: product.originalPrice || product.price,
      costPrice: product.costPrice,
      stock: product.stockQuantity || 0,
      minStockLevel: product.minStockLevel || 10,
      maxStockLevel: product.maxStockLevel || 100,
      trackInventory: product.trackInventory ?? true,
      isAvailable: product.isAvailable ?? true,
      sku: product.sku || product.masterProduct?.sku || '',
      barcode: product.barcode || product.masterProduct?.barcode || '',
      barcode1: product.barcode1 || '',
      barcode2: product.barcode2 || '',
      barcode3: product.barcode3 || '',
      image: product.primaryImageUrl || product.masterProduct?.primaryImageUrl || '',
      imageUrl: product.primaryImageUrl || product.masterProduct?.primaryImageUrl || '',
      categoryId: product.masterProduct?.category?.id || product.categoryId,
      categoryName: product.masterProduct?.category?.name || product.categoryName || '',
      category: product.masterProduct?.category?.name || product.categoryName || '',
      unit: product.baseUnit || product.masterProduct?.baseUnit || 'piece',
      weight: product.baseWeight || product.masterProduct?.baseWeight,
      masterProductId: product.masterProduct?.id,
      tags: product.tags || product.masterProduct?.tags || []
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

  // ==================== OFFLINE EDITS SYNC ====================

  /**
   * Sync all pending product edits to server
   */
  async syncPendingEdits(): Promise<{ synced: number; failed: number }> {
    if (!navigator.onLine) {
      console.log('Cannot sync edits - offline');
      return { synced: 0, failed: 0 };
    }

    const pendingEdits = await this.offlineStorage.getPendingEdits();
    if (pendingEdits.length === 0) {
      console.log('No pending edits to sync');
      return { synced: 0, failed: 0 };
    }

    this.updateStatus({ isSyncing: true });
    console.log(`Syncing ${pendingEdits.length} pending product edits...`);

    let synced = 0;
    let failed = 0;

    for (const edit of pendingEdits) {
      try {
        // Skip edits for offline-created products (negative temp IDs)
        // These products don't exist on the server yet — merge edit into the creation record
        // so the creation sync sends the latest values
        if (edit.productId < 0) {
          console.log(`Merging edit ${edit.editId} into offline creation for temp product ${edit.productId}`);
          await this.offlineStorage.applyEditToProductCreation(edit.productId, edit.changes);
          await this.offlineStorage.markEditSynced(edit.editId);
          await this.offlineStorage.removeOfflineEdit(edit.editId);
          synced++;
          continue;
        }

        // Sync availability change via dedicated endpoint
        if (edit.changes.isAvailable !== undefined) {
          await this.http.patch(
            `${this.apiUrl}/shop-products/${edit.productId}/availability`,
            { isAvailable: edit.changes.isAvailable }
          ).toPromise();
        }

        // Sync other field changes via quick-update
        const updateData: any = {};
        if (edit.changes.price !== undefined) updateData.price = edit.changes.price;
        if (edit.changes.originalPrice !== undefined) updateData.originalPrice = edit.changes.originalPrice;
        if (edit.changes.stockQuantity !== undefined) updateData.stockQuantity = edit.changes.stockQuantity;
        if (edit.changes.sku !== undefined) updateData.sku = edit.changes.sku;
        if (edit.changes.barcode !== undefined) updateData.barcode = edit.changes.barcode;
        if (edit.changes.barcode1 !== undefined) updateData.barcode1 = edit.changes.barcode1;
        if (edit.changes.barcode2 !== undefined) updateData.barcode2 = edit.changes.barcode2;
        if (edit.changes.barcode3 !== undefined) updateData.barcode3 = edit.changes.barcode3;

        if (Object.keys(updateData).length > 0) {
          await this.http.patch(
            `${this.apiUrl}/shop-products/${edit.productId}/quick-update`,
            updateData
          ).toPromise();
        }

        // Mark as synced and remove
        await this.offlineStorage.markEditSynced(edit.editId);
        await this.offlineStorage.removeOfflineEdit(edit.editId);
        synced++;
        console.log(`Synced edit: ${edit.editId} for product ${edit.productId}`);
      } catch (error) {
        console.error(`Failed to sync edit ${edit.editId}:`, error);
        failed++;
      }
    }

    await this.updatePendingCount();
    this.updateStatus({ isSyncing: false });

    console.log(`Edit sync complete: ${synced} synced, ${failed} failed`);
    return { synced, failed };
  }

  // ==================== OFFLINE PRODUCT CREATIONS SYNC ====================

  /**
   * Sync all pending product creations to server
   */
  async syncPendingProductCreations(): Promise<{ synced: number; failed: number }> {
    if (!navigator.onLine) {
      console.log('Cannot sync product creations - offline');
      return { synced: 0, failed: 0 };
    }

    const allPendingCreations = await this.offlineStorage.getPendingProductCreations();
    // Only sync creations belonging to the current shop to prevent cross-shop syncing
    const currentShopId = parseInt(localStorage.getItem('current_shop_id') || '0', 10);
    const pendingCreations = currentShopId
      ? allPendingCreations.filter(c => c.shopId === currentShopId)
      : allPendingCreations;
    if (pendingCreations.length === 0) {
      console.log('No pending product creations to sync for current shop');
      return { synced: 0, failed: 0 };
    }

    this.updateStatus({ isSyncing: true });
    console.log(`Syncing ${pendingCreations.length} pending product creations...`);

    let synced = 0;
    let failed = 0;

    for (const creation of pendingCreations) {
      try {
        console.log('Syncing creation record:', JSON.stringify({
          offlineProductId: creation.offlineProductId,
          name: creation.name,
          barcode1: creation.barcode1,
          barcode2: creation.barcode2,
          barcode3: creation.barcode3,
          price: creation.price
        }));

        // Build the request data for creating shop product
        const requestData = {
          masterProductId: creation.masterProductId,
          price: creation.price,
          originalPrice: creation.originalPrice,
          costPrice: creation.costPrice,
          stockQuantity: creation.stockQuantity,
          minStockLevel: creation.minStockLevel || 10,
          trackInventory: creation.trackInventory,
          customName: creation.customName || creation.name,
          customDescription: creation.customDescription,
          isFeatured: creation.isFeatured || false,
          tags: creation.tags,
          sku: creation.sku || '',
          barcode1: creation.barcode1,
          barcode2: creation.barcode2,
          barcode3: creation.barcode3,
          nameTamil: creation.nameTamil,
          categoryId: creation.categoryId,
          categoryName: creation.categoryName,
          isAvailable: true,
          status: 'ACTIVE'
        };

        // Create the product via API - use /create endpoint
        const response = await this.http.post<{ data: any }>(
          `${this.apiUrl}/shop-products/create`,
          requestData
        ).toPromise();

        const createdProduct = response?.data;
        const realProductId = createdProduct?.id;

        if (realProductId) {
          // Mark as synced
          await this.offlineStorage.markProductCreationSynced(creation.offlineProductId, realProductId);

          // Update local cache with real product ID
          if (creation.tempProductId) {
            await this.offlineStorage.updateLocalProductId(creation.tempProductId, realProductId);
          }

          // Remove the offline creation record
          await this.offlineStorage.removeOfflineProductCreation(creation.offlineProductId);

          synced++;
          console.log(`Synced product creation: ${creation.offlineProductId} -> ID ${realProductId}`);
        } else {
          throw new Error('No product ID returned from API');
        }
      } catch (error: any) {
        console.error(`Failed to sync product creation ${creation.offlineProductId}:`, error);
        await this.offlineStorage.updateProductCreationError(
          creation.offlineProductId,
          error.message || 'Sync failed'
        );
        failed++;
      }
    }

    await this.updatePendingCount();
    this.updateStatus({ isSyncing: false });

    console.log(`Product creation sync complete: ${synced} synced, ${failed} failed`);
    return { synced, failed };
  }

  /**
   * Create product offline (saves locally and adds to cache for immediate use)
   */
  async createProductOffline(productData: Omit<OfflineProductCreation, 'offlineProductId' | 'createdAt' | 'synced'>): Promise<{
    success: boolean;
    tempProductId: number;
    offlineProductId: string;
    message: string;
  }> {
    try {
      // Generate IDs
      const offlineProductId = this.offlineStorage.generateOfflineProductId();
      const tempProductId = this.offlineStorage.generateTempProductId();

      // Check for duplicate barcode in cached products AND pending offline creations
      const barcodeExists = await this.offlineStorage.isBarcodeExists(productData.barcode1);
      if (barcodeExists) {
        return {
          success: false,
          tempProductId: 0,
          offlineProductId: '',
          message: `Barcode "${productData.barcode1}" already exists. Please use a unique barcode.`
        };
      }

      // Create the offline product creation record
      const creation: OfflineProductCreation = {
        offlineProductId,
        ...productData,
        tempProductId,
        createdAt: new Date().toISOString(),
        synced: false
      };

      // Save to offline creations store
      await this.offlineStorage.saveOfflineProductCreation(creation);

      // Add to local products cache for immediate use
      await this.offlineStorage.addOfflineProductToLocalCache(creation, tempProductId);

      // Update pending count
      await this.updatePendingCount();

      console.log(`Product created offline: ${offlineProductId}, temp ID: ${tempProductId}`);

      return {
        success: true,
        tempProductId,
        offlineProductId,
        message: 'Product saved offline. Will sync when online.'
      };
    } catch (error: any) {
      console.error('Failed to create product offline:', error);
      return {
        success: false,
        tempProductId: 0,
        offlineProductId: '',
        message: error.message || 'Failed to save product offline'
      };
    }
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

    // Sync product edits
    await this.syncPendingEdits();

    // Sync product creations
    await this.syncPendingProductCreations();

    // Then refresh products
    await this.refreshProductCache(shopId);
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
