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
  private apiUrl = `${environment.apiUrl}/bus-timings`;

  constructor(private http: HttpClient) {}

  getAllBusTimings(): Observable<any> {
    return this.http.get(`${this.apiUrl}/all`);
  }

  getActiveBusTimings(location?: string, search?: string): Observable<any> {
    let params: any = {};
    if (location) params.location = location;
    if (search) params.search = search;
    return this.http.get(`${this.apiUrl}`, { params });
  }

  getBusTimingById(id: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/${id}`);
  }

  createBusTiming(timing: BusTiming): Observable<any> {
    return this.http.post(`${this.apiUrl}`, timing);
  }

  updateBusTiming(id: number, timing: BusTiming): Observable<any> {
    return this.http.put(`${this.apiUrl}/${id}`, timing);
  }

  deleteBusTiming(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }
}
