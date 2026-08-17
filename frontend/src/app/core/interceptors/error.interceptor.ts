import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { SwalService } from '../services/swal.service';

@Injectable()
export class ErrorInterceptor implements HttpInterceptor {

  constructor(
    private swal: SwalService,
    private authService: AuthService,
    private router: Router
  ) {}

  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    return next.handle(request).pipe(
      catchError((error: HttpErrorResponse) => {
        // Ignore aborted requests (user navigated away, closed browser, etc.)
        if (error.status === 0 && error.statusText === 'Unknown Error') {
          // Check if it's a user-initiated abort
          if (error.message?.includes('abort') || error.message?.includes('cancel') ||
              error.message?.includes('interrupt') || error.message?.includes('Interrupted')) {
            console.log('Request aborted by user');
            return throwError(() => error);
          }
        }

        let errorMessage = 'An unexpected error occurred';

        if (error.error?.message && typeof error.error.message === 'string') {
          errorMessage = error.error.message;
        } else if (error.error?.validationErrors) {
          const validationErrors = Object.values(error.error.validationErrors).join(', ');
          errorMessage = `Validation errors: ${validationErrors}`;
        } else if (error.message && typeof error.message === 'string') {
          // Don't show technical browser error messages to user
          if (!error.message.includes('Http failure') && !error.message.includes('Unknown Error')) {
            errorMessage = error.message;
          }
        }

        // Check for specific token error codes
        const statusCode = error.error?.statusCode;

        switch (error.status) {
          case 401:
            // Handle specific token errors
            if (statusCode === 'TOKEN_EXPIRED') {
              errorMessage = '⏰ Session Expired! Please login again.';
            } else if (statusCode === 'TOKEN_INVALIDATED') {
              errorMessage = '🔒 Session logged out. Please login again.';
            } else if (statusCode === 'TOKEN_MALFORMED' || statusCode === 'TOKEN_INVALID') {
              errorMessage = '❌ Invalid session. Please login again.';
            } else if (statusCode === 'TOKEN_INVALID_SIGNATURE') {
              errorMessage = '🔐 Security error. Please login again.';
            } else {
              errorMessage = error.error?.message || 'Session expired. Please login again.';
            }
            this.authService.logout();
            break;
          case 403:
            errorMessage = error.error?.message || 'You don\'t have permission to access this resource';
            break;
          case 404:
            errorMessage = 'Resource not found';
            break;
          case 402:
            errorMessage = 'Payment required to continue using the app';
            if (!this.router.url.startsWith('/pay-and-use')) {
              this.router.navigate(['/pay-and-use']);
            }
            break;
          case 500:
            errorMessage = 'Server error. Please try again later';
            break;
          case 0:
            errorMessage = 'Network error. Please check your connection';
            break;
        }

        // Don't show toast for auth endpoints or customer endpoints to avoid duplicate messages
        if (!request.url.includes('/auth/') && !request.url.includes('/customer/')) {
          this.swal.toast(errorMessage, 'error');
        }

        // Preserve the error message for downstream handlers
        const errorToThrow = new Error(errorMessage);
        (errorToThrow as any).originalError = error;
        (errorToThrow as any).status = error.status;
        return throwError(() => errorToThrow);
      })
    );
  }
}