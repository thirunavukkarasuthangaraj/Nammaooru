import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, BehaviorSubject, timer } from 'rxjs';
import { map, switchMap, catchError } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';

export interface BusinessHour {
  id?: number;
  shopId?: number;
  dayOfWeek: string;
  openTime: string | null;
  closeTime: string | null;
  isOpen: boolean;
  is24Hours?: boolean;
  breakStartTime?: string | null;
  breakEndTime?: string | null;
  specialNote?: string;
}

export interface ShopStatus {
  isOpen: boolean;
  status: string;
  message: string;
  overallStatus?: string;
  businessHours?: BusinessHour;
  currentTime?: string;
  currentDay?: string;
  openTime?: string;
  closeTime?: string;
  breakEndTime?: string;
  nextOpenTime?: any;
}

export interface WeeklySchedule {
  dayOfWeek: string;
  dayName: string;
  isOpen: boolean;
  schedule: string;
  is24Hours: boolean;
  openTime?: string;
  closeTime?: string;
  breakTime?: string;
  specialNote?: string;
}

@Injectable({
  providedIn: 'root'
})
export class BusinessHoursService {
  private readonly apiUrl = `${environment.apiUrl}/business-hours`;
  private readonly availabilityUrl = `${environment.apiUrl}/shop-availability`;
  
  private statusSubject = new BehaviorSubject<ShopStatus | null>(null);
  public status$ = this.statusSubject.asObservable();
  
  private scheduleSubject = new BehaviorSubject<WeeklySchedule[]>([]);
  public schedule$ = this.scheduleSubject.asObservable();

  constructor(private http: HttpClient) {
    this.startStatusPolling();
  }

  // Business Hours CRUD Operations
  getBusinessHours(shopId: number): Observable<BusinessHour[]> {
    return this.http.get<BusinessHour[]>(`${this.apiUrl}/shop/${shopId}`);
  }

  createBusinessHour(businessHour: BusinessHour): Observable<BusinessHour> {
    return this.http.post<BusinessHour>(this.apiUrl, businessHour);
  }

  updateBusinessHour(id: number, businessHour: BusinessHour): Observable<BusinessHour> {
    return this.http.put<BusinessHour>(`${this.apiUrl}/${id}`, businessHour);
  }

  deleteBusinessHour(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  createDefaultBusinessHours(shopId: number): Observable<BusinessHour[]> {
    return this.http.post<BusinessHour[]>(`${this.apiUrl}/shop/${shopId}/default`, {});
  }

  bulkUpdateBusinessHours(shopId: number, businessHours: BusinessHour[]): Observable<BusinessHour[]> {
    return this.http.put<BusinessHour[]>(`${this.apiUrl}/shop/${shopId}/bulk`, businessHours);
  }

  // Status and Schedule Operations
  getShopStatus(shopId: number): Observable<ShopStatus> {
    return this.http.get<ShopStatus>(`${this.apiUrl}/shop/${shopId}/status`)
      .pipe(
        map(status => {
          this.statusSubject.next(status);
          return status;
        })
      );
  }

  getWeeklySchedule(shopId: number): Observable<WeeklySchedule[]> {
    return this.http.get<WeeklySchedule[]>(`${this.apiUrl}/shop/${shopId}/schedule`)
      .pipe(
        map(schedule => {
          this.scheduleSubject.next(schedule);
          return schedule;
        })
      );
  }

  // Availability Operations
  getAvailabilityStatus(shopId: number): Observable<any> {
    return this.http.get(`${this.availabilityUrl}/${shopId}/status`);
  }

  forceUpdateAvailability(shopId: number): Observable<any> {
    return this.http.post(`${this.availabilityUrl}/${shopId}/force-update`, {});
  }

  overrideAvailability(shopId: number, isAvailable: boolean, reason?: string): Observable<any> {
    const params: any = { isAvailable };
    if (reason) params.reason = reason;
    return this.http.post(`${this.availabilityUrl}/${shopId}/override`, null, { params });
  }

  clearAvailabilityOverride(shopId: number): Observable<any> {
    return this.http.post(`${this.availabilityUrl}/${shopId}/clear-override`, {});
  }

  // Real-time Status Polling
  private startStatusPolling(): void {
    // Poll status every 30 seconds
    timer(0, 30000).pipe(
      switchMap(() => this.getCurrentShopId()),
      switchMap(shopId => {
        if (shopId) {
          return this.getShopStatus(shopId);
        }
        return [];
      }),
      catchError(error => {
        console.error('Status polling error:', error);
        return [];
      })
    ).subscribe();
  }

  private getCurrentShopId(): Observable<number | null> {
    // This should get the current user's shop ID
    // You might need to inject ShopService or AuthService here
    return new Observable(observer => {
      // For now, return null - implement based on your auth/shop service
      observer.next(null);
      observer.complete();
    });
  }

  // Utility Methods
  convertToBackendFormat(shopId: number, businessHours: any[]): BusinessHour[] {
    const dayMapping: { [key: string]: string } = {
      'monday': 'MONDAY',
      'tuesday': 'TUESDAY',
      'wednesday': 'WEDNESDAY',
      'thursday': 'THURSDAY',
      'friday': 'FRIDAY',
      'saturday': 'SATURDAY',
      'sunday': 'SUNDAY'
    };

    return businessHours.map(hour => ({
      shopId: shopId,
      dayOfWeek: dayMapping[hour.day] || hour.day.toUpperCase(),
      openTime: hour.closed ? null : hour.open,
      closeTime: hour.closed ? null : hour.close,
      isOpen: !hour.closed,
      is24Hours: hour.open === '00:00' && hour.close === '23:59',
      breakStartTime: hour.breakStart || null,
      breakEndTime: hour.breakEnd || null,
      specialNote: hour.specialNote || null
    }));
  }

  convertFromBackendFormat(businessHours: BusinessHour[]): any[] {
    const dayMapping: { [key: string]: string } = {
      'MONDAY': 'monday',
      'TUESDAY': 'tuesday',
      'WEDNESDAY': 'wednesday',
      'THURSDAY': 'thursday',
      'FRIDAY': 'friday',
      'SATURDAY': 'saturday',
      'SUNDAY': 'sunday'
    };

    const displayNames: { [key: string]: string } = {
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday'
    };

    return businessHours.map(hour => ({
      id: hour.id,
      day: dayMapping[hour.dayOfWeek] || hour.dayOfWeek.toLowerCase(),
      displayName: displayNames[dayMapping[hour.dayOfWeek]] || hour.dayOfWeek,
      open: hour.openTime || '09:00',
      close: hour.closeTime || '18:00',
      closed: !hour.isOpen,
      breakStart: hour.breakStartTime,
      breakEnd: hour.breakEndTime,
      specialNote: hour.specialNote
    }));
  }

  formatTime(time: string): string {
    if (!time) return '';
    const [hours, minutes] = time.split(':');
    const h = parseInt(hours);
    const suffix = h >= 12 ? 'PM' : 'AM';
    const displayHour = h === 0 ? 12 : h > 12 ? h - 12 : h;
    return `${displayHour}:${minutes} ${suffix}`;
  }

  formatTimeRange(openTime: string, closeTime: string): string {
    if (!openTime || !closeTime) return 'Closed';
    return `${this.formatTime(openTime)} - ${this.formatTime(closeTime)}`;
  }

  isCurrentlyInBreak(breakStart?: string, breakEnd?: string): boolean {
    if (!breakStart || !breakEnd) return false;
    
    const now = new Date();
    const currentTime = now.getHours().toString().padStart(2, '0') + ':' + 
                       now.getMinutes().toString().padStart(2, '0');
    
    return currentTime >= breakStart && currentTime <= breakEnd;
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'OPEN': return '#10b981'; // green
      case 'CLOSED': return '#ef4444'; // red
      case 'ON_BREAK': return '#f59e0b'; // yellow
      case 'OPENS_LATER': return '#3b82f6'; // blue
      case 'CLOSED_FOR_DAY': return '#6b7280'; // gray
      default: return '#6b7280';
    }
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'OPEN': return 'check_circle';
      case 'CLOSED': return 'cancel';
      case 'ON_BREAK': return 'pause_circle';
      case 'OPENS_LATER': return 'schedule';
      case 'CLOSED_FOR_DAY': return 'block';
      default: return 'help';
    }
  }
}