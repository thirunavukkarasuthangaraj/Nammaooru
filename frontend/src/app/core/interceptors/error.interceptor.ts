import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { MatSnackBar } from '@angular/material/snack-bar';
import { AuthService } from '../services/auth.service';

@Injectable()
export class ErrorInterceptor implements HttpInterceptor {

  constructor(
    private snackBar: MatSnackBar,
    private authService: AuthService
  ) {}

  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    return next.handle(request).pipe(
      catchError((error: HttpErrorResponse) => {
        let errorMessage = 'An unexpected error occurred';
        
        if (error.error?.message) {
          errorMessage = error.error.message;
        } else if (error.error?.validationErrors) {
          const validationErrors = Object.values(error.error.validationErrors).join(', ');
          errorMessage = `Validation errors: ${validationErrors}`;
        } else if (error.message) {
          errorMessage = error.message;
        }

        switch (error.status) {
          case 401:
            errorMessage = 'Invalid credentials or session expired';
            this.authService.logout();
            break;
          case 403:
            errorMessage = 'You don\'t have permission to access this resource';
            break;
          case 404:
            errorMessage = 'Resource not found';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later';
            break;
          case 0:
            errorMessage = 'Network error. Please check your connection';
            break;
        }

        // Don't show snackbar for auth endpoints or customer endpoints to avoid duplicate messages
        if (!request.url.includes('/auth/') && !request.url.includes('/customer/')) {
          // Only show error for non-customer routes
          this.snackBar.open(errorMessage, 'Close', {
            duration: 5000,
            horizontalPosition: 'end',
            verticalPosition: 'top',
            panelClass: ['error-snackbar']
          });
        }

        return throwError(() => error);
      })
    );
  }
}