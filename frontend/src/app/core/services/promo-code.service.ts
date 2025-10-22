import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../../environments/environment';
import {
  PromoCode,
  PromoCodeUsage,
  PromoCodeValidationRequest,
  PromoCodeValidationResponse,
  PromoCodeStats,
  CreatePromoCodeRequest
} from '../models/promo-code.model';

@Injectable({
  providedIn: 'root'
})
export class PromoCodeService {
  private apiUrl = `${environment.apiUrl}/api/promotions`;

  constructor(private http: HttpClient) {}

  /**
   * Get all promo codes with optional filters
   */
  getAllPromoCodes(filters?: {
    status?: string;
    shopId?: number;
    page?: number;
    size?: number;
  }): Observable<PromoCode[]> {
    let params = new HttpParams();

    if (filters) {
      if (filters.status) params = params.set('status', filters.status);
      if (filters.shopId) params = params.set('shopId', filters.shopId.toString());
      if (filters.page !== undefined) params = params.set('page', filters.page.toString());
      if (filters.size !== undefined) params = params.set('size', filters.size.toString());
    }

    return this.http.get<any>(this.apiUrl, { params }).pipe(
      map(response => response.data || response)
    );
  }

  /**
   * Get a single promo code by ID
   */
  getPromoCodeById(id: number): Observable<PromoCode> {
    return this.http.get<any>(`${this.apiUrl}/${id}`).pipe(
      map(response => response.data || response)
    );
  }

  /**
   * Get active promo codes
   */
  getActivePromoCodes(shopId?: number): Observable<PromoCode[]> {
    let params = new HttpParams();
    if (shopId) params = params.set('shopId', shopId.toString());

    return this.http.get<any>(`${this.apiUrl}/active`, { params }).pipe(
      map(response => response.data || response)
    );
  }

  /**
   * Create a new promo code
   */
  createPromoCode(promoCode: CreatePromoCodeRequest): Observable<PromoCode> {
    return this.http.post<any>(this.apiUrl, promoCode).pipe(
      map(response => response.data || response)
    );
  }

  /**
   * Update an existing promo code
   */
  updatePromoCode(id: number, promoCode: Partial<CreatePromoCodeRequest>): Observable<PromoCode> {
    return this.http.put<any>(`${this.apiUrl}/${id}`, promoCode).pipe(
      map(response => response.data || response)
    );
  }

  /**
   * Delete a promo code
   */
  deletePromoCode(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  /**
   * Validate a promo code
   */
  validatePromoCode(request: PromoCodeValidationRequest): Observable<PromoCodeValidationResponse> {
    return this.http.post<PromoCodeValidationResponse>(`${this.apiUrl}/validate`, request);
  }

  /**
   * Get promo code usage statistics
   */
  getPromoCodeStats(id: number): Observable<PromoCodeStats> {
    return this.http.get<any>(`${this.apiUrl}/${id}/stats`).pipe(
      map(response => response.data || response)
    );
  }

  /**
   * Get usage history for a promo code
   */
  getPromoCodeUsageHistory(id: number, page: number = 0, size: number = 20): Observable<{
    content: PromoCodeUsage[];
    totalElements: number;
    totalPages: number;
  }> {
    const params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http.get<any>(`${this.apiUrl}/${id}/usage`, { params }).pipe(
      map(response => response.data || response)
    );
  }

  /**
   * Get customer's promo code usage history
   */
  getCustomerUsageHistory(customerId: number): Observable<PromoCodeUsage[]> {
    return this.http.get<any>(`${this.apiUrl}/my-usage?customerId=${customerId}`).pipe(
      map(response => response.data || response)
    );
  }

  /**
   * Activate a promo code
   */
  activatePromoCode(id: number): Observable<PromoCode> {
    return this.http.patch<any>(`${this.apiUrl}/${id}/activate`, {}).pipe(
      map(response => response.data || response)
    );
  }

  /**
   * Deactivate a promo code
   */
  deactivatePromoCode(id: number): Observable<PromoCode> {
    return this.http.patch<any>(`${this.apiUrl}/${id}/deactivate`, {}).pipe(
      map(response => response.data || response)
    );
  }

  /**
   * Get formatted discount text
   */
  getFormattedDiscount(promo: PromoCode): string {
    switch (promo.type) {
      case 'PERCENTAGE':
        return `${promo.discountValue}% OFF`;
      case 'FIXED_AMOUNT':
        return `₹${promo.discountValue} OFF`;
      case 'FREE_SHIPPING':
        return 'FREE DELIVERY';
      default:
        return 'SPECIAL OFFER';
    }
  }

  /**
   * Get formatted minimum order text
   */
  getFormattedMinOrder(promo: PromoCode): string {
    if (promo.minimumOrderAmount && promo.minimumOrderAmount > 0) {
      return `Min order: ₹${promo.minimumOrderAmount}`;
    }
    return 'No minimum order';
  }

  /**
   * Check if promo code is expired
   */
  isExpired(promo: PromoCode): boolean {
    return new Date(promo.endDate) < new Date();
  }

  /**
   * Get promo code status badge color
   */
  getStatusBadgeColor(status: string): string {
    switch (status) {
      case 'ACTIVE':
        return 'success';
      case 'INACTIVE':
        return 'warning';
      case 'EXPIRED':
        return 'danger';
      default:
        return 'secondary';
    }
  }
}
