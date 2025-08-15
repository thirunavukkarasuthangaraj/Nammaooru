import { Injectable } from '@angular/core';
import { 
  APP_CONSTANTS, 
  API_STATUS_CODES, 
  SHOP_STATUS, 
  BUSINESS_TYPES,
  DOCUMENT_TYPES,
  UI_MESSAGES,
  UI_COLORS,
  LOCAL_STORAGE_KEYS,
  ROUTES
} from '../constants/app.constants';

/**
 * Service to provide easy access to application constants
 * This ensures consistent usage across all components
 */
@Injectable({
  providedIn: 'root'
})
export class ConstantsService {

  // Expose constants for easy access
  readonly API_STATUS = API_STATUS_CODES;
  readonly SHOP_STATUS = SHOP_STATUS;
  readonly BUSINESS_TYPES = BUSINESS_TYPES;
  readonly DOCUMENT_TYPES = DOCUMENT_TYPES;
  readonly MESSAGES = UI_MESSAGES;
  readonly COLORS = UI_COLORS;
  readonly STORAGE_KEYS = LOCAL_STORAGE_KEYS;
  readonly ROUTES = ROUTES;
  readonly ALL = APP_CONSTANTS;

  constructor() { }

  /**
   * Get shop status display text
   */
  getShopStatusDisplay(status: string): string {
    switch (status?.toUpperCase()) {
      case this.SHOP_STATUS.PENDING:
        return 'Pending Approval';
      case this.SHOP_STATUS.APPROVED:
        return 'Approved';
      case this.SHOP_STATUS.REJECTED:
        return 'Rejected';
      case this.SHOP_STATUS.SUSPENDED:
        return 'Suspended';
      default:
        return status || 'Unknown';
    }
  }

  /**
   * Get shop status color
   */
  getShopStatusColor(status: string): string {
    switch (status?.toUpperCase()) {
      case this.SHOP_STATUS.PENDING:
        return this.COLORS.STATUS.PENDING;
      case this.SHOP_STATUS.APPROVED:
        return this.COLORS.STATUS.APPROVED;
      case this.SHOP_STATUS.REJECTED:
        return this.COLORS.STATUS.REJECTED;
      case this.SHOP_STATUS.SUSPENDED:
        return this.COLORS.STATUS.SUSPENDED;
      default:
        return '#6c757d';
    }
  }

  /**
   * Get business type display text
   */
  getBusinessTypeDisplay(type: string): string {
    switch (type?.toUpperCase()) {
      case this.BUSINESS_TYPES.GROCERY:
        return 'Grocery Store';
      case this.BUSINESS_TYPES.SUPERMARKET:
        return 'Supermarket';
      case this.BUSINESS_TYPES.PHARMACY:
        return 'Pharmacy';
      case this.BUSINESS_TYPES.RESTAURANT:
        return 'Restaurant';
      case this.BUSINESS_TYPES.CAFE:
        return 'Cafe';
      case this.BUSINESS_TYPES.BAKERY:
        return 'Bakery';
      case this.BUSINESS_TYPES.ELECTRONICS:
        return 'Electronics Store';
      case this.BUSINESS_TYPES.CLOTHING:
        return 'Clothing Store';
      case this.BUSINESS_TYPES.HARDWARE:
        return 'Hardware Store';
      case this.BUSINESS_TYPES.GENERAL:
        return 'General Store';
      default:
        return type || 'Unknown';
    }
  }

  /**
   * Get business type color
   */
  getBusinessTypeColor(type: string): string {
    switch (type?.toUpperCase()) {
      case this.BUSINESS_TYPES.GROCERY:
        return this.COLORS.BUSINESS_TYPE.GROCERY;
      case this.BUSINESS_TYPES.SUPERMARKET:
        return this.COLORS.BUSINESS_TYPE.SUPERMARKET;
      case this.BUSINESS_TYPES.PHARMACY:
        return this.COLORS.BUSINESS_TYPE.PHARMACY;
      case this.BUSINESS_TYPES.RESTAURANT:
        return this.COLORS.BUSINESS_TYPE.RESTAURANT;
      case this.BUSINESS_TYPES.CAFE:
        return this.COLORS.BUSINESS_TYPE.CAFE;
      case this.BUSINESS_TYPES.BAKERY:
        return this.COLORS.BUSINESS_TYPE.BAKERY;
      case this.BUSINESS_TYPES.ELECTRONICS:
        return this.COLORS.BUSINESS_TYPE.ELECTRONICS;
      case this.BUSINESS_TYPES.CLOTHING:
        return this.COLORS.BUSINESS_TYPE.CLOTHING;
      case this.BUSINESS_TYPES.HARDWARE:
        return this.COLORS.BUSINESS_TYPE.HARDWARE;
      case this.BUSINESS_TYPES.GENERAL:
        return this.COLORS.BUSINESS_TYPE.GENERAL;
      default:
        return '#6c757d';
    }
  }

  /**
   * Get document type display text
   */
  getDocumentTypeDisplay(type: string): string {
    switch (type?.toUpperCase()) {
      case this.DOCUMENT_TYPES.OWNER_PHOTO:
        return 'Owner Photo';
      case this.DOCUMENT_TYPES.SHOP_PHOTO:
        return 'Shop Photo';
      case this.DOCUMENT_TYPES.BUSINESS_LICENSE:
        return 'Business License';
      case this.DOCUMENT_TYPES.GST_CERTIFICATE:
        return 'GST Certificate';
      case this.DOCUMENT_TYPES.PAN_CARD:
        return 'PAN Card';
      case this.DOCUMENT_TYPES.AADHAR_CARD:
        return 'Aadhar Card';
      case this.DOCUMENT_TYPES.ADDRESS_PROOF:
        return 'Address Proof';
      case this.DOCUMENT_TYPES.FSSAI_CERTIFICATE:
        return 'FSSAI Certificate';
      case this.DOCUMENT_TYPES.FOOD_LICENSE:
        return 'Food License';
      case this.DOCUMENT_TYPES.DRUG_LICENSE:
        return 'Drug License';
      default:
        return type || 'Other Document';
    }
  }

  /**
   * Check if API response is success
   */
  isApiSuccess(statusCode: string): boolean {
    return statusCode === this.API_STATUS.SUCCESS;
  }

  /**
   * Check if API response is error
   */
  isApiError(statusCode: string): boolean {
    return statusCode !== this.API_STATUS.SUCCESS;
  }

  /**
   * Check if error is authentication related
   */
  isAuthError(statusCode: string): boolean {
    return statusCode.startsWith('1');
  }

  /**
   * Check if error is validation related
   */
  isValidationError(statusCode: string): boolean {
    return statusCode.startsWith('2');
  }

  /**
   * Check if error is business logic related
   */
  isBusinessError(statusCode: string): boolean {
    return statusCode.startsWith('3');
  }

  /**
   * Get user-friendly error message for API status codes
   */
  getErrorMessage(statusCode: string): string {
    switch (statusCode) {
      case this.API_STATUS.UNAUTHORIZED:
        return this.MESSAGES.ERROR.UNAUTHORIZED;
      case this.API_STATUS.FORBIDDEN:
        return this.MESSAGES.ERROR.FORBIDDEN;
      case this.API_STATUS.VALIDATION_ERROR:
        return this.MESSAGES.ERROR.FORM_INVALID;
      case this.API_STATUS.FILE_SIZE_EXCEEDED:
        return this.MESSAGES.ERROR.FILE_SIZE_LARGE;
      case this.API_STATUS.FILE_TYPE_NOT_ALLOWED:
        return this.MESSAGES.ERROR.INVALID_FILE_TYPE;
      case this.API_STATUS.SHOP_NOT_FOUND:
        return 'Shop not found';
      case this.API_STATUS.INTERNAL_SERVER_ERROR:
        return this.MESSAGES.ERROR.GENERAL;
      default:
        return this.MESSAGES.ERROR.GENERAL;
    }
  }

  /**
   * Get success message for common operations
   */
  getSuccessMessage(operation: string): string {
    switch (operation.toLowerCase()) {
      case 'login':
        return this.MESSAGES.SUCCESS.LOGIN;
      case 'logout':
        return this.MESSAGES.SUCCESS.LOGOUT;
      case 'create_shop':
        return this.MESSAGES.SUCCESS.SHOP_CREATED;
      case 'update_shop':
        return this.MESSAGES.SUCCESS.SHOP_UPDATED;
      case 'delete_shop':
        return this.MESSAGES.SUCCESS.SHOP_DELETED;
      case 'approve_shop':
        return this.MESSAGES.SUCCESS.SHOP_APPROVED;
      case 'reject_shop':
        return this.MESSAGES.SUCCESS.SHOP_REJECTED;
      case 'upload_document':
        return this.MESSAGES.SUCCESS.DOCUMENT_UPLOADED;
      default:
        return this.MESSAGES.SUCCESS.DATA_SAVED;
    }
  }

  /**
   * Store data in localStorage with consistent keys
   */
  setStorageItem(key: keyof typeof LOCAL_STORAGE_KEYS, value: any): void {
    try {
      const storageKey = LOCAL_STORAGE_KEYS[key];
      localStorage.setItem(storageKey, JSON.stringify(value));
    } catch (error) {
      console.error('Error storing data:', error);
    }
  }

  /**
   * Get data from localStorage with consistent keys
   */
  getStorageItem(key: keyof typeof LOCAL_STORAGE_KEYS): any {
    try {
      const storageKey = LOCAL_STORAGE_KEYS[key];
      const item = localStorage.getItem(storageKey);
      return item ? JSON.parse(item) : null;
    } catch (error) {
      console.error('Error retrieving data:', error);
      return null;
    }
  }

  /**
   * Remove item from localStorage
   */
  removeStorageItem(key: keyof typeof LOCAL_STORAGE_KEYS): void {
    try {
      const storageKey = LOCAL_STORAGE_KEYS[key];
      localStorage.removeItem(storageKey);
    } catch (error) {
      console.error('Error removing data:', error);
    }
  }

  /**
   * Clear all app data from localStorage
   */
  clearAppStorage(): void {
    Object.values(LOCAL_STORAGE_KEYS).forEach(key => {
      localStorage.removeItem(key);
    });
  }
}