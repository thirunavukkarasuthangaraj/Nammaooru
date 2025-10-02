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

        // Get the first available partner
        List<User> availablePartners = userRepository.findByRoleAndIsActiveAndIsAvailableAndIsOnline(
            User.UserRole.DELIVERY_PARTNER, true, true, true);

        if (availablePartners.isEmpty()) {
            throw new RuntimeException("No available delivery partners found");
        }

        User selectedPartner = availablePartners.get(0);
        log.info("Selected delivery partner: {} (ID: {})", selectedPartner.getEmail(), selectedPartner.getId());
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
        OrderAssignment assignment = OrderAssignment.builder()
            .order(order)
            .deliveryPartner(selectedPartner)
            .assignedBy(assignedBy)
            .status(AssignmentStatus.ASSIGNED)
            .assignmentType(AssignmentType.AUTO)
            .deliveryFee(deliveryFee)
            .partnerCommission(partnerCommission)
            .assignmentNotes("Auto-assigned to nearest available partner")
            .build();

        assignment = assignmentRepository.save(assignment);

        // Update order status
        order.setStatus(Order.OrderStatus.OUT_FOR_DELIVERY);
        orderRepository.save(order);

        // Update partner availability (make them busy)
        selectedPartner.setIsAvailable(false);
        selectedPartner.setRideStatus(User.RideStatus.ON_RIDE);
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

                // Send Firebase notification
                firebaseNotificationService.sendOrderNotification(
                    order.getOrderNumber(),
                    "NEW_ASSIGNMENT",
                    fcmToken,
                    null // No customer ID for driver notifications
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

        log.info("Assignment {} accepted by partner {}", assignmentId, partnerId);
        return assignment;
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

        // Make partner available again
        User partner = assignment.getDeliveryPartner();
        partner.setIsAvailable(true);
        partner.setRideStatus(User.RideStatus.AVAILABLE);
        partner.setLastActivity(LocalDateTime.now());
        userRepository.save(partner);

        // Send delivery notification email
        try {
            emailService.sendDeliveryNotificationEmail(
                order.getCustomer().getEmail(),
                order.getCustomer().getFirstName() + " " + order.getCustomer().getLastName(),
                order.getOrderNumber(),
                assignment.getDeliveryPartner().getFirstName() + " " + assignment.getDeliveryPartner().getLastName(),
                order.getShop().getName()
            );
            log.info("Delivery notification email sent to customer {}", order.getCustomer().getEmail());
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
}