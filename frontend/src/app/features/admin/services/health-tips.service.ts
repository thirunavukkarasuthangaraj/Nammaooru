import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';

export interface HealthTip {
  id: number;
  message: string;
  status: 'PENDING' | 'APPROVED' | 'SENT' | 'REJECTED';
  scheduledDate: string;
  sentAt: string | null;
  approvedBy: string | null;
  approvedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface HealthTipQueueStats {
  PENDING: number;
  APPROVED: number;
  SENT: number;
  REJECTED: number;
}

@Injectable({
  providedIn: 'root'
})
export class HealthTipsService {
  private apiUrl = `${environment.apiUrl}/notifications/health-tip`;

  constructor(private http: HttpClient) {}

  generateWeeklyTips(): Observable<HealthTip[]> {
    return this.http.post<any>(`${this.apiUrl}/generate-week`, {}).pipe(
      map(response => response.data || [])
    );
  }

  getQueue(): Observable<{ data: HealthTip[]; stats: HealthTipQueueStats }> {
    return this.http.get<any>(`${this.apiUrl}/queue`).pipe(
      map(response => ({
        data: response.data || [],
        stats: response.stats || { PENDING: 0, APPROVED: 0, SENT: 0, REJECTED: 0 }
      }))
    );
  }

  editTip(tipId: number, message: string): Observable<HealthTip> {
    return this.http.put<any>(`${this.apiUrl}/queue/${tipId}/edit`, { message }).pipe(
      map(response => response.data || response)
    );
  }

  approveTip(tipId: number): Observable<HealthTip> {
    return this.http.put<any>(`${this.apiUrl}/queue/${tipId}/approve`, {}).pipe(
      map(response => response.data || response)
    );
  }

  rejectTip(tipId: number): Observable<HealthTip> {
    return this.http.put<any>(`${this.apiUrl}/queue/${tipId}/reject`, {}).pipe(
      map(response => response.data || response)
    );
  }

  sendNow(tipId: number): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/queue/${tipId}/send-now`, {});
  }

  getHistory(page: number = 0, size: number = 20): Observable<{
    data: HealthTip[];
    totalPages: number;
    totalElements: number;
    currentPage: number;
  }> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<any>(`${this.apiUrl}/history`, { params }).pipe(
      map(response => ({
        data: response.data || [],
        totalPages: response.totalPages || 0,
        totalElements: response.totalElements || 0,
        currentPage: response.currentPage || 0
      }))
    );
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'PENDING': return 'accent';
      case 'APPROVED': return 'primary';
      case 'SENT': return 'primary';
      case 'REJECTED': return 'warn';
      default: return '';
    }
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'PENDING': return 'hourglass_empty';
      case 'APPROVED': return 'check_circle';
      case 'SENT': return 'send';
      case 'REJECTED': return 'cancel';
      default: return 'help';
    }
  }
}
