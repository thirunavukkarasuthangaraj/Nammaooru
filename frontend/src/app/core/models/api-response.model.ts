/**
 * Standard API response interface matching backend ApiResponse
 */
export interface ApiResponse<T = any> {
  statusCode: string;
  message: string;
  data: T;
  timestamp: string;
  path?: string;
  errorDetails?: ErrorDetails;
}

export interface ErrorDetails {
  field?: string;
  rejectedValue?: string;
  reason?: string;
  stackTrace?: string;
}

import { API_STATUS_CODES, API_ERROR_MESSAGES } from '../constants/app.constants';

/**
 * Response constants matching backend (imported from centralized constants)
 */
export const ResponseConstants = API_STATUS_CODES;

/**
 * Type for response status codes
 */
export type ResponseStatusCode = typeof ResponseConstants[keyof typeof ResponseConstants];

/**
 * Helper functions for API response handling
 */
export class ApiResponseHelper {
  
  static isSuccess<T>(response: ApiResponse<T>): boolean {
    return response.statusCode === ResponseConstants.SUCCESS;
  }
  
  static isError<T>(response: ApiResponse<T>): boolean {
    return response.statusCode !== ResponseConstants.SUCCESS;
  }
  
  static getErrorMessage<T>(response: ApiResponse<T>): string {
    if (this.isSuccess(response)) {
      return '';
    }
    // Use specific error message from API_ERROR_MESSAGES if available, otherwise use response message or default
    return API_ERROR_MESSAGES[response.statusCode] || response.message || 'An unknown error occurred';
  }
  
  static isAuthError<T>(response: ApiResponse<T>): boolean {
    const authErrorCodes: string[] = [
      ResponseConstants.UNAUTHORIZED,
      ResponseConstants.FORBIDDEN,
      ResponseConstants.INVALID_CREDENTIALS,
      ResponseConstants.TOKEN_EXPIRED,
      ResponseConstants.TOKEN_INVALID
    ];
    return authErrorCodes.includes(response.statusCode);
  }
  
  static isValidationError<T>(response: ApiResponse<T>): boolean {
    return response.statusCode.startsWith('2');
  }
  
  static isBusinessError<T>(response: ApiResponse<T>): boolean {
    return response.statusCode.startsWith('3');
  }
  
  static isFileError<T>(response: ApiResponse<T>): boolean {
    return response.statusCode.startsWith('4');
  }
  
  static isServerError<T>(response: ApiResponse<T>): boolean {
    return response.statusCode.startsWith('7');
  }
}