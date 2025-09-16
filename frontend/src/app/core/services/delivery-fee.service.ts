import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface DeliveryFeeRange {
  id?: number;
  minDistanceKm: number;
  maxDistanceKm: number;
  deliveryFee: number;
  partnerCommission: number;
  isActive: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface DeliveryFeeCalculation {
  success: boolean;
  distance: number;
  deliveryFee: number;
  partnerCommission: number;
}

@Injectable({
  providedIn: 'root'
})
export class DeliveryFeeService {
  private apiUrl = `${environment.apiUrl}/delivery-fees`;
  private superAdminApiUrl = `${environment.apiUrl}/super-admin/delivery-fees`;

  constructor(private http: HttpClient) {}

  getAllRanges(): Observable<any> {
    return this.http.get(`${this.superAdminApiUrl}`);
  }

  getActiveRanges(): Observable<any> {
    return this.http.get(`${this.apiUrl}/active`);
  }

  createRange(range: DeliveryFeeRange): Observable<any> {
    return this.http.post(`${this.superAdminApiUrl}`, range);
  }

  updateRange(id: number, range: DeliveryFeeRange): Observable<any> {
    return this.http.put(`${this.superAdminApiUrl}/${id}`, range);
  }

  deleteRange(id: number): Observable<any> {
    return this.http.delete(`${this.superAdminApiUrl}/${id}`);
  }

  getRangeById(id: number): Observable<any> {
    return this.http.get(`${this.superAdminApiUrl}/${id}`);
  }

  toggleRangeStatus(id: number): Observable<any> {
    return this.http.patch(`${this.superAdminApiUrl}/${id}/toggle-status`, {});
  }

  calculateFee(coordinates: {
    shopLat: number;
    shopLon: number;
    customerLat: number;
    customerLon: number;
  }): Observable<DeliveryFeeCalculation> {
    return this.http.post<DeliveryFeeCalculation>(`${this.apiUrl}/calculate`, coordinates);
  }
}