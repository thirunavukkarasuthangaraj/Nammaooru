import { Component, OnInit } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatSnackBar } from '@angular/material/snack-bar';
import { OrderAssignmentService } from '../../services/order-assignment.service';

interface PartnerOrderAssignment {
  id: number;
  orderId: number;
  customerName: string;
  pickupAddress: string;
  deliveryAddress: string;
  status: string;
  assignedAt: Date;
  estimatedDeliveryTime: Date;
  amount: number;
}

@Component({
  selector: 'app-partner-orders',
  templateUrl: './partner-orders.component.html',
  styleUrls: ['./partner-orders.component.scss']
})
export class PartnerOrdersComponent implements OnInit {
  displayedColumns: string[] = ['orderId', 'customerName', 'pickupAddress', 'deliveryAddress', 'status', 'amount', 'actions'];
  dataSource = new MatTableDataSource<PartnerOrderAssignment>([]);
  isLoading = true;

  statusColors: { [key: string]: string } = {
    'ASSIGNED': 'primary',
    'PICKED_UP': 'accent',
    'IN_TRANSIT': 'warn',
    'DELIVERED': 'success',
    'CANCELLED': 'error'
  };

  constructor(
    private orderAssignmentService: OrderAssignmentService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.loadPartnerOrders();
  }

  loadPartnerOrders(): void {
    this.isLoading = true;
    this.orderAssignmentService.getPartnerOrders().subscribe({
      next: (orders) => {
        this.dataSource.data = orders as unknown as PartnerOrderAssignment[];
        this.isLoading = false;
      },
      error: (error) => {
        this.snackBar.open('Failed to load orders', 'Close', { duration: 3000 });
        this.isLoading = false;
      }
    });
  }

  updateOrderStatus(orderId: number, status: string): void {
    this.orderAssignmentService.updateOrderStatus(orderId, status).subscribe({
      next: () => {
        this.snackBar.open('Order status updated successfully', 'Close', { duration: 3000 });
        this.loadPartnerOrders();
      },
      error: (error) => {
        this.snackBar.open('Failed to update order status', 'Close', { duration: 3000 });
      }
    });
  }

  getStatusColor(status: string): string {
    return this.statusColors[status] || 'primary';
  }

  viewOrderDetails(orderId: number): void {
    // Implement order details view
    console.log('View order details:', orderId);
  }

  startDelivery(orderId: number): void {
    this.updateOrderStatus(orderId, 'PICKED_UP');
  }

  completeDelivery(orderId: number): void {
    this.updateOrderStatus(orderId, 'DELIVERED');
  }
}