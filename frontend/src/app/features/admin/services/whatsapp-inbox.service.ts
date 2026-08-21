import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, map } from 'rxjs';
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
  shopId: number | null;
  shopName: string | null;
  receivedAt: string | null;
  createdAt: string;
}

export interface ShopOption {
  id: number;
  name: string;
}

@Injectable({
  providedIn: 'root'
})
export class WhatsAppInboxService {
  // /shop-owner path is accessible to SUPER_ADMIN, ADMIN and SHOP_OWNER,
  // so one URL serves both the admin and the shop-owner screens
  private apiUrl = `${environment.apiUrl}/shop-owner/whatsapp-inbox`;

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

  assignShop(id: number, shop: ShopOption | null): Observable<WhatsAppInboxMessage> {
    return this.http.put<WhatsAppInboxMessage>(`${this.apiUrl}/${id}/assign`, {
      shopId: shop?.id ?? null,
      shopName: shop?.name ?? null
    });
  }

  /** Active shops for the assign dropdown. */
  getShops(): Observable<ShopOption[]> {
    return this.http.get<any>(`${environment.apiUrl}/shops/active`, {
      params: new HttpParams().set('page', 0).set('size', 200)
    }).pipe(
      map(res => (res?.data?.content || []).map((s: any) => ({ id: s.id, name: s.name })))
    );
  }
}
