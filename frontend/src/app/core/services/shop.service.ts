import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { throwError } from 'rxjs';
import { Shop, BusinessType, ShopStatus } from '../models/shop.model';
import { ApiResponse, ApiResponseHelper } from '../models/api-response.model';
import { API_ENDPOINTS } from '../constants/app.constants';
import { ConstantsService } from './constants.service';
export { Shop } from '../models/shop.model';

export interface ShopResponse {
  content: any[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
  first: boolean;
  last: boolean;
  hasNext: boolean;
  hasPrevious: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class ShopService {
  private readonly API_URL = API_ENDPOINTS.BASE_URL + API_ENDPOINTS.SHOPS.BASE;

  constructor(
    private http: HttpClient,
    private constants: ConstantsService
  ) {}

  // Get all shops with pagination and filtering
  getShops(params?: any): Observable<ShopResponse> {
    let httpParams = new HttpParams();
    
    if (params) {
      Object.keys(params).forEach(key => {
        if (params[key] !== null && params[key] !== undefined && params[key] !== '') {
          httpParams = httpParams.set(key, params[key].toString());
        }
      });
    }

    return this.http.get<ApiResponse<any>>(this.API_URL, { params: httpParams }).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        // Backend returns ApiResponse<ShopPageResponse>, so we need to access data.content
        const shopPageResponse = apiResponse.data;
        return {
          content: shopPageResponse.content.map((shop: any) => this.transformShop(shop)),
          totalElements: shopPageResponse.totalElements,
          totalPages: shopPageResponse.totalPages,
          size: shopPageResponse.size,
          number: shopPageResponse.page,
          first: shopPageResponse.first,
          last: shopPageResponse.last,
          hasNext: shopPageResponse.hasNext,
          hasPrevious: shopPageResponse.hasPrevious
        };
      }),
      catchError(error => {
        console.error('Error fetching shops:', error);
        return throwError(() => error);
      })
    );
  }

  // Search shops
  searchShops(query: string, page: number = 0, size: number = 20): Observable<ShopResponse> {
    const params = new HttpParams()
      .set('q', query)
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<ApiResponse<any>>(`${this.API_URL}/search`, { params }).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        const shopPageResponse = apiResponse.data;
        return {
          content: shopPageResponse.content.map((shop: any) => this.transformShop(shop)),
          totalElements: shopPageResponse.totalElements,
          totalPages: shopPageResponse.totalPages,
          size: shopPageResponse.size,
          number: shopPageResponse.page,
          first: shopPageResponse.first,
          last: shopPageResponse.last,
          hasNext: shopPageResponse.hasNext,
          hasPrevious: shopPageResponse.hasPrevious
        };
      }),
      catchError(error => {
        console.error('Error searching shops:', error);
        return throwError(() => error);
      })
    );
  }

  // Get shop by ID
  getShop(id: number): Observable<Shop> {
    return this.http.get<ApiResponse<any>>(`${this.API_URL}/${id}`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return this.transformShop(apiResponse.data);
      }),
      catchError(error => {
        console.error('Error fetching shop by ID:', error);
        return throwError(() => error);
      })
    );
  }

  // Create new shop
  createShop(shop: Partial<Shop>): Observable<any> {
    return this.http.post<ApiResponse<any>>(this.API_URL, shop).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return apiResponse.data; // Return the actual shop data
      }),
      catchError(error => {
        console.error('Error creating shop:', error);
        return throwError(() => error);
      })
    );
  }

  // Update existing shop
  updateShop(id: number, shop: Partial<Shop>): Observable<any> {
    return this.http.put<ApiResponse<any>>(`${this.API_URL}/${id}`, shop).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return apiResponse.data; // Return the actual shop data
      }),
      catchError(error => {
        console.error('Error updating shop:', error);
        return throwError(() => error);
      })
    );
  }

  // Delete shop
  deleteShop(id: number): Observable<void> {
    return this.http.delete<void>(`${this.API_URL}/${id}`);
  }

  // Get cities for filtering
  getCities(): Observable<string[]> {
    return this.http.get<ApiResponse<{cities: string[], count: number}>>(`${this.API_URL}/cities`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return apiResponse.data.cities;
      }),
      catchError(error => {
        console.error('Error fetching cities:', error);
        return throwError(() => error);
      })
    );
  }

  // Get pending shops for approval (admin only)
  getPendingShops(params?: any): Observable<ShopResponse> {
    let httpParams = new HttpParams();
    
    if (params) {
      Object.keys(params).forEach(key => {
        if (params[key] !== null && params[key] !== undefined && params[key] !== '') {
          httpParams = httpParams.set(key, params[key].toString());
        }
      });
    }

    return this.http.get<ApiResponse<any>>(`${this.API_URL}/approvals`, { params: httpParams }).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        const shopPageResponse = apiResponse.data;
        return {
          content: shopPageResponse.content.map((shop: any) => this.transformShop(shop)),
          totalElements: shopPageResponse.totalElements,
          totalPages: shopPageResponse.totalPages,
          size: shopPageResponse.size,
          number: shopPageResponse.page,
          first: shopPageResponse.first,
          last: shopPageResponse.last,
          hasNext: shopPageResponse.hasNext,
          hasPrevious: shopPageResponse.hasPrevious
        };
      }),
      catchError(error => {
        console.error('Error fetching pending shops:', error);
        return throwError(() => error);
      })
    );
  }

  // Get approval statistics (admin only)
  getApprovalStats(): Observable<any> {
    return this.http.get<ApiResponse<any>>(`${this.API_URL}/approvals/stats`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return apiResponse.data;
      }),
      catchError(error => {
        console.error('Error fetching approval stats:', error);
        return throwError(() => error);
      })
    );
  }

  // Approve shop (admin only)
  approveShop(id: number, notes?: string): Observable<Shop> {
    const body = notes ? { notes } : {};
    return this.http.put<ApiResponse<any>>(`${this.API_URL}/${id}/approve`, body).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return this.transformShop(apiResponse.data);
      }),
      catchError(error => {
        console.error('Error approving shop:', error);
        return throwError(() => error);
      })
    );
  }

  // Reject shop (admin only)
  rejectShop(id: number, reason: string): Observable<Shop> {
    return this.http.put<ApiResponse<any>>(`${this.API_URL}/${id}/reject`, { reason }).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return this.transformShop(apiResponse.data);
      }),
      catchError(error => {
        console.error('Error rejecting shop:', error);
        return throwError(() => error);
      })
    );
  }

  // Get shop documents for approval (admin only)
  getShopDocuments(shopId: number): Observable<any[]> {
    return this.http.get<ApiResponse<any[]>>(`${this.API_URL}/approvals/${shopId}/documents`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return apiResponse.data;
      }),
      catchError(error => {
        console.error('Error fetching shop documents:', error);
        return throwError(() => error);
      })
    );
  }

  // Get document verification status for a shop (admin only)
  getDocumentVerificationStatus(shopId: number): Observable<any> {
    return this.http.get<ApiResponse<any>>(`${this.API_URL}/approvals/${shopId}/documents/verification-status`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return apiResponse.data;
      }),
      catchError(error => {
        console.error('Error fetching document verification status:', error);
        return throwError(() => error);
      })
    );
  }

  // Get current user's shop (shop owner only)
  getMyShop(): Observable<Shop> {
    return this.http.get<ApiResponse<any>>(`${this.API_URL}/my-shop`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return this.transformShop(apiResponse.data);
      }),
      catchError(error => {
        console.error('Error fetching current user shop:', error);
        return throwError(() => error);
      })
    );
  }

  // Dashboard methods for shop owner
  getTodaysRevenue(): Observable<number> {
    return this.http.get<ApiResponse<number>>(`${this.API_URL}/dashboard/todays-revenue`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          return 0;
        }
        return apiResponse.data || 0;
      }),
      catchError(error => {
        console.error('Error fetching todays revenue:', error);
        return throwError(() => 0);
      })
    );
  }

  getTodaysOrderCount(): Observable<number> {
    return this.http.get<ApiResponse<number>>(`${this.API_URL}/dashboard/todays-orders`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          return 0;
        }
        return apiResponse.data || 0;
      }),
      catchError(error => {
        console.error('Error fetching todays orders:', error);
        return throwError(() => 0);
      })
    );
  }

  getTotalProductCount(): Observable<number> {
    return this.http.get<ApiResponse<number>>(`${this.API_URL}/dashboard/product-count`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          return 0;
        }
        return apiResponse.data || 0;
      }),
      catchError(error => {
        console.error('Error fetching product count:', error);
        return throwError(() => 0);
      })
    );
  }

  getLowStockCount(): Observable<number> {
    return this.http.get<ApiResponse<number>>(`${this.API_URL}/dashboard/low-stock-count`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          return 0;
        }
        return apiResponse.data || 0;
      }),
      catchError(error => {
        console.error('Error fetching low stock count:', error);
        return throwError(() => 0);
      })
    );
  }

  getRecentOrders(limit: number = 5): Observable<any[]> {
    const params = new HttpParams().set('limit', limit.toString());
    return this.http.get<ApiResponse<any[]>>(`${this.API_URL}/dashboard/recent-orders`, { params }).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          return [];
        }
        return apiResponse.data || [];
      }),
      catchError(error => {
        console.error('Error fetching recent orders:', error);
        return throwError(() => []);
      })
    );
  }

  getLowStockProducts(limit: number = 10): Observable<any[]> {
    const params = new HttpParams().set('limit', limit.toString());
    return this.http.get<ApiResponse<any[]>>(`${this.API_URL}/dashboard/low-stock-products`, { params }).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          return [];
        }
        return apiResponse.data || [];
      }),
      catchError(error => {
        console.error('Error fetching low stock products:', error);
        return throwError(() => []);
      })
    );
  }

  getTotalCustomerCount(): Observable<number> {
    return this.http.get<ApiResponse<number>>(`${this.API_URL}/dashboard/customer-count`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          return 0;
        }
        return apiResponse.data || 0;
      }),
      catchError(error => {
        console.error('Error fetching customer count:', error);
        return throwError(() => 0);
      })
    );
  }

  getNewCustomerCount(): Observable<number> {
    return this.http.get<ApiResponse<number>>(`${this.API_URL}/dashboard/new-customers`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          return 0;
        }
        return apiResponse.data || 0;
      }),
      catchError(error => {
        console.error('Error fetching new customer count:', error);
        return throwError(() => 0);
      })
    );
  }

  // Get shop by ID
  getShopById(id: number): Observable<any> {
    return this.http.get<ApiResponse<any>>(`${this.API_URL}/${id}`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return apiResponse.data;
      }),
      catchError(error => {
        console.error('Error fetching shop by ID:', error);
        return throwError(() => error);
      })
    );
  }

  // Get shop analytics
  getShopAnalytics(shopId: number): Observable<any> {
    return this.http.get<ApiResponse<any>>(`${this.API_URL}/${shopId}/analytics`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return apiResponse.data;
      }),
      catchError(error => {
        console.error('Error fetching shop analytics:', error);
        return throwError(() => error);
      })
    );
  }

  // Upload shop image (logo, banner, or gallery)
  uploadShopImage(shopId: number, file: File, imageType: 'LOGO' | 'BANNER' | 'GALLERY' = 'LOGO'): Observable<any> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('imageType', imageType);

    return this.http.post<ApiResponse<any>>(`${this.API_URL}/${shopId}/images`, formData).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return apiResponse.data;
      }),
      catchError(error => {
        console.error('Error uploading shop image:', error);
        return throwError(() => error);
      })
    );
  }

  // Delete shop image
  deleteShopImage(shopId: number, imageId: number): Observable<void> {
    return this.http.delete<ApiResponse<void>>(`${this.API_URL}/${shopId}/images/${imageId}`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
      }),
      catchError(error => {
        console.error('Error deleting shop image:', error);
        return throwError(() => error);
      })
    );
  }

  // Get shop images
  getShopImages(shopId: number): Observable<any[]> {
    return this.http.get<ApiResponse<any[]>>(`${this.API_URL}/${shopId}/images`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return apiResponse.data || [];
      }),
      catchError(error => {
        console.error('Error fetching shop images:', error);
        return throwError(() => error);
      })
    );
  }

  // Transform API response to match frontend model
  private transformShop(shop: any): Shop {
    return {
      ...shop,
      businessType: shop.businessType as BusinessType || BusinessType.GENERAL,
      status: shop.status as ShopStatus || ShopStatus.PENDING,
      createdAt: new Date(shop.createdAt),
      updatedAt: new Date(shop.updatedAt),
      images: shop.images || [],
      documents: shop.documents || [] // Add documents array for image display
    };
  }
}