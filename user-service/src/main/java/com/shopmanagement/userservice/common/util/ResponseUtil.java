package com.shopmanagement.userservice.common.util;

import com.shopmanagement.userservice.common.constants.ResponseConstants;
import com.shopmanagement.userservice.common.dto.ApiResponse;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ResponseUtil {

    public static <T> ResponseEntity<ApiResponse<T>> success(T data) {
        return ResponseEntity.ok(ApiResponse.success(data));
    }

    public static <T> ResponseEntity<ApiResponse<T>> success(T data, String message) {
        return ResponseEntity.ok(ApiResponse.success(data, message));
    }

    public static <T> ResponseEntity<ApiResponse<T>> created(T data, String message) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(data, message));
    }

    public static <T> ResponseEntity<ApiResponse<T>> error(String message) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(message));
    }

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

    public static <T> ResponseEntity<ApiResponse<Map<String, Object>>> list(List<T> items) {
        Map<String, Object> response = new HashMap<>();
        response.put("items", items);
        response.put("count", items.size());
        return ResponseEntity.ok(ApiResponse.success(response, "Data retrieved successfully"));
    }

    public static ResponseEntity<ApiResponse<Void>> deleted() {
        return ResponseEntity.ok(ApiResponse.success(null, "Deleted successfully"));
    }

    public static <T> ResponseEntity<ApiResponse<T>> updated(T data) {
        return ResponseEntity.ok(ApiResponse.success(data, "Updated successfully"));
    }

    private ResponseUtil() {}
}
