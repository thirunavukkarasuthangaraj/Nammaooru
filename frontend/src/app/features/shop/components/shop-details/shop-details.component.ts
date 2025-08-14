import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Shop } from '../../../../core/models/shop.model';
import { ShopService } from '../../../../core/services/shop.service';

@Component({
  selector: 'app-shop-details',
  template: `
    <div class="shop-details-container" *ngIf="shop">
      <div class="header">
        <button mat-icon-button (click)="goBack()">
          <mat-icon>arrow_back</mat-icon>
        </button>
        <h1>{{shop.name}}</h1>
        <div class="actions">
          <button mat-raised-button color="primary" (click)="editShop()">
            <mat-icon>edit</mat-icon>
            Edit Shop
          </button>
          <button mat-raised-button color="warn" (click)="deleteShop()">
            <mat-icon>delete</mat-icon>
            Delete
          </button>
        </div>
      </div>

      <div class="content">
        <mat-card class="basic-info">
          <mat-card-header>
            <mat-card-title>Basic Information</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="info-grid">
              <div class="info-item">
                <label>Shop ID:</label>
                <span>{{shop.shopId}}</span>
              </div>
              <div class="info-item">
                <label>Business Type:</label>
                <span>{{shop.businessType}}</span>
              </div>
              <div class="info-item">
                <label>Status:</label>
                <mat-chip [class]="'status-' + shop.status.toLowerCase()">{{shop.status}}</mat-chip>
              </div>
              <div class="info-item">
                <label>Rating:</label>
                <span>
                  <mat-icon class="star-icon">star</mat-icon>
                  {{shop.rating | number:'1.1-1'}} ({{shop.totalOrders}} orders)
                </span>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="contact-info">
          <mat-card-header>
            <mat-card-title>Contact Information</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="info-grid">
              <div class="info-item">
                <label>Owner Name:</label>
                <span>{{shop.ownerName}}</span>
              </div>
              <div class="info-item">
                <label>Email:</label>
                <span>{{shop.ownerEmail}}</span>
              </div>
              <div class="info-item">
                <label>Phone:</label>
                <span>{{shop.ownerPhone}}</span>
              </div>
              <div class="info-item">
                <label>Business Name:</label>
                <span>{{shop.businessName}}</span>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="address-info">
          <mat-card-header>
            <mat-card-title>Address & Location</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="info-grid">
              <div class="info-item full-width">
                <label>Address:</label>
                <span>{{shop.addressLine1}}</span>
              </div>
              <div class="info-item">
                <label>City:</label>
                <span>{{shop.city}}</span>
              </div>
              <div class="info-item">
                <label>State:</label>
                <span>{{shop.state}}</span>
              </div>
              <div class="info-item">
                <label>Postal Code:</label>
                <span>{{shop.postalCode}}</span>
              </div>
              <div class="info-item">
                <label>Country:</label>
                <span>{{shop.country}}</span>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="business-settings">
          <mat-card-header>
            <mat-card-title>Business Settings</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="info-grid">
              <div class="info-item">
                <label>Min Order Amount:</label>
                <span>₹{{shop.minOrderAmount || 0}}</span>
              </div>
              <div class="info-item">
                <label>Delivery Fee:</label>
                <span>₹{{shop.deliveryFee || 0}}</span>
              </div>
              <div class="info-item">
                <label>Delivery Radius:</label>
                <span>{{shop.deliveryRadius || 0}} km</span>
              </div>
              <div class="info-item">
                <label>Free Delivery Above:</label>
                <span>₹{{shop.freeDeliveryAbove || 0}}</span>
              </div>
              <div class="info-item">
                <label>Commission Rate:</label>
                <span>{{shop.commissionRate || 0}}%</span>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="features" *ngIf="hasFeatures()">
          <mat-card-header>
            <mat-card-title>Features</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <mat-chip-listbox>
              <mat-chip *ngIf="shop.isVerified" class="feature-chip verified">
                <mat-icon>verified</mat-icon>
                Verified
              </mat-chip>
              <mat-chip *ngIf="shop.isFeatured" class="feature-chip featured">
                <mat-icon>star</mat-icon>
                Featured
              </mat-chip>
              <mat-chip *ngIf="shop.isActive" class="feature-chip active">
                <mat-icon>check_circle</mat-icon>
                Active
              </mat-chip>
            </mat-chip-listbox>
          </mat-card-content>
        </mat-card>
      </div>
    </div>

    <div class="loading" *ngIf="loading">
      <mat-progress-spinner mode="indeterminate"></mat-progress-spinner>
    </div>

    <div class="error" *ngIf="error">
      <mat-card>
        <mat-card-content>
          <mat-icon color="warn">error</mat-icon>
          <h3>Error Loading Shop</h3>
          <p>{{error}}</p>
          <button mat-raised-button (click)="goBack()">Go Back</button>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .shop-details-container {
      padding: 20px;
      max-width: 1200px;
      margin: 0 auto;
    }

    .header {
      display: flex;
      align-items: center;
      gap: 20px;
      margin-bottom: 30px;
    }

    .header h1 {
      flex: 1;
      margin: 0;
    }

    .actions {
      display: flex;
      gap: 10px;
    }

    .content {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
      gap: 20px;
    }

    .info-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 15px;
    }

    .info-item {
      display: flex;
      flex-direction: column;
      gap: 5px;
    }

    .info-item.full-width {
      grid-column: 1 / -1;
    }

    .info-item label {
      font-weight: 500;
      color: #666;
      font-size: 14px;
    }

    .info-item span {
      font-size: 16px;
    }

    .star-icon {
      color: #ffd700;
      vertical-align: middle;
      margin-right: 5px;
    }

    .feature-chip {
      margin-right: 10px;
    }

    .feature-chip.verified {
      background-color: #4caf50;
      color: white;
    }

    .feature-chip.featured {
      background-color: #ff9800;
      color: white;
    }

    .feature-chip.active {
      background-color: #2196f3;
      color: white;
    }

    .status-pending {
      background-color: #ff9800;
      color: white;
    }

    .status-approved {
      background-color: #4caf50;
      color: white;
    }

    .status-rejected {
      background-color: #f44336;
      color: white;
    }

    .loading {
      display: flex;
      justify-content: center;
      align-items: center;
      height: 200px;
    }

    .error {
      text-align: center;
      padding: 40px;
    }

    .error mat-icon {
      font-size: 48px;
      height: 48px;
      width: 48px;
    }
  `]
})
export class ShopDetailsComponent implements OnInit {
  shop: Shop | null = null;
  loading = false;
  error = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private shopService: ShopService
  ) {}

  ngOnInit() {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.loadShop(+id);
    }
  }

  loadShop(id: number) {
    this.loading = true;
    this.shopService.getShop(id).subscribe({
      next: (shop) => {
        this.shop = shop;
        this.loading = false;
      },
      error: (error) => {
        this.error = 'Failed to load shop details';
        this.loading = false;
        console.error('Error loading shop:', error);
      }
    });
  }

  editShop() {
    if (this.shop) {
      this.router.navigate(['/shops', this.shop.id, 'edit']);
    }
  }

  deleteShop() {
    if (this.shop && confirm(`Are you sure you want to delete ${this.shop.name}?`)) {
      this.shopService.deleteShop(this.shop.id).subscribe({
        next: () => {
          this.router.navigate(['/shops']);
        },
        error: (error) => {
          console.error('Error deleting shop:', error);
        }
      });
    }
  }

  goBack() {
    this.router.navigate(['/shops']);
  }

  hasFeatures(): boolean {
    return !!(this.shop?.isVerified || this.shop?.isFeatured || this.shop?.isActive);
  }
}