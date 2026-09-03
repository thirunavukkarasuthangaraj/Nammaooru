import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface PaymentSummary {
  date: string;
  daySales: number;
  dayOrderCount: number;
  dayOnlineSales: number;
  dayOnlineOrderCount: number;
  dayCodSales: number;
  dayCodOrderCount: number;
  totalSales: number;
  totalOnlineSales: number;
  totalCodSales: number;
  walletBalance: number;
  totalEarned: number;
  totalWithdrawn: number;
  expectedSettlementDate: string;
}

export interface OrderPaymentRow {
  orderId: number;
  orderNumber: string;
  paymentMethod: string;
  subtotal: number;
  taxAmount: number;
  deliveryFee: number;
  totalAmount: number;
  orderStatus: string;
  paymentStatus: string;
  createdAt: string;
  isOnline: boolean;
  razorpayMdr: number;
  gstOnGatewayFee: number;
  totalGatewayFee: number;
  customerPaid: number;
  gatewayStatus: string | null;
}

@Injectable({
  providedIn: 'root'
})
export class PaymentsService {
  private walletApiUrl = `${environment.apiUrl}/wallet/shop`;

  constructor(private http: HttpClient) {}

  getSummary(date?: string): Observable<any> {
    const params: { date?: string } = {};
    if (date) params.date = date;
    return this.http.get(`${this.walletApiUrl}/summary`, { params });
  }

  getOrders(startDate?: string, endDate?: string, page: number = 0, size: number = 20): Observable<any> {
    const params: { startDate?: string; endDate?: string; page: number; size: number } = { page, size };
    if (startDate) params.startDate = startDate;
    if (endDate) params.endDate = endDate;
    return this.http.get(`${this.walletApiUrl}/orders`, { params });
  }

  // No amount sent = withdraw the full balance (backend treats a missing
  // "amount" key as "everything") - shop owners always want the full amount,
  // there's no reason to make them type it in.
  requestWithdrawal(): Observable<any> {
    return this.http.post(`${this.walletApiUrl}/withdraw`, {});
  }
}
