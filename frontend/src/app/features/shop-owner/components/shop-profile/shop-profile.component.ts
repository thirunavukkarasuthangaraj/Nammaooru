import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { ShopService } from '@core/services/shop.service';
import { Shop } from '@core/models/shop.model';

@Component({
  selector: 'app-shop-profile',
  template: `
    <div class="shop-profile-container">
      <div class="page-header">
        <h1>My Shop Profile</h1>
        <p>Manage your shop information and settings</p>
      </div>

      <div class="profile-content">
        <mat-card class="profile-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>store</mat-icon>
              Shop Information
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <form [formGroup]="shopForm" (ngSubmit)="onSave()" class="shop-form">
              <div class="form-row">
                <mat-form-field appearance="outline" class="full-width">
                  <mat-label>Shop Name</mat-label>
                  <input matInput formControlName="name" placeholder="Enter shop name">
                  <mat-error *ngIf="shopForm.get('name')?.hasError('required')">
                    Shop name is required
                  </mat-error>
                </mat-form-field>
              </div>

              <div class="form-row">
                <mat-form-field appearance="outline" class="full-width">
                  <mat-label>Description</mat-label>
                  <textarea matInput 
                           formControlName="description" 
                           placeholder="Describe your shop"
                           rows="3"></textarea>
                </mat-form-field>
              </div>

              <div class="form-row">
                <mat-form-field appearance="outline" class="half-width">
                  <mat-label>Phone Number</mat-label>
                  <input matInput formControlName="phone" placeholder="Enter phone number">
                  <mat-error *ngIf="shopForm.get('phone')?.hasError('required')">
                    Phone number is required
                  </mat-error>
                </mat-form-field>
                <mat-form-field appearance="outline" class="half-width">
                  <mat-label>Email</mat-label>
                  <input matInput type="email" formControlName="email" placeholder="Enter email">
                  <mat-error *ngIf="shopForm.get('email')?.hasError('email')">
                    Please enter a valid email
                  </mat-error>
                </mat-form-field>
              </div>

              <div class="form-row">
                <mat-form-field appearance="outline" class="full-width">
                  <mat-label>Address</mat-label>
                  <textarea matInput 
                           formControlName="address" 
                           placeholder="Enter shop address"
                           rows="2"></textarea>
                  <mat-error *ngIf="shopForm.get('address')?.hasError('required')">
                    Address is required
                  </mat-error>
                </mat-form-field>
              </div>

              <div class="form-row">
                <mat-form-field appearance="outline" class="half-width">
                  <mat-label>City</mat-label>
                  <input matInput formControlName="city" placeholder="Enter city">
                  <mat-error *ngIf="shopForm.get('city')?.hasError('required')">
                    City is required
                  </mat-error>
                </mat-form-field>
                <mat-form-field appearance="outline" class="half-width">
                  <mat-label>PIN Code</mat-label>
                  <input matInput formControlName="pincode" placeholder="Enter PIN code">
                  <mat-error *ngIf="shopForm.get('pincode')?.hasError('required')">
                    PIN code is required
                  </mat-error>
                </mat-form-field>
              </div>

              <div class="form-actions">
                <button mat-raised-button color="primary" type="submit" [disabled]="shopForm.invalid || isLoading">
                  <mat-spinner *ngIf="isLoading" diameter="20" style="margin-right: 8px;"></mat-spinner>
                  <mat-icon *ngIf="!isLoading" style="margin-right: 8px;">save</mat-icon>
                  Save Changes
                </button>
                <button mat-button type="button" (click)="onReset()">
                  <mat-icon style="margin-right: 8px;">refresh</mat-icon>
                  Reset
                </button>
              </div>
            </form>
          </mat-card-content>
        </mat-card>

        <!-- Shop Status Card -->
        <mat-card class="status-card">
          <mat-card-header>
            <mat-card-title>
              <mat-icon>info</mat-icon>
              Shop Status
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="status-info">
              <div class="status-item">
                <span class="status-label">Current Status:</span>
                <span class="status-value" [class]="'status-' + shopStatus.toLowerCase()">
                  {{ shopStatus }}
                </span>
              </div>
              <div class="status-item">
                <span class="status-label">Registered On:</span>
                <span class="status-value">{{ registrationDate | date:'mediumDate' }}</span>
              </div>
              <div class="status-item">
                <span class="status-label">Total Products:</span>
                <span class="status-value">{{ totalProducts }}</span>
              </div>
              <div class="status-item">
                <span class="status-label">Total Orders:</span>
                <span class="status-value">{{ totalOrders }}</span>
              </div>
            </div>

            <mat-divider style="margin: 16px 0;"></mat-divider>

            <div class="status-actions">
              <button mat-stroked-button color="primary" routerLink="/shop-owner">
                <mat-icon>dashboard</mat-icon>
                Go to Dashboard
              </button>
              <button mat-stroked-button color="accent" routerLink="/products/my-shop">
                <mat-icon>inventory</mat-icon>
                Manage Products
              </button>
            </div>
          </mat-card-content>
        </mat-card>
      </div>
    </div>
  `,
  styles: [`
    .shop-profile-container {
      padding: 24px;
      max-width: 1200px;
      margin: 0 auto;
    }

    .page-header {
      margin-bottom: 24px;
    }

    .page-header h1 {
      font-size: 2rem;
      font-weight: 500;
      margin: 0 0 8px 0;
      color: #333;
    }

    .page-header p {
      color: #666;
      margin: 0;
      font-size: 1rem;
    }

    .profile-content {
      display: grid;
      grid-template-columns: 2fr 1fr;
      gap: 24px;
    }

    .profile-card, .status-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .profile-card mat-card-header, .status-card mat-card-header {
      background: #f8f9fa;
      margin: -16px -16px 16px -16px;
      padding: 16px;
      border-radius: 12px 12px 0 0;
    }

    .profile-card mat-card-title, .status-card mat-card-title {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 1.1rem;
      font-weight: 500;
    }

    .shop-form {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .form-row {
      display: flex;
      gap: 16px;
      align-items: flex-start;
    }

    .full-width {
      width: 100%;
    }

    .half-width {
      flex: 1;
    }

    .form-actions {
      display: flex;
      gap: 12px;
      margin-top: 8px;
    }

    .form-actions button {
      height: 48px;
    }

    .status-info {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .status-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .status-label {
      font-weight: 500;
      color: #666;
    }

    .status-value {
      font-weight: 600;
      color: #333;
    }

    .status-value.status-active {
      color: #4caf50;
    }

    .status-value.status-pending {
      color: #ff9800;
    }

    .status-value.status-suspended {
      color: #f44336;
    }

    .status-actions {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .status-actions button {
      justify-content: flex-start;
    }

    /* Mobile Responsive */
    @media (max-width: 768px) {
      .shop-profile-container {
        padding: 16px;
      }

      .profile-content {
        grid-template-columns: 1fr;
      }

      .form-row {
        flex-direction: column;
        gap: 12px;
      }

      .half-width {
        width: 100%;
      }

      .page-header h1 {
        font-size: 1.5rem;
      }

      .form-actions {
        flex-direction: column;
      }

      .status-actions {
        gap: 12px;
      }
    }
  `]
})
export class ShopProfileComponent implements OnInit {
  shopForm: FormGroup;
  isLoading = false;
  shop: Shop | null = null;
  
  // Shop statistics
  shopStatus = 'Active';
  registrationDate = new Date();
  totalProducts = 0;
  totalOrders = 0;

  constructor(
    private fb: FormBuilder,
    private shopService: ShopService,
    private snackBar: MatSnackBar
  ) {
    this.shopForm = this.fb.group({
      name: ['', [Validators.required]],
      description: [''],
      phone: ['', [Validators.required]],
      email: ['', [Validators.email]],
      address: ['', [Validators.required]],
      city: ['', [Validators.required]],
      pincode: ['', [Validators.required]]
    });
  }

  ngOnInit(): void {
    this.loadShopProfile();
  }

  private loadShopProfile(): void {
    this.isLoading = true;
    
    // Get the current user's shop from real backend
    this.shopService.getMyShop().subscribe({
      next: (shop: any) => {
        if (shop) {
          this.shop = shop;
          console.log('Shop Profile data received:', shop);
          
          // Update form with actual shop data
          this.shopForm.patchValue({
            name: shop.name || '',
            description: shop.description || '',
            phone: shop.ownerPhone || shop.phone || '',
            email: shop.ownerEmail || shop.email || '',
            address: shop.addressLine1 || shop.address || '',
            city: shop.city || '',
            pincode: shop.postalCode || shop.pincode || ''
          });
          
          // Update statistics with real data
          this.shopStatus = shop.status || 'ACTIVE';
          this.registrationDate = new Date(shop.createdAt || new Date());
          this.totalProducts = shop.productCount || 0;
          this.totalOrders = shop.totalOrders || 0;
          
          // Get additional statistics
          this.loadShopStatistics();
        } else {
          this.handleNoShopFound();
        }
        
        this.isLoading = false;
      },
      error: (error: any) => {
        console.error('Error loading shop profile:', error);
        this.isLoading = false;
        
        // Handle 404 - no shop for user
        if (error.status === 404) {
          this.handleNoShopFound();
        } else {
          this.snackBar.open('Error loading shop profile. Please try again.', 'Close', {
            duration: 3000,
            horizontalPosition: 'end',
            verticalPosition: 'top',
            panelClass: ['error-snackbar']
          });
        }
      }
    });
  }
  
  private handleNoShopFound(): void {
    this.shopForm.patchValue({
      name: '',
      description: '',
      phone: '',
      email: '',
      address: '',
      city: '',
      pincode: ''
    });
    
    this.snackBar.open('No shop found. Please contact admin to assign a shop.', 'Close', {
      duration: 5000,
      horizontalPosition: 'end',
      verticalPosition: 'top',
      panelClass: ['warning-snackbar']
    });
  }
  
  private loadShopStatistics(): void {
    // Load real statistics from backend
    if (this.shop && this.shop.id) {
      // Get total orders count
      this.shopService.getTodaysOrderCount().subscribe({
        next: (count) => {
          this.totalOrders = count;
        }
      });
      
      // Get product count
      this.shopService.getTotalProductCount().subscribe({
        next: (count) => {
          this.totalProducts = count;
        }
      });
    }
  }

  onSave(): void {
    if (this.shopForm.valid && this.shop) {
      this.isLoading = true;
      
      const updatedShop = {
        ...this.shop,
        name: this.shopForm.value.name,
        description: this.shopForm.value.description,
        ownerPhone: this.shopForm.value.phone,
        ownerEmail: this.shopForm.value.email,
        addressLine1: this.shopForm.value.address,
        city: this.shopForm.value.city,
        postalCode: this.shopForm.value.pincode
      };
      
      this.shopService.updateShop(this.shop.id, updatedShop).subscribe({
        next: (response) => {
          this.isLoading = false;
          this.shop = response;
          this.snackBar.open('Shop profile updated successfully!', 'Close', {
            duration: 3000,
            horizontalPosition: 'end',
            verticalPosition: 'top',
            panelClass: ['success-snackbar']
          });
        },
        error: (error) => {
          this.isLoading = false;
          console.error('Error updating shop profile:', error);
          this.snackBar.open('Error updating shop profile', 'Close', {
            duration: 3000,
            horizontalPosition: 'end',
            verticalPosition: 'top',
            panelClass: ['error-snackbar']
          });
        }
      });
    }
  }

  onReset(): void {
    this.loadShopProfile();
    this.snackBar.open('Form reset to saved values', 'Close', {
      duration: 2000,
      horizontalPosition: 'end',
      verticalPosition: 'top'
    });
  }
}