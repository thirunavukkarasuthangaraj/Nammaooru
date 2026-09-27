import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class SignupBonusService {
  private apiUrl = `${environment.apiUrl}/admin/signup-bonuses`;

  constructor(private http: HttpClient) {}

  getPending(page: number = 0, size: number = 50): Observable<any> {
    return this.http.get(this.apiUrl, { params: { page, size } });
  }

  markPaid(id: number, payoutReference: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/${id}/mark-paid`, { payoutReference });
  }

  getConfig(): Observable<any> {
    return this.http.get(`${this.apiUrl}/config`);
  }

  setEnabled(enabled: boolean): Observable<any> {
    return this.http.post(`${this.apiUrl}/enabled`, { enabled });
  }

  setAmount(amount: number): Observable<any> {
    return this.http.post(`${this.apiUrl}/amount`, { amount });
  }

  setReminderInterval(minutes: number): Observable<any> {
    return this.http.post(`${this.apiUrl}/reminder-interval`, { minutes });
  }
}
