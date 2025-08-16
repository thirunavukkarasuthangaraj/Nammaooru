import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { OrderService, OrderResponse } from '../../../../core/services/order.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-order-detail',
  templateUrl: './order-detail.component.html',
  styleUrls: ['./order-detail.component.scss']
})
export class OrderDetailComponent implements OnInit {
  order: OrderResponse | null = null;
  loading = false;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private orderService: OrderService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    const orderId = this.route.snapshot.paramMap.get('id');
    if (orderId) {
      this.loadOrder(+orderId);
    }
  }

  loadOrder(orderId: number): void {
    this.loading = true;
    this.orderService.getOrderById(orderId).subscribe({
      next: (order) => {
        this.order = order;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading order:', error);
        Swal.fire({
          title: 'Error!',
          text: 'Failed to load order details. Please try again.',
          icon: 'error',
          confirmButtonText: 'OK'
        }).then(() => {
          this.router.navigate(['/orders']);
        });
        this.loading = false;
      }
    });
  }

  goBack(): void {
    this.router.navigate(['/orders']);
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

  updateOrderStatus(): void {
    if (!this.order) return;
    
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
      inputValue: this.order.status,
      showCancelButton: true,
      confirmButtonText: 'Update',
      cancelButtonText: 'Cancel'
    }).then((result) => {
      if (result.isConfirmed && result.value !== this.order!.status) {
        this.orderService.updateOrderStatus(this.order!.id, result.value).subscribe({
          next: (updatedOrder) => {
            this.order = updatedOrder;
            Swal.fire('Success!', 'Order status updated successfully', 'success');
          },
          error: (error) => {
            Swal.fire('Error!', 'Failed to update order status', 'error');
          }
        });
      }
    });
  }

  cancelOrder(): void {
    if (!this.order) return;
    
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
        this.orderService.cancelOrder(this.order!.id, result.value).subscribe({
          next: (updatedOrder) => {
            this.order = updatedOrder;
            Swal.fire('Success!', 'Order cancelled successfully', 'success');
          },
          error: (error) => {
            Swal.fire('Error!', 'Failed to cancel order', 'error');
          }
        });
      }
    });
  }
}