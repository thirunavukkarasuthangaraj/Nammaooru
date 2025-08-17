package com.shopmanagement.service;

import com.shopmanagement.dto.order.OrderRequest;
import com.shopmanagement.dto.order.OrderResponse;
import com.shopmanagement.entity.Customer;
import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderItem;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.product.repository.ShopProductRepository;
import com.shopmanagement.repository.CustomerRepository;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.shop.repository.ShopRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class OrderService {
    
    private final OrderRepository orderRepository;
    private final CustomerRepository customerRepository;
    private final ShopRepository shopRepository;
    private final ShopProductRepository shopProductRepository;
    private final EmailService emailService;
    
    @Transactional
    public OrderResponse createOrder(OrderRequest request) {
        log.info("Creating order for customer: {} at shop: {}", request.getCustomerId(), request.getShopId());
        
        // Validate customer
        Customer customer = customerRepository.findById(request.getCustomerId())
                .orElseThrow(() -> new RuntimeException("Customer not found"));
        
        // Validate shop
        Shop shop = shopRepository.findById(request.getShopId())
                .orElseThrow(() -> new RuntimeException("Shop not found"));
        
        // Calculate order totals
        BigDecimal subtotal = BigDecimal.ZERO;
        List<OrderItem> orderItems = request.getOrderItems().stream()
                .map(itemRequest -> {
                    ShopProduct shopProduct = shopProductRepository.findById(itemRequest.getShopProductId())
                            .orElseThrow(() -> new RuntimeException("Product not found"));
                    
                    BigDecimal itemTotal = shopProduct.getPrice()
                            .multiply(BigDecimal.valueOf(itemRequest.getQuantity()));
                    
                    return OrderItem.builder()
                            .shopProduct(shopProduct)
                            .quantity(itemRequest.getQuantity())
                            .unitPrice(shopProduct.getPrice())
                            .totalPrice(itemTotal)
                            .specialInstructions(itemRequest.getSpecialInstructions())
                            .productName(shopProduct.getMasterProduct().getName())
                            .productDescription(shopProduct.getMasterProduct().getDescription())
                            .productSku(shopProduct.getMasterProduct().getSku())
                            .productImageUrl(shopProduct.getMasterProduct().getPrimaryImageUrl())
                            .build();
                })
                .collect(Collectors.toList());
        
        // Calculate totals
        subtotal = orderItems.stream()
                .map(OrderItem::getTotalPrice)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        BigDecimal taxAmount = subtotal.multiply(BigDecimal.valueOf(0.05)); // 5% tax
        BigDecimal deliveryFee = BigDecimal.valueOf(50); // Fixed delivery fee
        BigDecimal discountAmount = request.getDiscountAmount() != null ? request.getDiscountAmount() : BigDecimal.ZERO;
        BigDecimal totalAmount = subtotal.add(taxAmount).add(deliveryFee).subtract(discountAmount);
        
        // Create order
        Order order = Order.builder()
                .customer(customer)
                .shop(shop)
                .status(Order.OrderStatus.PENDING)
                .paymentStatus(Order.PaymentStatus.PENDING)
                .paymentMethod(request.getPaymentMethod())
                .subtotal(subtotal)
                .taxAmount(taxAmount)
                .deliveryFee(deliveryFee)
                .discountAmount(discountAmount)
                .totalAmount(totalAmount)
                .notes(request.getNotes())
                .deliveryAddress(request.getDeliveryAddress())
                .deliveryCity(request.getDeliveryCity())
                .deliveryState(request.getDeliveryState())
                .deliveryPostalCode(request.getDeliveryPostalCode())
                .deliveryPhone(request.getDeliveryPhone())
                .deliveryContactName(request.getDeliveryContactName())
                .estimatedDeliveryTime(request.getEstimatedDeliveryTime())
                .createdBy(getCurrentUsername())
                .updatedBy(getCurrentUsername())
                .build();
        
        // Set order reference in items
        orderItems.forEach(item -> item.setOrder(order));
        order.setOrderItems(orderItems);
        
        Order savedOrder = orderRepository.save(order);
        
        // Send confirmation email to customer
        try {
            emailService.sendOrderConfirmationEmail(
                customer.getEmail(),
                customer.getFullName(),
                savedOrder.getOrderNumber(),
                savedOrder.getTotalAmount().doubleValue(),
                savedOrder.getCreatedAt().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"))
            );
        } catch (Exception e) {
            log.error("Failed to send order confirmation email", e);
        }
        
        // Send new order notification to shop owner
        try {
            String itemsSummary = orderItems.stream()
                .map(item -> String.format("%s x%d (₹%.2f)", 
                    item.getProductName(), 
                    item.getQuantity(), 
                    item.getTotalPrice()))
                .collect(Collectors.joining(", "));
                
            emailService.sendOrderPlacedNotificationToShop(
                shop.getOwnerEmail(),
                shop.getOwnerName(),
                savedOrder.getOrderNumber(),
                customer.getFullName(),
                String.format("₹%.2f", savedOrder.getTotalAmount()),
                itemsSummary
            );
        } catch (Exception e) {
            log.error("Failed to send order notification to shop owner", e);
        }
        
        log.info("Order created successfully: {}", savedOrder.getOrderNumber());
        return mapToResponse(savedOrder);
    }
    
    public OrderResponse getOrderById(Long id) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        return mapToResponse(order);
    }
    
    public OrderResponse getOrderByNumber(String orderNumber) {
        Order order = orderRepository.findByOrderNumber(orderNumber)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        return mapToResponse(order);
    }
    
    @Transactional
    public OrderResponse updateOrderStatus(Long orderId, Order.OrderStatus status) {
        log.info("Updating order status: {} to {}", orderId, status);
        
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        
        Order.OrderStatus oldStatus = order.getStatus();
        order.setStatus(status);
        order.setUpdatedBy(getCurrentUsername());
        
        if (status == Order.OrderStatus.DELIVERED) {
            order.setActualDeliveryTime(LocalDateTime.now());
        }
        
        Order updatedOrder = orderRepository.save(order);
        
        // Send status update email
        try {
            emailService.sendOrderStatusUpdateEmail(
                order.getCustomer().getEmail(),
                order.getCustomer().getFullName(),
                order.getOrderNumber(),
                oldStatus.name(),
                status.name()
            );
        } catch (Exception e) {
            log.error("Failed to send order status update email", e);
        }
        
        return mapToResponse(updatedOrder);
    }
    
    @Transactional
    public OrderResponse cancelOrder(Long orderId, String reason) {
        log.info("Cancelling order: {} with reason: {}", orderId, reason);
        
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        
        if (!order.canBeCancelled()) {
            throw new RuntimeException("Order cannot be cancelled in current status: " + order.getStatus());
        }
        
        order.setStatus(Order.OrderStatus.CANCELLED);
        order.setCancellationReason(reason);
        order.setUpdatedBy(getCurrentUsername());
        
        Order cancelledOrder = orderRepository.save(order);
        
        return mapToResponse(cancelledOrder);
    }
    
    public Page<OrderResponse> getAllOrders(int page, int size, String sortBy, String sortDirection) {
        Sort.Direction direction = sortDirection.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        
        Page<Order> orders = orderRepository.findAll(pageable);
        return orders.map(this::mapToResponse);
    }
    
    public Page<OrderResponse> getOrdersByShop(Long shopId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Order> orders = orderRepository.findByShopId(shopId, pageable);
        return orders.map(this::mapToResponse);
    }
    
    public Page<OrderResponse> getOrdersByCustomer(Long customerId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Order> orders = orderRepository.findByCustomerId(customerId, pageable);
        return orders.map(this::mapToResponse);
    }
    
    public Page<OrderResponse> getOrdersByStatus(Order.OrderStatus status, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Order> orders = orderRepository.findByStatus(status, pageable);
        return orders.map(this::mapToResponse);
    }
    
    public Page<OrderResponse> searchOrders(String searchTerm, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Order> orders = orderRepository.searchOrders(searchTerm, pageable);
        return orders.map(this::mapToResponse);
    }
    
    @Transactional
    public OrderResponse acceptOrder(Long orderId, String estimatedPreparationTime, String notes) {
        log.info("Accepting order: {} with estimated preparation time: {}", orderId, estimatedPreparationTime);
        
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        
        if (order.getStatus() != Order.OrderStatus.PENDING) {
            throw new RuntimeException("Order cannot be accepted in current status: " + order.getStatus());
        }
        
        order.setStatus(Order.OrderStatus.CONFIRMED);
        order.setUpdatedBy(getCurrentUsername());
        
        if (estimatedPreparationTime != null && !estimatedPreparationTime.trim().isEmpty()) {
            // Parse and set estimated delivery time based on preparation time
            try {
                int minutes = Integer.parseInt(estimatedPreparationTime);
                order.setEstimatedDeliveryTime(LocalDateTime.now().plusMinutes(minutes));
            } catch (NumberFormatException e) {
                log.warn("Invalid preparation time format: {}", estimatedPreparationTime);
            }
        }
        
        if (notes != null && !notes.trim().isEmpty()) {
            String existingNotes = order.getNotes();
            String updatedNotes = existingNotes != null ? 
                existingNotes + "\n[Shop Owner] " + notes : 
                "[Shop Owner] " + notes;
            order.setNotes(updatedNotes);
        }
        
        Order acceptedOrder = orderRepository.save(order);
        
        // Send order acceptance email to customer
        try {
            emailService.sendOrderStatusUpdateToCustomer(
                order.getCustomer().getEmail(),
                order.getCustomer().getFullName(),
                order.getOrderNumber(),
                "PENDING",
                "CONFIRMED",
                "Order accepted by " + order.getShop().getName()
            );
        } catch (Exception e) {
            log.error("Failed to send order acceptance email to customer", e);
        }
        
        log.info("Order accepted successfully: {}", acceptedOrder.getOrderNumber());
        return mapToResponse(acceptedOrder);
    }
    
    @Transactional
    public OrderResponse rejectOrder(Long orderId, String reason) {
        log.info("Rejecting order: {} with reason: {}", orderId, reason);
        
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        
        if (order.getStatus() != Order.OrderStatus.PENDING) {
            throw new RuntimeException("Order cannot be rejected in current status: " + order.getStatus());
        }
        
        order.setStatus(Order.OrderStatus.CANCELLED);
        order.setCancellationReason(reason);
        order.setUpdatedBy(getCurrentUsername());
        
        Order rejectedOrder = orderRepository.save(order);
        
        // Send order rejection email to customer
        try {
            emailService.sendOrderStatusUpdateToCustomer(
                order.getCustomer().getEmail(),
                order.getCustomer().getFullName(),
                order.getOrderNumber(),
                "PENDING",
                "CANCELLED",
                "Order rejected by " + order.getShop().getName() + ". Reason: " + reason
            );
        } catch (Exception e) {
            log.error("Failed to send order rejection email to customer", e);
        }
        
        log.info("Order rejected successfully: {}", rejectedOrder.getOrderNumber());
        return mapToResponse(rejectedOrder);
    }
    
    public Map<String, Object> getOrderTracking(Long orderId) {
        log.info("Fetching tracking information for order: {}", orderId);
        
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        
        Map<String, Object> trackingInfo = new HashMap<>();
        
        // Basic order info
        trackingInfo.put("orderId", order.getId());
        trackingInfo.put("orderNumber", order.getOrderNumber());
        trackingInfo.put("currentStatus", order.getStatus().name());
        trackingInfo.put("statusLabel", getStatusLabel(order.getStatus()));
        
        // Customer info
        trackingInfo.put("customerName", order.getCustomer().getFullName());
        trackingInfo.put("customerPhone", order.getCustomer().getMobileNumber());
        
        // Shop info
        trackingInfo.put("shopName", order.getShop().getName());
        trackingInfo.put("shopPhone", order.getShop().getPhone());
        trackingInfo.put("shopAddress", order.getShop().getAddressLine1() + ", " + order.getShop().getCity());
        
        // Delivery info
        String fullDeliveryAddress = String.format("%s, %s, %s - %s",
                order.getDeliveryAddress(),
                order.getDeliveryCity(),
                order.getDeliveryState(),
                order.getDeliveryPostalCode());
        trackingInfo.put("deliveryAddress", fullDeliveryAddress);
        trackingInfo.put("deliveryPhone", order.getDeliveryPhone());
        trackingInfo.put("deliveryContactName", order.getDeliveryContactName());
        
        // Timeline
        trackingInfo.put("timeline", buildOrderTimeline(order));
        
        // Progress percentage
        trackingInfo.put("progressPercentage", calculateProgressPercentage(order.getStatus()));
        
        // Estimated times
        trackingInfo.put("estimatedDeliveryTime", order.getEstimatedDeliveryTime());
        trackingInfo.put("actualDeliveryTime", order.getActualDeliveryTime());
        
        // Order details
        trackingInfo.put("totalAmount", order.getTotalAmount());
        trackingInfo.put("paymentMethod", order.getPaymentMethod().name());
        trackingInfo.put("paymentStatus", order.getPaymentStatus().name());
        
        // Special instructions
        trackingInfo.put("notes", order.getNotes());
        trackingInfo.put("cancellationReason", order.getCancellationReason());
        
        return trackingInfo;
    }
    
    private List<Map<String, Object>> buildOrderTimeline(Order order) {
        List<Map<String, Object>> timeline = List.of(
            Map.of(
                "status", "PENDING",
                "label", "Order Placed",
                "description", "Your order has been placed successfully",
                "timestamp", order.getCreatedAt(),
                "completed", true,
                "icon", "shopping_cart"
            ),
            Map.of(
                "status", "CONFIRMED",
                "label", "Order Confirmed",
                "description", "Shop has confirmed your order",
                "timestamp", order.getStatus().ordinal() >= Order.OrderStatus.CONFIRMED.ordinal() ? 
                    order.getUpdatedAt() : null,
                "completed", order.getStatus().ordinal() >= Order.OrderStatus.CONFIRMED.ordinal(),
                "icon", "check_circle"
            ),
            Map.of(
                "status", "PREPARING",
                "label", "Preparing Order",
                "description", "Your order is being prepared",
                "timestamp", order.getStatus().ordinal() >= Order.OrderStatus.PREPARING.ordinal() ? 
                    order.getUpdatedAt() : null,
                "completed", order.getStatus().ordinal() >= Order.OrderStatus.PREPARING.ordinal(),
                "icon", "restaurant"
            ),
            Map.of(
                "status", "READY",
                "label", "Ready for Pickup/Delivery",
                "description", "Your order is ready",
                "timestamp", order.getStatus().ordinal() >= Order.OrderStatus.READY.ordinal() ? 
                    order.getUpdatedAt() : null,
                "completed", order.getStatus().ordinal() >= Order.OrderStatus.READY.ordinal(),
                "icon", "done_all"
            ),
            Map.of(
                "status", "OUT_FOR_DELIVERY",
                "label", "Out for Delivery",
                "description", "Your order is on the way",
                "timestamp", order.getStatus().ordinal() >= Order.OrderStatus.OUT_FOR_DELIVERY.ordinal() ? 
                    order.getUpdatedAt() : null,
                "completed", order.getStatus().ordinal() >= Order.OrderStatus.OUT_FOR_DELIVERY.ordinal(),
                "icon", "local_shipping"
            ),
            Map.of(
                "status", "DELIVERED",
                "label", "Delivered",
                "description", "Order delivered successfully",
                "timestamp", order.getActualDeliveryTime(),
                "completed", order.getStatus() == Order.OrderStatus.DELIVERED,
                "icon", "home"
            )
        );
        
        // Handle cancelled orders
        if (order.getStatus() == Order.OrderStatus.CANCELLED) {
            return List.of(
                Map.of(
                    "status", "PENDING",
                    "label", "Order Placed",
                    "description", "Your order was placed",
                    "timestamp", order.getCreatedAt(),
                    "completed", true,
                    "icon", "shopping_cart"
                ),
                Map.of(
                    "status", "CANCELLED",
                    "label", "Order Cancelled",
                    "description", "Order was cancelled. Reason: " + order.getCancellationReason(),
                    "timestamp", order.getUpdatedAt(),
                    "completed", true,
                    "icon", "cancel",
                    "error", true
                )
            );
        }
        
        return timeline;
    }
    
    private int calculateProgressPercentage(Order.OrderStatus status) {
        return switch (status) {
            case PENDING -> 15;
            case CONFIRMED -> 30;
            case PREPARING -> 50;
            case READY -> 70;
            case OUT_FOR_DELIVERY -> 85;
            case DELIVERED -> 100;
            case CANCELLED -> 0;
        };
    }
    
    private String getStatusLabel(Order.OrderStatus status) {
        return switch (status) {
            case PENDING -> "Order Placed";
            case CONFIRMED -> "Order Confirmed";
            case PREPARING -> "Being Prepared";
            case READY -> "Ready for Delivery";
            case OUT_FOR_DELIVERY -> "Out for Delivery";
            case DELIVERED -> "Delivered";
            case CANCELLED -> "Cancelled";
        };
    }
    
    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null ? authentication.getName() : "system";
    }
    
    private OrderResponse mapToResponse(Order order) {
        List<OrderResponse.OrderItemResponse> itemResponses = order.getOrderItems().stream()
                .map(item -> OrderResponse.OrderItemResponse.builder()
                        .id(item.getId())
                        .shopProductId(item.getShopProduct().getId())
                        .productName(item.getProductName())
                        .productDescription(item.getProductDescription())
                        .productSku(item.getProductSku())
                        .productImageUrl(item.getProductImageUrl())
                        .quantity(item.getQuantity())
                        .unitPrice(item.getUnitPrice())
                        .totalPrice(item.getTotalPrice())
                        .specialInstructions(item.getSpecialInstructions())
                        .build())
                .collect(Collectors.toList());
        
        String fullDeliveryAddress = String.format("%s, %s, %s - %s",
                order.getDeliveryAddress(),
                order.getDeliveryCity(),
                order.getDeliveryState(),
                order.getDeliveryPostalCode());
        
        long daysBetween = ChronoUnit.DAYS.between(order.getCreatedAt(), LocalDateTime.now());
        String orderAge = daysBetween == 0 ? "Today" :
                         daysBetween == 1 ? "1 day ago" :
                         daysBetween + " days ago";
        
        return OrderResponse.builder()
                .id(order.getId())
                .orderNumber(order.getOrderNumber())
                .status(order.getStatus())
                .paymentStatus(order.getPaymentStatus())
                .paymentMethod(order.getPaymentMethod())
                .customerId(order.getCustomer().getId())
                .customerName(order.getCustomer().getFullName())
                .customerEmail(order.getCustomer().getEmail())
                .customerPhone(order.getCustomer().getMobileNumber())
                .shopId(order.getShop().getId())
                .shopName(order.getShop().getName())
                .shopAddress(order.getShop().getAddressLine1() + ", " + order.getShop().getCity())
                .subtotal(order.getSubtotal())
                .taxAmount(order.getTaxAmount())
                .deliveryFee(order.getDeliveryFee())
                .discountAmount(order.getDiscountAmount())
                .totalAmount(order.getTotalAmount())
                .notes(order.getNotes())
                .cancellationReason(order.getCancellationReason())
                .deliveryAddress(order.getDeliveryAddress())
                .deliveryCity(order.getDeliveryCity())
                .deliveryState(order.getDeliveryState())
                .deliveryPostalCode(order.getDeliveryPostalCode())
                .deliveryPhone(order.getDeliveryPhone())
                .deliveryContactName(order.getDeliveryContactName())
                .fullDeliveryAddress(fullDeliveryAddress)
                .estimatedDeliveryTime(order.getEstimatedDeliveryTime())
                .actualDeliveryTime(order.getActualDeliveryTime())
                .orderItems(itemResponses)
                .createdAt(order.getCreatedAt())
                .updatedAt(order.getUpdatedAt())
                .createdBy(order.getCreatedBy())
                .updatedBy(order.getUpdatedBy())
                .statusLabel(order.getStatus().name())
                .paymentStatusLabel(order.getPaymentStatus().name())
                .paymentMethodLabel(order.getPaymentMethod().name())
                .canBeCancelled(order.canBeCancelled())
                .isDelivered(order.isDelivered())
                .isPaid(order.isPaid())
                .orderAge(orderAge)
                .itemCount(order.getOrderItems().size())
                .build();
    }
}