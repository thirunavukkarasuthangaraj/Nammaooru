import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { catchError, map, tap } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';

export interface Shop {
  id: number;
  shopId: string; // The string identifier used for API calls
  name: string;
  businessName: string;
  description?: string;
  ownerName: string;
  ownerEmail: string;
  ownerPhone: string;
  addressLine1: string;
  addressLine2?: string;
  city: string;
  state: string;
  postalCode: string;
  country: string;
  businessType: string;
  gstNumber?: string;
  status: string;
  isActive: boolean;
  slug?: string;
  logoUrl?: string;
  bannerUrl?: string;
  averageRating?: number;
  totalReviews?: number;
  deliveryTime?: string;
  minimumOrder?: number;
  deliveryFee?: number;
  createdBy: string;
  productCount?: number;
}

@Injectable({
  providedIn: 'root'
})
export class ShopContextService {
  private shopSubject = new BehaviorSubject<Shop | null>(null);
  private loadingSubject = new BehaviorSubject<boolean>(false);
  private errorSubject = new BehaviorSubject<string | null>(null);
  
  public shop$ = this.shopSubject.asObservable();
  public loading$ = this.loadingSubject.asObservable();
  public error$ = this.errorSubject.asObservable();
  
  private apiUrl = `${environment.apiUrl}`;

  constructor(private http: HttpClient) {
    this.loadShopForCurrentUser();
  }

  /**
   * Load shop data for the currently logged-in shop owner
   */
  loadShopForCurrentUser(): void {
    this.loadingSubject.next(true);
    this.errorSubject.next(null);

    // First, try to get the shop for the logged-in user
    // API returns ApiResponse<ShopResponse>, so we need to extract data
    this.http.get<any>(`${this.apiUrl}/shops/my-shop`).pipe(
      tap(response => {
        // Extract shop from ApiResponse wrapper (response.data) or use directly if not wrapped
        const shop = response?.data || response;
        console.log('Shop loaded for current user:', shop);
        this.shopSubject.next(shop);
        this.loadingSubject.next(false);
        // Cache shop ID and name for quick access
        if (shop && shop.id) {
          localStorage.setItem('current_shop_id', shop.id.toString());
          const shopName = shop.name || shop.businessName;
          console.log('Saving shop name to localStorage:', shopName);
          if (shopName && shopName.trim()) {
            localStorage.setItem('shop_name', shopName.trim());
          }
        }
      }),
      catchError(error => {
        console.error('Error loading shop:', error);
        
        // If my-shop endpoint fails, try to get shop by owner username
        const userData = localStorage.getItem('shop_management_user');
        if (userData) {
          const user = JSON.parse(userData);
          return this.getShopByOwner(user.username);
        }
        
        this.errorSubject.next('Failed to load shop data');
        this.loadingSubject.next(false);
        return of(null);
      })
    ).subscribe();
  }

  /**
   * Get shop by owner username (fallback method)
   */
  private getShopByOwner(username: string): Observable<Shop | null> {
    return this.http.get<any>(`${this.apiUrl}/shops`).pipe(
      map(response => {
        const shops = response.content || response || [];
        const userShop = shops.find((shop: any) => 
          shop.createdBy === username || shop.ownerEmail === username
        );
        
        if (userShop) {
          console.log('Shop found by owner username:', userShop);
          this.shopSubject.next(userShop);
          localStorage.setItem('current_shop_id', userShop.id.toString());
          const shopName = userShop.name || userShop.businessName;
          if (shopName && shopName.trim()) {
            localStorage.setItem('shop_name', shopName.trim());
          }
        } else {
          this.errorSubject.next('No shop found for this user');
        }
        
        this.loadingSubject.next(false);
        return userShop || null;
      }),
      catchError(error => {
        console.error('Error finding shop by owner:', error);
        this.errorSubject.next('Failed to find shop');
        this.loadingSubject.next(false);
        return of(null);
      })
    );
  }

  /**
   * Get shop by ID
   */
  getShopById(shopId: number): Observable<Shop | null> {
    return this.http.get<any>(`${this.apiUrl}/shops/${shopId}`).pipe(
      map(response => {
        // Extract shop from ApiResponse wrapper (response.data) or use directly if not wrapped
        const shop = response?.data || response;
        console.log('Shop loaded by ID:', shop);
        this.shopSubject.next(shop);
        localStorage.setItem('current_shop_id', shop.id.toString());
        const shopName = shop.name || shop.businessName;
        console.log('Saving shop name to localStorage:', shopName);
        if (shopName && shopName.trim()) {
          localStorage.setItem('shop_name', shopName.trim());
        }
        return shop;
      }),
      catchError(error => {
        console.error('Error loading shop by ID:', error);
        this.errorSubject.next('Failed to load shop');
        return of(null);
      })
    );
  }

  /**
   * Get current shop
   */
  getCurrentShop(): Shop | null {
    return this.shopSubject.value;
  }

  /**
   * Get current shop ID (internal database ID)
   */
  getCurrentShopId(): number | null {
    const shop = this.shopSubject.value;
    if (shop) return shop.id;

    // Try from localStorage as fallback
    const cachedId = localStorage.getItem('current_shop_id');
    return cachedId ? parseInt(cachedId, 10) : null;
  }

  /**
   * Get current shop identifier (string used for API calls)
   */
  getCurrentShopIdentifier(): string | null {
    const shop = this.shopSubject.value;
    return shop ? shop.shopId : null;
  }

  /**
   * Update shop details
   */
  updateShop(shopData: Partial<Shop>): Observable<Shop> {
    const shopId = this.getCurrentShopId();
    if (!shopId) {
      throw new Error('No shop ID available');
    }
    
    return this.http.put<Shop>(`${this.apiUrl}/shops/${shopId}`, shopData).pipe(
      tap(updatedShop => {
        console.log('Shop updated:', updatedShop);
        this.shopSubject.next(updatedShop);
      }),
      catchError(error => {
        console.error('Error updating shop:', error);
        this.errorSubject.next('Failed to update shop');
        throw error;
      })
    );
  }

  /**
   * Refresh shop data
   */
  refreshShop(): void {
    const shopId = this.getCurrentShopId();
    if (shopId) {
      this.getShopById(shopId).subscribe();
    } else {
      this.loadShopForCurrentUser();
    }
  }

  /**
   * Clear shop data (for logout)
   */
  clearShop(): void {
    this.shopSubject.next(null);
    localStorage.removeItem('current_shop_id');
    localStorage.removeItem('shop_name');
    this.errorSubject.next(null);
  }

  /**
   * Get shop statistics
   */
  getShopStats(): Observable<any> {
    const shopId = this.getCurrentShopId();
    if (!shopId) {
      return of({
        todayRevenue: 0,
        totalOrders: 0,
        pendingOrders: 0,
        activeProducts: 0,
        lowStockCount: 0
      });
    }
    
    return this.http.get(`${this.apiUrl}/shops/${shopId}/stats`).pipe(
      catchError(error => {
        console.error('Error loading shop stats:', error);
        // Return default stats on error
        return of({
          todayRevenue: 0,
          totalOrders: 0,
          pendingOrders: 0,
          activeProducts: 0,
          lowStockCount: 0
        });
      })
    );
  }

  /**
   * Get shop dashboard data
   */
  getDashboardData(): Observable<any> {
    const shopId = this.getCurrentShopId();
    if (!shopId) {
      return of(null);
    }
    
    return this.http.get(`${this.apiUrl}/shops/${shopId}/dashboard`).pipe(
      catchError(error => {
        console.error('Error loading dashboard data:', error);
        return of(null);
      })
    );
  }
}