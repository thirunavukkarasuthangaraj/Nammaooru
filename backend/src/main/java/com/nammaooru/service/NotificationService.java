package com.nammaooru.service;

import com.google.firebase.messaging.*;
import com.nammaooru.entity.Order;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final FirebaseMessaging firebaseMessaging;
    private final EmailService emailService;

    // Send order placed notifications
    public void sendOrderPlacedNotifications(Order order, String customerOTP) {
        try {
            // 1. Firebase notification to customer
            sendFirebaseNotification(
                order.getCustomerFcmToken(),
                "Order Confirmed! 🎉",
                String.format("Your order #%s has been placed successfully!", order.getOrderNumber()),
                Map.of(
                    "type", "ORDER_PLACED",
                    "orderId", order.getId().toString(),
                    "orderNumber", order.getOrderNumber()
                )
            );

            // 2. Firebase notification to shop owner
            sendFirebaseNotification(
                order.getShop().getOwnerFcmToken(),
                "New Order Received!",
                String.format("Order #%s from %s", order.getOrderNumber(), order.getCustomerName()),
                Map.of(
                    "type", "NEW_ORDER",
                    "orderId", order.getId().toString(),
                    "orderNumber", order.getOrderNumber()
                )
            );

            log.info("Order placed notifications sent for order {}", order.getOrderNumber());
        } catch (Exception e) {
            log.error("Error sending order placed notifications: ", e);
        }
    }

    // Send order accepted notifications
    public void sendOrderAcceptedNotifications(Order order, String shopOTP) {
        try {
            // Firebase notification to customer
            sendFirebaseNotification(
                order.getCustomerFcmToken(),
                "Order Accepted! ✅",
                String.format("Your order #%s has been accepted by the shop", order.getOrderNumber()),
                Map.of(
                    "type", "ORDER_ACCEPTED",
                    "orderId", order.getId().toString(),
                    "shopOTP", shopOTP
                )
            );

            // Email to customer with shop OTP
            emailService.sendOrderStatusUpdate(
                order.getCustomerEmail(),
                order.getOrderNumber(),
                "ACCEPTED",
                "Your order has been accepted and is being prepared",
                shopOTP
            );

            // Notify assigned delivery partner if any
            if (order.getDeliveryPartner() != null) {
                sendFirebaseNotification(
                    order.getDeliveryPartner().getFcmToken(),
                    "New Delivery Assignment",
                    String.format("Order #%s ready for pickup", order.getOrderNumber()),
                    Map.of(
                        "type", "DELIVERY_ASSIGNMENT",
                        "orderId", order.getId().toString(),
                        "pickupOTP", shopOTP
                    )
                );
            }

            log.info("Order accepted notifications sent for order {}", order.getOrderNumber());
        } catch (Exception e) {
            log.error("Error sending order accepted notifications: ", e);
        }
    }

    // Send order rejected notifications
    public void sendOrderRejectedNotifications(Order order, String reason) {
        try {
            // Firebase notification to customer
            sendFirebaseNotification(
                order.getCustomerFcmToken(),
                "Order Rejected",
                String.format("Your order #%s has been rejected. Reason: %s", order.getOrderNumber(), reason),
                Map.of(
                    "type", "ORDER_REJECTED",
                    "orderId", order.getId().toString(),
                    "reason", reason
                )
            );

            // Email to customer
            emailService.sendOrderStatusUpdate(
                order.getCustomerEmail(),
                order.getOrderNumber(),
                "REJECTED",
                String.format("We're sorry, your order has been rejected. Reason: %s", reason),
                null
            );

            log.info("Order rejected notifications sent for order {}", order.getOrderNumber());
        } catch (Exception e) {
            log.error("Error sending order rejected notifications: ", e);
        }
    }

    // Send order status notification
    public void sendOrderStatusNotification(Order order) {
        try {
            String title = getStatusTitle(order.getStatus());
            String body = getStatusMessage(order.getStatus(), order.getOrderNumber());

            // Send to customer
            sendFirebaseNotification(
                order.getCustomerFcmToken(),
                title,
                body,
                Map.of(
                    "type", "STATUS_UPDATE",
                    "orderId", order.getId().toString(),
                    "status", order.getStatus()
                )
            );

            // Special handling for specific statuses
            switch (order.getStatus()) {
                case "OUT_FOR_DELIVERY":
                    // Send delivery OTP to customer
                    Map<String, String> otps = getOrderOTPs(order.getId());
                    if (otps.containsKey("customerOTP")) {
                        emailService.sendDeliveryNotification(
                            order.getCustomerEmail(),
                            order.getOrderNumber(),
                            getTrackingUrl(order.getOrderNumber()),
                            otps.get("customerOTP")
                        );
                    }
                    break;
                    
                case "DELIVERED":
                    // Send invoice
                    CompletableFuture.runAsync(() -> sendInvoice(order));
                    break;
            }

            log.info("Status notification sent for order {} - {}", order.getOrderNumber(), order.getStatus());
        } catch (Exception e) {
            log.error("Error sending status notification: ", e);
        }
    }

    // Send order cancellation notification
    public void sendOrderCancellationNotification(Order order, String reason) {
        try {
            sendFirebaseNotification(
                order.getCustomerFcmToken(),
                "Order Cancelled",
                String.format("Your order #%s has been cancelled. Reason: %s", order.getOrderNumber(), reason),
                Map.of(
                    "type", "ORDER_CANCELLED",
                    "orderId", order.getId().toString(),
                    "reason", reason
                )
            );

            log.info("Cancellation notification sent for order {}", order.getOrderNumber());
        } catch (Exception e) {
            log.error("Error sending cancellation notification: ", e);
        }
    }

    // Send Firebase push notification
    private void sendFirebaseNotification(String token, String title, String body, Map<String, String> data) {
        if (token == null || token.isEmpty()) {
            log.warn("FCM token is null or empty, skipping Firebase notification");
            return;
        }

        try {
            Message message = Message.builder()
                .setToken(token)
                .setNotification(Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build())
                .putAllData(data)
                .setAndroidConfig(AndroidConfig.builder()
                    .setPriority(AndroidConfig.Priority.HIGH)
                    .setNotification(AndroidNotification.builder()
                        .setSound("default")
                        .build())
                    .build())
                .setApnsConfig(ApnsConfig.builder()
                    .setAps(Aps.builder()
                        .setSound("default")
                        .build())
                    .build())
                .build();

            String response = firebaseMessaging.send(message);
            log.debug("Firebase notification sent successfully: {}", response);
        } catch (Exception e) {
            log.error("Error sending Firebase notification to token {}: ", token, e);
        }
    }

    // Send invoice after delivery
    private void sendInvoice(Order order) {
        try {
            InvoiceData invoice = InvoiceData.builder()
                .orderNumber(order.getOrderNumber())
                .customerName(order.getCustomerName())
                .customerEmail(order.getCustomerEmail())
                .shopName(order.getShop().getName())
                .items(convertToInvoiceItems(order.getOrderItems()))
                .subtotal(order.getSubtotal())
                .deliveryFee(order.getDeliveryFee())
                .discount(order.getDiscountAmount())
                .total(order.getTotalAmount())
                .deliveryAddress(order.getDeliveryAddress())
                .orderDate(order.getCreatedAt())
                .deliveryDate(order.getDeliveredAt())
                .build();

            emailService.sendInvoiceEmail(order.getCustomerEmail(), invoice);
            log.info("Invoice sent for order {}", order.getOrderNumber());
        } catch (Exception e) {
            log.error("Error sending invoice for order {}: ", order.getOrderNumber(), e);
        }
    }

    // Helper methods
    private String getStatusTitle(String status) {
        return switch (status) {
            case "CONFIRMED" -> "Order Confirmed! ✅";
            case "PREPARING" -> "Order Being Prepared 👨‍🍳";
            case "READY_FOR_PICKUP" -> "Ready for Pickup 📦";
            case "OUT_FOR_DELIVERY" -> "Out for Delivery 🚚";
            case "DELIVERED" -> "Delivered Successfully! 🎉";
            default -> "Order Update";
        };
    }

    private String getStatusMessage(String status, String orderNumber) {
        return switch (status) {
            case "CONFIRMED" -> String.format("Your order #%s has been confirmed", orderNumber);
            case "PREPARING" -> String.format("Your order #%s is being prepared", orderNumber);
            case "READY_FOR_PICKUP" -> String.format("Your order #%s is ready for pickup", orderNumber);
            case "OUT_FOR_DELIVERY" -> String.format("Your order #%s is on the way!", orderNumber);
            case "DELIVERED" -> String.format("Your order #%s has been delivered. Thank you!", orderNumber);
            default -> String.format("Your order #%s status: %s", orderNumber, status);
        };
    }

    private String getTrackingUrl(String orderNumber) {
        return String.format("https://nammaooru.com/track/%s", orderNumber);
    }

    private Map<String, String> getOrderOTPs(Long orderId) {
        // This should call OTPService to get OTPs
        return new HashMap<>();
    }

    private List<InvoiceItem> convertToInvoiceItems(List<OrderItem> orderItems) {
        // Convert order items to invoice items
        return orderItems.stream()
            .map(item -> {
                InvoiceItem invoiceItem = new InvoiceItem();
                invoiceItem.setProductName(item.getProductName());
                invoiceItem.setQuantity(item.getQuantity());
                invoiceItem.setPrice(item.getUnitPrice());
                invoiceItem.setUnit(item.getUnit());
                invoiceItem.setTotal(item.getTotalPrice());
                return invoiceItem;
            })
            .toList();
    }
}