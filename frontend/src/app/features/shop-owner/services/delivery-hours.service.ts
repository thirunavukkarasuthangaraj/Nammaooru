import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

/**
 * A single day of DELIVERY hours.
 *
 * Deliberately the same shape as BusinessHour: a shop open 9 to 9 may deliver only
 * 10 to 7, so the two are stored separately, but the editor for them is identical.
 */
export interface DeliveryHour {
  id?: number;
  shopId?: number;
  /** MONDAY, TUESDAY ... matches the Java DayOfWeek the API expects. */
  dayOfWeek: string;
  openTime?: string | null;
  closeTime?: string | null;
  breakStartTime?: string | null;
  breakEndTime?: string | null;
  isOpen: boolean;
  is24Hours?: boolean;
  specialNote?: string | null;
}

@Injectable({ providedIn: 'root' })
export class DeliveryHoursService {
  private readonly apiUrl = `${environment.apiUrl}/delivery-hours`;

  constructor(private http: HttpClient) {}

  getByShop(shopId: number): Observable<DeliveryHour[]> {
    return this.http.get<DeliveryHour[]>(`${this.apiUrl}/shop/${shopId}`);
  }

  /**
   * Whether this shop's delivery hours still match its opening hours, which is what the
   * "Same as opening hours" toggle shows when the screen loads.
   */
  matchesBusinessHours(shopId: number): Observable<{ matches: boolean }> {
    return this.http.get<{ matches: boolean }>(
      `${this.apiUrl}/shop/${shopId}/matches-business-hours`
    );
  }

  /**
   * Replace the whole week in one call. The editor saves seven days together, so a
   * per-day save would leave a half-updated week if the browser died mid-save.
   */
  replaceWeek(shopId: number, week: DeliveryHour[]): Observable<DeliveryHour[]> {
    return this.http.put<DeliveryHour[]>(`${this.apiUrl}/shop/${shopId}/bulk`, week);
  }

  /** Backs the "Same as opening hours" toggle being switched back on. */
  copyFromBusinessHours(shopId: number): Observable<DeliveryHour[]> {
    return this.http.post<DeliveryHour[]>(
      `${this.apiUrl}/shop/${shopId}/copy-from-business-hours`,
      {}
    );
  }
}
