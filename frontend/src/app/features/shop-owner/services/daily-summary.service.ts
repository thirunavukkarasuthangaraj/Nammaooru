import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';
import { EmailService, DailySummaryData } from '../../../core/services/email.service';
import { NotificationOrchestratorService } from '../../../core/services/notification-orchestrator.service';

export interface ShopDailyStats {
  date: string;
  totalOrders: number;
  completedOrders: number;
  cancelledOrders: number;
  pendingOrders: number;
  totalRevenue: number;
  totalCost: number;
  totalProfit: number;
  profitMargin: number;
  averageOrderValue: number;
  peakHours: string;
  topSellingItems: Array<{
    productId: number;
    name: string;
    quantity: number;
    revenue: number;
    profit: number;
  }>;
  orderDetails: Array<{
    orderId: number;
    orderNumber: string;
    customerName: string;
    items: string;
    total: number;
    profit: number;
    status: string;
    time: string;
  }>;
  costBreakdown: {
    productCost: number;
    deliveryFees: number;
    platformFees: number;
    packagingCost: number;
    otherCosts: number;
  };
}

@Injectable({
  providedIn: 'root'
})
export class DailySummaryService {
  private apiUrl = `${environment.apiUrl}/shop-owner`;

  constructor(
    private http: HttpClient,
    private emailService: EmailService,
    private notificationService: NotificationOrchestratorService
  ) {}

  // Get daily statistics for a shop
  getDailyStats(shopId: number, date?: string): Observable<ShopDailyStats> {
    const targetDate = date || new Date().toISOString().split('T')[0];
    
    return this.http.get<ShopDailyStats>(`${this.apiUrl}/shops/${shopId}/daily-stats`, {
      params: { date: targetDate }
    }).pipe(
      catchError(() => {
        // Return mock data if API fails
        return of(this.getMockDailyStats(shopId, targetDate));
      })
    );
  }

  // Calculate profit for a shop
  calculateProfit(shopId: number, startDate: string, endDate: string): Observable<any> {
    return this.http.get(`${this.apiUrl}/shops/${shopId}/profit-analysis`, {
      params: { startDate, endDate }
    }).pipe(
      map(data => this.enhanceProfitData(data)),
      catchError(() => {
        return of(this.getMockProfitAnalysis());
      })
    );
  }

  // Send daily summary email to shop owner
  sendDailySummary(shopId: number, shopOwnerEmail: string): Observable<boolean> {
    return this.getDailyStats(shopId).pipe(
      map(stats => {
        const summaryData: DailySummaryData = {
          shopId: shopId,
          shopName: this.getShopName(shopId),
          shopOwnerEmail: shopOwnerEmail,
          date: new Date().toLocaleDateString('en-IN'),
          totalOrders: stats.totalOrders,
          completedOrders: stats.completedOrders,
          cancelledOrders: stats.cancelledOrders,
          pendingOrders: stats.pendingOrders,
          totalRevenue: stats.totalRevenue,
          totalCost: stats.totalCost,
          totalProfit: stats.totalProfit,
          profitMargin: stats.profitMargin,
          topSellingItems: stats.topSellingItems,
          orderDetails: stats.orderDetails,
          averageOrderValue: stats.averageOrderValue,
          peakHours: stats.peakHours
        };
        
        return summaryData;
      }),
      catchError(() => of(this.getMockSummaryData(shopId, shopOwnerEmail))),
      map(summaryData => {
        // Send via notification orchestrator
        this.notificationService.handleNotification({
          type: 'DAILY_SUMMARY',
          recipients: {
            shopOwner: {
              email: shopOwnerEmail,
              name: summaryData.shopName
            }
          },
          data: summaryData
        }).subscribe();
        
        return true;
      })
    );
  }

  // Generate profit report
  generateProfitReport(shopId: number, period: 'daily' | 'weekly' | 'monthly'): Observable<any> {
    const endDate = new Date();
    let startDate = new Date();
    
    switch(period) {
      case 'daily':
        startDate.setDate(endDate.getDate() - 1);
        break;
      case 'weekly':
        startDate.setDate(endDate.getDate() - 7);
        break;
      case 'monthly':
        startDate.setMonth(endDate.getMonth() - 1);
        break;
    }
    
    return this.calculateProfit(
      shopId,
      startDate.toISOString().split('T')[0],
      endDate.toISOString().split('T')[0]
    );
  }

  // Get real-time profit tracking
  getRealTimeProfit(shopId: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/shops/${shopId}/realtime-profit`).pipe(
      catchError(() => {
        return of({
          currentProfit: 2500,
          projectedProfit: 5000,
          profitTrend: 'increasing',
          lastHourProfit: 350,
          topProfitableItem: 'Chicken Biryani'
        });
      })
    );
  }

  // Helper methods
  private enhanceProfitData(data: any): any {
    return {
      ...data,
      profitMargin: ((data.totalProfit / data.totalRevenue) * 100).toFixed(2),
      averageOrderProfit: (data.totalProfit / data.totalOrders).toFixed(2),
      profitPerItem: data.items?.map((item: any) => ({
        ...item,
        profitMargin: ((item.profit / item.revenue) * 100).toFixed(2)
      }))
    };
  }

  private getShopName(shopId: number): string {
    // This should be fetched from auth or shop service
    return `Shop ${shopId}`;
  }

  private getMockDailyStats(shopId: number, date: string): ShopDailyStats {
    return {
      date: date,
      totalOrders: 45,
      completedOrders: 42,
      cancelledOrders: 2,
      pendingOrders: 1,
      totalRevenue: 25000,
      totalCost: 17500,
      totalProfit: 7500,
      profitMargin: 30,
      averageOrderValue: 556,
      peakHours: '12:00 PM - 2:00 PM, 7:00 PM - 9:00 PM',
      topSellingItems: [
        { productId: 1, name: 'Chicken Biryani', quantity: 25, revenue: 6250, profit: 2187 },
        { productId: 2, name: 'Mutton Curry', quantity: 15, revenue: 4800, profit: 1680 },
        { productId: 3, name: 'Veg Biryani', quantity: 20, revenue: 4000, profit: 1600 },
        { productId: 4, name: 'Fish Curry', quantity: 10, revenue: 2800, profit: 980 },
        { productId: 5, name: 'Chicken 65', quantity: 18, revenue: 2700, profit: 945 }
      ],
      orderDetails: [
        {
          orderId: 101,
          orderNumber: 'ORD001',
          customerName: 'John Doe',
          items: '2x Chicken Biryani, 1x Raita',
          total: 550,
          profit: 192,
          status: 'DELIVERED',
          time: '12:30 PM'
        },
        {
          orderId: 102,
          orderNumber: 'ORD002',
          customerName: 'Jane Smith',
          items: '1x Mutton Curry, 2x Naan',
          total: 420,
          profit: 147,
          status: 'DELIVERED',
          time: '1:15 PM'
        }
      ],
      costBreakdown: {
        productCost: 12000,
        deliveryFees: 2000,
        platformFees: 2500,
        packagingCost: 800,
        otherCosts: 200
      }
    };
  }

  private getMockProfitAnalysis(): any {
    return {
      totalRevenue: 150000,
      totalCost: 105000,
      totalProfit: 45000,
      totalOrders: 300,
      profitMargin: 30,
      averageOrderProfit: 150,
      profitTrend: {
        daily: [5000, 4500, 6000, 5500, 7000, 6500, 7500],
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
      },
      topProfitableItems: [
        { name: 'Chicken Biryani', profit: 15000, margin: 35 },
        { name: 'Mutton Curry', profit: 10000, margin: 32 },
        { name: 'Fish Curry', profit: 8000, margin: 30 }
      ]
    };
  }

  private getMockSummaryData(shopId: number, email: string): DailySummaryData {
    const stats = this.getMockDailyStats(shopId, new Date().toISOString().split('T')[0]);
    return {
      shopId: shopId,
      shopName: `Shop ${shopId}`,
      shopOwnerEmail: email,
      date: new Date().toLocaleDateString('en-IN'),
      totalOrders: stats.totalOrders,
      completedOrders: stats.completedOrders,
      cancelledOrders: stats.cancelledOrders,
      pendingOrders: stats.pendingOrders,
      totalRevenue: stats.totalRevenue,
      totalCost: stats.totalCost,
      totalProfit: stats.totalProfit,
      profitMargin: stats.profitMargin,
      topSellingItems: stats.topSellingItems,
      orderDetails: stats.orderDetails,
      averageOrderValue: stats.averageOrderValue,
      peakHours: stats.peakHours
    };
  }
}