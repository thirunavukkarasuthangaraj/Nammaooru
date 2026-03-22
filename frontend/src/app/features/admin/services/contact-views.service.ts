import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class ContactViewsService {
  private apiUrl = `${environment.apiUrl}/contact-views`;

  constructor(private http: HttpClient) {}

  getAllViews(page: number = 0, size: number = 20): Observable<any> {
    return this.http.get(this.apiUrl, {
      params: { page: page.toString(), size: size.toString() }
    });
  }

  getViewsByPost(postType: string, postId: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/post/${postType}/${postId}`);
  }

  blockUser(userId: number): Observable<any> {
    return this.http.post(`${this.apiUrl}/block/${userId}`, {});
  }
}
