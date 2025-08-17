package com.shopmanagement.delivery.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.delivery.dto.*;
import com.shopmanagement.delivery.entity.OrderAssignment;
import com.shopmanagement.delivery.service.OrderAssignmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/delivery/assignments")
@RequiredArgsConstructor
@Slf4j
public class OrderAssignmentController {

    private final OrderAssignmentService assignmentService;

    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<OrderAssignmentResponse>> assignOrder(
            @Valid @RequestBody OrderAssignmentRequest request) {
        log.info("Order assignment request received for order: {}", request.getOrderId());
        
        try {
            OrderAssignmentResponse response = assignmentService.assignOrder(request);
            return ResponseUtil.success(response, "Order assigned successfully");
        } catch (Exception e) {
            log.error("Error assigning order: {}", e.getMessage());
            return ResponseUtil.error("Assignment failed: " + e.getMessage());
        }
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('SHOP_OWNER') or hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<OrderAssignmentResponse>> getAssignmentById(@PathVariable Long id) {
        return assignmentService.getAssignmentById(id)
                .map(assignment -> ResponseUtil.success(assignment))
                .orElse(ResponseUtil.error("Assignment not found"));
    }

    @GetMapping("/order/{orderId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<List<OrderAssignmentResponse>>> getAssignmentsByOrder(@PathVariable Long orderId) {
        List<OrderAssignmentResponse> assignments = assignmentService.getAssignmentsByOrder(orderId);
        return ResponseUtil.success(assignments);
    }

    @GetMapping("/partner/{partnerId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<Page<OrderAssignmentResponse>>> getAssignmentsByPartner(
            @PathVariable Long partnerId, Pageable pageable) {
        Page<OrderAssignmentResponse> assignments = assignmentService.getAssignmentsByPartner(partnerId, pageable);
        return ResponseUtil.success(assignments);
    }

    @GetMapping("/partner/{partnerId}/active")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<List<OrderAssignmentResponse>>> getActiveAssignmentsByPartner(@PathVariable Long partnerId) {
        List<OrderAssignmentResponse> assignments = assignmentService.getActiveAssignmentsByPartner(partnerId);
        return ResponseUtil.success(assignments);
    }

    @GetMapping("/status/{status}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<List<OrderAssignmentResponse>>> getAssignmentsByStatus(
            @PathVariable OrderAssignment.AssignmentStatus status) {
        List<OrderAssignmentResponse> assignments = assignmentService.getAssignmentsByStatus(status);
        return ResponseUtil.success(assignments);
    }

    @PutMapping("/{id}/accept")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<OrderAssignmentResponse>> acceptAssignment(
            @PathVariable Long id,
            @RequestBody Map<String, Long> request) {
        try {
            Long partnerId = request.get("partnerId");
            OrderAssignmentResponse response = assignmentService.acceptAssignment(id, partnerId);
            return ResponseUtil.success(response, "Assignment accepted successfully");
        } catch (Exception e) {
            log.error("Error accepting assignment: {}", e.getMessage());
            return ResponseUtil.error("Failed to accept assignment: " + e.getMessage());
        }
    }

    @PutMapping("/{id}/reject")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<OrderAssignmentResponse>> rejectAssignment(
            @PathVariable Long id,
            @RequestBody Map<String, Object> request) {
        try {
            Long partnerId = ((Number) request.get("partnerId")).longValue();
            String reason = (String) request.get("reason");
            OrderAssignmentResponse response = assignmentService.rejectAssignment(id, partnerId, reason);
            return ResponseUtil.success(response, "Assignment rejected successfully");
        } catch (Exception e) {
            log.error("Error rejecting assignment: {}", e.getMessage());
            return ResponseUtil.error("Failed to reject assignment: " + e.getMessage());
        }
    }

    @PutMapping("/{id}/pickup")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<OrderAssignmentResponse>> markPickedUp(
            @PathVariable Long id,
            @RequestBody Map<String, Long> request) {
        try {
            Long partnerId = request.get("partnerId");
            OrderAssignmentResponse response = assignmentService.markPickedUp(id, partnerId);
            return ResponseUtil.success(response, "Order marked as picked up successfully");
        } catch (Exception e) {
            log.error("Error marking pickup: {}", e.getMessage());
            return ResponseUtil.error("Failed to mark as picked up: " + e.getMessage());
        }
    }

    @PutMapping("/{id}/start-delivery")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<OrderAssignmentResponse>> startDelivery(
            @PathVariable Long id,
            @RequestBody Map<String, Long> request) {
        try {
            Long partnerId = request.get("partnerId");
            OrderAssignmentResponse response = assignmentService.startDelivery(id, partnerId);
            return ResponseUtil.success(response, "Delivery started successfully");
        } catch (Exception e) {
            log.error("Error starting delivery: {}", e.getMessage());
            return ResponseUtil.error("Failed to start delivery: " + e.getMessage());
        }
    }

    @PutMapping("/{id}/complete")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<OrderAssignmentResponse>> completeDelivery(
            @PathVariable Long id,
            @RequestBody Map<String, Object> request) {
        try {
            Long partnerId = ((Number) request.get("partnerId")).longValue();
            String notes = (String) request.get("notes");
            OrderAssignmentResponse response = assignmentService.completeDelivery(id, partnerId, notes);
            return ResponseUtil.success(response, "Delivery completed successfully");
        } catch (Exception e) {
            log.error("Error completing delivery: {}", e.getMessage());
            return ResponseUtil.error("Failed to complete delivery: " + e.getMessage());
        }
    }

    @PutMapping("/{id}/fail")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<OrderAssignmentResponse>> markFailed(
            @PathVariable Long id,
            @RequestBody Map<String, Object> request) {
        try {
            Long partnerId = ((Number) request.get("partnerId")).longValue();
            String reason = (String) request.get("reason");
            OrderAssignmentResponse response = assignmentService.markFailed(id, partnerId, reason);
            return ResponseUtil.success(response, "Assignment marked as failed");
        } catch (Exception e) {
            log.error("Error marking assignment as failed: {}", e.getMessage());
            return ResponseUtil.error("Failed to mark as failed: " + e.getMessage());
        }
    }

    @PostMapping("/process-expired")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<String>> processExpiredAssignments() {
        try {
            assignmentService.processExpiredAssignments();
            return ResponseUtil.success("Expired assignments processed successfully");
        } catch (Exception e) {
            log.error("Error processing expired assignments: {}", e.getMessage());
            return ResponseUtil.error("Failed to process expired assignments: " + e.getMessage());
        }
    }
}