import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Router } from '@angular/router';
import { ShopService } from '@core/services/shop.service';
import { Shop } from '@core/models/shop.model';

@Component({
  selector: 'app-shop-profile',
  template: `
    <div class="clean-shop-profile">
      <!-- Clean Header -->
      <div class="profile-header">
        <div class="header-content">
          <div class="shop-info">
            <h1>{{ shop?.name || 'My Shop' }}</h1>
            <p>{{ shop?.description || 'Manage your shop profile and settings' }}</p>
            <span class="status-badge" [ngClass]="'status-' + shopStatus.toLowerCase()">
              {{ shopStatus }}
            </span>
          </div>
          <div class="header-stats">
            <div class="stat-item" *ngFor="let stat of statisticsData">
              <span class="stat-number">{{ stat.value }}</span>
              <span class="stat-text">{{ stat.label }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Navigation Tabs -->
      <div class="tab-navigation">
        <button 
          class="tab-button" 
          [class.active]="selectedIndex === 0"
          (click)="selectedIndex = 0">
          <mat-icon>person</mat-icon>
          <span>Profile</span>
        </button>
        <button 
          class="tab-button" 
          [class.active]="selectedIndex === 1"
          (click)="selectedIndex = 1">
          <mat-icon>schedule</mat-icon>
          <span>Hours & Holidays</span>
        </button>
        <button 
          class="tab-button" 
          [class.active]="selectedIndex === 2"
          (click)="selectedIndex = 2">
          <mat-icon>settings</mat-icon>
          <span>Settings</span>
        </button>
        <button 
          class="tab-button" 
          [class.active]="selectedIndex === 3"
          (click)="selectedIndex = 3">
          <mat-icon>dashboard</mat-icon>
          <span>Quick Actions</span>
        </button>
      </div>

      <!-- Tab Content -->
      <div class="tab-content-area">
        
        <!-- Profile Tab -->
        <div class="tab-pane" [class.active]="selectedIndex === 0">
          <div class="content-header">
            <h2>Shop Information</h2>
            <button mat-raised-button color="primary" (click)="toggleEditMode()" [disabled]="isLoading">
              <mat-icon>{{ isEditMode ? 'close' : 'edit' }}</mat-icon>
              {{ isEditMode ? 'Cancel' : 'Edit' }}
            </button>
          </div>
          
          <div class="form-container">
            <form [formGroup]="shopForm" (ngSubmit)="onSave()">
              <div class="form-fields">
                <div class="field-row" *ngFor="let field of profileFieldsData">
                  <div class="field-group" [ngSwitch]="field.type">
                    <mat-form-field *ngSwitchCase="'text'" appearance="outline">
                      <mat-label>{{ field.label }}</mat-label>
                      <input matInput [formControlName]="field.control" [readonly]="!isEditMode">
                      <mat-icon matPrefix>{{ getFieldIcon(field.control) }}</mat-icon>
                      <mat-error *ngFor="let error of getFieldErrors(field.control)">{{ error }}</mat-error>
                    </mat-form-field>
                    
                    <mat-form-field *ngSwitchCase="'textarea'" appearance="outline">
                      <mat-label>{{ field.label }}</mat-label>
                      <textarea matInput [formControlName]="field.control" [readonly]="!isEditMode" rows="3"></textarea>
                      <mat-icon matPrefix>{{ getFieldIcon(field.control) }}</mat-icon>
                      <mat-error *ngFor="let error of getFieldErrors(field.control)">{{ error }}</mat-error>
                    </mat-form-field>
                    
                    <mat-form-field *ngSwitchCase="'email'" appearance="outline">
                      <mat-label>{{ field.label }}</mat-label>
                      <input matInput type="email" [formControlName]="field.control" readonly>
                      <mat-icon matPrefix>{{ getFieldIcon(field.control) }}</mat-icon>
                      <mat-icon matSuffix>lock</mat-icon>
                      <mat-hint>Email cannot be changed</mat-hint>
                    </mat-form-field>
                  </div>
                </div>
              </div>
              
              <div class="form-actions" *ngIf="isEditMode">
                <button mat-raised-button color="primary" type="submit" [disabled]="shopForm.invalid || isLoading">
                  <mat-spinner *ngIf="isLoading" diameter="16"></mat-spinner>
                  <mat-icon *ngIf="!isLoading">save</mat-icon>
                  {{ isLoading ? 'Saving...' : 'Save Changes' }}
                </button>
                <button mat-button type="button" (click)="onReset()">Reset</button>
              </div>
            </form>
          </div>
        </div>

        <!-- Hours & Holidays Tab -->
        <div class="tab-pane" [class.active]="selectedIndex === 1">
          <div class="content-header">
            <h2>Business Hours & Holidays</h2>
          </div>
          
          <div class="hours-container">
            <div class="hours-section">
              <h3>Regular Hours</h3>
              <app-business-hours></app-business-hours>
            </div>
            
            <div class="holidays-section">
              <h3>Holiday Settings</h3>
              <div class="holiday-controls">
                <mat-form-field appearance="outline">
                  <mat-label>Holiday Name</mat-label>
                  <input matInput [(ngModel)]="newHoliday.name" placeholder="e.g., Christmas Day">
                </mat-form-field>
                <mat-form-field appearance="outline">
                  <mat-label>Holiday Date</mat-label>
                  <input matInput type="date" [(ngModel)]="newHoliday.date">
                </mat-form-field>
                <mat-checkbox [(ngModel)]="newHoliday.recurring">Recurring Annually</mat-checkbox>
                <button mat-raised-button color="primary" (click)="addHoliday()">
                  <mat-icon>add</mat-icon>
                  Add Holiday
                </button>
              </div>
              
              <div class="holiday-list" *ngIf="holidays.length > 0">
                <div class="holiday-item" *ngFor="let holiday of holidays">
                  <div class="holiday-info">
                    <span class="holiday-name">{{ holiday.name }}</span>
                    <span class="holiday-date">{{ holiday.date | date:'mediumDate' }}</span>
                    <span class="holiday-recurring" *ngIf="holiday.recurring">Recurring</span>
                  </div>
                  <button mat-icon-button color="warn" (click)="removeHoliday(holiday)">
                    <mat-icon>delete</mat-icon>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Settings Tab -->
        <div class="tab-pane" [class.active]="selectedIndex === 2">
          <div class="content-header">
            <h2>Shop Settings</h2>
          </div>
          
          <div class="settings-container">
            <div class="setting-item" *ngFor="let setting of settingsData">
              <div class="setting-left">
                <mat-icon>{{ setting.icon }}</mat-icon>
                <div class="setting-text">
                  <h4>{{ setting.label }}</h4>
                  <p>{{ getSettingDescription(setting.key) }}</p>
                </div>
              </div>
              <mat-slide-toggle 
                [checked]="setting.value" 
                (change)="onSettingChange(setting.key, $event.checked)">
              </mat-slide-toggle>
            </div>
          </div>
        </div>

        <!-- Quick Actions Tab -->
        <div class="tab-pane" [class.active]="selectedIndex === 3">
          <div class="content-header">
            <h2>Quick Actions</h2>
          </div>
          
          <div class="actions-grid">
            <button mat-raised-button class="action-button dashboard-action" (click)="navigateTo('/shop-owner/dashboard')">
              <mat-icon>dashboard</mat-icon>
              <div class="action-text">
                <span>Dashboard</span>
                <small>View analytics & overview</small>
              </div>
            </button>
            
            <button mat-raised-button class="action-button products-action" (click)="navigateTo('/shop-owner/my-products')">
              <mat-icon>inventory</mat-icon>
              <div class="action-text">
                <span>My Products</span>
                <small>Manage inventory</small>
              </div>
            </button>
            
            <button mat-raised-button class="action-button orders-action" (click)="navigateTo('/shop-owner/orders')">
              <mat-icon>receipt_long</mat-icon>
              <div class="action-text">
                <span>Orders</span>
                <small>Track customer orders</small>
              </div>
            </button>
            
            <button mat-raised-button class="action-button customers-action" (click)="navigateTo('/shop-owner/customers')">
              <mat-icon>people</mat-icon>
              <div class="action-text">
                <span>Customers</span>
                <small>Customer management</small>
              </div>
            </button>
            
            <button mat-raised-button class="action-button analytics-action" (click)="navigateTo('/shop-owner/analytics')">
              <mat-icon>analytics</mat-icon>
              <div class="action-text">
                <span>Analytics</span>
                <small>Business insights</small>
              </div>
            </button>
            
            <button mat-raised-button class="action-button settings-action" (click)="navigateTo('/shop-owner/settings')">
              <mat-icon>settings</mat-icon>
              <div class="action-text">
                <span>Settings</span>
                <small>Shop configuration</small>
              </div>
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .clean-shop-profile {
      background: #f8fafc;
      min-height: 100vh;
      padding: 0;
      margin: -24px;
    }

    /* Clean Header */
    .profile-header {
      background: linear-gradient(135deg, #1e40af 0%, #3b82f6 100%);
      color: white;
      padding: 24px;
    }

    .header-content {
      max-width: 1200px;
      margin: 0 auto;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .shop-info h1 {
      font-size: 1.8rem;
      font-weight: 600;
      margin: 0 0 8px 0;
    }

    .shop-info p {
      margin: 0 0 12px 0;
      opacity: 0.9;
      font-size: 0.95rem;
    }

    .status-badge {
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 0.8rem;
      font-weight: 500;
      background: rgba(255, 255, 255, 0.2);
    }

    .status-badge.status-active {
      background: rgba(34, 197, 94, 0.9);
    }

    .status-badge.status-pending {
      background: rgba(251, 146, 60, 0.9);
    }

    .status-badge.status-suspended {
      background: rgba(239, 68, 68, 0.9);
    }

    .header-stats {
      display: flex;
      gap: 32px;
    }

    .stat-item {
      text-align: center;
    }

    .stat-number {
      display: block;
      font-size: 1.5rem;
      font-weight: 700;
      margin-bottom: 4px;
    }

    .stat-text {
      font-size: 0.8rem;
      opacity: 0.9;
    }

    /* Tab Navigation */
    .tab-navigation {
      background: white;
      border-bottom: 1px solid #e5e7eb;
      padding: 0 24px;
      display: flex;
    }

    .tab-button {
      background: none;
      border: none;
      padding: 16px 24px;
      display: flex;
      align-items: center;
      gap: 8px;
      cursor: pointer;
      color: #6b7280;
      font-weight: 500;
      border-bottom: 2px solid transparent;
      transition: all 0.2s ease;
    }

    .tab-button:hover {
      color: #3b82f6;
      background: #f3f4f6;
    }

    .tab-button.active {
      color: #3b82f6;
      border-bottom-color: #3b82f6;
      background: #eff6ff;
    }

    /* Tab Content */
    .tab-content-area {
      max-width: 1200px;
      margin: 0 auto;
      padding: 24px;
    }

    .tab-pane {
      display: none;
    }

    .tab-pane.active {
      display: block;
    }

    .content-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }

    .content-header h2 {
      font-size: 1.5rem;
      font-weight: 600;
      color: #111827;
      margin: 0;
    }

    /* Form Container */
    .form-container {
      background: white;
      border-radius: 8px;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      padding: 24px;
    }

    .form-fields {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
      gap: 20px;
    }

    .field-row {
      margin-bottom: 16px;
    }

    .field-group mat-form-field {
      width: 100%;
    }

    .form-actions {
      margin-top: 24px;
      padding-top: 24px;
      border-top: 1px solid #e5e7eb;
      display: flex;
      gap: 12px;
    }

    /* Hours Container */
    .hours-container {
      background: white;
      border-radius: 8px;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      padding: 24px;
    }

    .hours-section, .holidays-section {
      margin-bottom: 32px;
    }

    .hours-section:last-child, .holidays-section:last-child {
      margin-bottom: 0;
    }

    .hours-section h3, .holidays-section h3 {
      font-size: 1.2rem;
      font-weight: 600;
      color: #111827;
      margin: 0 0 16px 0;
    }

    .holiday-controls {
      display: grid;
      grid-template-columns: 1fr 1fr auto auto;
      gap: 16px;
      align-items: end;
      margin-bottom: 24px;
    }

    .holiday-list {
      border: 1px solid #e5e7eb;
      border-radius: 6px;
      overflow: hidden;
    }

    .holiday-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 16px;
      border-bottom: 1px solid #e5e7eb;
    }

    .holiday-item:last-child {
      border-bottom: none;
    }

    .holiday-info {
      display: flex;
      gap: 16px;
      align-items: center;
    }

    .holiday-name {
      font-weight: 500;
      color: #111827;
    }

    .holiday-date {
      color: #6b7280;
      font-size: 0.9rem;
    }

    .holiday-recurring {
      background: #dbeafe;
      color: #1e40af;
      padding: 2px 8px;
      border-radius: 4px;
      font-size: 0.8rem;
    }

    /* Settings Container */
    .settings-container {
      background: white;
      border-radius: 8px;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      padding: 24px;
    }

    .setting-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px 0;
      border-bottom: 1px solid #e5e7eb;
    }

    .setting-item:last-child {
      border-bottom: none;
    }

    .setting-left {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .setting-left mat-icon {
      color: #3b82f6;
      width: 20px;
      height: 20px;
      font-size: 20px;
    }

    .setting-text h4 {
      margin: 0 0 4px 0;
      font-size: 1rem;
      font-weight: 500;
      color: #111827;
    }

    .setting-text p {
      margin: 0;
      font-size: 0.875rem;
      color: #6b7280;
    }

    /* Actions Grid */
    .actions-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 16px;
    }

    .action-button {
      display: flex !important;
      align-items: center;
      gap: 12px;
      padding: 16px !important;
      text-align: left;
      height: auto !important;
      border-radius: 8px !important;
      transition: all 0.2s ease;
      border: 1px solid #e5e7eb;
      background: white !important;
      color: #111827 !important;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    }

    .action-button:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    }

    .action-button mat-icon {
      width: 24px;
      height: 24px;
      font-size: 24px;
    }

    .dashboard-action mat-icon { color: #3b82f6; }
    .products-action mat-icon { color: #10b981; }
    .orders-action mat-icon { color: #f59e0b; }
    .customers-action mat-icon { color: #8b5cf6; }
    .analytics-action mat-icon { color: #ef4444; }
    .settings-action mat-icon { color: #6b7280; }

    .action-text {
      display: flex;
      flex-direction: column;
    }

    .action-text span {
      font-size: 1rem;
      font-weight: 500;
      color: #111827;
    }

    .action-text small {
      font-size: 0.8rem;
      color: #6b7280;
      margin-top: 2px;
    }

    /* Mobile Responsive */
    @media (max-width: 768px) {
      .clean-shop-profile {
        margin: -16px;
      }

      .profile-header {
        padding: 16px;
      }

      .header-content {
        flex-direction: column;
        gap: 16px;
        text-align: center;
      }

      .header-stats {
        gap: 16px;
      }

      .tab-navigation {
        padding: 0 16px;
        overflow-x: auto;
        white-space: nowrap;
      }

      .tab-button {
        padding: 12px 16px;
        font-size: 0.9rem;
      }

      .tab-content-area {
        padding: 16px;
      }

      .form-fields {
        grid-template-columns: 1fr;
        gap: 16px;
      }

      .holiday-controls {
        grid-template-columns: 1fr;
        gap: 12px;
      }

      .actions-grid {
        grid-template-columns: 1fr;
      }

      .content-header {
        flex-direction: column;
        gap: 12px;
        align-items: stretch;
      }

      .form-actions {
        flex-direction: column;
      }
    }
  `]
})
export class ShopProfileComponent implements OnInit {
  shopForm: FormGroup;
  isLoading = false;
  isEditMode = false;
  shop: Shop | null = null;
  
  // Shop statistics
  shopStatus = 'Active';
  registrationDate = new Date();
  totalProducts = 0;
  totalOrders = 0;
  
  // Table data sources
  profileFieldsData: any[] = [];
  statisticsData: any[] = [];
  settingsData: any[] = [];
  
  // Tab management
  selectedIndex = 0;
  
  // Holiday management
  holidays: any[] = [];
  newHoliday = {
    name: '',
    date: '',
    recurring: false
  };

  constructor(
    private fb: FormBuilder,
    private shopService: ShopService,
    private snackBar: MatSnackBar,
    private router: Router
  ) {
    this.shopForm = this.fb.group({
      name: ['', [Validators.required]],
      description: [''],
      phone: ['', [Validators.required]],
      email: [{value: '', disabled: true}],
      address: ['', [Validators.required]],
      city: ['', [Validators.required]],
      pincode: ['', [Validators.required]]
    });
  }

  ngOnInit(): void {
    this.loadShopProfile();
    this.setupProfileFieldsData();
    this.setupStatisticsData();
    this.setupSettingsData();
  }
  
  setupProfileFieldsData(): void {
    this.profileFieldsData = [
      {
        label: 'Shop Name',
        control: 'name',
        type: 'text',
        placeholder: 'Enter shop name'
      },
      {
        label: 'Description',
        control: 'description',
        type: 'textarea',
        placeholder: 'Describe your shop',
        rows: 3
      },
      {
        label: 'Phone Number',
        control: 'phone',
        type: 'text',
        placeholder: 'Enter phone number'
      },
      {
        label: 'Email',
        control: 'email',
        type: 'email',
        placeholder: 'Enter email'
      },
      {
        label: 'Address',
        control: 'address',
        type: 'textarea',
        placeholder: 'Enter shop address',
        rows: 2
      },
      {
        label: 'City',
        control: 'city',
        type: 'text',
        placeholder: 'Enter city'
      },
      {
        label: 'PIN Code',
        control: 'pincode',
        type: 'text',
        placeholder: 'Enter PIN code'
      }
    ];
  }
  
  setupStatisticsData(): void {
    this.statisticsData = [
      {
        label: 'Current Status',
        value: this.shopStatus,
        icon: 'info',
        class: 'status-' + this.shopStatus.toLowerCase()
      },
      {
        label: 'Registered On',
        value: this.registrationDate.toLocaleDateString(),
        icon: 'calendar_today',
        class: ''
      },
      {
        label: 'Total Products',
        value: this.totalProducts.toString(),
        icon: 'inventory',
        class: ''
      },
      {
        label: 'Total Orders',
        value: this.totalOrders.toString(),
        icon: 'shopping_cart',
        class: ''
      }
    ];
  }
  
  toggleEditMode(): void {
    this.isEditMode = !this.isEditMode;
    if (!this.isEditMode) {
      this.onReset();
    }
  }
  
  getFieldErrors(controlName: string): string[] {
    const control = this.shopForm.get(controlName);
    const errors: string[] = [];
    
    if (control && control.errors && control.touched) {
      if (control.errors['required']) {
        errors.push(`${this.getFieldLabel(controlName)} is required`);
      }
      if (control.errors['email']) {
        errors.push('Please enter a valid email');
      }
    }
    
    return errors;
  }
  
  private getFieldLabel(controlName: string): string {
    const field = this.profileFieldsData.find(f => f.control === controlName);
    return field ? field.label : controlName;
  }
  
  setupSettingsData(): void {
    this.settingsData = [
      {
        label: 'Online Ordering',
        key: 'onlineOrdering',
        value: true,
        type: 'toggle',
        icon: 'shopping_cart'
      },
      {
        label: 'Delivery Service',
        key: 'deliveryService',
        value: true,
        type: 'toggle',
        icon: 'delivery_dining'
      },
      {
        label: 'Pickup Service',
        key: 'pickupService',
        value: true,
        type: 'toggle',
        icon: 'store'
      },
      {
        label: 'Accept Cash',
        key: 'acceptCash',
        value: true,
        type: 'toggle',
        icon: 'payments'
      },
      {
        label: 'Accept Card',
        key: 'acceptCard',
        value: true,
        type: 'toggle',
        icon: 'credit_card'
      },
      {
        label: 'Auto Accept Orders',
        key: 'autoAcceptOrders',
        value: false,
        type: 'toggle',
        icon: 'auto_mode'
      },
      {
        label: 'SMS Notifications',
        key: 'smsNotifications',
        value: true,
        type: 'toggle',
        icon: 'sms'
      },
      {
        label: 'Email Notifications',
        key: 'emailNotifications',
        value: true,
        type: 'toggle',
        icon: 'email'
      }
    ];
  }
  
  onSettingChange(settingKey: string, value: boolean): void {
    const setting = this.settingsData.find(s => s.key === settingKey);
    if (setting) {
      setting.value = value;
      
      // Here you would typically save the setting to the backend
      console.log(`Setting ${settingKey} changed to:`, value);
      
      this.snackBar.open(`${setting.label} ${value ? 'enabled' : 'disabled'}`, 'Close', {
        duration: 2000,
        horizontalPosition: 'end',
        verticalPosition: 'top'
      });
    }
  }
  
  getStatusIcon(): string {
    switch (this.shopStatus.toLowerCase()) {
      case 'active': return 'check_circle';
      case 'pending': return 'schedule';
      case 'suspended': return 'block';
      default: return 'info';
    }
  }
  
  getFieldIcon(controlName: string): string {
    const iconMap: { [key: string]: string } = {
      name: 'store',
      description: 'description',
      phone: 'phone',
      email: 'email',
      address: 'location_on',
      city: 'location_city',
      pincode: 'markunread_mailbox'
    };
    return iconMap[controlName] || 'info';
  }
  
  getSettingDescription(key: string): string {
    const descriptions: { [key: string]: string } = {
      onlineOrdering: 'Allow customers to place orders online',
      deliveryService: 'Offer delivery to customer locations',
      pickupService: 'Allow customers to pick up orders',
      acceptCash: 'Accept cash payments for orders',
      acceptCard: 'Accept card and digital payments',
      autoAcceptOrders: 'Automatically accept new orders',
      smsNotifications: 'Receive SMS alerts for orders',
      emailNotifications: 'Receive email notifications'
    };
    return descriptions[key] || 'Configure this setting';
  }
  
  navigateTo(path: string): void {
    this.router.navigate([path]);
  }
  
  addHoliday(): void {
    if (this.newHoliday.name && this.newHoliday.date) {
      const holiday = {
        id: Date.now(),
        name: this.newHoliday.name,
        date: new Date(this.newHoliday.date),
        recurring: this.newHoliday.recurring
      };
      
      this.holidays.push(holiday);
      
      // Reset form
      this.newHoliday = {
        name: '',
        date: '',
        recurring: false
      };
      
      this.snackBar.open(`Holiday "${holiday.name}" added successfully`, 'Close', {
        duration: 3000,
        horizontalPosition: 'end',
        verticalPosition: 'top'
      });
      
      // Here you would typically save to backend
      console.log('Holiday added:', holiday);
    }
  }
  
  removeHoliday(holiday: any): void {
    const index = this.holidays.indexOf(holiday);
    if (index > -1) {
      this.holidays.splice(index, 1);
      
      this.snackBar.open(`Holiday "${holiday.name}" removed`, 'Close', {
        duration: 2000,
        horizontalPosition: 'end',
        verticalPosition: 'top'
      });
      
      // Here you would typically remove from backend
      console.log('Holiday removed:', holiday);
    }
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
            address: shop.addressLine1 || shop.address || '',
            city: shop.city || '',
            pincode: shop.postalCode || shop.pincode || ''
          });
          
          // Set email separately since it's disabled
          this.shopForm.get('email')?.setValue(shop.ownerEmail || shop.email || '');
          
          // Update statistics with real data
          this.shopStatus = shop.status || 'ACTIVE';
          this.registrationDate = new Date(shop.createdAt || new Date());
          this.totalProducts = shop.productCount || 0;
          this.totalOrders = shop.totalOrders || 0;
          
          // Get additional statistics
          this.loadShopStatistics();
          
          // Update statistics data for table
          this.setupStatisticsData();
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
      address: '',
      city: '',
      pincode: ''
    });
    
    // Set email separately since it's disabled
    this.shopForm.get('email')?.setValue('');
    
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
          this.setupStatisticsData();
        }
      });
      
      // Get product count
      this.shopService.getTotalProductCount().subscribe({
        next: (count) => {
          this.totalProducts = count;
          this.setupStatisticsData();
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
        // Email is disabled and should not be updated
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