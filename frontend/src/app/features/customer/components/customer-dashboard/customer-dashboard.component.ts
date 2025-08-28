import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';

interface Order {
  orderNumber: string;
  shopName: string;
  status: string;
  totalAmount: number;
}

interface Shop {
  id: number;
  name: string;
  category: string;
  rating: number;
  image: string;
}

@Component({
  selector: 'app-customer-dashboard',
  templateUrl: './customer-dashboard.component.html',
  styleUrls: ['./customer-dashboard.component.scss']
})
export class CustomerDashboardComponent implements OnInit {
  customerName = 'Customer';
  totalOrders = 0;
  totalSpent = 0;
  favoriteShops = 0;
  cartItemCount = 0;
  
  recentOrders: Order[] = [];
  recommendedShops: Shop[] = [];

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.loadDashboardData();
    this.loadRecentOrders();
    this.loadRecommendedShops();
  }

  loadDashboardData(): void {
    // Get user info
    const user = JSON.parse(localStorage.getItem('shop_management_user') || localStorage.getItem('currentUser') || '{}');
    this.customerName = user.firstName || user.username || 'Customer';
    
    // Mock data for now
    this.totalOrders = 12;
    this.totalSpent = 4500;
    this.favoriteShops = 3;
    this.cartItemCount = 0; // This should come from cart service
  }

  loadRecentOrders(): void {
    // Mock recent orders
    this.recentOrders = [
      {
        orderNumber: 'ORD-2024-0045',
        shopName: 'Test Grocery Store',
        status: 'DELIVERED',
        totalAmount: 565
      },
      {
        orderNumber: 'ORD-2024-0044',
        shopName: 'TechMart Electronics',
        status: 'CONFIRMED',
        totalAmount: 85000
      }
    ];
  }

  loadRecommendedShops(): void {
    // Mock recommended shops
    this.recommendedShops = [
      {
        id: 1,
        name: 'Test Grocery Store',
        category: 'GROCERY',
        rating: 4.5,
        image: ''
      },
      {
        id: 2,
        name: 'TechMart Electronics',
        category: 'GENERAL',
        rating: 4.5,
        image: ''
      }
    ];
  }

  getStatusColor(status: string): string {
    const statusColors: { [key: string]: string } = {
      'PENDING': 'warn',
      'CONFIRMED': 'primary',
      'DELIVERED': 'primary',
      'CANCELLED': 'warn'
    };
    return statusColors[status] || 'basic';
  }
}