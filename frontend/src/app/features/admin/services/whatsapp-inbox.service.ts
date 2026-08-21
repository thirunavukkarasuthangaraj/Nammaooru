import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface WhatsAppInboxMessage {
  id: number;
  waMessageId: string;
  fromNumber: string;
  profileName: string | null;
  messageType: string;
  body: string | null;
  status: 'NEW' | 'PROCESSED';
  autoReplied: boolean;
  receivedAt: string | null;
  createdAt: string;
}

@Injectable({
  providedIn: 'root'
})
export class WhatsAppInboxService {
  private apiUrl = `${environment.apiUrl}/admin/whatsapp-inbox`;

  constructor(private http: HttpClient) {}

  /** Backend returns a Spring Page directly: { content, totalElements, totalPages, ... } */
  list(status: string, page: number = 0, size: number = 20): Observable<any> {
    let params = new HttpParams().set('page', page).set('size', size);
    if (status) {
      params = params.set('status', status);
    }
    return this.http.get(this.apiUrl, { params });
  }

  summary(): Observable<{ newCount: number; processedCount: number }> {
    return this.http.get<{ newCount: number; processedCount: number }>(`${this.apiUrl}/summary`);
  }

  markProcessed(id: number): Observable<WhatsAppInboxMessage> {
    return this.http.put<WhatsAppInboxMessage>(`${this.apiUrl}/${id}/processed`, {});
  }
}
