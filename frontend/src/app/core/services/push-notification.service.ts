import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { throwError } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface PushNotificationRequest {
  title: string;
  message: string;
  priority: 'HIGH' | 'MEDIUM' | 'LOW';
  type: 'REMINDER' | 'SUCCESS' | 'PAYMENT' | 'ANNOUNCEMENT' | 'ERROR' | 'ORDER_UPDATE' | 'WARNING' | 'ORDER' | 'SYSTEM' | 'PROMOTION' | 'INFO';
  recipientType?: 'ALL_CUSTOMERS' | 'SPECIFIC_USER';
  recipientId?: number;
  sendPush?: boolean;
  latitude?: number;
  longitude?: number;
  radiusKm?: number;
}

export interface NotificationResponse {
  id: number;
  title: string;
  message: string;
  type: string;
  priority: string;
  recipientType: string;
  createdAt: string;
  status: string;
}

@Injectable({
  providedIn: 'root'
})
export class PushNotificationService {
  private readonly API_URL = `${environment.apiUrl}/notifications`;

  constructor(private http: HttpClient) {}

  /**
   * Send a broadcast notification to all customers
   * Uses the /api/notifications/broadcast endpoint
   */
  sendBroadcastNotification(request: PushNotificationRequest): Observable<NotificationResponse> {
    const payload: any = {
      title: request.title,
      message: request.message,
      priority: request.priority,
      type: request.type,
      recipientType: 'ALL_CUSTOMERS',
      sendPush: true
    };

    // Add location-based targeting if provided
    if (request.latitude && request.longitude && request.radiusKm) {
      payload.latitude = request.latitude;
      payload.longitude = request.longitude;
      payload.radiusKm = request.radiusKm;
    }

    return this.http.post<NotificationResponse>(`${this.API_URL}/broadcast`, payload).pipe(
      map(response => {
        return response;
      }),
      catchError(error => {
        console.error('Error sending broadcast notification:', error);
        return throwError(() => error);
      })
    );
  }

  /**
   * Send a notification to a specific user
   * Uses the /api/notifications endpoint
   */
  sendNotificationToUser(request: PushNotificationRequest): Observable<NotificationResponse> {
    const payload = {
      title: request.title,
      message: request.message,
      priority: request.priority,
      type: request.type,
      recipientType: 'SPECIFIC_USER',
      recipientId: request.recipientId,
      sendPush: true
    };

    return this.http.post<NotificationResponse>(this.API_URL, payload).pipe(
      map(response => {
        return response;
      }),
      catchError(error => {
        console.error('Error sending notification:', error);
        return throwError(() => error);
      })
    );
  }

  /**
   * Get notification enums from backend
   */
  getNotificationEnums(): Observable<any> {
    return this.http.get<any>(`${this.API_URL}/enums`).pipe(
      catchError(error => {
        console.error('Error fetching notification enums:', error);
        return throwError(() => error);
      })
    );
  }
}
