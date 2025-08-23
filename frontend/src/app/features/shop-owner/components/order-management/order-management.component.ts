import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subject, interval } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { ShopOrderService, ShopOrder } from '../../services/shop-order.service';
import { DeliveryAssignmentService } from '../../../delivery/services/delivery-assignment.service';
import { DailySummaryService } from '../../services/daily-summary.service';
import { NotificationOrchestratorService } from '../../../../core/services/notification-orchestrator.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-order-management',
  templateUrl: './order-management.component.html',
  styleUrls: ['./order-management.component.scss']
})
export class OrderManagementComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  
  shopId = 1; // This should come from auth service
  pendingOrders: ShopOrder[] = [];
  activeOrders: ShopOrder[] = [];
  completedOrders: ShopOrder[] = [];
  
  selectedTab = 0;
  loading = false;
  autoRefreshEnabled = true;
  refreshInterval = 30000; // 30 seconds
  
  todayStats = {
    totalOrders: 0,
    pendingOrders: 0,
    completedOrders: 0,
    revenue: 0,
    averageOrderValue: 0,
    totalProfit: 0,
    profitMargin: 0
  };
  
  showProfitDetails = false;
  profitBreakdown: any = null;

  constructor(
    private shopOrderService: ShopOrderService,
    private deliveryService: DeliveryAssignmentService,
    private dailySummaryService: DailySummaryService,
    private notificationService: NotificationOrchestratorService
  ) {}

  ngOnInit(): void {
    this.loadShopId();
    this.loadOrders();
    this.loadTodayStats();
    this.loadProfitData();
    this.startAutoRefresh();
    this.checkAndSendDailySummary();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadShopId(): void {
    // Get shop ID from auth service or local storage
    const user = localStorage.getItem('currentUser');
    if (user) {
      const userData = JSON.parse(user);
      this.shopId = userData.shopId || 1;
    }
  }

  loadOrders(): void {
    this.loading = true;
    
    // Load pending orders
    this.shopOrderService.getPendingOrders(this.shopId)
      .pipe(takeUntil(this.destroy$))
      .subscribe(orders => {
        this.pendingOrders = orders;
        this.checkForNewOrders(orders);
      });
    
    // Load active orders
    this.shopOrderService.getActiveOrders(this.shopId)
      .pipe(takeUntil(this.destroy$))
      .subscribe(orders => {
        this.activeOrders = orders;
      });
    
    // Load completed orders
    this.shopOrderService.getShopOrders(this.shopId, 'COMPLETED')
      .pipe(takeUntil(this.destroy$))
      .subscribe(orders => {
        this.completedOrders = orders;
        this.loading = false;
      });
  }

  loadTodayStats(): void {
    this.shopOrderService.getTodayOrderStats(this.shopId)
      .pipe(takeUntil(this.destroy$))
      .subscribe(stats => {
        this.todayStats = stats;
      });
  }

  checkForNewOrders(orders: ShopOrder[]): void {
    const newOrdersCount = orders.filter(o => {
      const orderTime = new Date(o.createdAt).getTime();
      const fiveMinutesAgo = Date.now() - (5 * 60 * 1000);
      return orderTime > fiveMinutesAgo;
    }).length;
    
    if (newOrdersCount > 0) {
      this.playNotificationSound();
      Swal.fire({
        title: 'New Order!',
        text: `You have ${newOrdersCount} new order${newOrdersCount > 1 ? 's' : ''}`,
        icon: 'info',
        toast: true,
        position: 'top-end',
        timer: 5000,
        showConfirmButton: false
      });
    }
  }

  acceptOrder(order: ShopOrder): void {
    Swal.fire({
      title: 'Accept Order',
      text: 'Enter estimated preparation time:',
      input: 'select',
      inputOptions: {
        '15 minutes': '15 minutes',
        '20 minutes': '20 minutes',
        '30 minutes': '30 minutes',
        '45 minutes': '45 minutes',
        '1 hour': '1 hour'
      },
      inputPlaceholder: 'Select preparation time',
      showCancelButton: true,
      confirmButtonText: 'Accept Order',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        this.shopOrderService.acceptOrder(order.id, result.value)
          .pipe(takeUntil(this.destroy$))
          .subscribe({
            next: (acceptedOrder) => {
              this.loadOrders();
              this.autoAssignDeliveryPartner(order.id);
              
              // Send notifications via orchestrator
              this.notificationService.handleNotification({
                type: 'ORDER_ACCEPTED',
                orderId: order.id,
                orderNumber: order.orderNumber,
                recipients: {
                  customer: {
                    email: order.customerEmail,
                    name: order.customerName
                  }
                },
                data: {
                  estimatedTime: result.value,
                  shopOTP: this.generateOTP()
                }
              }).subscribe();
            },
            error: (error) => {
              console.error('Error accepting order:', error);
            }
          });
      }
    });
  }

  rejectOrder(order: ShopOrder): void {
    Swal.fire({
      title: 'Reject Order',
      text: 'Please provide a reason:',
      input: 'select',
      inputOptions: {
        'Out of stock': 'Out of stock',
        'Shop closed': 'Shop closed',
        'Too busy': 'Too busy',
        'Technical issue': 'Technical issue',
        'Other': 'Other'
      },
      inputPlaceholder: 'Select reason',
      showCancelButton: true,
      confirmButtonText: 'Reject',
      cancelButtonText: 'Cancel',
      confirmButtonColor: '#d33'
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        this.shopOrderService.rejectOrder(order.id, result.value)
          .pipe(takeUntil(this.destroy$))
          .subscribe({
            next: () => {
              this.loadOrders();
            },
            error: (error) => {
              console.error('Error rejecting order:', error);
            }
          });
      }
    });
  }

  markAsPreparing(order: ShopOrder): void {
    this.shopOrderService.markAsPreparing(order.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.loadOrders();
        },
        error: (error) => {
          console.error('Error updating status:', error);
        }
      });
  }

  markAsReady(order: ShopOrder): void {
    this.shopOrderService.markAsReady(order.id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.loadOrders();
          this.generatePickupOTP(order.id);
        },
        error: (error) => {
          console.error('Error updating status:', error);
        }
      });
  }

  generatePickupOTP(orderId: number): void {
    this.shopOrderService.generateShopOTP(orderId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          // OTP is shown in the service via Swal
        },
        error: (error) => {
          console.error('Error generating OTP:', error);
        }
      });
  }

  autoAssignDeliveryPartner(orderId: number): void {
    this.deliveryService.autoAssignDeliveryPartner(orderId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (assignment) => {
          console.log('Delivery partner assigned:', assignment);
        },
        error: (error) => {
          console.error('Auto-assignment failed:', error);
          // Manual assignment can be done from admin panel
        }
      });
  }

  viewOrderDetails(order: ShopOrder): void {
    const itemsHtml = order.items.map(item => `
      <tr>
        <td>${item.productName}</td>
        <td>${item.quantity}</td>
        <td>₹${item.unitPrice}</td>
        <td>₹${item.totalPrice}</td>
      </tr>
    `).join('');

    Swal.fire({
      title: `Order #${order.orderNumber}`,
      html: `
        <div style="text-align: left;">
          <p><strong>Customer:</strong> ${order.customerName}</p>
          <p><strong>Phone:</strong> ${order.customerPhone}</p>
          <p><strong>Delivery Address:</strong> ${order.deliveryAddress}</p>
          <p><strong>Payment:</strong> ${order.paymentMethod} (${order.paymentStatus})</p>
          ${order.notes ? `<p><strong>Notes:</strong> ${order.notes}</p>` : ''}
          <hr>
          <table style="width: 100%; border-collapse: collapse;">
            <thead>
              <tr style="border-bottom: 1px solid #ddd;">
                <th style="text-align: left;">Item</th>
                <th>Qty</th>
                <th>Price</th>
                <th>Total</th>
              </tr>
            </thead>
            <tbody>
              ${itemsHtml}
            </tbody>
          </table>
          <hr>
          <p style="text-align: right;"><strong>Total: ₹${order.totalAmount}</strong></p>
        </div>
      `,
      width: '600px',
      confirmButtonText: 'Close'
    });
  }

  printOrder(order: ShopOrder): void {
    this.shopOrderService.printOrderReceipt(order.id);
  }

  searchOrders(searchTerm: string): void {
    if (!searchTerm) {
      this.loadOrders();
      return;
    }
    
    this.shopOrderService.searchOrders(this.shopId, searchTerm)
      .pipe(takeUntil(this.destroy$))
      .subscribe(orders => {
        // Filter orders by current tab
        this.pendingOrders = orders.filter(o => o.status === 'PENDING');
        this.activeOrders = orders.filter(o => 
          ['CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP'].includes(o.status)
        );
        this.completedOrders = orders.filter(o => 
          ['COMPLETED', 'DELIVERED'].includes(o.status)
        );
      });
  }

  startAutoRefresh(): void {
    if (!this.autoRefreshEnabled) return;
    
    interval(this.refreshInterval)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => {
        this.loadOrders();
        this.loadTodayStats();
      });
  }

  playNotificationSound(): void {
    const audio = new Audio('/assets/sounds/notification.mp3');
    audio.play().catch(e => console.error('Error playing sound:', e));
  }

  getStatusColor(status: string): string {
    switch(status) {
      case 'PENDING': return '#ff9800';
      case 'CONFIRMED': return '#2196f3';
      case 'PREPARING': return '#9c27b0';
      case 'READY_FOR_PICKUP': return '#4caf50';
      case 'COMPLETED': return '#8bc34a';
      default: return '#757575';
    }
  }

  getStatusIcon(status: string): string {
    switch(status) {
      case 'PENDING': return 'hourglass_empty';
      case 'CONFIRMED': return 'check_circle';
      case 'PREPARING': return 'restaurant';
      case 'READY_FOR_PICKUP': return 'inventory';
      case 'COMPLETED': return 'done_all';
      default: return 'help';
    }
  }
  
  loadProfitData(): void {
    this.dailySummaryService.getRealTimeProfit(this.shopId)
      .pipe(takeUntil(this.destroy$))
      .subscribe(profit => {
        this.todayStats.totalProfit = profit.currentProfit;
        this.todayStats.profitMargin = profit.profitMargin || 30;
      });
  }
  
  toggleProfitDetails(): void {
    this.showProfitDetails = !this.showProfitDetails;
    if (this.showProfitDetails && !this.profitBreakdown) {
      this.dailySummaryService.generateProfitReport(this.shopId, 'daily')
        .pipe(takeUntil(this.destroy$))
        .subscribe(breakdown => {
          this.profitBreakdown = breakdown;
        });
    }
  }
  
  sendDailySummary(): void {
    const shopOwnerEmail = this.getShopOwnerEmail();
    if (shopOwnerEmail) {
      this.dailySummaryService.sendDailySummary(this.shopId, shopOwnerEmail)
        .pipe(takeUntil(this.destroy$))
        .subscribe(success => {
          if (success) {
            Swal.fire({
              title: 'Daily Summary Sent!',
              text: 'Your daily business summary has been sent to your email.',
              icon: 'success',
              timer: 3000
            });
          }
        });
    }
  }
  
  checkAndSendDailySummary(): void {
    const now = new Date();
    // Auto-send summary at 10 PM
    if (now.getHours() === 22) {
      this.sendDailySummary();
    }
  }
  
  getShopOwnerEmail(): string {
    const user = localStorage.getItem('currentUser');
    if (user) {
      const userData = JSON.parse(user);
      return userData.email || 'shop@nammaooru.com';
    }
    return 'shop@nammaooru.com';
  }
  
  generateOTP(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }
}