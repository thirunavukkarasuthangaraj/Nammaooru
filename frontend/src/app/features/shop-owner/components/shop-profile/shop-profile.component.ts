import { Component, OnInit, AfterViewChecked, ViewChild, ElementRef } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Router } from '@angular/router';
import { ShopService } from '@core/services/shop.service';
import { Shop } from '@core/models/shop.model';
import { getImageUrl } from '@core/utils/image-url.util';
import { ShopContextService } from '../../services/shop-context.service';
import * as L from 'leaflet';

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
          <!-- Shop Logo Upload Section -->
          <div class="image-upload-section">
            <div class="content-header">
              <h2>Shop Logo</h2>
            </div>
            <div class="logo-upload-container">
              <div class="logo-preview" (click)="triggerFileInput()">
                <img *ngIf="shopLogoUrl" [src]="shopLogoUrl" alt="Shop Logo" class="logo-image">
                <div *ngIf="!shopLogoUrl" class="logo-placeholder">
                  <mat-icon>store</mat-icon>
                  <span>Click to upload logo</span>
                </div>
                <div class="upload-overlay">
                  <mat-icon>cloud_upload</mat-icon>
                  <span>Upload New Logo</span>
                </div>
              </div>
              <input
                type="file"
                #fileInput
                (change)="onFileSelected($event)"
                accept="image/*"
                style="display: none;">
              <div class="logo-info">
                <p class="logo-hint">Recommended: 200x200 pixels, PNG or JPG format</p>
                <div class="logo-actions" *ngIf="shopLogoUrl">
                  <button mat-stroked-button color="primary" (click)="triggerFileInput()">
                    <mat-icon>edit</mat-icon>
                    Change Logo
                  </button>
                  <button mat-stroked-button color="warn" (click)="removeLogo()">
                    <mat-icon>delete</mat-icon>
                    Remove
                  </button>
                </div>
                <div class="upload-progress" *ngIf="isUploadingImage">
                  <mat-progress-bar mode="indeterminate"></mat-progress-bar>
                  <span>Uploading...</span>
                </div>
              </div>
            </div>
          </div>

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
                    
                    <mat-form-field *ngSwitchCase="'number'" appearance="outline">
                      <mat-label>{{ field.label }}</mat-label>
                      <input matInput type="number" step="0.000001" [formControlName]="field.control" [readonly]="!isEditMode" [placeholder]="field.placeholder">
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
              
              <!-- Interactive Map -->
              <div class="map-section">
                <h3>Shop Location on Map</h3>
                <p class="map-hint" *ngIf="isEditMode">Click on the map to set your shop location. The latitude and longitude will update automatically.</p>
                <div id="shopMap" class="map-container" style="height: 350px;"></div>
                <p class="map-hint" *ngIf="!shopForm.value.latitude">No location set. Edit and click on the map to set your shop location.</p>
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
            
            <button mat-raised-button class="action-button orders-action" (click)="navigateTo('/shop-owner/orders-management')">
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

    /* Clean Header - Green Theme */
    .profile-header {
      background: linear-gradient(135deg, #16a34a 0%, #4ade80 100%);
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
      color: #16a34a;
      background: #f0fdf4;
    }

    .tab-button.active {
      color: #16a34a;
      border-bottom-color: #4ade80;
      background: #f0fdf4;
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
      background: #dcfce7;
      color: #166534;
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
      color: #16a34a;
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

    .dashboard-action mat-icon { color: #16a34a; }
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

    /* Image Upload Section */
    .image-upload-section {
      background: white;
      border-radius: 8px;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      padding: 24px;
      margin-bottom: 24px;
    }

    .logo-upload-container {
      display: flex;
      align-items: flex-start;
      gap: 24px;
    }

    .logo-preview {
      width: 150px;
      height: 150px;
      border-radius: 12px;
      border: 2px dashed #d1d5db;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      position: relative;
      overflow: hidden;
      background: #f9fafb;
      transition: all 0.3s ease;
    }

    .logo-preview:hover {
      border-color: #4ade80;
      background: #f0fdf4;
    }

    .logo-preview:hover .upload-overlay {
      opacity: 1;
    }

    .logo-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
      border-radius: 10px;
    }

    .logo-placeholder {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      color: #9ca3af;
    }

    .logo-placeholder mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
    }

    .logo-placeholder span {
      font-size: 0.85rem;
      text-align: center;
    }

    .upload-overlay {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(74, 222, 128, 0.9);
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 8px;
      color: white;
      opacity: 0;
      transition: opacity 0.3s ease;
      border-radius: 10px;
    }

    .upload-overlay mat-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
    }

    .upload-overlay span {
      font-size: 0.85rem;
      font-weight: 500;
    }

    .logo-info {
      flex: 1;
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .logo-hint {
      color: #6b7280;
      font-size: 0.9rem;
      margin: 0;
    }

    .logo-actions {
      display: flex;
      gap: 12px;
    }

    .upload-progress {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .upload-progress mat-progress-bar {
      flex: 1;
      max-width: 200px;
    }

    .upload-progress span {
      color: #16a34a;
      font-size: 0.9rem;
    }

    /* Map Section */
    .map-section {
      margin-top: 24px;
      padding-top: 24px;
      border-top: 1px solid #e5e7eb;
    }

    .map-section h3 {
      font-size: 1.1rem;
      font-weight: 600;
      color: #111827;
      margin: 0 0 12px 0;
    }

    .map-container {
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    }

    .map-hint {
      margin: 8px 0 0 0;
      font-size: 0.85rem;
      color: #6b7280;
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

      /* Image upload responsive */
      .logo-upload-container {
        flex-direction: column;
        align-items: center;
      }

      .logo-preview {
        width: 120px;
        height: 120px;
      }

      .logo-info {
        text-align: center;
        align-items: center;
      }

      .logo-actions {
        flex-direction: column;
        width: 100%;
      }

      .logo-actions button {
        width: 100%;
      }
    }
  `]
})
export class ShopProfileComponent implements OnInit, AfterViewChecked {
  @ViewChild('fileInput') fileInput!: ElementRef<HTMLInputElement>;

  shopForm: FormGroup;
  isLoading = false;
  isEditMode = false;
  shop: Shop | null = null;

  // Map
  private map: L.Map | null = null;
  private marker: L.Marker | null = null;
  private mapInitialized = false;

  // Image upload
  shopLogoUrl: string | null = null;
  shopLogoId: number | null = null;
  isUploadingImage = false;

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
    private router: Router,
    private shopContext: ShopContextService
  ) {
    this.shopForm = this.fb.group({
      name: ['', [Validators.required]],
      nameTamil: [''],
      description: [''],
      phone: ['', [Validators.required]],
      email: [{value: '', disabled: true}],
      address: ['', [Validators.required]],
      city: ['', [Validators.required]],
      pincode: ['', [Validators.required]],
      upiId: [''],
      latitude: [null],
      longitude: [null]
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
        label: 'Shop Name (Tamil)',
        control: 'nameTamil',
        type: 'text',
        placeholder: 'கடை பெயர் தமிழில்'
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
      },
      {
        label: 'UPI ID',
        control: 'upiId',
        type: 'text',
        placeholder: 'e.g., yourname@upi'
      },
      {
        label: 'Latitude',
        control: 'latitude',
        type: 'number',
        placeholder: 'e.g., 12.4962'
      },
      {
        label: 'Longitude',
        control: 'longitude',
        type: 'number',
        placeholder: 'e.g., 78.5722'
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
      nameTamil: 'translate',
      description: 'description',
      phone: 'phone',
      email: 'email',
      address: 'location_on',
      city: 'location_city',
      pincode: 'markunread_mailbox',
      upiId: 'qr_code',
      latitude: 'my_location',
      longitude: 'my_location'
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
  
  ngAfterViewChecked(): void {
    if (this.selectedIndex === 0 && !this.mapInitialized && !this.isLoading) {
      this.initMap();
    }
  }

  private initMap(): void {
    const mapEl = document.getElementById('shopMap');
    if (!mapEl || this.mapInitialized) return;

    this.mapInitialized = true;

    // Fix Leaflet default icon path issue
    const iconDefault = L.icon({
      iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
      iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
      shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
      iconSize: [25, 41],
      iconAnchor: [12, 41],
      popupAnchor: [1, -34],
      shadowSize: [41, 41]
    });

    const lat = this.shopForm.value.latitude || 12.4962;
    const lng = this.shopForm.value.longitude || 78.5722;

    this.map = L.map('shopMap').setView([lat, lng], 15);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap'
    }).addTo(this.map);

    // Add marker if coordinates exist
    if (this.shopForm.value.latitude && this.shopForm.value.longitude) {
      this.marker = L.marker([lat, lng], { icon: iconDefault }).addTo(this.map);
      this.marker.bindPopup('Shop Location').openPopup();
    }

    // Click to set location
    this.map.on('click', (e: L.LeafletMouseEvent) => {
      if (!this.isEditMode) return;

      const { lat, lng } = e.latlng;
      this.shopForm.patchValue({
        latitude: parseFloat(lat.toFixed(6)),
        longitude: parseFloat(lng.toFixed(6))
      });

      // Update marker
      if (this.marker) {
        this.marker.setLatLng(e.latlng);
      } else {
        this.marker = L.marker(e.latlng, { icon: iconDefault }).addTo(this.map!);
      }
      this.marker.bindPopup('Shop Location').openPopup();
    });
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
            nameTamil: shop.nameTamil || '',
            description: shop.description || '',
            phone: shop.ownerPhone || shop.phone || '',
            address: shop.addressLine1 || shop.address || '',
            city: shop.city || '',
            pincode: shop.postalCode || shop.pincode || '',
            upiId: shop.upiId || '',
            latitude: shop.latitude || null,
            longitude: shop.longitude || null
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

          // Load shop logo
          this.loadShopLogo();

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

      // Save UPI ID to localStorage immediately (for POS Billing receipt)
      const upiIdValue = this.shopForm.value.upiId;
      if (upiIdValue && upiIdValue.trim()) {
        localStorage.setItem('shop_upi_id', upiIdValue.trim());
        console.log('UPI ID saved to localStorage:', upiIdValue.trim());
      }

      const updatedShop = {
        ...this.shop,
        name: this.shopForm.value.name,
        nameTamil: this.shopForm.value.nameTamil,
        description: this.shopForm.value.description,
        ownerPhone: this.shopForm.value.phone,
        // Email is disabled and should not be updated
        addressLine1: this.shopForm.value.address,
        city: this.shopForm.value.city,
        postalCode: this.shopForm.value.pincode,
        upiId: this.shopForm.value.upiId,
        latitude: this.shopForm.value.latitude,
        longitude: this.shopForm.value.longitude
      };
      
      this.shopService.updateShop(this.shop.id, updatedShop).subscribe({
        next: (response) => {
          this.isLoading = false;
          this.shop = response;
          this.isEditMode = false;

          // Re-patch form with updated values from response
          this.shopForm.patchValue({
            name: response.name || '',
            nameTamil: response.nameTamil || '',
            description: response.description || '',
            phone: response.ownerPhone || '',
            address: response.addressLine1 || '',
            city: response.city || '',
            pincode: response.postalCode || '',
            upiId: response.upiId || '',
            latitude: response.latitude || null,
            longitude: response.longitude || null
          });

          // Save UPI ID to localStorage for POS Billing
          if (response.upiId) {
            localStorage.setItem('shop_upi_id', response.upiId);
          }

          // Refresh shop context so other pages (like POS Billing) get updated data
          this.shopContext.refreshShop();

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

  // Image upload methods
  triggerFileInput(): void {
    this.fileInput.nativeElement.click();
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      const file = input.files[0];

      // Validate file type
      if (!file.type.startsWith('image/')) {
        this.snackBar.open('Please select an image file', 'Close', {
          duration: 3000,
          horizontalPosition: 'end',
          verticalPosition: 'top',
          panelClass: ['error-snackbar']
        });
        return;
      }

      // Validate file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        this.snackBar.open('Image size should be less than 5MB', 'Close', {
          duration: 3000,
          horizontalPosition: 'end',
          verticalPosition: 'top',
          panelClass: ['error-snackbar']
        });
        return;
      }

      this.uploadImage(file);
    }
  }

  private uploadImage(file: File): void {
    if (!this.shop || !this.shop.id) {
      this.snackBar.open('Shop not found. Please refresh the page.', 'Close', {
        duration: 3000,
        horizontalPosition: 'end',
        verticalPosition: 'top',
        panelClass: ['error-snackbar']
      });
      return;
    }

    this.isUploadingImage = true;

    this.shopService.uploadShopImage(this.shop.id, file, 'LOGO').subscribe({
      next: (response) => {
        this.isUploadingImage = false;

        // Update the logo URL
        if (response && response.imageUrl) {
          this.shopLogoUrl = getImageUrl(response.imageUrl);
          this.shopLogoId = response.id;
        }

        this.snackBar.open('Shop logo uploaded successfully!', 'Close', {
          duration: 3000,
          horizontalPosition: 'end',
          verticalPosition: 'top',
          panelClass: ['success-snackbar']
        });

        // Reset the file input
        this.fileInput.nativeElement.value = '';
      },
      error: (error) => {
        this.isUploadingImage = false;
        console.error('Error uploading image:', error);
        this.snackBar.open('Failed to upload logo. Please try again.', 'Close', {
          duration: 3000,
          horizontalPosition: 'end',
          verticalPosition: 'top',
          panelClass: ['error-snackbar']
        });
      }
    });
  }

  removeLogo(): void {
    if (!this.shop || !this.shop.id || !this.shopLogoId) {
      return;
    }

    this.isUploadingImage = true;

    this.shopService.deleteShopImage(this.shop.id, this.shopLogoId).subscribe({
      next: () => {
        this.isUploadingImage = false;
        this.shopLogoUrl = null;
        this.shopLogoId = null;

        this.snackBar.open('Shop logo removed successfully', 'Close', {
          duration: 3000,
          horizontalPosition: 'end',
          verticalPosition: 'top',
          panelClass: ['success-snackbar']
        });
      },
      error: (error) => {
        this.isUploadingImage = false;
        console.error('Error removing logo:', error);
        this.snackBar.open('Failed to remove logo. Please try again.', 'Close', {
          duration: 3000,
          horizontalPosition: 'end',
          verticalPosition: 'top',
          panelClass: ['error-snackbar']
        });
      }
    });
  }

  private loadShopLogo(): void {
    if (this.shop && this.shop.images && this.shop.images.length > 0) {
      // Find the logo image
      const logoImage = this.shop.images.find(img => img.imageType === 'LOGO')
        || this.shop.images.find(img => img.isPrimary)
        || this.shop.images[0];

      if (logoImage) {
        this.shopLogoUrl = getImageUrl(logoImage.imageUrl);
        this.shopLogoId = logoImage.id;
      }
    }
  }
}