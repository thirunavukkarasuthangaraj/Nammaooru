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
  private readonly API_URL = API_ENDPOINTS.BASE_URL + '/api/settings';

  constructor(private http: HttpClient) {}

  getAllSettings(): Observable<Setting[]> {
    return this.http.get<ApiResponse<Setting[]>>(this.API_URL).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return apiResponse.data || [];
      }),
      catchError(error => {
        console.error('Error fetching settings:', error);
        return throwError(() => error);
      })
    );
  }

  updateSetting(key: string, value: string): Observable<Setting> {
    return this.http.put<ApiResponse<Setting>>(`${this.API_URL}/${key}`, { value }).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return apiResponse.data;
      }),
      catchError(error => {
        console.error('Error updating setting:', error);
        return throwError(() => error);
      })
    );
  }

  updateMultipleSettings(settings: { [key: string]: string }): Observable<Setting[]> {
    return this.http.put<ApiResponse<Setting[]>>(`${this.API_URL}/bulk`, settings).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return apiResponse.data || [];
      }),
      catchError(error => {
        console.error('Error updating multiple settings:', error);
        return throwError(() => error);
      })
    );
  }

  resetToDefaults(): Observable<Setting[]> {
    return this.http.post<ApiResponse<Setting[]>>(`${this.API_URL}/reset`, {}).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return apiResponse.data || [];
      }),
      catchError(error => {
        console.error('Error resetting settings:', error);
        return throwError(() => error);
      })
    );
  }

  getSettingsByCategory(category: string): Observable<Setting[]> {
    return this.http.get<ApiResponse<Setting[]>>(`${this.API_URL}/category/${category}`).pipe(
      map(apiResponse => {
        if (ApiResponseHelper.isError(apiResponse)) {
          throw new Error(ApiResponseHelper.getErrorMessage(apiResponse));
        }
        return apiResponse.data || [];
      }),
      catchError(error => {
        console.error('Error fetching settings by category:', error);
        return throwError(() => error);
      })
    );
  }
}