package com.shopmanagement.controller;

import com.shopmanagement.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.annotation.SubscribeMapping;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;

import java.time.LocalDateTime;
import java.util.Map;

@Controller
@RequiredArgsConstructor
@Slf4j
public class WebSocketController {

    private final SimpMessagingTemplate messagingTemplate;
    private final NotificationService notificationService;

    /**
     * Handle delivery partner connection
     */
    @SubscribeMapping("/partner/{partnerId}/connect")
    public String partnerConnect(@DestinationVariable Long partnerId, Authentication authentication) {
        log.info("Delivery partner {} connected to WebSocket", partnerId);

        // Send connection confirmation
        messagingTemplate.convertAndSendToUser(
            partnerId.toString(),
            "/queue/partner/status",
            Map.of(
                "status", "connected",
                "message", "Successfully connected to real-time updates",
                "timestamp", LocalDateTime.now()
            )
        );

        return "Connected successfully";
    }

    /**
     * Handle delivery partner status updates
     */
    @MessageMapping("/partner/{partnerId}/status")
    public void updatePartnerStatus(@DestinationVariable Long partnerId, @Payload Map<String, Object> statusUpdate) {
        log.info("Partner {} status update: {}", partnerId, statusUpdate);

        try {
            String status = (String) statusUpdate.get("status");
            String location = (String) statusUpdate.get("location");
            Boolean isAvailable = (Boolean) statusUpdate.get("isAvailable");

            // Broadcast status update to relevant parties
            messagingTemplate.convertAndSend("/topic/delivery/partner-status", Map.of(
                "partnerId", partnerId,
                "status", status,
                "location", location,
                "isAvailable", isAvailable,
                "timestamp", LocalDateTime.now()
            ));

            // Send confirmation back to partner
            messagingTemplate.convertAndSendToUser(
                partnerId.toString(),
                "/queue/partner/status",
                Map.of(
                    "status", "updated",
                    "message", "Status updated successfully",
                    "timestamp", LocalDateTime.now()
                )
            );

        } catch (Exception e) {
            log.error("Error updating partner status: {}", e.getMessage());
            messagingTemplate.convertAndSendToUser(
                partnerId.toString(),
                "/queue/partner/error",
                Map.of(
                    "error", "Failed to update status",
                    "message", e.getMessage(),
                    "timestamp", LocalDateTime.now()
                )
            );
        }
    }

    /**
     * Handle order acceptance from delivery partner
     */
    @MessageMapping("/partner/{partnerId}/order/{orderId}/accept")
    public void acceptOrder(@DestinationVariable Long partnerId, @DestinationVariable Long orderId) {
        log.info("Partner {} accepting order {}", partnerId, orderId);

        try {
            // Broadcast order acceptance
            messagingTemplate.convertAndSend("/topic/delivery/orders", Map.of(
                "type", "ORDER_ACCEPTED",
                "orderId", orderId,
                "partnerId", partnerId,
                "timestamp", LocalDateTime.now()
            ));

            // Send confirmation to partner
            messagingTemplate.convertAndSendToUser(
                partnerId.toString(),
                "/queue/partner/orders",
                Map.of(
                    "type", "ORDER_ACCEPTED_CONFIRMATION",
                    "orderId", orderId,
                    "message", "Order accepted successfully",
                    "timestamp", LocalDateTime.now()
                )
            );

        } catch (Exception e) {
            log.error("Error accepting order: {}", e.getMessage());
            messagingTemplate.convertAndSendToUser(
                partnerId.toString(),
                "/queue/partner/error",
                Map.of(
                    "error", "Failed to accept order",
                    "orderId", orderId,
                    "message", e.getMessage(),
                    "timestamp", LocalDateTime.now()
                )
            );
        }
    }

    /**
     * Handle order status updates from delivery partner
     */
    @MessageMapping("/partner/{partnerId}/order/{orderId}/status")
    public void updateOrderStatus(@DestinationVariable Long partnerId,
                                 @DestinationVariable Long orderId,
                                 @Payload Map<String, Object> statusUpdate) {
        log.info("Partner {} updating order {} status: {}", partnerId, orderId, statusUpdate);

        try {
            String newStatus = (String) statusUpdate.get("status");
            String location = (String) statusUpdate.get("location");
            String notes = (String) statusUpdate.get("notes");

            // Broadcast order status update
            messagingTemplate.convertAndSend("/topic/delivery/orders", Map.of(
                "type", "ORDER_STATUS_UPDATE",
                "orderId", orderId,
                "partnerId", partnerId,
                "status", newStatus,
                "location", location,
                "notes", notes,
                "timestamp", LocalDateTime.now()
            ));

            // Send confirmation to partner
            messagingTemplate.convertAndSendToUser(
                partnerId.toString(),
                "/queue/partner/orders",
                Map.of(
                    "type", "ORDER_STATUS_UPDATE_CONFIRMATION",
                    "orderId", orderId,
                    "status", newStatus,
                    "message", "Order status updated successfully",
                    "timestamp", LocalDateTime.now()
                )
            );

        } catch (Exception e) {
            log.error("Error updating order status: {}", e.getMessage());
            messagingTemplate.convertAndSendToUser(
                partnerId.toString(),
                "/queue/partner/error",
                Map.of(
                    "error", "Failed to update order status",
                    "orderId", orderId,
                    "message", e.getMessage(),
                    "timestamp", LocalDateTime.now()
                )
            );
        }
    }

    /**
     * Handle location updates from delivery partner
     */
    @MessageMapping("/partner/{partnerId}/location")
    public void updateLocation(@DestinationVariable Long partnerId, @Payload Map<String, Object> locationData) {
        log.debug("Partner {} location update: lat={}, lng={}",
                 partnerId, locationData.get("latitude"), locationData.get("longitude"));

        try {
            Double latitude = ((Number) locationData.get("latitude")).doubleValue();
            Double longitude = ((Number) locationData.get("longitude")).doubleValue();
            Double accuracy = locationData.get("accuracy") != null ?
                ((Number) locationData.get("accuracy")).doubleValue() : null;
            Double speed = locationData.get("speed") != null ?
                ((Number) locationData.get("speed")).doubleValue() : null;
            Long orderId = locationData.get("orderId") != null ?
                ((Number) locationData.get("orderId")).longValue() : null;

            // Broadcast location update for real-time tracking
            messagingTemplate.convertAndSend("/topic/tracking/location", Map.of(
                "partnerId", partnerId,
                "latitude", latitude,
                "longitude", longitude,
                "accuracy", accuracy,
                "speed", speed,
                "orderId", orderId,
                "timestamp", LocalDateTime.now()
            ));

            // If there's an active order, send specific tracking update
            if (orderId != null) {
                messagingTemplate.convertAndSend("/topic/tracking/order/" + orderId, Map.of(
                    "partnerId", partnerId,
                    "latitude", latitude,
                    "longitude", longitude,
                    "timestamp", LocalDateTime.now()
                ));
            }

        } catch (Exception e) {
            log.error("Error processing location update: {}", e.getMessage());
            messagingTemplate.convertAndSendToUser(
                partnerId.toString(),
                "/queue/partner/error",
                Map.of(
                    "error", "Failed to process location update",
                    "message", e.getMessage(),
                    "timestamp", LocalDateTime.now()
                )
            );
        }
    }

    /**
     * Handle emergency alerts from delivery partner
     */
    @MessageMapping("/partner/{partnerId}/emergency")
    public void handleEmergency(@DestinationVariable Long partnerId, @Payload Map<String, Object> emergencyData) {
        log.warn("EMERGENCY alert from partner {}: {}", partnerId, emergencyData);

        try {
            String emergencyType = (String) emergencyData.get("type");
            String message = (String) emergencyData.get("message");
            Double latitude = emergencyData.get("latitude") != null ?
                ((Number) emergencyData.get("latitude")).doubleValue() : null;
            Double longitude = emergencyData.get("longitude") != null ?
                ((Number) emergencyData.get("longitude")).doubleValue() : null;

            // Broadcast emergency alert to admin and support
            messagingTemplate.convertAndSend("/topic/delivery/emergency", Map.of(
                "partnerId", partnerId,
                "type", emergencyType,
                "message", message,
                "latitude", latitude,
                "longitude", longitude,
                "timestamp", LocalDateTime.now(),
                "priority", "URGENT"
            ));

            // Send immediate response to partner
            messagingTemplate.convertAndSendToUser(
                partnerId.toString(),
                "/queue/partner/emergency",
                Map.of(
                    "status", "received",
                    "message", "Emergency alert received. Help is on the way.",
                    "timestamp", LocalDateTime.now()
                )
            );

        } catch (Exception e) {
            log.error("Error handling emergency alert: {}", e.getMessage());
        }
    }

    /**
     * Send notification to specific partner
     */
    @MessageMapping("/admin/notify-partner")
    public void notifyPartner(@Payload Map<String, Object> notificationData) {
        log.info("Admin notification to partner: {}", notificationData);

        try {
            Long partnerId = ((Number) notificationData.get("partnerId")).longValue();
            String title = (String) notificationData.get("title");
            String message = (String) notificationData.get("message");
            String type = (String) notificationData.get("type");
            Object data = notificationData.get("data");

            messagingTemplate.convertAndSendToUser(
                partnerId.toString(),
                "/queue/partner/notifications",
                Map.of(
                    "title", title,
                    "message", message,
                    "type", type,
                    "data", data,
                    "timestamp", LocalDateTime.now()
                )
            );

        } catch (Exception e) {
            log.error("Error sending notification to partner: {}", e.getMessage());
        }
    }

    /**
     * Broadcast announcement to all partners
     */
    @MessageMapping("/admin/broadcast")
    @SendTo("/topic/delivery/announcements")
    public Map<String, Object> broadcastAnnouncement(@Payload Map<String, Object> announcement) {
        log.info("Broadcasting announcement: {}", announcement);

        announcement.put("timestamp", LocalDateTime.now());
        return announcement;
    }

    /**
     * Handle partner ping/heartbeat
     */
    @MessageMapping("/partner/{partnerId}/ping")
    public void handlePing(@DestinationVariable Long partnerId) {
        messagingTemplate.convertAndSendToUser(
            partnerId.toString(),
            "/queue/partner/pong",
            Map.of(
                "message", "pong",
                "timestamp", LocalDateTime.now()
            )
        );
    }
}