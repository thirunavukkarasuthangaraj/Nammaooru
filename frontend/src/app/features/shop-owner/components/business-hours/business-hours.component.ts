import { Component, OnInit, OnDestroy } from '@angular/core';
import { FormBuilder, FormGroup } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { ShopService } from '@core/services/shop.service';
import { BusinessHoursService, BusinessHour, ShopStatus } from '../../services/business-hours.service';
import { finalize, takeUntil } from 'rxjs/operators';
import { Subject } from 'rxjs';

interface LocalBusinessHour {
  id?: number;
  day: string;
  displayName: string;
  open: string;
  close: string;
  closed: boolean;
  breakStart?: string;
  breakEnd?: string;
  specialNote?: string;
}

@Component({
  selector: 'app-business-hours',
  template: `
    <div class="business-hours-container">
      <div class="page-header">
        <div class="header-content">
          <h1>Business Hours</h1>
          <p>Configure your shop's operating hours</p>
          <!-- Real-time Status Badge -->
          <div class="status-badge" *ngIf="shopStatus" [style.background-color]="getStatusBadge().color">
            <mat-icon>{{ getStatusBadge().icon }}</mat-icon>
            <span>{{ getStatusBadge().text }}</span>
          </div>
        </div>
        <div class="header-actions">
          <!-- Status Control Buttons -->
          <div class="status-controls" *ngIf="shopStatus">
            <button mat-stroked-button 
                    (click)="forceUpdateStatus()" 
                    matTooltip="Force update shop status">
              <mat-icon>refresh</mat-icon>
              Update Status
            </button>
            
            <button mat-stroked-button 
                    *ngIf="!shopStatus.isOpen" 
                    (click)="overrideStatus(true)"
                    color="primary"
                    matTooltip="Manually open shop now">
              <mat-icon>lock_open</mat-icon>
              Open Now
            </button>
            
            <button mat-stroked-button 
                    *ngIf="shopStatus.isOpen" 
                    (click)="overrideStatus(false)"
                    color="warn"
                    matTooltip="Manually close shop now">
              <mat-icon>lock</mat-icon>
              Close Now
            </button>
            
            <button mat-stroked-button 
                    *ngIf="shopStatus && shopStatus.overallStatus?.includes('MANUALLY')"
                    (click)="clearOverride()"
                    matTooltip="Return to automatic schedule">
              <mat-icon>schedule</mat-icon>
              Auto Mode
            </button>
          </div>
          
          <button mat-stroked-button (click)="copyToAllDays()">
            <mat-icon>content_copy</mat-icon>
            Copy Monday to All
          </button>
          <button mat-raised-button color="primary" (click)="saveBusinessHours()" [disabled]="loading">
            <mat-spinner *ngIf="loading" diameter="20"></mat-spinner>
            <mat-icon *ngIf="!loading">save</mat-icon>
            Save Changes
          </button>
        </div>
      </div>

      <!-- Current Status Card -->
      <mat-card class="status-card" *ngIf="shopStatus">
        <mat-card-header>
          <mat-card-title>
            <mat-icon>info</mat-icon>
            Current Status
          </mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="status-info">
            <div class="status-item">
              <span class="label">Status:</span>
              <span class="value" [style.color]="getStatusBadge().color">
                <mat-icon>{{ getStatusBadge().icon }}</mat-icon>
                {{ shopStatus.message }}
              </span>
            </div>
            <div class="status-item" *ngIf="shopStatus.currentTime">
              <span class="label">Current Time:</span>
              <span class="value">{{ shopStatus.currentTime }} ({{ shopStatus.currentDay }})</span>
            </div>
            <div class="status-item" *ngIf="shopStatus.openTime && shopStatus.isOpen">
              <span class="label">Today's Hours:</span>
              <span class="value">{{ shopStatus.openTime }} - {{ shopStatus.closeTime }}</span>
            </div>
            <div class="status-item" *ngIf="shopStatus.nextOpenTime?.dateTime && !shopStatus.isOpen">
              <span class="label">Next Open:</span>
              <span class="value">{{ shopStatus.nextOpenTime.dayOfWeek }} at {{ shopStatus.nextOpenTime.time }}</span>
            </div>
            <div class="status-item" *ngIf="shopStatus.breakEndTime">
              <span class="label">Break Ends:</span>
              <span class="value">{{ shopStatus.breakEndTime }}</span>
            </div>
          </div>
        </mat-card-content>
      </mat-card>

      <mat-card class="hours-card">
        <mat-card-content>
          <form [formGroup]="businessHoursForm">
            <div class="hours-grid">
              <!-- Individual Day Cards -->
              <mat-card class="day-card" *ngFor="let hour of businessHours">
                <mat-card-header>
                  <mat-card-title>
                    <span class="day-name">{{ hour.displayName }}</span>
                    <mat-slide-toggle 
                      [(ngModel)]="hour.closed" 
                      [ngModelOptions]="{standalone: true}"
                      (change)="onDayToggle(hour)">
                      {{ hour.closed ? 'Closed' : 'Open' }}
                    </mat-slide-toggle>
                  </mat-card-title>
                </mat-card-header>
                
                <mat-card-content>
                  <div class="time-inputs" [class.disabled]="hour.closed">
                    <mat-form-field appearance="outline">
                      <mat-label>Opening Time</mat-label>
                      <input matInput type="time" 
                             [(ngModel)]="hour.open"
                             [ngModelOptions]="{standalone: true}"
                             [disabled]="hour.closed">
                    </mat-form-field>
                    
                    <span class="time-separator">to</span>
                    
                    <mat-form-field appearance="outline">
                      <mat-label>Closing Time</mat-label>
                      <input matInput type="time" 
                             [(ngModel)]="hour.close"
                             [ngModelOptions]="{standalone: true}"
                             [disabled]="hour.closed">
                    </mat-form-field>
                  </div>
                  
                  <div class="time-display" *ngIf="!hour.closed">
                    <mat-icon>schedule</mat-icon>
                    <span>{{ formatTimeRange(hour) }}</span>
                  </div>
                  
                  <div class="closed-display" *ngIf="hour.closed">
                    <mat-icon>block</mat-icon>
                    <span>Closed All Day</span>
                  </div>
                </mat-card-content>
              </mat-card>
            </div>

            <!-- Quick Actions Section -->
            <mat-card class="quick-actions">
              <mat-card-header>
                <mat-card-title>Quick Actions</mat-card-title>
              </mat-card-header>
              <mat-card-content>
                <div class="action-buttons">
                  <button mat-stroked-button type="button" (click)="setDefaultHours()">
                    <mat-icon>restore</mat-icon>
                    Set Default Hours (9 AM - 6 PM)
                  </button>
                  <button mat-stroked-button type="button" (click)="set24Hours()">
                    <mat-icon>access_time</mat-icon>
                    Set 24 Hours
                  </button>
                  <button mat-stroked-button type="button" (click)="closeWeekends()">
                    <mat-icon>weekend</mat-icon>
                    Close Weekends
                  </button>
                  <button mat-stroked-button type="button" (click)="openAllDays()">
                    <mat-icon>check_circle</mat-icon>
                    Open All Days
                  </button>
                </div>
              </mat-card-content>
            </mat-card>

            <!-- Holiday Settings -->
            <mat-card class="holiday-settings">
              <mat-card-header>
                <mat-card-title>
                  <mat-icon>event</mat-icon>
                  Holiday Settings
                </mat-card-title>
              </mat-card-header>
              <mat-card-content>
                <div class="holiday-info">
                  <p>Configure special hours for holidays and special occasions</p>
                  <button mat-raised-button color="accent">
                    <mat-icon>add</mat-icon>
                    Add Holiday
                  </button>
                </div>
                
                <div class="holiday-list" *ngIf="holidays.length > 0">
                  <div class="holiday-item" *ngFor="let holiday of holidays">
                    <div class="holiday-details">
                      <span class="holiday-date">{{ holiday.date | date:'MMM d, y' }}</span>
                      <span class="holiday-name">{{ holiday.name }}</span>
                      <span class="holiday-status">{{ holiday.closed ? 'Closed' : holiday.hours }}</span>
                    </div>
                    <button mat-icon-button color="warn" (click)="removeHoliday(holiday)">
                      <mat-icon>delete</mat-icon>
                    </button>
                  </div>
                </div>
              </mat-card-content>
            </mat-card>
          </form>
        </mat-card-content>
      </mat-card>

      <!-- Preview Card -->
      <mat-card class="preview-card">
        <mat-card-header>
          <mat-card-title>
            <mat-icon>visibility</mat-icon>
            Preview
          </mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <h3>Your shop will display these hours to customers:</h3>
          <div class="preview-list">
            <div class="preview-item" *ngFor="let hour of businessHours">
              <span class="preview-day">{{ hour.displayName }}:</span>
              <span class="preview-hours" [class.closed]="hour.closed">
                {{ hour.closed ? 'Closed' : formatTimeRange(hour) }}
              </span>
            </div>
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .business-hours-container {
      padding: 24px;
      background-color: #f5f5f5;
      min-height: calc(100vh - 64px);
    }

    .page-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
      background: white;
      padding: 24px;
      border-radius: 12px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .header-content h1 {
      margin: 0 0 4px 0;
      font-size: 2rem;
      font-weight: 600;
      color: #1f2937;
    }

    .header-content p {
      margin: 0;
      color: #6b7280;
    }

    .header-actions {
      display: flex;
      gap: 12px;
      align-items: center;
      flex-wrap: wrap;
    }

    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 12px;
      border-radius: 20px;
      color: white;
      font-size: 0.875rem;
      font-weight: 500;
      margin-top: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .status-badge mat-icon {
      font-size: 16px;
      height: 16px;
      width: 16px;
    }

    .status-controls {
      display: flex;
      gap: 8px;
      margin-right: 12px;
      border-right: 1px solid #e5e7eb;
      padding-right: 12px;
    }

    .status-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      margin-bottom: 24px;
      border-left: 4px solid #3b82f6;
    }

    .status-info {
      display: grid;
      gap: 12px;
    }

    .status-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 8px 0;
      border-bottom: 1px solid #f3f4f6;
    }

    .status-item:last-child {
      border-bottom: none;
    }

    .status-item .label {
      font-weight: 500;
      color: #374151;
    }

    .status-item .value {
      display: flex;
      align-items: center;
      gap: 6px;
      font-weight: 600;
      color: #1f2937;
    }

    .status-item .value mat-icon {
      font-size: 18px;
      height: 18px;
      width: 18px;
    }

    .hours-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      margin-bottom: 24px;
    }

    .hours-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .day-card {
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      transition: all 0.3s ease;
    }

    .day-card:hover {
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      transform: translateY(-2px);
    }

    .day-card mat-card-header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      border-radius: 8px 8px 0 0;
      padding: 12px 16px;
    }

    .day-card mat-card-title {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin: 0;
    }

    .day-name {
      font-size: 1.1rem;
      font-weight: 500;
    }

    .time-inputs {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-top: 16px;
    }

    .time-inputs.disabled {
      opacity: 0.5;
      pointer-events: none;
    }

    .time-separator {
      font-weight: 500;
      color: #6b7280;
    }

    .time-display, .closed-display {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-top: 12px;
      padding: 8px 12px;
      border-radius: 6px;
      font-size: 0.95rem;
    }

    .time-display {
      background: #e0f2fe;
      color: #0284c7;
    }

    .closed-display {
      background: #fee2e2;
      color: #dc2626;
    }

    .quick-actions, .holiday-settings, .preview-card {
      margin-top: 24px;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .action-buttons {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 12px;
    }

    .holiday-info {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px;
      background: #f9fafb;
      border-radius: 8px;
      margin-bottom: 16px;
    }

    .holiday-info p {
      margin: 0;
      color: #6b7280;
    }

    .holiday-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .holiday-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px;
      border: 1px solid #e5e7eb;
      border-radius: 6px;
      background: white;
    }

    .holiday-details {
      display: flex;
      gap: 16px;
      align-items: center;
    }

    .holiday-date {
      font-weight: 500;
      color: #1f2937;
    }

    .holiday-name {
      color: #6b7280;
    }

    .holiday-status {
      padding: 4px 8px;
      border-radius: 4px;
      background: #fef3c7;
      color: #92400e;
      font-size: 0.875rem;
    }

    .preview-list {
      display: grid;
      gap: 12px;
      margin-top: 16px;
    }

    .preview-item {
      display: flex;
      justify-content: space-between;
      padding: 12px;
      border-bottom: 1px solid #e5e7eb;
    }

    .preview-item:last-child {
      border-bottom: none;
    }

    .preview-day {
      font-weight: 500;
      color: #1f2937;
    }

    .preview-hours {
      color: #059669;
      font-weight: 500;
    }

    .preview-hours.closed {
      color: #dc2626;
    }

    mat-spinner {
      display: inline-block;
      margin-right: 8px;
    }

    /* Mobile Responsive */
    @media (max-width: 768px) {
      .business-hours-container {
        padding: 16px;
      }

      .page-header {
        flex-direction: column;
        gap: 16px;
        text-align: center;
      }

      .hours-grid {
        grid-template-columns: 1fr;
      }

      .time-inputs {
        flex-direction: column;
      }

      .time-separator {
        display: none;
      }

      .action-buttons {
        grid-template-columns: 1fr;
      }

      .holiday-details {
        flex-direction: column;
        align-items: flex-start;
        gap: 4px;
      }
    }
  `]
})
export class BusinessHoursComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  currentShopId: number | null = null;
  shopStatus: ShopStatus | null = null;
  businessHoursForm: FormGroup;
  loading = false;
  
  businessHours: LocalBusinessHour[] = [
    { day: 'monday', displayName: 'Monday', open: '09:00', close: '18:00', closed: false },
    { day: 'tuesday', displayName: 'Tuesday', open: '09:00', close: '18:00', closed: false },
    { day: 'wednesday', displayName: 'Wednesday', open: '09:00', close: '18:00', closed: false },
    { day: 'thursday', displayName: 'Thursday', open: '09:00', close: '18:00', closed: false },
    { day: 'friday', displayName: 'Friday', open: '09:00', close: '18:00', closed: false },
    { day: 'saturday', displayName: 'Saturday', open: '09:00', close: '18:00', closed: false },
    { day: 'sunday', displayName: 'Sunday', open: '09:00', close: '18:00', closed: true }
  ];

  holidays: any[] = [];

  constructor(
    private fb: FormBuilder,
    private snackBar: MatSnackBar,
    private shopService: ShopService,
    private businessHoursService: BusinessHoursService
  ) {
    this.businessHoursForm = this.fb.group({});
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  ngOnInit(): void {
    this.loadBusinessHours();
    this.subscribeToStatusUpdates();
  }

  private subscribeToStatusUpdates(): void {
    this.businessHoursService.status$
      .pipe(takeUntil(this.destroy$))
      .subscribe(status => {
        this.shopStatus = status;
      });
  }

  loadBusinessHours(): void {
    this.loading = true;
    
    // First get shop info to get shop ID
    this.shopService.getMyShop()
      .pipe(finalize(() => this.loading = false))
      .subscribe({
        next: (shop: any) => {
          if (shop) {
            this.currentShopId = shop.id;
            this.loadBusinessHoursFromAPI(shop.id);
            this.loadShopStatus(shop.id);
          }
        },
        error: (error) => {
          console.error('Error loading shop:', error);
          if (error.status === 404) {
            this.snackBar.open('No shop found. Please contact admin to assign a shop.', 'Close', { 
              duration: 5000 
            });
          } else {
            this.snackBar.open('Failed to load shop data.', 'Close', { 
              duration: 3000 
            });
          }
        }
      });
  }

  private loadBusinessHoursFromAPI(shopId: number): void {
    this.businessHoursService.getBusinessHours(shopId)
      .subscribe({
        next: (hours: BusinessHour[]) => {
          if (hours && hours.length > 0) {
            this.businessHours = this.businessHoursService.convertFromBackendFormat(hours);
          } else {
            // Create default hours if none exist
            this.createDefaultBusinessHours(shopId);
          }
        },
        error: (error) => {
          console.error('Error loading business hours:', error);
          this.setDefaultHours();
          this.snackBar.open('Failed to load business hours. Using defaults.', 'Close', { 
            duration: 3000 
          });
        }
      });
  }

  private loadShopStatus(shopId: number): void {
    this.businessHoursService.getShopStatus(shopId)
      .subscribe({
        next: (status) => {
          this.shopStatus = status;
        },
        error: (error) => {
          console.error('Error loading shop status:', error);
        }
      });
  }

  private createDefaultBusinessHours(shopId: number): void {
    this.businessHoursService.createDefaultBusinessHours(shopId)
      .subscribe({
        next: (hours: BusinessHour[]) => {
          this.businessHours = this.businessHoursService.convertFromBackendFormat(hours);
          this.snackBar.open('Default business hours created. Please configure your schedule.', 'Close', { 
            duration: 3000 
          });
        },
        error: (error) => {
          console.error('Error creating default hours:', error);
          this.setDefaultHours();
        }
      });
  }

  saveBusinessHours(): void {
    if (!this.currentShopId) {
      this.snackBar.open('No shop found. Cannot save business hours.', 'Close', { duration: 3000 });
      return;
    }

    this.loading = true;
    
    const businessHoursData = this.businessHoursService.convertToBackendFormat(
      this.currentShopId, 
      this.businessHours
    );

    this.businessHoursService.bulkUpdateBusinessHours(this.currentShopId, businessHoursData)
      .pipe(finalize(() => this.loading = false))
      .subscribe({
        next: (updatedHours) => {
          this.businessHours = this.businessHoursService.convertFromBackendFormat(updatedHours);
          this.snackBar.open('Business hours saved successfully!', 'Close', { 
            duration: 3000,
            horizontalPosition: 'end',
            verticalPosition: 'top'
          });
          
          // Refresh shop status
          if (this.currentShopId) {
            this.loadShopStatus(this.currentShopId);
          }
        },
        error: (error) => {
          console.error('Error saving business hours:', error);
          this.snackBar.open('Failed to save business hours. Please try again.', 'Close', { 
            duration: 3000 
          });
        }
      });
  }

  onDayToggle(hour: LocalBusinessHour): void {
    if (hour.closed) {
      // Day is now closed, clear times
      hour.open = '';
      hour.close = '';
    } else {
      // Day is now open, set default times
      hour.open = '09:00';
      hour.close = '18:00';
    }
  }

  copyToAllDays(): void {
    const monday = this.businessHours[0];
    this.businessHours.forEach((hour, index) => {
      if (index !== 0) {
        hour.open = monday.open;
        hour.close = monday.close;
        hour.closed = monday.closed;
      }
    });
    
    this.snackBar.open('Monday hours copied to all days', 'Close', { duration: 2000 });
  }

  setDefaultHours(): void {
    this.businessHours.forEach(hour => {
      hour.open = '09:00';
      hour.close = '18:00';
      hour.closed = false;
    });
    
    // Close Sunday by default
    this.businessHours[6].closed = true;
    
    this.snackBar.open('Default hours set (9 AM - 6 PM)', 'Close', { duration: 2000 });
  }

  set24Hours(): void {
    this.businessHours.forEach(hour => {
      hour.open = '00:00';
      hour.close = '23:59';
      hour.closed = false;
    });
    
    this.snackBar.open('24-hour operation set for all days', 'Close', { duration: 2000 });
  }

  closeWeekends(): void {
    // Saturday and Sunday
    this.businessHours[5].closed = true;
    this.businessHours[6].closed = true;
    
    this.snackBar.open('Weekends set to closed', 'Close', { duration: 2000 });
  }

  openAllDays(): void {
    this.businessHours.forEach(hour => {
      hour.closed = false;
      if (!hour.open) hour.open = '09:00';
      if (!hour.close) hour.close = '18:00';
    });
    
    this.snackBar.open('All days set to open', 'Close', { duration: 2000 });
  }

  formatTimeRange(hour: LocalBusinessHour): string {
    if (hour.closed) return 'Closed';
    return this.businessHoursService.formatTimeRange(hour.open, hour.close);
  }

  getStatusBadge(): { text: string; color: string; icon: string } {
    if (!this.shopStatus) {
      return { text: 'Loading...', color: '#6b7280', icon: 'help' };
    }
    
    return {
      text: this.shopStatus.status.replace('_', ' '),
      color: this.businessHoursService.getStatusColor(this.shopStatus.status),
      icon: this.businessHoursService.getStatusIcon(this.shopStatus.status)
    };
  }

  forceUpdateStatus(): void {
    if (!this.currentShopId) return;
    
    this.businessHoursService.forceUpdateAvailability(this.currentShopId)
      .subscribe({
        next: () => {
          this.snackBar.open('Shop status updated!', 'Close', { duration: 2000 });
          this.loadShopStatus(this.currentShopId!);
        },
        error: (error) => {
          console.error('Error updating status:', error);
          this.snackBar.open('Failed to update status', 'Close', { duration: 2000 });
        }
      });
  }

  overrideStatus(isOpen: boolean): void {
    if (!this.currentShopId) return;
    
    const reason = isOpen ? 'Manual override: Opened by shop owner' : 'Manual override: Closed by shop owner';
    
    this.businessHoursService.overrideAvailability(this.currentShopId, isOpen, reason)
      .subscribe({
        next: () => {
          this.snackBar.open(`Shop manually ${isOpen ? 'opened' : 'closed'}!`, 'Close', { duration: 2000 });
          this.loadShopStatus(this.currentShopId!);
        },
        error: (error) => {
          console.error('Error overriding status:', error);
          this.snackBar.open('Failed to override status', 'Close', { duration: 2000 });
        }
      });
  }

  clearOverride(): void {
    if (!this.currentShopId) return;
    
    this.businessHoursService.clearAvailabilityOverride(this.currentShopId)
      .subscribe({
        next: () => {
          this.snackBar.open('Manual override cleared. Using automatic schedule.', 'Close', { duration: 3000 });
          this.loadShopStatus(this.currentShopId!);
        },
        error: (error) => {
          console.error('Error clearing override:', error);
          this.snackBar.open('Failed to clear override', 'Close', { duration: 2000 });
        }
      });
  }

  formatTimeRangeLegacy(hour: LocalBusinessHour): string {
    if (hour.closed) return 'Closed';
    return this.businessHoursService.formatTimeRange(hour.open, hour.close);
  }

  removeHoliday(holiday: any): void {
    const index = this.holidays.indexOf(holiday);
    if (index > -1) {
      this.holidays.splice(index, 1);
      this.snackBar.open('Holiday removed', 'Close', { duration: 2000 });
    }
  }
}