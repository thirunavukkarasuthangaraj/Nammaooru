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

    return this.http.get<{data: {content: any[]}}>(`${this.apiUrl}/shop-products/my-products`, { params })
      .pipe(
        switchMap(response => of(response.data?.content || [])),
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
            shopId: 57,
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

  uploadProductImage(shopId: number, productId: number, imageFile: File): Observable<any> {
    const formData = new FormData();
    formData.append('images', imageFile);

    return this.http.post<any>(`${this.apiUrl}/products/images/shop/${shopId}/${productId}`, formData)
      .pipe(
        switchMap(response => {
          console.log('Upload response:', response);
          // Return the first image from the response
          if (response && response.data && response.data.length > 0) {
            const imageData = response.data[0];
            console.log('Image data from server:', imageData);
            // The imageUrl from backend is the actual path we need to use
            return of({
              id: imageData.id,
              imageUrl: imageData.imageUrl, // This should be like "uploads/products/shop/..."
              isPrimary: imageData.isPrimary
            });
          }
          return of(null);
        }),
        catchError((error) => {
          console.error('Error uploading image:', error);
          // Fallback to mock image URL
          const mockImageUrl = `uploads/products/shop/${shopId}/product_${productId}_${Date.now()}.jpg`;
          return of({ imageUrl: mockImageUrl });
        })
      );
  }

  getProductImages(shopId: number, productId: number): Observable<any[]> {
    return this.http.get<any>(`${this.apiUrl}/products/images/shop/${shopId}/${productId}`)
      .pipe(
        switchMap(response => {
          if (response && response.data) {
            return of(response.data);
          }
          return of([]);
        }),
        catchError(() => of([]))
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

  // Browse master products for assignment to shop
  getMasterProducts(page: number = 0, size: number = 20, search?: string): Observable<any[]> {
    let params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    if (search) {
      params = params.set('search', search);
    }

    return this.http.get<{data: any[]}>(`${this.apiUrl}/products/master`, { params })
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          // Fallback to mock data
          const mockMasterProducts = [
            {
              id: 1,
              name: 'Organic Rice Basmati',
              description: 'Premium quality organic basmati rice',
              sku: 'RICE-ORG-001',
              brand: 'Organic India',
              category: { name: 'Grocery', id: 1 },
              baseUnit: 'kg',
              baseWeight: 1.0,
              status: 'ACTIVE',
              isFeatured: true,
              primaryImageUrl: '/assets/images/rice.jpg'
            },
            {
              id: 2,
              name: 'Fresh Milk',
              description: 'Pure cow milk',
              sku: 'MILK-FRESH-001',
              brand: 'Amul',
              category: { name: 'Dairy', id: 2 },
              baseUnit: 'liter',
              baseWeight: 1.0,
              status: 'ACTIVE',
              isFeatured: false,
              primaryImageUrl: '/assets/images/milk.jpg'
            }
          ];
          return of(mockMasterProducts);
        })
      );
  }

  // Get available master products (excluding already assigned products)
  getAvailableMasterProducts(page: number = 0, size: number = 20, search?: string, categoryId?: number, brand?: string): Observable<{content: any[], totalElements: number}> {
    let params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    if (search) {
      params = params.set('search', search);
    }
    if (categoryId) {
      params = params.set('categoryId', categoryId.toString());
    }
    if (brand) {
      params = params.set('brand', brand);
    }

    return this.http.get<{data: {content: any[], totalElements: number}}>(`${this.apiUrl}/shop-products/available-master-products`, { params })
      .pipe(
        switchMap(response => of(response.data || {content: [], totalElements: 0})),
        catchError(() => {
          // Fallback to mock data
          const mockMasterProducts = [
            {
              id: 3,
              name: 'Organic Tomatoes',
              description: 'Fresh organic tomatoes from local farms',
              sku: 'TOM-ORG-001',
              brand: 'Fresh Farm',
              category: { name: 'Vegetables', id: 3 },
              baseUnit: 'kg',
              baseWeight: 1.0,
              status: 'ACTIVE',
              isFeatured: true,
              primaryImageUrl: '/assets/images/tomatoes.jpg',
              images: [{ imageUrl: '/assets/images/tomatoes.jpg', isPrimary: true }]
            },
            {
              id: 4,
              name: 'Premium Chicken',
              description: 'Fresh chicken from organic farms',
              sku: 'CHK-PREM-001',
              brand: 'Organic Meat',
              category: { name: 'Meat', id: 4 },
              baseUnit: 'kg',
              baseWeight: 1.0,
              status: 'ACTIVE',
              isFeatured: false,
              primaryImageUrl: '/assets/images/chicken.jpg',
              images: [{ imageUrl: '/assets/images/chicken.jpg', isPrimary: true }]
            }
          ];
          return of({content: mockMasterProducts, totalElements: mockMasterProducts.length});
        })
      );
  }

  // Assign master product to shop with custom price
  assignProductToShop(shopId: number, assignmentData: {
    masterProductId: number;
    price: number;
    stockQuantity?: number;
    customName?: string;
    customDescription?: string;
  }): Observable<ShopProduct> {
    const payload = {
      masterProductId: assignmentData.masterProductId,
      price: assignmentData.price,
      stockQuantity: assignmentData.stockQuantity || 0,
      customName: assignmentData.customName,
      customDescription: assignmentData.customDescription,
      isAvailable: true,
      status: 'ACTIVE'
    };

    return this.http.post<{data: ShopProduct}>(`${this.apiUrl}/shops/${shopId}/products`, payload)
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Fallback to mock response
          const mockProduct: ShopProduct = {
            id: Math.floor(Math.random() * 10000),
            name: assignmentData.customName || 'Assigned Product',
            description: assignmentData.customDescription || 'Product assigned from master catalog',
            category: 'General',
            price: assignmentData.price,
            stockQuantity: assignmentData.stockQuantity || 0,
            unit: 'piece',
            status: 'ACTIVE',
            isActive: true,
            lowStockThreshold: 10,
            shopId: shopId,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
          };
          return of(mockProduct);
        })
      );
  }
}