import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class JobAdminService {
  private apiUrl = `${environment.apiUrl}/admin/jobs`;

  constructor(private http: HttpClient) {}

  getAllPosts(page: number = 0, size: number = 20, status?: string): Observable<any> {
    let params: any = { page: page.toString(), size: size.toString() };
    if (status) params.status = status;
    return this.http.get(this.apiUrl, { params });
  }

  getPendingPosts(page: number = 0, size: number = 20): Observable<any> {
    return this.getAllPosts(page, size, 'PENDING_APPROVAL');
  }

  getReportedPosts(page: number = 0, size: number = 20): Observable<any> {
    return this.http.get(`${this.apiUrl}/reported`, {
      params: { page: page.toString(), size: size.toString() }
    });
  }

  getStats(): Observable<any> {
    return this.http.get(`${this.apiUrl}/stats`);
  }

  approvePost(id: number): Observable<any> {
    return this.http.post(`${this.apiUrl}/${id}/approve`, {});
  }

  rejectPost(id: number, reason: string = ''): Observable<any> {
    return this.http.post(`${this.apiUrl}/${id}/reject`, { reason });
  }

  deletePost(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }
}
