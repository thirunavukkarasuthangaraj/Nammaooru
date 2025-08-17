package com.shopmanagement.common.util;

import com.shopmanagement.common.constants.ResponseConstants;
import com.shopmanagement.common.dto.ApiResponse;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Utility class for creating standardized API responses
 */
public class ResponseUtil {
    
    /**
     * Create a success response with data
     */
    public static <T> ResponseEntity<ApiResponse<T>> success(T data) {
        return ResponseEntity.ok(ApiResponse.success(data));
    }
    
    /**
     * Create a success response with custom message
     */
    public static <T> ResponseEntity<ApiResponse<T>> success(T data, String message) {
        return ResponseEntity.ok(ApiResponse.success(data, message));
    }
    
    /**
     * Create a created response (HTTP 201)
     */
    public static <T> ResponseEntity<ApiResponse<T>> created(T data) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(data, "Created successfully"));
    }
    
    /**
     * Create a created response with custom message
     */
    public static <T> ResponseEntity<ApiResponse<T>> created(T data, String message) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(data, message));
    }
    
    /**
     * Create an error response
     */
    public static <T> ResponseEntity<ApiResponse<T>> error(HttpStatus status, String statusCode, String message) {
        return ResponseEntity.status(status)
                .body(ApiResponse.error(statusCode, message));
    }
    
    /**
     * Create a bad request error response
     */
    public static <T> ResponseEntity<ApiResponse<T>> badRequest(String message) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(ResponseConstants.VALIDATION_ERROR, message));
    }
    
    /**
     * Create a not found error response
     */
    public static <T> ResponseEntity<ApiResponse<T>> notFound(String message) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error(ResponseConstants.GENERAL_ERROR, message));
    }
    
    /**
     * Create an unauthorized error response
     */
    public static <T> ResponseEntity<ApiResponse<T>> unauthorized() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.error(ResponseConstants.UNAUTHORIZED, ResponseConstants.UNAUTHORIZED_MESSAGE));
    }
    
    /**
     * Create a forbidden error response
     */
    public static <T> ResponseEntity<ApiResponse<T>> forbidden() {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(ApiResponse.error(ResponseConstants.FORBIDDEN, ResponseConstants.FORBIDDEN_MESSAGE));
    }
    
    /**
     * Create an internal server error response
     */
    public static <T> ResponseEntity<ApiResponse<T>> internalServerError() {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(ResponseConstants.INTERNAL_SERVER_ERROR, 
                                       ResponseConstants.INTERNAL_SERVER_ERROR_MESSAGE));
    }
    
    /**
     * Create an internal server error response with custom message
     */
    public static <T> ResponseEntity<ApiResponse<T>> internalServerError(String message) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(ResponseConstants.INTERNAL_SERVER_ERROR, message));
    }
    
    /**
     * Create a simple error response with default error code and internal server error status
     */
    public static <T> ResponseEntity<ApiResponse<T>> error(String message) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(message));
    }
    
    /**
     * Create a paginated response
     */
    public static <T> ResponseEntity<ApiResponse<Map<String, Object>>> paginated(Page<T> page) {
        Map<String, Object> response = new HashMap<>();
        response.put("content", page.getContent());
        response.put("currentPage", page.getNumber());
        response.put("totalItems", page.getTotalElements());
        response.put("totalPages", page.getTotalPages());
        response.put("pageSize", page.getSize());
        response.put("isFirst", page.isFirst());
        response.put("isLast", page.isLast());
        response.put("hasNext", page.hasNext());
        response.put("hasPrevious", page.hasPrevious());
        
        return ResponseEntity.ok(ApiResponse.success(response, "Data retrieved successfully"));
    }
    
    /**
     * Create a list response
     */
    public static <T> ResponseEntity<ApiResponse<Map<String, Object>>> list(List<T> items) {
        Map<String, Object> response = new HashMap<>();
        response.put("items", items);
        response.put("count", items.size());
        
        return ResponseEntity.ok(ApiResponse.success(response, "Data retrieved successfully"));
    }
    
    /**
     * Create a delete success response
     */
    public static ResponseEntity<ApiResponse<Void>> deleted() {
        return ResponseEntity.ok(ApiResponse.success(null, "Deleted successfully"));
    }
    
    /**
     * Create an update success response
     */
    public static <T> ResponseEntity<ApiResponse<T>> updated(T data) {
        return ResponseEntity.ok(ApiResponse.success(data, "Updated successfully"));
    }
    
    private ResponseUtil() {
        // Private constructor to prevent instantiation
    }
}