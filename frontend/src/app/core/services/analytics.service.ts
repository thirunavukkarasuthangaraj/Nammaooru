import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

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
  startDate: Date;
  endDate: Date;
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

  getDashboardMetrics(startDate: Date, endDate: Date): Observable<DashboardMetrics> {
    const request: AnalyticsRequest = {
      periodType: 'CUSTOM',
      startDate,
      endDate
    };
    return this.http.post<DashboardMetrics>(`${this.apiUrl}/dashboard`, request);
  }

  getShopDashboardMetrics(shopId: number, startDate: Date, endDate: Date): Observable<DashboardMetrics> {
    const request: AnalyticsRequest = {
      periodType: 'CUSTOM',
      startDate,
      endDate,
      shopId
    };
    return this.http.post<DashboardMetrics>(`${this.apiUrl}/dashboard/shop/${shopId}`, request);
  }

  getCustomerAnalytics(startDate: Date, endDate: Date): Observable<any> {
    const request: AnalyticsRequest = {
      periodType: 'CUSTOM',
      startDate,
      endDate
    };
    return this.http.post(`${this.apiUrl}/customers`, request);
  }

  generateAnalytics(startDate: Date, endDate: Date, periodType: string): Observable<void> {
    return this.http.post<void>(`${this.apiUrl}/generate`, {}, {
      params: {
        startDate: startDate.toISOString(),
        endDate: endDate.toISOString(),
        periodType
      }
    });
  }

  getAvailableCategories(): Observable<string[]> {
    return this.http.get<string[]>(`${this.apiUrl}/categories`);
  }

  getAvailableMetricTypes(): Observable<string[]> {
    return this.http.get<string[]>(`${this.apiUrl}/metric-types`);
  }

  getAvailablePeriodTypes(): Observable<string[]> {
    return this.http.get<string[]>(`${this.apiUrl}/period-types`);
  }

  getAnalyticsEnums(): Observable<any> {
    return this.http.get(`${this.apiUrl}/enums`);
  }
}