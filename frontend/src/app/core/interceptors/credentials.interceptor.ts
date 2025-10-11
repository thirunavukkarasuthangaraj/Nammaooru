import { Injectable } from '@angular/core';
import {
  HttpRequest,
  HttpHandler,
  HttpEvent,
  HttpInterceptor
} from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

/**
 * HTTP Interceptor that automatically adds withCredentials: true to all API requests
 * This is required for CORS to work properly with cookies and authentication tokens
 */
@Injectable()
export class CredentialsInterceptor implements HttpInterceptor {

  intercept(request: HttpRequest<unknown>, next: HttpHandler): Observable<HttpEvent<unknown>> {
    // Only add withCredentials for requests to our API
    if (request.url.startsWith(environment.apiUrl)) {
      const modifiedRequest = request.clone({
        withCredentials: true
      });
      return next.handle(modifiedRequest);
    }

    // For other requests (external APIs, CDN, etc.), pass through unchanged
    return next.handle(request);
  }
}
