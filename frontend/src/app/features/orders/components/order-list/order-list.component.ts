import { Component, OnInit, OnDestroy, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Router } from '@angular/router';
import { OrderService, OrderResponse, PageResponse } from '../../../../core/services/order.service';
import { OrderStatusDialogComponent } from '../order-status-dialog/order-status-dialog.component';
import Swal from 'sweetalert2';
import { interval, Subscription } from 'rxjs';

@Component({
  selector: 'app-order-list',
  templateUrl: './order-list.component.html',
  styleUrls: ['./order-list.component.scss']
})
export class OrderListComponent implements OnInit, OnDestroy {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  displayedColumns: string[] = ['orderNumber', 'customerName', 'shopName', 'status', 'paymentStatus', 'totalAmount', 'createdAt', 'actions'];
  dataSource = new MatTableDataSource<OrderResponse>();
  loading = false;
  searchText = '';
  statusFilter = '';
  totalOrders = 0;
  pageSize = 10;
  currentPage = 0;
  
  // Real-time updates
  autoRefreshEnabled = true;
  refreshInterval = 60000; // 60 seconds for orders
  private refreshSubscription?: Subscription;
  
  statusOptions = [
    { value: '', label: 'All Statuses' },
    { value: 'PENDING', label: 'Pending' },
    { value: 'CONFIRMED', label: 'Confirmed' },
    { value: 'PREPARING', label: 'Preparing' },
    { value: 'READY_FOR_PICKUP', label: 'Ready for Pickup' },
    { value: 'OUT_FOR_DELIVERY', label: 'Out for Delivery' },
    { value: 'DELIVERED', label: 'Delivered' },
    { value: 'CANCELLED', label: 'Cancelled' }
  ];

  constructor(
    private orderService: OrderService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadOrders();
    this.startAutoRefresh();
  }

  ngOnDestroy(): void {
    this.stopAutoRefresh();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  loadOrders(): void {
    this.loading = true;
    this.orderService.getAllOrders(this.currentPage, this.pageSize).subscribe({
      next: (response) => {
        this.dataSource.data = response.data.content;
        this.totalOrders = response.data.totalElements;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading orders:', error);
        this.loadMockData();
        this.loading = false;
      }
    });
  }

  private loadMockData(): void {
    const mockOrders: OrderResponse[] = [
      {
        id: 1,
        orderNumber: 'ORD-001',
        status: 'CONFIRMED',
        paymentStatus: 'PAID',
        paymentMethod: 'CARD',
        customerId: 101,
        customerName: 'Ramesh Kumar',
        customerEmail: 'ramesh@example.com',
        customerPhone: '+91 98765 43210',
        shopId: 1,
        shopName: 'Annamalai Stores',
        shopAddress: '123 T.Nagar Main Road',
        subtotal: 850.00,
        taxAmount: 85.00,
        deliveryFee: 40.00,
        discountAmount: 0.00,
        totalAmount: 975.00,
        notes: 'Please deliver after 6 PM',
        cancellationReason: '',
        deliveryAddress: '45 Anna Nagar West',
        deliveryCity: 'Chennai',
        deliveryState: 'Tamil Nadu',
        deliveryPostalCode: '600040',
        deliveryPhone: '+91 98765 43210',
        deliveryContactName: 'Ramesh Kumar',
        fullDeliveryAddress: '45 Anna Nagar West, Chennai, Tamil Nadu - 600040',
        estimatedDeliveryTime: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(),
        actualDeliveryTime: '',
        orderItems: [
          {
            id: 1,
            shopProductId: 1,
            productName: 'Basmati Rice',
            productDescription: 'Premium quality basmati rice',
            productSku: 'RICE-001',
            productImageUrl: '',
            quantity: 2,
            unitPrice: 250.00,
            totalPrice: 500.00,
            specialInstructions: ''
          },
          {
            id: 2,
            shopProductId: 2,
            productName: 'Toor Dal',
            productDescription: 'Fresh toor dal',
            productSku: 'DAL-001',
            productImageUrl: '',
            quantity: 1,
            unitPrice: 350.00,
            totalPrice: 350.00,
            specialInstructions: ''
          }
        ],
        createdAt: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
        createdBy: 'ramesh@example.com',
        updatedBy: 'system',
        statusLabel: 'Confirmed',
        paymentStatusLabel: 'Paid',
        paymentMethodLabel: 'Card Payment',
        canBeCancelled: true,
        isDelivered: false,
        isPaid: true,
        orderAge: '30 mins ago',
        itemCount: 2
      },
      {
        id: 2,
        orderNumber: 'ORD-002',
        status: 'PREPARING',
        paymentStatus: 'PAID',
        paymentMethod: 'UPI',
        customerId: 102,
        customerName: 'Priya Sharma',
        customerEmail: 'priya@example.com',
        customerPhone: '+91 98765 43211',
        shopId: 2,
        shopName: 'Saravana Medical',
        shopAddress: '456 Adyar Main Road',
        subtotal: 425.00,
        taxAmount: 42.50,
        deliveryFee: 30.00,
        discountAmount: 25.00,
        totalAmount: 472.50,
        notes: 'Urgent medicines required',
        cancellationReason: '',
        deliveryAddress: '88 Mylapore East',
        deliveryCity: 'Chennai',
        deliveryState: 'Tamil Nadu',
        deliveryPostalCode: '600004',
        deliveryPhone: '+91 98765 43211',
        deliveryContactName: 'Priya Sharma',
        fullDeliveryAddress: '88 Mylapore East, Chennai, Tamil Nadu - 600004',
        estimatedDeliveryTime: new Date(Date.now() + 1.5 * 60 * 60 * 1000).toISOString(),
        actualDeliveryTime: '',
        orderItems: [
          {
            id: 3,
            shopProductId: 3,
            productName: 'Paracetamol Tablets',
            productDescription: '500mg tablets - Pack of 10',
            productSku: 'MED-001',
            productImageUrl: '',
            quantity: 2,
            unitPrice: 45.00,
            totalPrice: 90.00,
            specialInstructions: ''
          },
          {
            id: 4,
            shopProductId: 4,
            productName: 'Vitamin D3 Capsules',
            productDescription: '60000 IU - Pack of 4',
            productSku: 'MED-002',
            productImageUrl: '',
            quantity: 1,
            unitPrice: 335.00,
            totalPrice: 335.00,
            specialInstructions: 'Check expiry date'
          }
        ],
        createdAt: new Date(Date.now() - 45 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 10 * 60 * 1000).toISOString(),
        createdBy: 'priya@example.com',
        updatedBy: 'shop',
        statusLabel: 'Preparing',
        paymentStatusLabel: 'Paid',
        paymentMethodLabel: 'UPI Payment',
        canBeCancelled: true,
        isDelivered: false,
        isPaid: true,
        orderAge: '45 mins ago',
        itemCount: 2
      },
      {
        id: 3,
        orderNumber: 'ORD-003',
        status: 'OUT_FOR_DELIVERY',
        paymentStatus: 'PAID',
        paymentMethod: 'COD',
        customerId: 103,
        customerName: 'Vikram Raj',
        customerEmail: 'vikram@example.com',
        customerPhone: '+91 98765 43212',
        shopId: 3,
        shopName: 'Tamil Books Corner',
        shopAddress: '789 Mylapore Street',
        subtotal: 650.00,
        taxAmount: 65.00,
        deliveryFee: 50.00,
        discountAmount: 50.00,
        totalAmount: 715.00,
        notes: 'Handle books carefully',
        cancellationReason: '',
        deliveryAddress: '22 Velachery Main Road',
        deliveryCity: 'Chennai',
        deliveryState: 'Tamil Nadu',
        deliveryPostalCode: '600042',
        deliveryPhone: '+91 98765 43212',
        deliveryContactName: 'Vikram Raj',
        fullDeliveryAddress: '22 Velachery Main Road, Chennai, Tamil Nadu - 600042',
        estimatedDeliveryTime: new Date(Date.now() + 30 * 60 * 1000).toISOString(),
        actualDeliveryTime: '',
        orderItems: [
          {
            id: 5,
            shopProductId: 5,
            productName: 'Tamil Literature Collection',
            productDescription: 'Set of 3 classic Tamil novels',
            productSku: 'BOOK-001',
            productImageUrl: '',
            quantity: 1,
            unitPrice: 650.00,
            totalPrice: 650.00,
            specialInstructions: 'Gift wrap requested'
          }
        ],
        createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 5 * 60 * 1000).toISOString(),
        createdBy: 'vikram@example.com',
        updatedBy: 'delivery',
        statusLabel: 'Out for Delivery',
        paymentStatusLabel: 'Cash on Delivery',
        paymentMethodLabel: 'Cash on Delivery',
        canBeCancelled: false,
        isDelivered: false,
        isPaid: false,
        orderAge: '2 hours ago',
        itemCount: 1
      },
      {
        id: 4,
        orderNumber: 'ORD-004',
        status: 'DELIVERED',
        paymentStatus: 'PAID',
        paymentMethod: 'CARD',
        customerId: 104,
        customerName: 'Meera Devi',
        customerEmail: 'meera@example.com',
        customerPhone: '+91 98765 43213',
        shopId: 7,
        shopName: 'Textile Paradise',
        shopAddress: '999 Ranganathan Street',
        subtotal: 1250.00,
        taxAmount: 125.00,
        deliveryFee: 60.00,
        discountAmount: 100.00,
        totalAmount: 1335.00,
        notes: 'Birthday gift for daughter',
        cancellationReason: '',
        deliveryAddress: '15 Besant Nagar Beach Road',
        deliveryCity: 'Chennai',
        deliveryState: 'Tamil Nadu',
        deliveryPostalCode: '600090',
        deliveryPhone: '+91 98765 43213',
        deliveryContactName: 'Meera Devi',
        fullDeliveryAddress: '15 Besant Nagar Beach Road, Chennai, Tamil Nadu - 600090',
        estimatedDeliveryTime: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
        actualDeliveryTime: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
        orderItems: [
          {
            id: 6,
            shopProductId: 6,
            productName: 'Silk Saree',
            productDescription: 'Traditional Kanjivaram silk saree',
            productSku: 'SAREE-001',
            productImageUrl: '',
            quantity: 1,
            unitPrice: 1250.00,
            totalPrice: 1250.00,
            specialInstructions: 'Check for any damages'
          }
        ],
        createdAt: new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
        createdBy: 'meera@example.com',
        updatedBy: 'delivery',
        statusLabel: 'Delivered',
        paymentStatusLabel: 'Paid',
        paymentMethodLabel: 'Card Payment',
        canBeCancelled: false,
        isDelivered: true,
        isPaid: true,
        orderAge: '3 hours ago',
        itemCount: 1
      },
      {
        id: 5,
        orderNumber: 'ORD-005',
        status: 'CANCELLED',
        paymentStatus: 'REFUNDED',
        paymentMethod: 'UPI',
        customerId: 105,
        customerName: 'Arun Kumar',
        customerEmail: 'arun@example.com',
        customerPhone: '+91 98765 43214',
        shopId: 5,
        shopName: 'Digital Electronics Hub',
        shopAddress: '555 Anna Salai',
        subtotal: 15000.00,
        taxAmount: 1500.00,
        deliveryFee: 100.00,
        discountAmount: 500.00,
        totalAmount: 16100.00,
        notes: 'Need latest model',
        cancellationReason: 'Item out of stock',
        deliveryAddress: '33 OMR Thoraipakkam',
        deliveryCity: 'Chennai',
        deliveryState: 'Tamil Nadu',
        deliveryPostalCode: '600097',
        deliveryPhone: '+91 98765 43214',
        deliveryContactName: 'Arun Kumar',
        fullDeliveryAddress: '33 OMR Thoraipakkam, Chennai, Tamil Nadu - 600097',
        estimatedDeliveryTime: '',
        actualDeliveryTime: '',
        orderItems: [
          {
            id: 7,
            shopProductId: 7,
            productName: 'iPhone 15 Pro',
            productDescription: '128GB Space Black',
            productSku: 'PHONE-001',
            productImageUrl: '',
            quantity: 1,
            unitPrice: 15000.00,
            totalPrice: 15000.00,
            specialInstructions: 'Check warranty'
          }
        ],
        createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString(),
        createdBy: 'arun@example.com',
        updatedBy: 'shop',
        statusLabel: 'Cancelled',
        paymentStatusLabel: 'Refunded',
        paymentMethodLabel: 'UPI Payment',
        canBeCancelled: false,
        isDelivered: false,
        isPaid: false,
        orderAge: '1 day ago',
        itemCount: 1
      },
      {
        id: 6,
        orderNumber: 'ORD-006',
        status: 'PENDING',
        paymentStatus: 'PENDING',
        paymentMethod: 'CARD',
        customerId: 106,
        customerName: 'Lakshmi Priya',
        customerEmail: 'lakshmi@example.com',
        customerPhone: '+91 98765 43215',
        shopId: 6,
        shopName: 'Flower Garden Store',
        shopAddress: '888 Pondy Bazaar',
        subtotal: 750.00,
        taxAmount: 75.00,
        deliveryFee: 40.00,
        discountAmount: 0.00,
        totalAmount: 865.00,
        notes: 'Wedding decoration flowers',
        cancellationReason: '',
        deliveryAddress: '12 Cathedral Road',
        deliveryCity: 'Chennai',
        deliveryState: 'Tamil Nadu',
        deliveryPostalCode: '600086',
        deliveryPhone: '+91 98765 43215',
        deliveryContactName: 'Lakshmi Priya',
        fullDeliveryAddress: '12 Cathedral Road, Chennai, Tamil Nadu - 600086',
        estimatedDeliveryTime: new Date(Date.now() + 4 * 60 * 60 * 1000).toISOString(),
        actualDeliveryTime: '',
        orderItems: [
          {
            id: 8,
            shopProductId: 8,
            productName: 'Rose Bouquet',
            productDescription: 'Red roses - 12 pieces',
            productSku: 'FLOWER-001',
            productImageUrl: '',
            quantity: 5,
            unitPrice: 150.00,
            totalPrice: 750.00,
            specialInstructions: 'Fresh flowers needed for tomorrow'
          }
        ],
        createdAt: new Date(Date.now() - 10 * 60 * 1000).toISOString(),
        updatedAt: new Date(Date.now() - 10 * 60 * 1000).toISOString(),
        createdBy: 'lakshmi@example.com',
        updatedBy: 'lakshmi@example.com',
        statusLabel: 'Pending',
        paymentStatusLabel: 'Payment Pending',
        paymentMethodLabel: 'Card Payment',
        canBeCancelled: true,
        isDelivered: false,
        isPaid: false,
        orderAge: '10 mins ago',
        itemCount: 1
      }
    ];

    const mockResponse: PageResponse<OrderResponse> = {
      data: {
        content: mockOrders,
        totalElements: mockOrders.length,
        totalPages: 1,
        size: 20,
        number: 0
      }
    };

    this.dataSource.data = mockResponse.data.content;
    this.totalOrders = mockResponse.data.totalElements;
    
    this.snackBar.open('Loaded mock data - API not available', 'Close', { duration: 3000 });
  }

  applyFilter(): void {
    let filteredData = this.dataSource.data;

    if (this.searchText) {
      filteredData = filteredData.filter(order =>
        order.orderNumber.toLowerCase().includes(this.searchText.toLowerCase()) ||
        order.customerName.toLowerCase().includes(this.searchText.toLowerCase()) ||
        order.shopName.toLowerCase().includes(this.searchText.toLowerCase())
      );
    }

    if (this.statusFilter) {
      filteredData = filteredData.filter(order => order.status === this.statusFilter);
    }

    this.dataSource.data = filteredData;
  }

  clearFilters(): void {
    this.searchText = '';
    this.statusFilter = '';
    this.loadOrders();
  }

  viewOrder(order: OrderResponse): void {
    this.router.navigate(['/orders', order.id]);
  }

  updateOrderStatus(order: OrderResponse): void {
    Swal.fire({
      title: 'Update Order Status',
      input: 'select',
      inputOptions: {
        'PENDING': 'Pending',
        'CONFIRMED': 'Confirmed',
        'PREPARING': 'Preparing',
        'READY_FOR_PICKUP': 'Ready for Pickup',
        'OUT_FOR_DELIVERY': 'Out for Delivery',
        'DELIVERED': 'Delivered',
        'CANCELLED': 'Cancelled'
      },
      inputValue: order.status,
      showCancelButton: true,
      confirmButtonText: 'Update',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed && result.value !== order.status) {
        this.orderService.updateOrderStatus(order.id, result.value).subscribe({
          next: () => {
            Swal.fire('Success!', 'Order status updated successfully', 'success');
            this.loadOrders();
          },
          error: (error) => {
            Swal.fire('Error!', 'Failed to update order status', 'error');
          }
        });
      }
    });
  }

  cancelOrder(order: OrderResponse): void {
    Swal.fire({
      title: 'Cancel Order',
      text: 'Please provide a reason for cancellation:',
      input: 'textarea',
      inputPlaceholder: 'Cancellation reason...',
      showCancelButton: true,
      confirmButtonText: 'Cancel Order',
      cancelButtonText: 'Close',
      confirmButtonColor: '#d33'
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        this.orderService.cancelOrder(order.id, result.value).subscribe({
          next: () => {
            Swal.fire('Success!', 'Order cancelled successfully', 'success');
            this.loadOrders();
          },
          error: (error) => {
            Swal.fire('Error!', 'Failed to cancel order', 'error');
          }
        });
      }
    });
  }

  onPageChange(event: any): void {
    this.currentPage = event.pageIndex;
    this.pageSize = event.pageSize;
    this.loadOrders();
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'PENDING': return 'warn';
      case 'CONFIRMED': return 'primary';
      case 'PREPARING': return 'primary';
      case 'READY_FOR_PICKUP': return 'accent';
      case 'OUT_FOR_DELIVERY': return 'accent';
      case 'DELIVERED': return 'primary';
      case 'CANCELLED': return 'warn';
      default: return '';
    }
  }

  getPaymentStatusColor(status: string): string {
    switch (status) {
      case 'PAID': return 'primary';
      case 'PENDING': return 'warn';
      case 'FAILED': return 'warn';
      case 'REFUNDED': return 'accent';
      default: return '';
    }
  }

  startAutoRefresh(): void {
    if (this.autoRefreshEnabled && !this.refreshSubscription) {
      this.refreshSubscription = interval(this.refreshInterval).subscribe(() => {
        this.loadOrdersQuietly();
      });
    }
  }

  stopAutoRefresh(): void {
    if (this.refreshSubscription) {
      this.refreshSubscription.unsubscribe();
      this.refreshSubscription = undefined;
    }
  }

  loadOrdersQuietly(): void {
    // Load orders without showing loading indicator for background refresh
    this.orderService.getAllOrders(this.currentPage, this.pageSize).subscribe({
      next: (response) => {
        const currentOrderCount = this.dataSource.data.length;
        const newOrderCount = response.data.content.length;
        
        this.dataSource.data = response.data.content;
        this.totalOrders = response.data.totalElements;
        
        // Show toast if new orders arrived
        if (newOrderCount > currentOrderCount) {
          const newItems = newOrderCount - currentOrderCount;
          Swal.fire({
            title: 'New Orders',
            text: `${newItems} new order${newItems > 1 ? 's' : ''} received.`,
            icon: 'info',
            timer: 3000,
            showConfirmButton: false,
            position: 'top-end',
            toast: true
          });
        }
      },
      error: (error) => {
        console.error('Error loading orders quietly:', error);
        // Don't show error message for background refresh failures
      }
    });
  }

  toggleAutoRefresh(): void {
    this.autoRefreshEnabled = !this.autoRefreshEnabled;
    
    if (this.autoRefreshEnabled) {
      this.startAutoRefresh();
      Swal.fire({
        title: 'Auto-refresh Enabled',
        text: `Orders will refresh every ${this.refreshInterval / 1000} seconds.`,
        icon: 'info',
        timer: 2000,
        showConfirmButton: false
      });
    } else {
      this.stopAutoRefresh();
      Swal.fire({
        title: 'Auto-refresh Disabled',
        text: 'Orders will no longer refresh automatically.',
        icon: 'info',
        timer: 2000,
        showConfirmButton: false
      });
    }
  }
}