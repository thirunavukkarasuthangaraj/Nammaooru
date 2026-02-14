import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class FarmerProductsAdminService {
  private apiUrl = `${environment.apiUrl}/farmer-products`;

  constructor(private http: HttpClient) {}

  getPendingPosts(page: number = 0, size: number = 20): Observable<any> {
    return this.http.get(`${this.apiUrl}/pending`, {
      params: { page: page.toString(), size: size.toString() }
    });
  }

  getAllPosts(page: number = 0, size: number = 20): Observable<any> {
    return this.http.get(`${this.apiUrl}/admin/all`, {
      params: { page: page.toString(), size: size.toString() }
    });
  }

  getReportedPosts(page: number = 0, size: number = 20): Observable<any> {
    return this.http.get(`${this.apiUrl}/admin/reported`, {
      params: { page: page.toString(), size: size.toString() }
    });
  }

  approvePost(id: number): Observable<any> {
    return this.http.put(`${this.apiUrl}/${id}/approve`, {});
  }

  rejectPost(id: number): Observable<any> {
    return this.http.put(`${this.apiUrl}/${id}/reject`, {});
  }

  deletePost(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }

  changePostStatus(id: number, status: string): Observable<any> {
    return this.http.put(`${this.apiUrl}/${id}/status`, { status });
  }
}
