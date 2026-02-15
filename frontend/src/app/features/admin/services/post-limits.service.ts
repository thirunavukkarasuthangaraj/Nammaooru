import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface UserPostLimit {
  id?: number;
  userId: number;
  featureName: string;
  maxPosts: number;
  createdAt?: string;
  updatedAt?: string;
}

@Injectable({
  providedIn: 'root'
})
export class PostLimitsService {
  private apiUrl = `${environment.apiUrl}/admin/post-limits`;

  constructor(private http: HttpClient) {}

  getAllLimits(): Observable<any> {
    return this.http.get(this.apiUrl);
  }

  getLimitsByUser(userId: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/user/${userId}`);
  }

  createOrUpdate(limit: UserPostLimit): Observable<any> {
    return this.http.post(this.apiUrl, limit);
  }

  deleteLimit(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }
}
