import { Component, OnInit } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatSnackBar } from '@angular/material/snack-bar';
import { OrderAssignmentService } from '../../services/order-assignment.service';
import { AuthService } from '../../../../core/services/auth.service';

interface PartnerOrderAssignment {
  id: string;
  orderId: number;
  orderNumber: string;
  customerName: string;
  shopName: string;
  deliveryAddress: string;
  status: string;
  assignmentStatus: string;
  totalAmount: number;
  deliveryFee: number;
  pickupOtp?: string;
}

@Component({
  selector: 'app-partner-orders',
  templateUrl: './partner-orders.component.html',
  styleUrls: ['./partner-orders.component.scss']
})
export class PartnerOrdersComponent implements OnInit {
  displayedColumns: string[] = ['orderNumber', 'customerName', 'shopName', 'deliveryAddress', 'status', 'amount', 'actions'];
  dataSource = new MatTableDataSource<PartnerOrderAssignment>([]);
  isLoading = true;
  partnerId: number | null = null;

  statusColors: { [key: string]: string } = {
    'assigned': 'primary',
    'accepted': 'accent',
    'picked_up': 'accent',
    'in_transit': 'warn',
    'delivered': 'success',
    'cancelled': 'error'
  };

  constructor(
    private orderAssignmentService: OrderAssignmentService,
    private authService: AuthService,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    if (user) {
      this.partnerId = user.id;
      this.loadPartnerOrders();
    } else {
      this.isLoading = false;
      this.snackBar.open('Could not identify logged-in user', 'Close', { duration: 3000 });
    }
  }

  loadPartnerOrders(): void {
    if (!this.partnerId) return;
    this.isLoading = true;

    this.orderAssignmentService.getActiveOrdersForPartner(this.partnerId).subscribe({
      next: (response) => {
        if (response.success && response.orders) {
          this.dataSource.data = response.orders.map((o: any) => ({
            id: o.id,
            orderId: o.id,
            orderNumber: o.orderNumber || '-',
            customerName: o.customerName || '-',
            shopName: o.shopName || '-',
            deliveryAddress: o.deliveryAddress || '-',
            status: o.status || o.assignmentStatus || '-',
            assignmentStatus: o.assignmentStatus || o.status || '-',
            totalAmount: o.totalAmount || 0,
            deliveryFee: o.deliveryFee || 0,
            pickupOtp: o.pickupOtp
          }));
        } else {
          this.dataSource.data = [];
        }
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error loading partner orders:', error);
        this.snackBar.open('Failed to load orders', 'Close', { duration: 3000 });
        this.dataSource.data = [];
        this.isLoading = false;
      }
    });
  }

  getStatusColor(status: string): string {
    return this.statusColors[status?.toLowerCase()] || 'primary';
  }

  viewOrderDetails(orderId: number): void {
    console.log('View order details:', orderId);
  }

  startDelivery(orderId: number): void {
    this.snackBar.open('Starting delivery...', 'Close', { duration: 2000 });
  }

  completeDelivery(orderId: number): void {
    this.snackBar.open('Completing delivery...', 'Close', { duration: 2000 });
  }
}
