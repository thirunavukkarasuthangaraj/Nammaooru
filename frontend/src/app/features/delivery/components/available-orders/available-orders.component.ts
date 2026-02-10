import { Component, OnInit } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatSnackBar } from '@angular/material/snack-bar';
import { OrderAssignmentService } from '../../services/order-assignment.service';
import { AuthService } from '../../../../core/services/auth.service';

interface AvailableOrder {
  id: string;
  orderNumber: string;
  customerName: string;
  shopName: string;
  shopAddress: string;
  deliveryAddress: string;
  totalAmount: number;
  deliveryFee: number;
  status: string;
  createdAt: string;
}

@Component({
  selector: 'app-available-orders',
  templateUrl: './available-orders.component.html',
  styleUrls: ['./available-orders.component.scss']
})
export class AvailableOrdersComponent implements OnInit {
  displayedColumns: string[] = ['orderNumber', 'customerName', 'shopName', 'deliveryAddress', 'deliveryFee', 'actions'];
  dataSource = new MatTableDataSource<AvailableOrder>([]);
  isLoading = true;
  partnerId: number | null = null;

  constructor(
    private orderAssignmentService: OrderAssignmentService,
    private authService: AuthService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    if (user) {
      this.partnerId = user.id;
      this.loadAvailableOrders();
    } else {
      this.isLoading = false;
    }
  }

  loadAvailableOrders(): void {
    if (!this.partnerId) return;
    this.isLoading = true;

    this.orderAssignmentService.getAvailableOrdersForPartner(this.partnerId).subscribe({
      next: (response) => {
        if (response.success && response.orders) {
          this.dataSource.data = response.orders.map((o: any) => ({
            id: o.id,
            orderNumber: o.orderNumber || '-',
            customerName: o.customerName || '-',
            shopName: o.shopName || '-',
            shopAddress: o.shopAddress || '-',
            deliveryAddress: o.deliveryAddress || '-',
            totalAmount: o.totalAmount || 0,
            deliveryFee: o.deliveryFee || 0,
            status: o.status || 'ASSIGNED',
            createdAt: o.createdAt
          }));
        } else {
          this.dataSource.data = [];
        }
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading available orders:', error);
        this.snackBar.open('Failed to load available orders', 'Close', { duration: 3000 });
        this.dataSource.data = [];
        this.isLoading = false;
      }
    });
  }

  acceptOrder(orderId: string): void {
    if (!this.partnerId) return;

    this.orderAssignmentService.acceptAssignment(Number(orderId), this.partnerId).subscribe({
      next: () => {
        this.snackBar.open('Order accepted successfully!', 'Close', { duration: 3000 });
        this.loadAvailableOrders();
      },
      error: (error) => {
        console.error('Error accepting order:', error);
        this.snackBar.open('Failed to accept order', 'Close', { duration: 3000 });
      }
    });
  }

  rejectOrder(orderId: string): void {
    if (!this.partnerId) return;

    this.orderAssignmentService.rejectAssignment(Number(orderId), this.partnerId, 'Not available').subscribe({
      next: () => {
        this.snackBar.open('Order rejected', 'Close', { duration: 3000 });
        this.loadAvailableOrders();
      },
      error: (error) => {
        console.error('Error rejecting order:', error);
        this.snackBar.open('Failed to reject order', 'Close', { duration: 3000 });
      }
    });
  }
}
