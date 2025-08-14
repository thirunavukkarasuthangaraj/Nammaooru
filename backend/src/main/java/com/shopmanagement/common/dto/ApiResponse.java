package com.shopmanagement.common.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Standard API response wrapper for all endpoints
 * @param <T> The type of data being returned
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {
    
    /**
     * Response status code (0000 for success, other codes for errors)
     */
    private String statusCode;
    
    /**
     * Response message
     */
    private String message;
    
    /**
     * Response data (null for error responses)
     */
    private T data;
    
    /**
     * Timestamp of the response
     */
    @Builder.Default
    private LocalDateTime timestamp = LocalDateTime.now();
    
    /**
     * Request path (optional)
     */
    private String path;
    
    /**
     * Additional error details (only for error responses)
     */
    private ErrorDetails errorDetails;
    
    /**
     * Create a success response with data
     */
    public static <T> ApiResponse<T> success(T data) {
        return ApiResponse.<T>builder()
                .statusCode("0000")
                .message("Success")
                .data(data)
                .build();
    }
    
    /**
     * Create a success response with custom message
     */
    public static <T> ApiResponse<T> success(T data, String message) {
        return ApiResponse.<T>builder()
                .statusCode("0000")
                .message(message)
                .data(data)
                .build();
    }
    
    /**
     * Create an error response
     */
    public static <T> ApiResponse<T> error(String statusCode, String message) {
        return ApiResponse.<T>builder()
                .statusCode(statusCode)
                .message(message)
                .data(null)
                .build();
    }
    
    /**
     * Create an error response with details
     */
    public static <T> ApiResponse<T> error(String statusCode, String message, ErrorDetails errorDetails) {
        return ApiResponse.<T>builder()
                .statusCode(statusCode)
                .message(message)
                .errorDetails(errorDetails)
                .data(null)
                .build();
    }
    
    /**
     * Error details for more specific error information
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ErrorDetails {
        private String field;
        private String rejectedValue;
        private String reason;
        private String stackTrace;
    }
}