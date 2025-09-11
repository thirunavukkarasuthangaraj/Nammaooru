package com.shopmanagement.exception;

import com.shopmanagement.common.constants.ResponseConstants;
import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.shop.exception.ShopNotFoundException;
import com.shopmanagement.shop.exception.ShopValidationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(ShopNotFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleShopNotFoundException(ShopNotFoundException ex, WebRequest request) {
        log.error("Shop not found: {}", ex.getMessage());
        
        ApiResponse<Void> response = ApiResponse.<Void>builder()
                .statusCode(ResponseConstants.SHOP_NOT_FOUND)
                .message(ex.getMessage())
                .path(request.getDescription(false).replace("uri=", ""))
                .build();
        
        return new ResponseEntity<>(response, HttpStatus.OK);  // Always return 200
    }

    @ExceptionHandler(ShopValidationException.class)
    public ResponseEntity<ApiResponse<Void>> handleShopValidationException(ShopValidationException ex, WebRequest request) {
        log.error("Shop validation error: {}", ex.getMessage());
        
        ApiResponse<Void> response = ApiResponse.<Void>builder()
                .statusCode(ResponseConstants.VALIDATION_ERROR)
                .message(ex.getMessage())
                .path(request.getDescription(false).replace("uri=", ""))
                .build();
        
        return new ResponseEntity<>(response, HttpStatus.OK);  // Always return 200
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleValidationExceptions(
            MethodArgumentNotValidException ex, WebRequest request) {
        
        Map<String, String> errors = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .collect(Collectors.toMap(
                    FieldError::getField,
                    fieldError -> fieldError.getDefaultMessage() != null ? fieldError.getDefaultMessage() : "Invalid value",
                    (existing, replacement) -> existing
                ));

        ApiResponse<Map<String, String>> response = ApiResponse.<Map<String, String>>builder()
                .statusCode(ResponseConstants.VALIDATION_ERROR)
                .message(ResponseConstants.VALIDATION_ERROR_MESSAGE)
                .data(errors)
                .path(request.getDescription(false).replace("uri=", ""))
                .build();

        return new ResponseEntity<>(response, HttpStatus.OK);  // Always return 200
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse<Void>> handleIllegalArgumentException(IllegalArgumentException ex, WebRequest request) {
        log.error("Illegal argument: {}", ex.getMessage());
        
        ApiResponse<Void> response = ApiResponse.<Void>builder()
                .statusCode(ResponseConstants.VALIDATION_ERROR)
                .message(ex.getMessage())
                .path(request.getDescription(false).replace("uri=", ""))
                .build();
        
        return new ResponseEntity<>(response, HttpStatus.OK);  // Always return 200
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiResponse<Void>> handleAuthenticationException(AuthenticationException ex, WebRequest request) {
        log.error("Authentication failed: {}", ex.getMessage());
        
        String message = ex.getMessage() != null ? ex.getMessage() : ResponseConstants.INVALID_CREDENTIALS_MESSAGE;
        
        ApiResponse<Void> response = ApiResponse.<Void>builder()
                .statusCode(ResponseConstants.INVALID_CREDENTIALS)  // Use proper auth error code 1003
                .message(message)
                .path(request.getDescription(false).replace("uri=", ""))
                .build();
        
        return new ResponseEntity<>(response, HttpStatus.OK);  // Always return 200
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handleAccessDeniedException(AccessDeniedException ex, WebRequest request) {
        log.error("Access denied: {}", ex.getMessage());
        
        ApiResponse<Void> response = ApiResponse.<Void>builder()
                .statusCode(ResponseConstants.FORBIDDEN)
                .message(ResponseConstants.FORBIDDEN_MESSAGE)
                .path(request.getDescription(false).replace("uri=", ""))
                .build();
        
        return new ResponseEntity<>(response, HttpStatus.OK);  // Always return 200
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiResponse<Void>> handleMaxUploadSizeExceededException(MaxUploadSizeExceededException ex, WebRequest request) {
        log.error("File size exceeded: {}", ex.getMessage());
        
        ApiResponse<Void> response = ApiResponse.<Void>builder()
                .statusCode(ResponseConstants.FILE_SIZE_EXCEEDED)
                .message(ResponseConstants.FILE_SIZE_EXCEEDED_MESSAGE)
                .path(request.getDescription(false).replace("uri=", ""))
                .build();
        
        return new ResponseEntity<>(response, HttpStatus.OK);  // Always return 200
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ApiResponse<Void>> handleRuntimeException(RuntimeException ex, WebRequest request) {
        log.error("Runtime error occurred", ex);
        
        String statusCode = ResponseConstants.GENERAL_ERROR;
        String message = ex.getMessage();
        
        // Check for specific runtime exceptions
        if (ex.getMessage() != null) {
            if (ex.getMessage().contains("not found")) {
                statusCode = ResponseConstants.GENERAL_ERROR;
            } else if (ex.getMessage().contains("File")) {
                statusCode = ResponseConstants.FILE_UPLOAD_ERROR;
                message = ResponseConstants.FILE_UPLOAD_ERROR_MESSAGE;
            } else if (ex.getMessage().contains("Database")) {
                statusCode = ResponseConstants.DATABASE_ERROR;
                message = ResponseConstants.DATABASE_ERROR_MESSAGE;
            }
        }
        
        ApiResponse<Void> response = ApiResponse.<Void>builder()
                .statusCode(statusCode)
                .message(message != null ? message : ResponseConstants.GENERAL_ERROR_MESSAGE)
                .path(request.getDescription(false).replace("uri=", ""))
                .build();
        
        return new ResponseEntity<>(response, HttpStatus.OK);  // Always return 200
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleGlobalException(Exception ex, WebRequest request) {
        log.error("Unexpected error occurred", ex);
        
        ApiResponse<Void> response = ApiResponse.<Void>builder()
                .statusCode(ResponseConstants.GENERAL_ERROR)  // Use 9999 for general errors
                .message(ResponseConstants.INTERNAL_SERVER_ERROR_MESSAGE)
                .path(request.getDescription(false).replace("uri=", ""))
                .build();
        
        return new ResponseEntity<>(response, HttpStatus.OK);  // Always return 200
    }
}