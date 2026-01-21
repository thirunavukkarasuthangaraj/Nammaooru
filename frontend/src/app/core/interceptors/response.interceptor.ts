import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpResponse, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { ApiResponse, ApiResponseHelper } from '../models/api-response.model';
import { API_ERROR_MESSAGES, API_STATUS_CODES } from '../constants/app.constants';

@Injectable()
export class ResponseInterceptor implements HttpInterceptor {

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<any> {
    return next.handle(req).pipe(
      map(event => {
        if (event instanceof HttpResponse) {
          const body = event.body;
          
          // Check if response has our API response structure
          if (body && typeof body === 'object' && 'statusCode' in body) {
            const apiResponse = body as ApiResponse<any>;
            
            // If the API response indicates failure, throw an error
            if (ApiResponseHelper.isError(apiResponse)) {
              const errorMessage = this.getErrorMessage(apiResponse.statusCode, apiResponse.message);
              throw new Error(errorMessage);
            }
          }
        }
        return event;
      }),
      catchError((error: HttpErrorResponse) => {
        let errorMessage = 'An unexpected error occurred';

        if (error.error && typeof error.error === 'object') {
          const errorBody = error.error;
          
          // Check if error body has our API response structure
          if ('statusCode' in errorBody) {
            errorMessage = this.getErrorMessage(errorBody.statusCode, errorBody.message);
          } else if ('message' in errorBody) {
            errorMessage = errorBody.message;
          }
        } else if (error.message) {
          errorMessage = error.message;
        }

        // Handle HTTP status codes
        switch (error.status) {
          case 0:
            errorMessage = 'Network error. Please check your connection.';
            break;
          case 401:
            errorMessage = 'Session expired. Please login again.';
            break;
          case 403:
            errorMessage = 'You do not have permission to perform this action.';
            break;
          case 404:
            errorMessage = 'Resource not found.';
            break;
          case 500:
            errorMessage = errorMessage || 'Server error. Please try again later.';
            break;
        }

        return throwError(() => new Error(errorMessage));
      })
    );
  }

  private getErrorMessage(statusCode: string, message?: string): string {
    // For general errors (9999), prefer the specific backend message if provided
    // This handles specific errors like "SKU already exists", auth errors, etc.
    if (statusCode === '9999' && message && message.trim() !== '') {
      // Only transform "Bad credentials" to a user-friendly message
      return message === 'Bad credentials' ? 'Invalid email or password' : message;
    }

    // First try to get message from our error codes mapping
    if (API_ERROR_MESSAGES[statusCode]) {
      return API_ERROR_MESSAGES[statusCode];
    }

    // Fallback to provided message or generic error
    return message || 'An error occurred';
  }
}