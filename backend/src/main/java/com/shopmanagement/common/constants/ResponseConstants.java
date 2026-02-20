package com.shopmanagement.common.constants;

/**
 * Common response constants for all API responses
 */
public class ResponseConstants {
    
    // Success codes
    public static final String SUCCESS = "0000";
    public static final String SUCCESS_MESSAGE = "Success";
    
    // General error codes
    public static final String GENERAL_ERROR = "9999";
    public static final String GENERAL_ERROR_MESSAGE = "General error occurred";
    
    // Authentication & Authorization errors (1xxx)
    public static final String UNAUTHORIZED = "1001";
    public static final String UNAUTHORIZED_MESSAGE = "Unauthorized access";
    
    public static final String FORBIDDEN = "1002";
    public static final String FORBIDDEN_MESSAGE = "Access forbidden";
    
    public static final String INVALID_CREDENTIALS = "1003";
    public static final String INVALID_CREDENTIALS_MESSAGE = "Invalid username or password";
    
    public static final String TOKEN_EXPIRED = "1004";
    public static final String TOKEN_EXPIRED_MESSAGE = "Token has expired";
    
    public static final String TOKEN_INVALID = "1005";
    public static final String TOKEN_INVALID_MESSAGE = "Invalid token";
    
    // Validation errors (2xxx)
    public static final String VALIDATION_ERROR = "2001";
    public static final String VALIDATION_ERROR_MESSAGE = "Validation error";
    
    public static final String REQUIRED_FIELD_MISSING = "2002";
    public static final String REQUIRED_FIELD_MISSING_MESSAGE = "Required field is missing";
    
    public static final String INVALID_FORMAT = "2003";
    public static final String INVALID_FORMAT_MESSAGE = "Invalid data format";
    
    public static final String DUPLICATE_ENTRY = "2004";
    public static final String DUPLICATE_ENTRY_MESSAGE = "Duplicate entry exists";
    
    // Business logic errors (3xxx)
    public static final String SHOP_NOT_FOUND = "3001";
    public static final String SHOP_NOT_FOUND_MESSAGE = "Shop not found";
    
    public static final String USER_NOT_FOUND = "3002";
    public static final String USER_NOT_FOUND_MESSAGE = "User not found";
    
    public static final String DOCUMENT_NOT_FOUND = "3003";
    public static final String DOCUMENT_NOT_FOUND_MESSAGE = "Document not found";
    
    public static final String SHOP_ALREADY_APPROVED = "3004";
    public static final String SHOP_ALREADY_APPROVED_MESSAGE = "Shop is already approved";
    
    public static final String SHOP_ALREADY_REJECTED = "3005";
    public static final String SHOP_ALREADY_REJECTED_MESSAGE = "Shop is already rejected";

    public static final String PRODUCT_NOT_FOUND = "3006";
    public static final String PRODUCT_NOT_FOUND_MESSAGE = "Product not found";

    // File upload errors (4xxx)
    public static final String FILE_UPLOAD_ERROR = "4001";
    public static final String FILE_UPLOAD_ERROR_MESSAGE = "File upload failed";
    
    public static final String FILE_SIZE_EXCEEDED = "4002";
    public static final String FILE_SIZE_EXCEEDED_MESSAGE = "File size exceeds limit";
    
    public static final String FILE_TYPE_NOT_ALLOWED = "4003";
    public static final String FILE_TYPE_NOT_ALLOWED_MESSAGE = "File type not allowed";
    
    public static final String FILE_NOT_FOUND = "4004";
    public static final String FILE_NOT_FOUND_MESSAGE = "File not found";

    public static final String CONTENT_MODERATION_FAILED = "4005";
    public static final String CONTENT_MODERATION_FAILED_MESSAGE = "Image contains inappropriate content";

    // Database errors (5xxx)
    public static final String DATABASE_ERROR = "5001";
    public static final String DATABASE_ERROR_MESSAGE = "Database operation failed";
    
    public static final String CONNECTION_ERROR = "5002";
    public static final String CONNECTION_ERROR_MESSAGE = "Database connection error";
    
    // External service errors (6xxx)
    public static final String EXTERNAL_SERVICE_ERROR = "6001";
    public static final String EXTERNAL_SERVICE_ERROR_MESSAGE = "External service error";
    
    public static final String TIMEOUT_ERROR = "6002";
    public static final String TIMEOUT_ERROR_MESSAGE = "Request timeout";
    
    // Server errors (7xxx)
    public static final String INTERNAL_SERVER_ERROR = "7001";
    public static final String INTERNAL_SERVER_ERROR_MESSAGE = "Internal server error";
    
    public static final String SERVICE_UNAVAILABLE = "7002";
    public static final String SERVICE_UNAVAILABLE_MESSAGE = "Service temporarily unavailable";
    
    private ResponseConstants() {
        // Private constructor to prevent instantiation
    }
}