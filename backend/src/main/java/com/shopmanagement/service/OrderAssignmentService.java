package com.shopmanagement.service;

import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderAssignment;
import com.shopmanagement.entity.OrderAssignment.AssignmentStatus;
import com.shopmanagement.entity.OrderAssignment.AssignmentType;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.OrderAssignmentRepository;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.repository.UserRepository;
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
    private final EmailService emailService;

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

        // Check if order is ready for pickup
        if (order.getStatus() != Order.OrderStatus.READY_FOR_PICKUP) {
            throw new RuntimeException("Order is not ready for pickup. Current status: " + order.getStatus());
        }

        // Check if order is already assigned
        Optional<OrderAssignment> existingAssignment = findActiveAssignmentByOrderId(orderId);
        if (existingAssignment.isPresent()) {
            throw new RuntimeException("Order is already assigned to a delivery partner");
        }

        // Smart partner selection with time-based logic
        User selectedPartner = findBestAvailablePartner();
        if (selectedPartner == null) {
            throw new RuntimeException("No suitable delivery partners found");
        }
        User assignedBy = userRepository.findById(assignedByUserId)
            .orElseThrow(() -> new RuntimeException("Assigned by user not found: " + assignedByUserId));

        // Calculate delivery fee and commission
        BigDecimal deliveryFee = order.getDeliveryFee();
        if (deliveryFee == null || deliveryFee.compareTo(BigDecimal.ZERO) == 0) {
            // Set default delivery fee if not set
            deliveryFee = new BigDecimal("50.00"); // Default ₹50 delivery fee
            order.setDeliveryFee(deliveryFee);
            orderRepository.save(order);
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

        // Calculate delivery fee and commission
        BigDecimal deliveryFee = order.getDeliveryFee();
        if (deliveryFee == null || deliveryFee.compareTo(BigDecimal.ZERO) == 0) {
            // Set default delivery fee if not set
            deliveryFee = new BigDecimal("50.00"); // Default ₹50 delivery fee
            order.setDeliveryFee(deliveryFee);
            orderRepository.save(order);
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
        // Partner gets 80% of delivery fee as commission
        return deliveryFee.multiply(BigDecimal.valueOf(0.8));
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

        // For now, return the first available partner
        // TODO: Implement distance-based selection when location tracking is ready
        User selectedPartner = availablePartners.get(0);
        log.info("Selected available partner: {} (ID: {})", selectedPartner.getEmail(), selectedPartner.getId());
        return selectedPartner;
    }
}