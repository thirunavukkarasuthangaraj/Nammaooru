import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map, tap, catchError, throwError } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ApiResponse, ApiResponseHelper } from '../models/api-response.model';

export interface DashboardMetrics {
  totalRevenue: number;
  totalOrders: number;
  totalCustomers: number;
  totalShops: number;
  averageOrderValue: number;
  conversionRate: number;
  customerRetentionRate: number;
  monthlyGrowth: number;
  revenueData: RevenueData[];
  orderData: OrderData[];
  categoryData: CategoryData[];
  topShops: ShopPerformance[];
  topProducts: ProductPerformance[];
  revenueByPeriod: { [key: string]: number };
  ordersByPeriod: { [key: string]: number };
  conversionByPeriod: { [key: string]: number };
}

export interface RevenueData {
  period: string;
  revenue: number;
  previousRevenue: number;
  growthPercentage: number;
  date: string;
}

export interface OrderData {
  period: string;
  orderCount: number;
  previousOrderCount: number;
  growthPercentage: number;
  date: string;
}

export interface CategoryData {
  categoryName: string;
  revenue: number;
  orderCount: number;
  marketShare: number;
  growthPercentage: number;
}

export interface ShopPerformance {
  shopId: number;
  shopName: string;
  shopOwner: string;
  revenue: number;
  orderCount: number;
  customerCount: number;
  rating: number;
  growthPercentage: number;
  status: string;
}

export interface ProductPerformance {
  productId: number;
  productName: string;
  category: string;
  quantitySold: number;
  revenue: number;
  averageRating: number;
  stockLevel: number;
  conversionRate: number;
  trendDirection: string;
}

export interface AnalyticsRequest {
  periodType: string;
  startDate: string;
  endDate: string;
  shopId?: number;
  category?: string;
  metricType?: string;
}

@Injectable({
  providedIn: 'root'
})
export class AnalyticsService {
  private apiUrl = `${environment.apiUrl}/analytics`;

  constructor(private http: HttpClient) {}

  /** Format Date to LocalDateTime string (no timezone) for Java backend */
  private formatDate(date: Date): string {
    const pad = (n: number) => n.toString().padStart(2, '0');
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
  }

  getDashboardMetrics(startDate: Date, endDate: Date): Observable<DashboardMetrics> {
    const request: AnalyticsRequest = {
      periodType: 'CUSTOM',
      startDate: this.formatDate(startDate),
      endDate: this.formatDate(endDate)
    };
    return this.http.post<ApiResponse<DashboardMetrics>>(`${this.apiUrl}/dashboard`, request)
      .pipe(
        map(response => {
          if (ApiResponseHelper.isError(response)) {
            const errorMessage = ApiResponseHelper.getErrorMessage(response);
            throw new Error(errorMessage);
          }
          return response.data;
        }),
        catchError(error => {
          console.error('Dashboard metrics error:', error);
          return throwError(() => error);
        })
      );
  }

  getShopDashboardMetrics(shopId: number, startDate: Date, endDate: Date): Observable<DashboardMetrics> {
    const request: AnalyticsRequest = {
      periodType: 'CUSTOM',
      startDate: this.formatDate(startDate),
      endDate: this.formatDate(endDate),
      shopId
    };
    return this.http.post<ApiResponse<DashboardMetrics>>(`${this.apiUrl}/dashboard/shop/${shopId}`, request)
      .pipe(
        map(response => {
          if (ApiResponseHelper.isError(response)) {
            const errorMessage = ApiResponseHelper.getErrorMessage(response);
            throw new Error(errorMessage);
          }
          return response.data;
        }),
        catchError(error => {
          console.error('Shop dashboard metrics error:', error);
          return throwError(() => error);
        })
      );
  }

  getCustomerAnalytics(startDate: Date, endDate: Date): Observable<any> {
    const request: AnalyticsRequest = {
      periodType: 'CUSTOM',
      startDate: this.formatDate(startDate),
      endDate: this.formatDate(endDate)
    };
    return this.http.post<ApiResponse<any>>(`${this.apiUrl}/customers`, request)
      .pipe(
        map(response => {
          if (ApiResponseHelper.isError(response)) {
            const errorMessage = ApiResponseHelper.getErrorMessage(response);
            throw new Error(errorMessage);
          }
          return response.data;
        }),
        catchError(error => {
          console.error('Customer analytics error:', error);
          return throwError(() => error);
        })
      );
  }

  generateAnalytics(startDate: Date, endDate: Date, periodType: string): Observable<void> {
    return this.http.post<void>(`${this.apiUrl}/generate`, {}, {
      params: {
        startDate: this.formatDate(startDate),
        endDate: this.formatDate(endDate),
        periodType
      }
    });
  }

  getAvailableCategories(): Observable<string[]> {
    return this.http.get<ApiResponse<string[]>>(`${this.apiUrl}/categories`)
      .pipe(
        map(response => {
          if (ApiResponseHelper.isError(response)) {
            const errorMessage = ApiResponseHelper.getErrorMessage(response);
            throw new Error(errorMessage);
          }
          return response.data;
        }),
        catchError(error => {
          console.error('Categories error:', error);
          return throwError(() => error);
        })
      );
  }

  getAvailableMetricTypes(): Observable<string[]> {
    return this.http.get<ApiResponse<string[]>>(`${this.apiUrl}/metric-types`)
      .pipe(
        map(response => {
          if (ApiResponseHelper.isError(response)) {
            const errorMessage = ApiResponseHelper.getErrorMessage(response);
            throw new Error(errorMessage);
          }
          return response.data;
        }),
        catchError(error => {
          console.error('Metric types error:', error);
          return throwError(() => error);
        })
      );
  }

  getAvailablePeriodTypes(): Observable<string[]> {
    return this.http.get<ApiResponse<string[]>>(`${this.apiUrl}/period-types`)
      .pipe(
        map(response => {
          if (ApiResponseHelper.isError(response)) {
            const errorMessage = ApiResponseHelper.getErrorMessage(response);
            throw new Error(errorMessage);
          }
          return response.data;
        }),
        catchError(error => {
          console.error('Period types error:', error);
          return throwError(() => error);
        })
      );
  }

  getAnalyticsEnums(): Observable<any> {
    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/enums`)
      .pipe(
        map(response => {
          if (ApiResponseHelper.isError(response)) {
            const errorMessage = ApiResponseHelper.getErrorMessage(response);
            throw new Error(errorMessage);
          }
          return response.data;
        }),
        catchError(error => {
          console.error('Analytics enums error:', error);
          return throwError(() => error);
        })
      );
  }
}