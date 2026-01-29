import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { OfflineStorageService, CachedProduct } from './offline-storage.service';
import { AuthService } from './auth.service';

export interface PreloadStatus {
  isLoading: boolean;
  progress: number; // 0-100
  message: string;
  productsLoaded: number;
  totalProducts: number;
  error?: string;
}

@Injectable({
  providedIn: 'root'
})
export class DataPreloadService {
  private apiUrl = environment.apiUrl;
  private readonly PRODUCTS_CACHE_KEY = 'products_preload_timestamp';
  private readonly CACHE_VALIDITY_MS = 30 * 60 * 1000; // 30 minutes

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

    // Check if cache is still valid
    const lastPreload = localStorage.getItem(this.PRODUCTS_CACHE_KEY);
    const lastPreloadTime = lastPreload ? parseInt(lastPreload, 10) : 0;
    const cacheAge = Date.now() - lastPreloadTime;

    if (cacheAge < this.CACHE_VALIDITY_MS) {
      console.log('Cache is still valid, skipping preload');
      return;
    }

    this.updateStatus({
      isLoading: true,
      progress: 0,
      message: 'Loading products...',
      productsLoaded: 0,
      totalProducts: 0
    });

    try {
      await this.preloadProducts();

      // Mark preload complete
      localStorage.setItem(this.PRODUCTS_CACHE_KEY, Date.now().toString());

      this.updateStatus({
        isLoading: false,
        progress: 100,
        message: 'Preload complete',
        productsLoaded: this.statusSubject.value.productsLoaded,
        totalProducts: this.statusSubject.value.totalProducts
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
   * Force preload (ignore cache validity)
   */
  async forcePreload(): Promise<void> {
    localStorage.removeItem(this.PRODUCTS_CACHE_KEY);
    await this.preloadAllData();
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
