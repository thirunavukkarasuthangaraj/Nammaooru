import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface PaymentSummary {
  date: string;
  daySales: number;
  dayOrderCount: number;
  totalSales: number;
  walletBalance: number;
  totalEarned: number;
  totalWithdrawn: number;
}

export interface PaymentTransaction {
  id: number;
  orderId: number;
  orderNumber: string;
  orderAmount: number;
  gatewayFeeAmount: number;
  totalChargedAmount: number;
  status: 'CREATED' | 'PAID' | 'FAILED' | 'REFUNDED' | 'PARTIALLY_REFUNDED';
  refundAmount: number | null;
  failureReason: string | null;
  createdAt: string;
}

@Injectable({
  providedIn: 'root'
})
export class PaymentsService {
  private walletApiUrl = `${environment.apiUrl}/wallet/shop`;
  private orderPaymentsApiUrl = `${environment.apiUrl}/order-payments/shop`;

  constructor(private http: HttpClient) {}

  getSummary(date?: string): Observable<any> {
    const params: { date?: string } = {};
    if (date) params.date = date;
    return this.http.get(`${this.walletApiUrl}/summary`, { params });
  }

  getTransactions(page: number = 0, size: number = 20): Observable<any> {
    return this.http.get(`${this.orderPaymentsApiUrl}/transactions`, { params: { page, size } });
  }

  getWalletTransactions(page: number = 0, size: number = 20): Observable<any> {
    return this.http.get(`${this.walletApiUrl}/transactions`, { params: { page, size } });
  }
}
