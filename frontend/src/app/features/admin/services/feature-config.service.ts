import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface FeatureConfig {
  id?: number;
  featureName: string;
  displayName: string;
  displayNameTamil?: string;
  icon?: string;
  color?: string;
  route?: string;
  latitude?: number;
  longitude?: number;
  radiusKm?: number;
  isActive?: boolean;
  displayOrder?: number;
  maxPostsPerUser?: number;
  createdAt?: string;
  updatedAt?: string;
}

@Injectable({
  providedIn: 'root'
})
export class FeatureConfigService {
  private apiUrl = `${environment.apiUrl}/feature-config`;

  constructor(private http: HttpClient) {}

  getAllFeatures(): Observable<any> {
    return this.http.get(`${this.apiUrl}/admin/all`);
  }

  getVisibleFeatures(lat: number, lng: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/visible`, {
      params: { lat: lat.toString(), lng: lng.toString() }
    });
  }

  createFeature(config: FeatureConfig): Observable<any> {
    return this.http.post(`${this.apiUrl}/admin`, config);
  }

  updateFeature(id: number, config: FeatureConfig): Observable<any> {
    return this.http.put(`${this.apiUrl}/admin/${id}`, config);
  }

  deleteFeature(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/admin/${id}`);
  }

  toggleActive(id: number): Observable<any> {
    return this.http.put(`${this.apiUrl}/admin/${id}/toggle`, {});
  }
}
