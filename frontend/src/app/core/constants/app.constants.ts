/**
 * Application-wide constants for consistent usage across all components
 */

import { environment } from "@environments/environment";

// API Response Status Codes (matching backend ResponseConstants)
export const API_STATUS_CODES = {
  // Success
  SUCCESS: '0000',
  
  // General Error
  GENERAL_ERROR: '9999',
  
  // Authentication & Authorization (1xxx)
  UNAUTHORIZED: '1001',
  FORBIDDEN: '1002', 
  INVALID_CREDENTIALS: '1003',
  TOKEN_EXPIRED: '1004',
  TOKEN_INVALID: '1005',
  
  // Validation (2xxx)
  VALIDATION_ERROR: '2001',
  REQUIRED_FIELD_MISSING: '2002',
  INVALID_FORMAT: '2003',
  DUPLICATE_ENTRY: '2004',
  
  // Business Logic (3xxx)
  SHOP_NOT_FOUND: '3001',
  USER_NOT_FOUND: '3002',
  DOCUMENT_NOT_FOUND: '3003',
  SHOP_ALREADY_APPROVED: '3004',
  SHOP_ALREADY_REJECTED: '3005',
  
  // File Upload (4xxx)
  FILE_UPLOAD_ERROR: '4001',
  FILE_SIZE_EXCEEDED: '4002',
  FILE_TYPE_NOT_ALLOWED: '4003',
  FILE_NOT_FOUND: '4004',
  
  // Database (5xxx)
  DATABASE_ERROR: '5001',
  CONNECTION_ERROR: '5002',
  
  // Server (7xxx)
  INTERNAL_SERVER_ERROR: '7001',
  SERVICE_UNAVAILABLE: '7002'
} as const;

// Shop Status
export const SHOP_STATUS = {
  PENDING: 'PENDING',
  APPROVED: 'APPROVED',
  REJECTED: 'REJECTED',
  SUSPENDED: 'SUSPENDED'
} as const;

// Business Types
export const BUSINESS_TYPES = {
  GROCERY: 'GROCERY',
  SUPERMARKET: 'SUPERMARKET',
  PHARMACY: 'PHARMACY',
  RESTAURANT: 'RESTAURANT',
  CAFE: 'CAFE',
  BAKERY: 'BAKERY',
  ELECTRONICS: 'ELECTRONICS',
  CLOTHING: 'CLOTHING',
  HARDWARE: 'HARDWARE',
  GENERAL: 'GENERAL'
} as const;

// Document Types
export const DOCUMENT_TYPES = {
  OWNER_PHOTO: 'OWNER_PHOTO',
  SHOP_PHOTO: 'SHOP_PHOTO',
  BUSINESS_LICENSE: 'BUSINESS_LICENSE',
  GST_CERTIFICATE: 'GST_CERTIFICATE',
  PAN_CARD: 'PAN_CARD',
  AADHAR_CARD: 'AADHAR_CARD',
  ADDRESS_PROOF: 'ADDRESS_PROOF',
  FSSAI_CERTIFICATE: 'FSSAI_CERTIFICATE',
  FOOD_LICENSE: 'FOOD_LICENSE',
  DRUG_LICENSE: 'DRUG_LICENSE',
  TRADE_LICENSE: 'TRADE_LICENSE',
  OTHER: 'OTHER'
} as const;

// Document Verification Status
export const DOCUMENT_STATUS = {
  PENDING: 'PENDING',
  VERIFIED: 'VERIFIED',
  APPROVED: 'APPROVED',
  REJECTED: 'REJECTED'
} as const;

// User Roles
export const USER_ROLES = {
  ADMIN: 'ADMIN',
  SHOP_OWNER: 'SHOP_OWNER',
  USER: 'USER'
} as const;

// API Endpoints
export const API_ENDPOINTS = {
  BASE_URL: environment.apiUrl,
  
  // Authentication
  AUTH: {
    LOGIN: '/auth/login',
    LOGOUT: '/auth/logout',
    REFRESH: '/auth/refresh',
    REGISTER: '/auth/register'
  },
  
  // Shops
  SHOPS: {
    BASE: '/shops',
    ACTIVE: '/shops/active',
    SEARCH: '/shops/search',
    NEARBY: '/shops/nearby',
    FEATURED: '/shops/featured',
    CITIES: '/shops/cities',
    STATISTICS: '/shops/statistics',
    MY_SHOP: '/shops/my-shop',
    APPROVE: (id: number) => `/shops/${id}/approve`,
    REJECT: (id: number) => `/shops/${id}/reject`,
    SUSPEND: (id: number) => `/shops/${id}/suspend`,
    BY_ID: (id: number) => `/shops/${id}`,
    BY_SHOP_ID: (shopId: string) => `/shops/shop-id/${shopId}`,
    BY_SLUG: (slug: string) => `/shops/slug/${slug}`
  },
  
  // Documents
  DOCUMENTS: {
    BASE: '/documents',
    SHOP_DOCUMENTS: (shopId: number) => `/documents/shop/${shopId}`,
    UPLOAD: (shopId: number) => `/documents/shop/${shopId}/upload`,
    DOWNLOAD: (docId: number) => `/documents/${docId}/download`,
    VERIFY: (docId: number) => `/documents/${docId}/verify`,
    TYPES: '/documents/types'
  },
  
  // Users
  USERS: {
    BASE: '/users',
    PROFILE: '/users/profile',
    BY_ID: (id: number) => `/users/${id}`
  }
} as const;

// Error Messages for Status Codes
export const API_ERROR_MESSAGES: Record<string, string> = {
  // Authentication & Authorization errors (1xxx)
  '1001': 'Unauthorized access',
  '1002': 'Access forbidden',
  '1003': 'Invalid username or password',
  '1004': 'Token has expired',
  '1005': 'Invalid token',
  
  // Validation errors (2xxx)
  '2001': 'Validation error',
  '2002': 'Required field is missing',
  '2003': 'Invalid data format',
  '2004': 'Duplicate entry exists',
  
  // Business logic errors (3xxx)
  '3001': 'Shop not found',
  '3002': 'User not found',
  '3003': 'Document not found',
  '3004': 'Shop is already approved',
  '3005': 'Shop is already rejected',
  
  // File upload errors (4xxx)
  '4001': 'File upload failed',
  '4002': 'File size exceeds limit',
  '4003': 'File type not allowed',
  '4004': 'File not found',
  
  // Database errors (5xxx)
  '5001': 'Database operation failed',
  '5002': 'Database connection error',
  
  // External service errors (6xxx)
  '6001': 'External service error',
  '6002': 'Request timeout',
  
  // Server errors (7xxx)
  '7001': 'Internal server error',
  '7002': 'Service temporarily unavailable',
  
  // General error
  '9999': 'General error occurred',
};

// UI Messages
export const UI_MESSAGES = {
  // Success Messages
  SUCCESS: {
    LOGIN: 'Login successful',
    LOGOUT: 'Logout successful',
    SHOP_CREATED: 'Shop created successfully',
    SHOP_UPDATED: 'Shop updated successfully',
    SHOP_DELETED: 'Shop deleted successfully',
    SHOP_APPROVED: 'Shop approved successfully',
    SHOP_REJECTED: 'Shop rejected successfully',
    DOCUMENT_UPLOADED: 'Document uploaded successfully',
    DOCUMENT_VERIFIED: 'Document verified successfully',
    DATA_SAVED: 'Data saved successfully',
    DATA_DELETED: 'Data deleted successfully'
  },
  
  // Error Messages
  ERROR: {
    GENERAL: 'An unexpected error occurred',
    NETWORK: 'Network error. Please check your connection.',
    LOGIN_FAILED: 'Login failed. Please check your credentials.',
    UNAUTHORIZED: 'You are not authorized to perform this action',
    FORBIDDEN: 'Access denied. You don\'t have permission.',
    NOT_FOUND: 'Resource not found',
    FILE_SIZE_LARGE: 'File size too large. Maximum 10MB allowed.',
    INVALID_FILE_TYPE: 'Invalid file type. Only PDF, JPG, PNG allowed.',
    FORM_INVALID: 'Please fill all required fields correctly',
    PASSWORD_MISMATCH: 'Passwords do not match',
    EMAIL_INVALID: 'Please enter a valid email address'
  },
  
  // Confirmation Messages
  CONFIRMATION: {
    DELETE_SHOP: 'Are you sure you want to delete this shop?',
    APPROVE_SHOP: 'Are you sure you want to approve this shop?',
    REJECT_SHOP: 'Are you sure you want to reject this shop?',
    LOGOUT: 'Are you sure you want to logout?',
    UNSAVED_CHANGES: 'You have unsaved changes. Are you sure you want to leave?',
    DELETE_DOCUMENT: 'Are you sure you want to delete this document?'
  },
  
  // Info Messages
  INFO: {
    NO_DATA: 'No data available',
    LOADING: 'Loading...',
    SEARCHING: 'Searching...',
    UPLOADING: 'Uploading...',
    PROCESSING: 'Processing...',
    SAVE_CHANGES: 'Don\'t forget to save your changes',
    DOCUMENT_REQUIRED: 'Documents are required for verification',
    SELECT_FILE: 'Please select a file to upload'
  }
} as const;

// Form Validation Messages
export const VALIDATION_MESSAGES = {
  REQUIRED: 'This field is required',
  MIN_LENGTH: (length: number) => `Minimum ${length} characters required`,
  MAX_LENGTH: (length: number) => `Maximum ${length} characters allowed`,
  EMAIL: 'Please enter a valid email address',
  PHONE: 'Please enter a valid phone number',
  PASSWORD_MIN: 'Password must be at least 8 characters',
  PASSWORD_PATTERN: 'Password must contain at least one uppercase, lowercase, number and special character',
  NUMERIC: 'Only numeric values allowed',
  POSITIVE: 'Value must be positive',
  URL: 'Please enter a valid URL',
  ALPHANUMERIC: 'Only letters and numbers allowed'
} as const;

// File Upload Constants
export const FILE_UPLOAD = {
  MAX_SIZE_MB: 10,
  MAX_SIZE_BYTES: 10 * 1024 * 1024,
  ALLOWED_TYPES: {
    IMAGES: ['image/jpeg', 'image/jpg', 'image/png'],
    DOCUMENTS: ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
    ALL: ['image/jpeg', 'image/jpg', 'image/png', 'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
  },
  EXTENSIONS: {
    IMAGES: ['.jpg', '.jpeg', '.png'],
    DOCUMENTS: ['.pdf', '.doc', '.docx'],
    ALL: ['.jpg', '.jpeg', '.png', '.pdf', '.doc', '.docx']
  }
} as const;

// Pagination Constants
export const PAGINATION = {
  DEFAULT_PAGE_SIZE: 20,
  PAGE_SIZE_OPTIONS: [10, 20, 50, 100],
  MAX_PAGE_SIZE: 100
} as const;

// Date/Time Formats
export const DATE_FORMATS = {
  DISPLAY: 'MMM dd, yyyy',
  DISPLAY_TIME: 'MMM dd, yyyy HH:mm',
  API: 'yyyy-MM-dd',
  API_TIME: 'yyyy-MM-ddTHH:mm:ss'
} as const;

// UI Colors (for status badges, etc.)
export const UI_COLORS = {
  STATUS: {
    PENDING: '#ffc107',
    APPROVED: '#28a745',
    REJECTED: '#dc3545',
    SUSPENDED: '#6c757d'
  },
  BUSINESS_TYPE: {
    GROCERY: '#28a745',
    SUPERMARKET: '#22c55e',
    PHARMACY: '#007bff',
    RESTAURANT: '#6f42c1',
    CAFE: '#8b5cf6',
    BAKERY: '#f59e0b',
    ELECTRONICS: '#3b82f6',
    CLOTHING: '#ec4899',
    HARDWARE: '#64748b',
    GENERAL: '#6c757d'
  },
  DOCUMENT: {
    VERIFIED: '#28a745',
    PENDING: '#ffc107',
    REJECTED: '#dc3545'
  }
} as const;

// Local Storage Keys
export const LOCAL_STORAGE_KEYS = {
  TOKEN: 'auth_token',
  REFRESH_TOKEN: 'refresh_token',
  USER: 'current_user',
  THEME: 'app_theme',
  LANGUAGE: 'app_language',
  SIDEBAR_COLLAPSED: 'sidebar_collapsed',
  RECENT_SEARCHES: 'recent_searches'
} as const;

// Route Paths
export const ROUTES = {
  LOGIN: '/login',
  DASHBOARD: '/dashboard',
  SHOPS: {
    LIST: '/shops',
    MASTER: '/shops/master',
    CREATE: '/shops/create',
    EDIT: (id: number) => `/shops/edit/${id}`,
    VIEW: (id: number) => `/shops/view/${id}`
  },
  USERS: {
    LIST: '/users',
    CREATE: '/users/create',
    EDIT: (id: number) => `/users/edit/${id}`,
    PROFILE: '/profile'
  },
  SETTINGS: '/settings',
  REPORTS: '/reports'
} as const;

// Regex Patterns
export const REGEX_PATTERNS = {
  EMAIL: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  PHONE: /^[6-9]\d{9}$/,
  PASSWORD: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
  ALPHANUMERIC: /^[a-zA-Z0-9]+$/,
  NUMERIC: /^\d+$/,
  POSTAL_CODE: /^\d{6}$/,
  SHOP_ID: /^[A-Z]{2}\d+$/
} as const;

// Animation Durations (in milliseconds)
export const ANIMATIONS = {
  FAST: 150,
  NORMAL: 300,
  SLOW: 500,
  LOADING: 2000
} as const;

// Export all constants as a single object for easy importing
export const APP_CONSTANTS = {
  API_STATUS_CODES,
  API_ERROR_MESSAGES,
  SHOP_STATUS,
  BUSINESS_TYPES,
  DOCUMENT_TYPES,
  DOCUMENT_STATUS,
  USER_ROLES,
  API_ENDPOINTS,
  UI_MESSAGES,
  VALIDATION_MESSAGES,
  FILE_UPLOAD,
  PAGINATION,
  DATE_FORMATS,
  UI_COLORS,
  LOCAL_STORAGE_KEYS,
  ROUTES,
  REGEX_PATTERNS,
  ANIMATIONS
} as const;