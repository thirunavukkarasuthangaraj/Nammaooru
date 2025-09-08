import { Injectable } from '@angular/core';
import { Observable, throwError } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { ApiResponse, ApiResponseHelper } from '../models/api-response.model';
import { API_ERROR_MESSAGES } from '../constants/app.constants';

@Injectable({
  providedIn: 'root'
})
export class ApiResponseService {

  /**
   * Extracts data from successful API response or throws error for failed responses
   */
  static extractData<T>(source: Observable<ApiResponse<T>>): Observable<T> {
    return source.pipe(
      map(response => {
        if (ApiResponseHelper.isSuccess(response)) {
          return response.data;
        } else {
          const errorMessage = ApiResponseHelper.getErrorMessage(response);
          throw new Error(errorMessage);
        }
      }),
      catchError(error => {
        // If it's already our custom error, re-throw it
        if (error instanceof Error) {
          return throwError(() => error);
        }
        
        // Handle HTTP errors
        if (error.error && error.error.statusCode) {
          const statusCode = error.error.statusCode;
          const message = API_ERROR_MESSAGES[statusCode] || error.error.message || 'An error occurred';
          return throwError(() => new Error(message));
        }
        
        // Handle network errors
        if (error.status === 0) {
          return throwError(() => new Error('Network error. Please check your connection.'));
        }
        
        // Generic error handling
        return throwError(() => new Error(error.message || 'An unexpected error occurred'));
      })
    );
  }

  /**
   * Extract data with custom error message
   */
  static extractDataWithErrorMessage<T>(source: Observable<ApiResponse<T>>, customErrorMessage: string): Observable<T> {
    return source.pipe(
      map(response => {
        if (ApiResponseHelper.isSuccess(response)) {
          return response.data;
        } else {
          throw new Error(customErrorMessage);
        }
      }),
      catchError(error => {
        if (error instanceof Error) {
          return throwError(() => error);
        }
        return throwError(() => new Error(customErrorMessage));
      })
    );
  }

  /**
   * Check if response is successful without extracting data
   */
  static validateResponse<T>(source: Observable<ApiResponse<T>>): Observable<ApiResponse<T>> {
    return source.pipe(
      map(response => {
        if (ApiResponseHelper.isError(response)) {
          const errorMessage = ApiResponseHelper.getErrorMessage(response);
          throw new Error(errorMessage);
        }
        return response;
      }),
      catchError(error => {
        if (error instanceof Error) {
          return throwError(() => error);
        }
        
        if (error.error && error.error.statusCode) {
          const statusCode = error.error.statusCode;
          const message = API_ERROR_MESSAGES[statusCode] || error.error.message || 'An error occurred';
          return throwError(() => new Error(message));
        }
        
        return throwError(() => new Error(error.message || 'An unexpected error occurred'));
      })
    );
  }
}