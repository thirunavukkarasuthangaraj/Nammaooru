import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface BusTiming {
  id?: number;
  busNumber: string;
  busName: string;
  routeFrom: string;
  routeTo: string;
  viaStops: string;
  departureTime: string;
  arrivalTime: string;
  busType: 'GOVERNMENT' | 'PRIVATE';
  operatingDays: string;
  fare: number;
  locationArea: string;
  isActive: boolean;
  createdAt?: string;
  updatedAt?: string;
}

@Injectable({
  providedIn: 'root'
})
export class BusTimingService {
  private publicUrl = `${environment.apiUrl}/bus-timings`;
  private adminUrl = `${environment.apiUrl}/admin/bus-timings`;

  constructor(private http: HttpClient) {}

  // Admin: Get all (including inactive)
  getAllBusTimings(): Observable<any> {
    return this.http.get(`${this.adminUrl}`);
  }

  // Public: Get active only
  getActiveBusTimings(location?: string, search?: string): Observable<any> {
    let params: any = {};
    if (location) params.location = location;
    if (search) params.search = search;
    return this.http.get(`${this.publicUrl}`, { params });
  }

  getBusTimingById(id: number): Observable<any> {
    return this.http.get(`${this.publicUrl}/${id}`);
  }

  // Admin operations
  createBusTiming(timing: BusTiming): Observable<any> {
    return this.http.post(`${this.adminUrl}`, timing);
  }

  updateBusTiming(id: number, timing: BusTiming): Observable<any> {
    return this.http.put(`${this.adminUrl}/${id}`, timing);
  }

  deleteBusTiming(id: number): Observable<any> {
    return this.http.delete(`${this.adminUrl}/${id}`);
  }
}
