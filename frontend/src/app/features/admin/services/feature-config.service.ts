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
  imageUrl?: string;
  latitude?: number;
  longitude?: number;
  radiusKm?: number;
  isActive?: boolean;
  displayOrder?: number;
  maxPostsPerUser?: number;
  maxImagesPerPost?: number;
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

  createFeature(config: FeatureConfig, image?: File): Observable<any> {
    const formData = this._buildFormData(config, image);
    return this.http.post(`${this.apiUrl}/admin`, formData);
  }

  updateFeature(id: number, config: FeatureConfig, image?: File): Observable<any> {
    const formData = this._buildFormData(config, image);
    return this.http.put(`${this.apiUrl}/admin/${id}`, formData);
  }

  deleteFeature(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/admin/${id}`);
  }

  toggleActive(id: number): Observable<any> {
    return this.http.put(`${this.apiUrl}/admin/${id}/toggle`, {});
  }

  private _buildFormData(config: FeatureConfig, image?: File): FormData {
    const fd = new FormData();
    fd.append('featureName', config.featureName || '');
    fd.append('displayName', config.displayName || '');
    if (config.displayNameTamil) fd.append('displayNameTamil', config.displayNameTamil);
    if (config.icon) fd.append('icon', config.icon);
    if (config.color) fd.append('color', config.color);
    if (config.route) fd.append('route', config.route);
    if (config.latitude != null) fd.append('latitude', config.latitude.toString());
    if (config.longitude != null) fd.append('longitude', config.longitude.toString());
    if (config.radiusKm != null) fd.append('radiusKm', config.radiusKm.toString());
    if (config.displayOrder != null) fd.append('displayOrder', config.displayOrder.toString());
    if (config.maxPostsPerUser != null) fd.append('maxPostsPerUser', config.maxPostsPerUser.toString());
    if (config.maxImagesPerPost != null) fd.append('maxImagesPerPost', config.maxImagesPerPost.toString());
    if (image) fd.append('image', image);
    return fd;
  }
}
