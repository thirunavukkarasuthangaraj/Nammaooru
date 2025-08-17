import { Component, OnInit, ViewChild, OnDestroy } from '@angular/core';
import { Subject, takeUntil } from 'rxjs';
import { MatSnackBar } from '@angular/material/snack-bar';
import { DeliveryAnalyticsService } from '../../services/delivery-analytics.service';
import { ApiResponseHelper } from '../../../../core/models/api-response.model';
import { ChartConfiguration, ChartType } from 'chart.js';
import { BaseChartDirective } from 'ng2-charts';

@Component({
  selector: 'app-delivery-analytics',
  templateUrl: './delivery-analytics.component.html',
  styleUrls: ['./delivery-analytics.component.scss']
})
export class DeliveryAnalyticsComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  
  @ViewChild(BaseChartDirective) chart?: BaseChartDirective;

  // Date Range
  startDate: Date = new Date(new Date().setDate(new Date().getDate() - 30));
  endDate: Date = new Date();
  selectedPeriod = '30days';

  // Loading state
  isLoading = true;

  // Key Metrics
  metrics = {
    totalDeliveries: 0,
    successRate: 0,
    avgDeliveryTime: 0,
    totalRevenue: 0,
    activePartners: 0,
    avgRating: 0,
    onTimeDeliveryRate: 0,
    totalDistance: 0
  };

  // Chart Data
  deliveryTrendChartData: ChartConfiguration<'line'>['data'] = {
    labels: [],
    datasets: [{
      data: [],
      label: 'Deliveries',
      borderColor: '#667eea',
      backgroundColor: 'rgba(102, 126, 234, 0.1)',
      tension: 0.4
    }]
  };

  deliveryTrendChartOptions: ChartConfiguration<'line'>['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: true },
      tooltip: { 
        callbacks: {
          label: (context) => `Deliveries: ${context.parsed.y}`
        }
      }
    },
    scales: {
      y: { beginAtZero: true }
    }
  };

  // Partner Performance Data
  partnerPerformanceData: any[] = [];
  partnerColumns = ['rank', 'partnerName', 'deliveries', 'successRate', 'avgTime', 'rating', 'earnings'];

  // Zone Performance Data
  zonePerformanceData: any[] = [];
  
  // Delivery Status Distribution
  statusDistributionData: ChartConfiguration<'doughnut'>['data'] = {
    labels: ['Delivered', 'In Transit', 'Failed', 'Cancelled'],
    datasets: [{
      data: [],
      backgroundColor: ['#4CAF50', '#2196F3', '#f44336', '#FF9800']
    }]
  };

  // Peak Hours Chart
  peakHoursChartData: ChartConfiguration<'bar'>['data'] = {
    labels: [],
    datasets: [{
      data: [],
      label: 'Orders',
      backgroundColor: '#667eea'
    }]
  };

  // Revenue Chart
  revenueChartData: ChartConfiguration<'line'>['data'] = {
    labels: [],
    datasets: [
      {
        data: [],
        label: 'Revenue',
        borderColor: '#4CAF50',
        backgroundColor: 'rgba(76, 175, 80, 0.1)',
        tension: 0.4
      },
      {
        data: [],
        label: 'Commission',
        borderColor: '#FF9800',
        backgroundColor: 'rgba(255, 152, 0, 0.1)',
        tension: 0.4
      }
    ]
  };

  // Customer Satisfaction
  satisfactionData = {
    avgRating: 0,
    totalReviews: 0,
    distribution: {
      5: 0,
      4: 0,
      3: 0,
      2: 0,
      1: 0
    }
  };

  // Filters
  selectedZone = 'all';
  selectedPartner = 'all';
  selectedVehicleType = 'all';
  
  zones: any[] = [];
  partners: any[] = [];
  vehicleTypes = ['BIKE', 'SCOOTER', 'BICYCLE', 'CAR', 'AUTO'];

  constructor(
    private analyticsService: DeliveryAnalyticsService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadAnalytics();
    this.loadFilters();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadAnalytics(): void {
    this.isLoading = true;
    
    // Load all analytics data
    Promise.all([
      this.loadKeyMetrics(),
      this.loadDeliveryTrends(),
      this.loadPartnerPerformance(),
      this.loadZonePerformance(),
      this.loadStatusDistribution(),
      this.loadPeakHours(),
      this.loadRevenueData(),
      this.loadCustomerSatisfaction()
    ]).then(() => {
      this.isLoading = false;
    }).catch(error => {
      console.error('Error loading analytics:', error);
      this.snackBar.open('Failed to load analytics', 'Close', { duration: 3000 });
      this.isLoading = false;
    });
  }

  private loadKeyMetrics(): Promise<void> {
    return new Promise((resolve) => {
      this.analyticsService.getKeyMetrics(this.startDate, this.endDate)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (response) => {
            if (ApiResponseHelper.isSuccess(response) && response.data) {
              this.metrics = response.data;
            }
            resolve();
          },
          error: () => resolve()
        });
    });
  }

  private loadDeliveryTrends(): Promise<void> {
    return new Promise((resolve) => {
      this.analyticsService.getDeliveryTrends(this.startDate, this.endDate)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (response) => {
            if (ApiResponseHelper.isSuccess(response) && response.data) {
              this.deliveryTrendChartData.labels = response.data.labels;
              this.deliveryTrendChartData.datasets[0].data = response.data.values;
              this.chart?.update();
            }
            resolve();
          },
          error: () => resolve()
        });
    });
  }

  private loadPartnerPerformance(): Promise<void> {
    return new Promise((resolve) => {
      this.analyticsService.getTopPartners(10)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (response) => {
            if (ApiResponseHelper.isSuccess(response) && response.data) {
              this.partnerPerformanceData = response.data.map((p: any, index: number) => ({
                ...p,
                rank: index + 1
              }));
            }
            resolve();
          },
          error: () => resolve()
        });
    });
  }

  private loadZonePerformance(): Promise<void> {
    return new Promise((resolve) => {
      this.analyticsService.getZonePerformance()
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (response) => {
            if (ApiResponseHelper.isSuccess(response) && response.data) {
              this.zonePerformanceData = response.data;
            }
            resolve();
          },
          error: () => resolve()
        });
    });
  }

  private loadStatusDistribution(): Promise<void> {
    return new Promise((resolve) => {
      this.analyticsService.getStatusDistribution(this.startDate, this.endDate)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (response) => {
            if (ApiResponseHelper.isSuccess(response) && response.data) {
              this.statusDistributionData.datasets[0].data = [
                response.data.delivered,
                response.data.inTransit,
                response.data.failed,
                response.data.cancelled
              ];
            }
            resolve();
          },
          error: () => resolve()
        });
    });
  }

  private loadPeakHours(): Promise<void> {
    return new Promise((resolve) => {
      this.analyticsService.getPeakHours()
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (response) => {
            if (ApiResponseHelper.isSuccess(response) && response.data) {
              this.peakHoursChartData.labels = response.data.hours;
              this.peakHoursChartData.datasets[0].data = response.data.orders;
            }
            resolve();
          },
          error: () => resolve()
        });
    });
  }

  private loadRevenueData(): Promise<void> {
    return new Promise((resolve) => {
      this.analyticsService.getRevenueAnalytics(this.startDate, this.endDate)
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (response) => {
            if (ApiResponseHelper.isSuccess(response) && response.data) {
              this.revenueChartData.labels = response.data.labels;
              this.revenueChartData.datasets[0].data = response.data.revenue;
              this.revenueChartData.datasets[1].data = response.data.commission;
            }
            resolve();
          },
          error: () => resolve()
        });
    });
  }

  private loadCustomerSatisfaction(): Promise<void> {
    return new Promise((resolve) => {
      this.analyticsService.getCustomerSatisfaction()
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (response) => {
            if (ApiResponseHelper.isSuccess(response) && response.data) {
              this.satisfactionData = response.data;
            }
            resolve();
          },
          error: () => resolve()
        });
    });
  }

  private loadFilters(): void {
    // Load zones
    this.analyticsService.getZones()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response)) {
            this.zones = response.data;
          }
        }
      });

    // Load partners
    this.analyticsService.getPartners()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (ApiResponseHelper.isSuccess(response)) {
            this.partners = response.data;
          }
        }
      });
  }

  onPeriodChange(): void {
    const now = new Date();
    
    switch (this.selectedPeriod) {
      case '7days':
        this.startDate = new Date(now.setDate(now.getDate() - 7));
        break;
      case '30days':
        this.startDate = new Date(now.setDate(now.getDate() - 30));
        break;
      case '90days':
        this.startDate = new Date(now.setDate(now.getDate() - 90));
        break;
      case 'custom':
        // Keep current selection
        break;
    }
    
    this.loadAnalytics();
  }

  onDateRangeChange(): void {
    if (this.startDate && this.endDate) {
      this.selectedPeriod = 'custom';
      this.loadAnalytics();
    }
  }

  onFilterChange(): void {
    this.loadAnalytics();
  }

  exportReport(format: string): void {
    this.analyticsService.exportReport(format, this.startDate, this.endDate)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (blob) => {
          const url = window.URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = `delivery-analytics-${new Date().toISOString().split('T')[0]}.${format}`;
          a.click();
          window.URL.revokeObjectURL(url);
          
          this.snackBar.open('Report exported successfully', 'Close', { duration: 3000 });
        },
        error: (error) => {
          console.error('Error exporting report:', error);
          this.snackBar.open('Failed to export report', 'Close', { duration: 3000 });
        }
      });
  }

  refreshData(): void {
    this.loadAnalytics();
  }

  formatCurrency(value: number): string {
    return `₹${value.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  }

  formatPercentage(value: number): string {
    return `${value.toFixed(1)}%`;
  }

  formatTime(minutes: number): string {
    if (minutes < 60) {
      return `${Math.round(minutes)} mins`;
    }
    const hours = Math.floor(minutes / 60);
    const mins = Math.round(minutes % 60);
    return `${hours}h ${mins}m`;
  }

  formatDistance(km: number): string {
    return `${km.toFixed(1)} km`;
  }

  getRatingStars(rating: number): string[] {
    const fullStars = Math.floor(rating);
    const hasHalfStar = rating % 1 >= 0.5;
    const stars = [];
    
    for (let i = 0; i < fullStars; i++) {
      stars.push('star');
    }
    
    if (hasHalfStar && stars.length < 5) {
      stars.push('star_half');
    }
    
    while (stars.length < 5) {
      stars.push('star_border');
    }
    
    return stars;
  }

  getMetricIcon(metric: string): string {
    switch (metric) {
      case 'deliveries': return 'local_shipping';
      case 'success': return 'check_circle';
      case 'time': return 'schedule';
      case 'revenue': return 'currency_rupee';
      case 'partners': return 'group';
      case 'rating': return 'star';
      case 'ontime': return 'timer';
      case 'distance': return 'navigation';
      default: return 'analytics';
    }
  }

  getMetricColor(metric: string): string {
    switch (metric) {
      case 'deliveries': return 'primary';
      case 'success': return 'accent';
      case 'revenue': return 'primary';
      case 'rating': return 'accent';
      default: return 'basic';
    }
  }
}