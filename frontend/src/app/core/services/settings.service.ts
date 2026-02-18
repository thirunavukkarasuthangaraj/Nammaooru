import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { throwError } from 'rxjs';
import { ApiResponse, ApiResponseHelper } from '../models/api-response.model';
import { API_ENDPOINTS } from '../constants/app.constants';

export interface Setting {
  id: number;
  key: string;
  value: string;
  description: string;
  scope: string;
  category: string;
}

@Injectable({
  providedIn: 'root'
})
export class SettingsService {
  private readonly API_URL = API_ENDPOINTS.BASE_URL + '/settings';

  constructor(private http: HttpClient) {}

  /** Map backend SettingResponse (settingKey/settingValue) to frontend Setting (key/value) */
  private mapSetting(raw: any): Setting {
    return {
      id: raw.id,
      key: raw.settingKey || raw.key,
      value: raw.settingValue || raw.value,
      description: raw.description || '',
      scope: raw.scope || raw.scopeLabel || '',
      category: raw.category || raw.categoryLabel || ''
    };
  }

  getAllSettings(): Observable<Setting[]> {
    return this.http.get<ApiResponse<any[]>>(`${this.API_URL}/all`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return (apiResponse.data || []).map(s => this.mapSetting(s));
      }),
      catchError(error => {
        console.error('Error fetching settings:', error);
        return throwError(() => error);
      })
    );
  }

  updateSetting(key: string, value: string): Observable<Setting> {
    return this.http.put<any>(`${this.API_URL}/value/${key}`, value).pipe(
      map(data => this.mapSetting(data)),
      catchError(error => {
        console.error('Error updating setting:', error);
        return throwError(() => error);
      })
    );
  }

  updateMultipleSettings(settings: { [key: string]: string }): Observable<Setting[]> {
    return this.http.put<ApiResponse<any[]>>(`${this.API_URL}/bulk`, settings).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return (apiResponse.data || []).map(s => this.mapSetting(s));
      }),
      catchError(error => {
        console.error('Error updating multiple settings:', error);
        return throwError(() => error);
      })
    );
  }

  resetToDefaults(): Observable<Setting[]> {
    return this.http.post<ApiResponse<any[]>>(`${this.API_URL}/reset`, {}).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return (apiResponse.data || []).map(s => this.mapSetting(s));
      }),
      catchError(error => {
        console.error('Error resetting settings:', error);
        return throwError(() => error);
      })
    );
  }

  getSettingsByCategory(category: string): Observable<Setting[]> {
    return this.http.get<any>(`${this.API_URL}/category/${category}`).pipe(
      map(response => {
        const data = response?.content || response?.data || response || [];
        return (Array.isArray(data) ? data : []).map((s: any) => this.mapSetting(s));
      }),
      catchError(error => {
        console.error('Error fetching settings by category:', error);
        return throwError(() => error);
      })
    );
  }
}
