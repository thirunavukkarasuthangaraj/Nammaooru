import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../../environments/environment';
import { ApiResponse } from '../models/api-response.model';
import { ProductCategory, ProductCategoryRequest, ProductPage } from '../models/product.model';

@Injectable({
  providedIn: 'root'
})
export class ProductCategoryService {
  private readonly API_URL = `${environment.apiUrl}/products/categories`;

  constructor(private http: HttpClient) {}

  // Categories
  getCategories(
    parentId?: number, 
    isActive?: boolean, 
    search?: string, 
    page: number = 0, 
    size: number = 10,
    sortBy: string = 'name',
    sortDirection: 'ASC' | 'DESC' = 'ASC'
  ): Observable<ProductPage<ProductCategory>> {
    let params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString())
      .set('sortBy', sortBy)
      .set('sortDirection', sortDirection);

    if (parentId !== undefined) {
      params = params.set('parentId', parentId.toString());
    }
    if (isActive !== undefined) {
      params = params.set('isActive', isActive.toString());
    }
    if (search) {
      params = params.set('search', search);
    }

    return this.http.get<ApiResponse<ProductPage<ProductCategory>>>(this.API_URL, { params })
      .pipe(map(response => response.data));
  }

  getCategoryTree(rootId?: number, activeOnly: boolean = true): Observable<ProductCategory[]> {
    let params = new HttpParams().set('activeOnly', activeOnly.toString());
    
    if (rootId !== undefined) {
      params = params.set('rootId', rootId.toString());
    }

    return this.http.get<ApiResponse<ProductCategory[]>>(`${this.API_URL}/tree`, { params })
      .pipe(map(response => response.data));
  }

  getRootCategories(activeOnly: boolean = true): Observable<ProductCategory[]> {
    const params = new HttpParams().set('activeOnly', activeOnly.toString());

    return this.http.get<ApiResponse<ProductCategory[]>>(`${this.API_URL}/root`, { params })
      .pipe(map(response => response.data));
  }

  getCategory(id: number): Observable<ProductCategory> {
    return this.http.get<ApiResponse<ProductCategory>>(`${this.API_URL}/${id}`)
      .pipe(map(response => response.data));
  }

  getCategoryBySlug(slug: string): Observable<ProductCategory> {
    return this.http.get<ApiResponse<ProductCategory>>(`${this.API_URL}/slug/${slug}`)
      .pipe(map(response => response.data));
  }

  createCategory(category: ProductCategoryRequest): Observable<ProductCategory> {
    return this.http.post<ApiResponse<ProductCategory>>(this.API_URL, category)
      .pipe(map(response => response.data));
  }

  updateCategory(id: number, category: ProductCategoryRequest): Observable<ProductCategory> {
    return this.http.put<ApiResponse<ProductCategory>>(`${this.API_URL}/${id}`, category)
      .pipe(map(response => response.data));
  }

  deleteCategory(id: number): Observable<void> {
    return this.http.delete<ApiResponse<void>>(`${this.API_URL}/${id}`)
      .pipe(map(() => void 0));
  }

  getSubcategories(id: number, activeOnly: boolean = true): Observable<ProductCategory[]> {
    const params = new HttpParams().set('activeOnly', activeOnly.toString());

    return this.http.get<ApiResponse<ProductCategory[]>>(`${this.API_URL}/${id}/subcategories`, { params })
      .pipe(map(response => response.data));
  }

  getCategoryPath(id: number): Observable<ProductCategory[]> {
    return this.http.get<ApiResponse<ProductCategory[]>>(`${this.API_URL}/${id}/path`)
      .pipe(map(response => response.data));
  }

  updateCategoryStatus(id: number, isActive: boolean): Observable<ProductCategory> {
    const params = new HttpParams().set('isActive', isActive.toString());

    return this.http.patch<ApiResponse<ProductCategory>>(`${this.API_URL}/${id}/status`, null, { params })
      .pipe(map(response => response.data));
  }

  reorderCategories(categoryIds: number[]): Observable<ProductCategory[]> {
    return this.http.patch<ApiResponse<ProductCategory[]>>(`${this.API_URL}/reorder`, categoryIds)
      .pipe(map(response => response.data));
  }
}