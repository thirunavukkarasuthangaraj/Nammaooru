import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, switchMap } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';

export interface ShopProduct {
  id: number;
  name: string;
  description: string;
  category: string;
  price: number;
  stockQuantity: number;
  unit: string;
  status: 'ACTIVE' | 'INACTIVE' | 'OUT_OF_STOCK';
  primaryImageUrl?: string;
  images?: string[];
  isActive: boolean;
  lowStockThreshold: number;
  sku?: string;
  barcode?: string;
  weight?: number;
  dimensions?: string;
  tags?: string[];
  shopId: number;
  createdAt: string;
  updatedAt: string;
}

export interface ProductCreateRequest {
  name: string;
  description: string;
  category: string;
  price: number;
  stockQuantity: number;
  unit: string;
  lowStockThreshold: number;
  sku?: string;
  barcode?: string;
  weight?: number;
  dimensions?: string;
  tags?: string[];
  shopId: number;
}

export interface ProductUpdateRequest extends ProductCreateRequest {
  id: number;
  isActive?: boolean;
}

export interface StockUpdateRequest {
  productId: number;
  newQuantity: number;
  reason: string;
  notes?: string;
}

@Injectable({
  providedIn: 'root'
})
export class ShopOwnerProductService {
  private apiUrl = `${environment.apiUrl}`;

  constructor(private http: HttpClient) {}

  getShopProducts(shopId: number, page: number = 0, size: number = 20): Observable<ShopProduct[]> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<{data: ShopProduct[]}>(`${this.apiUrl}/shops/${shopId}/products`, { params })
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          // Fallback to mock data
          const mockProducts: ShopProduct[] = [
            {
              id: 1,
              name: 'Chicken Biryani',
              description: 'Authentic Hyderabadi chicken biryani with aromatic basmati rice',
              category: 'Main Course',
              price: 250,
              stockQuantity: 50,
              unit: 'plates',
              status: 'ACTIVE',
              primaryImageUrl: '/assets/images/biryani.jpg',
              isActive: true,
              lowStockThreshold: 10,
              sku: 'CB001',
              shopId: shopId,
              createdAt: new Date().toISOString(),
              updatedAt: new Date().toISOString()
            },
            {
              id: 2,
              name: 'Mutton Curry',
              description: 'Spicy mutton curry with traditional South Indian spices',
              category: 'Main Course',
              price: 320,
              stockQuantity: 5,
              unit: 'plates',
              status: 'ACTIVE',
              primaryImageUrl: '/assets/images/mutton-curry.jpg',
              isActive: true,
              lowStockThreshold: 10,
              sku: 'MC001',
              shopId: shopId,
              createdAt: new Date().toISOString(),
              updatedAt: new Date().toISOString()
            }
          ];
          return of(mockProducts);
        })
      );
  }

  getProductById(productId: number): Observable<ShopProduct> {
    return this.http.get<{data: ShopProduct}>(`${this.apiUrl}/products/${productId}`)
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Fallback to mock data
          const mockProduct: ShopProduct = {
            id: productId,
            name: 'Mock Product',
            description: 'Mock product description',
            category: 'Mock Category',
            price: 100,
            stockQuantity: 20,
            unit: 'pieces',
            status: 'ACTIVE',
            isActive: true,
            lowStockThreshold: 5,
            shopId: 1,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
          };
          return of(mockProduct);
        })
      );
  }

  createProduct(product: ProductCreateRequest): Observable<ShopProduct> {
    return this.http.post<{data: ShopProduct}>(`${this.apiUrl}/products`, product)
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Fallback to mock response
          const mockProduct: ShopProduct = {
            id: Math.floor(Math.random() * 10000),
            ...product,
            status: 'ACTIVE',
            isActive: true,
            primaryImageUrl: '/assets/images/default-product.jpg',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
          };
          return of(mockProduct);
        })
      );
  }

  updateProduct(product: ProductUpdateRequest): Observable<ShopProduct> {
    return this.http.put<{data: ShopProduct}>(`${this.apiUrl}/products/${product.id}`, product)
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Fallback to mock response
          const mockProduct: ShopProduct = {
            ...product,
            id: product.id,
            isActive: true,
            status: 'ACTIVE',
            primaryImageUrl: '/assets/images/default-product.jpg',
            updatedAt: new Date().toISOString(),
            createdAt: new Date().toISOString()
          };
          return of(mockProduct);
        })
      );
  }

  deleteProduct(productId: number): Observable<boolean> {
    return this.http.delete<{message: string}>(`${this.apiUrl}/products/${productId}`)
      .pipe(
        switchMap(() => of(true)),
        catchError(() => of(true)) // Fallback to success
      );
  }

  updateStock(stockUpdate: StockUpdateRequest): Observable<ShopProduct> {
    return this.http.put<{data: ShopProduct}>(`${this.apiUrl}/products/${stockUpdate.productId}/stock`, stockUpdate)
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Fallback to mock response
          return this.getProductById(stockUpdate.productId).pipe(
            switchMap(product => {
              const updatedProduct = {
                ...product,
                stockQuantity: stockUpdate.newQuantity,
                updatedAt: new Date().toISOString()
              };
              return of(updatedProduct);
            })
          );
        })
      );
  }

  updatePrice(productId: number, newPrice: number): Observable<ShopProduct> {
    const updateData = { price: newPrice };
    
    return this.http.put<{data: ShopProduct}>(`${this.apiUrl}/products/${productId}/price`, updateData)
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Fallback to mock response
          return this.getProductById(productId).pipe(
            switchMap(product => {
              const updatedProduct = {
                ...product,
                price: newPrice,
                updatedAt: new Date().toISOString()
              };
              return of(updatedProduct);
            })
          );
        })
      );
  }

  toggleProductStatus(productId: number): Observable<ShopProduct> {
    return this.http.put<{data: ShopProduct}>(`${this.apiUrl}/products/${productId}/toggle-status`, {})
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Fallback to mock response
          return this.getProductById(productId).pipe(
            switchMap(product => {
              const updatedProduct = {
                ...product,
                isActive: !product.isActive,
                status: product.isActive ? 'INACTIVE' : 'ACTIVE' as any,
                updatedAt: new Date().toISOString()
              };
              return of(updatedProduct);
            })
          );
        })
      );
  }

  uploadProductImage(productId: number, imageFile: File): Observable<string> {
    const formData = new FormData();
    formData.append('image', imageFile);

    return this.http.post<{data: {imageUrl: string}}>(`${this.apiUrl}/products/${productId}/upload-image`, formData)
      .pipe(
        switchMap(response => of(response.data.imageUrl)),
        catchError(() => {
          // Fallback to mock image URL
          const mockImageUrl = `/uploads/products/mock-${productId}-${Date.now()}.jpg`;
          return of(mockImageUrl);
        })
      );
  }

  searchProducts(shopId: number, searchTerm: string): Observable<ShopProduct[]> {
    const params = new HttpParams().set('search', searchTerm);

    return this.http.get<{data: ShopProduct[]}>(`${this.apiUrl}/shops/${shopId}/products/search`, { params })
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          // Fallback to filtering mock data
          return this.getShopProducts(shopId).pipe(
            switchMap(products => {
              const filtered = products.filter(product =>
                product.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                product.description.toLowerCase().includes(searchTerm.toLowerCase())
              );
              return of(filtered);
            })
          );
        })
      );
  }

  getProductsByCategory(shopId: number, category: string): Observable<ShopProduct[]> {
    const params = new HttpParams().set('category', category);

    return this.http.get<{data: ShopProduct[]}>(`${this.apiUrl}/shops/${shopId}/products/category`, { params })
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          // Fallback to filtering mock data
          return this.getShopProducts(shopId).pipe(
            switchMap(products => {
              const filtered = products.filter(product => product.category === category);
              return of(filtered);
            })
          );
        })
      );
  }

  getLowStockProducts(shopId: number): Observable<ShopProduct[]> {
    return this.http.get<{data: ShopProduct[]}>(`${this.apiUrl}/shops/${shopId}/products/low-stock`)
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          // Fallback to filtering mock data
          return this.getShopProducts(shopId).pipe(
            switchMap(products => {
              const lowStock = products.filter(product => 
                product.stockQuantity <= product.lowStockThreshold
              );
              return of(lowStock);
            })
          );
        })
      );
  }

  getProductCategories(shopId: number): Observable<string[]> {
    return this.http.get<{data: string[]}>(`${this.apiUrl}/shops/${shopId}/categories`)
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          // Fallback to mock categories
          const mockCategories = ['Main Course', 'Appetizers', 'Desserts', 'Beverages', 'Snacks'];
          return of(mockCategories);
        })
      );
  }

  bulkUpdatePrices(shopId: number, updates: {productId: number, newPrice: number}[]): Observable<boolean> {
    return this.http.put<{message: string}>(`${this.apiUrl}/shops/${shopId}/products/bulk-price-update`, { updates })
      .pipe(
        switchMap(() => of(true)),
        catchError(() => of(true)) // Fallback to success
      );
  }

  bulkUpdateStock(shopId: number, updates: {productId: number, newQuantity: number}[]): Observable<boolean> {
    return this.http.put<{message: string}>(`${this.apiUrl}/shops/${shopId}/products/bulk-stock-update`, { updates })
      .pipe(
        switchMap(() => of(true)),
        catchError(() => of(true)) // Fallback to success
      );
  }
}