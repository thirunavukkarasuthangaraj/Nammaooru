import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../../environments/environment';

export interface TransportStop { name: string; lat: number | null; lng: number | null; }
export interface TransportRoute {
  id?: number; name: string; source: string; destination: string; stops: TransportStop[];
  sourceLat?: number | null; sourceLng?: number | null; destLat?: number | null; destLng?: number | null;
}

// Dark, high-contrast colours so route lines stand out on the map
const ROUTE_COLORS = ['#b71c1c', '#0d47a1', '#1b5e20', '#e65100', '#4a148c', '#006064', '#3e2723', '#827717'];
export function routeColor(routeId: number | null | undefined): string { const id = routeId == null ? 0 : Math.abs(+routeId); return ROUTE_COLORS[id % ROUTE_COLORS.length]; }

/** From -> stops -> To as map points (only the ones that have coordinates). */
export function routePath(r?: TransportRoute | null): { lat: number; lng: number; label: string; kind: 'from' | 'stop' | 'to' }[] {
  if (!r) return [];
  const out: { lat: number; lng: number; label: string; kind: 'from' | 'stop' | 'to' }[] = [];
  if (r.sourceLat != null && r.sourceLng != null) out.push({ lat: +r.sourceLat, lng: +r.sourceLng, label: r.source, kind: 'from' });
  (r.stops || []).forEach(st => { if (st.lat != null && st.lng != null) out.push({ lat: +st.lat, lng: +st.lng, label: st.name, kind: 'stop' }); });
  if (r.destLat != null && r.destLng != null) out.push({ lat: +r.destLat, lng: +r.destLng, label: r.destination, kind: 'to' });
  return out;
}
export interface TransportDriver { id?: number; name: string; phone: string; status?: string; }
export interface TransportVehicle {
  id?: number; vehicleType: string; regNo: string; name: string;
  routeId?: number | null; driverId?: number | null; isPublic: boolean; status?: string;
  driverName?: string | null; routeName?: string | null;
}
export interface TransportSchedule {
  id?: number; vehicleId: number; routeId?: number | null; direction: 'AB' | 'BA';
  departTime: string; arriveTime: string; days: string; isActive?: boolean;
}
export interface TransportPosition {
  vehicleId: number; tripId?: number; lat: number; lng: number; speedKmh?: number; heading?: number;
  accuracyM?: number; recordedAt?: string; ageSec: number; state: 'MOVING' | 'STOPPED' | 'OFFLINE'; direction?: 'AB' | 'BA';
}
export interface OwnerBootstrap {
  transporter: any; vehicles: TransportVehicle[]; drivers: TransportDriver[]; routes: TransportRoute[];
  schedules: TransportSchedule[]; positions: TransportPosition[]; settings: { staleAfterSec: number };
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

  saveSchedule(sc: Partial<TransportSchedule>): Observable<any> { return this.http.post(`${this.base}/owner/schedules`, sc); }
  deleteSchedule(id: number): Observable<any> { return this.http.delete(`${this.base}/owner/schedules/${id}`); }

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
