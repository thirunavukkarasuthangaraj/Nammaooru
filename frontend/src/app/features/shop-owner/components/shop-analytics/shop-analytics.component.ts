import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatNativeDateModule } from '@angular/material/core';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTableModule } from '@angular/material/table';
import { MatChipsModule } from '@angular/material/chips';
import { MatTooltipModule } from '@angular/material/tooltip';

interface MetricCard {
  title: string;
  value: string | number;
  icon: string;
  trend: number;
  trendLabel: string;
  colorClass: string;
}

interface TopProduct {
  name: string;
  category: string;
  revenue: number;
  orders: number;
  trend: number;
}

interface RecentOrder {
  id: string;
  customerName: string;
  items: number;
  amount: number;
  status: string;
  date: Date;
}

@Component({
  selector: 'app-shop-analytics',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatIconModule,
    MatButtonModule,
    MatDatepickerModule,
    MatFormFieldModule,
    MatInputModule,
    MatNativeDateModule,
    MatProgressSpinnerModule,
    MatTableModule,
    MatChipsModule,
    MatTooltipModule
  ],
  templateUrl: './shop-analytics.component.html',
  styleUrls: ['./shop-analytics.component.scss']
})
export class ShopAnalyticsComponent implements OnInit {
  isLoading = false;
  dateRange = {
    start: new Date(new Date().setDate(new Date().getDate() - 30)),
    end: new Date()
  };

  metrics: MetricCard[] = [
    {
      title: 'Total Revenue',
      value: '₹45,280',
      icon: 'attach_money',
      trend: 12.5,
      trendLabel: 'from delivered orders',
      colorClass: 'revenue'
    },
    {
      title: 'Total Received',
      value: '₹38,450',
      icon: 'account_balance_wallet',
      trend: 10.8,
      trendLabel: 'paid orders only',
      colorClass: 'received'
    },
    {
      title: "Today's Orders",
      value: 28,
      icon: 'today',
      trend: 18.5,
      trendLabel: 'vs yesterday',
      colorClass: 'today-orders'
    },
    {
      title: 'Total Orders',
      value: 342,
      icon: 'shopping_cart',
      trend: 8.2,
      trendLabel: 'this month',
      colorClass: 'orders'
    },
    {
      title: 'Paid Orders',
      value: 298,
      icon: 'payment',
      trend: 7.5,
      trendLabel: 'payment completed',
      colorClass: 'paid'
    },
    {
      title: 'Cancelled Orders',
      value: 12,
      icon: 'cancel',
      trend: -5.2,
      trendLabel: 'down from last month',
      colorClass: 'cancelled'
    },
    {
      title: 'Total Refunds',
      value: '₹3,240',
      icon: 'money_off',
      trend: -15.3,
      trendLabel: 'down from last month',
      colorClass: 'refunds'
    },
    {
      title: 'Avg Order Value',
      value: '₹132',
      icon: 'trending_up',
      trend: 5.7,
      trendLabel: 'vs last month',
      colorClass: 'avg-order'
    }
  ];

  topProducts: TopProduct[] = [
    {
      name: 'Basmati Rice (5kg)',
      category: 'Grains & Cereals',
      revenue: 12500,
      orders: 85,
      trend: 15.2
    },
    {
      name: 'Coconut Oil (1L)',
      category: 'Cooking Oils',
      revenue: 8900,
      orders: 62,
      trend: 8.5
    },
    {
      name: 'Atta Flour (10kg)',
      category: 'Flours',
      revenue: 7600,
      orders: 48,
      trend: -2.3
    },
    {
      name: 'Toor Dal (1kg)',
      category: 'Pulses',
      revenue: 6800,
      orders: 54,
      trend: 12.7
    },
    {
      name: 'Idli Rice (5kg)',
      category: 'Grains',
      revenue: 5200,
      orders: 38,
      trend: 6.4
    }
  ];

  recentOrders: RecentOrder[] = [
    {
      id: 'ORD-2025-001',
      customerName: 'Priya Sharma',
      items: 8,
      amount: 1240,
      status: 'Delivered',
      date: new Date()
    },
    {
      id: 'ORD-2025-002',
      customerName: 'Rajesh Kumar',
      items: 5,
      amount: 850,
      status: 'In Transit',
      date: new Date()
    },
    {
      id: 'ORD-2025-003',
      customerName: 'Lakshmi Devi',
      items: 12,
      amount: 1890,
      status: 'Processing',
      date: new Date()
    },
    {
      id: 'ORD-2025-004',
      customerName: 'Venkat Raman',
      items: 6,
      amount: 740,
      status: 'Delivered',
      date: new Date()
    },
    {
      id: 'ORD-2025-005',
      customerName: 'Meena Bala',
      items: 9,
      amount: 1320,
      status: 'Delivered',
      date: new Date()
    }
  ];

  orderColumns: string[] = ['orderId', 'customer', 'items', 'amount', 'status', 'date'];

  ngOnInit(): void {
    this.loadAnalytics();
  }

  loadAnalytics(): void {
    this.isLoading = true;
    // Simulate API call
    setTimeout(() => {
      this.isLoading = false;
    }, 1000);
  }

  refreshData(): void {
    this.loadAnalytics();
  }

  exportReport(): void {
    console.log('Exporting report...');
    // Implement export functionality
  }

  getStatusClass(status: string): string {
    const statusMap: { [key: string]: string } = {
      'Delivered': 'status-delivered',
      'In Transit': 'status-transit',
      'Processing': 'status-processing',
      'Cancelled': 'status-cancelled'
    };
    return statusMap[status] || '';
  }

  formatCurrency(amount: number): string {
    return `₹${amount.toLocaleString('en-IN')}`;
  }

  formatDate(date: Date): string {
    return new Intl.DateTimeFormat('en-IN', {
      day: '2-digit',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit'
    }).format(date);
  }

  // ===== CLICK HANDLERS FOR DETAILED VIEWS =====

  viewMetricDetails(metric: MetricCard): void {
    // Import Swal at the top if not already imported
    import('sweetalert2').then((Swal) => {
      let detailsHtml = '';

      switch(metric.title) {
        case 'Total Revenue':
          detailsHtml = `
            <div style="text-align: left; padding: 1rem;">
              <h3 style="color: #48bb78; margin-bottom: 1rem;">💰 Revenue Breakdown</h3>
              <div style="background: #f7fafc; padding: 1rem; border-radius: 8px; margin-bottom: 1rem;">
                <p><strong>Total Revenue:</strong> ${metric.value}</p>
                <p><strong>From Delivered Orders:</strong> 298 orders</p>
                <p><strong>Average per Order:</strong> ₹152</p>
              </div>
              <h4>Revenue by Category</h4>
              <ul style="list-style: none; padding: 0;">
                <li style="margin: 0.5rem 0;">🌾 Grains & Cereals: ₹18,500 (41%)</li>
                <li style="margin: 0.5rem 0;">🥬 Vegetables: ₹12,300 (27%)</li>
                <li style="margin: 0.5rem 0;">🧈 Cooking Oils: ₹8,900 (20%)</li>
                <li style="margin: 0.5rem 0;">🫘 Pulses: ₹5,580 (12%)</li>
              </ul>
            </div>
          `;
          break;

        case 'Total Received':
          detailsHtml = `
            <div style="text-align: left; padding: 1rem;">
              <h3 style="color: #38b2ac; margin-bottom: 1rem;">👛 Payment Received</h3>
              <div style="background: #f7fafc; padding: 1rem; border-radius: 8px; margin-bottom: 1rem;">
                <p><strong>Total Received:</strong> ${metric.value}</p>
                <p><strong>Paid Orders:</strong> 298 orders</p>
                <p><strong>Pending Payment:</strong> ₹6,830 (44 orders)</p>
              </div>
              <h4>Payment Methods</h4>
              <ul style="list-style: none; padding: 0;">
                <li style="margin: 0.5rem 0;">💵 Cash on Delivery: ₹22,500 (58%)</li>
                <li style="margin: 0.5rem 0;">💳 Online Payment: ₹12,300 (32%)</li>
                <li style="margin: 0.5rem 0;">📱 UPI: ₹3,650 (10%)</li>
              </ul>
            </div>
          `;
          break;

        case "Today's Orders":
          detailsHtml = `
            <div style="text-align: left; padding: 1rem;">
              <h3 style="color: #4299e1; margin-bottom: 1rem;">📅 Today's Orders</h3>
              <div style="background: #f7fafc; padding: 1rem; border-radius: 8px; margin-bottom: 1rem;">
                <p><strong>Total Orders:</strong> ${metric.value}</p>
                <p><strong>Revenue Today:</strong> ₹3,840</p>
                <p><strong>Avg Order Value:</strong> ₹137</p>
              </div>
              <h4>Order Status Breakdown</h4>
              <ul style="list-style: none; padding: 0;">
                <li style="margin: 0.5rem 0;">✅ Delivered: 12 orders</li>
                <li style="margin: 0.5rem 0;">🚚 Out for Delivery: 8 orders</li>
                <li style="margin: 0.5rem 0;">🍳 Preparing: 5 orders</li>
                <li style="margin: 0.5rem 0;">⏳ Pending: 3 orders</li>
              </ul>
            </div>
          `;
          break;

        case 'Cancelled Orders':
          detailsHtml = `
            <div style="text-align: left; padding: 1rem;">
              <h3 style="color: #f56565; margin-bottom: 1rem;">❌ Cancelled Orders</h3>
              <div style="background: #f7fafc; padding: 1rem; border-radius: 8px; margin-bottom: 1rem;">
                <p><strong>Total Cancelled:</strong> ${metric.value}</p>
                <p><strong>Cancellation Rate:</strong> 3.5%</p>
                <p><strong>Trend:</strong> <span style="color: #48bb78;">Down 5.2%</span> ✅</p>
              </div>
              <h4>Top Cancellation Reasons</h4>
              <ul style="list-style: none; padding: 0;">
                <li style="margin: 0.5rem 0;">❌ Out of Stock: 5 orders (42%)</li>
                <li style="margin: 0.5rem 0;">⏰ Delayed Delivery: 3 orders (25%)</li>
                <li style="margin: 0.5rem 0;">💰 Price Issue: 2 orders (17%)</li>
                <li style="margin: 0.5rem 0;">🔄 Customer Changed Mind: 2 orders (16%)</li>
              </ul>
            </div>
          `;
          break;

        case 'Total Refunds':
          detailsHtml = `
            <div style="text-align: left; padding: 1rem;">
              <h3 style="color: #ed8936; margin-bottom: 1rem;">💸 Refunds Issued</h3>
              <div style="background: #f7fafc; padding: 1rem; border-radius: 8px; margin-bottom: 1rem;">
                <p><strong>Total Refunded:</strong> ${metric.value}</p>
                <p><strong>Refund Orders:</strong> 12 orders</p>
                <p><strong>Avg Refund:</strong> ₹270</p>
              </div>
              <h4>Refund Timeline</h4>
              <ul style="list-style: none; padding: 0;">
                <li style="margin: 0.5rem 0;">⚡ Processed within 24h: 8 refunds</li>
                <li style="margin: 0.5rem 0;">⏳ Processed within 3 days: 3 refunds</li>
                <li style="margin: 0.5rem 0;">🕐 Pending: 1 refund</li>
              </ul>
              <p style="margin-top: 1rem; color: #48bb78;"><strong>✅ Good news!</strong> Refunds are down 15.3% from last month</p>
            </div>
          `;
          break;

        default:
          detailsHtml = `
            <div style="text-align: left; padding: 1rem;">
              <h3 style="color: #667eea; margin-bottom: 1rem;">📊 ${metric.title}</h3>
              <div style="background: #f7fafc; padding: 1rem; border-radius: 8px;">
                <p><strong>Value:</strong> ${metric.value}</p>
                <p><strong>Trend:</strong> ${metric.trend >= 0 ? '+' : ''}${metric.trend}%</p>
                <p><strong>Details:</strong> ${metric.trendLabel}</p>
              </div>
            </div>
          `;
      }

      Swal.default.fire({
        title: metric.title,
        html: detailsHtml,
        icon: 'info',
        confirmButtonColor: '#667eea',
        confirmButtonText: 'Close',
        width: 600
      });
    });
  }

  viewProductDetails(product: TopProduct): void {
    import('sweetalert2').then((Swal) => {
      Swal.default.fire({
        title: product.name,
        html: `
          <div style="text-align: left; padding: 1rem;">
            <div style="background: #f7fafc; padding: 1.5rem; border-radius: 12px; margin-bottom: 1rem;">
              <h4 style="margin: 0 0 1rem 0; color: #667eea;">📦 Product Performance</h4>
              <p><strong>Category:</strong> ${product.category}</p>
              <p><strong>Total Revenue:</strong> ${this.formatCurrency(product.revenue)}</p>
              <p><strong>Total Orders:</strong> ${product.orders} orders</p>
              <p><strong>Avg Revenue/Order:</strong> ${this.formatCurrency(Math.round(product.revenue / product.orders))}</p>
            </div>

            <div style="background: ${product.trend >= 0 ? '#f0fff4' : '#fff5f5'}; padding: 1rem; border-radius: 8px; margin-bottom: 1rem;">
              <p style="margin: 0; color: ${product.trend >= 0 ? '#38a169' : '#e53e3e'};">
                <strong>Trend:</strong> ${product.trend >= 0 ? '📈' : '📉'} ${product.trend >= 0 ? '+' : ''}${product.trend}% vs last month
              </p>
            </div>

            <h4 style="margin: 1rem 0 0.5rem 0;">📊 Sales Breakdown</h4>
            <ul style="list-style: none; padding: 0; margin: 0;">
              <li style="margin: 0.5rem 0;">🗓️ This Week: ${Math.floor(product.orders * 0.25)} orders</li>
              <li style="margin: 0.5rem 0;">📅 This Month: ${product.orders} orders</li>
              <li style="margin: 0.5rem 0;">⭐ Top Selling Day: Sunday (${Math.floor(product.orders * 0.15)} orders)</li>
            </ul>

            <div style="margin-top: 1rem; padding: 1rem; background: #edf2f7; border-radius: 8px;">
              <p style="margin: 0; font-size: 0.9rem; color: #4a5568;">
                💡 <strong>Insight:</strong> ${product.trend >= 0
                  ? 'This product is performing well! Consider promoting similar items.'
                  : 'Sales are declining. Consider promotions or check inventory levels.'}
              </p>
            </div>
          </div>
        `,
        icon: 'info',
        confirmButtonColor: '#667eea',
        confirmButtonText: 'Close',
        width: 650
      });
    });
  }

  viewOrderDetails(order: RecentOrder): void {
    import('sweetalert2').then((Swal) => {
      Swal.default.fire({
        title: `Order ${order.id}`,
        html: `
          <div style="text-align: left; padding: 1rem;">
            <div style="background: #f7fafc; padding: 1.5rem; border-radius: 12px; margin-bottom: 1rem;">
              <h4 style="margin: 0 0 1rem 0; color: #667eea;">📋 Order Information</h4>
              <p><strong>Customer:</strong> ${order.customerName}</p>
              <p><strong>Order ID:</strong> ${order.id}</p>
              <p><strong>Date:</strong> ${this.formatDate(order.date)}</p>
              <p><strong>Total Items:</strong> ${order.items} items</p>
              <p><strong>Order Amount:</strong> ${this.formatCurrency(order.amount)}</p>
            </div>

            <div style="padding: 1rem; border-radius: 8px; margin-bottom: 1rem;
                        background: ${this.getOrderStatusColor(order.status)};">
              <p style="margin: 0;">
                <strong>Status:</strong> ${this.getOrderStatusIcon(order.status)} ${order.status}
              </p>
            </div>

            <h4 style="margin: 1rem 0 0.5rem 0;">📦 Sample Order Items</h4>
            <ul style="list-style: none; padding: 0; margin: 0;">
              <li style="margin: 0.5rem 0; padding: 0.5rem; background: #f7fafc; border-radius: 6px;">
                Rice (5kg) × 2 - ₹${Math.floor(order.amount * 0.4)}
              </li>
              <li style="margin: 0.5rem 0; padding: 0.5rem; background: #f7fafc; border-radius: 6px;">
                Dal (1kg) × 1 - ₹${Math.floor(order.amount * 0.3)}
              </li>
              <li style="margin: 0.5rem 0; padding: 0.5rem; background: #f7fafc; border-radius: 6px;">
                Oil (1L) × 1 - ₹${Math.floor(order.amount * 0.3)}
              </li>
            </ul>

            <div style="margin-top: 1rem; padding: 1rem; background: #edf2f7; border-radius: 8px; text-align: center;">
              <p style="margin: 0; font-size: 0.9rem;">
                ${order.status === 'Delivered'
                  ? '✅ Order successfully delivered!'
                  : order.status === 'In Transit'
                  ? '🚚 Order is on the way to customer'
                  : '🍳 Order is being prepared'}
              </p>
            </div>
          </div>
        `,
        icon: 'info',
        confirmButtonColor: '#667eea',
        confirmButtonText: 'Close',
        width: 650,
        showCancelButton: order.status !== 'Delivered',
        cancelButtonText: 'View in Order Management',
        cancelButtonColor: '#4299e1'
      }).then((result) => {
        if (result.dismiss === Swal.default.DismissReason.cancel) {
          console.log('Navigate to order management for order:', order.id);
          // TODO: Navigate to order management screen
          // this.router.navigate(['/shop-owner/orders'], { queryParams: { orderId: order.id } });
        }
      });
    });
  }

  private getOrderStatusColor(status: string): string {
    const colorMap: { [key: string]: string } = {
      'Delivered': '#c6f6d5',
      'In Transit': '#bee3f8',
      'Processing': '#fef5e7',
      'Cancelled': '#fed7d7'
    };
    return colorMap[status] || '#f7fafc';
  }

  private getOrderStatusIcon(status: string): string {
    const iconMap: { [key: string]: string } = {
      'Delivered': '✅',
      'In Transit': '🚚',
      'Processing': '🍳',
      'Cancelled': '❌'
    };
    return iconMap[status] || '📦';
  }
}
