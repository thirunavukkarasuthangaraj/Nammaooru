package com.shopmanagement.service;

import com.shopmanagement.dto.order.OrderResponse;
import com.shopmanagement.dto.order.PosOrderItemRequest;
import com.shopmanagement.dto.order.PosOrderRequest;
import com.shopmanagement.entity.Customer;
import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderItem;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.product.repository.ShopProductRepository;
import com.shopmanagement.repository.CustomerRepository;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.repository.ShopRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class PosService {

    private final OrderRepository orderRepository;
    private final ShopRepository shopRepository;
    private final ShopProductRepository shopProductRepository;
    private final CustomerRepository customerRepository;

    /**
     * Create a POS order for walk-in customers
     * - Immediate inventory deduction
     * - No delivery flow
     * - Status set to SELF_PICKUP_COLLECTED
     */
    @Transactional
    public OrderResponse createPosOrder(PosOrderRequest request) {
        log.info("Creating POS order for shop: {}", request.getShopId());

        // 1. Validate shop
        Shop shop = shopRepository.findById(request.getShopId())
                .orElseThrow(() -> new RuntimeException("Shop not found with id: " + request.getShopId()));

        // 2. Get or create walk-in customer
        Customer customer = getOrCreateWalkInCustomer(request, shop);

        // 3. Process items and deduct inventory
        List<OrderItem> orderItems = new ArrayList<>();
        BigDecimal subtotal = BigDecimal.ZERO;

        for (PosOrderItemRequest itemRequest : request.getItems()) {
            ShopProduct shopProduct = shopProductRepository.findById(itemRequest.getShopProductId())
                    .orElseThrow(() -> new RuntimeException("Product not found: " + itemRequest.getShopProductId()));

            // Check and deduct stock
            if (shopProduct.getTrackInventory()) {
                Integer currentStock = shopProduct.getStockQuantity() != null ? shopProduct.getStockQuantity() : 0;
                if (currentStock < itemRequest.getQuantity()) {
                    throw new RuntimeException(String.format(
                            "Insufficient stock for %s. Available: %d, Requested: %d",
                            shopProduct.getCustomName() != null ? shopProduct.getCustomName() : shopProduct.getMasterProduct().getName(),
                            currentStock, itemRequest.getQuantity()));
                }

                // Deduct stock
                int newStock = currentStock - itemRequest.getQuantity();
                shopProduct.setStockQuantity(newStock);

                if (newStock == 0) {
                    shopProduct.setStatus(ShopProduct.ShopProductStatus.OUT_OF_STOCK);
                    shopProduct.setIsAvailable(false);
                }

                shopProductRepository.save(shopProduct);
                log.info("Stock deducted for product {}: {} -> {}", shopProduct.getId(), currentStock, newStock);
            }

            // Get price (use override if provided, else product price)
            BigDecimal unitPrice = itemRequest.getUnitPrice() != null
                    ? itemRequest.getUnitPrice()
                    : shopProduct.getPrice();
            BigDecimal itemTotal = unitPrice.multiply(BigDecimal.valueOf(itemRequest.getQuantity()));

            // Create order item
            OrderItem orderItem = OrderItem.builder()
                    .shopProduct(shopProduct)
                    .productName(shopProduct.getCustomName() != null
                            ? shopProduct.getCustomName()
                            : shopProduct.getMasterProduct().getName())
                    .quantity(itemRequest.getQuantity())
                    .unitPrice(unitPrice)
                    .totalPrice(itemTotal)
                    .productImageUrl(shopProduct.getMasterProduct().getPrimaryImageUrl())
                    .addedByShopOwner(true)
                    .build();

            orderItems.add(orderItem);
            subtotal = subtotal.add(itemTotal);
        }

        // 4. Calculate totals (no delivery fee for POS)
        BigDecimal taxAmount = subtotal.multiply(BigDecimal.valueOf(0.05)); // 5% tax
        BigDecimal discountAmount = request.getDiscountAmount() != null ? request.getDiscountAmount() : BigDecimal.ZERO;
        BigDecimal totalAmount = subtotal.add(taxAmount).subtract(discountAmount);

        // 5. Create order
        Order order = Order.builder()
                .customer(customer)
                .shop(shop)
                .orderType(Order.OrderType.WALK_IN)
                .deliveryType(Order.DeliveryType.SELF_PICKUP)
                .status(Order.OrderStatus.SELF_PICKUP_COLLECTED) // Immediate completion
                .paymentStatus(Order.PaymentStatus.PAID) // Paid at counter
                .paymentMethod(request.getPaymentMethod())
                .subtotal(subtotal)
                .taxAmount(taxAmount)
                .deliveryFee(BigDecimal.ZERO)
                .discountAmount(discountAmount)
                .totalAmount(totalAmount)
                .notes(request.getNotes())
                .createdBy(getCurrentUsername())
                .updatedBy(getCurrentUsername())
                .build();

        // Set order reference on items
        for (OrderItem item : orderItems) {
            item.setOrder(order);
        }
        order.setOrderItems(orderItems);

        // 6. Save order
        Order savedOrder = orderRepository.save(order);
        log.info("POS order created: {} - Total: {}", savedOrder.getOrderNumber(), totalAmount);

        return mapToResponse(savedOrder);
    }

    /**
     * Sync multiple offline orders
     */
    @Transactional
    public List<OrderResponse> syncOfflineOrders(List<PosOrderRequest> requests) {
        log.info("Syncing {} offline orders", requests.size());

        List<OrderResponse> responses = new ArrayList<>();
        for (PosOrderRequest request : requests) {
            try {
                // Check if order already synced (by offlineOrderId)
                if (request.getOfflineOrderId() != null) {
                    // Could check for duplicate sync here
                    log.info("Processing offline order: {}", request.getOfflineOrderId());
                }
                OrderResponse response = createPosOrder(request);
                responses.add(response);
            } catch (Exception e) {
                log.error("Failed to sync offline order: {}", e.getMessage());
                // Continue with other orders
            }
        }

        return responses;
    }

    /**
     * Get all products for a shop (for offline caching)
     */
    public List<ShopProduct> getShopProductsForCache(Long shopId) {
        return shopProductRepository.findByShopIdAndIsAvailable(shopId, true);
    }

    /**
     * Get or create a walk-in customer
     * Performance optimized: Reuses a single "Walk-in Customer" per shop
     * Only creates new customer if phone number is provided
     */
    private Customer getOrCreateWalkInCustomer(PosOrderRequest request, Shop shop) {
        String customerPhone = request.getCustomerPhone();
        String customerName = request.getCustomerName();

        // If phone provided, try to find existing customer or create new
        if (customerPhone != null && !customerPhone.trim().isEmpty()) {
            Customer existing = customerRepository.findByMobileNumber(customerPhone).orElse(null);
            if (existing != null) {
                return existing;
            }

            // Create new customer with real phone number
            Customer newCustomer = Customer.builder()
                    .firstName(customerName != null && !customerName.trim().isEmpty()
                            ? customerName
                            : "Customer")
                    .lastName("POS")
                    .mobileNumber(customerPhone)
                    .email(customerPhone + "@pos.local")
                    .createdBy(getCurrentUsername())
                    .updatedBy(getCurrentUsername())
                    .build();

            return customerRepository.save(newCustomer);
        }

        // No phone provided - use shared walk-in customer for this shop
        // This avoids creating thousands of dummy customer records
        // Use a valid phone format: 9000000 + shopId (padded to 10 digits)
        String walkInPhone = String.format("90000%05d", shop.getId());
        Customer walkInCustomer = customerRepository.findByMobileNumber(walkInPhone).orElse(null);

        if (walkInCustomer == null) {
            // Create one walk-in customer per shop (first time only)
            walkInCustomer = Customer.builder()
                    .firstName("Walk-in")
                    .lastName("Customer")
                    .mobileNumber(walkInPhone)
                    .email("walkin-" + shop.getId() + "@pos.local")
                    .createdBy(getCurrentUsername())
                    .updatedBy(getCurrentUsername())
                    .build();

            walkInCustomer = customerRepository.save(walkInCustomer);
            log.info("Created walk-in customer for shop: {}", shop.getId());
        }

        return walkInCustomer;
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated()) {
            return authentication.getName();
        }
        return "system";
    }

    /**
     * Map Order entity to OrderResponse DTO
     */
    private OrderResponse mapToResponse(Order order) {
        List<OrderResponse.OrderItemResponse> itemResponses = order.getOrderItems().stream()
                .map(item -> OrderResponse.OrderItemResponse.builder()
                        .id(item.getId())
                        .productName(item.getProductName())
                        .quantity(item.getQuantity())
                        .unitPrice(item.getUnitPrice())
                        .totalPrice(item.getTotalPrice())
                        .productImageUrl(item.getProductImageUrl())
                        .addedByShopOwner(item.getAddedByShopOwner())
                        .build())
                .collect(Collectors.toList());

        return OrderResponse.builder()
                .id(order.getId())
                .orderNumber(order.getOrderNumber())
                .customerId(order.getCustomer().getId())
                .customerName(order.getCustomer().getFullName())
                .customerPhone(order.getCustomer().getMobileNumber())
                .shopId(order.getShop().getId())
                .shopName(order.getShop().getName())
                .status(order.getStatus())
                .orderType(order.getOrderType())
                .paymentStatus(order.getPaymentStatus())
                .paymentMethod(order.getPaymentMethod())
                .deliveryType(order.getDeliveryType() != null ? order.getDeliveryType().name() : null)
                .subtotal(order.getSubtotal())
                .taxAmount(order.getTaxAmount())
                .deliveryFee(order.getDeliveryFee())
                .discountAmount(order.getDiscountAmount())
                .totalAmount(order.getTotalAmount())
                .notes(order.getNotes())
                .orderItems(itemResponses)
                .createdAt(order.getCreatedAt())
                .updatedAt(order.getUpdatedAt())
                .build();
    }
}
