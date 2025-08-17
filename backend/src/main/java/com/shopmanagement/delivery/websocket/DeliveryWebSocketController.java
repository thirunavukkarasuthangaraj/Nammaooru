package com.shopmanagement.delivery.websocket;

import com.shopmanagement.delivery.dto.*;
import com.shopmanagement.delivery.service.DeliveryTrackingService;
import com.shopmanagement.delivery.service.OrderAssignmentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.*;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.annotation.SendToUser;
import org.springframework.messaging.simp.annotation.SubscribeMapping;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Controller
@RequiredArgsConstructor
@Slf4j
public class DeliveryWebSocketController {

    private final SimpMessagingTemplate messagingTemplate;
    private final DeliveryTrackingService trackingService;
    private final OrderAssignmentService assignmentService;

    /**
     * Handle location updates from delivery partners
     */
    @MessageMapping("/delivery/location")
    public void updatePartnerLocation(@Payload LocationUpdateRequest request, Principal principal) {
        log.debug("Received location update from partner: {}", principal.getName());
        
        try {
            // Update location in database
            DeliveryTrackingResponse tracking = trackingService.updateLocation(request);
            
            // Broadcast to customers tracking this order
            messagingTemplate.convertAndSend(
                "/topic/tracking/assignment/" + request.getAssignmentId(),
                tracking
            );
            
            // Send confirmation to partner
            messagingTemplate.convertAndSendToUser(
                principal.getName(),
                "/queue/partner/location-confirm",
                Map.of("success", true, "timestamp", LocalDateTime.now())
            );
            
        } catch (Exception e) {
            log.error("Error updating location: {}", e.getMessage());
            messagingTemplate.convertAndSendToUser(
                principal.getName(),
                "/queue/partner/error",
                Map.of("error", "Failed to update location", "message", e.getMessage())
            );
        }
    }

    /**
     * Handle order assignment notifications
     */
    @MessageMapping("/delivery/assignment/notify")
    public void notifyOrderAssignment(@Payload Map<String, Object> payload) {
        Long partnerId = ((Number) payload.get("partnerId")).longValue();
        Long assignmentId = ((Number) payload.get("assignmentId")).longValue();
        
        log.info("Notifying partner {} about assignment {}", partnerId, assignmentId);
        
        // Get assignment details
        assignmentService.getAssignmentById(assignmentId).ifPresent(assignment -> {
            // Notify specific partner
            messagingTemplate.convertAndSend(
                "/queue/partner/" + partnerId + "/new-assignment",
                assignment
            );
        });
    }

    /**
     * Handle delivery status updates
     */
    @MessageMapping("/delivery/status")
    public void updateDeliveryStatus(@Payload Map<String, Object> payload, Principal principal) {
        Long assignmentId = ((Number) payload.get("assignmentId")).longValue();
        String status = (String) payload.get("status");
        
        log.info("Status update for assignment {}: {}", assignmentId, status);
        
        // Broadcast status update to all subscribers
        Map<String, Object> statusUpdate = new HashMap<>();
        statusUpdate.put("assignmentId", assignmentId);
        statusUpdate.put("status", status);
        statusUpdate.put("timestamp", LocalDateTime.now());
        statusUpdate.put("updatedBy", principal.getName());
        
        // Notify customers
        messagingTemplate.convertAndSend(
            "/topic/delivery/status/" + assignmentId,
            statusUpdate
        );
        
        // Notify admin dashboard
        messagingTemplate.convertAndSend(
            "/topic/delivery/admin/status",
            statusUpdate
        );
    }

    /**
     * Subscribe to tracking updates for an assignment
     */
    @SubscribeMapping("/tracking/assignment/{assignmentId}")
    public DeliveryTrackingResponse subscribeToTracking(@DestinationVariable Long assignmentId) {
        log.info("Client subscribed to tracking for assignment: {}", assignmentId);
        
        // Return current tracking data on subscription
        return trackingService.getLatestTracking(assignmentId)
            .orElse(null);
    }

    /**
     * Handle partner online status updates
     */
    @MessageMapping("/partner/online-status")
    public void updatePartnerOnlineStatus(@Payload Map<String, Object> payload, Principal principal) {
        Long partnerId = ((Number) payload.get("partnerId")).longValue();
        Boolean isOnline = (Boolean) payload.get("isOnline");
        
        log.info("Partner {} status changed to: {}", partnerId, isOnline ? "online" : "offline");
        
        // Update database
        trackingService.updatePartnerOnlineStatus(partnerId, isOnline);
        
        // Notify admin dashboard
        Map<String, Object> statusUpdate = new HashMap<>();
        statusUpdate.put("partnerId", partnerId);
        statusUpdate.put("isOnline", isOnline);
        statusUpdate.put("timestamp", LocalDateTime.now());
        
        messagingTemplate.convertAndSend(
            "/topic/delivery/admin/partner-status",
            statusUpdate
        );
    }

    /**
     * Handle emergency alerts from partners
     */
    @MessageMapping("/partner/emergency")
    @SendToUser("/queue/partner/emergency-response")
    public Map<String, Object> handleEmergencyAlert(@Payload Map<String, Object> payload, Principal principal) {
        Long partnerId = ((Number) payload.get("partnerId")).longValue();
        String emergencyType = (String) payload.get("type");
        Double latitude = ((Number) payload.get("latitude")).doubleValue();
        Double longitude = ((Number) payload.get("longitude")).doubleValue();
        
        log.warn("EMERGENCY ALERT from partner {}: {}", partnerId, emergencyType);
        
        // Notify admin immediately
        Map<String, Object> alert = new HashMap<>();
        alert.put("partnerId", partnerId);
        alert.put("partnerName", principal.getName());
        alert.put("type", emergencyType);
        alert.put("latitude", latitude);
        alert.put("longitude", longitude);
        alert.put("timestamp", LocalDateTime.now());
        alert.put("priority", "HIGH");
        
        messagingTemplate.convertAndSend("/topic/delivery/admin/emergency", alert);
        
        // Send confirmation to partner
        return Map.of(
            "received", true,
            "message", "Emergency alert received. Help is on the way.",
            "timestamp", LocalDateTime.now()
        );
    }

    /**
     * Broadcast system announcements to all partners
     */
    public void broadcastToAllPartners(String message) {
        Map<String, Object> announcement = new HashMap<>();
        announcement.put("message", message);
        announcement.put("timestamp", LocalDateTime.now());
        announcement.put("type", "SYSTEM");
        
        messagingTemplate.convertAndSend("/topic/delivery/announcements", announcement);
    }

    /**
     * Send direct message to specific partner
     */
    public void sendToPartner(Long partnerId, String message) {
        Map<String, Object> directMessage = new HashMap<>();
        directMessage.put("message", message);
        directMessage.put("timestamp", LocalDateTime.now());
        
        messagingTemplate.convertAndSend(
            "/queue/partner/" + partnerId + "/message",
            directMessage
        );
    }

    /**
     * Handle customer feedback submission
     */
    @MessageMapping("/customer/feedback")
    public void handleCustomerFeedback(@Payload Map<String, Object> payload) {
        Long assignmentId = ((Number) payload.get("assignmentId")).longValue();
        Integer rating = ((Number) payload.get("rating")).intValue();
        String feedback = (String) payload.get("feedback");
        
        log.info("Customer feedback for assignment {}: {} stars", assignmentId, rating);
        
        // Notify partner about feedback
        assignmentService.getAssignmentById(assignmentId).ifPresent(assignment -> {
            Map<String, Object> feedbackNotification = new HashMap<>();
            feedbackNotification.put("assignmentId", assignmentId);
            feedbackNotification.put("rating", rating);
            feedbackNotification.put("feedback", feedback);
            feedbackNotification.put("timestamp", LocalDateTime.now());
            
            messagingTemplate.convertAndSend(
                "/queue/partner/" + assignment.getPartnerId() + "/feedback",
                feedbackNotification
            );
        });
    }

    /**
     * Handle real-time chat between customer and partner
     */
    @MessageMapping("/chat/send")
    public void handleChatMessage(@Payload Map<String, Object> payload, Principal principal) {
        Long assignmentId = ((Number) payload.get("assignmentId")).longValue();
        String message = (String) payload.get("message");
        String senderType = (String) payload.get("senderType"); // CUSTOMER or PARTNER
        
        Map<String, Object> chatMessage = new HashMap<>();
        chatMessage.put("assignmentId", assignmentId);
        chatMessage.put("message", message);
        chatMessage.put("senderType", senderType);
        chatMessage.put("senderName", principal.getName());
        chatMessage.put("timestamp", LocalDateTime.now());
        
        // Broadcast to both customer and partner channels
        messagingTemplate.convertAndSend(
            "/topic/delivery/chat/" + assignmentId,
            chatMessage
        );
    }
}