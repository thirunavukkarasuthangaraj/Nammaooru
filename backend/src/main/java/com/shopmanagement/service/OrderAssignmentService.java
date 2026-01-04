package com.shopmanagement.service;

import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderAssignment;
import com.shopmanagement.entity.OrderAssignment.AssignmentStatus;
import com.shopmanagement.entity.OrderAssignment.AssignmentType;
import com.shopmanagement.entity.User;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.repository.OrderAssignmentRepository;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.repository.UserFcmTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class OrderAssignmentService {

    private final OrderAssignmentRepository assignmentRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final UserFcmTokenRepository userFcmTokenRepository;
    private final EmailService emailService;
    private final DeliveryFeeService deliveryFeeService;
    private final FirebaseNotificationService firebaseNotificationService;

    // Active assignment statuses
    private static final List<AssignmentStatus> ACTIVE_STATUSES = Arrays.asList(
        AssignmentStatus.ASSIGNED,
        AssignmentStatus.ACCEPTED,
        AssignmentStatus.PICKED_UP,
        AssignmentStatus.IN_TRANSIT
    );

    /**
     * Automatically assign an order to an available delivery partner
     */
    @Transactional
    public OrderAssignment autoAssignOrder(Long orderId, Long assignedByUserId) {
        log.info("Auto-assigning order {} by user {}", orderId, assignedByUserId);

        // Get the order
        Order order = orderRepository.findById(orderId)
            .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));

        // Skip status check for auto-assignment - we know it's triggered when READY_FOR_PICKUP
        log.info("Auto-assignment triggered for order {} with status: {}", order.getOrderNumber(), order.getStatus());

        // Check if order is already assigned
        Optional<OrderAssignment> existingAssignment = findActiveAssignmentByOrderId(orderId);
        if (existingAssignment.isPresent()) {
            throw new RuntimeException("Order is already assigned to a delivery partner");
        }

        // Get all ONLINE and ACTIVE partners (regardless of availability - they can handle multiple orders)
        List<User> availablePartners = userRepository.findByRoleAndIsActiveAndIsAvailableAndIsOnline(
            User.UserRole.DELIVERY_PARTNER, true, true, true);

        if (availablePartners.isEmpty()) {
            throw new RuntimeException("No available delivery partners found");
        }

        log.info("Found {} online delivery partners (allowing multiple orders per partner)", availablePartners.size());

        // Select partner using FAIR DISTRIBUTION (least busy driver gets the order)
        User selectedPartner = selectBestAvailablePartner(availablePartners);
        log.info("Selected delivery partner: {} (ID: {}) from {} available partners",
            selectedPartner.getEmail(), selectedPartner.getId(), availablePartners.size());
        User assignedBy = userRepository.findById(assignedByUserId)
            .orElseThrow(() -> new RuntimeException("Assigned by user not found: " + assignedByUserId));

        // Calculate delivery fee and commission based on distance
        BigDecimal deliveryFee = order.getDeliveryFee();
        if (deliveryFee == null || deliveryFee.compareTo(BigDecimal.ZERO) == 0) {
            // Calculate distance-based fee if not already calculated
            Double distance = calculateOrderDistance(order);
            deliveryFee = deliveryFeeService.calculateDeliveryFee(distance);
            order.setDeliveryFee(deliveryFee);
            orderRepository.save(order);
            log.info("Calculated delivery fee for order {}: ₹{} for {}km", order.getId(), deliveryFee, distance);
        }

        BigDecimal partnerCommission = calculatePartnerCommission(deliveryFee);

        // Create assignment
        LocalDateTime now = LocalDateTime.now();
        OrderAssignment assignment = OrderAssignment.builder()
            .order(order)
            .deliveryPartner(selectedPartner)
            .assignedBy(assignedBy)
            .status(AssignmentStatus.ASSIGNED)
            .assignmentType(AssignmentType.AUTO)
            .assignedAt(now)
            .deliveryFee(deliveryFee)
            .partnerCommission(partnerCommission)
            .assignmentNotes("Auto-assigned to nearest available partner")
            .createdBy("system")
            .updatedBy("system")
            .build();

        // Explicitly set timestamps (Hibernate annotations not working reliably)
        assignment.setCreatedAt(now);
        assignment.setUpdatedAt(now);

        assignment = assignmentRepository.save(assignment);

        // DON'T update order status yet - driver needs to accept first
        // Order stays as READY_FOR_PICKUP until driver accepts
        log.info("Order {} assigned to driver, waiting for driver acceptance", order.getOrderNumber());

        // DON'T make partner unavailable yet - they need to accept first
        // Partner availability will be updated when they accept the order
        selectedPartner.setLastActivity(LocalDateTime.now());
        userRepository.save(selectedPartner);

        // Send push notification to assigned delivery partner
        try {
            log.info("🔔 Sending assignment notification to partner: {}", selectedPartner.getEmail());

            // Get FCM token for the delivery partner
            String fcmToken = userFcmTokenRepository.findByUserIdAndIsActiveTrue(selectedPartner.getId())
                .stream()
                .findFirst()
                .map(UserFcmToken::getFcmToken)
                .orElse(null);

            if (fcmToken != null && !fcmToken.isEmpty()) {
                log.info("📱 Found FCM token for partner {}, sending notification", selectedPartner.getEmail());

                // Send Firebase notification to driver with proper title, sound, and details
                firebaseNotificationService.sendOrderAssignmentNotificationToDriver(
                    order.getOrderNumber(),
                    fcmToken,
                    selectedPartner.getId(),
                    order.getShop().getName(),
                    order.getDeliveryAddress(),
                    deliveryFee.doubleValue()
                );

                log.info("✅ Assignment notification sent successfully to partner: {}", selectedPartner.getEmail());
            } else {
                log.warn("❌ No FCM token found for delivery partner: {} (ID: {})",
                    selectedPartner.getEmail(), selectedPartner.getId());
            }
        } catch (Exception e) {
            log.error("❌ Failed to send assignment notification to partner {}: {}",
                selectedPartner.getEmail(), e.getMessage(), e);
            // Don't fail the assignment if notification fails
        }

        log.info("Order {} auto-assigned to partner {} (ID: {})",
                 orderId, selectedPartner.getEmail(), selectedPartner.getId());

        return assignment;
    }

    /**
     * Manually assign an order to a specific delivery partner
     */
    @Transactional
    public OrderAssignment manualAssignOrder(Long orderId, Long deliveryPartnerId, Long assignedByUserId) {
        log.info("Manually assigning order {} to partner {} by user {}", orderId, deliveryPartnerId, assignedByUserId);

        // Get the order
        Order order = orderRepository.findById(orderId)
            .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));

        // Get the delivery partner
        User deliveryPartner = userRepository.findById(deliveryPartnerId)
            .orElseThrow(() -> new RuntimeException("Delivery partner not found: " + deliveryPartnerId));

        // Validate partner role
        if (deliveryPartner.getRole() != User.UserRole.DELIVERY_PARTNER) {
            throw new RuntimeException("User is not a delivery partner");
        }

        // Get assigned by user
        User assignedBy = userRepository.findById(assignedByUserId)
            .orElseThrow(() -> new RuntimeException("Assigned by user not found: " + assignedByUserId));

        // Check if order is ready for pickup
        if (order.getStatus() != Order.OrderStatus.READY_FOR_PICKUP) {
            throw new RuntimeException("Order is not ready for pickup. Current status: " + order.getStatus());
        }

        // Check if order is already assigned
        Optional<OrderAssignment> existingAssignment = findActiveAssignmentByOrderId(orderId);
        if (existingAssignment.isPresent()) {
            throw new RuntimeException("Order is already assigned to a delivery partner");
        }

        // Calculate delivery fee and commission based on distance
        BigDecimal deliveryFee = order.getDeliveryFee();
        if (deliveryFee == null || deliveryFee.compareTo(BigDecimal.ZERO) == 0) {
            // Calculate distance-based fee if not already calculated
            Double distance = calculateOrderDistance(order);
            deliveryFee = deliveryFeeService.calculateDeliveryFee(distance);
            order.setDeliveryFee(deliveryFee);
            orderRepository.save(order);
            log.info("Calculated delivery fee for order {}: ₹{} for {}km", order.getId(), deliveryFee, distance);
        }

        BigDecimal partnerCommission = calculatePartnerCommission(deliveryFee);

        // Create assignment
        OrderAssignment assignment = OrderAssignment.builder()
            .order(order)
            .deliveryPartner(deliveryPartner)
            .assignedBy(assignedBy)
            .status(AssignmentStatus.ASSIGNED)
            .assignmentType(AssignmentType.MANUAL)
            .deliveryFee(deliveryFee)
            .partnerCommission(partnerCommission)
            .assignmentNotes("Manually assigned by " + assignedBy.getEmail())
            .build();

        assignment = assignmentRepository.save(assignment);

        // Update order status
        order.setStatus(Order.OrderStatus.OUT_FOR_DELIVERY);
        orderRepository.save(order);

        // Update partner availability (make them busy)
        deliveryPartner.setIsAvailable(false);
        deliveryPartner.setRideStatus(User.RideStatus.ON_RIDE);
        deliveryPartner.setLastActivity(LocalDateTime.now());
        userRepository.save(deliveryPartner);

        // Send push notification to manually assigned delivery partner
        try {
            log.info("🔔 Sending manual assignment notification to partner: {}", deliveryPartner.getEmail());

            // Get FCM token for the delivery partner
            String fcmToken = userFcmTokenRepository.findByUserIdAndIsActiveTrue(deliveryPartner.getId())
                .stream()
                .findFirst()
                .map(UserFcmToken::getFcmToken)
                .orElse(null);

            if (fcmToken != null && !fcmToken.isEmpty()) {
                log.info("📱 Found FCM token for partner {}, sending manual assignment notification", deliveryPartner.getEmail());

                // Send Firebase notification
                firebaseNotificationService.sendOrderNotification(
                    order.getOrderNumber(),
                    "MANUAL_ASSIGNMENT",
                    fcmToken,
                    null // No customer ID for driver notifications
                );

                log.info("✅ Manual assignment notification sent successfully to partner: {}", deliveryPartner.getEmail());
            } else {
                log.warn("❌ No FCM token found for delivery partner: {} (ID: {})",
                    deliveryPartner.getEmail(), deliveryPartner.getId());
            }
        } catch (Exception e) {
            log.error("❌ Failed to send manual assignment notification to partner {}: {}",
                deliveryPartner.getEmail(), e.getMessage(), e);
            // Don't fail the assignment if notification fails
        }

        log.info("Order {} manually assigned to partner {} (ID: {})",
                 orderId, deliveryPartner.getEmail(), deliveryPartner.getId());

        return assignment;
    }

    /**
     * Accept an assignment (called by delivery partner)
     */
    @Transactional
    public OrderAssignment acceptAssignment(Long assignmentId, Long partnerId) {
        log.info("Partner {} accepting assignment {}", partnerId, assignmentId);

        OrderAssignment assignment = assignmentRepository.findById(assignmentId)
            .orElseThrow(() -> new RuntimeException("Assignment not found: " + assignmentId));

        // Validate partner
        if (!assignment.getDeliveryPartner().getId().equals(partnerId)) {
            throw new RuntimeException("Assignment does not belong to this partner");
        }

        // Accept the assignment
        assignment.accept();
        assignment = assignmentRepository.save(assignment);

        // Update order status to OUT_FOR_DELIVERY (driver accepted and will pick up)
        Order order = assignment.getOrder();
        // Keep order as READY_FOR_PICKUP until driver actually picks up
        // order.setStatus(Order.OrderStatus.OUT_FOR_DELIVERY);
        orderRepository.save(order);

        // Generate pickup OTP for shop owner verification
        if (order.getPickupOtp() == null || order.getPickupOtp().isEmpty()) {
            String otp = generatePickupOTP();
            order.setPickupOtp(otp);
            order.setPickupOtpGeneratedAt(LocalDateTime.now());
            orderRepository.save(order);
            log.info("✅ Generated pickup OTP for order {}: {}", order.getId(), otp);
        }

        // Send notification to shop owner that driver accepted the order
        try {
            if (order.getShop() != null && order.getShop().getOwnerEmail() != null) {
                // Find shop owner user by email
                Optional<User> shopOwnerOpt = userRepository.findByEmail(order.getShop().getOwnerEmail());
                if (shopOwnerOpt.isEmpty()) {
                    log.warn("Shop owner user not found for email: {}", order.getShop().getOwnerEmail());
                    return assignment;
                }

                Long shopOwnerId = shopOwnerOpt.get().getId();
                User partner = assignment.getDeliveryPartner();

                // Get FCM tokens for the shop owner
                List<UserFcmToken> tokens = userFcmTokenRepository.findActiveTokensByUserId(shopOwnerId);
                log.info("📊 Found {} active FCM tokens for shop owner (user ID: {}) for driver accept notification",
                    tokens.size(), shopOwnerId);

                if (!tokens.isEmpty()) {
                    boolean notificationSent = false;
                    for (UserFcmToken tokenEntity : tokens) {
                        String fcmToken = tokenEntity.getFcmToken();
                        try {
                            firebaseNotificationService.sendOrderNotification(
                                order.getOrderNumber(),
                                "DRIVER_ACCEPTED",
                                fcmToken,
                                shopOwnerId
                            );
                            log.info("✅ Driver accept notification sent to shop owner for order: {}", order.getOrderNumber());
                            notificationSent = true;
                            break; // Success! No need to try other tokens
                        } catch (Exception e) {
                            log.warn("⚠️ Failed to send driver accept notification with token {}..., trying next token: {}",
                                fcmToken.substring(0, Math.min(30, fcmToken.length())), e.getMessage());
                            // Continue to next token
                        }
                    }

                    if (!notificationSent) {
                        log.error("❌ Failed to send driver accept notification with all available tokens for order: {}",
                            order.getOrderNumber());
                    }
                } else {
                    log.warn("⚠️ No active FCM tokens found for shop owner (user ID: {}). Driver accept notification not sent for order: {}",
                        shopOwnerId, order.getOrderNumber());
                }
            } else {
                log.warn("⚠️ Shop or shop owner is null for order: {}. Driver accept notification not sent.",
                    order.getOrderNumber());
            }
        } catch (Exception e) {
            log.error("❌ Failed to send driver accept notification for order: {}", order.getOrderNumber(), e);
            // Don't fail the accept operation if notification fails
        }

        // Update partner status to ON_RIDE but keep them AVAILABLE for accepting more orders
        User partner = assignment.getDeliveryPartner();
        partner.setIsAvailable(true); // KEEP AVAILABLE - they can accept multiple orders
        partner.setRideStatus(User.RideStatus.ON_RIDE);
        partner.setLastActivity(LocalDateTime.now());
        userRepository.save(partner);

        log.info("✅ Assignment {} accepted by partner {}. Order status: ACCEPTED, Partner: AVAILABLE FOR MORE ORDERS",
            assignmentId, partnerId);
        return assignment;
    }

    /**
     * Generate a 4-digit OTP for pickup verification
     */
    private String generatePickupOTP() {
        return String.format("%04d", (int) (Math.random() * 10000));
    }

    /**
     * Reject an assignment (called by delivery partner)
     */
    @Transactional
    public void rejectAssignment(Long assignmentId, Long partnerId, String reason) {
        log.info("Partner {} rejecting assignment {} with reason: {}", partnerId, assignmentId, reason);

        OrderAssignment assignment = assignmentRepository.findById(assignmentId)
            .orElseThrow(() -> new RuntimeException("Assignment not found: " + assignmentId));

        // Validate partner
        if (!assignment.getDeliveryPartner().getId().equals(partnerId)) {
            throw new RuntimeException("Assignment does not belong to this partner");
        }

        // Reject the assignment
        assignment.reject(reason);
        assignmentRepository.save(assignment);

        // Reset order status back to ready for pickup
        Order order = assignment.getOrder();
        order.setStatus(Order.OrderStatus.READY_FOR_PICKUP);
        orderRepository.save(order);

        // Make partner available again
        User partner = assignment.getDeliveryPartner();
        partner.setIsAvailable(true);
        partner.setRideStatus(User.RideStatus.AVAILABLE);
        partner.setLastActivity(LocalDateTime.now());
        userRepository.save(partner);

        log.info("Assignment {} rejected by partner {}. Order {} reset to READY_FOR_PICKUP",
                 assignmentId, partnerId, order.getId());

        // Send push notification to shop owner
        try {
            String shopOwnerEmail = order.getShop().getOwnerEmail();
            if (shopOwnerEmail != null) {
                User shopOwner = userRepository.findByEmail(shopOwnerEmail).orElse(null);
                if (shopOwner != null) {
                    List<UserFcmToken> tokens = userFcmTokenRepository.findActiveTokensByUserId(shopOwner.getId());
                    log.info("📊 Found {} active FCM tokens for shop owner (user ID: {}) for rejection notification", tokens.size(), shopOwner.getId());

                    if (!tokens.isEmpty()) {
                        String partnerName = partner.getFirstName() != null ? partner.getFirstName() : "Delivery partner";
                        String title = "Driver Rejected Order";
                        String message = partnerName + " rejected order #" + order.getOrderNumber() + ". Reason: " + reason + ". Order is back to Ready for Pickup status.";

                        for (UserFcmToken tokenEntity : tokens) {
                            try {
                                firebaseNotificationService.sendOrderNotification(
                                    order.getOrderNumber(),
                                    "DRIVER_REJECTED",
                                    tokenEntity.getFcmToken(),
                                    title,
                                    message
                                );
                                log.info("✅ Sent rejection notification to shop owner for order {}", order.getOrderNumber());
                                break; // One successful notification is enough
                            } catch (Exception e) {
                                log.warn("Failed to send notification to token: {}", e.getMessage());
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.warn("Failed to send rejection notification to shop owner: {}", e.getMessage());
        }
    }

    /**
     * Mark assignment as picked up (called by delivery partner)
     */
    @Transactional
    public OrderAssignment markPickedUp(Long assignmentId, Long partnerId) {
        log.info("Partner {} marking assignment {} as picked up", partnerId, assignmentId);

        OrderAssignment assignment = assignmentRepository.findById(assignmentId)
            .orElseThrow(() -> new RuntimeException("Assignment not found: " + assignmentId));

        // Validate partner
        if (!assignment.getDeliveryPartner().getId().equals(partnerId)) {
            throw new RuntimeException("Assignment does not belong to this partner");
        }

        // Mark as picked up
        assignment.markPickedUp();
        assignment.markInTransit(); // Automatically move to in-transit
        assignment = assignmentRepository.save(assignment);

        // Update order status
        Order order = assignment.getOrder();
        order.setStatus(Order.OrderStatus.OUT_FOR_DELIVERY);
        orderRepository.save(order);

        // Send push notification to customer
        try {
            if (order.getCustomer() != null && order.getCustomer().getEmail() != null) {
                // Find user by customer's email
                User customerUser = userRepository.findByEmail(order.getCustomer().getEmail()).orElse(null);
                if (customerUser != null) {
                    Long userId = customerUser.getId();

                    // Get FCM tokens for the customer (newest first)
                    List<UserFcmToken> tokens = userFcmTokenRepository.findActiveTokensByUserId(userId);
                    log.info("📊 Found {} active FCM tokens for customer (user ID: {}) for pickup notification", tokens.size(), userId);

                    if (!tokens.isEmpty()) {
                        boolean notificationSent = false;
                        for (UserFcmToken tokenEntity : tokens) {
                            String fcmToken = tokenEntity.getFcmToken();
                            try {
                                firebaseNotificationService.sendOrderNotification(
                                    order.getOrderNumber(),
                                    "OUT_FOR_DELIVERY",
                                    fcmToken,
                                    order.getCustomer().getId()
                                );
                                log.info("✅ Pickup notification sent successfully to customer for order: {}", order.getOrderNumber());
                                notificationSent = true;
                                break; // Success! No need to try other tokens
                            } catch (Exception e) {
                                log.warn("⚠️ Failed to send pickup notification with token {}..., trying next token: {}",
                                    fcmToken.substring(0, Math.min(30, fcmToken.length())), e.getMessage());
                                // Continue to next token
                            }
                        }

                        if (!notificationSent) {
                            log.error("❌ Failed to send pickup notification with all available tokens for order: {}", order.getOrderNumber());
                        }
                    } else {
                        log.warn("⚠️ No active FCM tokens found for customer (user ID: {}). Pickup notification not sent for order: {}",
                            userId, order.getOrderNumber());
                    }
                } else {
                    log.warn("⚠️ No user found for customer email: {}. Pickup notification not sent.", order.getCustomer().getEmail());
                }
            } else {
                log.warn("⚠️ Customer or email is null for order: {}. Pickup notification not sent.", order.getOrderNumber());
            }
        } catch (Exception e) {
            log.error("❌ Failed to send pickup push notification for order: {}", order.getOrderNumber(), e);
            // Don't fail the pickup operation if notification fails
        }

        log.info("Assignment {} marked as picked up and in transit by partner {}", assignmentId, partnerId);
        return assignment;
    }

    /**
     * Mark assignment as delivered (called by delivery partner)
     */
    @Transactional
    public OrderAssignment markDelivered(Long assignmentId, Long partnerId, String deliveryNotes) {
        log.info("Partner {} marking assignment {} as delivered", partnerId, assignmentId);

        OrderAssignment assignment = assignmentRepository.findById(assignmentId)
            .orElseThrow(() -> new RuntimeException("Assignment not found: " + assignmentId));

        // Validate partner
        if (!assignment.getDeliveryPartner().getId().equals(partnerId)) {
            throw new RuntimeException("Assignment does not belong to this partner");
        }

        // Mark as delivered
        assignment.markDelivered();
        assignment.setDeliveryNotes(deliveryNotes);
        assignment = assignmentRepository.save(assignment);

        // Update order status
        Order order = assignment.getOrder();
        order.setStatus(Order.OrderStatus.DELIVERED);
        order.setActualDeliveryTime(LocalDateTime.now());
        orderRepository.save(order);

        // Check if partner has other active assignments
        User partner = assignment.getDeliveryPartner();
        List<OrderAssignment> activeAssignments = assignmentRepository.findByDeliveryPartnerAndStatusIn(
            partner, ACTIVE_STATUSES);

        // If no more active orders, mark partner as AVAILABLE with status AVAILABLE
        // If still has active orders, keep them ON_RIDE but AVAILABLE to accept more
        if (activeAssignments.isEmpty() || (activeAssignments.size() == 1 && activeAssignments.get(0).getId().equals(assignmentId))) {
            partner.setIsAvailable(true);
            partner.setRideStatus(User.RideStatus.AVAILABLE);
            log.info("Partner {} has no more active orders. Status: AVAILABLE", partnerId);
        } else {
            partner.setIsAvailable(true); // Keep available for more orders
            partner.setRideStatus(User.RideStatus.ON_RIDE);
            log.info("Partner {} still has {} active orders. Status: ON_RIDE but AVAILABLE",
                partnerId, activeAssignments.size() - 1);
        }
        partner.setLastActivity(LocalDateTime.now());
        userRepository.save(partner);

        // Send delivery notification email with order items and total
        try {
            // Build order items list for email
            java.util.List<java.util.Map<String, Object>> orderItemsForEmail = order.getOrderItems().stream()
                .map(item -> {
                    java.util.Map<String, Object> itemMap = new java.util.HashMap<>();
                    itemMap.put("productName", item.getProductName());
                    itemMap.put("quantity", item.getQuantity());
                    itemMap.put("unitPrice", item.getUnitPrice().doubleValue());
                    itemMap.put("totalPrice", item.getTotalPrice().doubleValue());

                    // Get product image URL if available
                    if (item.getShopProduct() != null && item.getShopProduct().getMasterProduct() != null) {
                        String imageUrl = item.getShopProduct().getMasterProduct().getPrimaryImageUrl();
                        if (imageUrl != null && !imageUrl.isEmpty()) {
                            if (!imageUrl.startsWith("http")) {
                                imageUrl = "https://api.nammaoorudelivary.in" + imageUrl;
                            }
                        }
                        itemMap.put("productImageUrl", imageUrl);
                    }
                    return itemMap;
                })
                .collect(java.util.stream.Collectors.toList());

            emailService.sendDeliverySummaryEmail(
                order.getCustomer().getEmail(),
                order.getCustomer().getFirstName() + " " + order.getCustomer().getLastName(),
                order.getOrderNumber(),
                assignment.getDeliveryPartner().getFirstName() + " " + assignment.getDeliveryPartner().getLastName(),
                order.getShop().getName(),
                orderItemsForEmail,
                order.getTotalAmount().doubleValue()
            );
            log.info("Delivery summary email sent to customer {} with {} items",
                order.getCustomer().getEmail(), orderItemsForEmail.size());
        } catch (Exception e) {
            log.error("Failed to send delivery notification email: {}", e.getMessage());
        }

        log.info("Assignment {} marked as delivered by partner {}. Order {} status updated to DELIVERED",
                 assignmentId, partnerId, order.getId());
        return assignment;
    }

    // Query methods
    public List<User> findAvailableDeliveryPartners() {
        return assignmentRepository.findAvailableDeliveryPartners(ACTIVE_STATUSES);
    }

    public Optional<OrderAssignment> findActiveAssignmentByOrderId(Long orderId) {
        return assignmentRepository.findActiveAssignmentByOrderId(orderId, ACTIVE_STATUSES);
    }

    @Transactional(readOnly = true)
    public Optional<OrderAssignment> findCurrentAssignmentByPartnerId(Long partnerId) {
        return assignmentRepository.findCurrentAssignmentByPartnerId(partnerId, ACTIVE_STATUSES);
    }

    public List<OrderAssignment> findPendingAssignmentsByPartnerId(Long partnerId) {
        return assignmentRepository.findPendingAssignmentsByPartnerId(partnerId);
    }

    public Page<OrderAssignment> findAssignmentsByPartnerId(Long partnerId, Pageable pageable) {
        User partner = userRepository.findById(partnerId)
            .orElseThrow(() -> new RuntimeException("Delivery partner not found: " + partnerId));
        return assignmentRepository.findByDeliveryPartner(partner, pageable);
    }

    public List<OrderAssignment> findAssignmentsByPartnerAndStatuses(User partner, List<OrderAssignment.AssignmentStatus> statuses) {
        return assignmentRepository.findByDeliveryPartnerAndStatusIn(partner, statuses);
    }

    public List<OrderAssignment> findAssignmentsByOrderId(Long orderId) {
        return assignmentRepository.findByOrderId(orderId);
    }

    public List<OrderAssignment> findAssignmentsByOrderNumber(String orderNumber) {
        Order order = orderRepository.findByOrderNumber(orderNumber)
            .orElseThrow(() -> new RuntimeException("Order not found with number: " + orderNumber));
        return assignmentRepository.findByOrderId(order.getId());
    }

    // Helper methods
    private BigDecimal calculatePartnerCommission(BigDecimal deliveryFee) {
        // Calculate 75% of delivery fee as commission
        return deliveryFee.multiply(BigDecimal.valueOf(0.75));
    }

    private Double calculateOrderDistance(Order order) {
        try {
            // Get shop coordinates
            Double shopLat = order.getShop().getLatitude() != null ? order.getShop().getLatitude().doubleValue() : null;
            Double shopLon = order.getShop().getLongitude() != null ? order.getShop().getLongitude().doubleValue() : null;

            // Get customer coordinates (assuming from delivery address)
            // For now, use default coordinates or implement geocoding
            Double customerLat = 12.9716; // Default Bangalore coordinates
            Double customerLon = 77.5946;

            return deliveryFeeService.calculateDistance(shopLat, shopLon, customerLat, customerLon);
        } catch (Exception e) {
            log.warn("Could not calculate distance for order {}, using default 5km", order.getId());
            return 5.0; // Default 5km distance
        }
    }

    // Analytics and reporting methods
    public Long getCompletedAssignmentsCount(Long partnerId) {
        return assignmentRepository.countCompletedAssignmentsByPartnerId(partnerId);
    }

    public Long getRejectedAssignmentsCount(Long partnerId) {
        return assignmentRepository.countRejectedAssignmentsByPartnerId(partnerId);
    }

    public Double getPartnerAverageRating(Long partnerId) {
        return assignmentRepository.getAverageRatingByPartnerId(partnerId);
    }

    public Double getPartnerTotalEarnings(Long partnerId) {
        return assignmentRepository.getTotalEarningsByPartnerId(partnerId);
    }

    /**
     * Smart partner selection with time-based logic
     */
    private User findBestAvailablePartner() {
        List<User> availablePartners = findAvailableDeliveryPartners();

        System.out.println("DEBUG: Found " + availablePartners.size() + " available partners");

        // Debug: Print all delivery partners status
        List<User> allDeliveryPartners = userRepository.findByRole(User.UserRole.DELIVERY_PARTNER);
        System.out.println("DEBUG: Total delivery partners: " + allDeliveryPartners.size());
        for (User partner : allDeliveryPartners) {
            System.out.println("DEBUG: Partner " + partner.getEmail() +
                " - Online: " + partner.getIsOnline() +
                ", Available: " + partner.getIsAvailable() +
                ", RideStatus: " + partner.getRideStatus());
        }

        if (availablePartners.isEmpty()) {
            // If no available partners, check for partners who might finish soon
            List<User> busyPartners = userRepository.findByRoleAndIsOnline(User.UserRole.DELIVERY_PARTNER, true)
                .stream()
                .filter(partner -> partner.getRideStatus() == User.RideStatus.ON_RIDE)
                .toList();

            for (User busyPartner : busyPartners) {
                // Check if partner has been on ride for more than 20 minutes
                Optional<OrderAssignment> currentAssignment = findCurrentAssignmentByPartnerId(busyPartner.getId());
                if (currentAssignment.isPresent()) {
                    OrderAssignment assignment = currentAssignment.get();
                    if (assignment.getPickupTime() != null) {
                        long minutesSincePickup = java.time.Duration.between(
                            assignment.getPickupTime(),
                            LocalDateTime.now()
                        ).toMinutes();

                        if (minutesSincePickup > 20) {
                            log.info("Assigning to busy partner {} who should finish soon (on ride for {} minutes)",
                                    busyPartner.getEmail(), minutesSincePickup);
                            return busyPartner;
                        }
                    }
                }
            }

            return null; // No suitable partners found
        }

        // For now, return the first available partner (location-based selection can be improved later)
        User selectedPartner = availablePartners.get(0);
        log.info("Selected partner: {} (ID: {})", selectedPartner.getEmail(), selectedPartner.getId());
        return selectedPartner;
    }

    /**
     * Find the closest delivery partner to the shop based on location
     */
    private User findClosestPartner(List<User> availablePartners, Order order) {
        try {
            // Get shop coordinates
            Double shopLat = order.getShop().getLatitude() != null ? order.getShop().getLatitude().doubleValue() : null;
            Double shopLon = order.getShop().getLongitude() != null ? order.getShop().getLongitude().doubleValue() : null;

            if (shopLat == null || shopLon == null) {
                log.warn("Shop coordinates not available for order {}, cannot use distance-based selection", order.getId());
                return null;
            }

            User closestPartner = null;
            double minDistance = Double.MAX_VALUE;

            for (User partner : availablePartners) {
                // Get partner coordinates
                Double partnerLat = partner.getCurrentLatitude() != null ? partner.getCurrentLatitude().doubleValue() : null;
                Double partnerLon = partner.getCurrentLongitude() != null ? partner.getCurrentLongitude().doubleValue() : null;

                if (partnerLat != null && partnerLon != null) {
                    // Calculate distance using Haversine formula
                    double distance = calculateHaversineDistance(shopLat, shopLon, partnerLat, partnerLon);

                    log.info("Partner {} distance from shop: {:.2f} km", partner.getEmail(), distance);

                    if (distance < minDistance) {
                        minDistance = distance;
                        closestPartner = partner;
                    }
                } else {
                    log.warn("Partner {} has no location data, skipping distance calculation", partner.getEmail());
                }
            }

            if (closestPartner != null) {
                log.info("Closest partner found: {} at {:.2f} km distance", closestPartner.getEmail(), minDistance);
            }

            return closestPartner;
        } catch (Exception e) {
            log.error("Error calculating closest partner: {}", e.getMessage(), e);
            return null;
        }
    }

    /**
     * Calculate distance between two points using Haversine formula
     */
    private double calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
        final double R = 6371; // Radius of the earth in km

        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);

        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c; // Distance in km
    }

    /**
     * Select best available partner using FAIR DISTRIBUTION
     * Strategy: Pick the partner with LEAST active/completed orders today
     * This ensures equal workload distribution among all drivers
     */
    private User selectBestAvailablePartner(List<User> availablePartners) {
        log.info("Selecting best partner from {} available partners", availablePartners.size());

        // If only one partner, return immediately
        if (availablePartners.size() == 1) {
            return availablePartners.get(0);
        }

        // Count today's orders for each partner
        LocalDateTime todayStart = LocalDateTime.now().withHour(0).withMinute(0).withSecond(0);

        User selectedPartner = null;
        long minOrderCount = Long.MAX_VALUE;

        for (User partner : availablePartners) {
            // Count assignments for this partner today
            long orderCount = assignmentRepository.countByDeliveryPartnerAndCreatedAtAfter(
                partner, todayStart);

            log.info("Partner {} ({}) has {} orders today",
                partner.getEmail(), partner.getId(), orderCount);

            // Select partner with fewest orders
            if (orderCount < minOrderCount) {
                minOrderCount = orderCount;
                selectedPartner = partner;
            }
        }

        log.info("✅ Selected partner: {} with {} orders today (FAIR DISTRIBUTION)",
            selectedPartner.getEmail(), minOrderCount);

        return selectedPartner;
    }
}