import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface TransporterRow {
  id: number;
  userId: number;
  companyName: string;
  ownerName: string;
  phone: string;
  status: 'PENDING' | 'ACTIVE' | 'BLOCKED';
  createdAt: string;
  vehicleCount: number;
}

@Injectable({ providedIn: 'root' })
export class TransportAdminService {
  private adminUrl = `${environment.apiUrl}/transport/admin`;
  private publicUrl = `${environment.apiUrl}/transport/public`;

  constructor(private http: HttpClient) {}

  listTransporters(status: string, page = 0, size = 50): Observable<any> {
    const params: any = { page, size };
    if (status) params.status = status;
    return this.http.get(`${this.adminUrl}/transporters`, { params });
  }

  createTransporter(phone: string, companyName: string, ownerName: string): Observable<any> {
    return this.http.post(`${this.adminUrl}/transporters`, { phone, companyName, ownerName });
  }

  setStatus(id: number, status: string): Observable<any> {
    return this.http.put(`${this.adminUrl}/transporters/${id}/status`, { status });
  }

  publicBuses(): Observable<any> {
    return this.http.get(`${this.publicUrl}/buses`);
  }
}
