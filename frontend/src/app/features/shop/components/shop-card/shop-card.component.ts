import { Component, Input, Output, EventEmitter } from '@angular/core';
import { Router } from '@angular/router';
import { Shop, ShopStatus, BusinessType } from '@core/models/shop.model';
import { AuthService } from '@core/services/auth.service';

@Component({
  selector: 'app-shop-card',
  template: `
    <mat-card class="shop-card" [class]="'status-' + shop.status.toLowerCase()">
      <div class="card-header">
        <img 
          [src]="getPrimaryImage()" 
          [alt]="shop.name"
          class="shop-image"
          (error)="onImageError($event)">
        
        <div class="status-overlay">
          <span class="status-chip" [class]="'status-' + shop.status.toLowerCase()">
            {{shop.status}}
          </span>
          <span class="business-type-chip">{{shop.businessType}}</span>
        </div>

        <div class="action-overlay" *ngIf="canManageShops()">
          <button mat-icon-button [matMenuTriggerFor]="actionMenu" class="action-button">
            <mat-icon>more_vert</mat-icon>
          </button>
          
          <mat-menu #actionMenu="matMenu">
            <button mat-menu-item (click)="editShop()">
              <mat-icon>edit</mat-icon>
              Edit
            </button>
            <button mat-menu-item (click)="viewDetails()">
              <mat-icon>visibility</mat-icon>
              View Details
            </button>
            <mat-divider></mat-divider>
            <button mat-menu-item (click)="deleteShop()" class="delete-action">
              <mat-icon>delete</mat-icon>
              Delete
            </button>
          </mat-menu>
        </div>
      </div>

      <mat-card-content class="card-content">
        <div class="shop-header">
          <h3 class="shop-name" [title]="shop.name">{{shop.name}}</h3>
          <div class="shop-rating" *ngIf="shop.rating > 0">
            <mat-icon class="star-icon">star</mat-icon>
            <span>{{shop.rating | number:'1.1-1'}}</span>
            <span class="orders-count">({{shop.totalOrders}} orders)</span>
          </div>
        </div>

        <p class="shop-description" *ngIf="shop.description" [title]="shop.description">
          {{shop.description | slice:0:120}}{{shop.description.length > 120 ? '...' : ''}}
        </p>

        <div class="shop-info">
          <div class="info-row">
            <mat-icon class="info-icon">location_on</mat-icon>
            <span>{{shop.city}}, {{shop.state}}</span>
          </div>
          
          <div class="info-row">
            <mat-icon class="info-icon">phone</mat-icon>
            <span>{{shop.ownerPhone}}</span>
          </div>
          
          <div class="info-row" *ngIf="shop.minOrderAmount > 0">
            <mat-icon class="info-icon">shopping_cart</mat-icon>
            <span>Min Order: ₹{{shop.minOrderAmount}}</span>
          </div>
          
          <div class="info-row" *ngIf="shop.deliveryRadius > 0">
            <mat-icon class="info-icon">local_shipping</mat-icon>
            <span>Delivery: {{shop.deliveryRadius}}km (Distance-based pricing)</span>
          </div>
        </div>

        <div class="features-row">
          <mat-chip-listbox>
            <mat-chip *ngIf="shop.isVerified" class="feature-chip verified">
              <mat-icon>verified</mat-icon>
              Verified
            </mat-chip>
            <mat-chip *ngIf="shop.isFeatured" class="feature-chip featured">
              <mat-icon>star</mat-icon>
              Featured
            </mat-chip>
            <mat-chip *ngIf="shop.freeDeliveryAbove" class="feature-chip free-delivery">
              <mat-icon>local_shipping</mat-icon>
              Free Delivery
            </mat-chip>
          </mat-chip-listbox>
        </div>
      </mat-card-content>

      <mat-card-actions class="card-actions">
        <button mat-button color="primary" (click)="viewDetails()">
          <mat-icon>visibility</mat-icon>
          View Details
        </button>
        
        <button mat-button (click)="getDirections()" *ngIf="shop.latitude && shop.longitude">
          <mat-icon>directions</mat-icon>
          Directions
        </button>
        
        <div class="spacer"></div>
        
        <span class="shop-id">ID: {{shop.shopId}}</span>
      </mat-card-actions>
    </mat-card>
  `,
  styles: [`
    .shop-card {
      max-width: 400px;
      margin: 16px;
      transition: transform 0.2s ease, box-shadow 0.2s ease;
      position: relative;
      overflow: hidden;
    }

    .shop-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 8px 24px rgba(0,0,0,0.15);
    }

    .card-header {
      position: relative;
      height: 200px;
      overflow: hidden;
    }

    .shop-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
      transition: transform 0.3s ease;
    }

    .shop-card:hover .shop-image {
      transform: scale(1.05);
    }

    .status-overlay {
      position: absolute;
      top: 12px;
      left: 12px;
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }

    .status-chip, .business-type-chip {
      padding: 4px 8px;
      border-radius: 12px;
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      backdrop-filter: blur(8px);
    }

    .business-type-chip {
      background: rgba(103, 58, 183, 0.9);
      color: white;
    }

    .status-pending { background: rgba(255, 193, 7, 0.9); color: #333; }
    .status-approved { background: rgba(76, 175, 80, 0.9); color: white; }
    .status-rejected { background: rgba(244, 67, 54, 0.9); color: white; }
    .status-suspended { background: rgba(156, 39, 176, 0.9); color: white; }

    .action-overlay {
      position: absolute;
      top: 12px;
      right: 12px;
    }

    .action-button {
      background: rgba(255, 255, 255, 0.9);
      backdrop-filter: blur(8px);
      color: #333;
    }

    .card-content {
      padding: 16px;
    }

    .shop-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 12px;
    }

    .shop-name {
      margin: 0;
      font-size: 18px;
      font-weight: 600;
      color: #333;
      flex: 1;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .shop-rating {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 14px;
      color: #666;
    }

    .star-icon {
      color: #ffc107;
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .orders-count {
      font-size: 12px;
      color: #999;
    }

    .shop-description {
      color: #666;
      font-size: 14px;
      line-height: 1.4;
      margin: 0 0 16px 0;
      overflow: hidden;
      display: -webkit-box;
      -webkit-line-clamp: 3;
      -webkit-box-orient: vertical;
    }

    .shop-info {
      margin-bottom: 16px;
    }

    .info-row {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 8px;
      font-size: 14px;
      color: #666;
    }

    .info-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
      color: #999;
    }

    .features-row {
      margin-bottom: 8px;
    }

    .feature-chip {
      display: inline-flex;
      align-items: center;
      gap: 4px;
      font-size: 11px;
      padding: 4px 8px;
      margin: 2px;
    }

    .feature-chip mat-icon {
      font-size: 14px;
      width: 14px;
      height: 14px;
    }

    .verified { background: #e8f5e8; color: #2e7d32; }
    .featured { background: #fff3e0; color: #f57c00; }
    .free-delivery { background: #e3f2fd; color: #1976d2; }

    .card-actions {
      padding: 8px 16px 16px;
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .spacer {
      flex: 1;
    }

    .shop-id {
      font-size: 12px;
      color: #999;
      font-family: monospace;
    }

    .delete-action {
      color: #f44336 !important;
    }

    /* Mobile responsiveness */
    @media (max-width: 768px) {
      .shop-card {
        margin: 8px;
        max-width: calc(100vw - 32px);
      }

      .card-header {
        height: 160px;
      }

      .shop-header {
        flex-direction: column;
        gap: 8px;
        align-items: flex-start;
      }

      .info-row {
        font-size: 13px;
      }

      .card-actions {
        flex-wrap: wrap;
      }
    }
  `]
})
export class ShopCardComponent {
  @Input() shop!: Shop;
  @Output() onEdit = new EventEmitter<Shop>();
  @Output() onDelete = new EventEmitter<Shop>();
  @Output() onView = new EventEmitter<Shop>();

  constructor(
    private router: Router,
    private authService: AuthService
  ) {}

  getPrimaryImage(): string {
    const primaryImage = this.shop.images?.find(img => img.isPrimary);
    if (primaryImage) {
      return primaryImage.imageUrl;
    }
    
    const firstImage = this.shop.images?.[0];
    if (firstImage) {
      return firstImage.imageUrl;
    }
    
    // Default placeholder based on business type
    switch (this.shop.businessType) {
      case BusinessType.GROCERY:
        return 'assets/images/shop-grocery-default.jpg';
      case BusinessType.PHARMACY:
        return 'assets/images/shop-pharmacy-default.jpg';
      case BusinessType.RESTAURANT:
        return 'assets/images/shop-restaurant-default.jpg';
      default:
        return 'assets/images/shop-default.jpg';
    }
  }

  onImageError(event: any): void {
    event.target.src = 'assets/images/shop-default.jpg';
  }

  canManageShops(): boolean {
    return this.authService.canManageShops();
  }

  viewDetails(): void {
    this.onView.emit(this.shop);
    this.router.navigate(['/shops', this.shop.id]);
  }

  editShop(): void {
    this.onEdit.emit(this.shop);
    this.router.navigate(['/shops', this.shop.id, 'edit']);
  }

  deleteShop(): void {
    if (confirm(`Are you sure you want to delete "${this.shop.name}"?`)) {
      this.onDelete.emit(this.shop);
    }
  }

  getDirections(): void {
    if (this.shop.latitude && this.shop.longitude) {
      const url = `https://www.google.com/maps/dir/?api=1&destination=${this.shop.latitude},${this.shop.longitude}`;
      window.open(url, '_blank');
    }
  }
}