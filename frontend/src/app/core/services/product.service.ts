import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../../environments/environment';
import { ApiResponse } from '../models/api-response.model';
import { 
  MasterProduct, 
  MasterProductRequest, 
  ProductFilters,
  ProductPage 
} from '../models/product.model';

@Injectable({
  providedIn: 'root'
})
export class ProductService {
  private readonly API_URL = `${environment.apiUrl}/products/master`;

  constructor(private http: HttpClient) {}

  // Master Products
  getMasterProducts(filters: ProductFilters = {}): Observable<ProductPage<MasterProduct>> {
    let params = new HttpParams();
    
    Object.keys(filters).forEach(key => {
      const value = (filters as any)[key];
      if (value !== undefined && value !== null && value !== '') {
        params = params.set(key, value.toString());
      }
    });

    return this.http.get<ApiResponse<ProductPage<MasterProduct>>>(this.API_URL, { params })
      .pipe(map(response => response.data));
  }

  getMasterProduct(id: number): Observable<MasterProduct> {
    return this.http.get<ApiResponse<MasterProduct>>(`${this.API_URL}/${id}`)
      .pipe(map(response => response.data));
  }

  getMasterProductBySku(sku: string): Observable<MasterProduct> {
    return this.http.get<ApiResponse<MasterProduct>>(`${this.API_URL}/sku/${sku}`)
      .pipe(map(response => response.data));
  }

  createMasterProduct(product: MasterProductRequest): Observable<MasterProduct> {
    return this.http.post<ApiResponse<MasterProduct>>(this.API_URL, product)
      .pipe(map(response => response.data));
  }

  updateMasterProduct(id: number, product: MasterProductRequest): Observable<MasterProduct> {
    return this.http.put<ApiResponse<MasterProduct>>(`${this.API_URL}/${id}`, product)
      .pipe(map(response => response.data));
  }

  deleteMasterProduct(id: number): Observable<void> {
    return this.http.delete<ApiResponse<void>>(`${this.API_URL}/${id}`)
      .pipe(map(() => void 0));
  }

  searchMasterProducts(query: string, page: number = 0, size: number = 10): Observable<ProductPage<MasterProduct>> {
    const params = new HttpParams()
      .set('query', query)
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<ApiResponse<ProductPage<MasterProduct>>>(`${this.API_URL}/search`, { params })
      .pipe(map(response => response.data));
  }

  getFeaturedProducts(): Observable<MasterProduct[]> {
    return this.http.get<ApiResponse<MasterProduct[]>>(`${this.API_URL}/featured`)
      .pipe(map(response => response.data));
  }

  getProductsByCategory(categoryId: number, page: number = 0, size: number = 10): Observable<ProductPage<MasterProduct>> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<ApiResponse<ProductPage<MasterProduct>>>(`${this.API_URL}/category/${categoryId}`, { params })
      .pipe(map(response => response.data));
  }

  getAllBrands(): Observable<string[]> {
    return this.http.get<ApiResponse<string[]>>(`${this.API_URL}/brands`)
      .pipe(map(response => response.data));
  }

  uploadMasterProductImages(productId: number, formData: FormData): Observable<any[]> {
    return this.http.post<ApiResponse<any[]>>(`${environment.apiUrl}/products/images/master/${productId}`, formData)
      .pipe(map(response => response.data));
  }

  deleteMasterProductImage(imageId: number): Observable<void> {
    return this.http.delete<ApiResponse<void>>(`${environment.apiUrl}/products/images/${imageId}`)
      .pipe(map(() => void 0));
  }

  getMasterProductImages(productId: number): Observable<any[]> {
    return this.http.get<ApiResponse<any[]>>(`${environment.apiUrl}/products/images/master/${productId}`)
      .pipe(map(response => response.data));
  }

  getShopProductImages(shopId: number, productId: number): Observable<any[]> {
    return this.http.get<ApiResponse<any[]>>(`${environment.apiUrl}/products/images/shop/${shopId}/${productId}`)
      .pipe(map(response => response.data));
  }

  uploadShopProductImages(shopId: number, productId: number, formData: FormData): Observable<any[]> {
    return this.http.post<ApiResponse<any[]>>(`${environment.apiUrl}/products/images/shop/${shopId}/${productId}`, formData)
      .pipe(map(response => response.data));
  }
}