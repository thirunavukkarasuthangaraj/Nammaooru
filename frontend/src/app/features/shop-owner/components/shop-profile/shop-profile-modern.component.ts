import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { ShopService } from '@core/services/shop.service';
import { Shop } from '@core/models/shop.model';

@Component({
  selector: 'app-shop-profile',
  template: `
    <div class="shop-profile-modern">
      <!-- Header Section with Cover Image -->
      <div class="profile-header">
        <div class="cover-image">
          <img [src]="coverImage || 'assets/images/default-cover.jpg'" alt="Shop Cover">
          <button mat-fab class="change-cover-btn" color="primary">
            <mat-icon>camera_alt</mat-icon>
          </button>
        </div>
        
        <div class="shop-identity">
          <div class="logo-section">
            <img [src]="shopLogo || 'assets/images/default-shop.png'" alt="Shop Logo" class="shop-logo">
            <button mat-mini-fab class="change-logo-btn" color="accent">
              <mat-icon>edit</mat-icon>
            </button>
          </div>
          
          <div class="shop-basic-info">
            <h1>{{ shop?.name || 'Your Shop Name' }}</h1>
            <div class="status-badges">
              <span class="status-badge" [class.active]="shop?.status === 'APPROVED'">
                <mat-icon>{{ shop?.status === 'APPROVED' ? 'verified' : 'schedule' }}</mat-icon>
                {{ shop?.status || 'PENDING' }}
              </span>
              <span class="rating-badge">
                <mat-icon>star</mat-icon>
                {{ shop?.rating || '4.5' }} ({{ shop?.reviewCount || '234' }} reviews)
              </span>
              <span class="delivery-badge">
                <mat-icon>delivery_dining</mat-icon>
                30-40 mins
              </span>
            </div>
          </div>
          
          <div class="quick-stats">
            <div class="stat-card">
              <span class="stat-value">{{ totalOrders || 0 }}</span>
              <span class="stat-label">Total Orders</span>
            </div>
            <div class="stat-card">
              <span class="stat-value">{{ totalProducts || 0 }}</span>
              <span class="stat-label">Products</span>
            </div>
            <div class="stat-card">
              <span class="stat-value">{{ shop?.customerCount || 0 }}</span>
              <span class="stat-label">Customers</span>
            </div>
            <div class="stat-card">
              <span class="stat-value">₹{{ monthlyRevenue || '0' }}</span>
              <span class="stat-label">This Month</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Navigation Tabs -->
      <mat-tab-group class="profile-tabs" animationDuration="300ms">
        
        <!-- Basic Information Tab -->
        <mat-tab>
          <ng-template mat-tab-label>
            <mat-icon>info</mat-icon>
            <span>Basic Information</span>
          </ng-template>
          
          <div class="tab-content">
            <form [formGroup]="shopForm" class="modern-form">
              <div class="form-section">
                <h3>Shop Details</h3>
                <div class="form-grid">
                  <mat-form-field appearance="outline" class="full-width">
                    <mat-label>Shop Name</mat-label>
                    <input matInput formControlName="name" placeholder="Enter your shop name">
                    <mat-icon matPrefix>store</mat-icon>
                    <mat-error>Shop name is required</mat-error>
                  </mat-form-field>

                  <mat-form-field appearance="outline" class="full-width">
                    <mat-label>Description</mat-label>
                    <textarea matInput formControlName="description" rows="4" 
                             placeholder="Tell customers about your shop"></textarea>
                    <mat-hint>Make it appealing to customers</mat-hint>
                  </mat-form-field>

                  <mat-form-field appearance="outline">
                    <mat-label>Business Type</mat-label>
                    <mat-select formControlName="businessType">
                      <mat-option value="RESTAURANT">Restaurant</mat-option>
                      <mat-option value="GROCERY">Grocery</mat-option>
                      <mat-option value="PHARMACY">Pharmacy</mat-option>
                      <mat-option value="ELECTRONICS">Electronics</mat-option>
                      <mat-option value="FASHION">Fashion</mat-option>
                    </mat-select>
                    <mat-icon matPrefix>category</mat-icon>
                  </mat-form-field>

                  <mat-form-field appearance="outline">
                    <mat-label>Cuisines/Categories</mat-label>
                    <mat-chip-list #chipList>
                      <mat-chip *ngFor="let tag of tags" [removable]="true" (removed)="removeTag(tag)">
                        {{ tag }}
                        <mat-icon matChipRemove>cancel</mat-icon>
                      </mat-chip>
                      <input placeholder="Add category..."
                             [matChipInputFor]="chipList"
                             [matChipInputAddOnBlur]="true"
                             (matChipInputTokenEnd)="addTag($event)">
                    </mat-chip-list>
                  </mat-form-field>
                </div>
              </div>

              <div class="form-section">
                <h3>Contact Information</h3>
                <div class="form-grid">
                  <mat-form-field appearance="outline">
                    <mat-label>Phone Number</mat-label>
                    <input matInput formControlName="phone" placeholder="+91 98765 43210">
                    <mat-icon matPrefix>phone</mat-icon>
                    <mat-error>Valid phone number required</mat-error>
                  </mat-form-field>

                  <mat-form-field appearance="outline">
                    <mat-label>WhatsApp Number</mat-label>
                    <input matInput formControlName="whatsapp" placeholder="+91 98765 43210">
                    <mat-icon matPrefix>chat</mat-icon>
                  </mat-form-field>

                  <mat-form-field appearance="outline">
                    <mat-label>Email Address</mat-label>
                    <input matInput type="email" formControlName="email" placeholder="shop@example.com">
                    <mat-icon matPrefix>email</mat-icon>
                    <mat-error>Valid email required</mat-error>
                  </mat-form-field>

                  <mat-form-field appearance="outline">
                    <mat-label>Website</mat-label>
                    <input matInput formControlName="website" placeholder="https://yourshop.com">
                    <mat-icon matPrefix>language</mat-icon>
                  </mat-form-field>
                </div>
              </div>

              <div class="form-section">
                <h3>Location Details</h3>
                <div class="form-grid">
                  <mat-form-field appearance="outline" class="full-width">
                    <mat-label>Complete Address</mat-label>
                    <textarea matInput formControlName="address" rows="2" 
                             placeholder="Building, Street, Landmark"></textarea>
                    <mat-icon matPrefix>location_on</mat-icon>
                    <mat-error>Address is required</mat-error>
                  </mat-form-field>

                  <mat-form-field appearance="outline">
                    <mat-label>City</mat-label>
                    <input matInput formControlName="city" placeholder="Chennai">
                    <mat-icon matPrefix>location_city</mat-icon>
                    <mat-error>City is required</mat-error>
                  </mat-form-field>

                  <mat-form-field appearance="outline">
                    <mat-label>State</mat-label>
                    <mat-select formControlName="state">
                      <mat-option value="Tamil Nadu">Tamil Nadu</mat-option>
                      <mat-option value="Karnataka">Karnataka</mat-option>
                      <mat-option value="Kerala">Kerala</mat-option>
                      <mat-option value="Maharashtra">Maharashtra</mat-option>
                    </mat-select>
                  </mat-form-field>

                  <mat-form-field appearance="outline">
                    <mat-label>PIN Code</mat-label>
                    <input matInput formControlName="pincode" placeholder="600001">
                    <mat-icon matPrefix>pin_drop</mat-icon>
                    <mat-error>Valid PIN code required</mat-error>
                  </mat-form-field>

                  <mat-form-field appearance="outline">
                    <mat-label>Google Maps Link</mat-label>
                    <input matInput formControlName="mapLink" placeholder="https://maps.google.com/...">
                    <mat-icon matPrefix>map</mat-icon>
                  </mat-form-field>
                </div>

                <div class="map-preview">
                  <iframe 
                    src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3886.0!2d80.2707!3d13.0827!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zMTPCsDA0JzU3LjciTiA4MMKwMTYnMTQuNSJF!5e0!3m2!1sen!2sin!4v1234567890"
                    width="100%" 
                    height="250" 
                    style="border:0; border-radius: 8px;" 
                    allowfullscreen="" 
                    loading="lazy">
                  </iframe>
                </div>
              </div>

              <div class="form-actions">
                <button mat-button type="button" (click)="onReset()" class="reset-btn">
                  <mat-icon>refresh</mat-icon>
                  Reset Changes
                </button>
                <button mat-raised-button color="primary" type="submit" (click)="onSave()" 
                        [disabled]="shopForm.invalid || isLoading" class="save-btn">
                  <mat-spinner *ngIf="isLoading" diameter="20"></mat-spinner>
                  <mat-icon *ngIf="!isLoading">save</mat-icon>
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </mat-tab>

        <!-- Business Hours Tab -->
        <mat-tab>
          <ng-template mat-tab-label>
            <mat-icon>schedule</mat-icon>
            <span>Business Hours</span>
          </ng-template>
          
          <div class="tab-content">
            <app-business-hours></app-business-hours>
          </div>
        </mat-tab>

        <!-- Gallery Tab -->
        <mat-tab>
          <ng-template mat-tab-label>
            <mat-icon>photo_library</mat-icon>
            <span>Gallery</span>
          </ng-template>
          
          <div class="tab-content">
            <div class="gallery-section">
              <h3>Shop Images</h3>
              <div class="image-grid">
                <div class="image-card" *ngFor="let image of shopImages">
                  <img [src]="image.url" [alt]="image.caption">
                  <div class="image-overlay">
                    <button mat-icon-button color="warn" (click)="deleteImage(image)">
                      <mat-icon>delete</mat-icon>
                    </button>
                  </div>
                </div>
                <div class="add-image-card" (click)="uploadImage()">
                  <mat-icon>add_photo_alternate</mat-icon>
                  <span>Add Image</span>
                </div>
              </div>
            </div>
          </div>
        </mat-tab>

        <!-- Settings Tab -->
        <mat-tab>
          <ng-template mat-tab-label>
            <mat-icon>settings</mat-icon>
            <span>Settings</span>
          </ng-template>
          
          <div class="tab-content">
            <app-shop-settings></app-shop-settings>
          </div>
        </mat-tab>
      </mat-tab-group>
    </div>
  `,
  styles: [`
    .shop-profile-modern {
      background: #f8f9fa;
      min-height: 100vh;
    }

    /* Header Section */
    .profile-header {
      background: white;
      border-radius: 0 0 24px 24px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.08);
      margin-bottom: 24px;
      overflow: hidden;
    }

    .cover-image {
      position: relative;
      height: 280px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      overflow: hidden;
    }

    .cover-image img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      opacity: 0.9;
    }

    .change-cover-btn {
      position: absolute;
      bottom: 16px;
      right: 16px;
    }

    .shop-identity {
      padding: 0 32px 32px;
      margin-top: -60px;
      position: relative;
    }

    .logo-section {
      position: relative;
      display: inline-block;
    }

    .shop-logo {
      width: 120px;
      height: 120px;
      border-radius: 20px;
      border: 4px solid white;
      background: white;
      box-shadow: 0 4px 20px rgba(0,0,0,0.15);
      object-fit: cover;
    }

    .change-logo-btn {
      position: absolute;
      bottom: 0;
      right: 0;
    }

    .shop-basic-info {
      margin-top: 16px;
    }

    .shop-basic-info h1 {
      font-size: 2rem;
      font-weight: 700;
      margin: 0 0 12px 0;
      color: #1a1a1a;
    }

    .status-badges {
      display: flex;
      gap: 16px;
      flex-wrap: wrap;
    }

    .status-badge, .rating-badge, .delivery-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 12px;
      border-radius: 20px;
      font-size: 0.875rem;
      font-weight: 500;
    }

    .status-badge {
      background: #fee2e2;
      color: #dc2626;
    }

    .status-badge.active {
      background: #dcfce7;
      color: #16a34a;
    }

    .rating-badge {
      background: #fef3c7;
      color: #d97706;
    }

    .delivery-badge {
      background: #e0e7ff;
      color: #4f46e5;
    }

    .status-badge mat-icon,
    .rating-badge mat-icon,
    .delivery-badge mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    /* Quick Stats */
    .quick-stats {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
      gap: 16px;
      margin-top: 24px;
    }

    .stat-card {
      background: #f8f9fa;
      padding: 16px;
      border-radius: 12px;
      text-align: center;
      border: 1px solid #e5e7eb;
    }

    .stat-value {
      display: block;
      font-size: 1.75rem;
      font-weight: 700;
      color: #1a1a1a;
      margin-bottom: 4px;
    }

    .stat-label {
      font-size: 0.875rem;
      color: #6b7280;
      font-weight: 500;
    }

    /* Tabs Styling */
    .profile-tabs {
      background: white;
      border-radius: 16px;
      margin: 0 16px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.05);
    }

    ::ng-deep .profile-tabs .mat-tab-label {
      height: 56px;
      font-weight: 500;
    }

    ::ng-deep .profile-tabs .mat-tab-label mat-icon {
      margin-right: 8px;
    }

    .tab-content {
      padding: 32px;
    }

    /* Modern Form Styling */
    .modern-form {
      max-width: 900px;
      margin: 0 auto;
    }

    .form-section {
      margin-bottom: 40px;
    }

    .form-section h3 {
      font-size: 1.25rem;
      font-weight: 600;
      color: #1a1a1a;
      margin: 0 0 20px 0;
      padding-bottom: 12px;
      border-bottom: 2px solid #e5e7eb;
    }

    .form-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 20px;
    }

    .full-width {
      grid-column: 1 / -1;
    }

    ::ng-deep .mat-form-field-appearance-outline .mat-form-field-wrapper {
      margin: 0;
    }

    ::ng-deep .mat-form-field-appearance-outline .mat-form-field-flex {
      padding: 0 14px;
    }

    ::ng-deep .mat-form-field-appearance-outline .mat-form-field-infix {
      padding: 14px 0;
    }

    /* Map Preview */
    .map-preview {
      margin-top: 20px;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }

    /* Gallery Section */
    .gallery-section h3 {
      font-size: 1.25rem;
      font-weight: 600;
      margin-bottom: 20px;
    }

    .image-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
      gap: 16px;
    }

    .image-card {
      position: relative;
      border-radius: 12px;
      overflow: hidden;
      aspect-ratio: 1;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }

    .image-card img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    .image-overlay {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0,0,0,0.5);
      display: flex;
      align-items: center;
      justify-content: center;
      opacity: 0;
      transition: opacity 0.3s;
    }

    .image-card:hover .image-overlay {
      opacity: 1;
    }

    .add-image-card {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      border: 2px dashed #d1d5db;
      border-radius: 12px;
      aspect-ratio: 1;
      cursor: pointer;
      transition: all 0.3s;
      background: #f9fafb;
    }

    .add-image-card:hover {
      border-color: #6366f1;
      background: #eef2ff;
    }

    .add-image-card mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      color: #9ca3af;
      margin-bottom: 8px;
    }

    .add-image-card span {
      color: #6b7280;
      font-weight: 500;
    }

    /* Form Actions */
    .form-actions {
      display: flex;
      justify-content: flex-end;
      gap: 16px;
      padding-top: 24px;
      border-top: 1px solid #e5e7eb;
      margin-top: 32px;
    }

    .reset-btn {
      color: #6b7280;
    }

    .save-btn {
      min-width: 140px;
    }

    /* Responsive Design */
    @media (max-width: 768px) {
      .shop-identity {
        padding: 0 16px 24px;
      }

      .shop-basic-info h1 {
        font-size: 1.5rem;
      }

      .quick-stats {
        grid-template-columns: repeat(2, 1fr);
      }

      .form-grid {
        grid-template-columns: 1fr;
      }

      .tab-content {
        padding: 16px;
      }

      .image-grid {
        grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
      }
    }

    /* Loading State */
    mat-spinner {
      display: inline-block;
      margin-right: 8px;
    }
  `]
})
export class ShopProfileModernComponent implements OnInit {
  shopForm: FormGroup;
  isLoading = false;
  shop: Shop | null = null;
  
  // Statistics
  totalOrders = 0;
  totalProducts = 0;
  monthlyRevenue = '0';
  
  // Images
  coverImage = '';
  shopLogo = '';
  shopImages: any[] = [];
  
  // Tags/Categories
  tags: string[] = ['South Indian', 'Fast Food', 'Beverages'];

  constructor(
    private fb: FormBuilder,
    private shopService: ShopService,
    private snackBar: MatSnackBar
  ) {
    this.shopForm = this.fb.group({
      name: ['', [Validators.required]],
      description: [''],
      businessType: [''],
      phone: ['', [Validators.required, Validators.pattern('^[0-9]{10}$')]],
      whatsapp: [''],
      email: ['', [Validators.email]],
      website: [''],
      address: ['', [Validators.required]],
      city: ['', [Validators.required]],
      state: ['Tamil Nadu'],
      pincode: ['', [Validators.required, Validators.pattern('^[0-9]{6}$')]],
      mapLink: ['']
    });
  }

  ngOnInit(): void {
    this.loadShopProfile();
  }

  private loadShopProfile(): void {
    this.isLoading = true;
    
    this.shopService.getMyShop().subscribe({
      next: (shop: any) => {
        if (shop) {
          this.shop = shop;
          this.updateFormWithShopData(shop);
          this.loadStatistics();
        }
        this.isLoading = false;
      },
      error: (error: any) => {
        console.error('Error loading shop:', error);
        this.isLoading = false;
        
        if (error.status === 404) {
          this.snackBar.open('No shop assigned. Contact admin.', 'Close', {
            duration: 5000
          });
        }
      }
    });
  }

  private updateFormWithShopData(shop: any): void {
    this.shopForm.patchValue({
      name: shop.name || '',
      description: shop.description || '',
      businessType: shop.businessType || '',
      phone: shop.ownerPhone || '',
      whatsapp: shop.whatsappNumber || '',
      email: shop.ownerEmail || '',
      website: shop.website || '',
      address: shop.addressLine1 || '',
      city: shop.city || '',
      state: shop.state || 'Tamil Nadu',
      pincode: shop.postalCode || '',
      mapLink: shop.googleMapsLink || ''
    });
    
    // Load images
    this.coverImage = shop.coverImage || '';
    this.shopLogo = shop.logo || '';
    this.shopImages = shop.images || [];
  }

  private loadStatistics(): void {
    if (this.shop && this.shop.id) {
      // Load real statistics
      this.shopService.getTodaysOrderCount().subscribe({
        next: (count) => this.totalOrders = count
      });
      
      this.shopService.getTotalProductCount().subscribe({
        next: (count) => this.totalProducts = count
      });
      
      this.shopService.getTodaysRevenue().subscribe({
        next: (revenue) => this.monthlyRevenue = revenue.toString()
      });
    }
  }

  onSave(): void {
    if (this.shopForm.valid && this.shop) {
      this.isLoading = true;
      
      const updatedShop = {
        ...this.shop,
        ...this.shopForm.value
      };
      
      this.shopService.updateShop(this.shop.id, updatedShop).subscribe({
        next: (response) => {
          this.isLoading = false;
          this.shop = response;
          this.snackBar.open('Shop profile updated successfully!', 'Close', {
            duration: 3000,
            panelClass: ['success-snackbar']
          });
        },
        error: (error) => {
          this.isLoading = false;
          this.snackBar.open('Error updating profile', 'Close', {
            duration: 3000,
            panelClass: ['error-snackbar']
          });
        }
      });
    }
  }

  onReset(): void {
    if (this.shop) {
      this.updateFormWithShopData(this.shop);
      this.snackBar.open('Form reset', 'Close', { duration: 2000 });
    }
  }

  addTag(event: any): void {
    const value = event.value?.trim();
    if (value && !this.tags.includes(value)) {
      this.tags.push(value);
    }
    event.chipInput?.clear();
  }

  removeTag(tag: string): void {
    const index = this.tags.indexOf(tag);
    if (index >= 0) {
      this.tags.splice(index, 1);
    }
  }

  uploadImage(): void {
    // TODO: Implement image upload
    this.snackBar.open('Image upload coming soon', 'Close', { duration: 2000 });
  }

  deleteImage(image: any): void {
    // TODO: Implement image deletion
    this.snackBar.open('Image deletion coming soon', 'Close', { duration: 2000 });
  }
}