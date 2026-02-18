import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { throwError } from 'rxjs';
import { ApiResponse, ApiResponseHelper } from '../models/api-response.model';
import { API_ENDPOINTS } from '../constants/app.constants';

export interface Notification {
  id: number;
  title: string;
  message: string;
  type: string;
  priority: string;
  isRead: boolean;
  createdAt: Date;
  action?: string;
  actionUrl?: string;
  actionData?: any;
  rejectionReason?: string;
}

@Injectable({
  providedIn: 'root'
})
export class NotificationService {
  private readonly API_URL = API_ENDPOINTS.BASE_URL + '/notifications';

  constructor(private http: HttpClient) {}

  getAllNotifications(page: number = 0, size: number = 20): Observable<{ content: Notification[], totalElements: number }> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<ApiResponse<any>>(this.API_URL, { params }).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return {
          content: apiResponse.data.content.map((notification: any) => ({
            ...notification,
            createdAt: new Date(notification.createdAt)
          })),
          totalElements: apiResponse.data.totalElements
        };
      }),
      catchError(error => {
        console.error('Error fetching notifications:', error);
        return throwError(() => error);
      })
    );
  }

  getUnreadNotifications(): Observable<Notification[]> {
    return this.http.get<ApiResponse<Notification[]>>(`${this.API_URL}/unread`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return (apiResponse.data || []).map(notification => ({
          ...notification,
          createdAt: new Date(notification.createdAt)
        }));
      }),
      catchError(error => {
        console.error('Error fetching unread notifications:', error);
        return throwError(() => error);
      })
    );
  }

  markAsRead(notificationId: number): Observable<void> {
    return this.http.put<ApiResponse<void>>(`${this.API_URL}/${notificationId}/read`, {}).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
      }),
      catchError(error => {
        console.error('Error marking notification as read:', error);
        return throwError(() => error);
      })
    );
  }

  markAllAsRead(): Observable<void> {
    return this.http.put<ApiResponse<void>>(`${this.API_URL}/read-all`, {}).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
      }),
      catchError(error => {
        console.error('Error marking all notifications as read:', error);
        return throwError(() => error);
      })
    );
  }

  deleteNotification(notificationId: number): Observable<void> {
    return this.http.delete<ApiResponse<void>>(`${this.API_URL}/${notificationId}`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
      }),
      catchError(error => {
        console.error('Error deleting notification:', error);
        return throwError(() => error);
      })
    );
  }

  getNotificationsByType(type: string): Observable<Notification[]> {
    const params = new HttpParams().set('type', type);
    return this.http.get<ApiResponse<Notification[]>>(`${this.API_URL}/type`, { params }).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return (apiResponse.data || []).map(notification => ({
          ...notification,
          createdAt: new Date(notification.createdAt)
        }));
      }),
      catchError(error => {
        console.error('Error fetching notifications by type:', error);
        return throwError(() => error);
      })
    );
  }

  getUnreadCount(): Observable<number> {
    return this.http.get<ApiResponse<number>>(`${this.API_URL}/unread/count`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          return 0;
        }
        return apiResponse.data || 0;
      }),
      catchError(error => {
        console.error('Error fetching unread count:', error);
        return throwError(() => 0);
      })
    );
  }

  clearAllNotifications(): Observable<void> {
    return this.http.delete<ApiResponse<void>>(`${this.API_URL}/clear-all`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
      }),
      catchError(error => {
        console.error('Error clearing all notifications:', error);
        return throwError(() => error);
      })
    );
  }

  sendTestNotification(notificationData: any): Observable<void> {
    return this.http.post<ApiResponse<void>>(`${this.API_URL}/test`, notificationData).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
      }),
      catchError(error => {
        console.error('Error sending test notification:', error);
        return throwError(() => error);
      })
    );
  }

  exportNotifications(format: string): Observable<Blob> {
    const params = new HttpParams().set('format', format);
    return this.http.get(`${this.API_URL}/export`, { 
      params, 
      responseType: 'blob' 
    }).pipe(
      catchError(error => {
        console.error('Error exporting notifications:', error);
        return throwError(() => error);
      })
    );
  }

  getShopNotifications(page: number = 0, size: number = 20): Observable<{ content: Notification[], totalElements: number }> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<ApiResponse<any>>(`${this.API_URL}/shop`, { params }).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return {
          content: (apiResponse.data?.content || []).map((notification: any) => ({
            ...notification,
            createdAt: new Date(notification.createdAt)
          })),
          totalElements: apiResponse.data?.totalElements || 0
        };
      }),
      catchError(error => {
        console.error('Error fetching shop notifications:', error);
        return throwError(() => error);
      })
    );
  }
}