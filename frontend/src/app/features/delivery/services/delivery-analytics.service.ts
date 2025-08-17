import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ApiResponse } from '../../../core/models/api-response.model';
import { environment } from '../../../../environments/environment';

export interface DeliveryMetrics {
  totalDeliveries: number;
  successRate: number;
  avgDeliveryTime: number;
  totalRevenue: number;
  activePartners: number;
  avgRating: number;
  onTimeDeliveryRate: number;
  totalDistance: number;
}

export interface TrendData {
  labels: string[];
  values: number[];
}

export interface PartnerPerformance {
  partnerId: number;
  partnerName: string;
  deliveries: number;
  successRate: number;
  avgTime: number;
  rating: number;
  earnings: number;
}

export interface ZonePerformance {
  zoneId: number;
  zoneName: string;
  totalOrders: number;
  avgDeliveryTime: number;
  successRate: number;
  revenue: number;
}

export interface StatusDistribution {
  delivered: number;
  inTransit: number;
  failed: number;
  cancelled: number;
}

export interface PeakHoursData {
  hours: string[];
  orders: number[];
}

export interface RevenueData {
  labels: string[];
  revenue: number[];
  commission: number[];
}

export interface CustomerSatisfaction {
  avgRating: number;
  totalReviews: number;
  distribution: {
    5: number;
    4: number;
    3: number;
    2: number;
    1: number;
  };
}

@Injectable({
  providedIn: 'root'
})
export class DeliveryAnalyticsService {
  private readonly apiUrl = `${environment.apiUrl}/api/delivery/analytics`;

  constructor(private http: HttpClient) {}

  // Key Metrics
  getKeyMetrics(startDate: Date, endDate: Date): Observable<ApiResponse<DeliveryMetrics>> {
    const params = new HttpParams()
      .set('startDate', startDate.toISOString())
      .set('endDate', endDate.toISOString());
    
    return this.http.get<ApiResponse<DeliveryMetrics>>(`${this.apiUrl}/metrics`, { params });
  }

  // Trends
  getDeliveryTrends(startDate: Date, endDate: Date, groupBy: string = 'day'): Observable<ApiResponse<TrendData>> {
    const params = new HttpParams()
      .set('startDate', startDate.toISOString())
      .set('endDate', endDate.toISOString())
      .set('groupBy', groupBy);
    
    return this.http.get<ApiResponse<TrendData>>(`${this.apiUrl}/trends`, { params });
  }

  // Partner Analytics
  getTopPartners(limit: number = 10): Observable<ApiResponse<PartnerPerformance[]>> {
    const params = new HttpParams().set('limit', limit.toString());
    return this.http.get<ApiResponse<PartnerPerformance[]>>(`${this.apiUrl}/partners/top`, { params });
  }

  getPartnerPerformance(partnerId: number, startDate: Date, endDate: Date): Observable<ApiResponse<PartnerPerformance>> {
    const params = new HttpParams()
      .set('startDate', startDate.toISOString())
      .set('endDate', endDate.toISOString());
    
    return this.http.get<ApiResponse<PartnerPerformance>>(`${this.apiUrl}/partners/${partnerId}`, { params });
  }

  // Zone Analytics
  getZonePerformance(): Observable<ApiResponse<ZonePerformance[]>> {
    return this.http.get<ApiResponse<ZonePerformance[]>>(`${this.apiUrl}/zones`);
  }

  getZoneDetails(zoneId: number, startDate: Date, endDate: Date): Observable<ApiResponse<ZonePerformance>> {
    const params = new HttpParams()
      .set('startDate', startDate.toISOString())
      .set('endDate', endDate.toISOString());
    
    return this.http.get<ApiResponse<ZonePerformance>>(`${this.apiUrl}/zones/${zoneId}`, { params });
  }

  // Status Distribution
  getStatusDistribution(startDate: Date, endDate: Date): Observable<ApiResponse<StatusDistribution>> {
    const params = new HttpParams()
      .set('startDate', startDate.toISOString())
      .set('endDate', endDate.toISOString());
    
    return this.http.get<ApiResponse<StatusDistribution>>(`${this.apiUrl}/status-distribution`, { params });
  }

  // Peak Hours Analysis
  getPeakHours(): Observable<ApiResponse<PeakHoursData>> {
    return this.http.get<ApiResponse<PeakHoursData>>(`${this.apiUrl}/peak-hours`);
  }

  // Revenue Analytics
  getRevenueAnalytics(startDate: Date, endDate: Date): Observable<ApiResponse<RevenueData>> {
    const params = new HttpParams()
      .set('startDate', startDate.toISOString())
      .set('endDate', endDate.toISOString());
    
    return this.http.get<ApiResponse<RevenueData>>(`${this.apiUrl}/revenue`, { params });
  }

  // Customer Satisfaction
  getCustomerSatisfaction(): Observable<ApiResponse<CustomerSatisfaction>> {
    return this.http.get<ApiResponse<CustomerSatisfaction>>(`${this.apiUrl}/customer-satisfaction`);
  }

  // Vehicle Type Analytics
  getVehicleTypePerformance(): Observable<ApiResponse<any>> {
    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/vehicle-types`);
  }

  // Delivery Time Analysis
  getDeliveryTimeAnalysis(startDate: Date, endDate: Date): Observable<ApiResponse<any>> {
    const params = new HttpParams()
      .set('startDate', startDate.toISOString())
      .set('endDate', endDate.toISOString());
    
    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/delivery-times`, { params });
  }

  // Failed Delivery Analysis
  getFailedDeliveryAnalysis(startDate: Date, endDate: Date): Observable<ApiResponse<any>> {
    const params = new HttpParams()
      .set('startDate', startDate.toISOString())
      .set('endDate', endDate.toISOString());
    
    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/failed-deliveries`, { params });
  }

  // Filters
  getZones(): Observable<ApiResponse<any[]>> {
    return this.http.get<ApiResponse<any[]>>(`${this.apiUrl}/filters/zones`);
  }

  getPartners(): Observable<ApiResponse<any[]>> {
    return this.http.get<ApiResponse<any[]>>(`${this.apiUrl}/filters/partners`);
  }

  // Export
  exportReport(format: string, startDate: Date, endDate: Date): Observable<Blob> {
    const params = new HttpParams()
      .set('format', format)
      .set('startDate', startDate.toISOString())
      .set('endDate', endDate.toISOString());
    
    return this.http.get(`${this.apiUrl}/export`, {
      params,
      responseType: 'blob'
    });
  }

  // Real-time Dashboard
  getDashboardStats(): Observable<ApiResponse<any>> {
    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/dashboard`);
  }

  // Predictive Analytics
  getDemandForecast(days: number = 7): Observable<ApiResponse<any>> {
    const params = new HttpParams().set('days', days.toString());
    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/forecast`, { params });
  }

  // Partner Utilization
  getPartnerUtilization(): Observable<ApiResponse<any>> {
    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/partner-utilization`);
  }

  // Route Efficiency
  getRouteEfficiency(startDate: Date, endDate: Date): Observable<ApiResponse<any>> {
    const params = new HttpParams()
      .set('startDate', startDate.toISOString())
      .set('endDate', endDate.toISOString());
    
    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/route-efficiency`, { params });
  }

  // Mock implementations for demo (replace with actual API calls)
  private mockResponse<T>(data: T): Observable<ApiResponse<T>> {
    return new Observable(observer => {
      setTimeout(() => {
        observer.next({
          statusCode: 'SUCCESS',
          message: 'Data retrieved successfully',
          data,
          timestamp: new Date().toISOString()
        });
        observer.complete();
      }, 500);
    });
  }
}