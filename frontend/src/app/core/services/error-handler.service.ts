import { Injectable } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { ApiResponse, ApiResponseHelper, ResponseConstants, ResponseStatusCode } from '../models/api-response.model';
import Swal from 'sweetalert2';

@Injectable({
  providedIn: 'root'
})
export class ErrorHandlerService {

  constructor() { }

  /**
   * Handle HTTP errors and API response errors
   */
  handleError(error: HttpErrorResponse | ApiResponse<any> | any): Observable<never> {
    let errorMessage = 'An unexpected error occurred';
    let errorTitle = 'Error';
    let statusCode: ResponseStatusCode = ResponseConstants.GENERAL_ERROR;

    // Check if it's an API response error
    if (error && typeof error === 'object' && 'statusCode' in error) {
      const apiResponse = error as ApiResponse<any>;
      
      if (ApiResponseHelper.isError(apiResponse)) {
        statusCode = apiResponse.statusCode as ResponseStatusCode;
        errorMessage = ApiResponseHelper.getErrorMessage(apiResponse);
        errorTitle = this.getErrorTitle(apiResponse.statusCode);
      }
    }
    // Check if it's an HTTP error
    else if (error instanceof HttpErrorResponse) {
      statusCode = this.mapHttpStatusToResponseCode(error.status);
      errorMessage = this.getHttpErrorMessage(error);
      errorTitle = this.getErrorTitle(statusCode);
    }
    // Generic error
    else if (error?.message) {
      errorMessage = error.message;
    }

    // Log the error
    console.error('Error occurred:', {
      statusCode,
      message: errorMessage,
      originalError: error
    });

    // Show user-friendly error message
    this.showErrorAlert(errorTitle, errorMessage, statusCode);

    return throwError(() => ({
      statusCode,
      message: errorMessage,
      originalError: error
    }));
  }

  /**
   * Handle API response and extract data or throw error
   */
  handleApiResponse<T>(apiResponse: ApiResponse<T>): T {
    if (ApiResponseHelper.isError(apiResponse)) {
      throw apiResponse;
    }
    return apiResponse.data;
  }

  /**
   * Show error alert to user
   */
  private showErrorAlert(title: string, message: string, statusCode: string): void {
    // Don't show alert for authentication errors (handled by auth interceptor)
    if (this.isAuthError(statusCode)) {
      return;
    }

    let icon: 'error' | 'warning' | 'info' = 'error';
    
    if (this.isValidationError(statusCode)) {
      icon = 'warning';
    } else if (this.isBusinessError(statusCode)) {
      icon = 'info';
    }

    Swal.fire({
      icon,
      title,
      text: message,
      confirmButtonText: 'OK',
      confirmButtonColor: '#3085d6'
    });
  }

  /**
   * Get error title based on status code
   */
  private getErrorTitle(statusCode: string): string {
    if (this.isAuthError(statusCode)) {
      return 'Authentication Error';
    } else if (this.isValidationError(statusCode)) {
      return 'Validation Error';
    } else if (this.isBusinessError(statusCode)) {
      return 'Business Rule Violation';
    } else if (this.isFileError(statusCode)) {
      return 'File Upload Error';
    } else if (this.isServerError(statusCode)) {
      return 'Server Error';
    }
    return 'Error';
  }

  /**
   * Map HTTP status codes to API response codes
   */
  private mapHttpStatusToResponseCode(httpStatus: number): ResponseStatusCode {
    switch (httpStatus) {
      case 401:
        return ResponseConstants.UNAUTHORIZED;
      case 403:
        return ResponseConstants.FORBIDDEN;
      case 404:
        return ResponseConstants.GENERAL_ERROR;
      case 400:
        return ResponseConstants.VALIDATION_ERROR;
      case 413:
        return ResponseConstants.FILE_SIZE_EXCEEDED;
      case 500:
        return ResponseConstants.INTERNAL_SERVER_ERROR;
      case 503:
        return ResponseConstants.SERVICE_UNAVAILABLE;
      default:
        return ResponseConstants.GENERAL_ERROR;
    }
  }

  /**
   * Get user-friendly message for HTTP errors
   */
  private getHttpErrorMessage(error: HttpErrorResponse): string {
    if (error.error && typeof error.error === 'object') {
      // Try to extract message from error response
      if (error.error.message) {
        return error.error.message;
      }
      if (error.error.error) {
        return error.error.error;
      }
    }

    switch (error.status) {
      case 0:
        return 'Unable to connect to server. Please check your internet connection.';
      case 401:
        return 'You are not authorized to perform this action.';
      case 403:
        return 'Access denied. You don\'t have permission to access this resource.';
      case 404:
        return 'The requested resource was not found.';
      case 413:
        return 'File size too large.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 503:
        return 'Service temporarily unavailable.';
      default:
        return `Server error occurred (${error.status})`;
    }
  }

  private isAuthError(statusCode: string): boolean {
    return statusCode.startsWith('1');
  }

  private isValidationError(statusCode: string): boolean {
    return statusCode.startsWith('2');
  }

  private isBusinessError(statusCode: string): boolean {
    return statusCode.startsWith('3');
  }

  private isFileError(statusCode: string): boolean {
    return statusCode.startsWith('4');
  }

  private isServerError(statusCode: string): boolean {
    return statusCode.startsWith('7');
  }
}