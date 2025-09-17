package com.shopmanagement.service;

import com.shopmanagement.entity.Order;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
@Slf4j
public class DeliveryConfirmationService {

    private final OrderService orderService;
    private final FileUploadService fileUploadService;
    private final NotificationService notificationService;
    private final EmailService emailService;

    // In-memory OTP storage (in production, use Redis or database)
    private final Map<String, OTPData> otpStorage = new ConcurrentHashMap<>();
    private final Random random = new Random();

    /**
     * Generate OTP for pickup confirmation
     */
    public String generatePickupOTP(Long orderId) {
        try {
            String otp = String.format("%06d", random.nextInt(1000000));
            String otpKey = "pickup_" + orderId;

            OTPData otpData = OTPData.builder()
                .otp(otp)
                .orderId(orderId)
                .type("PICKUP")
                .generatedAt(LocalDateTime.now())
                .expiresAt(LocalDateTime.now().plusMinutes(10)) // 10 minutes expiry
                .attempts(0)
                .build();

            otpStorage.put(otpKey, otpData);

            log.info("Generated pickup OTP for order {}: {}", orderId, otp);

            // Send OTP to customer via SMS/Email
            sendPickupOTPToCustomer(orderId, otp);

            return otp;
        } catch (Exception e) {
            log.error("Error generating pickup OTP for order {}: {}", orderId, e.getMessage());
            throw new RuntimeException("Failed to generate pickup OTP", e);
        }
    }

    /**
     * Generate OTP for delivery confirmation
     */
    public String generateDeliveryOTP(Long orderId) {
        try {
            String otp = String.format("%06d", random.nextInt(1000000));
            String otpKey = "delivery_" + orderId;

            OTPData otpData = OTPData.builder()
                .otp(otp)
                .orderId(orderId)
                .type("DELIVERY")
                .generatedAt(LocalDateTime.now())
                .expiresAt(LocalDateTime.now().plusMinutes(15)) // 15 minutes expiry
                .attempts(0)
                .build();

            otpStorage.put(otpKey, otpData);

            log.info("Generated delivery OTP for order {}: {}", orderId, otp);

            // Send OTP to customer via SMS/Email
            sendDeliveryOTPToCustomer(orderId, otp);

            return otp;
        } catch (Exception e) {
            log.error("Error generating delivery OTP for order {}: {}", orderId, e.getMessage());
            throw new RuntimeException("Failed to generate delivery OTP", e);
        }
    }

    /**
     * Validate pickup OTP and confirm pickup
     */
    @Transactional
    public DeliveryConfirmationResponse confirmPickup(Long orderId, String otp, MultipartFile pickupPhoto) {
        try {
            String otpKey = "pickup_" + orderId;

            if (!validateOTP(otpKey, otp)) {
                return DeliveryConfirmationResponse.builder()
                    .success(false)
                    .message("Invalid or expired OTP")
                    .build();
            }

            // Upload pickup photo
            String photoUrl = null;
            if (pickupPhoto != null && !pickupPhoto.isEmpty()) {
                photoUrl = fileUploadService.uploadDeliveryProof(pickupPhoto, orderId, "pickup");
            }

            // Update order status to OUT_FOR_DELIVERY
            orderService.updateOrderStatus(orderId, Order.OrderStatus.OUT_FOR_DELIVERY);

            // Save pickup confirmation details
            savePickupConfirmation(orderId, photoUrl);

            // Remove OTP from storage
            otpStorage.remove(otpKey);

            // Send notifications
            // TODO: Fix notification service method
            // notificationService.notifyOrderStatusChange(orderId, "ACCEPTED", "PICKED_UP",
            //     Map.of("pickupPhotoUrl", photoUrl));

            log.info("Pickup confirmed for order {}", orderId);

            return DeliveryConfirmationResponse.builder()
                .success(true)
                .message("Pickup confirmed successfully")
                .photoUrl(photoUrl)
                .timestamp(LocalDateTime.now())
                .build();

        } catch (Exception e) {
            log.error("Error confirming pickup for order {}: {}", orderId, e.getMessage());
            throw new RuntimeException("Failed to confirm pickup", e);
        }
    }

    /**
     * Validate delivery OTP and confirm delivery
     */
    @Transactional
    public DeliveryConfirmationResponse confirmDelivery(DeliveryConfirmationRequest request) {
        try {
            String otpKey = "delivery_" + request.getOrderId();

            if (!validateOTP(otpKey, request.getOtp())) {
                return DeliveryConfirmationResponse.builder()
                    .success(false)
                    .message("Invalid or expired OTP")
                    .build();
            }

            // Upload delivery photos and signature
            String deliveryPhotoUrl = null;
            String signatureUrl = null;

            if (request.getDeliveryPhoto() != null && !request.getDeliveryPhoto().isEmpty()) {
                deliveryPhotoUrl = fileUploadService.uploadDeliveryProof(
                    request.getDeliveryPhoto(), request.getOrderId(), "delivery");
            }

            if (request.getSignature() != null && !request.getSignature().isEmpty()) {
                signatureUrl = fileUploadService.uploadDeliveryProof(
                    request.getSignature(), request.getOrderId(), "signature");
            }

            // Update order status to DELIVERED
            orderService.updateOrderStatus(request.getOrderId(), Order.OrderStatus.DELIVERED);

            // Save delivery confirmation details
            saveDeliveryConfirmation(request, deliveryPhotoUrl, signatureUrl);

            // Remove OTP from storage
            otpStorage.remove(otpKey);

            // Send notifications
            // TODO: Fix notification service method
            // notificationService.notifyOrderStatusChange(request.getOrderId(), "IN_TRANSIT", "DELIVERED",
            //     Map.of(
            //         "deliveryPhotoUrl", deliveryPhotoUrl,
            //         "signatureUrl", signatureUrl,
            //         "customerName", request.getCustomerName(),
            //         "deliveryNotes", request.getDeliveryNotes()
            //     ));

            log.info("Delivery confirmed for order {}", request.getOrderId());

            return DeliveryConfirmationResponse.builder()
                .success(true)
                .message("Delivery confirmed successfully")
                .photoUrl(deliveryPhotoUrl)
                .signatureUrl(signatureUrl)
                .timestamp(LocalDateTime.now())
                .build();

        } catch (Exception e) {
            log.error("Error confirming delivery for order {}: {}", request.getOrderId(), e.getMessage());
            throw new RuntimeException("Failed to confirm delivery", e);
        }
    }

    /**
     * Validate OTP
     */
    private boolean validateOTP(String otpKey, String otp) {
        OTPData otpData = otpStorage.get(otpKey);

        if (otpData == null) {
            log.warn("OTP not found for key: {}", otpKey);
            return false;
        }

        if (LocalDateTime.now().isAfter(otpData.getExpiresAt())) {
            log.warn("OTP expired for key: {}", otpKey);
            otpStorage.remove(otpKey);
            return false;
        }

        if (otpData.getAttempts() >= 3) {
            log.warn("Max OTP attempts exceeded for key: {}", otpKey);
            otpStorage.remove(otpKey);
            return false;
        }

        if (!otp.equals(otpData.getOtp())) {
            otpData.setAttempts(otpData.getAttempts() + 1);
            log.warn("Invalid OTP attempt {} for key: {}", otpData.getAttempts(), otpKey);
            return false;
        }

        return true;
    }

    /**
     * Send pickup OTP to customer
     */
    private void sendPickupOTPToCustomer(Long orderId, String otp) {
        try {
            // TODO: Get customer details from order
            String customerEmail = "customer@example.com"; // Get from order
            String customerPhone = "+1234567890"; // Get from order

            String message = String.format(
                "Your pickup OTP for order #%d is: %s. Please share this with the delivery partner for pickup confirmation.",
                orderId, otp
            );

            // Send email
            emailService.sendSimpleEmail(customerEmail, "Pickup OTP - Order #" + orderId, message);

            // TODO: Send SMS via SMS service
            log.info("Pickup OTP sent to customer for order {}", orderId);

        } catch (Exception e) {
            log.error("Error sending pickup OTP to customer for order {}: {}", orderId, e.getMessage());
        }
    }

    /**
     * Send delivery OTP to customer
     */
    private void sendDeliveryOTPToCustomer(Long orderId, String otp) {
        try {
            // TODO: Get customer details from order
            String customerEmail = "customer@example.com"; // Get from order
            String customerPhone = "+1234567890"; // Get from order

            String message = String.format(
                "Your delivery OTP for order #%d is: %s. Please share this with the delivery partner for delivery confirmation.",
                orderId, otp
            );

            // Send email
            emailService.sendSimpleEmail(customerEmail, "Delivery OTP - Order #" + orderId, message);

            // TODO: Send SMS via SMS service
            log.info("Delivery OTP sent to customer for order {}", orderId);

        } catch (Exception e) {
            log.error("Error sending delivery OTP to customer for order {}: {}", orderId, e.getMessage());
        }
    }

    /**
     * Save pickup confirmation details
     */
    private void savePickupConfirmation(Long orderId, String photoUrl) {
        // TODO: Implement database storage for pickup confirmation
        log.info("Pickup confirmation saved for order {} with photo: {}", orderId, photoUrl);
    }

    /**
     * Save delivery confirmation details
     */
    private void saveDeliveryConfirmation(DeliveryConfirmationRequest request, String photoUrl, String signatureUrl) {
        // TODO: Implement database storage for delivery confirmation
        log.info("Delivery confirmation saved for order {} with photo: {} and signature: {}",
            request.getOrderId(), photoUrl, signatureUrl);
    }

    /**
     * Get delivery proof for an order
     */
    public DeliveryProofResponse getDeliveryProof(Long orderId) {
        try {
            // TODO: Fetch from database
            return DeliveryProofResponse.builder()
                .orderId(orderId)
                .pickupPhotoUrl("pickup_photo_url")
                .deliveryPhotoUrl("delivery_photo_url")
                .signatureUrl("signature_url")
                .pickupTimestamp(LocalDateTime.now().minusHours(2))
                .deliveryTimestamp(LocalDateTime.now())
                .build();

        } catch (Exception e) {
            log.error("Error fetching delivery proof for order {}: {}", orderId, e.getMessage());
            throw new RuntimeException("Failed to fetch delivery proof", e);
        }
    }

    /**
     * Resend OTP
     */
    public void resendOTP(Long orderId, String type) {
        try {
            if ("PICKUP".equalsIgnoreCase(type)) {
                generatePickupOTP(orderId);
            } else if ("DELIVERY".equalsIgnoreCase(type)) {
                generateDeliveryOTP(orderId);
            } else {
                throw new IllegalArgumentException("Invalid OTP type: " + type);
            }

            log.info("OTP resent for order {} with type {}", orderId, type);
        } catch (Exception e) {
            log.error("Error resending OTP for order {}: {}", orderId, e.getMessage());
            throw new RuntimeException("Failed to resend OTP", e);
        }
    }

    // DTO Classes
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DeliveryConfirmationRequest {
        private Long orderId;
        private String otp;
        private MultipartFile deliveryPhoto;
        private MultipartFile signature;
        private String customerName;
        private String deliveryNotes;
        private Double latitude;
        private Double longitude;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DeliveryConfirmationResponse {
        private boolean success;
        private String message;
        private String photoUrl;
        private String signatureUrl;
        private LocalDateTime timestamp;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DeliveryProofResponse {
        private Long orderId;
        private String pickupPhotoUrl;
        private String deliveryPhotoUrl;
        private String signatureUrl;
        private LocalDateTime pickupTimestamp;
        private LocalDateTime deliveryTimestamp;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    private static class OTPData {
        private String otp;
        private Long orderId;
        private String type;
        private LocalDateTime generatedAt;
        private LocalDateTime expiresAt;
        private int attempts;
    }
}