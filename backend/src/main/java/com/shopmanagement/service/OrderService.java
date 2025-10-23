package com.shopmanagement.service;

import com.shopmanagement.dto.order.OrderRequest;
import com.shopmanagement.dto.order.OrderResponse;
import com.shopmanagement.dto.order.CustomerOrderRequest;
import com.shopmanagement.dto.order.OrderTrackingResponse;
import com.shopmanagement.entity.Customer;
import com.shopmanagement.entity.Notification;
import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderItem;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.product.entity.MasterProduct;
import com.shopmanagement.product.repository.ShopProductRepository;
import com.shopmanagement.repository.CustomerRepository;
import com.shopmanagement.repository.NotificationRepository;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.shop.repository.ShopRepository;
import com.shopmanagement.entity.User;
import com.shopmanagement.service.OrderAssignmentService;
import com.shopmanagement.repository.UserFcmTokenRepository;
import com.shopmanagement.repository.OrderAssignmentRepository;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.entity.OrderAssignment;
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
import org.springframework.context.annotation.Lazy;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Slf4j
@Service
public class OrderService {

    private final OrderRepository orderRepository;
    private final CustomerRepository customerRepository;
    private final UserRepository userRepository;
    private final ShopRepository shopRepository;
    private final ShopProductRepository shopProductRepository;
    private final EmailService emailService;
    private final InvoiceService invoiceService;
    private final FirebaseNotificationService firebaseNotificationService;
    private final OrderAssignmentService orderAssignmentService;
    private final UserFcmTokenRepository userFcmTokenRepository;
    private final NotificationRepository notificationRepository;
    private final DeliveryConfirmationService deliveryConfirmationService;
    private final OrderAssignmentRepository orderAssignmentRepository;

    public OrderService(
            OrderRepository orderRepository,
            CustomerRepository customerRepository,
            UserRepository userRepository,
            ShopRepository shopRepository,
            ShopProductRepository shopProductRepository,
            EmailService emailService,
            InvoiceService invoiceService,
            FirebaseNotificationService firebaseNotificationService,
            OrderAssignmentService orderAssignmentService,
            UserFcmTokenRepository userFcmTokenRepository,
            NotificationRepository notificationRepository,
            OrderAssignmentRepository orderAssignmentRepository,
            @Lazy DeliveryConfirmationService deliveryConfirmationService) {
        this.orderRepository = orderRepository;
        this.customerRepository = customerRepository;
        this.userRepository = userRepository;
        this.shopRepository = shopRepository;
        this.shopProductRepository = shopProductRepository;
        this.emailService = emailService;
        this.invoiceService = invoiceService;
        this.firebaseNotificationService = firebaseNotificationService;
        this.orderAssignmentService = orderAssignmentService;
        this.userFcmTokenRepository = userFcmTokenRepository;
        this.notificationRepository = notificationRepository;
        this.orderAssignmentRepository = orderAssignmentRepository;
        this.deliveryConfirmationService = deliveryConfirmationService;
    }
    
    @Transactional
    public OrderResponse createOrder(OrderRequest request) {
        log.info("Creating order for customer: {} at shop: {}", request.getCustomerId(), request.getShopId());
        
        Customer customer;
        if (request.getCustomerId() != null) {
            // Use provided customer ID
            customer = customerRepository.findById(request.getCustomerId())
                    .orElseThrow(() -> new RuntimeException("Customer not found"));
        } else if (request.getUserId() != null) {
            // Find or create customer based on userId
            customer = findOrCreateCustomerByUserId(request.getUserId());
        } else {
            // Get user ID from current authentication context
            String currentUsername = getCurrentUsername();
            if (currentUsername != null && !currentUsername.equals("system")) {
                User currentUser = userRepository.findByUsername(currentUsername)
                        .orElseThrow(() -> new RuntimeException("Current user not found"));
                customer = findOrCreateCustomerByUserId(currentUser.getId());
            } else {
                throw new RuntimeException("No customer or user information provided");
            }
        }
        
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

        // Minimum order amount validation
        BigDecimal minimumOrderAmount = BigDecimal.valueOf(100);
        if (subtotal.compareTo(minimumOrderAmount) < 0) {
            throw new RuntimeException(String.format("Minimum order amount is ₹%.2f. Current order total is ₹%.2f",
                    minimumOrderAmount, subtotal));
        }

        BigDecimal taxAmount = subtotal.multiply(BigDecimal.valueOf(0.05)); // 5% tax

        // Determine delivery type - default to HOME_DELIVERY if not specified
        Order.DeliveryType deliveryType = Order.DeliveryType.HOME_DELIVERY;
        if (request.getDeliveryType() != null && !request.getDeliveryType().trim().isEmpty()) {
            try {
                deliveryType = Order.DeliveryType.valueOf(request.getDeliveryType().toUpperCase());
            } catch (IllegalArgumentException e) {
                log.warn("Invalid delivery type: {}, defaulting to HOME_DELIVERY", request.getDeliveryType());
            }
        }

        // Delivery fee is 0 for self-pickup, otherwise fixed fee
        BigDecimal deliveryFee = deliveryType == Order.DeliveryType.SELF_PICKUP ? BigDecimal.ZERO : BigDecimal.valueOf(50);

        BigDecimal discountAmount = request.getDiscountAmount() != null ? request.getDiscountAmount() : BigDecimal.ZERO;
        BigDecimal totalAmount = subtotal.add(taxAmount).add(deliveryFee).subtract(discountAmount);
        
        // Create order
        Order order = Order.builder()
                .customer(customer)
                .shop(shop)
                .status(Order.OrderStatus.PENDING)
                .paymentStatus(Order.PaymentStatus.PENDING)
                .paymentMethod(request.getPaymentMethod())
                .deliveryType(deliveryType)
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

        // Create order placed notification
        try {
            Notification orderPlacedNotification = Notification.builder()
                    .title("Order Placed Successfully! 🎉")
                    .message(String.format("Your order %s has been placed at %s. Total: ₹%.2f",
                            savedOrder.getOrderNumber(), savedOrder.getShop().getName(), savedOrder.getTotalAmount()))
                    .type(Notification.NotificationType.ORDER)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .status(Notification.NotificationStatus.UNREAD)
                    .recipientId(customer.getId())
                    .recipientType(Notification.RecipientType.CUSTOMER)
                    .referenceId(savedOrder.getId())
                    .referenceType("ORDER")
                    .category("ORDER_STATUS")
                    .isActive(true)
                    .isPersistent(true)
                    .build();
            notificationRepository.save(orderPlacedNotification);
            log.info("✅ Order placed notification created for order: {}", savedOrder.getOrderNumber());
        } catch (Exception e) {
            log.error("Failed to create order placed notification", e);
        }

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

        // Send FCM push notification to shop owner
        try {
            log.info("🔔 Attempting to send FCM notification to shop owner: {}", shop.getOwnerEmail());

            // Find shop owner's user record
            Optional<User> shopOwnerOpt = userRepository.findByEmail(shop.getOwnerEmail());
            if (shopOwnerOpt.isPresent()) {
                User shopOwner = shopOwnerOpt.get();
                log.info("✅ Found shop owner user: ID={}, Role={}", shopOwner.getId(), shopOwner.getRole());

                // Get all active FCM tokens for shop owner
                List<UserFcmToken> fcmTokens = userFcmTokenRepository.findActiveTokensByUserId(shopOwner.getId());
                log.info("📱 Found {} active FCM token(s) for shop owner", fcmTokens.size());

                if (!fcmTokens.isEmpty()) {
                    // Send notification to all active devices
                    for (UserFcmToken fcmToken : fcmTokens) {
                        try {
                            log.info("📤 Sending FCM to device: {}", fcmToken.getDeviceType());
                            firebaseNotificationService.sendOrderNotification(
                                savedOrder.getOrderNumber(),
                                "PENDING",
                                fcmToken.getFcmToken(),
                                shopOwner.getId()
                            );
                            log.info("✅ FCM notification sent successfully to shop owner's device");
                        } catch (Exception e) {
                            log.error("❌ Failed to send FCM to device {}: {}", fcmToken.getDeviceType(), e.getMessage());
                        }
                    }
                } else {
                    log.warn("⚠️ No active FCM tokens found for shop owner {}", shop.getOwnerEmail());
                }
            } else {
                log.warn("⚠️ Shop owner user not found for email: {}", shop.getOwnerEmail());
            }
        } catch (Exception e) {
            log.error("❌ Failed to send FCM notification to shop owner", e);
        }
        
        log.info("Order created successfully: {}", savedOrder.getOrderNumber());
        return mapToResponse(savedOrder);
    }
    
    @Transactional(readOnly = true)
    public OrderResponse getOrderById(Long id) {
        Order order = orderRepository.findByIdWithOrderItems(id)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        return mapToResponse(order);
    }
    
    @Transactional(readOnly = true)
    public OrderResponse getOrderByNumber(String orderNumber) {
        Order order = orderRepository.findByOrderNumberWithOrderItems(orderNumber)
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

        // Save the order status update first
        OrderResponse response = mapToResponse(updatedOrder);

        // Create notification in database
        try {
            createOrderStatusNotification(updatedOrder, oldStatus, status);
        } catch (Exception e) {
            log.error("Failed to create order status notification", e);
        }

        // Auto-assign delivery partner when order is ready for pickup (separate transaction)
        if (status == Order.OrderStatus.READY_FOR_PICKUP) {
            // Use a separate thread to avoid transaction rollback issues
            CompletableFuture.runAsync(() -> {
                try {
                    // Delay to ensure transaction commits first
                    Thread.sleep(500);

                    log.info("Order {} is ready for pickup - auto-assigning delivery partner", order.getOrderNumber());

                    // Auto-assign to available delivery partner
                    Long assignedBy = 1L; // System auto-assignment
                    orderAssignmentService.autoAssignOrder(orderId, assignedBy);

                    log.info("Order {} successfully auto-assigned to delivery partner", order.getOrderNumber());

                    // AUTO-GENERATE PICKUP OTP after assignment
                    try {
                        Thread.sleep(500); // Small delay after assignment
                        log.info("Auto-generating pickup OTP for order {}", orderId);
                        String otp = deliveryConfirmationService.generatePickupOTP(orderId);
                        log.info("✅ Pickup OTP generated successfully for order {}: {}", orderId, otp);
                    } catch (Exception otpError) {
                        log.error("Failed to auto-generate pickup OTP for order {}: {}", orderId, otpError.getMessage());
                    }
                } catch (Exception e) {
                    log.error("Failed to auto-assign delivery partner for order: {}", order.getOrderNumber(), e);
                }
            });
        }
        
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

        // Send push notification to customer for all status updates
        try {
            log.info("🔔 Starting push notification process for order: {}", order.getOrderNumber());

            if (order.getCustomer() != null && order.getCustomer().getEmail() != null) {
                String customerEmail = order.getCustomer().getEmail();
                log.info("📧 Customer email from order: {}", customerEmail);

                // Find user by customer's email
                User customerUser = userRepository.findByEmail(customerEmail).orElse(null);
                if (customerUser != null) {
                    Long userId = customerUser.getId();
                    String username = customerUser.getUsername();
                    log.info("✅ Found user: {} (ID: {}) for customer email: {}", username, userId, customerEmail);

                    // Get FCM token for the customer
                    String fcmToken = userFcmTokenRepository.findByUserIdAndIsActiveTrue(userId)
                            .stream()
                            .findFirst()
                            .map(UserFcmToken::getFcmToken)
                            .orElse(null);
                    log.info("🔍 FCM token lookup for user ID {}: {}", userId,
                            fcmToken != null ? "Found token (length: " + fcmToken.length() + ")" : "No token found");

                    if (fcmToken != null && !fcmToken.isEmpty()) {
                        log.info("📱 Sending push notification to FCM token: {}...", fcmToken.substring(0, Math.min(50, fcmToken.length())));
                        firebaseNotificationService.sendOrderNotification(
                            order.getOrderNumber(),
                            status.name(),
                            fcmToken,
                            order.getCustomer().getId()
                        );
                        log.info("✅ Push notification sent successfully for order status update: {} -> {} to user: {}",
                                oldStatus.name(), status.name(), username);
                    } else {
                        log.warn("❌ No FCM token found for customer user ID: {} (username: {})", userId, username);
                        log.warn("💡 User may need to login to mobile app to register FCM token");
                    }
                } else {
                    log.warn("❌ No user found for customer email: {}", customerEmail);
                    log.warn("💡 Customer email in order must match a user account email for push notifications");
                }
            } else {
                log.warn("❌ Order customer or customer email is null for order: {}", order.getOrderNumber());
            }
        } catch (Exception e) {
            log.error("❌ Failed to send push notification for status update", e);
        }
        
        // Auto-send invoice when order is delivered
        if (status == Order.OrderStatus.DELIVERED) {
            try {
                invoiceService.sendInvoiceEmail(orderId);
                log.info("Invoice email automatically sent for delivered order: {}", order.getOrderNumber());
            } catch (Exception e) {
                log.error("Failed to send automatic invoice email for order: {}", order.getOrderNumber(), e);
            }
        }
        
        return response;
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
    
    @Transactional(readOnly = true)
    public Page<OrderResponse> getAllOrders(int page, int size, String sortBy, String sortDirection) {
        Sort.Direction direction = sortDirection.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        
        Page<Order> orders = orderRepository.findAllWithOrderItems(pageable);
        return orders.map(this::mapToResponse);
    }
    
    @Transactional(readOnly = true)
    public Page<OrderResponse> getOrdersByShop(Long shopId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Order> orders = orderRepository.findByShopIdWithOrderItems(shopId, pageable);

        // Get all order IDs to check for active assignments
        List<Long> orderIds = orders.getContent().stream()
                .map(Order::getId)
                .collect(Collectors.toList());

        // Query for all active assignments for these orders
        List<OrderAssignment.AssignmentStatus> activeStatuses = List.of(
                OrderAssignment.AssignmentStatus.ASSIGNED,
                OrderAssignment.AssignmentStatus.ACCEPTED,
                OrderAssignment.AssignmentStatus.PICKED_UP,
                OrderAssignment.AssignmentStatus.IN_TRANSIT
        );

        // Collect order IDs that have active assignments
        Map<Long, Boolean> orderAssignmentMap = new HashMap<>();
        log.info("🔍 Checking assignments for {} orders. Active statuses: {}", orderIds.size(), activeStatuses);
        for (Long orderId : orderIds) {
            Optional<OrderAssignment> activeAssignment = orderAssignmentRepository
                    .findActiveAssignmentByOrderId(orderId, activeStatuses);
            boolean hasAssignment = activeAssignment.isPresent();
            log.info("Order {}: Assignment found = {}", orderId, hasAssignment);
            if (hasAssignment) {
                log.info("Order {}: Assignment status = {}", orderId, activeAssignment.get().getStatus());
            }
            orderAssignmentMap.put(orderId, hasAssignment);
        }

        // Map orders to responses with assignment status
        return orders.map(order -> mapToResponse(order, orderAssignmentMap.get(order.getId())));
    }
    
    @Transactional(readOnly = true)
    public Page<OrderResponse> getOrdersByCustomer(Long customerId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Order> orders = orderRepository.findByCustomerIdWithOrderItems(customerId, pageable);
        return orders.map(this::mapToResponse);
    }

    @Transactional(readOnly = true)
    public Page<OrderResponse> getOrdersByCustomer(Long customerId, int page, int size, String status) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Order> orders;

        if (status != null && !status.trim().isEmpty()) {
            try {
                Order.OrderStatus orderStatus = Order.OrderStatus.valueOf(status.toUpperCase());
                orders = orderRepository.findByCustomerIdAndStatusWithOrderItems(customerId, orderStatus, pageable);
            } catch (IllegalArgumentException e) {
                log.warn("Invalid order status: {}, returning all orders", status);
                orders = orderRepository.findByCustomerIdWithOrderItems(customerId, pageable);
            }
        } else {
            orders = orderRepository.findByCustomerIdWithOrderItems(customerId, pageable);
        }

        return orders.map(this::mapToResponse);
    }
    
    @Transactional(readOnly = true)
    public Page<OrderResponse> getOrdersByStatus(Order.OrderStatus status, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Order> orders = orderRepository.findByStatusWithOrderItems(status, pageable);
        return orders.map(this::mapToResponse);
    }
    
    @Transactional(readOnly = true)
    public Page<OrderResponse> searchOrders(String searchTerm, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Order> orders = orderRepository.searchOrdersWithOrderItems(searchTerm, pageable);
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
        
        // Auto-assign delivery partner when order is confirmed
        // Commented out delivery assignment logic
        // try {
        //     log.info("Attempting auto-assignment of delivery partner for order: {}", acceptedOrder.getOrderNumber());
        //     
        //     OrderAssignmentRequest assignmentRequest = OrderAssignmentRequest.builder()
        //             .orderId(acceptedOrder.getId())
        //             .assignmentType(OrderAssignmentRequest.AssignmentType.AUTO)
        //             .deliveryFee(acceptedOrder.getDeliveryFee())
        //             .build();
        //     
        //     orderAssignmentService.assignOrder(assignmentRequest);
        //     log.info("Successfully auto-assigned delivery partner for order: {}", acceptedOrder.getOrderNumber());
        //     
        // } catch (Exception e) {
        //     log.error("Failed to auto-assign delivery partner for order: {} - Error: {}", 
        //         acceptedOrder.getOrderNumber(), e.getMessage());
        //     // Don't fail the order acceptance if assignment fails
        // }
        
        // Send order acceptance email to customer (simplified for now)
        try {
            if (acceptedOrder.getCustomer() != null && acceptedOrder.getShop() != null) {
                log.info("Order accepted successfully - email would be sent to customer: {} for order: {}", 
                    acceptedOrder.getCustomer().getEmail(), acceptedOrder.getOrderNumber());
                // TODO: Implement email notification after fixing compilation issues
            } else {
                log.error("Cannot send email - Customer or Shop is null for order: {}", acceptedOrder.getId());
            }
        } catch (Exception e) {
            log.error("Failed to send order acceptance email to customer", e);
        }
        
        // Send push notification to customer
        try {
            if (acceptedOrder.getCustomer() != null && acceptedOrder.getCustomer().getEmail() != null) {
                // Find user by customer's email
                User customerUser = userRepository.findByEmail(acceptedOrder.getCustomer().getEmail()).orElse(null);
                if (customerUser == null) {
                    log.warn("No user found for customer email: {}", acceptedOrder.getCustomer().getEmail());
                    return mapToResponse(acceptedOrder);
                }
                Long userId = customerUser.getId();

                // Get FCM tokens for the customer (newest first)
                List<String> fcmTokens = getFcmTokensForUser(userId);

                if (!fcmTokens.isEmpty()) {
                    boolean notificationSent = false;
                    for (String fcmToken : fcmTokens) {
                        try {
                            firebaseNotificationService.sendOrderNotification(
                                acceptedOrder.getOrderNumber(),
                                "CONFIRMED",
                                fcmToken,
                                acceptedOrder.getCustomer().getId()
                            );
                            log.info("✅ Push notification sent successfully to customer for order: {}", acceptedOrder.getOrderNumber());
                            notificationSent = true;
                            break; // Success! No need to try other tokens
                        } catch (Exception e) {
                            log.warn("⚠️ Failed to send notification with token {}..., trying next token: {}",
                                fcmToken.substring(0, Math.min(30, fcmToken.length())), e.getMessage());
                            // Continue to next token
                        }
                    }

                    if (!notificationSent) {
                        log.error("❌ Failed to send push notification with all available tokens for order: {}", acceptedOrder.getOrderNumber());

                        // Fallback to SMS notification when push notification fails
                        try {
                            if (acceptedOrder.getCustomer().getMobileNumber() != null) {
                                log.info("📱 Attempting SMS fallback notification for order: {}", acceptedOrder.getOrderNumber());
                                String smsMessage = String.format("Your order %s has been confirmed and is being prepared. Thank you for choosing NammaOoru!",
                                    acceptedOrder.getOrderNumber());

                                // You can uncomment this when SMS service is available
                                // smsService.sendSms(acceptedOrder.getCustomer().getMobileNumber(), smsMessage);
                                log.info("📲 SMS fallback notification would be sent to: {}", acceptedOrder.getCustomer().getMobileNumber());
                            }
                        } catch (Exception smsException) {
                            log.error("❌ SMS fallback also failed", smsException);
                        }
                    }
                } else {
                    log.warn("No FCM token found for customer user ID: {}", userId);
                }
            }
        } catch (Exception e) {
            log.error("Failed to send push notification to customer", e);
        }
        
        log.info("Order accepted successfully with notifications sent: {}", acceptedOrder.getOrderNumber());
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
    
    @Transactional(readOnly = true)
    public Map<String, Object> getOrderTracking(Long orderId) {
        log.info("Fetching tracking information for order: {}", orderId);
        
        Order order = orderRepository.findByIdWithOrderItems(orderId)
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
        trackingInfo.put("shopPhone", order.getShop().getOwnerPhone());
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
                "status", "READY_FOR_PICKUP",
                "label", "Ready for Pickup/Delivery",
                "description", "Your order is ready",
                "timestamp", order.getStatus().ordinal() >= Order.OrderStatus.READY_FOR_PICKUP.ordinal() ? 
                    order.getUpdatedAt() : null,
                "completed", order.getStatus().ordinal() >= Order.OrderStatus.READY_FOR_PICKUP.ordinal(),
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
            case READY -> 65;
            case READY_FOR_PICKUP -> 70;
            case OUT_FOR_DELIVERY -> 85;
            case DELIVERED -> 100;
            case COMPLETED -> 100;
            case CANCELLED -> 0;
            case REFUNDED -> 0;
            default -> 0;
        };
    }
    
    private String getStatusLabel(Order.OrderStatus status) {
        return switch (status) {
            case PENDING -> "Order Placed";
            case CONFIRMED -> "Order Confirmed";
            case PREPARING -> "Being Prepared";
            case READY -> "Ready";
            case READY_FOR_PICKUP -> "Ready for Pickup";
            case OUT_FOR_DELIVERY -> "Out for Delivery";
            case DELIVERED -> "Delivered";
            case COMPLETED -> "Completed";
            case CANCELLED -> "Cancelled";
            case REFUNDED -> "Refunded";
            default -> "Unknown";
        };
    }
    
    private String getCurrentUsername() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication != null && authentication.isAuthenticated() && 
                !"anonymousUser".equals(authentication.getPrincipal())) {
                return authentication.getName();
            }
        } catch (Exception e) {
            log.warn("Could not get current username: {}", e.getMessage());
        }
        return "system";
    }
    
    private OrderResponse mapToResponse(Order order) {
        return mapToResponse(order, null);
    }

    private OrderResponse mapToResponse(Order order, Boolean assignedToDeliveryPartner) {
        List<OrderResponse.OrderItemResponse> itemResponses = order.getOrderItems().stream()
                .map(item -> {
                    ShopProduct shopProduct = item.getShopProduct();
                    MasterProduct masterProduct = shopProduct.getMasterProduct();
                    Shop shop = shopProduct.getShop();

                    // Get product image - fallback to master product images if order item doesn't have one
                    String productImageUrl = item.getProductImageUrl();
                    if (productImageUrl == null || productImageUrl.isEmpty()) {
                        if (masterProduct.getImages() != null && !masterProduct.getImages().isEmpty()) {
                            productImageUrl = masterProduct.getImages().iterator().next().getImageUrl();
                        }
                    }

                    return OrderResponse.OrderItemResponse.builder()
                            .id(item.getId())
                            .shopProductId(shopProduct.getId())
                            .productName(item.getProductName())
                            .productDescription(item.getProductDescription())
                            .productSku(item.getProductSku())
                            .productImageUrl(productImageUrl)
                            .unit(masterProduct.getBaseUnit())
                            .shopId(shop.getId())
                            .shopName(shop.getName())
                            .quantity(item.getQuantity())
                            .unitPrice(item.getUnitPrice())
                            .totalPrice(item.getTotalPrice())
                            .specialInstructions(item.getSpecialInstructions())
                            .build();
                })
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

        // Use provided assignedToDeliveryPartner if available, otherwise try to get from order
        Boolean isAssigned = assignedToDeliveryPartner != null ?
                assignedToDeliveryPartner :
                order.getAssignedToDeliveryPartner();

        log.info("📦 Mapping order {}: assignedToDeliveryPartner param={}, from order={}, final={}",
                order.getOrderNumber(), assignedToDeliveryPartner,
                order.getAssignedToDeliveryPartner(), isAssigned);

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
                .assignedToDeliveryPartner(isAssigned)
                .orderAge(orderAge)
                .itemCount(order.getOrderItems().size())
                .build();
    }
    
    @Transactional
    public OrderResponse createCustomerOrder(CustomerOrderRequest request) {
        log.info("Creating customer order for shop: {}", request.getShopId());
        
        // Validate request
        if (request.getShopId() == null) {
            throw new IllegalArgumentException("Shop ID is required");
        }
        
        if (request.getItems() == null || request.getItems().isEmpty()) {
            throw new IllegalArgumentException("Order items are required");
        }

        // Validate delivery address only for HOME_DELIVERY orders
        String deliveryType = request.getDeliveryType() != null ? request.getDeliveryType() : "HOME_DELIVERY";
        if ("HOME_DELIVERY".equals(deliveryType)) {
            if (request.getDeliveryAddress() == null) {
                throw new IllegalArgumentException("Delivery address is required for home delivery");
            }
        }

        if (request.getCustomerInfo() == null) {
            throw new IllegalArgumentException("Customer information is required");
        }
        
        // Create a customer if not exists (guest checkout)
        Customer customer = null;
        if (request.getCustomerId() != null) {
            customer = customerRepository.findById(request.getCustomerId())
                    .orElseThrow(() -> new RuntimeException("Customer not found"));
        } else {
            // Try to find/create customer from auth context first
            String currentUsername = getCurrentUsername();
            if (currentUsername != null && !currentUsername.equals("system")) {
                try {
                    User currentUser = userRepository.findByUsername(currentUsername).orElse(null);
                    if (currentUser != null) {
                        customer = findOrCreateCustomerByUserId(currentUser.getId());
                        log.info("Found/created customer from auth context for user: {}", currentUsername);
                    }
                } catch (Exception e) {
                    log.warn("Could not create customer from auth context: {}", e.getMessage());
                }
            }
            
            // If no customer from auth, create guest customer with validation
            if (customer == null) {
                String firstName = request.getCustomerInfo().getFirstName();
                String lastName = request.getCustomerInfo().getLastName();
                String email = request.getCustomerInfo().getEmail();
                String phone = request.getCustomerInfo().getPhone();
            
            if (firstName == null || firstName.trim().isEmpty()) {
                throw new IllegalArgumentException("Customer first name is required");
            }
            
            if (phone == null || phone.trim().isEmpty()) {
                throw new IllegalArgumentException("Customer phone is required");
            }
            
            // Check if customer already exists by email or phone
            if (email != null && !email.trim().isEmpty()) {
                Customer existingCustomer = customerRepository.findByEmail(email).orElse(null);
                if (existingCustomer != null) {
                    customer = existingCustomer;
                    log.info("Using existing customer by email: {}", email);
                }
            }
            
            if (customer == null) {
                // Try to find by phone
                // Note: You may need to add findByMobileNumber to your repository
                customer = Customer.builder()
                        .firstName(firstName.trim())
                        .lastName(lastName != null ? lastName.trim() : "")
                        .email(email != null ? email.trim() : "")
                        .mobileNumber(phone.trim())
                        .isActive(true)
                        .build();
                
                try {
                    customer = customerRepository.save(customer);
                    log.info("Created new guest customer with phone: {}", phone);
                } catch (Exception e) {
                    log.error("Error creating guest customer: {}", e.getMessage());
                    throw new RuntimeException("Failed to create customer: " + e.getMessage());
                }
            }
            }
        }
        
        // Validate shop
        Shop shop = shopRepository.findById(request.getShopId())
                .orElseThrow(() -> new RuntimeException("Shop not found"));
        
        // Create order items
        List<OrderItem> orderItems = request.getItems().stream()
                .map(itemRequest -> {
                    ShopProduct shopProduct = shopProductRepository.findById(itemRequest.getProductId())
                            .orElseThrow(() -> new RuntimeException("Product not found"));
                    
                    BigDecimal itemTotal = itemRequest.getPrice()
                            .multiply(BigDecimal.valueOf(itemRequest.getQuantity()));
                    
                    return OrderItem.builder()
                            .shopProduct(shopProduct)
                            .quantity(itemRequest.getQuantity())
                            .unitPrice(itemRequest.getPrice())
                            .totalPrice(itemTotal)
                            .productName(itemRequest.getProductName())
                            .productDescription(shopProduct.getMasterProduct().getDescription())
                            .productSku(shopProduct.getMasterProduct().getSku())
                            .productImageUrl(shopProduct.getMasterProduct().getPrimaryImageUrl())
                            .build();
                })
                .collect(Collectors.toList());
        
        // Create order
        Order order = Order.builder()
                .customer(customer)
                .shop(shop)
                .status(Order.OrderStatus.PENDING)
                .paymentStatus(Order.PaymentStatus.PENDING)
                .paymentMethod(Order.PaymentMethod.valueOf(request.getPaymentMethod()))
                .subtotal(request.getSubtotal())
                .taxAmount(BigDecimal.ZERO)
                .deliveryFee(request.getDeliveryFee())
                .discountAmount(request.getDiscount())
                .totalAmount(request.getTotal())
                .notes(request.getNotes())
                .deliveryType(Order.DeliveryType.valueOf(deliveryType))
                .deliveryAddress(request.getDeliveryAddress() != null ? request.getDeliveryAddress().getStreetAddress() : null)
                .deliveryCity(request.getDeliveryAddress() != null ? request.getDeliveryAddress().getCity() : null)
                .deliveryState(request.getDeliveryAddress() != null ? request.getDeliveryAddress().getState() : null)
                .deliveryPostalCode(request.getDeliveryAddress() != null ? request.getDeliveryAddress().getPincode() : null)
                .deliveryPhone(request.getCustomerInfo().getPhone())
                .deliveryContactName(request.getCustomerInfo().getFirstName() + " " + request.getCustomerInfo().getLastName())
                .estimatedDeliveryTime(LocalDateTime.now().plusMinutes(30))
                .createdBy("customer")
                .updatedBy("customer")
                .build();
        
        // Set order reference in items
        orderItems.forEach(item -> item.setOrder(order));
        order.setOrderItems(orderItems);

        Order savedOrder = orderRepository.save(order);

        // Send FCM push notification to shop owner
        try {
            log.info("🔔 Attempting to send FCM notification to shop owner: {}", shop.getOwnerEmail());

            // Find shop owner's user record
            Optional<User> shopOwnerOpt = userRepository.findByEmail(shop.getOwnerEmail());
            if (shopOwnerOpt.isPresent()) {
                User shopOwner = shopOwnerOpt.get();
                log.info("✅ Found shop owner user: ID={}, Role={}", shopOwner.getId(), shopOwner.getRole());

                // Get all active FCM tokens for shop owner
                List<UserFcmToken> fcmTokens = userFcmTokenRepository.findActiveTokensByUserId(shopOwner.getId());
                log.info("📱 Found {} active FCM token(s) for shop owner", fcmTokens.size());

                if (!fcmTokens.isEmpty()) {
                    // Send notification to all active devices
                    for (UserFcmToken fcmToken : fcmTokens) {
                        try {
                            log.info("📤 Sending FCM to device: {}", fcmToken.getDeviceType());
                            firebaseNotificationService.sendOrderNotification(
                                savedOrder.getOrderNumber(),
                                "PENDING",
                                fcmToken.getFcmToken(),
                                shopOwner.getId()
                            );
                            log.info("✅ FCM notification sent successfully to shop owner's device");
                        } catch (Exception e) {
                            log.error("❌ Failed to send FCM to device {}: {}", fcmToken.getDeviceType(), e.getMessage());
                        }
                    }
                } else {
                    log.warn("⚠️ No active FCM tokens found for shop owner {}", shop.getOwnerEmail());
                }
            } else {
                log.warn("⚠️ Shop owner user not found for email: {}", shop.getOwnerEmail());
            }
        } catch (Exception e) {
            log.error("❌ Failed to send FCM notification to shop owner", e);
        }

        log.info("Customer order created successfully: {}", savedOrder.getOrderNumber());
        return mapToResponse(savedOrder);
    }
    
    public OrderTrackingResponse getOrderTracking(String orderNumber) {
        log.info("Getting tracking for order: {}", orderNumber);
        
        Order order = orderRepository.findByOrderNumberWithOrderItems(orderNumber)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        
        // Create status history
        List<OrderTrackingResponse.OrderStatusUpdate> statusHistory = List.of(
            new OrderTrackingResponse.OrderStatusUpdate() {{
                setStatus("PLACED");
                setTimestamp(order.getCreatedAt());
                setMessage("Order placed successfully");
            }},
            new OrderTrackingResponse.OrderStatusUpdate() {{
                setStatus("CONFIRMED");
                setTimestamp(order.getStatus().ordinal() >= Order.OrderStatus.CONFIRMED.ordinal() ? 
                    order.getUpdatedAt() : null);
                setMessage("Order confirmed by restaurant");
            }},
            new OrderTrackingResponse.OrderStatusUpdate() {{
                setStatus("PREPARING");
                setTimestamp(order.getStatus().ordinal() >= Order.OrderStatus.PREPARING.ordinal() ? 
                    order.getUpdatedAt() : null);
                setMessage("Order is being prepared");
            }}
        );
        
        // Create delivery partner info (mock for now)
        OrderTrackingResponse.DeliveryPartnerInfo deliveryPartner = null;
        if (order.getStatus().ordinal() >= Order.OrderStatus.OUT_FOR_DELIVERY.ordinal()) {
            deliveryPartner = new OrderTrackingResponse.DeliveryPartnerInfo();
            deliveryPartner.setId(1L);
            deliveryPartner.setName("Ravi Kumar");
            deliveryPartner.setPhone("+91 98765 43210");
            deliveryPartner.setVehicleType("Bike");
            deliveryPartner.setVehicleNumber("TN01AB1234");
            deliveryPartner.setRating(4.8);
        }
        
        OrderTrackingResponse response = new OrderTrackingResponse();
        response.setOrderId(order.getId());
        response.setOrderNumber(order.getOrderNumber());
        response.setStatus(order.getStatus().name());
        response.setTotal(order.getTotalAmount());
        response.setStatusHistory(statusHistory);
        response.setDeliveryPartner(deliveryPartner);
        response.setEstimatedDeliveryTime("20 minutes");
        
        return response;
    }
    
    public List<OrderResponse> getCustomerOrders(Long customerId, int page, int size) {
        log.info("Getting orders for customer: {}", customerId);
        
        if (customerId == null) {
            return List.of(); // Return empty list for guest customers
        }
        
        Page<OrderResponse> orders = getOrdersByCustomer(customerId, page, size);
        return orders.getContent();
    }
    
    public void rateOrder(Long orderId, int rating, String review) {
        log.info("Rating order: {} with rating: {}", orderId, rating);

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        if (order.getStatus() != Order.OrderStatus.DELIVERED) {
            throw new RuntimeException("Order must be delivered to rate");
        }

        // Add rating logic here (would need OrderRating entity)
        // For now, just log the rating
        log.info("Order {} rated with {} stars. Review: {}", orderId, rating, review);
    }

    @Transactional
    public String reorderItems(Long orderId, Long userId) {
        log.info("Reordering items from order: {} for user: {}", orderId, userId);

        // Get the order with items
        Order order = orderRepository.findByIdWithOrderItems(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        // For now, return a success message
        // In a real implementation, this would:
        // 1. Find or create a cart for the user
        // 2. Add all order items to the cart
        // 3. Return the cart details

        int itemCount = order.getOrderItems().size();
        log.info("Successfully added {} items from order {} to cart for user {}", itemCount, orderId, userId);

        return String.format("Added %d items to cart", itemCount);
    }
    
    private Customer findOrCreateCustomerByUserId(Long userId) {
        log.info("Finding or creating customer for userId: {}", userId);
        
        if (userId == null) {
            throw new RuntimeException("User ID cannot be null");
        }
        
        // First, find the user
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with ID: " + userId));
        
        // Check if customer already exists with the same email
        Customer customer = customerRepository.findByEmail(user.getEmail()).orElse(null);
        
        if (customer == null) {
            // Create new customer from user data
            log.info("Creating new customer for user: {}", user.getEmail());
            
            // Generate a proper mobile number if user doesn't have one
            String mobileNumber = user.getMobileNumber();
            if (mobileNumber == null || mobileNumber.trim().isEmpty()) {
                // Use email username + random digits for mobile number if not available
                String emailPrefix = user.getEmail().split("@")[0];
                mobileNumber = "9" + String.format("%09d", Math.abs(emailPrefix.hashCode() % 1000000000));
            }
            
            customer = Customer.builder()
                    .firstName(user.getFirstName() != null && !user.getFirstName().trim().isEmpty() ? user.getFirstName() : "Customer")
                    .lastName(user.getLastName() != null && !user.getLastName().trim().isEmpty() ? user.getLastName() : "User")
                    .email(user.getEmail())
                    .mobileNumber(mobileNumber)
                    .isActive(true)
                    .isVerified(user.getEmailVerified() != null ? user.getEmailVerified() : false)
                    .build();
            
            try {
                customer = customerRepository.save(customer);
                log.info("Customer created with ID: {} for user: {}", customer.getId(), user.getEmail());
            } catch (Exception e) {
                log.error("Error creating customer for user: {}", user.getEmail(), e);
                throw new RuntimeException("Failed to create customer: " + e.getMessage());
            }
        } else {
            log.info("Found existing customer with ID: {} for user: {}", customer.getId(), user.getEmail());
        }
        
        return customer;
    }

    private List<String> getFcmTokensForUser(Long userId) {
        try {
            log.info("🔍 Looking up FCM tokens for user ID: {}", userId);

            // Get the most recent active FCM tokens for the user (ordered by updatedAt DESC)
            List<UserFcmToken> tokens = userFcmTokenRepository.findActiveTokensByUserId(userId);

            log.info("📊 Found {} active FCM tokens for user ID: {}", tokens.size(), userId);

            if (!tokens.isEmpty()) {
                List<String> fcmTokens = tokens.stream()
                        .map(token -> {
                            String fcmToken = token.getFcmToken();
                            log.info("✅ Retrieved FCM token for user {}: {}... (device: {}, updated: {})",
                                    userId,
                                    fcmToken.substring(0, Math.min(30, fcmToken.length())),
                                    token.getDeviceType(),
                                    token.getUpdatedAt());
                            return fcmToken;
                        })
                        .toList();
                return fcmTokens;
            } else {
                log.warn("⚠️ No active FCM tokens found for user ID: {}", userId);
            }
        } catch (Exception e) {
            log.error("❌ Error getting FCM tokens for user {}: {}", userId, e.getMessage(), e);
        }

        return List.of();
    }

    private void createOrderStatusNotification(Order order, Order.OrderStatus oldStatus, Order.OrderStatus newStatus) {
        log.info("Creating notification for order {} status change: {} -> {}", order.getOrderNumber(), oldStatus, newStatus);

        String title = "";
        String message = "";
        Notification.NotificationType notificationType = Notification.NotificationType.ORDER;

        switch (newStatus) {
            case CONFIRMED:
                title = "Order Confirmed! 🎉";
                message = String.format("Your order %s from %s has been confirmed and will be prepared soon.",
                        order.getOrderNumber(), order.getShop().getName());
                break;
            case PREPARING:
                title = "Order Being Prepared 👨‍🍳";
                message = String.format("Your order %s is being prepared by %s.",
                        order.getOrderNumber(), order.getShop().getName());
                break;
            case READY_FOR_PICKUP:
                title = "Order Ready for Pickup 📦";
                message = String.format("Your order %s is ready and will be picked up soon for delivery.",
                        order.getOrderNumber());
                break;
            case OUT_FOR_DELIVERY:
                title = "Out for Delivery 🚚";
                message = String.format("Your order %s is on its way! Your delivery partner will reach you soon.",
                        order.getOrderNumber());
                break;
            case DELIVERED:
                title = "Order Delivered ✅";
                message = String.format("Your order %s has been delivered successfully. Thank you for your order!",
                        order.getOrderNumber());
                break;
            case CANCELLED:
                title = "Order Cancelled ❌";
                message = String.format("Your order %s has been cancelled.",
                        order.getOrderNumber());
                break;
            default:
                title = "Order Status Updated 📋";
                message = String.format("Your order %s status has been updated to %s.",
                        order.getOrderNumber(), newStatus.name());
                break;
        }

        try {
            Notification notification = Notification.builder()
                    .title(title)
                    .message(message)
                    .type(notificationType)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .status(Notification.NotificationStatus.UNREAD)
                    .recipientId(order.getCustomer().getId())
                    .recipientType(Notification.RecipientType.CUSTOMER)
                    .referenceId(order.getId())
                    .referenceType("ORDER")
                    .category("ORDER_STATUS")
                    .isActive(true)
                    .isPersistent(true)
                    .build();

            notificationRepository.save(notification);
            log.info("✅ Notification created successfully for order: {}", order.getOrderNumber());
        } catch (Exception e) {
            log.error("❌ Failed to create notification for order {}: {}", order.getOrderNumber(), e.getMessage(), e);
        }
    }
}