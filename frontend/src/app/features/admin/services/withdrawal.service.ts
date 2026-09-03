import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class WithdrawalService {
  private apiUrl = `${environment.apiUrl}/wallet/admin`;

  constructor(private http: HttpClient) {}

  getPendingWithdrawals(page: number = 0, size: number = 20): Observable<any> {
    return this.http.get(`${this.apiUrl}/withdrawals/pending`, { params: { page, size } });
  }

  markPaid(id: number, payoutReference: string): Observable<any> {
    return this.http.put(`${this.apiUrl}/withdrawals/${id}/mark-paid`, { payoutReference });
  }

  reject(id: number, reason: string): Observable<any> {
    return this.http.put(`${this.apiUrl}/withdrawals/${id}/reject`, { reason });
  }
}
