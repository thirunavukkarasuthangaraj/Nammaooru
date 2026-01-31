import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { OfflineStorageService, CachedProduct, CachedOrder, CachedDashboardStats, CachedCombo } from './offline-storage.service';
import { AuthService } from './auth.service';
import { getImageUrl } from '../utils/image-url.util';

export interface PreloadStatus {
  isLoading: boolean;
  progress: number; // 0-100
  message: string;
  productsLoaded: number;
  totalProducts: number;
  ordersLoaded?: number;
  dashboardLoaded?: boolean;
  combosLoaded?: number;
  imagesLoaded?: number;
  totalImages?: number;
  error?: string;
}

@Injectable({
  providedIn: 'root'
})
export class DataPreloadService {
  private apiUrl = environment.apiUrl;
  private readonly PRODUCTS_CACHE_KEY = 'products_preload_timestamp';

  private statusSubject = new BehaviorSubject<PreloadStatus>({
    isLoading: false,
    progress: 0,
    message: '',
    productsLoaded: 0,
    totalProducts: 0
  });

  status$ = this.statusSubject.asObservable();

  constructor(
    private http: HttpClient,
    private offlineStorage: OfflineStorageService,
    private authService: AuthService
  ) {}

  /**
   * Preload all data after login
   * Called automatically after successful login
   */
  async preloadAllData(): Promise<void> {
    const user = this.authService.getCurrentUser();
    if (!user) {
      console.log('No user logged in, skipping preload');
      return;
    }

    // Only preload for shop owners
    if (user.role !== 'SHOP_OWNER') {
      console.log('User is not shop owner, skipping product preload');
      return;
    }

    // Check if cache exists - only preload if no cache
    try {
      const cachedProducts = await this.offlineStorage.getProducts();
      if (cachedProducts && cachedProducts.length > 0) {
        console.log(`Cache exists with ${cachedProducts.length} products, skipping preload`);
        return;
      }
    } catch (error) {
      console.warn('Error checking cache:', error);
    }

    console.log('No cache found, starting preload...');

    this.updateStatus({
      isLoading: true,
      progress: 0,
      message: 'Loading products...',
      productsLoaded: 0,
      totalProducts: 0
    });

    try {
      await this.preloadProducts();
      // Note: Images are cached by Service Worker on-demand (faster than preloading 3000+ images)
      await this.preloadOrders();
      await this.preloadDashboard();
      await this.preloadCombos();

      // Mark preload complete
      localStorage.setItem(this.PRODUCTS_CACHE_KEY, Date.now().toString());

      this.updateStatus({
        isLoading: false,
        progress: 100,
        message: 'Preload complete',
        productsLoaded: this.statusSubject.value.productsLoaded,
        totalProducts: this.statusSubject.value.totalProducts,
        ordersLoaded: this.statusSubject.value.ordersLoaded,
        dashboardLoaded: true,
        combosLoaded: this.statusSubject.value.combosLoaded
      });
    } catch (error: any) {
      console.error('Preload failed:', error);
      this.updateStatus({
        isLoading: false,
        progress: 0,
        message: 'Preload failed',
        productsLoaded: 0,
        totalProducts: 0,
        error: error.message
      });
    }
  }

  /**
   * Force preload - fetches fresh data from server and updates cache
   * Use when user wants to refresh all data manually
   */
  async forcePreload(): Promise<void> {
    this.updateStatus({
      isLoading: true,
      progress: 0,
      message: 'Refreshing data...',
      productsLoaded: 0,
      totalProducts: 0
    });

    try {
      await this.preloadProducts();
      // Note: Images are cached by Service Worker on-demand
      await this.preloadOrders();
      await this.preloadDashboard();
      await this.preloadCombos();
      localStorage.setItem(this.PRODUCTS_CACHE_KEY, Date.now().toString());

      this.updateStatus({
        isLoading: false,
        progress: 100,
        message: 'Refresh complete',
        productsLoaded: this.statusSubject.value.productsLoaded,
        totalProducts: this.statusSubject.value.totalProducts,
        ordersLoaded: this.statusSubject.value.ordersLoaded,
        dashboardLoaded: true,
        combosLoaded: this.statusSubject.value.combosLoaded
      });
    } catch (error: any) {
      console.error('Force preload failed:', error);
      this.updateStatus({
        isLoading: false,
        progress: 0,
        message: 'Refresh failed',
        productsLoaded: 0,
        totalProducts: 0,
        error: error.message
      });
    }
  }

  /**
   * Preload all products from API and cache to IndexedDB
   */
  private async preloadProducts(): Promise<void> {
    const pageSize = 500;
    let allProducts: any[] = [];
    let currentPage = 0;
    let totalPages = 1;
    let totalElements = 0;

    console.log('Starting product preload...');

    // Fetch all pages
    while (currentPage < totalPages) {
      const response: any = await this.http.get<any>(
        `${this.apiUrl}/shop-products/my-products?page=${currentPage}&size=${pageSize}`
      ).toPromise();

      let products = [];
      if (response?.data?.content) {
        products = response.data.content;
        totalPages = response.data.totalPages || 1;
        totalElements = response.data.totalElements || products.length;
      } else if (Array.isArray(response?.data)) {
        products = response.data;
        totalElements = products.length;
        totalPages = 1;
      } else if (Array.isArray(response)) {
        products = response;
        totalElements = products.length;
        totalPages = 1;
      }

      allProducts = allProducts.concat(products);
      currentPage++;

      // Update progress
      const progress = Math.round((currentPage / totalPages) * 100);
      this.updateStatus({
        isLoading: true,
        progress,
        message: `Loading products... (${allProducts.length}/${totalElements})`,
        productsLoaded: allProducts.length,
        totalProducts: totalElements
      });

      // Safety: prevent infinite loop
      if (currentPage > 100) break;
    }

    console.log(`Loaded ${allProducts.length} products from ${currentPage} pages`);

    // Map to CachedProduct format
    const cachedProducts: CachedProduct[] = allProducts.map((p: any) => ({
      id: p.id,
      shopId: p.shopId,
      name: p.displayName || p.customName || p.masterProduct?.name || '',
      nameTamil: p.masterProduct?.nameTamil || '',
      description: p.displayDescription || p.customDescription || p.masterProduct?.description || '',
      price: p.price,
      originalPrice: p.originalPrice,
      costPrice: p.costPrice,
      stock: p.stockQuantity || 0,
      minStockLevel: p.minStockLevel,
      maxStockLevel: p.maxStockLevel,
      trackInventory: p.trackInventory !== false,
      isAvailable: p.isAvailable !== false,
      sku: p.sku || p.masterProduct?.sku || '',
      barcode: p.barcode1 || p.masterProduct?.barcode || '',
      barcode1: p.barcode1 || '',
      barcode2: p.barcode2 || '',
      barcode3: p.barcode3 || '',
      image: p.masterProduct?.image || '',
      imageUrl: p.primaryImageUrl || p.masterProduct?.imageUrl || '',
      categoryId: p.masterProduct?.category?.id,
      categoryName: p.masterProduct?.category?.name || '',
      category: p.masterProduct?.category?.name || '',
      netQty: p.netQty || p.masterProduct?.netQty || '',
      packedDate: p.packedDate || '',
      expiryDate: p.expiryDate || '',
      unit: p.unit || p.masterProduct?.unit || 'piece',
      weight: p.weight || p.masterProduct?.weight,
      masterProductId: p.masterProduct?.id,
      tags: p.masterProduct?.tags ? p.masterProduct.tags.split(',').map((t: string) => t.trim()) : []
    }));

    // Get shop ID from first product or user
    const user = this.authService.getCurrentUser();
    const shopId = cachedProducts[0]?.shopId || user?.shopId || 0;

    // Save to IndexedDB
    await this.offlineStorage.saveProducts(cachedProducts, shopId);
    console.log(`Cached ${cachedProducts.length} products to IndexedDB`);
  }

  /**
   * Preload product images from cached products and store in IndexedDB
   * This enables offline viewing of product images
   */
  private async preloadImages(): Promise<void> {
    console.log('Starting images preload...');

    this.updateStatus({
      message: 'Caching images for offline use...'
    });

    try {
      // Get all cached products
      const products = await this.offlineStorage.getProducts();
      if (!products || products.length === 0) {
        console.log('No products found, skipping image preload');
        return;
      }

      // Extract unique image URLs from products
      const imageUrls: string[] = [];
      for (const product of products) {
        if (product.imageUrl) {
          const fullUrl = getImageUrl(product.imageUrl);
          if (fullUrl && !imageUrls.includes(fullUrl)) {
            imageUrls.push(fullUrl);
          }
        }
      }

      console.log(`Found ${imageUrls.length} unique product images to cache`);

      if (imageUrls.length === 0) {
        this.updateStatus({
          imagesLoaded: 0,
          totalImages: 0
        });
        return;
      }

      this.updateStatus({
        totalImages: imageUrls.length,
        imagesLoaded: 0
      });

      // Cache images with progress callback
      const cached = await this.offlineStorage.cacheImages(imageUrls, (loaded, total) => {
        this.updateStatus({
          message: `Caching images (${loaded}/${total})...`,
          imagesLoaded: loaded
        });
      });

      console.log(`Cached ${cached} images to IndexedDB`);
      this.updateStatus({
        imagesLoaded: cached
      });
    } catch (error) {
      console.warn('Error preloading images:', error);
      // Don't fail the entire preload if images fail
    }
  }

  /**
   * Preload orders from API and cache to IndexedDB
   * Fetches the last 100 orders for offline viewing
   */
  private async preloadOrders(): Promise<void> {
    console.log('Starting orders preload...');

    this.updateStatus({
      message: 'Loading orders...'
    });

    try {
      // Get shop ID
      const shopId = localStorage.getItem('current_shop_id');
      if (!shopId) {
        console.log('No shop ID found, skipping orders preload');
        return;
      }

      const response: any = await this.http.get<any>(
        `${this.apiUrl}/orders/shop/${shopId}?page=0&size=100`
      ).toPromise();

      let orders: CachedOrder[] = [];
      if (response?.data?.content) {
        orders = response.data.content;
      } else if (Array.isArray(response?.data)) {
        orders = response.data;
      } else if (Array.isArray(response)) {
        orders = response;
      }

      // Save to IndexedDB
      await this.offlineStorage.saveOrdersCache(orders, parseInt(shopId, 10));
      console.log(`Cached ${orders.length} orders to IndexedDB`);

      this.updateStatus({
        ordersLoaded: orders.length
      });
    } catch (error) {
      console.warn('Error preloading orders:', error);
      // Don't fail the entire preload if orders fail
    }
  }

  /**
   * Preload dashboard stats from API and cache to IndexedDB
   */
  private async preloadDashboard(): Promise<void> {
    console.log('Starting dashboard preload...');

    this.updateStatus({
      message: 'Loading dashboard...'
    });

    try {
      // Get shop ID
      const shopId = localStorage.getItem('current_shop_id');
      const shopStringId = localStorage.getItem('current_shop_string_id');

      if (!shopId && !shopStringId) {
        console.log('No shop ID found, skipping dashboard preload');
        return;
      }

      // Get dashboard stats
      const response: any = await this.http.get<any>(
        `${this.apiUrl}/shops/${shopStringId || shopId}/dashboard`,
        { withCredentials: true }
      ).toPromise();

      if (response?.statusCode === '0000' && response?.data) {
        const orderMetrics = response.data.orderMetrics || {};
        const productMetrics = response.data.productMetrics || {};

        const dashboardCache: CachedDashboardStats = {
          key: `dashboard_stats_${shopId}`,
          shopId: parseInt(shopId!, 10),
          stats: {
            todayOrders: orderMetrics.todayOrders || 0,
            totalOrders: orderMetrics.totalOrders || 0,
            pendingOrders: orderMetrics.pendingOrders || 0,
            todayRevenue: orderMetrics.todayRevenue || 0,
            monthlyRevenue: orderMetrics.monthlyRevenue || 0,
            totalProducts: productMetrics.totalProducts || 0,
            lowStockProducts: productMetrics.lowStockProducts || 0,
            outOfStockProducts: productMetrics.outOfStockProducts || 0,
          },
          cachedAt: new Date().toISOString()
        };

        // Save to IndexedDB
        await this.offlineStorage.saveDashboardCache(dashboardCache);
        console.log('Cached dashboard stats to IndexedDB');

        // Also save to localStorage for quick access
        localStorage.setItem('dashboard_stats', JSON.stringify(dashboardCache.stats));

        this.updateStatus({
          dashboardLoaded: true
        });
      }
    } catch (error) {
      console.warn('Error preloading dashboard:', error);
      // Don't fail the entire preload if dashboard fails
    }
  }

  /**
   * Preload combos from API and cache to IndexedDB
   */
  private async preloadCombos(): Promise<void> {
    console.log('Starting combos preload...');

    this.updateStatus({
      message: 'Loading combos...'
    });

    try {
      // Get shop ID
      const shopId = localStorage.getItem('current_shop_id');
      if (!shopId) {
        console.log('No shop ID found, skipping combos preload');
        return;
      }

      const response: any = await this.http.get<any>(
        `${this.apiUrl}/shops/${shopId}/combos`
      ).toPromise();

      let combos: CachedCombo[] = [];
      if (response?.data?.content) {
        combos = response.data.content;
      } else if (Array.isArray(response?.data)) {
        combos = response.data;
      } else if (Array.isArray(response)) {
        combos = response;
      }

      // Save to IndexedDB
      await this.offlineStorage.saveCombosCache(combos, parseInt(shopId, 10));
      console.log(`Cached ${combos.length} combos to IndexedDB`);

      this.updateStatus({
        combosLoaded: combos.length
      });
    } catch (error) {
      console.warn('Error preloading combos:', error);
      // Don't fail the entire preload if combos fail
    }
  }

  private updateStatus(status: Partial<PreloadStatus>): void {
    this.statusSubject.next({
      ...this.statusSubject.value,
      ...status
    });
  }

  /**
   * Get current preload status
   */
  getStatus(): PreloadStatus {
    return this.statusSubject.value;
  }

  /**
   * Check if preload is in progress
   */
  isPreloading(): boolean {
    return this.statusSubject.value.isLoading;
  }
}
