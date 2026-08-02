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
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import org.springframework.data.domain.PageRequest;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class PosService {

    private final OrderRepository orderRepository;
    private final ShopRepository shopRepository;
    private final ShopProductRepository shopProductRepository;
    private final CustomerRepository customerRepository;
    private final BillPdfService billPdfService;
    private final WhatsAppNotificationService whatsAppNotificationService;
    private final EmailService emailService;

    @Value("${app.upload.dir:./uploads}")
    private String uploadDir;

    @Value("${app.api.base-url:https://api.nammaoorudelivary.in}")
    private String apiBaseUrl;

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

        // 3. OPTIMIZED: Batch fetch all products at once
        List<Long> productIds = request.getItems().stream()
                .map(PosOrderItemRequest::getShopProductId)
                .toList();
        List<ShopProduct> shopProducts = shopProductRepository.findAllById(productIds);

        // Create a map for O(1) lookup
        java.util.Map<Long, ShopProduct> productMap = shopProducts.stream()
                .collect(java.util.stream.Collectors.toMap(ShopProduct::getId, p -> p));

        // Validate all products exist
        for (Long productId : productIds) {
            if (!productMap.containsKey(productId)) {
                throw new RuntimeException("Product not found: " + productId);
            }
        }

        // 4. Process items and prepare inventory updates
        List<OrderItem> orderItems = new ArrayList<>();
        List<ShopProduct> productsToUpdate = new ArrayList<>();
        BigDecimal subtotal = BigDecimal.ZERO;

        for (PosOrderItemRequest itemRequest : request.getItems()) {
            ShopProduct shopProduct = productMap.get(itemRequest.getShopProductId());

            // Check and prepare stock deduction
            if (shopProduct.getTrackInventory() != null && shopProduct.getTrackInventory()) {
                Integer currentStock = shopProduct.getStockQuantity() != null ? shopProduct.getStockQuantity() : 0;
                if (currentStock < itemRequest.getQuantity()) {
                    String stockProductName = shopProduct.getCustomName();
                    if (stockProductName == null && shopProduct.getMasterProduct() != null) {
                        stockProductName = shopProduct.getMasterProduct().getName();
                    }
                    if (stockProductName == null) {
                        stockProductName = "Product #" + shopProduct.getId();
                    }
                    throw new RuntimeException(String.format(
                            "Insufficient stock for %s. Available: %d, Requested: %d",
                            stockProductName, currentStock, itemRequest.getQuantity()));
                }

                // Deduct stock (will batch save later)
                int newStock = currentStock - itemRequest.getQuantity();
                shopProduct.setStockQuantity(newStock);

                if (newStock == 0) {
                    shopProduct.setStatus(ShopProduct.ShopProductStatus.OUT_OF_STOCK);
                    shopProduct.setIsAvailable(false);
                }

                productsToUpdate.add(shopProduct);
                log.debug("Stock prepared for deduction: product {}: {} -> {}", shopProduct.getId(), currentStock, newStock);
            }

            // Get price (use override if provided, else product price)
            BigDecimal unitPrice = itemRequest.getUnitPrice() != null
                    ? itemRequest.getUnitPrice()
                    : shopProduct.getPrice();
            BigDecimal itemTotal = unitPrice.multiply(BigDecimal.valueOf(itemRequest.getQuantity()));

            // Create order item with null-safe product name
            String productName = shopProduct.getCustomName();
            String productNameTamil = null;
            String productImageUrl = null;
            if (shopProduct.getMasterProduct() != null) {
                if (productName == null || productName.trim().isEmpty()) {
                    productName = shopProduct.getMasterProduct().getName();
                }
                productNameTamil = shopProduct.getMasterProduct().getNameTamil();
                productImageUrl = shopProduct.getMasterProduct().getPrimaryImageUrl();
            }
            if (productName == null || productName.trim().isEmpty()) {
                productName = "Product #" + shopProduct.getId();
            }

            OrderItem orderItem = OrderItem.builder()
                    .shopProduct(shopProduct)
                    .productName(productName)
                    .productNameTamil(productNameTamil)
                    .quantity(itemRequest.getQuantity())
                    .unitPrice(unitPrice)
                    .totalPrice(itemTotal)
                    .productImageUrl(productImageUrl)
                    .addedByShopOwner(true)
                    .build();

            orderItems.add(orderItem);
            subtotal = subtotal.add(itemTotal);
        }

        // 5. BATCH save all inventory updates at once
        if (!productsToUpdate.isEmpty()) {
            shopProductRepository.saveAll(productsToUpdate);
            log.info("Batch updated stock for {} products", productsToUpdate.size());
        }

        // 6. Calculate totals (no delivery fee, no tax for POS walk-in orders)
        BigDecimal taxAmount = BigDecimal.ZERO; // No tax for walk-in orders
        BigDecimal discountAmount = request.getDiscountAmount() != null ? request.getDiscountAmount() : BigDecimal.ZERO;
        BigDecimal totalAmount = subtotal.subtract(discountAmount);

        // 7. Create order
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

        // 8. Save order
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
     * Generate the bill PDF for an order and send it to the customer via WhatsApp.
     * phoneOverride/nameOverride let the shop owner fill in details at send-time
     * if they weren't captured when the bill was created.
     */
    @Transactional
    public void sendBillViaWhatsApp(Long orderId, String phoneOverride, String nameOverride) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));

        String phone = phoneOverride != null && !phoneOverride.trim().isEmpty()
                ? phoneOverride.trim()
                : (order.getCustomer() != null ? order.getCustomer().getMobileNumber() : null);

        if (phone == null || phone.trim().isEmpty()) {
            throw new RuntimeException("A customer phone number is required to send the bill via WhatsApp");
        }

        String name = nameOverride != null && !nameOverride.trim().isEmpty()
                ? nameOverride.trim()
                : (order.getCustomer() != null ? order.getCustomer().getFullName() : null);

        byte[] pdfBytes = billPdfService.generateBillPdf(order);

        try {
            String fileName = "bill_" + order.getOrderNumber() + "_" + UUID.randomUUID().toString().substring(0, 8) + ".pdf";
            Path billsDir = Paths.get(uploadDir, "bills");
            Files.createDirectories(billsDir);
            Files.write(billsDir.resolve(fileName), pdfBytes);

            String pdfUrl = apiBaseUrl + "/uploads/bills/" + fileName;

            boolean sent = whatsAppNotificationService.sendBillDocument(
                    phone,
                    name,
                    order.getShop().getName(),
                    order.getOrderNumber(),
                    order.getTotalAmount().toPlainString(),
                    pdfUrl,
                    "Bill-" + order.getOrderNumber() + ".pdf"
            );

            if (!sent) {
                throw new RuntimeException("WhatsApp send failed. Possible reasons: bill_receipt template not yet approved, access token expired, or recipient not allowed (test numbers can only message registered recipients). Check backend logs for the exact WhatsApp API error.");
            }
        } catch (java.io.IOException e) {
            log.error("Failed to store bill PDF for order {}", order.getOrderNumber(), e);
            throw new RuntimeException("Failed to save bill PDF", e);
        }
    }

    /**
     * Generate the bill PDF for an order and email it to the customer.
     * emailOverride/nameOverride let the shop owner fill in details at send-time
     * if they weren't captured when the bill was created.
     */
    @Transactional
    public void sendBillViaEmail(Long orderId, String emailOverride, String nameOverride) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));

        String email = emailOverride != null && !emailOverride.trim().isEmpty()
                ? emailOverride.trim()
                : (order.getCustomer() != null ? order.getCustomer().getEmail() : null);

        if (email == null || email.trim().isEmpty()) {
            throw new RuntimeException("A customer email address is required to send the bill via email");
        }

        String name = nameOverride != null && !nameOverride.trim().isEmpty()
                ? nameOverride.trim()
                : (order.getCustomer() != null ? order.getCustomer().getFullName() : null);

        byte[] pdfBytes = billPdfService.generateBillPdf(order);

        emailService.sendBillEmail(
                email,
                name,
                order.getShop().getName(),
                order.getOrderNumber(),
                order.getTotalAmount().toPlainString(),
                pdfBytes,
                "Bill-" + order.getOrderNumber() + ".pdf"
        );
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
    /**
     * Search customers previously billed at this shop by mobile number or name.
     * Used by the POS billing customer autocomplete.
     */
    @Transactional(readOnly = true)
    public List<Map<String, Object>> searchCustomers(Long shopId, String query) {
        String q = query == null ? "" : query.trim();
        List<Object[]> rows = orderRepository.searchShopCustomers(shopId, q, PageRequest.of(0, 10));
        List<Map<String, Object>> results = new ArrayList<>();
        for (Object[] row : rows) {
            String mobileNumber = (String) row[0];
            String firstName = (String) row[1];
            String lastName = (String) row[2];
            // POS-created customers get a placeholder "POS" last name - don't show it
            String name = (lastName == null || "POS".equalsIgnoreCase(lastName))
                    ? (firstName == null ? "" : firstName.trim())
                    : (firstName + " " + lastName).trim();
            Map<String, Object> entry = new HashMap<>();
            entry.put("customerName", name);
            entry.put("customerPhone", mobileNumber);
            entry.put("billCount", row[3]);
            entry.put("lastOrderDate", row[4] != null ? row[4].toString() : null);
            results.add(entry);
        }
        return results;
    }

    private OrderResponse mapToResponse(Order order) {
        List<OrderResponse.OrderItemResponse> itemResponses = order.getOrderItems().stream()
                .map(item -> OrderResponse.OrderItemResponse.builder()
                        .id(item.getId())
                        .productName(item.getProductName())
                        .productNameTamil(item.getProductNameTamil())
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
