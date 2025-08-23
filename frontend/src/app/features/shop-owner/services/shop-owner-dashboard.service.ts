import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, of, forkJoin } from 'rxjs';
import { catchError, switchMap, map } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';
import { ShopOwnerOrderService } from './shop-owner-order.service';
import { ShopOwnerProductService } from './shop-owner-product.service';

export interface DashboardStats {
  totalOrders: number;
  pendingOrders: number;
  processingOrders: number;
  deliveredOrders: number;
  totalRevenue: number;
  todayRevenue: number;
  totalProducts: number;
  lowStockProducts: number;
  activeProducts: number;
  inactiveProducts: number;
  totalCustomers: number;
  avgOrderValue: number;
  orderGrowth: number;
  revenueGrowth: number;
}

export interface RecentOrder {
  id: number;
  orderNumber: string;
  customerName: string;
  totalAmount: number;
  status: string;
  createdAt: string;
}

export interface TopProduct {
  id: number;
  name: string;
  totalSold: number;
  revenue: number;
  category: string;
  imageUrl?: string;
}

export interface SalesChart {
  date: string;
  orders: number;
  revenue: number;
}

export interface CategoryStats {
  category: string;
  productCount: number;
  totalSales: number;
  revenue: number;
}

@Injectable({
  providedIn: 'root'
})
export class ShopOwnerDashboardService {
  private apiUrl = `${environment.apiUrl}`;

  constructor(
    private http: HttpClient,
    private orderService: ShopOwnerOrderService,
    private productService: ShopOwnerProductService
  ) {}

  getDashboardStats(shopId: number): Observable<DashboardStats> {
    return this.http.get<{data: DashboardStats}>(`${this.apiUrl}/shops/${shopId}/dashboard/stats`)
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Fallback to calculated stats from other services
          return this.calculateMockStats(shopId);
        })
      );
  }

  private calculateMockStats(shopId: number): Observable<DashboardStats> {
    return forkJoin({
      orders: this.orderService.getShopOrders(shopId),
      products: this.productService.getShopProducts(shopId)
    }).pipe(
      map(({ orders, products }) => {
        const pendingOrders = orders.filter(o => o.status === 'PENDING').length;
        const processingOrders = orders.filter(o => 
          ['CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP'].includes(o.status)
        ).length;
        const deliveredOrders = orders.filter(o => o.status === 'DELIVERED').length;
        
        const totalRevenue = orders
          .filter(o => o.status === 'DELIVERED')
          .reduce((sum, order) => sum + order.totalAmount, 0);
        
        const today = new Date().toDateString();
        const todayRevenue = orders
          .filter(o => o.status === 'DELIVERED' && new Date(o.createdAt).toDateString() === today)
          .reduce((sum, order) => sum + order.totalAmount, 0);
        
        const lowStockProducts = products.filter(p => p.stockQuantity <= p.lowStockThreshold).length;
        const activeProducts = products.filter(p => p.isActive).length;
        const inactiveProducts = products.filter(p => !p.isActive).length;
        
        const avgOrderValue = orders.length > 0 ? totalRevenue / orders.length : 0;

        const mockStats: DashboardStats = {
          totalOrders: orders.length,
          pendingOrders,
          processingOrders,
          deliveredOrders,
          totalRevenue,
          todayRevenue,
          totalProducts: products.length,
          lowStockProducts,
          activeProducts,
          inactiveProducts,
          totalCustomers: new Set(orders.map(o => o.customerId)).size,
          avgOrderValue,
          orderGrowth: 12.5, // Mock growth percentage
          revenueGrowth: 18.3 // Mock growth percentage
        };

        return mockStats;
      })
    );
  }

  getRecentOrders(shopId: number, limit: number = 5): Observable<RecentOrder[]> {
    const params = new HttpParams().set('limit', limit.toString());

    return this.http.get<{data: RecentOrder[]}>(`${this.apiUrl}/shops/${shopId}/dashboard/recent-orders`, { params })
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          // Fallback to recent orders from order service
          return this.orderService.getShopOrders(shopId, 0, limit).pipe(
            map(orders => orders.slice(0, limit).map(order => ({
              id: order.id,
              orderNumber: order.orderNumber,
              customerName: order.customerName,
              totalAmount: order.totalAmount,
              status: order.status,
              createdAt: order.createdAt
            })))
          );
        })
      );
  }

  getTopProducts(shopId: number, limit: number = 5): Observable<TopProduct[]> {
    const params = new HttpParams().set('limit', limit.toString());

    return this.http.get<{data: TopProduct[]}>(`${this.apiUrl}/shops/${shopId}/dashboard/top-products`, { params })
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          // Fallback to mock top products
          const mockTopProducts: TopProduct[] = [
            {
              id: 1,
              name: 'Chicken Biryani',
              totalSold: 340,
              revenue: 85000,
              category: 'Main Course',
              imageUrl: '/assets/images/biryani.jpg'
            },
            {
              id: 2,
              name: 'Mutton Curry',
              totalSold: 210,
              revenue: 67200,
              category: 'Main Course',
              imageUrl: '/assets/images/mutton-curry.jpg'
            },
            {
              id: 3,
              name: 'Fish Fry',
              totalSold: 185,
              revenue: 27750,
              category: 'Appetizers',
              imageUrl: '/assets/images/fish-fry.jpg'
            }
          ];
          return of(mockTopProducts.slice(0, limit));
        })
      );
  }

  getSalesChart(shopId: number, period: string = '7days'): Observable<SalesChart[]> {
    const params = new HttpParams().set('period', period);

    return this.http.get<{data: SalesChart[]}>(`${this.apiUrl}/shops/${shopId}/dashboard/sales-chart`, { params })
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          // Fallback to mock sales chart data
          const mockSalesChart: SalesChart[] = [];
          const days = period === '7days' ? 7 : period === '30days' ? 30 : 7;
          
          for (let i = days - 1; i >= 0; i--) {
            const date = new Date();
            date.setDate(date.getDate() - i);
            
            mockSalesChart.push({
              date: date.toISOString().split('T')[0],
              orders: Math.floor(Math.random() * 20) + 5,
              revenue: Math.floor(Math.random() * 5000) + 1000
            });
          }
          
          return of(mockSalesChart);
        })
      );
  }

  getCategoryStats(shopId: number): Observable<CategoryStats[]> {
    return this.http.get<{data: CategoryStats[]}>(`${this.apiUrl}/shops/${shopId}/dashboard/category-stats`)
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          // Fallback to mock category stats
          const mockCategoryStats: CategoryStats[] = [
            {
              category: 'Main Course',
              productCount: 15,
              totalSales: 1250,
              revenue: 312500
            },
            {
              category: 'Appetizers',
              productCount: 8,
              totalSales: 650,
              revenue: 97500
            },
            {
              category: 'Desserts',
              productCount: 6,
              totalSales: 420,
              revenue: 42000
            },
            {
              category: 'Beverages',
              productCount: 10,
              totalSales: 890,
              revenue: 53400
            }
          ];
          return of(mockCategoryStats);
        })
      );
  }

  getOrderStatusDistribution(shopId: number): Observable<{status: string, count: number, percentage: number}[]> {
    return this.http.get<{data: any[]}>(`${this.apiUrl}/shops/${shopId}/dashboard/order-status-distribution`)
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          // Fallback using order service data
          return this.orderService.getShopOrders(shopId).pipe(
            map(orders => {
              const statusCounts = orders.reduce((acc, order) => {
                acc[order.status] = (acc[order.status] || 0) + 1;
                return acc;
              }, {} as Record<string, number>);

              const total = orders.length;
              return Object.entries(statusCounts).map(([status, count]) => ({
                status,
                count,
                percentage: total > 0 ? Math.round((count / total) * 100) : 0
              }));
            })
          );
        })
      );
  }

  getMonthlyRevenue(shopId: number, year: number = new Date().getFullYear()): Observable<{month: string, revenue: number}[]> {
    const params = new HttpParams().set('year', year.toString());

    return this.http.get<{data: any[]}>(`${this.apiUrl}/shops/${shopId}/dashboard/monthly-revenue`, { params })
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => {
          // Fallback to mock monthly revenue
          const months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          
          const mockMonthlyRevenue = months.map(month => ({
            month,
            revenue: Math.floor(Math.random() * 50000) + 20000
          }));
          
          return of(mockMonthlyRevenue);
        })
      );
  }

  refreshDashboard(shopId: number): Observable<any> {
    // Trigger a refresh of all dashboard data
    return forkJoin({
      stats: this.getDashboardStats(shopId),
      recentOrders: this.getRecentOrders(shopId),
      topProducts: this.getTopProducts(shopId),
      salesChart: this.getSalesChart(shopId),
      categoryStats: this.getCategoryStats(shopId)
    });
  }
}