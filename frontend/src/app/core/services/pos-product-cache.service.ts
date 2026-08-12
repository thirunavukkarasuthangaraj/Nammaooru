import { Injectable } from '@angular/core';
import { CachedProduct } from './offline-storage.service';

/**
 * Keeps the POS catalog in memory across navigation so re-entering POS
 * Billing reuses the previous visit's list instantly instead of re-reading
 * thousands of products (with embedded images) from IndexedDB every time.
 * Keyed by shopId so a shop switch or different login never leaks products.
 */
@Injectable({ providedIn: 'root' })
export class PosProductCacheService {
  private products: CachedProduct[] | null = null;
  private shopId: number | null = null;

  set(shopId: number, products: CachedProduct[]): void {
    this.shopId = shopId;
    this.products = products;
  }

  getFor(shopId: number): CachedProduct[] | null {
    return this.products && this.shopId === shopId ? this.products : null;
  }

  clear(): void {
    this.products = null;
    this.shopId = null;
  }
}
