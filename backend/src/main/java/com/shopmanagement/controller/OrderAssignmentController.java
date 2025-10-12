package com.shopmanagement.controller;

import com.shopmanagement.entity.OrderAssignment;
import com.shopmanagement.entity.User;
import com.shopmanagement.service.OrderAssignmentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/assignments")
@RequiredArgsConstructor
@Slf4j
public class OrderAssignmentController {

    private final OrderAssignmentService assignmentService;

    /**
     * Auto-assign an order to available delivery partner
     * Called by shop owners when order is ready for pickup
     */
    @PostMapping("/orders/{orderId}/auto-assign")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> autoAssignOrder(
            @PathVariable Long orderId,
            @RequestParam Long assignedBy) {

        log.info("Auto-assigning order {} by user {}", orderId, assignedBy);

        try {
            OrderAssignment assignment = assignmentService.autoAssignOrder(orderId, assignedBy);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Order successfully assigned to delivery partner");
            response.put("assignment", createAssignmentResponse(assignment));

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error auto-assigning order {}: {}", orderId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Manually assign an order to a specific delivery partner
     * Called by shop owners or admins
     */
    @PostMapping("/orders/{orderId}/manual-assign")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> manualAssignOrder(
            @PathVariable Long orderId,
            @RequestParam Long deliveryPartnerId,
            @RequestParam Long assignedBy) {

        log.info("Manually assigning order {} to partner {} by user {}", orderId, deliveryPartnerId, assignedBy);

        try {
            OrderAssignment assignment = assignmentService.manualAssignOrder(orderId, deliveryPartnerId, assignedBy);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Order successfully assigned to delivery partner");
            response.put("assignment", createAssignmentResponse(assignment));

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error manually assigning order {} to partner {}: {}", orderId, deliveryPartnerId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Accept an assignment (called by delivery partner)
     */
    @PostMapping("/{assignmentId}/accept")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<Map<String, Object>> acceptAssignment(
            @PathVariable Long assignmentId,
            @RequestParam Long partnerId) {

        log.info("Partner {} accepting assignment {}", partnerId, assignmentId);

        try {
            OrderAssignment assignment = assignmentService.acceptAssignment(assignmentId, partnerId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Assignment accepted successfully");
            response.put("assignment", createAssignmentResponse(assignment));

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error accepting assignment {}: {}", assignmentId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Reject an assignment (called by delivery partner)
     */
    @PostMapping("/{assignmentId}/reject")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<Map<String, Object>> rejectAssignment(
            @PathVariable Long assignmentId,
            @RequestParam Long partnerId,
            @RequestParam(required = false, defaultValue = "No reason provided") String reason) {

        log.info("Partner {} rejecting assignment {} with reason: {}", partnerId, assignmentId, reason);

        try {
            assignmentService.rejectAssignment(assignmentId, partnerId, reason);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Assignment rejected successfully");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error rejecting assignment {}: {}", assignmentId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Mark assignment as picked up (called by delivery partner)
     */
    @PostMapping("/{assignmentId}/pickup")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<Map<String, Object>> markPickedUp(
            @PathVariable Long assignmentId,
            @RequestParam Long partnerId) {

        log.info("Partner {} marking assignment {} as picked up", partnerId, assignmentId);

        try {
            OrderAssignment assignment = assignmentService.markPickedUp(assignmentId, partnerId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Order marked as picked up successfully");
            response.put("assignment", createAssignmentResponse(assignment));

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error marking assignment {} as picked up: {}", assignmentId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Mark assignment as delivered (called by delivery partner)
     */
    @PostMapping("/{assignmentId}/deliver")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<Map<String, Object>> markDelivered(
            @PathVariable Long assignmentId,
            @RequestParam Long partnerId,
            @RequestParam(required = false) String deliveryNotes) {

        log.info("Partner {} marking assignment {} as delivered", partnerId, assignmentId);

        try {
            OrderAssignment assignment = assignmentService.markDelivered(assignmentId, partnerId, deliveryNotes);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Order marked as delivered successfully");
            response.put("assignment", createAssignmentResponse(assignment));

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error marking assignment {} as delivered: {}", assignmentId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Get available delivery partners for assignment
     */
    @GetMapping("/available-partners")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> getAvailablePartners() {

        try {
            List<User> availablePartners = assignmentService.findAvailableDeliveryPartners();

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("partners", availablePartners.stream()
                .map(this::createPartnerResponse)
                .toList());
            response.put("totalAvailable", availablePartners.size());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error getting available partners: {}", e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Get pending assignments for a delivery partner
     */
    @GetMapping("/partners/{partnerId}/pending")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getPendingAssignments(@PathVariable Long partnerId) {

        try {
            List<OrderAssignment> pendingAssignments = assignmentService.findPendingAssignmentsByPartnerId(partnerId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("assignments", pendingAssignments.stream()
                .map(this::createAssignmentResponse)
                .toList());
            response.put("totalPending", pendingAssignments.size());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error getting pending assignments for partner {}: {}", partnerId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Get available orders for a delivery partner (mobile app endpoint)
     * This endpoint matches what the mobile app expects
     */
    @GetMapping("/partner/{partnerId}/available")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getAvailableOrders(@PathVariable Long partnerId) {

        try {
            List<OrderAssignment> pendingAssignments = assignmentService.findPendingAssignmentsByPartnerId(partnerId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);

            // Format orders for mobile app
            response.put("orders", pendingAssignments.stream()
                .map(this::createMobileOrderResponse)
                .toList());
            response.put("totalAvailable", pendingAssignments.size());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error getting available orders for partner {}: {}", partnerId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            response.put("orders", List.of());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Get current assignment for a delivery partner
     */
    @GetMapping("/partners/{partnerId}/current")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getCurrentAssignment(@PathVariable Long partnerId) {

        try {
            Optional<OrderAssignment> currentAssignment = assignmentService.findCurrentAssignmentByPartnerId(partnerId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);

            if (currentAssignment.isPresent()) {
                response.put("assignment", createAssignmentResponse(currentAssignment.get()));
                response.put("hasCurrentAssignment", true);
            } else {
                response.put("assignment", null);
                response.put("hasCurrentAssignment", false);
                response.put("message", "No current assignment found");
            }

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error getting current assignment for partner {}: {}", partnerId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Get assignment history for a delivery partner
     */
    @GetMapping("/partners/{partnerId}/history")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getAssignmentHistory(@PathVariable Long partnerId, Pageable pageable) {

        try {
            Page<OrderAssignment> assignmentHistory = assignmentService.findAssignmentsByPartnerId(partnerId, pageable);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("assignments", assignmentHistory.getContent().stream()
                .map(this::createAssignmentResponse)
                .toList());
            response.put("totalElements", assignmentHistory.getTotalElements());
            response.put("totalPages", assignmentHistory.getTotalPages());
            response.put("currentPage", assignmentHistory.getNumber());
            response.put("pageSize", assignmentHistory.getSize());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error getting assignment history for partner {}: {}", partnerId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Diagnostic endpoint to check auto-assignment readiness
     */
    @GetMapping("/debug/auto-assignment/{orderId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> debugAutoAssignment(@PathVariable Long orderId) {

        try {
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("orderId", orderId);

            // Check available partners
            List<User> availablePartners = assignmentService.findAvailableDeliveryPartners();
            response.put("availablePartners", availablePartners.stream()
                .map(this::createPartnerResponse)
                .toList());
            response.put("availablePartnersCount", availablePartners.size());

            // Check if order already has active assignment
            Optional<OrderAssignment> existingAssignment = assignmentService.findActiveAssignmentByOrderId(orderId);
            response.put("hasExistingAssignment", existingAssignment.isPresent());
            if (existingAssignment.isPresent()) {
                response.put("existingAssignment", createAssignmentResponse(existingAssignment.get()));
            }

            // Try to simulate auto-assignment without actually doing it
            String autoAssignmentStatus = "ready";
            String autoAssignmentMessage = "Auto-assignment is ready";

            if (availablePartners.isEmpty()) {
                autoAssignmentStatus = "no_partners";
                autoAssignmentMessage = "No available delivery partners found";
            } else if (existingAssignment.isPresent()) {
                autoAssignmentStatus = "already_assigned";
                autoAssignmentMessage = "Order already has an active assignment";
            }

            response.put("autoAssignmentStatus", autoAssignmentStatus);
            response.put("autoAssignmentMessage", autoAssignmentMessage);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error debugging auto-assignment for order {}: {}", orderId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Get assignments for a specific order
     */
    @GetMapping("/orders/{orderId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> getOrderAssignments(@PathVariable Long orderId) {

        try {
            List<OrderAssignment> assignments = assignmentService.findAssignmentsByOrderId(orderId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("assignments", assignments.stream()
                .map(this::createAssignmentResponse)
                .toList());
            response.put("totalAssignments", assignments.size());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error getting assignments for order {}: {}", orderId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Accept order by orderId (mobile app endpoint)
     * This endpoint matches what the mobile app expects
     */
    @PostMapping("/orders/{orderId}/accept")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<Map<String, Object>> acceptOrderById(
            @PathVariable Long orderId,
            @RequestParam Long partnerId) {

        log.info("Partner {} accepting order {}", partnerId, orderId);

        try {
            // Find the assignment by orderId and partnerId
            List<OrderAssignment> assignments = assignmentService.findAssignmentsByOrderId(orderId);
            OrderAssignment assignment = assignments.stream()
                .filter(a -> a.getDeliveryPartner().getId().equals(partnerId) &&
                           a.getStatus() == OrderAssignment.AssignmentStatus.ASSIGNED)
                .findFirst()
                .orElseThrow(() -> new RuntimeException("No pending assignment found for this order and partner"));

            // Accept the assignment
            OrderAssignment acceptedAssignment = assignmentService.acceptAssignment(assignment.getId(), partnerId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Order accepted successfully");
            response.put("assignment", createMobileOrderResponse(acceptedAssignment));

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error accepting order {}: {}", orderId, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    // Helper methods to create response objects
    private Map<String, Object> createAssignmentResponse(OrderAssignment assignment) {
        Map<String, Object> response = new HashMap<>();
        response.put("id", assignment.getId());
        response.put("status", assignment.getStatus());
        response.put("assignmentType", assignment.getAssignmentType());
        response.put("assignedAt", assignment.getAssignedAt());
        response.put("acceptedAt", assignment.getAcceptedAt());
        response.put("pickupTime", assignment.getPickupTime());
        response.put("deliveryCompletedAt", assignment.getDeliveryCompletedAt());
        response.put("deliveryFee", assignment.getDeliveryFee());
        response.put("partnerCommission", assignment.getPartnerCommission());
        response.put("assignmentNotes", assignment.getAssignmentNotes());
        response.put("deliveryNotes", assignment.getDeliveryNotes());

        // Order information
        Map<String, Object> orderInfo = new HashMap<>();
        orderInfo.put("id", assignment.getOrder().getId());
        orderInfo.put("orderNumber", assignment.getOrder().getOrderNumber());
        orderInfo.put("totalAmount", assignment.getOrder().getTotalAmount());
        orderInfo.put("deliveryAddress", assignment.getOrder().getDeliveryAddress());
        response.put("order", orderInfo);

        // Partner information
        Map<String, Object> partnerInfo = new HashMap<>();
        partnerInfo.put("id", assignment.getDeliveryPartner().getId());
        partnerInfo.put("name", assignment.getDeliveryPartner().getFirstName() + " " + assignment.getDeliveryPartner().getLastName());
        partnerInfo.put("email", assignment.getDeliveryPartner().getEmail());
        partnerInfo.put("mobileNumber", assignment.getDeliveryPartner().getMobileNumber());
        response.put("deliveryPartner", partnerInfo);

        return response;
    }

    private Map<String, Object> createPartnerResponse(User partner) {
        Map<String, Object> response = new HashMap<>();
        response.put("id", partner.getId());
        response.put("name", partner.getFirstName() + " " + partner.getLastName());
        response.put("email", partner.getEmail());
        response.put("mobileNumber", partner.getMobileNumber());
        response.put("isOnline", partner.getIsOnline());
        response.put("isAvailable", partner.getIsAvailable());
        response.put("rideStatus", partner.getRideStatus());
        response.put("currentLatitude", partner.getCurrentLatitude());
        response.put("currentLongitude", partner.getCurrentLongitude());
        response.put("lastActivity", partner.getLastActivity());
        return response;
    }

    /**
     * Create mobile app formatted order response
     */
    private Map<String, Object> createMobileOrderResponse(OrderAssignment assignment) {
        Map<String, Object> response = new HashMap<>();

        // Assignment details
        response.put("assignmentId", assignment.getId());
        response.put("orderId", assignment.getOrder().getId());
        response.put("orderNumber", assignment.getOrder().getOrderNumber());
        response.put("status", assignment.getStatus().toString());

        // Order details
        response.put("orderValue", assignment.getOrder().getTotalAmount());
        response.put("deliveryFee", assignment.getDeliveryFee());
        response.put("partnerCommission", assignment.getPartnerCommission());
        response.put("deliveryAddress", assignment.getOrder().getDeliveryAddress());

        // Customer details
        response.put("customerName", assignment.getOrder().getCustomer().getFirstName() + " " + assignment.getOrder().getCustomer().getLastName());
        response.put("customerPhone", assignment.getOrder().getCustomer().getMobileNumber());

        // Shop details
        response.put("shopName", assignment.getOrder().getShop().getName());
        response.put("shopAddress", assignment.getOrder().getShop().getAddressLine1());
        response.put("shopPhone", assignment.getOrder().getShop().getOwnerPhone());

        // Timestamps
        response.put("assignedAt", assignment.getAssignedAt());
        response.put("createdAt", assignment.getOrder().getCreatedAt());

        return response;
    }
}