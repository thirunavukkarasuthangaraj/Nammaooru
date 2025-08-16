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
        
        // Send confirmation email
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