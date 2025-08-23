import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';
import { catchError } from 'rxjs/operators';
import { of } from 'rxjs';

export interface RevenueData {
  id: number;
  shopId: number;
  shopName: string;
  period: string;
  totalOrders: number;
  totalRevenue: number;
  commissionEarned: number;
  netRevenue: number;
  averageOrderValue: number;
  topSellingCategory: string;
  growthRate: number;
  createdAt: string;
}

export interface RevenueStats {
  totalRevenue: number;
  monthlyRevenue: number;
  totalCommission: number;
  monthlyCommission: number;
  totalOrders: number;
  monthlyOrders: number;
  averageOrderValue: number;
  revenueGrowth: number;
  topPerformingShop: string;
  topPerformingCategory: string;
}

@Component({
  selector: 'app-revenue-analytics',
  templateUrl: './revenue-analytics.component.html',
  styleUrls: ['./revenue-analytics.component.scss']
})
export class RevenueAnalyticsComponent implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = [
    'shopName',
    'period',
    'totalOrders',
    'totalRevenue',
    'commissionEarned',
    'netRevenue',
    'averageOrderValue',
    'growthRate',
    'actions'
  ];

  dataSource = new MatTableDataSource<RevenueData>();
  loading = false;
  revenueStats: RevenueStats = {
    totalRevenue: 0,
    monthlyRevenue: 0,
    totalCommission: 0,
    monthlyCommission: 0,
    totalOrders: 0,
    monthlyOrders: 0,
    averageOrderValue: 0,
    revenueGrowth: 0,
    topPerformingShop: '',
    topPerformingCategory: ''
  };

  selectedPeriod = 'monthly';
  periodOptions = [
    { value: 'daily', label: 'Daily' },
    { value: 'weekly', label: 'Weekly' },
    { value: 'monthly', label: 'Monthly' },
    { value: 'quarterly', label: 'Quarterly' },
    { value: 'yearly', label: 'Yearly' }
  ];

  searchTerm = '';
  dateRange = {
    start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
    end: new Date()
  };

  constructor(
    private http: HttpClient,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadRevenueData();
    this.loadRevenueStats();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  loadRevenueData(): void {
    this.loading = true;
    const apiUrl = `${environment.apiUrl}/financial/revenue-analytics`;
    
    this.http.get<{data: RevenueData[]}>(apiUrl).pipe(
      catchError(() => {
        this.loadMockRevenueData();
        return of(null);
      })
    ).subscribe({
      next: (response) => {
        if (response) {
          this.dataSource.data = response.data;
        }
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading revenue data:', error);
        this.loadMockRevenueData();
        this.loading = false;
      }
    });
  }

  private loadMockRevenueData(): void {
    const mockData: RevenueData[] = [
      {
        id: 1,
        shopId: 1,
        shopName: 'Annamalai Stores',
        period: 'December 2024',
        totalOrders: 145,
        totalRevenue: 87500.00,
        commissionEarned: 8750.00,
        netRevenue: 78750.00,
        averageOrderValue: 603.45,
        topSellingCategory: 'Groceries',
        growthRate: 15.2,
        createdAt: new Date().toISOString()
      },
      {
        id: 2,
        shopId: 2,
        shopName: 'Saravana Medical',
        period: 'December 2024',
        totalOrders: 89,
        totalRevenue: 45600.00,
        commissionEarned: 4560.00,
        netRevenue: 41040.00,
        averageOrderValue: 512.36,
        topSellingCategory: 'Medicines',
        growthRate: 8.7,
        createdAt: new Date().toISOString()
      },
      {
        id: 3,
        shopId: 3,
        shopName: 'Tamil Books Corner',
        period: 'December 2024',
        totalOrders: 67,
        totalRevenue: 23400.00,
        commissionEarned: 2340.00,
        netRevenue: 21060.00,
        averageOrderValue: 349.25,
        topSellingCategory: 'Books',
        growthRate: 12.3,
        createdAt: new Date().toISOString()
      },
      {
        id: 4,
        shopId: 7,
        shopName: 'Textile Paradise',
        period: 'December 2024',
        totalOrders: 112,
        totalRevenue: 156800.00,
        commissionEarned: 15680.00,
        netRevenue: 141120.00,
        averageOrderValue: 1400.00,
        topSellingCategory: 'Clothing',
        growthRate: 22.1,
        createdAt: new Date().toISOString()
      },
      {
        id: 5,
        shopId: 8,
        shopName: 'Sports Zone',
        period: 'December 2024',
        totalOrders: 78,
        totalRevenue: 98400.00,
        commissionEarned: 9840.00,
        netRevenue: 88560.00,
        averageOrderValue: 1261.54,
        topSellingCategory: 'Sports Equipment',
        growthRate: 18.9,
        createdAt: new Date().toISOString()
      },
      {
        id: 6,
        shopId: 6,
        shopName: 'Flower Garden Store',
        period: 'December 2024',
        totalOrders: 156,
        totalRevenue: 34200.00,
        commissionEarned: 3420.00,
        netRevenue: 30780.00,
        averageOrderValue: 219.23,
        topSellingCategory: 'Flowers & Gifts',
        growthRate: 25.6,
        createdAt: new Date().toISOString()
      }
    ];

    this.dataSource.data = mockData;
    this.snackBar.open('Loaded mock revenue data - API not available', 'Close', { duration: 3000 });
  }

  loadRevenueStats(): void {
    const apiUrl = `${environment.apiUrl}/financial/revenue-stats`;
    
    this.http.get<{data: RevenueStats}>(apiUrl).pipe(
      catchError(() => {
        this.loadMockRevenueStats();
        return of(null);
      })
    ).subscribe({
      next: (response) => {
        if (response) {
          this.revenueStats = response.data;
        }
      },
      error: (error) => {
        console.error('Error loading revenue stats:', error);
        this.loadMockRevenueStats();
      }
    });
  }

  private loadMockRevenueStats(): void {
    this.revenueStats = {
      totalRevenue: 445900.00,
      monthlyRevenue: 445900.00,
      totalCommission: 44590.00,
      monthlyCommission: 44590.00,
      totalOrders: 647,
      monthlyOrders: 647,
      averageOrderValue: 689.21,
      revenueGrowth: 17.2,
      topPerformingShop: 'Textile Paradise',
      topPerformingCategory: 'Clothing'
    };
  }

  applyFilter(): void {
    const filterValue = this.searchTerm.trim().toLowerCase();
    this.dataSource.filter = filterValue;
  }

  onPeriodChange(): void {
    this.loadRevenueData();
    this.loadRevenueStats();
  }

  onDateRangeChange(): void {
    this.loadRevenueData();
    this.loadRevenueStats();
  }

  exportData(): void {
    const csvData = this.dataSource.data.map(item => ({
      'Shop Name': item.shopName,
      'Period': item.period,
      'Total Orders': item.totalOrders,
      'Total Revenue': item.totalRevenue,
      'Commission Earned': item.commissionEarned,
      'Net Revenue': item.netRevenue,
      'Average Order Value': item.averageOrderValue,
      'Growth Rate': item.growthRate + '%'
    }));

    const csv = this.convertToCSV(csvData);
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `revenue-analytics-${new Date().toISOString().split('T')[0]}.csv`;
    link.click();
    window.URL.revokeObjectURL(url);
    
    this.snackBar.open('Revenue data exported successfully', 'Close', { duration: 3000 });
  }

  private convertToCSV(data: any[]): string {
    if (data.length === 0) return '';
    
    const headers = Object.keys(data[0]);
    const csvHeaders = headers.join(',');
    const csvRows = data.map(row => 
      headers.map(header => {
        const value = row[header];
        return typeof value === 'string' && value.includes(',') ? `"${value}"` : value;
      }).join(',')
    );
    
    return [csvHeaders, ...csvRows].join('\n');
  }

  viewShopDetails(revenue: RevenueData): void {
    this.snackBar.open(`Viewing details for ${revenue.shopName}`, 'Close', { duration: 2000 });
  }

  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR'
    }).format(amount);
  }

  formatPercentage(value: number): string {
    return `${value.toFixed(1)}%`;
  }
}