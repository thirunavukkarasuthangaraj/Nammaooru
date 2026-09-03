import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface ShopBalanceRow {
  shopId: number;
  shopName: string;
  balance: number;
  totalEarned: number;
  totalWithdrawn: number;
}

@Injectable({
  providedIn: 'root'
})
export class ShopPaymentsService {
  private apiUrl = `${environment.apiUrl}/wallet/admin`;

  constructor(private http: HttpClient) {}

  getShopsSummary(page: number = 0, size: number = 100): Observable<any> {
    return this.http.get(`${this.apiUrl}/shops-summary`, { params: { page, size } });
  }

  getShopSummary(shopId: number, date?: string): Observable<any> {
    const params: { date?: string } = {};
    if (date) params.date = date;
    return this.http.get(`${this.apiUrl}/shop/${shopId}/summary`, { params });
  }

  getShopOrders(shopId: number, startDate?: string, endDate?: string, page: number = 0, size: number = 1000): Observable<any> {
    const params: { startDate?: string; endDate?: string; page: number; size: number } = { page, size };
    if (startDate) params.startDate = startDate;
    if (endDate) params.endDate = endDate;
    return this.http.get(`${this.apiUrl}/shop/${shopId}/orders`, { params });
  }

  // amount omitted = release the full wallet balance
  releasePayment(shopId: number, payoutReference: string, amount?: number): Observable<any> {
    const body: { payoutReference: string; amount?: string } = { payoutReference };
    if (amount != null) body.amount = amount.toFixed(2);
    return this.http.post(`${this.apiUrl}/shop/${shopId}/release-payment`, body);
  }

  getPayoutHistory(shopId: number, page: number = 0, size: number = 20): Observable<any> {
    return this.http.get(`${this.apiUrl}/shop/${shopId}/payout-history`, { params: { page, size } });
  }
}
