import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../../environments/environment';
import { ApiResponse } from '../models/api-response.model';
import { LabelTemplate } from '../models/label-template.model';

@Injectable({ providedIn: 'root' })
export class LabelTemplateService {
  private readonly API_URL = `${environment.apiUrl}/label-templates`;

  constructor(private http: HttpClient) {}

  getAll(): Observable<LabelTemplate[]> {
    return this.http.get<ApiResponse<LabelTemplate[]>>(this.API_URL)
      .pipe(map(res => res.data || []));
  }

  /** The common/default template (null if none saved yet). */
  getDefault(): Observable<LabelTemplate | null> {
    return this.http.get<ApiResponse<LabelTemplate>>(`${this.API_URL}/default`)
      .pipe(map(res => res.data || null));
  }

  getById(id: number): Observable<LabelTemplate> {
    return this.http.get<ApiResponse<LabelTemplate>>(`${this.API_URL}/${id}`)
      .pipe(map(res => res.data));
  }

  /** Upsert the single common template. */
  saveDefault(template: LabelTemplate): Observable<LabelTemplate> {
    return this.http.post<ApiResponse<LabelTemplate>>(`${this.API_URL}/default`, template)
      .pipe(map(res => res.data));
  }

  delete(id: number): Observable<void> {
    return this.http.delete<ApiResponse<void>>(`${this.API_URL}/${id}`)
      .pipe(map(() => void 0));
  }
}
