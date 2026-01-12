import { Component, OnInit, OnDestroy, NgZone } from '@angular/core';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatTabChangeEvent } from '@angular/material/tabs';
import { ShopOwnerOrderService, ShopOwnerOrder } from '../../services/shop-owner-order.service';
import { ShopOwnerProductService } from '../../services/shop-owner-product.service';
import { AssignmentService } from '../../services/assignment.service';
import { AuthService } from '../../../../core/services/auth.service';
import { SwalService } from '../../../../core/services/swal.service';
import { ShopContextService } from '../../services/shop-context.service';
import { WebSocketService } from '../../../../core/services/websocket.service';
import { environment } from '../../../../../environments/environment';
import { getImageUrl as getImageUrlUtil } from '../../../../core/utils/image-url.util';
import { Subject } from 'rxjs';
import Swal from 'sweetalert2';
import { takeUntil, distinctUntilChanged } from 'rxjs/operators';

@Component({
  selector: 'app-orders-management',
  templateUrl: './orders-management.component.html',
  styleUrls: ['./orders-management.component.scss']
})
export class OrdersManagementComponent implements OnInit, OnDestroy {

  // Order data
  orders: ShopOwnerOrder[] = [];
  filteredOrders: ShopOwnerOrder[] = [];
  pendingOrders: ShopOwnerOrder[] = [];
  processingOrders: ShopOwnerOrder[] = [];
  activeOrders: ShopOwnerOrder[] = [];
  completedOrders: ShopOwnerOrder[] = [];
  todayOrders: ShopOwnerOrder[] = [];
  inProgressOrders: ShopOwnerOrder[] = [];

  // Shop ID - dynamically retrieved from shop context service
  shopId: number | null = null;

  // Main tab control (realtime vs history)
  mainTab: 'realtime' | 'history' = 'realtime';

  // Filter controls
  searchTerm = '';
  selectedStatus = 'REALTIME_ALL';
  selectedTabIndex = 0;
  startDate: Date | null = null;
  endDate: Date | null = null;
  fromDate: string = '';
  toDate: string = '';

  // Pagination
  totalOrders = 0;
  pageSize = 10;

  // Statistics
  todayRevenue = 0;
  todayProfit = 0;
  profitMargin = 20; // Default 20% profit margin

  // Assignment state
  isAssigningPartner = false;

  // Orders currently searching for driver
  searchingDriverOrders: Set<number> = new Set();

  // Orders currently processing (loading state per order)
  processingOrderIds: Set<number> = new Set();

  // Driver verification
  verificationCodes: { [orderId: number]: string } = {};

  // Message properties
  successMessage = '';
  errorMessage = '';

  // Daily summary loading state
  isSendingSummary = false;

  // Unsubscription subject
  private destroy$ = new Subject<void>();

  constructor(
    private orderService: ShopOwnerOrderService,
    private productService: ShopOwnerProductService,
    private assignmentService: AssignmentService,
    private authService: AuthService,
    private shopContextService: ShopContextService,
    private snackBar: MatSnackBar,
    private swal: SwalService,
    private router: Router,
    private http: HttpClient,
    private webSocketService: WebSocketService,
    private ngZone: NgZone
  ) {}

  ngOnInit(): void {
    // Check if user is authenticated
    if (!this.authService.isAuthenticated()) {
      console.error('User not authenticated. Redirecting to login...');
      this.router.navigate(['/auth/login']);
      return;
    }

    // Simple: Get shop ID from localStorage and load orders
    this.loadOrdersFromCache();
  }

  ngOnDestroy(): void {
    // Clean up subscriptions
    this.destroy$.next();
    this.destroy$.complete();
    // Disconnect WebSocket
    this.webSocketService.disconnect();
  }

  loadOrdersFromCache(): void {
    // Check cache first - use numeric ID
    const cachedShopId = localStorage.getItem('current_shop_id');
    if (cachedShopId) {
      this.shopId = parseInt(cachedShopId, 10);
      console.log('Using cached shop ID:', this.shopId);
      this.loadOrders();
      this.subscribeToWebSocketUpdates();
      return;
    }

    // No cache - call API to get shop ID dynamically
    console.log('No cached shop ID - calling /api/shops/my-shop');
    this.http.get<any>(`${environment.apiUrl}/shops/my-shop`).subscribe({
      next: (response) => {
        if (response.data && response.data.id) {
          this.shopId = response.data.id;
          localStorage.setItem('current_shop_id', response.data.id.toString());
          // Save shop name for receipt printing
          if (response.data.name) {
            localStorage.setItem('shop_name', response.data.name);
          }
          console.log('Got shop ID from API:', this.shopId);
          this.loadOrders();
          this.subscribeToWebSocketUpdates();
        }
      },
      error: (error) => {
        console.error('Error getting shop ID:', error);
      }
    });
  }

  /**
   * Subscribe to WebSocket for real-time order updates
   */
  private subscribeToWebSocketUpdates(): void {
    if (!this.shopId) {
      console.log('Cannot subscribe to WebSocket - no shop ID');
      return;
    }

    console.log('📡 Connecting to WebSocket for shop:', this.shopId);

    // Connect to WebSocket
    const token = localStorage.getItem('auth_token');
    this.webSocketService.connect(token || undefined).pipe(
      takeUntil(this.destroy$)
    ).subscribe({
      next: (connected) => {
        if (connected) {
          console.log('✅ WebSocket connected, subscribing to shop orders');
          this.subscribeToShopOrders();
        }
      },
      error: (error) => {
        console.error('❌ WebSocket connection error:', error);
      }
    });
  }

  /**
   * Subscribe to shop orders topic for real-time notifications
   */
  private subscribeToShopOrders(): void {
    if (!this.shopId) return;

    this.webSocketService.subscribeToShopOrders(this.shopId).pipe(
      takeUntil(this.destroy$)
    ).subscribe({
      next: (message) => {
        console.log('📬 WebSocket message received:', message);
        this.handleWebSocketMessage(message);
      },
      error: (error) => {
        console.error('❌ WebSocket subscription error:', error);
      }
    });
  }

  /**
   * Handle incoming WebSocket messages for order updates
   * Uses NgZone.run() to ensure Angular change detection is triggered
   */
  private handleWebSocketMessage(message: any): void {
    if (!message || !message.type) return;

    // Run inside Angular zone to trigger change detection
    this.ngZone.run(() => {
      switch (message.type) {
        case 'NEW_ORDER':
          console.log('🆕 New order received:', message.orderNumber);
          // Play notification sound
          this.playNotificationSound();
          // Show toast notification
          this.swal.toast(`New order #${message.orderNumber} received!`, 'success');
          // Reload orders to get the new order
          this.loadOrders();
          break;

        case 'ORDER_STATUS_UPDATE':
          console.log('🔄 Order status updated:', message.orderNumber, message.oldStatus, '->', message.newStatus);
          // Update the order in the local list or reload
          this.loadOrders();
          break;

        case 'ORDER_RETURNING':
          console.log('🔙 Order returning to shop:', message.orderNumber);
          // Play notification sound for important update
          this.playNotificationSound();
          // Show warning toast
          this.swal.toast(`Order #${message.orderNumber} - Driver returning products!`, 'warning');
          // Reload orders
          this.loadOrders();
          break;

        case 'ORDER_RETURNED':
          console.log('📦 Order returned to shop:', message.orderNumber);
          // Play notification sound for important update
          this.playNotificationSound();
          // Show info toast
          this.swal.toast(`Order #${message.orderNumber} - Products returned. Please verify!`, 'info');
          // Reload orders
          this.loadOrders();
          break;

        default:
          console.log('Unknown WebSocket message type:', message.type);
      }
    });
  }

  /**
   * Play notification sound for new orders using Web Audio API
   * This generates a pleasant notification beep without needing external files
   */
  private playNotificationSound(): void {
    try {
      // Create audio context
      const AudioContext = window.AudioContext || (window as any).webkitAudioContext;
      const audioContext = new AudioContext();

      // Create oscillator for the beep
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();

      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);

      // Set beep properties - pleasant notification tone
      oscillator.frequency.value = 880; // A5 note
      oscillator.type = 'sine';

      // Set volume envelope (fade in/out)
      gainNode.gain.setValueAtTime(0, audioContext.currentTime);
      gainNode.gain.linearRampToValueAtTime(0.3, audioContext.currentTime + 0.05);
      gainNode.gain.linearRampToValueAtTime(0, audioContext.currentTime + 0.3);

      // Play first beep
      oscillator.start(audioContext.currentTime);
      oscillator.stop(audioContext.currentTime + 0.3);

      // Play second beep after short delay
      setTimeout(() => {
        const osc2 = audioContext.createOscillator();
        const gain2 = audioContext.createGain();
        osc2.connect(gain2);
        gain2.connect(audioContext.destination);
        osc2.frequency.value = 1046.5; // C6 note (higher)
        osc2.type = 'sine';
        gain2.gain.setValueAtTime(0, audioContext.currentTime);
        gain2.gain.linearRampToValueAtTime(0.3, audioContext.currentTime + 0.05);
        gain2.gain.linearRampToValueAtTime(0, audioContext.currentTime + 0.3);
        osc2.start(audioContext.currentTime);
        osc2.stop(audioContext.currentTime + 0.3);
      }, 200);

      console.log('🔔 Notification sound played');
    } catch (error) {
      console.log('Error playing notification sound:', error);
    }
  }

  loadDashboardData(): void {
    console.log('Loading dashboard data...');

    // Load all orders first, then calculate statistics from them
    this.loadOrders();
  }

  /**
   * Send daily order summary email to shop owner
   */
  sendDailySummary(): void {
    this.isSendingSummary = true;

    this.http.post<any>('/api/shops/dashboard/send-daily-summary', {}).subscribe({
      next: (response) => {
        this.isSendingSummary = false;
        if (response.success) {
          this.swal.success('Email Sent', response.message || 'Daily summary email sent to your registered email.');
        } else {
          this.swal.error('Failed', response.message || 'Failed to send daily summary.');
        }
      },
      error: (error) => {
        this.isSendingSummary = false;
        console.error('Error sending daily summary:', error);
        this.swal.error('Error', 'Failed to send daily summary email. Please try again.');
      }
    });
  }

  loadOrders(): void {
    if (!this.shopId) {
      console.log('No shop ID available, cannot load orders');
      return;
    }

    console.log('Loading orders for shop:', this.shopId);

    this.orderService.getShopOrders(this.shopId).subscribe({
      next: (orders) => {
        console.log('Orders loaded successfully:', orders.length);
        this.orders = orders;
        this.updateOrderLists();

        // Show success message if orders are loaded
        if (orders.length > 0) {
          this.successMessage = `Loaded ${orders.length} orders successfully`;
          setTimeout(() => this.successMessage = '', 3000);
        }
      },
      error: (error) => {
        console.error('Error loading orders:', error);

        // Check if it's an authentication error
        if (error.status === 401 || error.status === 403) {
          this.swal.error('Authentication Required', 'Please login to view orders.');
        } else {
          this.swal.error('Error', 'Failed to load orders. Please try again.');
        }
      }
    });
  }

  updateOrderLists(): void {
    this.filteredOrders = [...this.orders];

    // Filter orders by status
    this.pendingOrders = this.orders.filter(o => o.status === 'PENDING');
    this.processingOrders = this.orders.filter(o => o.status === 'CONFIRMED');
    this.activeOrders = this.orders.filter(o =>
      ['CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY'].includes(o.status)
    );
    this.completedOrders = this.orders.filter(o => o.status === 'DELIVERED');

    // Filter today's orders
    this.todayOrders = this.orders.filter(o => this.isToday(new Date(o.createdAt)));

    // In-progress orders
    this.inProgressOrders = this.orders.filter(o =>
      ['CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY'].includes(o.status)
    );

    // Set total count
    this.totalOrders = this.orders.length;

    // Calculate comprehensive statistics
    this.calculateStatistics();
  }

  calculateStatistics(): void {
    // Calculate OVERALL revenue from ALL delivered orders (not just today)
    const allDeliveredOrders = this.orders.filter(order =>
      order.status === 'DELIVERED' || order.paymentStatus === 'PAID'
    );

    // Calculate TODAY's revenue from all orders (not just delivered)
    const today = new Date();
    const allTodayOrders = this.orders.filter(order => {
      const orderDate = new Date(order.createdAt);
      return orderDate.toDateString() === today.toDateString();
    });

    // Revenue from all today's orders
    this.todayRevenue = allTodayOrders.reduce((sum, order) => sum + (order.totalAmount || 0), 0);

    // If no orders today, show total revenue from all orders
    if (this.todayRevenue === 0) {
      this.todayRevenue = this.orders.reduce((sum, order) => sum + (order.totalAmount || 0), 0);
    }

    // Calculate profit based on margin
    this.todayProfit = this.todayRevenue * (this.profitMargin / 100);

    console.log('Statistics calculated:', {
      totalOrders: this.totalOrders,
      pendingOrders: this.pendingOrders.length,
      completedOrders: this.completedOrders.length,
      todayOrders: this.todayOrders.length,
      todayRevenue: this.todayRevenue,
      todayProfit: this.todayProfit
    });
  }

  isToday(date: Date): boolean {
    const today = new Date();
    return date.toDateString() === today.toDateString();
  }

  applyFilter(): void {
    const realtimeStatuses = ['PENDING', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'PICKED_UP', 'OUT_FOR_DELIVERY', 'RETURNING_TO_SHOP', 'RETURNED_TO_SHOP'];
    const historyStatuses = ['DELIVERED', 'CANCELLED', 'SELF_PICKUP_COLLECTED'];

    this.filteredOrders = this.orders.filter(order => {
      const matchesSearch = !this.searchTerm ||
        order.orderNumber.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        order.customerName.toLowerCase().includes(this.searchTerm.toLowerCase());

      // Handle special status filters
      let matchesStatus = true;
      if (this.selectedStatus === 'REALTIME_ALL') {
        matchesStatus = realtimeStatuses.includes(order.status);
      } else if (this.selectedStatus === 'HISTORY_ALL') {
        matchesStatus = historyStatuses.includes(order.status);
      } else if (this.selectedStatus === 'RETURNS') {
        matchesStatus = order.status === 'RETURNING_TO_SHOP' || order.status === 'RETURNED_TO_SHOP';
      } else if (this.selectedStatus === 'SELF_PICKUP_ACTIVE') {
        const activeStatuses = ['PENDING', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP'];
        matchesStatus = order.deliveryType === 'SELF_PICKUP' && activeStatuses.includes(order.status);
      } else if (this.selectedStatus === 'SELF_PICKUP') {
        matchesStatus = order.deliveryType === 'SELF_PICKUP' && historyStatuses.includes(order.status);
      } else if (this.selectedStatus === 'WALK_IN') {
        matchesStatus = (order as any).orderType === 'WALK_IN' && historyStatuses.includes(order.status);
      } else if (this.selectedStatus === 'ONLINE') {
        matchesStatus = (order as any).orderType !== 'WALK_IN' && historyStatuses.includes(order.status);
      } else if (this.selectedStatus === 'DELIVERED') {
        matchesStatus = order.status === 'DELIVERED' || order.status === 'SELF_PICKUP_COLLECTED';
      } else if (this.selectedStatus) {
        matchesStatus = order.status === this.selectedStatus;
      }

      const matchesDateRange = this.matchesDateRange(order);

      return matchesSearch && matchesStatus && matchesDateRange;
    });
  }

  matchesDateRange(order: ShopOwnerOrder): boolean {
    if (!this.fromDate && !this.toDate) {
      return true; // No date filter applied
    }

    try {
      const orderDate = new Date(order.createdAt);
      const orderDateOnly = new Date(orderDate.getFullYear(), orderDate.getMonth(), orderDate.getDate());

      if (this.fromDate) {
        const fromDateParts = this.fromDate.split('-');
        const fromDateOnly = new Date(parseInt(fromDateParts[0]), parseInt(fromDateParts[1]) - 1, parseInt(fromDateParts[2]));
        if (orderDateOnly < fromDateOnly) {
          return false;
        }
      }

      if (this.toDate) {
        const toDateParts = this.toDate.split('-');
        const toDateOnly = new Date(parseInt(toDateParts[0]), parseInt(toDateParts[1]) - 1, parseInt(toDateParts[2]));
        if (orderDateOnly > toDateOnly) {
          return false;
        }
      }

      return true;
    } catch (error) {
      console.error('Error in date filtering:', error);
      return true; // Return true if there's an error to show the order
    }
  }

  clearDateFilter(): void {
    this.fromDate = '';
    this.toDate = '';
    this.applyFilter();
  }

  onTabChange(event: MatTabChangeEvent): void {
    this.selectedTabIndex = event.index;
  }

  acceptOrder(order: ShopOwnerOrder): void {
    this.startProcessing(order.id);
    this.orderService.acceptOrder(order.id).subscribe({
      next: (updatedOrder) => {
        const orderIndex = this.orders.findIndex(o => o.id === order.id);
        if (orderIndex !== -1) {
          this.orders[orderIndex] = updatedOrder;
          this.updateOrderLists();
          this.applyFilter();
        }
        this.stopProcessing(order.id);
        this.swal.toast('Order accepted', 'success');
      },
      error: (error) => {
        console.error('Error accepting order:', error);
        this.stopProcessing(order.id);
        this.swal.error('Error', 'Failed to accept order. Please try again.');
      }
    });
  }

  rejectOrder(order: ShopOwnerOrder): void {
    this.swal.custom({
      title: 'Reject Order',
      text: 'Please provide a reason for rejection:',
      input: 'text',
      inputPlaceholder: 'Enter reason...',
      showCancelButton: true,
      confirmButtonText: 'Reject',
      cancelButtonText: 'Cancel',
      confirmButtonColor: '#ef4444',
      inputValidator: (value) => {
        if (!value) {
          return 'You need to provide a reason!';
        }
        return null;
      }
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        this.swal.loading('Rejecting order...');
        this.orderService.rejectOrder(order.id, result.value).subscribe({
          next: (updatedOrder) => {
            const orderIndex = this.orders.findIndex(o => o.id === order.id);
            if (orderIndex !== -1) {
              this.orders[orderIndex] = updatedOrder;
              this.updateOrderLists();
              this.applyFilter();
            }
            this.swal.close();
            this.swal.success('Order Rejected', `Order #${order.orderNumber} has been rejected.`);
          },
          error: (error) => {
            console.error('Error rejecting order:', error);
            this.swal.close();
            this.swal.error('Error', 'Failed to reject order. Please try again.');
          }
        });
      }
    });
  }

  cancelOrder(order: ShopOwnerOrder): void {
    // Define predefined cancellation reasons
    const cancelReasons = [
      'Item out of stock',
      'Customer request',
      'Damaged items',
      'Wrong items packed',
      'Unable to prepare on time',
      'Other (please specify)'
    ];

    // Create options HTML for SweetAlert
    const reasonsHtml = cancelReasons
      .map((reason, index) => `
        <label style="display: block; margin: 8px 0; cursor: pointer;">
          <input type="radio" name="cancelReason" value="${reason}" ${index === 0 ? 'checked' : ''} style="margin-right: 8px;">
          <span>${reason}</span>
        </label>
      `)
      .join('');

    this.swal.custom({
      title: 'Cancel Order',
      html: `
        <div style="text-align: left; padding: 10px 0;">
          <p style="margin-bottom: 15px; font-weight: 500;">Why are you cancelling this order?</p>
          <div style="border: 1px solid #ddd; padding: 12px; border-radius: 4px; max-height: 250px; overflow-y: auto;">
            ${reasonsHtml}
          </div>
          <textarea id="customReason" placeholder="If 'Other', please specify reason here..." style="width: 100%; margin-top: 12px; padding: 8px; border: 1px solid #ddd; border-radius: 4px; display: none; min-height: 60px;" maxlength="255"></textarea>
        </div>
      `,
      showCancelButton: true,
      confirmButtonText: 'Cancel Order',
      cancelButtonText: 'Go Back',
      confirmButtonColor: '#ef4444',
      didOpen: () => {
        // Add event listener for radio button changes
        const radioButtons = document.querySelectorAll('input[name="cancelReason"]');
        const customReasonTextarea = document.getElementById('customReason') as HTMLTextAreaElement;

        radioButtons.forEach((radio: any) => {
          radio.addEventListener('change', (e: any) => {
            if (e.target.value === 'Other (please specify)') {
              customReasonTextarea.style.display = 'block';
            } else {
              customReasonTextarea.style.display = 'none';
            }
          });
        });
      },
      inputValidator: () => {
        const selectedReason = (document.querySelector('input[name="cancelReason"]:checked') as any)?.value;
        const customReasonTextarea = document.getElementById('customReason') as HTMLTextAreaElement;

        if (!selectedReason) {
          return 'Please select a cancellation reason';
        }

        if (selectedReason === 'Other (please specify)' && !customReasonTextarea.value.trim()) {
          return 'Please specify the reason';
        }

        return null;
      }
    }).then((result) => {
      if (result.isConfirmed) {
        const selectedReason = (document.querySelector('input[name="cancelReason"]:checked') as any)?.value;
        const customReasonTextarea = document.getElementById('customReason') as HTMLTextAreaElement;

        const cancellationReason = selectedReason === 'Other (please specify)'
          ? customReasonTextarea.value.trim()
          : selectedReason;

        this.swal.loading('Cancelling order...');
        this.orderService.cancelOrder(order.id, cancellationReason).subscribe({
          next: (updatedOrder) => {
            const orderIndex = this.orders.findIndex(o => o.id === order.id);
            if (orderIndex !== -1) {
              this.orders[orderIndex] = updatedOrder;
              this.updateOrderLists();
              this.applyFilter();
            }
            this.swal.close();
            this.swal.success('Order Cancelled', `Order #${order.orderNumber} has been cancelled successfully.`);
          },
          error: (error) => {
            console.error('Error cancelling order:', error);
            this.swal.close();
            // Extract proper error message
            let errorMsg = 'Failed to cancel order. Please try again.';
            if (error?.error?.message) {
              errorMsg = error.error.message;
            } else if (error?.message && typeof error.message === 'string' &&
                       !error.message.includes('Http failure')) {
              errorMsg = error.message;
            }
            this.swal.error('Error', errorMsg);
          }
        });
      }
    });
  }

  startPreparing(orderId: number): void {
    this.startProcessing(orderId);
    this.orderService.startPreparing(orderId).subscribe({
      next: (updatedOrder) => {
        const orderIndex = this.orders.findIndex(o => o.id === orderId);
        if (orderIndex !== -1) {
          this.orders[orderIndex] = updatedOrder;
          this.updateOrderLists();
        }
        this.stopProcessing(orderId);
        this.swal.toast('Preparation started', 'success');
      },
      error: (error) => {
        console.error('Error starting preparation:', error);
        this.stopProcessing(orderId);
        this.swal.error('Error', 'Failed to start preparation. Please try again.');
      }
    });
  }

  markReady(orderId: number): void {
    this.startProcessing(orderId);
    this.orderService.markReady(orderId).subscribe({
      next: (updatedOrder) => {
        const orderIndex = this.orders.findIndex(o => o.id === orderId);
        if (orderIndex !== -1) {
          this.orders[orderIndex] = updatedOrder;
          this.updateOrderLists();
        }
        this.stopProcessing(orderId);

        // For HOME_DELIVERY, start polling for driver assignment
        if (updatedOrder.deliveryType === 'HOME_DELIVERY') {
          this.searchingDriverOrders.add(orderId);
          this.swal.toast('Searching for driver...', 'info');
          this.pollForDriverAssignment(orderId);
        } else {
          this.swal.toast('Order ready for pickup', 'success');
        }
      },
      error: (error) => {
        console.error('Error marking ready:', error);
        this.stopProcessing(orderId);
        this.swal.error('Error', 'Failed to mark order as ready. Please try again.');
      }
    });
  }

  // Poll for driver assignment status
  private pollForDriverAssignment(orderId: number, attempts: number = 0): void {
    const maxAttempts = 10; // Poll for up to 15 seconds (10 * 1.5s)
    const pollInterval = 1500; // 1.5 seconds

    if (attempts >= maxAttempts) {
      this.searchingDriverOrders.delete(orderId);
      // Final check - driver might not have been found
      this.refreshSingleOrder(orderId);
      return;
    }

    setTimeout(() => {
      this.orderService.getOrderById(orderId).subscribe({
        next: (order) => {
          const orderIndex = this.orders.findIndex(o => o.id === orderId);
          if (orderIndex !== -1) {
            this.orders[orderIndex] = order;
            this.updateOrderLists();
          }

          if (order.assignedToDeliveryPartner) {
            // Driver found!
            this.searchingDriverOrders.delete(orderId);
            this.swal.success('Driver Assigned!', 'A delivery partner has been assigned. Please verify pickup OTP.');
          } else {
            // Keep polling
            this.pollForDriverAssignment(orderId, attempts + 1);
          }
        },
        error: (error) => {
          console.error('Error polling for driver assignment:', error);
          this.searchingDriverOrders.delete(orderId);
        }
      });
    }, pollInterval);
  }

  // Refresh a single order without reloading all
  private refreshSingleOrder(orderId: number): void {
    this.orderService.getOrderById(orderId).subscribe({
      next: (order) => {
        const orderIndex = this.orders.findIndex(o => o.id === orderId);
        if (orderIndex !== -1) {
          this.orders[orderIndex] = order;
          this.updateOrderLists();
        }
      },
      error: (error) => {
        console.error('Error refreshing order:', error);
      }
    });
  }

  // Check if order is searching for driver
  isSearchingDriver(orderId: number): boolean {
    return this.searchingDriverOrders.has(orderId);
  }

  // Check if order is being processed
  isProcessingOrder(orderId: number): boolean {
    return this.processingOrderIds.has(orderId);
  }

  // Start processing an order
  private startProcessing(orderId: number): void {
    this.processingOrderIds.add(orderId);
  }

  // Stop processing an order
  private stopProcessing(orderId: number): void {
    this.processingOrderIds.delete(orderId);
  }

  markPickedUp(orderId: number): void {
    this.orderService.markDelivered(orderId).subscribe({
      next: (updatedOrder) => {
        const orderIndex = this.orders.findIndex(o => o.id === orderId);
        if (orderIndex !== -1) {
          this.orders[orderIndex] = updatedOrder;
          this.updateOrderLists();
        }
        this.swal.toast('Order marked as delivered', 'success');
      },
      error: (error) => {
        console.error('Error marking delivered:', error);
        this.swal.error('Error', 'Failed to mark order as delivered.');
      }
    });
  }

  // Handover SELF_PICKUP order to customer
  handoverSelfPickup(orderId: number): void {
    this.swal.confirm(
      'Handover Order',
      'Are you sure you want to handover this order to the customer?',
      'Yes, Handover',
      'Cancel'
    ).then((result) => {
      if (result.isConfirmed) {
        this.swal.loading('Processing handover...');
        this.orderService.handoverSelfPickup(orderId).subscribe({
          next: (response) => {
            const orderIndex = this.orders.findIndex(o => o.id === orderId);
            if (orderIndex !== -1) {
              this.orders[orderIndex].status = 'SELF_PICKUP_COLLECTED';
              this.updateOrderLists();
            }
            this.swal.close();
            this.swal.success('Order Handed Over!', 'Order has been successfully handed over to the customer.');
            this.loadOrders();
          },
          error: (error) => {
            console.error('Error handing over order:', error);
            this.swal.close();
            this.swal.error('Error', error.error?.message || 'Failed to handover order. Please try again.');
          }
        });
      }
    });
  }

  // Verify pickup OTP for HOME_DELIVERY order
  verifyPickupOTP(orderId: number): void {
    this.swal.custom({
      title: 'Verify Pickup OTP',
      text: 'Enter the 4-digit OTP shown by the delivery partner:',
      input: 'text',
      inputPlaceholder: 'Enter 4-digit OTP...',
      showCancelButton: true,
      confirmButtonText: 'Verify',
      cancelButtonText: 'Cancel',
      confirmButtonColor: '#FF9800',
      inputValidator: (value) => {
        if (!value) {
          return 'You need to enter the OTP!';
        }
        if (value.trim().length !== 4) {
          return 'Please enter a valid 4-digit OTP';
        }
        return null;
      }
    }).then((result: any) => {
      if (result.isConfirmed && result.value) {
        const otp = result.value.trim();

        this.swal.loading('Verifying OTP...');
        this.orderService.verifyPickupOTP(orderId, otp).subscribe({
          next: (response) => {
            const orderIndex = this.orders.findIndex(o => o.id === orderId);
            if (orderIndex !== -1) {
              this.orders[orderIndex].status = 'OUT_FOR_DELIVERY';
              this.updateOrderLists();
            }
            this.swal.close();
            this.swal.success('OTP Verified!', 'Order handed over to delivery partner successfully.');
            this.loadOrders();
          },
          error: (error) => {
            console.error('Error verifying OTP:', error);
            this.swal.close();
            this.swal.error('Invalid OTP', error.error?.message || 'The OTP you entered is incorrect. Please try again.');
          }
        });
      }
    });
  }

  quickAccept(order: ShopOwnerOrder): void {
    this.acceptOrder(order);
  }

  quickReject(order: ShopOwnerOrder): void {
    this.rejectOrder(order);
  }

  moveToNextStage(orderId: number): void {
    const order = this.orders.find(o => o.id === orderId);
    if (order) {
      switch (order.status) {
        case 'CONFIRMED':
          this.startPreparing(orderId);
          break;
        case 'PREPARING':
          this.markReady(orderId); // This will auto-assign delivery partner
          break;
        // Removed READY_FOR_PICKUP case as assignment is automatic
      }
    }
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'PENDING': return 'warn';
      case 'CONFIRMED': return 'primary';
      case 'PREPARING': return 'accent';
      case 'READY_FOR_PICKUP': return 'primary';
      case 'DELIVERED': return 'primary';
      case 'CANCELLED': return 'warn';
      default: return 'basic';
    }
  }

  isUrgent(createdAt: string): boolean {
    const now = new Date();
    const orderDate = new Date(createdAt);
    const diffMinutes = (now.getTime() - orderDate.getTime()) / (1000 * 60);
    return diffMinutes > 15; // Orders older than 15 minutes are urgent
  }

  getTimeAgo(createdAt: string): string {
    const now = new Date();
    const orderDate = new Date(createdAt);
    const diffMinutes = Math.floor((now.getTime() - orderDate.getTime()) / (1000 * 60));
    if (diffMinutes < 1) return 'Just now';
    if (diffMinutes < 60) return `${diffMinutes} min ago`;
    const diffHours = Math.floor(diffMinutes / 60);
    return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
  }

  getEstimatedTime(status: string): number {
    switch (status) {
      case 'CONFIRMED': return 25;
      case 'PREPARING': return 15;
      case 'READY_FOR_PICKUP': return 5;
      default: return 0;
    }
  }

  getNextStageAction(status: string): string {
    switch (status) {
      case 'CONFIRMED': return 'Start Preparing';
      case 'PREPARING': return 'Mark Ready';
      default: return 'Next Stage';
    }
  }

  shouldShowNextStageButton(status: string): boolean {
    // Hide button for orders that are ready for pickup or beyond
    return status === 'CONFIRMED' || status === 'PREPARING';
  }

  getStatusLabel(status: string): string {
    // Convert status to readable format
    switch (status) {
      case 'PENDING': return 'Pending';
      case 'CONFIRMED': return 'Confirmed';
      case 'PREPARING': return 'Preparing';
      case 'READY_FOR_PICKUP': return 'Ready for Pickup';
      case 'OUT_FOR_DELIVERY': return 'Out for Delivery';
      case 'DELIVERED': return 'Delivered';
      case 'CANCELLED': return 'Cancelled';
      case 'RETURNING_TO_SHOP': return 'Driver Returning';
      case 'RETURNED_TO_SHOP': return 'Products Returned';
      case 'SELF_PICKUP_COLLECTED': return 'Collected';
      default: return status.replace(/_/g, ' ');
    }
  }


  printOrder(orderId: number): void {
    const order = this.orders.find(o => o.id === orderId);
    if (!order) {
      this.swal.error('Error', 'Order not found');
      return;
    }

    // Create printable content
    const printContent = this.generatePrintContent(order);

    // Open print window
    const printWindow = window.open('', '_blank', 'width=800,height=600');
    if (printWindow) {
      printWindow.document.write(printContent);
      printWindow.document.close();
      printWindow.focus();
      printWindow.print();
      printWindow.close();
    }

    this.swal.toast(`Order #${order.orderNumber} sent to printer`, 'success');
  }

  // Small print for thermal/receipt printers (58mm/80mm)
  printOrderSmall(orderId: number): void {
    const order = this.orders.find(o => o.id === orderId);
    if (!order) {
      this.swal.error('Error', 'Order not found');
      return;
    }

    // Create small receipt content
    const printContent = this.generateSmallPrintContent(order);

    // Open print window with smaller size
    const printWindow = window.open('', '_blank', 'width=300,height=600');
    if (printWindow) {
      printWindow.document.write(printContent);
      printWindow.document.close();
      printWindow.focus();
      printWindow.print();
      printWindow.close();
    }

    this.swal.toast(`Receipt sent to printer`, 'success');
  }

  generateSmallPrintContent(order: ShopOwnerOrder): string {
    const itemsHtml = order.items.map(item => {
      const unitPrice = item.price || item.unitPrice || 0;
      const totalPrice = item.total || item.totalPrice || (item.quantity * unitPrice) || 0;
      const englishName = item.name || item.productName || '';
      const tamilName = item.productNameTamil || '';
      // Show Tamil name below English name if available
      const nameHtml = tamilName
        ? `${englishName}<br><span style="font-size: 8px; color: #333;">${tamilName}</span>`
        : englishName;
      return `
        <tr>
          <td style="font-size: 9px; padding: 2px 0; font-weight: 600; word-wrap: break-word; max-width: 60px;">${nameHtml}</td>
          <td style="font-size: 9px; text-align: right; padding: 2px 0; font-weight: 600; white-space: nowrap;">${unitPrice}</td>
          <td style="font-size: 9px; text-align: center; padding: 2px 0; font-weight: 700; white-space: nowrap;">${item.quantity}</td>
          <td style="font-size: 9px; text-align: right; padding: 2px 0; font-weight: 700; white-space: nowrap;">${totalPrice}</td>
        </tr>
      `;
    }).join('');

    // Get shop name from order or localStorage
    const shopName = order.shopName || localStorage.getItem('shop_name') || 'NammaOoru';

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Receipt - ${order.orderNumber}</title>
        <style>
          @page {
            size: 58mm auto;
            margin: 1mm;
          }
          @media print {
            body {
              -webkit-print-color-adjust: exact;
              print-color-adjust: exact;
            }
          }
          body {
            font-family: 'Noto Sans Tamil', 'Latha', 'Tamil Sangam MN', Arial, sans-serif;
            font-size: 11px;
            width: 180px;
            max-width: 180px;
            margin: 0 auto;
            padding: 8px;
            line-height: 1.3;
          }
          .center { text-align: center; }
          .bold { font-weight: bold; }
          .divider {
            border-top: 1px dashed #000;
            margin: 6px 0;
          }
          .divider-solid {
            border-top: 1px solid #000;
            margin: 6px 0;
          }
          table { width: 100%; border-collapse: collapse; }
          .total-row {
            font-weight: bold;
            font-size: 14px;
            border-top: 1px solid #000;
            padding-top: 6px;
            margin-top: 6px;
          }
          .shop-name {
            font-family: 'Noto Sans Tamil', 'Latha', 'Tamil Sangam MN', Arial, sans-serif;
            font-size: 14px;
            font-weight: 700;
            margin-bottom: 3px;
          }
          .order-number {
            font-size: 12px;
            font-weight: 700;
            background: #000;
            color: #fff;
            padding: 4px 8px;
            display: inline-block;
            border-radius: 3px;
            margin: 4px 0;
          }
          .customer-name {
            font-size: 12px;
            font-weight: 700;
          }
          .customer-phone {
            font-size: 10px;
            color: #333;
          }
          .item-header th {
            font-size: 10px;
            padding: 4px 0;
            border-bottom: 1px solid #000;
            text-transform: uppercase;
            font-weight: 700;
          }
          .payment-badge {
            font-size: 10px;
            font-weight: 700;
            padding: 4px 8px;
            background: #f0f0f0;
            border-radius: 3px;
            display: inline-block;
            margin: 4px 0;
          }
          .footer-text {
            font-size: 9px;
            color: #666;
            margin-top: 6px;
          }
          .flex-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
          }
        </style>
      </head>
      <body>
        <div class="center shop-name">${shopName}</div>
        <div class="center" style="font-size: 9px; color: #666;">Order Receipt</div>
        <div class="divider"></div>

        <div class="center">
          <div class="order-number">#${order.orderNumber}</div>
        </div>
        <div style="font-size: 9px; text-align: center; margin-bottom: 4px;">
          ${new Date(order.createdAt).toLocaleDateString('en-IN', {day: '2-digit', month: 'short', year: 'numeric'})} | ${new Date(order.createdAt).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
        </div>
        <div class="divider"></div>

        <div style="margin-bottom: 4px;">
          <div class="customer-name">${order.customerName}</div>
          <div class="customer-phone">${order.customerPhone || ''}</div>
        </div>
        <div class="divider"></div>

        <table>
          <thead>
            <tr class="item-header">
              <th style="text-align: left;">ITEM</th>
              <th style="text-align: right;">RATE</th>
              <th style="text-align: center;">QTY</th>
              <th style="text-align: right;">AMT</th>
            </tr>
          </thead>
          <tbody>
            ${itemsHtml}
          </tbody>
        </table>
        <div class="divider-solid"></div>

        <div class="flex-row" style="font-size: 10px; padding: 4px 0;">
          <span style="font-weight: 600;">Items: ${order.items?.length || 0}</span>
          <span style="font-weight: 700;">₹${order.totalAmount || 0}</span>
        </div>

        <div class="flex-row" style="border-top: 1px solid #000; padding-top: 6px; margin-top: 4px;">
          <span style="font-size: 14px; font-weight: 700;">TOTAL</span>
          <span style="font-size: 16px; font-weight: 700;">₹${order.totalAmount || 0}</span>
        </div>

        <div class="divider"></div>
        <div class="center">
          <span class="payment-badge">
            ${order.paymentMethod === 'CASH_ON_DELIVERY' ? '💵 CASH ON DELIVERY' : '✓ PAID ONLINE'}
          </span>
        </div>
        <div class="divider"></div>

        <div class="center footer-text">
          Thank you for your order!<br>
          Printed: ${new Date().toLocaleString('en-IN')}
        </div>
      </body>
      </html>
    `;
  }

  generatePrintContent(order: ShopOwnerOrder): string {
    const itemsHtml = order.items.map(item => `
      <tr>
        <td>${item.name || item.productName}</td>
        <td style="text-align: center;">${item.quantity}</td>
        <td style="text-align: right;">₹${item.price || item.unitPrice}</td>
        <td style="text-align: right;">₹${item.total || item.totalPrice}</td>
      </tr>
    `).join('');

    // Get shop name from localStorage or use default
    const shopName = localStorage.getItem('shop_name') || 'NammaOoru';

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Order #${order.orderNumber}</title>
        <style>
          body { font-family: 'Noto Sans Tamil', 'Latha', 'Tamil Sangam MN', Arial, sans-serif; padding: 20px; }
          .header { text-align: center; margin-bottom: 30px; }
          .order-info { margin-bottom: 20px; }
          .customer-info { margin-bottom: 20px; }
          table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
          th, td { padding: 8px; border: 1px solid #ddd; }
          th { background-color: #f5f5f5; }
          .total { font-weight: bold; font-size: 16px; }
          .footer { margin-top: 30px; text-align: center; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>${shopName}</h1>
          <h2>Order #${order.orderNumber}</h2>
        </div>

        <div class="order-info">
          <p><strong>Date:</strong> ${new Date(order.createdAt).toLocaleString()}</p>
          <p><strong>Status:</strong> ${this.getStatusLabel(order.status)}</p>
          <p><strong>Payment Method:</strong> ${order.paymentMethod === 'CASH_ON_DELIVERY' ? 'Cash on Delivery' : 'Paid Online'}</p>
        </div>

        <div class="customer-info">
          <h3>Customer Details</h3>
          <p><strong>Name:</strong> ${order.customerName}</p>
          <p><strong>Phone:</strong> ${order.customerPhone}</p>
          <p><strong>Address:</strong> ${order.customerAddress || order.deliveryAddress}</p>
        </div>

        <h3>Order Items</h3>
        <table>
          <thead>
            <tr>
              <th>Item</th>
              <th>Quantity</th>
              <th>Unit Price</th>
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            ${itemsHtml}
          </tbody>
          <tfoot>
            <tr class="total">
              <td colspan="3">Total Amount</td>
              <td style="text-align: right;">₹${order.totalAmount}</td>
            </tr>
          </tfoot>
        </table>

        <div class="footer">
          <p>Thank you for your order!</p>
          <p>Printed on: ${new Date().toLocaleString()}</p>
        </div>
      </body>
      </html>
    `;
  }

  viewCustomer(customerId: number): void {
    this.swal.info('Coming Soon', 'Customer details feature is under development.');
  }

  refundOrder(orderId: number): void {
    this.swal.info('Refund Initiated', 'Refund process has been started.');
  }

  reportIssue(orderId: number): void {
    this.swal.info('Coming Soon', 'Issue reporting feature is under development.');
  }

  assignDeliveryPartner(orderId: number): void {
    this.isAssigningPartner = true;

    // For now, we'll auto-assign to available partner
    // Later this can be enhanced with a partner selection dialog
    const assignedBy = 1; // TODO: Should get from auth service - current user ID

    this.assignmentService.autoAssignOrder(orderId, assignedBy).subscribe({
      next: (response) => {
        this.isAssigningPartner = false;

        if (response.success && response.assignment) {
          // Update order status
          const orderIndex = this.orders.findIndex(o => o.id === orderId);
          if (orderIndex !== -1) {
            this.orders[orderIndex].status = 'OUT_FOR_DELIVERY';
            this.updateOrderLists();
          }

          this.swal.success('Order Assigned', `Order assigned to ${response.assignment.deliveryPartner.name}`);
        } else {
          this.swal.error('Assignment Failed', response.message || 'Failed to assign delivery partner');
        }
      },
      error: (error) => {
        this.isAssigningPartner = false;
        console.error('Error assigning delivery partner:', error);
        this.swal.error('Error', 'Failed to assign delivery partner. Please try again.');
      }
    });
  }

  onPageChange(event: any): void {
    // Handle pagination
  }

  verifyDriver(orderId: number, verificationCode: string): void {
    if (!verificationCode || verificationCode.length < 4) {
      this.swal.warning('Invalid Code', 'Please enter a valid verification code');
      return;
    }

    // Call the verification service/API
    this.orderService.verifyDriverForPickup(orderId, verificationCode).subscribe({
      next: (response) => {
        if (response.success) {
          // Update order status locally
          const orderIndex = this.orders.findIndex(o => o.id === orderId);
          if (orderIndex !== -1) {
            this.orders[orderIndex].driverVerified = true;
            this.updateOrderLists();
          }

          this.swal.success('Driver Verified!', 'Order can be handed over to the delivery partner.');

          // Clear the verification code
          delete this.verificationCodes[orderId];
        } else {
          this.swal.error('Verification Failed', response.message || 'Invalid verification code');
        }
      },
      error: (error) => {
        console.error('Error verifying driver:', error);
        this.swal.error('Error', 'Failed to verify driver. Please try again.');
      }
    });
  }

  // ===== ADDITIONAL METHODS FOR NEW UI =====

  getStatusClass(status: string): string {
    switch (status) {
      case 'PENDING': return 'status-pending';
      case 'CONFIRMED': return 'status-confirmed';
      case 'PREPARING': return 'status-preparing';
      case 'READY_FOR_PICKUP': return 'status-ready';
      case 'OUT_FOR_DELIVERY': return 'status-delivery';
      case 'DELIVERED': return 'status-delivered';
      case 'CANCELLED': return 'status-cancelled';
      case 'RETURNING_TO_SHOP': return 'status-returning';
      case 'RETURNED_TO_SHOP': return 'status-returned';
      case 'SELF_PICKUP_COLLECTED': return 'status-collected';
      default: return '';
    }
  }

  assignDelivery(orderId: number): void {
    this.assignDeliveryPartner(orderId);
  }

  viewOrderDetails(order: ShopOwnerOrder): void {
    // Create detailed view content
    const detailsContent = this.generateOrderDetailsContent(order);

    // Open details window
    const detailsWindow = window.open('', '_blank', 'width=900,height=700,scrollbars=yes');
    if (detailsWindow) {
      detailsWindow.document.write(detailsContent);
      detailsWindow.document.close();
      detailsWindow.focus();
    }

    this.successMessage = `Viewing details for Order #${order.orderNumber}`;
    setTimeout(() => this.successMessage = '', 3000);
  }

  generateOrderDetailsContent(order: ShopOwnerOrder): string {
    const itemsHtml = order.items.map(item => {
      const unitPrice = item.price || item.unitPrice || 0;
      const totalPrice = item.quantity * unitPrice;

      const imageHtml = (item.image || item.productImageUrl)
        ? `<img src="${this.getImageUrl(item.image || item.productImageUrl || '')}" alt="${item.name || item.productName}" style="width: 50px; height: 50px; object-fit: cover; border-radius: 4px; margin-right: 10px;">`
        : `<div style="width: 50px; height: 50px; background: #ecf0f1; border-radius: 4px; display: flex; align-items: center; justify-content: center; margin-right: 10px; font-size: 18px; color: #7f8c8d; font-weight: bold;">${(item.name || item.productName || 'P')[0].toUpperCase()}</div>`;

      return `
        <tr>
          <td style="display: flex; align-items: center; padding: 12px;">
            ${imageHtml}
            <div>
              <div style="font-weight: 600; margin-bottom: 4px; color: #2c3e50;">${item.name || item.productName}</div>
              <div style="color: #7f8c8d; font-size: 12px;">Unit Price: ₹${unitPrice}</div>
            </div>
          </td>
          <td style="text-align: center; font-weight: 600; color: #3498db;">${item.quantity}</td>
          <td style="text-align: center; color: #7f8c8d;">${item.quantity} × ₹${unitPrice}</td>
          <td style="text-align: right; font-weight: 700; color: #2c3e50;">₹${totalPrice.toFixed(0)}</td>
        </tr>
      `;
    }).join('');

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <title>Order Details - #${order.orderNumber}</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            padding: 20px;
            background: #f5f6fa;
            margin: 0;
          }
          .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(44, 62, 80, 0.08);
            overflow: hidden;
          }
          .header {
            background: #2c3e50;
            color: white;
            padding: 24px;
            text-align: center;
          }
          .content { padding: 24px; }
          .section {
            margin-bottom: 24px;
            background: #ecf0f1;
            padding: 16px;
            border-radius: 6px;
            border-left: 3px solid #3498db;
          }
          .section h3 {
            margin: 0 0 12px 0;
            color: #2c3e50;
            font-size: 16px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
          }
          .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 12px;
          }
          .info-item {
            background: white;
            padding: 12px;
            border-radius: 4px;
            border: 1px solid #dfe6e9;
          }
          .info-label {
            font-weight: 500;
            color: #7f8c8d;
            font-size: 11px;
            text-transform: uppercase;
            margin-bottom: 4px;
            letter-spacing: 0.5px;
          }
          .info-value {
            color: #2c3e50;
            font-weight: 600;
          }
          table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 6px;
            overflow: hidden;
            box-shadow: 0 1px 3px rgba(44, 62, 80, 0.08);
          }
          th {
            background: #34495e;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 500;
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
          }
          td {
            padding: 12px;
            border-bottom: 1px solid #ecf0f1;
          }
          tr:last-child td {
            border-bottom: none;
          }
          .status-badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.5px;
          }
          .status-pending { background: rgba(52, 152, 219, 0.15); color: #2980b9; border: 1px solid rgba(52, 152, 219, 0.3); }
          .status-confirmed { background: rgba(52, 152, 219, 0.1); color: #3498db; border: 1px solid #3498db; }
          .status-preparing { background: rgba(41, 128, 185, 0.1); color: #2980b9; border: 1px solid #2980b9; }
          .status-ready { background: rgba(44, 62, 80, 0.1); color: #2c3e50; border: 1px solid #2c3e50; }
          .status-delivered { background: #ecf0f1; color: #7f8c8d; border: 1px solid #dfe6e9; }
          .total-section {
            background: rgba(44, 62, 80, 0.05);
            border: 1px solid rgba(44, 62, 80, 0.1);
            color: #2c3e50;
            padding: 20px;
            border-radius: 6px;
            margin-top: 20px;
          }
          .print-btn {
            background: #2c3e50;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            font-weight: 500;
            margin-top: 20px;
            font-size: 14px;
          }
          .print-btn:hover {
            background: #34495e;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1 style="margin: 0 0 8px 0; font-size: 20px; font-weight: 600;">Order Details</h1>
            <h2 style="margin: 0 0 12px 0; font-size: 16px; font-weight: 400;">Order #${order.orderNumber}</h2>
            <div class="status-badge ${this.getStatusClass(order.status)}">
              ${this.getStatusLabel(order.status)}
            </div>
          </div>

          <div class="content">
            <div class="section">
              <h3>Order Information</h3>
              <div class="info-grid">
                <div class="info-item">
                  <div class="info-label">Order Date</div>
                  <div class="info-value">${new Date(order.createdAt).toLocaleString()}</div>
                </div>
                <div class="info-item">
                  <div class="info-label">Payment Method</div>
                  <div class="info-value">${order.paymentMethod === 'CASH_ON_DELIVERY' ? 'Cash on Delivery' : 'Online Payment'}</div>
                </div>
                <div class="info-item">
                  <div class="info-label">Payment Status</div>
                  <div class="info-value">${order.paymentStatus}</div>
                </div>
                <div class="info-item">
                  <div class="info-label">Total Amount</div>
                  <div class="info-value" style="font-size: 18px; font-weight: 700; color: #2c3e50;">₹${order.totalAmount}</div>
                </div>
              </div>
            </div>

            <div class="section">
              <h3>Customer Information</h3>
              <div class="info-grid">
                <div class="info-item">
                  <div class="info-label">Customer Name</div>
                  <div class="info-value">${order.customerName}</div>
                </div>
                <div class="info-item">
                  <div class="info-label">Phone Number</div>
                  <div class="info-value">${order.customerPhone || 'Not provided'}</div>
                </div>
                <div class="info-item">
                  <div class="info-label">Email</div>
                  <div class="info-value">${order.customerEmail || 'Not provided'}</div>
                </div>
                <div class="info-item">
                  <div class="info-label">Delivery Address</div>
                  <div class="info-value">${order.customerAddress || order.deliveryAddress || 'Not provided'}</div>
                </div>
              </div>
            </div>

            <div class="section">
              <h3>Order Items (${order.items?.length || 0})</h3>
              <table>
                <thead>
                  <tr>
                    <th>Item Details</th>
                    <th style="text-align: center;">Quantity</th>
                    <th style="text-align: center;">Calculation</th>
                    <th style="text-align: right;">Total</th>
                  </tr>
                </thead>
                <tbody>
                  ${itemsHtml}
                </tbody>
              </table>
            </div>

            <div class="total-section">
              <div style="display: flex; justify-content: space-between; align-items: center;">
                <div>
                  <div style="font-size: 16px; font-weight: 500; color: #7f8c8d;">Order Total</div>
                  <div style="font-size: 12px; color: #95a5a6;">${order.items?.length || 0} items</div>
                </div>
                <div style="font-size: 24px; font-weight: 600; color: #2c3e50;">₹${order.totalAmount}</div>
              </div>
            </div>

            <button class="print-btn" onclick="window.print()">Print Order Details</button>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  getItemIcon(itemName: string): string {
    if (!itemName) return '🍽️';

    const name = itemName.toLowerCase();
    if (name.includes('coffee')) return '☕';
    if (name.includes('tea')) return '🍵';
    if (name.includes('pizza')) return '🍕';
    if (name.includes('burger')) return '🍔';
    if (name.includes('cake')) return '🎂';
    if (name.includes('bread')) return '🍞';
    if (name.includes('milk')) return '🥛';
    if (name.includes('water')) return '💧';
    if (name.includes('juice')) return '🧃';
    if (name.includes('rice')) return '🍚';
    if (name.includes('chicken')) return '🍗';
    if (name.includes('fish')) return '🐟';
    if (name.includes('egg')) return '🥚';
    if (name.includes('fruit')) return '🍎';
    if (name.includes('vegetable')) return '🥕';
    if (name.includes('abc')) return '🥤';
    return '🍽️';
  }

  selectStatusTab(status: string): void {
    this.selectedStatus = status;
    this.applyFilter();
  }

  getOrdersByStatus(status: string): ShopOwnerOrder[] {
    return this.orders.filter(order => order.status === status);
  }

  // Get all return orders (RETURNING_TO_SHOP and RETURNED_TO_SHOP)
  getReturnOrders(): ShopOwnerOrder[] {
    return this.orders.filter(order =>
      order.status === 'RETURNING_TO_SHOP' || order.status === 'RETURNED_TO_SHOP'
    );
  }

  // Get all self-pickup orders
  getSelfPickupOrders(): ShopOwnerOrder[] {
    return this.orders.filter(order => order.deliveryType === 'SELF_PICKUP');
  }

  // Get all walk-in/POS orders (offline counter sales)
  getWalkInOrders(): ShopOwnerOrder[] {
    return this.orders.filter(order => (order as any).orderType === 'WALK_IN');
  }

  // Get all online orders
  getOnlineOrders(): ShopOwnerOrder[] {
    return this.orders.filter(order => (order as any).orderType !== 'WALK_IN');
  }

  // Switch main tab between realtime and history
  switchMainTab(tab: 'realtime' | 'history'): void {
    this.mainTab = tab;
    if (tab === 'realtime') {
      this.selectedStatus = 'REALTIME_ALL';
    } else {
      this.selectedStatus = 'HISTORY_ALL';
    }
    this.applyFilter();
  }

  // Get count of real-time orders (active orders needing action)
  getRealtimeOrdersCount(): number {
    const realtimeStatuses = ['PENDING', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'PICKED_UP', 'OUT_FOR_DELIVERY', 'RETURNING_TO_SHOP', 'RETURNED_TO_SHOP'];
    return this.orders.filter(order => realtimeStatuses.includes(order.status)).length;
  }

  // Get count of history orders (completed/cancelled)
  getHistoryOrdersCount(): number {
    const historyStatuses = ['DELIVERED', 'CANCELLED', 'SELF_PICKUP_COLLECTED'];
    return this.orders.filter(order => historyStatuses.includes(order.status)).length;
  }

  // Get real-time orders (active)
  getRealtimeOrders(): ShopOwnerOrder[] {
    const realtimeStatuses = ['PENDING', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'PICKED_UP', 'OUT_FOR_DELIVERY', 'RETURNING_TO_SHOP', 'RETURNED_TO_SHOP'];
    return this.orders.filter(order => realtimeStatuses.includes(order.status));
  }

  // Get history orders (completed/cancelled)
  getHistoryOrders(): ShopOwnerOrder[] {
    const historyStatuses = ['DELIVERED', 'CANCELLED', 'SELF_PICKUP_COLLECTED'];
    return this.orders.filter(order => historyStatuses.includes(order.status));
  }

  // Get active self pickup orders (not yet collected)
  getActiveSelfPickupOrders(): ShopOwnerOrder[] {
    const activeStatuses = ['PENDING', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP'];
    return this.orders.filter(order =>
      order.deliveryType === 'SELF_PICKUP' && activeStatuses.includes(order.status)
    );
  }

  // Retry driver search for orders without assigned driver
  retryDriverSearch(orderId: number): void {
    this.swal.loading('Searching for available drivers...');

    this.http.post<any>(`${environment.apiUrl}/orders/${orderId}/retry-driver-search`, {}).subscribe({
      next: (response) => {
        this.swal.close();
        if (response.data?.driverAssigned) {
          this.swal.success('Driver Found!', 'A delivery partner has been assigned to this order.');
        } else {
          this.swal.custom({
            icon: 'warning',
            title: 'Searching for Drivers',
            text: response.data?.message || 'We are looking for available drivers. Please wait or try again later.',
            confirmButtonText: 'OK'
          });
        }
        this.loadOrders(); // Refresh orders
      },
      error: (error) => {
        console.error('Error retrying driver search:', error);
        this.swal.close();
        this.swal.error('Error', error.error?.message || 'Failed to search for drivers. Please try again.');
      }
    });
  }

  // Confirm return receipt - collect products from driver
  confirmReturnReceipt(orderId: number): void {
    this.swal.custom({
      icon: 'question',
      title: 'Verify & Collect Products',
      html: `
        <div style="text-align: left; padding: 10px;">
          <p style="margin-bottom: 15px;">Please verify the following before confirming:</p>
          <ul style="margin: 0; padding-left: 20px; color: #666;">
            <li style="margin-bottom: 8px;">All items have been returned</li>
            <li style="margin-bottom: 8px;">Products are in good condition</li>
            <li style="margin-bottom: 8px;">Quantities match the order</li>
          </ul>
          <p style="margin-top: 15px; font-size: 13px; color: #888;">
            Stock will be automatically restored after confirmation.
          </p>
        </div>
      `,
      showCancelButton: true,
      confirmButtonText: 'Confirm Collection',
      cancelButtonText: 'Cancel',
      confirmButtonColor: '#4CAF50'
    }).then((result) => {
      if (result.isConfirmed) {
        this.swal.loading('Processing return receipt...');

        this.http.post<any>(`${environment.apiUrl}/orders/${orderId}/confirm-return-receipt`, {}).subscribe({
          next: (response) => {
            this.swal.close();
            this.swal.success('Products Collected!', 'Return receipt confirmed and stock has been restored.');
            this.loadOrders(); // Refresh orders
          },
          error: (error) => {
            console.error('Error confirming return receipt:', error);
            this.swal.close();
            this.swal.error('Error', error.error?.message || 'Failed to confirm return receipt. Please try again.');
          }
        });
      }
    });
  }

  getImageUrl(imageUrl: string): string {
    return getImageUrlUtil(imageUrl);
  }

  onImageError(event: any): void {
    // Hide the image and show fallback icon when image fails to load
    const imgElement = event.target;
    if (imgElement) {
      imgElement.style.display = 'none';
      // You could also show a fallback icon here
      const container = imgElement.parentElement;
      if (container && !container.querySelector('.fallback-icon')) {
        const fallbackIcon = document.createElement('div');
        fallbackIcon.className = 'item-icon fallback-icon';
        fallbackIcon.textContent = '🍽️'; // Default food icon
        container.appendChild(fallbackIcon);
      }
    }
  }

  // Format date/time in Indian format (d/M/yy, h:mm AM/PM)
  formatOrderTime(dateString: string): string {
    if (!dateString) return '';
    const d = new Date(dateString);
    const day = d.getDate();
    const month = d.getMonth() + 1;
    let hours = d.getHours();
    const minutes = d.getMinutes().toString().padStart(2, '0');
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12 || 12;
    return `${day}/${month}, ${hours}:${minutes} ${ampm}`;
  }

  // Remove item from existing order
  removeItemFromOrder(order: ShopOwnerOrder, item: any): void {
    // Prevent removing if order is not in editable status
    if (!['PENDING', 'CONFIRMED', 'PREPARING'].includes(order.status)) {
      this.swal.error('Cannot Remove Item', 'Items can only be removed from orders that are Pending, Confirmed, or Preparing.');
      return;
    }

    // Check if this is the last item
    if (order.items.length <= 1) {
      this.swal.error('Cannot Remove Item', 'Cannot remove the last item from an order. Cancel the order instead.');
      return;
    }

    this.swal.confirm(
      'Remove Item',
      `Are you sure you want to remove "${item.name || item.productName}" from this order?`,
      'Yes, Remove',
      'Cancel'
    ).then((result) => {
      if (result.isConfirmed) {
        this.swal.loading('Removing item...');

        this.orderService.removeItemFromOrder(order.id, item.id).subscribe({
          next: (updatedOrder) => {
            const orderIndex = this.orders.findIndex(o => o.id === order.id);
            if (orderIndex !== -1) {
              this.orders[orderIndex] = updatedOrder;
              this.updateOrderLists();
              this.applyFilter();
            }
            this.swal.close();
            this.swal.success('Item Removed', `Item removed from order #${order.orderNumber}. New total: ₹${updatedOrder.totalAmount}`);
          },
          error: (error) => {
            console.error('Error removing item from order:', error);
            this.swal.close();
            let errorMsg = 'Failed to remove item from order.';
            if (error?.error?.message) {
              errorMsg = error.error.message;
            }
            this.swal.error('Error', errorMsg);
          }
        });
      }
    });
  }

  // Open modal to add item to existing order
  openUpdateOrderModal(order: ShopOwnerOrder): void {
    if (!this.shopId) {
      this.swal.error('Error', 'Shop ID not found');
      return;
    }

    // Load shop products for dropdown
    this.productService.getShopProducts(this.shopId, 0, 100).subscribe({
      next: (products) => {
        if (!products || products.length === 0) {
          this.swal.error('No Products', 'No products found in your shop');
          return;
        }

        // Build product options HTML
        const productOptions = products.map((p: any) =>
          `<option value="${p.id}" data-price="${p.price}">${p.name || p.masterProduct?.name} - ₹${p.price}</option>`
        ).join('');

        Swal.fire({
          title: `Add Item to Order #${order.orderNumber}`,
          html: `
            <div style="text-align: left; padding: 10px 0;">
              <label style="font-weight: 600; margin-bottom: 8px; display: block;">Select Product:</label>
              <select id="productSelect" class="swal2-select" style="width: 100%; padding: 10px; border-radius: 6px; border: 1px solid #ddd; margin-bottom: 15px;">
                <option value="">-- Select Product --</option>
                ${productOptions}
              </select>

              <label style="font-weight: 600; margin-bottom: 8px; display: block;">Quantity:</label>
              <input type="number" id="quantityInput" class="swal2-input" min="1" value="1" style="width: 100%; margin: 0 0 15px 0;">

              <label style="font-weight: 600; margin-bottom: 8px; display: block;">Special Instructions (optional):</label>
              <textarea id="instructionsInput" class="swal2-textarea" placeholder="Any special instructions..." style="width: 100%; margin: 0;"></textarea>

              <div id="itemPreview" style="margin-top: 15px; padding: 12px; background: #f5f5f5; border-radius: 8px; display: none;">
                <strong>Item Total:</strong> <span id="itemTotal">₹0</span>
              </div>
            </div>
          `,
          showCancelButton: true,
          confirmButtonText: 'Add Item',
          confirmButtonColor: '#4CAF50',
          cancelButtonText: 'Cancel',
          didOpen: () => {
            const productSelect = document.getElementById('productSelect') as HTMLSelectElement;
            const quantityInput = document.getElementById('quantityInput') as HTMLInputElement;
            const itemPreview = document.getElementById('itemPreview') as HTMLElement;
            const itemTotal = document.getElementById('itemTotal') as HTMLElement;

            const updatePreview = () => {
              const selectedOption = productSelect.selectedOptions[0];
              if (selectedOption && selectedOption.value) {
                const price = parseFloat(selectedOption.getAttribute('data-price') || '0');
                const quantity = parseInt(quantityInput.value) || 1;
                const total = price * quantity;
                itemTotal.textContent = `₹${total.toFixed(0)}`;
                itemPreview.style.display = 'block';
              } else {
                itemPreview.style.display = 'none';
              }
            };

            productSelect.addEventListener('change', updatePreview);
            quantityInput.addEventListener('input', updatePreview);
          },
          preConfirm: () => {
            const productSelect = document.getElementById('productSelect') as HTMLSelectElement;
            const quantityInput = document.getElementById('quantityInput') as HTMLInputElement;
            const instructionsInput = document.getElementById('instructionsInput') as HTMLTextAreaElement;

            const shopProductId = parseInt(productSelect.value);
            const quantity = parseInt(quantityInput.value);
            const specialInstructions = instructionsInput.value.trim();

            if (!shopProductId) {
              Swal.showValidationMessage('Please select a product');
              return false;
            }
            if (!quantity || quantity < 1) {
              Swal.showValidationMessage('Quantity must be at least 1');
              return false;
            }

            return { shopProductId, quantity, specialInstructions };
          }
        }).then((result: any) => {
          if (result.isConfirmed && result.value) {
            const { shopProductId, quantity, specialInstructions } = result.value;

            this.swal.loading('Adding item to order...');

            this.orderService.addItemToOrder(order.id, shopProductId, quantity, specialInstructions).subscribe({
              next: (updatedOrder) => {
                const orderIndex = this.orders.findIndex(o => o.id === order.id);
                if (orderIndex !== -1) {
                  this.orders[orderIndex] = updatedOrder;
                  this.updateOrderLists();
                  this.applyFilter();
                }
                this.swal.close();
                this.swal.success('Item Added', `Item added to order #${order.orderNumber}. New total: ₹${updatedOrder.totalAmount}`);
              },
              error: (error) => {
                console.error('Error adding item to order:', error);
                this.swal.close();
                let errorMsg = 'Failed to add item to order.';
                if (error?.error?.message) {
                  errorMsg = error.error.message;
                }
                this.swal.error('Error', errorMsg);
              }
            });
          }
        });
      },
      error: (error) => {
        console.error('Error loading products:', error);
        this.swal.error('Error', 'Failed to load products');
      }
    });
  }
}