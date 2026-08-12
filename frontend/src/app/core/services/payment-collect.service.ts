import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map, catchError, throwError } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ApiResponse, ApiResponseHelper } from '../models/api-response.model';

export interface ShopPaymentRow {
  shopId: number;
  shopName: string;
  ownerName: string;
  ownerPhone: string;
  amount: number;
  currency: string;
  paymentBlocked: boolean;
  validUntil: string | null;
}

export interface ShopPaymentStatus {
  shopId: number;
  shopName: string;
  amount: number;
  currency: string;
  durationDays: number;
  paid: boolean;
  paymentRequired: boolean;
  validUntil: string | null;
  keyId: string;
  testMode: boolean;
}

export interface PaymentOrder {
  orderId: string;
  amount: number;
  currency: string;
  keyId: string;
  testMode: boolean;
}

export interface PagedResult<T> {
  content: T[];
  currentPage: number;
  totalItems: number;
  totalPages: number;
  pageSize: number;
}

let razorpayScriptPromise: Promise<boolean> | null = null;

@Injectable({
  providedIn: 'root'
})
export class PaymentCollectService {
  private superAdminUrl = `${environment.apiUrl}/super-admin/payment-collect`;
  private shopOwnerUrl = `${environment.apiUrl}/shop-owner-payments`;

  constructor(private http: HttpClient) {}

  private unwrap<T>(response: ApiResponse<T>): T {
    if (ApiResponseHelper.isError(response)) {
      throw new Error(ApiResponseHelper.getErrorMessage(response));
    }
    return response.data;
  }

  // ---- Superadmin ----

  listShops(page = 0, size = 50): Observable<PagedResult<ShopPaymentRow>> {
    return this.http.get<ApiResponse<PagedResult<ShopPaymentRow>>>(this.superAdminUrl, { params: { page, size } as any }).pipe(
      map(response => this.unwrap(response)),
      catchError(error => throwError(() => error))
    );
  }

  setPrice(shopId: number, amount: number): Observable<void> {
    return this.http.put<ApiResponse<void>>(`${this.superAdminUrl}/${shopId}`, { amount }).pipe(
      map(response => this.unwrap(response)),
      catchError(error => throwError(() => error))
    );
  }

  getDuration(): Observable<number> {
    return this.http.get<ApiResponse<{ durationDays: number }>>(`${this.superAdminUrl}/duration`).pipe(
      map(response => this.unwrap(response).durationDays),
      catchError(error => throwError(() => error))
    );
  }

  setDuration(durationDays: number): Observable<void> {
    return this.http.put<ApiResponse<void>>(`${this.superAdminUrl}/duration`, { durationDays }).pipe(
      map(response => this.unwrap(response)),
      catchError(error => throwError(() => error))
    );
  }

  // ---- Shop owner ----

  getStatus(): Observable<ShopPaymentStatus> {
    return this.http.get<ApiResponse<ShopPaymentStatus>>(`${this.shopOwnerUrl}/status`).pipe(
      map(response => this.unwrap(response)),
      catchError(error => throwError(() => error))
    );
  }

  createOrder(): Observable<PaymentOrder> {
    return this.http.post<ApiResponse<PaymentOrder>>(`${this.shopOwnerUrl}/create-order`, {}).pipe(
      map(response => this.unwrap(response)),
      catchError(error => throwError(() => error))
    );
  }

  verifyPayment(payload: { razorpay_order_id: string; razorpay_payment_id: string; razorpay_signature: string }): Observable<any> {
    return this.http.post<ApiResponse<any>>(`${this.shopOwnerUrl}/verify`, payload).pipe(
      map(response => this.unwrap(response)),
      catchError(error => throwError(() => error))
    );
  }

  // ---- Razorpay Checkout.js loader ----

  loadRazorpayScript(): Promise<boolean> {
    if ((window as any).Razorpay) {
      return Promise.resolve(true);
    }
    if (razorpayScriptPromise) {
      return razorpayScriptPromise;
    }
    razorpayScriptPromise = new Promise(resolve => {
      const script = document.createElement('script');
      script.src = 'https://checkout.razorpay.com/v1/checkout.js';
      script.onload = () => resolve(true);
      script.onerror = () => {
        razorpayScriptPromise = null;
        resolve(false);
      };
      document.body.appendChild(script);
    });
    return razorpayScriptPromise;
  }
}
