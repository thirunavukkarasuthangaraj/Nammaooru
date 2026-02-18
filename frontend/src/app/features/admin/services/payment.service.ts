import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

@Injectable({ providedIn: 'root' })
export class PaymentService {
  private apiUrl = `${environment.apiUrl}/post-payments`;

  constructor(private http: HttpClient) {}

  getStats(): Observable<any> {
    return this.http.get(`${this.apiUrl}/admin/stats`);
  }

  getAllPayments(page = 0, size = 20): Observable<any> {
    return this.http.get(`${this.apiUrl}/admin/all`, {
      params: { page: page.toString(), size: size.toString() }
    });
  }
}
