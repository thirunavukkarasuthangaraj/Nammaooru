import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../../environments/environment';
import { ApiResponse } from '../models/api-response.model';
import { 
  ShopProduct, 
  ShopProductRequest, 
  ShopProductFilters,
  ShopProductStats,
  ProductPage,
  InventoryOperation
} from '../models/product.model';

@Injectable({
  providedIn: 'root'
})
export class ShopProductService {
  private readonly API_URL = `${environment.apiUrl}/shops`;

  constructor(private http: HttpClient) {}

  // Shop Products
  getShopProducts(shopId: number, filters: ShopProductFilters = {}): Observable<ProductPage<ShopProduct>> {
    let params = new HttpParams();
    
    Object.keys(filters).forEach(key => {
      const value = (filters as any)[key];
      if (value !== undefined && value !== null && value !== '') {
        params = params.set(key, value.toString());
      }
    });

    return this.http.get<ApiResponse<ProductPage<ShopProduct>>>(`${this.API_URL}/${shopId}/products`, { params })
      .pipe(map(response => response.data));
  }

  getShopProduct(shopId: number, productId: number): Observable<ShopProduct> {
    return this.http.get<ApiResponse<ShopProduct>>(`${this.API_URL}/${shopId}/products/${productId}`)
      .pipe(map(response => response.data));
  }

  addProductToShop(shopId: number, product: ShopProductRequest): Observable<ShopProduct> {
    return this.http.post<ApiResponse<ShopProduct>>(`${this.API_URL}/${shopId}/products`, product)
      .pipe(map(response => response.data));
  }

  updateShopProduct(shopId: number, productId: number, product: ShopProductRequest): Observable<ShopProduct> {
    return this.http.put<ApiResponse<ShopProduct>>(`${this.API_URL}/${shopId}/products/${productId}`, product)
      .pipe(map(response => response.data));
  }

  removeProductFromShop(shopId: number, productId: number): Observable<void> {
    return this.http.delete<ApiResponse<void>>(`${this.API_URL}/${shopId}/products/${productId}`)
      .pipe(map(() => void 0));
  }

  searchShopProducts(shopId: number, query: string, page: number = 0, size: number = 10): Observable<ProductPage<ShopProduct>> {
    const params = new HttpParams()
      .set('query', query)
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<ApiResponse<ProductPage<ShopProduct>>>(`${this.API_URL}/${shopId}/products/search`, { params })
      .pipe(map(response => response.data));
  }

  getFeaturedShopProducts(shopId: number): Observable<ShopProduct[]> {
    return this.http.get<ApiResponse<ShopProduct[]>>(`${this.API_URL}/${shopId}/products/featured`)
      .pipe(map(response => response.data));
  }

  getLowStockProducts(shopId: number): Observable<ShopProduct[]> {
    return this.http.get<ApiResponse<ShopProduct[]>>(`${this.API_URL}/${shopId}/products/low-stock`)
      .pipe(map(response => response.data));
  }

  updateInventory(shopId: number, productId: number, operation: InventoryOperation): Observable<ShopProduct> {
    const params = new HttpParams()
      .set('quantity', operation.quantity.toString())
      .set('operation', operation.operation);

    return this.http.patch<ApiResponse<ShopProduct>>(
      `${this.API_URL}/${shopId}/products/${productId}/inventory`, 
      null, 
      { params }
    ).pipe(map(response => response.data));
  }

  getShopProductStats(shopId: number): Observable<ShopProductStats> {
    return this.http.get<ApiResponse<ShopProductStats>>(`${this.API_URL}/${shopId}/products/stats`)
      .pipe(map(response => response.data));
  }
}