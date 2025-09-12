import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent } from '@angular/common/http';
import { Observable } from 'rxjs';
import { AuthService } from '../services/auth.service';

@Injectable()
export class AuthInterceptor implements HttpInterceptor {

  constructor(private authService: AuthService) {}

  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const token = this.authService.getToken();
    
    // Add client identification headers
    let headers = request.headers
      .set('X-Client-Type', 'web')
      .set('X-Platform', 'angular');
    
    if (token && this.authService.isAuthenticated()) {
      headers = headers.set('Authorization', `Bearer ${token}`);
    }
    
    const modifiedRequest = request.clone({ headers });
    return next.handle(modifiedRequest);
  }
}