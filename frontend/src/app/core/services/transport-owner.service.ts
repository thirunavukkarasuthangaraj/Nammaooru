import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../../environments/environment';

export interface TransportStop { name: string; lat: number | null; lng: number | null; }
export interface TransportRoute { id?: number; name: string; source: string; destination: string; stops: TransportStop[]; }
export interface TransportDriver { id?: number; name: string; phone: string; status?: string; }
export interface TransportVehicle {
  id?: number; vehicleType: string; regNo: string; name: string;
  routeId?: number | null; driverId?: number | null; isPublic: boolean; status?: string;
  driverName?: string | null; routeName?: string | null;
}
export interface TransportPosition {
  vehicleId: number; tripId?: number; lat: number; lng: number; speedKmh?: number; heading?: number;
  accuracyM?: number; recordedAt?: string; ageSec: number; state: 'MOVING' | 'STOPPED' | 'OFFLINE';
}
export interface OwnerBootstrap {
  transporter: any; vehicles: TransportVehicle[]; drivers: TransportDriver[]; routes: TransportRoute[];
  positions: TransportPosition[]; settings: { staleAfterSec: number };
}

export const VEHICLE_TYPES = ['BUS', 'LORRY', 'VAN', 'AUTO', 'CAR', 'BIKE', 'TRACTOR', 'OTHER'];

/** Owner-side transport API (same endpoints the mobile app uses). */
@Injectable({ providedIn: 'root' })
export class TransportOwnerService {
  private base = `${environment.apiUrl}/transport`;

  constructor(private http: HttpClient) {}

  private data<T>() { return map((r: any) => (r && r.data !== undefined ? r.data : r) as T); }

  me(): Observable<any> { return this.http.get(`${this.base}/me`, { params: { silentError: '1' } }).pipe(this.data<any>()); }

  register(companyName: string, ownerName: string, phone: string): Observable<any> {
    return this.http.post(`${this.base}/register`, { companyName, ownerName, phone });
  }

  bootstrap(): Observable<OwnerBootstrap> { return this.http.get(`${this.base}/owner/bootstrap`).pipe(this.data<OwnerBootstrap>()); }
  // silentError: background poll, never pop a toast (the layout shows a feed-health dot instead)
  live(): Observable<TransportPosition[]> { return this.http.get(`${this.base}/owner/live`, { params: { silentError: '1' } }).pipe(this.data<TransportPosition[]>()); }

  saveVehicle(v: Partial<TransportVehicle>): Observable<any> { return this.http.post(`${this.base}/owner/vehicles`, v); }
  deleteVehicle(id: number): Observable<any> { return this.http.delete(`${this.base}/owner/vehicles/${id}`); }

  saveDriver(d: Partial<TransportDriver>): Observable<any> { return this.http.post(`${this.base}/owner/drivers`, d); }
  deleteDriver(id: number): Observable<any> { return this.http.delete(`${this.base}/owner/drivers/${id}`); }

  saveRoute(r: Partial<TransportRoute>): Observable<any> { return this.http.post(`${this.base}/owner/routes`, r); }
  deleteRoute(id: number): Observable<any> { return this.http.delete(`${this.base}/owner/routes/${id}`); }

  trips(vehicleId?: number, page = 0, size = 50): Observable<any> {
    const params: any = { page, size };
    if (vehicleId) params.vehicleId = vehicleId;
    return this.http.get(`${this.base}/owner/trips`, { params }).pipe(this.data<any>());
  }
  tripTrail(tripId: number): Observable<any> { return this.http.get(`${this.base}/owner/trips/${tripId}/trail`).pipe(this.data<any>()); }

  // OTP login (website) - same endpoints as the mobile app
  sendLoginOtp(mobileNumber: string): Observable<any> {
    return this.http.post(`${environment.apiUrl}/auth/login/send-otp`, { mobileNumber });
  }
}
