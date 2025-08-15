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

    return this.http.get<ShopResponse>(`${this.API_URL}/search`, { params });
  }

  // Get shop by ID
  getShop(id: number): Observable<Shop> {
    return this.http.get<any>(`${this.API_URL}/${id}`).pipe(
      map(shop => this.transformShop(shop))
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

  // Approve shop (admin only)
  approveShop(id: number): Observable<Shop> {
    return this.http.put<Shop>(`${this.API_URL}/${id}/approve`, {});
  }

  // Reject shop (admin only)
  rejectShop(id: number, reason: string): Observable<Shop> {
    return this.http.put<Shop>(`${this.API_URL}/${id}/reject`, { reason });
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