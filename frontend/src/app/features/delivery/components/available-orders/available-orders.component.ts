import { Component, OnInit } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatSnackBar } from '@angular/material/snack-bar';

interface AvailableOrder {
  id: number;
  orderId: number;
  customerName: string;
  pickupAddress: string;
  deliveryAddress: string;
  distance: number;
  estimatedEarning: number;
  createdAt: Date;
}

@Component({
  selector: 'app-available-orders',
  templateUrl: './available-orders.component.html',
  styleUrls: ['./available-orders.component.scss']
})
export class AvailableOrdersComponent implements OnInit {
  displayedColumns: string[] = ['orderId', 'customerName', 'pickupAddress', 'deliveryAddress', 'distance', 'estimatedEarning', 'actions'];
  dataSource = new MatTableDataSource<AvailableOrder>([]);
  isLoading = true;

  constructor(private snackBar: MatSnackBar) {}

  ngOnInit(): void {
    this.loadAvailableOrders();
  }

  loadAvailableOrders(): void {
    this.isLoading = true;
    // Mock data - replace with actual service call
    setTimeout(() => {
      this.dataSource.data = [
        {
          id: 1,
          orderId: 12345,
          customerName: 'John Doe',
          pickupAddress: 'Shop A, Main Street',
          deliveryAddress: '123 Home Street',
          distance: 2.5,
          estimatedEarning: 45,
          createdAt: new Date()
        }
      ];
      this.isLoading = false;
    }, 1000);
  }

  acceptOrder(orderId: number): void {
    this.snackBar.open('Order accepted successfully!', 'Close', { duration: 3000 });
    this.loadAvailableOrders();
  }
}