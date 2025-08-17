package com.shopmanagement.delivery.service;

import com.shopmanagement.delivery.dto.*;
import com.shopmanagement.delivery.entity.*;
import com.shopmanagement.delivery.mapper.DeliveryPartnerMapper;
import com.shopmanagement.delivery.repository.*;
import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class OrderAssignmentService {

    private final OrderAssignmentRepository assignmentRepository;
    private final DeliveryPartnerRepository partnerRepository;
    private final OrderRepository orderRepository;
    private final UserService userService;
    private final DeliveryPartnerMapper mapper;
    private final PartnerEarningRepository earningRepository;
    private final DeliveryPartnerService partnerService;

    @Transactional
    public OrderAssignmentResponse assignOrder(OrderAssignmentRequest request) {
        log.info("Assigning order {} to delivery partner", request.getOrderId());

        // Validate order
        Order order = getOrderEntity(request.getOrderId());
        validateOrderForAssignment(order);

        // Get or find delivery partner
        DeliveryPartner partner = getDeliveryPartner(request);

        // Create assignment
        OrderAssignment assignment = createOrderAssignment(request, order, partner);
        OrderAssignment savedAssignment = assignmentRepository.save(assignment);

        // Create partner earning record
        createPartnerEarning(savedAssignment);

        log.info("Successfully assigned order {} to partner {}", 
                order.getOrderNumber(), partner.getPartnerId());

        return mapper.toAssignmentResponse(savedAssignment);
    }

    @Transactional
    public OrderAssignmentResponse acceptAssignment(Long assignmentId, Long partnerId) {
        OrderAssignment assignment = getAssignmentEntity(assignmentId);
        validatePartnerForAssignment(assignment, partnerId);

        if (!assignment.canBeAccepted()) {
            throw new IllegalStateException("Assignment cannot be accepted in current status: " + assignment.getStatus());
        }

        assignment.setStatus(OrderAssignment.AssignmentStatus.ACCEPTED);
        assignment.setAcceptedAt(LocalDateTime.now());

        OrderAssignment savedAssignment = assignmentRepository.save(assignment);
        log.info("Partner {} accepted assignment {}", partnerId, assignmentId);

        return mapper.toAssignmentResponse(savedAssignment);
    }

    @Transactional
    public OrderAssignmentResponse rejectAssignment(Long assignmentId, Long partnerId, String reason) {
        OrderAssignment assignment = getAssignmentEntity(assignmentId);
        validatePartnerForAssignment(assignment, partnerId);

        if (!assignment.canBeRejected()) {
            throw new IllegalStateException("Assignment cannot be rejected in current status: " + assignment.getStatus());
        }

        assignment.setStatus(OrderAssignment.AssignmentStatus.REJECTED);
        assignment.setRejectionReason(reason);

        OrderAssignment savedAssignment = assignmentRepository.save(assignment);
        log.info("Partner {} rejected assignment {} with reason: {}", partnerId, assignmentId, reason);

        // TODO: Trigger auto-reassignment logic

        return mapper.toAssignmentResponse(savedAssignment);
    }

    @Transactional
    public OrderAssignmentResponse markPickedUp(Long assignmentId, Long partnerId) {
        OrderAssignment assignment = getAssignmentEntity(assignmentId);
        validatePartnerForAssignment(assignment, partnerId);

        if (!assignment.canBePickedUp()) {
            throw new IllegalStateException("Assignment cannot be picked up in current status: " + assignment.getStatus());
        }

        assignment.setStatus(OrderAssignment.AssignmentStatus.PICKED_UP);
        assignment.setPickupTime(LocalDateTime.now());

        // Update order status
        Order order = assignment.getOrder();
        order.setStatus(Order.OrderStatus.OUT_FOR_DELIVERY);

        OrderAssignment savedAssignment = assignmentRepository.save(assignment);
        log.info("Partner {} picked up order for assignment {}", partnerId, assignmentId);

        return mapper.toAssignmentResponse(savedAssignment);
    }

    @Transactional
    public OrderAssignmentResponse startDelivery(Long assignmentId, Long partnerId) {
        OrderAssignment assignment = getAssignmentEntity(assignmentId);
        validatePartnerForAssignment(assignment, partnerId);

        assignment.setStatus(OrderAssignment.AssignmentStatus.IN_TRANSIT);

        OrderAssignment savedAssignment = assignmentRepository.save(assignment);
        log.info("Partner {} started delivery for assignment {}", partnerId, assignmentId);

        return mapper.toAssignmentResponse(savedAssignment);
    }

    @Transactional
    public OrderAssignmentResponse completeDelivery(Long assignmentId, Long partnerId, String notes) {
        OrderAssignment assignment = getAssignmentEntity(assignmentId);
        validatePartnerForAssignment(assignment, partnerId);

        if (!assignment.canBeDelivered()) {
            throw new IllegalStateException("Assignment cannot be completed in current status: " + assignment.getStatus());
        }

        assignment.setStatus(OrderAssignment.AssignmentStatus.DELIVERED);
        assignment.setDeliveryTime(LocalDateTime.now());
        assignment.setDeliveryNotes(notes);

        // Update order status
        Order order = assignment.getOrder();
        order.setStatus(Order.OrderStatus.DELIVERED);
        order.setActualDeliveryTime(LocalDateTime.now());

        // Update partner stats
        partnerService.updateDeliveryStats(partnerId, true);

        // Update earning status
        updateEarningStatus(assignment);

        OrderAssignment savedAssignment = assignmentRepository.save(assignment);
        log.info("Partner {} completed delivery for assignment {}", partnerId, assignmentId);

        return mapper.toAssignmentResponse(savedAssignment);
    }

    @Transactional
    public OrderAssignmentResponse markFailed(Long assignmentId, Long partnerId, String reason) {
        OrderAssignment assignment = getAssignmentEntity(assignmentId);
        validatePartnerForAssignment(assignment, partnerId);

        assignment.setStatus(OrderAssignment.AssignmentStatus.FAILED);
        assignment.setRejectionReason(reason);

        // Update partner stats
        partnerService.updateDeliveryStats(partnerId, false);

        OrderAssignment savedAssignment = assignmentRepository.save(assignment);
        log.info("Partner {} marked assignment {} as failed: {}", partnerId, assignmentId, reason);

        return mapper.toAssignmentResponse(savedAssignment);
    }

    public Optional<OrderAssignmentResponse> getAssignmentById(Long assignmentId) {
        return assignmentRepository.findById(assignmentId)
                .map(mapper::toAssignmentResponse);
    }

    public List<OrderAssignmentResponse> getAssignmentsByOrder(Long orderId) {
        return assignmentRepository.findByOrderId(orderId)
                .stream()
                .map(mapper::toAssignmentResponse)
                .toList();
    }

    public Page<OrderAssignmentResponse> getAssignmentsByPartner(Long partnerId, Pageable pageable) {
        return assignmentRepository.findByDeliveryPartnerId(partnerId, pageable)
                .map(mapper::toAssignmentResponse);
    }

    public List<OrderAssignmentResponse> getActiveAssignmentsByPartner(Long partnerId) {
        return assignmentRepository.findActiveAssignmentsByPartner(partnerId)
                .stream()
                .map(mapper::toAssignmentResponse)
                .toList();
    }

    public List<OrderAssignmentResponse> getAssignmentsByStatus(OrderAssignment.AssignmentStatus status) {
        return assignmentRepository.findByStatus(status)
                .stream()
                .map(mapper::toAssignmentResponse)
                .toList();
    }

    @Transactional
    public void processExpiredAssignments() {
        LocalDateTime timeoutDate = LocalDateTime.now().minusMinutes(15); // 15 minutes timeout
        List<OrderAssignment> expiredAssignments = assignmentRepository.findExpiredAssignments(timeoutDate);

        for (OrderAssignment assignment : expiredAssignments) {
            assignment.setStatus(OrderAssignment.AssignmentStatus.CANCELLED);
            assignment.setRejectionReason("Assignment timeout - no response from partner");
            assignmentRepository.save(assignment);

            log.info("Cancelled expired assignment {} for order {}", 
                    assignment.getId(), assignment.getOrder().getOrderNumber());
        }
    }

    // Auto-assignment logic
    public List<DeliveryPartner> findBestPartnersForOrder(Order order) {
        // Get order location (from shop or customer)
        BigDecimal orderLat = order.getShop().getLatitude();
        BigDecimal orderLng = order.getShop().getLongitude();

        if (orderLat == null || orderLng == null) {
            // Fallback to all available partners
            return partnerRepository.findAvailablePartners();
        }

        // Find nearby available partners
        List<DeliveryPartner> nearbyPartners = partnerRepository.findNearbyAvailablePartners(orderLat, orderLng);

        // Sort by rating and success rate
        return nearbyPartners.stream()
                .filter(partner -> partner.canTakeOrders())
                .sorted((p1, p2) -> {
                    // Primary sort by rating
                    int ratingCompare = p2.getRating().compareTo(p1.getRating());
                    if (ratingCompare != 0) return ratingCompare;
                    
                    // Secondary sort by success rate
                    return p2.getSuccessRate().compareTo(p1.getSuccessRate());
                })
                .toList();
    }

    // Private helper methods

    private Order getOrderEntity(Long orderId) {
        return orderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Order not found: " + orderId));
    }

    private OrderAssignment getAssignmentEntity(Long assignmentId) {
        return assignmentRepository.findById(assignmentId)
                .orElseThrow(() -> new IllegalArgumentException("Assignment not found: " + assignmentId));
    }

    private void validateOrderForAssignment(Order order) {
        if (order.getStatus() != Order.OrderStatus.CONFIRMED) {
            throw new IllegalStateException("Order must be confirmed before assignment");
        }

        // Check if already assigned
        Optional<OrderAssignment> existingAssignment = assignmentRepository
                .findByOrderIdAndStatus(order.getId(), OrderAssignment.AssignmentStatus.ASSIGNED);
        
        if (existingAssignment.isPresent()) {
            throw new IllegalStateException("Order is already assigned to a partner");
        }
    }

    private DeliveryPartner getDeliveryPartner(OrderAssignmentRequest request) {
        if (request.getPartnerId() != null) {
            // Manual assignment
            DeliveryPartner partner = partnerRepository.findById(request.getPartnerId())
                    .orElseThrow(() -> new IllegalArgumentException("Partner not found: " + request.getPartnerId()));
            
            if (!partner.canTakeOrders()) {
                throw new IllegalStateException("Partner is not available for assignments");
            }
            
            return partner;
        } else {
            // Auto assignment
            Order order = getOrderEntity(request.getOrderId());
            List<DeliveryPartner> availablePartners = findBestPartnersForOrder(order);
            
            if (availablePartners.isEmpty()) {
                throw new IllegalStateException("No available partners found for this order");
            }
            
            return availablePartners.get(0); // Get the best partner
        }
    }

    private OrderAssignment createOrderAssignment(OrderAssignmentRequest request, Order order, DeliveryPartner partner) {
        return OrderAssignment.builder()
                .order(order)
                .deliveryPartner(partner)
                .assignmentType(request.getAssignmentType())
                .deliveryFee(request.getDeliveryFee())
                .partnerCommission(calculatePartnerCommission(request.getDeliveryFee()))
                .pickupLatitude(request.getPickupLatitude())
                .pickupLongitude(request.getPickupLongitude())
                .deliveryLatitude(request.getDeliveryLatitude())
                .deliveryLongitude(request.getDeliveryLongitude())
                .build();
    }

    private void createPartnerEarning(OrderAssignment assignment) {
        PartnerEarning earning = PartnerEarning.builder()
                .deliveryPartner(assignment.getDeliveryPartner())
                .orderAssignment(assignment)
                .baseAmount(assignment.getPartnerCommission())
                .totalAmount(assignment.getPartnerCommission())
                .build();

        earningRepository.save(earning);
    }

    private void updateEarningStatus(OrderAssignment assignment) {
        if (assignment.getEarning() != null) {
            PartnerEarning earning = assignment.getEarning();
            earning.setPaymentStatus(PartnerEarning.PaymentStatus.PROCESSED);
            earningRepository.save(earning);

            // Update partner total earnings
            partnerService.updateEarnings(assignment.getDeliveryPartner().getId(), earning.getTotalAmount());
        }
    }

    private void validatePartnerForAssignment(OrderAssignment assignment, Long partnerId) {
        if (!assignment.getDeliveryPartner().getId().equals(partnerId)) {
            throw new IllegalArgumentException("Assignment does not belong to the specified partner");
        }
    }

    private BigDecimal calculatePartnerCommission(BigDecimal deliveryFee) {
        // Default commission is 80% of delivery fee
        return deliveryFee.multiply(BigDecimal.valueOf(0.8))
                .setScale(2, RoundingMode.HALF_UP);
    }
}