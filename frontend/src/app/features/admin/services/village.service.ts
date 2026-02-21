import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface Village {
  id?: number;
  name: string;
  nameTamil?: string;
  district?: string;
  panchayatName?: string;
  panchayatUrl?: string;
  description?: string;
  isActive?: boolean;
  displayOrder?: number;
  createdAt?: string;
  updatedAt?: string;
}

@Injectable({
  providedIn: 'root'
})
export class VillageService {
  private apiUrl = `${environment.apiUrl}/villages`;

  constructor(private http: HttpClient) {}

  getActiveVillages(): Observable<any> {
    return this.http.get(this.apiUrl);
  }

  getAllVillages(): Observable<any> {
    return this.http.get(`${this.apiUrl}/admin/all`);
  }

  createVillage(village: Village): Observable<any> {
    return this.http.post(`${this.apiUrl}/admin`, village);
  }

  updateVillage(id: number, village: Village): Observable<any> {
    return this.http.put(`${this.apiUrl}/admin/${id}`, village);
  }

  deleteVillage(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/admin/${id}`);
  }

  toggleActive(id: number): Observable<any> {
    return this.http.put(`${this.apiUrl}/admin/${id}/toggle`, {});
  }
}
