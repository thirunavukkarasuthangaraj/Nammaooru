import { Component, OnInit } from '@angular/core';
import { AuthService } from '@core/services/auth.service';
import { ShopService } from '@core/services/shop.service';
import { User } from '@core/models/auth.model';
import { Shop } from '@core/models/shop.model';
import { Observable } from 'rxjs';

interface ShopStats {
  todayOrders: number;
  weeklyOrders: number;
  monthlyRevenue: number;
  totalCustomers: number;
  averageRating: number;
  responseTime: string;
  deliverySuccess: number;
}

@Component({
  selector: 'app-shop-overview',
  template: `
    <div class="shop-overview-container">
      <!-- Loading State -->
      <div *ngIf="loading" class="loading-container">
        <mat-spinner></mat-spinner>
        <p>Loading shop information...</p>
      </div>

      <!-- Shop Header Card -->
      <mat-card class="shop-header-card">
        <div class="shop-header-content">
          <div class="shop-branding">
            <div class="shop-logo">
              <img [src]="shopData.logoUrl" [alt]="shopData.name" class="shop-logo-img">
              <div class="shop-logo-fallback">
                <mat-icon>storefront</mat-icon>
              </div>
            </div>
            <div class="shop-info">
              <h1 class="shop-name">{{ shopData.name }}</h1>
              <p class="shop-description">{{ shopData.description }}</p>
              <div class="shop-badges">
                <span class="status-badge" [class]="'status-' + shopData.status.toLowerCase()">
                  <mat-icon>{{ getStatusIcon(shopData.status) }}</mat-icon>
                  {{ shopData.status }}
                </span>
                <span class="verification-badge" *ngIf="shopData.isVerified">
                  <mat-icon>verified</mat-icon>
                  Verified
                </span>
              </div>
            </div>
          </div>
          <div class="shop-actions">
            <button mat-raised-button color="primary" routerLink="/shop-owner/shop/profile">
              <mat-icon>edit</mat-icon>
              Edit Profile
            </button>
            <button mat-stroked-button routerLink="/shop-owner/settings">
              <mat-icon>settings</mat-icon>
              Settings
            </button>
          </div>
        </div>
      </mat-card>

      <!-- Shop Details Grid -->
      <div class="details-grid">
        <!-- Contact Information -->
        <mat-card class="detail-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>contact_phone</mat-icon>
              Contact Information
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="contact-item">
              <mat-icon>phone</mat-icon>
              <div class="contact-details">
                <span class="contact-label">Phone</span>
                <span class="contact-value">{{ shopData.phone }}</span>
              </div>
            </div>
            <div class="contact-item">
              <mat-icon>email</mat-icon>
              <div class="contact-details">
                <span class="contact-label">Email</span>
                <span class="contact-value">{{ shopData.email }}</span>
              </div>
            </div>
            <div class="contact-item">
              <mat-icon>location_on</mat-icon>
              <div class="contact-details">
                <span class="contact-label">Address</span>
                <span class="contact-value">{{ shopData.address }}, {{ shopData.city }} - {{ shopData.pincode }}</span>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <!-- Business Hours -->
        <mat-card class="detail-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>schedule</mat-icon>
              Business Hours
            </mat-card-title>
            <div class="card-actions">
              <button mat-button routerLink="/shop-owner/business-hours">Update</button>
            </div>
          </mat-card-header>
          <mat-card-content>
            <div class="hours-list">
              <div class="hours-item" *ngFor="let day of businessHours">
                <span class="day-name">{{ day.day }}</span>
                <span class="day-hours" [class.closed]="day.isClosed">
                  {{ day.isClosed ? 'Closed' : day.hours }}
                </span>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <!-- Performance Metrics -->
        <mat-card class="detail-card metrics-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>trending_up</mat-icon>
              Performance Metrics
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="metrics-grid">
              <div class="metric-item">
                <div class="metric-value">{{ shopStats.averageRating.toFixed(1) }}</div>
                <div class="metric-label">Average Rating</div>
                <div class="metric-stars">
                  <mat-icon *ngFor="let star of getStars(shopStats.averageRating)">{{ star }}</mat-icon>
                </div>
              </div>
              <div class="metric-item">
                <div class="metric-value">{{ shopStats.responseTime }}</div>
                <div class="metric-label">Response Time</div>
              </div>
              <div class="metric-item">
                <div class="metric-value">{{ shopStats.deliverySuccess }}%</div>
                <div class="metric-label">Delivery Success</div>
              </div>
              <div class="metric-item">
                <div class="metric-value">{{ shopStats.totalCustomers }}</div>
                <div class="metric-label">Total Customers</div>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <!-- Recent Activity -->
        <mat-card class="detail-card activity-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>history</mat-icon>
              Recent Activity
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="activity-timeline">
              <div class="activity-item" *ngFor="let activity of recentActivities">
                <div class="activity-icon">
                  <mat-icon [class]="activity.type">{{ activity.icon }}</mat-icon>
                </div>
                <div class="activity-content">
                  <h4 class="activity-title">{{ activity.title }}</h4>
                  <p class="activity-description">{{ activity.description }}</p>
                  <span class="activity-time">{{ activity.time | date:'short' }}</span>
                </div>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <!-- Quick Stats -->
        <mat-card class="detail-card stats-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>analytics</mat-icon>
              This Month
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="quick-stats">
              <div class="stat-item">
                <div class="stat-number">{{ shopStats.monthlyRevenue | currency:'INR':'symbol':'1.0-0' }}</div>
                <div class="stat-label">Revenue</div>
                <div class="stat-change positive">+15.3%</div>
              </div>
              <div class="stat-item">
                <div class="stat-number">{{ shopStats.weeklyOrders }}</div>
                <div class="stat-label">Orders</div>
                <div class="stat-change positive">+8.2%</div>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <!-- Delivery Settings -->
        <mat-card class="detail-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>local_shipping</mat-icon>
              Delivery Settings
            </mat-card-title>
            <div class="card-actions">
              <button mat-button routerLink="/shop-owner/delivery">Update</button>
            </div>
          </mat-card-header>
          <mat-card-content>
            <div class="delivery-info">
              <div class="delivery-item">
                <span class="delivery-label">Delivery Radius</span>
                <span class="delivery-value">{{ deliverySettings.radius }} km</span>
              </div>
              <div class="delivery-item">
                <span class="delivery-label">Minimum Order</span>
                <span class="delivery-value">₹{{ deliverySettings.minimumOrder }}</span>
              </div>
              <div class="delivery-item">
                <span class="delivery-label">Delivery Charge</span>
                <span class="delivery-value">₹{{ deliverySettings.charge }}</span>
              </div>
              <div class="delivery-item">
                <span class="delivery-label">Free Delivery Above</span>
                <span class="delivery-value">₹{{ deliverySettings.freeAbove }}</span>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      </div>
    </div>
  `,
  styles: [`
    .shop-overview-container {
      padding: 24px;
      background-color: #f5f5f5;
      min-height: calc(100vh - 64px);
    }

    .shop-header-card {
      margin-bottom: 24px;
      border-radius: 12px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }

    .shop-header-content {
      display: flex;
      align-items: center;
      gap: 24px;
      padding: 8px;
    }

    .shop-branding {
      display: flex;
      align-items: center;
      gap: 20px;
      flex: 1;
    }

    .shop-logo {
      position: relative;
      width: 80px;
      height: 80px;
      border-radius: 50%;
      overflow: hidden;
      border: 3px solid #e5e7eb;
    }

    .shop-logo-img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    .shop-logo-fallback {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: linear-gradient(135deg, #667eea, #764ba2);
      color: white;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .shop-logo-fallback mat-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
    }

    .shop-name {
      font-size: 2rem;
      font-weight: 600;
      margin: 0 0 8px 0;
      color: #1f2937;
    }

    .shop-description {
      font-size: 1rem;
      color: #6b7280;
      margin: 0 0 12px 0;
      line-height: 1.5;
    }

    .shop-badges {
      display: flex;
      gap: 8px;
      align-items: center;
    }

    .status-badge, .verification-badge {
      display: flex;
      align-items: center;
      gap: 4px;
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 0.8rem;
      font-weight: 500;
      text-transform: uppercase;
    }

    .status-badge.status-active {
      background: #d1fae5;
      color: #065f46;
    }

    .status-badge.status-pending {
      background: #fef3c7;
      color: #92400e;
    }

    .verification-badge {
      background: #dbeafe;
      color: #1e40af;
    }

    .shop-actions {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .details-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
      gap: 16px;
    }

    .detail-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .detail-card mat-card-header {
      background: #f8f9fa;
      margin: -16px -16px 16px -16px;
      padding: 16px;
      border-radius: 12px 12px 0 0;
    }

    .detail-card mat-card-title {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 1.1rem;
      font-weight: 500;
    }

    .card-actions {
      margin-left: auto;
    }

    .contact-item {
      display: flex;
      align-items: flex-start;
      gap: 12px;
      margin-bottom: 16px;
    }

    .contact-item mat-icon {
      color: #6b7280;
      margin-top: 2px;
    }

    .contact-details {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }

    .contact-label {
      font-size: 0.8rem;
      color: #6b7280;
      font-weight: 500;
    }

    .contact-value {
      font-size: 0.9rem;
      color: #374151;
    }

    .hours-list {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .hours-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 8px 0;
      border-bottom: 1px solid #f3f4f6;
    }

    .day-name {
      font-weight: 500;
      color: #374151;
    }

    .day-hours {
      font-size: 0.9rem;
      color: #16a34a;
    }

    .day-hours.closed {
      color: #dc2626;
    }

    .metrics-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
    }

    .metric-item {
      text-align: center;
    }

    .metric-value {
      font-size: 1.5rem;
      font-weight: 600;
      color: #1f2937;
      margin-bottom: 4px;
    }

    .metric-label {
      font-size: 0.8rem;
      color: #6b7280;
      margin-bottom: 4px;
    }

    .metric-stars {
      display: flex;
      justify-content: center;
      gap: 2px;
    }

    .metric-stars mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
      color: #fbbf24;
    }

    .activity-timeline {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .activity-item {
      display: flex;
      align-items: flex-start;
      gap: 12px;
    }

    .activity-icon {
      width: 32px;
      height: 32px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #f3f4f6;
      flex-shrink: 0;
    }

    .activity-icon mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
      color: #6b7280;
    }

    .activity-icon.order mat-icon { color: #2563eb; }
    .activity-icon.product mat-icon { color: #16a34a; }
    .activity-icon.update mat-icon { color: #f59e0b; }

    .activity-title {
      font-size: 0.9rem;
      font-weight: 600;
      margin: 0 0 2px 0;
      color: #374151;
    }

    .activity-description {
      font-size: 0.8rem;
      color: #6b7280;
      margin: 0 0 4px 0;
    }

    .activity-time {
      font-size: 0.7rem;
      color: #9ca3af;
    }

    .quick-stats {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .stat-item {
      text-align: center;
    }

    .stat-number {
      font-size: 1.5rem;
      font-weight: 600;
      color: #1f2937;
      margin-bottom: 4px;
    }

    .stat-label {
      font-size: 0.8rem;
      color: #6b7280;
      margin-bottom: 4px;
    }

    .stat-change {
      font-size: 0.8rem;
      font-weight: 500;
      padding: 2px 6px;
      border-radius: 12px;
    }

    .stat-change.positive {
      background: #dcfce7;
      color: #16a34a;
    }

    .delivery-info {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .delivery-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 8px 0;
      border-bottom: 1px solid #f3f4f6;
    }

    .delivery-label {
      font-weight: 500;
      color: #374151;
    }

    .delivery-value {
      font-size: 0.9rem;
      color: #6b7280;
      font-weight: 600;
    }

    /* Mobile Responsive */
    @media (max-width: 768px) {
      .shop-overview-container {
        padding: 16px;
      }

      .shop-header-content {
        flex-direction: column;
        text-align: center;
      }

      .details-grid {
        grid-template-columns: 1fr;
      }

      .metrics-grid {
        grid-template-columns: 1fr;
      }

      .shop-name {
        font-size: 1.5rem;
      }
    }
  `]
})
export class ShopOverviewComponent implements OnInit {
  currentUser$: Observable<User | null>;
  
  shopData = {
    name: 'Raghavendra Stores',
    description: 'Your neighborhood grocery store with fresh products and daily essentials. We pride ourselves on quality products and excellent customer service.',
    phone: '+91 9876543210',
    email: 'raghavendra.stores@email.com',
    address: '123 Main Street, Gandhi Nagar',
    city: 'Bangalore',
    pincode: '560001',
    status: 'Active',
    isVerified: true,
    logoUrl: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iODAiIGhlaWdodD0iODAiIHZpZXdCb3g9IjAgMCA4MCA4MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iNDAiIGN5PSI0MCIgcj0iNDAiIGZpbGw9IiM2MzY2RjEiLz4KPHRleHQgeD0iNDAiIHk9IjQwIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBkb21pbmFudC1iYXNlbGluZT0iY2VudHJhbCIgZmlsbD0id2hpdGUiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIyNCIgZm9udC13ZWlnaHQ9ImJvbGQiPlJTPC90ZXh0Pgo8L3N2Zz4='
  };

  businessHours = [
    { day: 'Monday', hours: '9:00 AM - 9:00 PM', isClosed: false },
    { day: 'Tuesday', hours: '9:00 AM - 9:00 PM', isClosed: false },
    { day: 'Wednesday', hours: '9:00 AM - 9:00 PM', isClosed: false },
    { day: 'Thursday', hours: '9:00 AM - 9:00 PM', isClosed: false },
    { day: 'Friday', hours: '9:00 AM - 9:00 PM', isClosed: false },
    { day: 'Saturday', hours: '9:00 AM - 10:00 PM', isClosed: false },
    { day: 'Sunday', hours: '10:00 AM - 8:00 PM', isClosed: false }
  ];

  shopStats: ShopStats = {
    todayOrders: 23,
    weeklyOrders: 156,
    monthlyRevenue: 89500,
    totalCustomers: 892,
    averageRating: 4.5,
    responseTime: '< 15 min',
    deliverySuccess: 96
  };

  recentActivities = [
    {
      title: 'New Order Received',
      description: 'Order #ORD-456 for ₹850 from Priya Sharma',
      time: new Date(),
      icon: 'shopping_cart',
      type: 'order'
    },
    {
      title: 'Product Added',
      description: 'Fresh Organic Bananas added to inventory',
      time: new Date(Date.now() - 2 * 60 * 60 * 1000),
      icon: 'add_box',
      type: 'product'
    },
    {
      title: 'Profile Updated',
      description: 'Business hours updated for weekends',
      time: new Date(Date.now() - 4 * 60 * 60 * 1000),
      icon: 'edit',
      type: 'update'
    }
  ];

  deliverySettings = {
    radius: 5,
    minimumOrder: 100,
    charge: 30,
    freeAbove: 500
  };

  constructor(
    private authService: AuthService,
    private shopService: ShopService
  ) {
    this.currentUser$ = this.authService.currentUser$;
  }

  ngOnInit(): void {
    this.loadShopOverview();
  }

  loading = false;

  private loadShopOverview(): void {
    this.loading = true;
    const currentUser = this.authService.getCurrentUser();
    
    if (!currentUser || !currentUser.shopId) {
      console.warn('No shop ID found for current user');
      this.loading = false;
      return;
    }

    // Load shop details from API
    this.shopService.getShopById(currentUser.shopId).subscribe({
      next: (shop) => {
        // Map API response to our shop data structure
        this.shopData = {
          name: shop.name || 'My Shop',
          description: shop.description || 'Shop description not provided',
          phone: shop.contactNumber || shop.phone || '+91 9876543210',
          email: shop.email || 'shop@email.com',
          address: shop.address || '123 Main Street',
          city: shop.city || 'City',
          pincode: shop.pincode || '000000',
          status: shop.status || 'Active',
          isVerified: shop.verified || false,
          logoUrl: shop.logoUrl || this.generateShopLogo(shop.name)
        };
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading shop data:', error);
        this.loading = false;
        // Keep default mock data on error
      }
    });

    // Load shop statistics
    this.loadShopStatistics(currentUser.shopId);
  }

  private loadShopStatistics(shopId: number): void {
    // Load multiple statistics in parallel
    this.shopService.getShopAnalytics(shopId).subscribe({
      next: (analytics) => {
        this.shopStats = {
          todayOrders: analytics.todayOrders || 23,
          weeklyOrders: analytics.weeklyOrders || 156,
          monthlyRevenue: analytics.monthlyRevenue || 89500,
          totalCustomers: analytics.totalCustomers || 892,
          averageRating: analytics.averageRating || 4.5,
          responseTime: analytics.responseTime || '< 15 min',
          deliverySuccess: analytics.deliverySuccess || 96
        };
      },
      error: (error) => {
        console.error('Error loading shop statistics:', error);
        // Keep default mock data on error
      }
    });
  }

  private generateShopLogo(shopName: string): string {
    const initials = shopName.split(' ').map(word => word[0]).join('').substring(0, 2).toUpperCase();
    return `data:image/svg+xml;base64,${btoa(`
      <svg width="80" height="80" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg">
        <circle cx="40" cy="40" r="40" fill="#6366F1"/>
        <text x="40" y="40" text-anchor="middle" dominant-baseline="central" fill="white" font-family="Arial" font-size="24" font-weight="bold">${initials}</text>
      </svg>
    `)}`;
  }

  getStatusIcon(status: string): string {
    switch (status.toLowerCase()) {
      case 'active': return 'check_circle';
      case 'pending': return 'schedule';
      case 'suspended': return 'block';
      default: return 'help';
    }
  }

  getStars(rating: number): string[] {
    const stars: string[] = [];
    const fullStars = Math.floor(rating);
    const hasHalfStar = rating % 1 !== 0;
    
    for (let i = 0; i < fullStars; i++) {
      stars.push('star');
    }
    
    if (hasHalfStar) {
      stars.push('star_half');
    }
    
    const emptyStars = 5 - Math.ceil(rating);
    for (let i = 0; i < emptyStars; i++) {
      stars.push('star_border');
    }
    
    return stars;
  }
}