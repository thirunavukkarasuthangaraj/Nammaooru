import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatDialog } from '@angular/material/dialog';
import { ShopService } from '@core/services/shop.service';
import { AuthService } from '@core/services/auth.service';
import { SettingsService } from '@core/services/settings.service';
import { finalize } from 'rxjs/operators';

interface ShopSettings {
  id: number;
  shopName: string;
  description: string;
  contactNumber: string;
  email: string;
  address: string;
  city: string;
  state: string;
  pincode: string;
  businessHours: {
    monday: { open: string; close: string; closed: boolean };
    tuesday: { open: string; close: string; closed: boolean };
    wednesday: { open: string; close: string; closed: boolean };
    thursday: { open: string; close: string; closed: boolean };
    friday: { open: string; close: string; closed: boolean };
    saturday: { open: string; close: string; closed: boolean };
    sunday: { open: string; close: string; closed: boolean };
  };
  notifications: {
    emailNotifications: boolean;
    smsNotifications: boolean;
    orderAlerts: boolean;
    lowStockAlerts: boolean;
    customerMessages: boolean;
  };
  business: {
    gstNumber: string;
    panNumber: string;
    minimumOrderAmount: number;
    deliveryRadius: number;
    deliveryFee: number;
    freeDeliveryAbove: number;
  };
  integrations: {
    paymentGateway: string;
    inventorySync: boolean;
    autoStockUpdate: boolean;
    emailService: boolean;
    smsService: boolean;
  };
}

@Component({
  selector: 'app-shop-settings',
  template: `
    <div class="shop-settings-container">
      <!-- Header -->
      <div class="page-header">
        <div class="header-content">
          <h1 class="page-title">Shop Settings</h1>
          <p class="page-subtitle">Manage your shop preferences and configurations</p>
        </div>
        <div class="header-actions">
          <button mat-stroked-button (click)="exportSettings()">
            <mat-icon>download</mat-icon>
            Export Settings
          </button>
          <button mat-raised-button color="primary" (click)="saveAllSettings()" [disabled]="loading">
            <mat-icon>save</mat-icon>
            Save Changes
          </button>
        </div>
      </div>

      <!-- Loading State -->
      <div *ngIf="loading && !settingsLoaded" class="loading-container">
        <mat-spinner></mat-spinner>
        <p>Loading shop settings...</p>
      </div>

      <!-- Settings Tabs -->
      <mat-card class="settings-card" *ngIf="!loading || settingsLoaded">
        <mat-tab-group>
          <!-- Shop Information Tab -->
          <mat-tab label="Shop Information">
            <div class="tab-content">
              <form [formGroup]="shopInfoForm" class="settings-form">
                <div class="form-section">
                  <h3 class="section-title">Basic Information</h3>
                  <div class="form-grid">
                    <mat-form-field appearance="outline">
                      <mat-label>Shop Name</mat-label>
                      <input matInput formControlName="shopName" placeholder="Enter shop name">
                      <mat-error *ngIf="shopInfoForm.get('shopName')?.hasError('required')">
                        Shop name is required
                      </mat-error>
                    </mat-form-field>

                    <mat-form-field appearance="outline">
                      <mat-label>Contact Number</mat-label>
                      <input matInput formControlName="contactNumber" placeholder="+91 9876543210">
                      <mat-error *ngIf="shopInfoForm.get('contactNumber')?.hasError('required')">
                        Contact number is required
                      </mat-error>
                    </mat-form-field>

                    <mat-form-field appearance="outline" class="full-width">
                      <mat-label>Email</mat-label>
                      <input matInput type="email" formControlName="email" placeholder="shop@example.com">
                      <mat-error *ngIf="shopInfoForm.get('email')?.hasError('email')">
                        Please enter a valid email
                      </mat-error>
                    </mat-form-field>

                    <mat-form-field appearance="outline" class="full-width">
                      <mat-label>Description</mat-label>
                      <textarea matInput formControlName="description" rows="3" 
                               placeholder="Describe your shop..."></textarea>
                    </mat-form-field>
                  </div>
                </div>

                <div class="form-section">
                  <h3 class="section-title">Address Information</h3>
                  <div class="form-grid">
                    <mat-form-field appearance="outline" class="full-width">
                      <mat-label>Address</mat-label>
                      <textarea matInput formControlName="address" rows="2" 
                               placeholder="Enter complete address"></textarea>
                    </mat-form-field>

                    <mat-form-field appearance="outline">
                      <mat-label>City</mat-label>
                      <input matInput formControlName="city" placeholder="Enter city">
                    </mat-form-field>

                    <mat-form-field appearance="outline">
                      <mat-label>State</mat-label>
                      <input matInput formControlName="state" placeholder="Enter state">
                    </mat-form-field>

                    <mat-form-field appearance="outline">
                      <mat-label>Pincode</mat-label>
                      <input matInput formControlName="pincode" placeholder="Enter pincode">
                    </mat-form-field>
                  </div>
                </div>

                <div class="form-actions">
                  <button mat-raised-button color="primary" (click)="saveShopInfo()" [disabled]="shopInfoForm.invalid">
                    <mat-icon>save</mat-icon>
                    Save Shop Information
                  </button>
                </div>
              </form>
            </div>
          </mat-tab>

          <!-- Business Hours Tab -->
          <mat-tab label="Business Hours">
            <div class="tab-content">
              <form [formGroup]="businessHoursForm" class="settings-form">
                <div class="form-section">
                  <h3 class="section-title">Operating Hours</h3>
                  <div class="business-hours-grid">
                    <div *ngFor="let day of weekDays" class="day-schedule">
                      <div class="day-header">
                        <h4>{{ day | titlecase }}</h4>
                        <mat-slide-toggle 
                          [formControlName]="day + '_closed'"
                          (change)="onDayToggle(day, $event)">
                          {{ getToggleText(day) }}
                        </mat-slide-toggle>
                      </div>
                      
                      <div class="time-inputs" [class.disabled]="isDayClosed(day)">
                        <mat-form-field appearance="outline">
                          <mat-label>Open Time</mat-label>
                          <input matInput type="time" [formControlName]="day + '_open'" 
                                [disabled]="isDayClosed(day)">
                        </mat-form-field>
                        
                        <mat-form-field appearance="outline">
                          <mat-label>Close Time</mat-label>
                          <input matInput type="time" [formControlName]="day + '_close'" 
                                [disabled]="isDayClosed(day)">
                        </mat-form-field>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="form-actions">
                  <button mat-raised-button color="primary" (click)="saveBusinessHours()">
                    <mat-icon>schedule</mat-icon>
                    Save Business Hours
                  </button>
                </div>
              </form>
            </div>
          </mat-tab>

          <!-- Notifications Tab -->
          <mat-tab label="Notifications">
            <div class="tab-content">
              <form [formGroup]="notificationsForm" class="settings-form">
                <div class="form-section">
                  <h3 class="section-title">Notification Preferences</h3>
                  <div class="notification-options">
                    <div class="notification-item">
                      <div class="notification-info">
                        <h4>Email Notifications</h4>
                        <p>Receive notifications via email</p>
                      </div>
                      <mat-slide-toggle formControlName="emailNotifications"></mat-slide-toggle>
                    </div>

                    <div class="notification-item">
                      <div class="notification-info">
                        <h4>SMS Notifications</h4>
                        <p>Receive notifications via SMS</p>
                      </div>
                      <mat-slide-toggle formControlName="smsNotifications"></mat-slide-toggle>
                    </div>

                    <div class="notification-item">
                      <div class="notification-info">
                        <h4>Order Alerts</h4>
                        <p>Get notified about new orders</p>
                      </div>
                      <mat-slide-toggle formControlName="orderAlerts"></mat-slide-toggle>
                    </div>

                    <div class="notification-item">
                      <div class="notification-info">
                        <h4>Low Stock Alerts</h4>
                        <p>Get alerted when inventory is running low</p>
                      </div>
                      <mat-slide-toggle formControlName="lowStockAlerts"></mat-slide-toggle>
                    </div>

                    <div class="notification-item">
                      <div class="notification-info">
                        <h4>Customer Messages</h4>
                        <p>Receive notifications for customer inquiries</p>
                      </div>
                      <mat-slide-toggle formControlName="customerMessages"></mat-slide-toggle>
                    </div>
                  </div>
                </div>

                <div class="form-actions">
                  <button mat-raised-button color="primary" (click)="saveNotificationSettings()">
                    <mat-icon>notifications</mat-icon>
                    Save Notification Settings
                  </button>
                </div>
              </form>
            </div>
          </mat-tab>

          <!-- Business Settings Tab -->
          <mat-tab label="Business Settings">
            <div class="tab-content">
              <form [formGroup]="businessForm" class="settings-form">
                <div class="form-section">
                  <h3 class="section-title">Business Information</h3>
                  <div class="form-grid">
                    <mat-form-field appearance="outline">
                      <mat-label>GST Number</mat-label>
                      <input matInput formControlName="gstNumber" placeholder="Enter GST number">
                    </mat-form-field>

                    <mat-form-field appearance="outline">
                      <mat-label>PAN Number</mat-label>
                      <input matInput formControlName="panNumber" placeholder="Enter PAN number">
                    </mat-form-field>
                  </div>
                </div>

                <div class="form-section">
                  <h3 class="section-title">Order Settings</h3>
                  <div class="form-grid">
                    <mat-form-field appearance="outline">
                      <mat-label>Minimum Order Amount (₹)</mat-label>
                      <input matInput type="number" formControlName="minimumOrderAmount" 
                            placeholder="0" min="0">
                    </mat-form-field>

                    <mat-form-field appearance="outline">
                      <mat-label>Delivery Radius (km)</mat-label>
                      <input matInput type="number" formControlName="deliveryRadius" 
                            placeholder="10" min="1" max="50">
                    </mat-form-field>

                    <mat-form-field appearance="outline">
                      <mat-label>Delivery Fee (₹)</mat-label>
                      <input matInput type="number" formControlName="deliveryFee" 
                            placeholder="30" min="0">
                    </mat-form-field>

                    <mat-form-field appearance="outline">
                      <mat-label>Free Delivery Above (₹)</mat-label>
                      <input matInput type="number" formControlName="freeDeliveryAbove" 
                            placeholder="500" min="0">
                    </mat-form-field>
                  </div>
                </div>

                <div class="form-actions">
                  <button mat-raised-button color="primary" (click)="saveBusinessSettings()">
                    <mat-icon>business</mat-icon>
                    Save Business Settings
                  </button>
                </div>
              </form>
            </div>
          </mat-tab>

          <!-- Integrations Tab -->
          <mat-tab label="Integrations">
            <div class="tab-content">
              <form [formGroup]="integrationsForm" class="settings-form">
                <div class="form-section">
                  <h3 class="section-title">Payment & Services</h3>
                  <div class="integration-options">
                    <div class="integration-item">
                      <div class="integration-info">
                        <h4>Payment Gateway</h4>
                        <p>Choose your preferred payment provider</p>
                      </div>
                      <mat-form-field appearance="outline">
                        <mat-label>Payment Gateway</mat-label>
                        <mat-select formControlName="paymentGateway">
                          <mat-option value="razorpay">Razorpay</mat-option>
                          <mat-option value="paytm">Paytm</mat-option>
                          <mat-option value="phonepe">PhonePe</mat-option>
                          <mat-option value="upi">UPI</mat-option>
                        </mat-select>
                      </mat-form-field>
                    </div>

                    <div class="integration-item">
                      <div class="integration-info">
                        <h4>Inventory Sync</h4>
                        <p>Automatically sync inventory across platforms</p>
                      </div>
                      <mat-slide-toggle formControlName="inventorySync"></mat-slide-toggle>
                    </div>

                    <div class="integration-item">
                      <div class="integration-info">
                        <h4>Auto Stock Update</h4>
                        <p>Automatically update stock levels after orders</p>
                      </div>
                      <mat-slide-toggle formControlName="autoStockUpdate"></mat-slide-toggle>
                    </div>

                    <div class="integration-item">
                      <div class="integration-info">
                        <h4>Email Service</h4>
                        <p>Enable automated email notifications</p>
                      </div>
                      <mat-slide-toggle formControlName="emailService"></mat-slide-toggle>
                    </div>

                    <div class="integration-item">
                      <div class="integration-info">
                        <h4>SMS Service</h4>
                        <p>Enable SMS notifications for customers</p>
                      </div>
                      <mat-slide-toggle formControlName="smsService"></mat-slide-toggle>
                    </div>
                  </div>
                </div>

                <div class="form-actions">
                  <button mat-raised-button color="primary" (click)="saveIntegrationSettings()">
                    <mat-icon>settings_applications</mat-icon>
                    Save Integration Settings
                  </button>
                </div>
              </form>
            </div>
          </mat-tab>
        </mat-tab-group>
      </mat-card>

      <!-- Quick Actions Card -->
      <mat-card class="quick-actions-card">
        <mat-card-header>
          <mat-card-title>Quick Actions</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="quick-actions-grid">
            <button mat-stroked-button class="action-btn" (click)="testEmailSettings()">
              <mat-icon>email</mat-icon>
              Test Email
            </button>
            <button mat-stroked-button class="action-btn" (click)="testSmsSettings()">
              <mat-icon>sms</mat-icon>
              Test SMS
            </button>
            <button mat-stroked-button class="action-btn" (click)="viewShopProfile()">
              <mat-icon>store</mat-icon>
              View Shop Profile
            </button>
            <button mat-stroked-button class="action-btn" (click)="backupSettings()">
              <mat-icon>backup</mat-icon>
              Backup Settings
            </button>
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .shop-settings-container {
      padding: 24px;
      background-color: #f5f5f5;
      min-height: calc(100vh - 64px);
    }

    .page-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }

    .page-title {
      font-size: 2rem;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: #1f2937;
    }

    .page-subtitle {
      color: #6b7280;
      margin: 0;
    }

    .header-actions {
      display: flex;
      gap: 12px;
    }

    .loading-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 200px;
    }

    .settings-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      margin-bottom: 24px;
    }

    .tab-content {
      padding: 24px;
    }

    .settings-form {
      max-width: 800px;
    }

    .form-section {
      margin-bottom: 32px;
    }

    .section-title {
      font-size: 1.2rem;
      font-weight: 600;
      margin: 0 0 16px 0;
      color: #1f2937;
      border-bottom: 2px solid #e5e7eb;
      padding-bottom: 8px;
    }

    .form-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 16px;
    }

    .full-width {
      grid-column: 1 / -1;
    }

    .business-hours-grid {
      display: grid;
      gap: 16px;
    }

    .day-schedule {
      padding: 16px;
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      background: #fafafa;
    }

    .day-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 12px;
    }

    .day-header h4 {
      margin: 0;
      font-weight: 500;
      color: #1f2937;
    }

    .time-inputs {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }

    .time-inputs.disabled {
      opacity: 0.5;
      pointer-events: none;
    }

    .notification-options, .integration-options {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .notification-item, .integration-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px;
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      background: #fafafa;
    }

    .notification-info h4, .integration-info h4 {
      margin: 0 0 4px 0;
      font-weight: 500;
      color: #1f2937;
    }

    .notification-info p, .integration-info p {
      margin: 0;
      font-size: 0.9rem;
      color: #6b7280;
    }

    .form-actions {
      display: flex;
      justify-content: flex-end;
      gap: 12px;
      margin-top: 24px;
      padding-top: 16px;
      border-top: 1px solid #e5e7eb;
    }

    .quick-actions-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .quick-actions-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 12px;
    }

    .action-btn {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      padding: 16px;
      height: auto;
    }

    .action-btn mat-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
    }

    /* Mobile Responsive */
    @media (max-width: 768px) {
      .shop-settings-container {
        padding: 16px;
      }

      .page-header {
        flex-direction: column;
        gap: 16px;
        text-align: center;
      }

      .form-grid {
        grid-template-columns: 1fr;
      }

      .time-inputs {
        grid-template-columns: 1fr;
      }

      .notification-item, .integration-item {
        flex-direction: column;
        align-items: flex-start;
        gap: 12px;
      }

      .quick-actions-grid {
        grid-template-columns: 1fr 1fr;
      }
    }
  `]
})
export class ShopSettingsComponent implements OnInit {
  loading = false;
  settingsLoaded = false;

  shopInfoForm!: FormGroup;
  businessHoursForm!: FormGroup;
  notificationsForm!: FormGroup;
  businessForm!: FormGroup;
  integrationsForm!: FormGroup;

  weekDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  constructor(
    private fb: FormBuilder,
    private snackBar: MatSnackBar,
    private dialog: MatDialog,
    private shopService: ShopService,
    private authService: AuthService,
    private settingsService: SettingsService
  ) {
    this.initializeForms();
  }

  ngOnInit(): void {
    this.loadShopSettings();
  }

  private initializeForms(): void {
    this.shopInfoForm = this.fb.group({
      shopName: ['', Validators.required],
      description: [''],
      contactNumber: ['', Validators.required],
      email: ['', [Validators.email]],
      address: [''],
      city: [''],
      state: [''],
      pincode: ['']
    });

    this.businessHoursForm = this.fb.group({});
    this.weekDays.forEach(day => {
      this.businessHoursForm.addControl(`${day}_open`, this.fb.control('09:00'));
      this.businessHoursForm.addControl(`${day}_close`, this.fb.control('18:00'));
      this.businessHoursForm.addControl(`${day}_closed`, this.fb.control(false));
    });

    this.notificationsForm = this.fb.group({
      emailNotifications: [true],
      smsNotifications: [false],
      orderAlerts: [true],
      lowStockAlerts: [true],
      customerMessages: [true]
    });

    this.businessForm = this.fb.group({
      gstNumber: [''],
      panNumber: [''],
      minimumOrderAmount: [0, [Validators.min(0)]],
      deliveryRadius: [10, [Validators.min(1), Validators.max(50)]],
      deliveryFee: [30, [Validators.min(0)]],
      freeDeliveryAbove: [500, [Validators.min(0)]]
    });

    this.integrationsForm = this.fb.group({
      paymentGateway: ['razorpay'],
      inventorySync: [false],
      autoStockUpdate: [true],
      emailService: [true],
      smsService: [false]
    });
  }

  loadShopSettings(): void {
    this.loading = true;
    const currentUser = this.authService.getCurrentUser();
    
    if (!currentUser || !currentUser.shopId) {
      this.snackBar.open('Shop information not found', 'Close', { duration: 3000 });
      this.loading = false;
      this.settingsLoaded = true;
      return;
    }

    this.shopService.getShopById(currentUser.shopId)
      .pipe(finalize(() => {
        this.loading = false;
        this.settingsLoaded = true;
      }))
      .subscribe({
        next: (shop) => {
          this.shopInfoForm.patchValue({
            shopName: shop.name || '',
            description: shop.description || '',
            contactNumber: shop.contactNumber || shop.phone || '',
            email: shop.email || '',
            address: shop.address || '',
            city: shop.city || '',
            state: shop.state || '',
            pincode: shop.pincode || shop.postalCode || ''
          });
        },
        error: (error) => {
          console.error('Error loading shop settings:', error);
          this.snackBar.open('Failed to load shop settings. Using defaults.', 'Close', { duration: 3000 });
        }
      });
  }

  saveShopInfo(): void {
    if (this.shopInfoForm.valid) {
      this.loading = true;
      const formData = this.shopInfoForm.value;
      
      // Simulate API call
      setTimeout(() => {
        this.loading = false;
        this.snackBar.open('Shop information saved successfully', 'Close', { duration: 3000 });
      }, 1000);
    }
  }

  saveBusinessHours(): void {
    this.loading = true;
    const formData = this.businessHoursForm.value;
    
    // Simulate API call
    setTimeout(() => {
      this.loading = false;
      this.snackBar.open('Business hours saved successfully', 'Close', { duration: 3000 });
    }, 1000);
  }

  saveNotificationSettings(): void {
    this.loading = true;
    const formData = this.notificationsForm.value;
    
    // Simulate API call
    setTimeout(() => {
      this.loading = false;
      this.snackBar.open('Notification settings saved successfully', 'Close', { duration: 3000 });
    }, 1000);
  }

  saveBusinessSettings(): void {
    if (this.businessForm.valid) {
      this.loading = true;
      const formData = this.businessForm.value;
      
      // Simulate API call
      setTimeout(() => {
        this.loading = false;
        this.snackBar.open('Business settings saved successfully', 'Close', { duration: 3000 });
      }, 1000);
    }
  }

  saveIntegrationSettings(): void {
    this.loading = true;
    const formData = this.integrationsForm.value;
    
    // Simulate API call
    setTimeout(() => {
      this.loading = false;
      this.snackBar.open('Integration settings saved successfully', 'Close', { duration: 3000 });
    }, 1000);
  }

  saveAllSettings(): void {
    if (this.shopInfoForm.valid && this.businessForm.valid) {
      this.loading = true;
      
      // Simulate API call to save all settings
      setTimeout(() => {
        this.loading = false;
        this.snackBar.open('All settings saved successfully', 'Close', { duration: 3000 });
      }, 1500);
    } else {
      this.snackBar.open('Please check all forms for errors', 'Close', { duration: 3000 });
    }
  }

  onDayToggle(day: string, event: any): void {
    const isClosed = event.checked;
    if (isClosed) {
      this.businessHoursForm.get(`${day}_open`)?.disable();
      this.businessHoursForm.get(`${day}_close`)?.disable();
    } else {
      this.businessHoursForm.get(`${day}_open`)?.enable();
      this.businessHoursForm.get(`${day}_close`)?.enable();
    }
  }

  isDayClosed(day: string): boolean {
    return this.businessHoursForm.get(`${day}_closed`)?.value === true;
  }

  getToggleText(day: string): string {
    return this.isDayClosed(day) ? 'Closed' : 'Open';
  }

  testEmailSettings(): void {
    this.snackBar.open('Sending test email...', 'Close', { duration: 2000 });
    setTimeout(() => {
      this.snackBar.open('Test email sent successfully!', 'Close', { duration: 3000 });
    }, 2000);
  }

  testSmsSettings(): void {
    this.snackBar.open('Sending test SMS...', 'Close', { duration: 2000 });
    setTimeout(() => {
      this.snackBar.open('Test SMS sent successfully!', 'Close', { duration: 3000 });
    }, 2000);
  }

  viewShopProfile(): void {
    this.snackBar.open('Opening shop profile...', 'Close', { duration: 2000 });
  }

  backupSettings(): void {
    const settings = {
      shopInfo: this.shopInfoForm.value,
      businessHours: this.businessHoursForm.value,
      notifications: this.notificationsForm.value,
      business: this.businessForm.value,
      integrations: this.integrationsForm.value,
      exportedAt: new Date().toISOString()
    };
    
    const blob = new Blob([JSON.stringify(settings, null, 2)], { type: 'application/json' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `shop-settings-backup-${new Date().toISOString().split('T')[0]}.json`;
    link.click();
    window.URL.revokeObjectURL(url);
    
    this.snackBar.open('Settings backup downloaded successfully', 'Close', { duration: 3000 });
  }

  exportSettings(): void {
    this.backupSettings();
  }
}