import { Component, OnInit, OnDestroy } from '@angular/core';
import { Store } from '@ngrx/store';
import { Observable, Subject, interval } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { AppState } from '../../../../store/app.state';
import { ChartConfiguration } from 'chart.js';

@Component({
  selector: 'app-financial-dashboard',
  templateUrl: './financial-dashboard.component.html',
  styleUrls: ['./financial-dashboard.component.scss']
})
export class FinancialDashboardComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  
  // Financial Summary
  financialSummary = {
    totalRevenue: 2580000,
    totalCommission: 258000,
    totalPayouts: 2190000,
    pendingPayouts: 132000,
    refundsProcessed: 25000,
    taxCollected: 46440,
    netProfit: 180000,
    monthlyGrowth: 12.5
  };
  
  // Revenue Breakdown
  revenueBreakdown = {
    orderRevenue: 2200000,
    deliveryCharges: 180000,
    convenienceFee: 120000,
    cancellationFee: 80000
  };
  
  // Commission Structure
  commissionRates = {
    foodDelivery: 18,
    groceryDelivery: 15,
    medicineDelivery: 12,
    electronics: 8,
    fashion: 15
  };
  
  // Recent Transactions
  recentTransactions = [
    {
      id: 'TXN001',
      type: 'ORDER_PAYMENT',
      amount: 1250,
      shop: 'Saravana Bhavan',
      customer: 'Rajesh Kumar',
      timestamp: new Date(),
      status: 'COMPLETED'
    },
    {
      id: 'TXN002',
      type: 'COMMISSION',
      amount: -225,
      shop: 'Murugan Idli Shop',
      customer: null,
      timestamp: new Date(),
      status: 'PROCESSED'
    },
    {
      id: 'TXN003',
      type: 'PAYOUT',
      amount: -45000,
      shop: 'Chennai Spice Garden',
      customer: null,
      timestamp: new Date(),
      status: 'PENDING'
    }
  ];
  
  // Pending Approvals
  pendingApprovals = {
    payouts: 15,
    refunds: 8,
    adjustments: 3,
    withdrawals: 22
  };
  
  // Charts Data
  revenueChartData: ChartConfiguration['data'] = {
    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    datasets: [
      {
        data: [1800000, 2100000, 2300000, 2200000, 2450000, 2580000],
        label: 'Total Revenue',
        backgroundColor: 'rgba(255, 107, 53, 0.2)',
        borderColor: '#FF6B35',
        borderWidth: 3,
        fill: true
      },
      {
        data: [162000, 189000, 207000, 198000, 220500, 232200],
        label: 'Commission',
        backgroundColor: 'rgba(255, 215, 0, 0.2)',
        borderColor: '#FFD700',
        borderWidth: 3,
        fill: true
      }
    ]
  };
  
  categoryRevenueData: ChartConfiguration['data'] = {
    labels: ['Food Delivery', 'Grocery', 'Medicine', 'Electronics', 'Fashion'],
    datasets: [{
      data: [1800000, 480000, 180000, 120000, 80000],
      backgroundColor: [
        '#FF6B35',
        '#FFD700',
        '#006994',
        '#4CAF50',
        '#C41E3A'
      ]
    }]
  };
  
  payoutTrendData: ChartConfiguration['data'] = {
    labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
    datasets: [{
      data: [520000, 580000, 640000, 690000],
      label: 'Weekly Payouts',
      backgroundColor: '#006994'
    }]
  };
  
  profitMarginData: ChartConfiguration['data'] = {
    labels: ['Q1', 'Q2', 'Q3', 'Q4'],
    datasets: [{
      data: [6.8, 7.2, 7.8, 8.1],
      label: 'Profit Margin %',
      borderColor: '#4CAF50',
      backgroundColor: 'rgba(76, 175, 80, 0.1)',
      borderWidth: 3
    }]
  };
  
  // Chart Options
  chartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: true,
        position: 'top'
      }
    },
    scales: {
      y: {
        beginAtZero: true,
        ticks: {
          callback: function(value) {
            return '₹' + (Number(value) / 1000) + 'K';
          }
        }
      }
    }
  };
  
  constructor(private store: Store<AppState>) {}
  
  ngOnInit(): void {
    this.loadFinancialData();
    this.setupAutoRefresh();
  }
  
  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
  
  private loadFinancialData(): void {
    // Load financial metrics from store
    // this.store.dispatch(loadFinancialMetrics());
  }
  
  private setupAutoRefresh(): void {
    interval(300000) // 5 minutes
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        this.refreshData();
      });
  }
  
  refreshData(): void {
    this.loadFinancialData();
  }
  
  processApproval(type: string, id: string): void {
    console.log(`Processing ${type} approval for ${id}`);
  }
  
  exportReport(type: string): void {
    console.log(`Exporting ${type} report`);
  }
  
  viewTransactionDetails(transactionId: string): void {
    console.log(`Viewing transaction ${transactionId}`);
  }
  
  navigateToSection(section: string): void {
    console.log(`Navigating to ${section}`);
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