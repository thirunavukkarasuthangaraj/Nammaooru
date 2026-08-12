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
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

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
    private final ShopWhatsAppUsageService shopWhatsAppUsageService;
    private final EmailService emailService;
    private final PlatformTransactionManager transactionManager;

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

        // 0. Idempotency: an offline order may be re-sent if the client timed out or
        // retried after a partial sync — return the already-created order, don't duplicate
        if (request.getOfflineOrderId() != null && !request.getOfflineOrderId().isBlank()) {
            var existing = orderRepository.findByShopIdAndOfflineOrderId(
                    request.getShopId(), request.getOfflineOrderId());
            if (existing.isPresent()) {
                log.info("Offline order {} already synced as {} - returning existing order",
                        request.getOfflineOrderId(), existing.get().getOrderNumber());
                return mapToResponse(existing.get());
            }
        }

        // 1. Validate shop
        Shop shop = shopRepository.findById(request.getShopId())
                .orElseThrow(() -> new RuntimeException("Shop not found with id: " + request.getShopId()));

        // 2. Get or create walk-in customer
        Customer customer = getOrCreateWalkInCustomer(request, shop);

        // 3. OPTIMIZED: Batch fetch all products at once
        // Custom items (typed name + price at the counter) have null/negative IDs and no catalog row
        List<Long> productIds = request.getItems().stream()
                .map(PosOrderItemRequest::getShopProductId)
                .filter(id -> id != null && id > 0)
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
            Long requestedProductId = itemRequest.getShopProductId();

            // Custom item: no catalog product, billed with the typed name and price
            if (requestedProductId == null || requestedProductId <= 0) {
                if (itemRequest.getUnitPrice() == null) {
                    throw new RuntimeException("Price is required for custom item");
                }
                String customName = itemRequest.getProductName() != null && !itemRequest.getProductName().isBlank()
                        ? itemRequest.getProductName().trim()
                        : "Custom Item";
                BigDecimal customTotal = itemRequest.getUnitPrice()
                        .multiply(BigDecimal.valueOf(itemRequest.getQuantity()));

                orderItems.add(OrderItem.builder()
                        .productName(customName)
                        .quantity(itemRequest.getQuantity())
                        .unitPrice(itemRequest.getUnitPrice())
                        .totalPrice(customTotal)
                        .addedByShopOwner(true)
                        .build());
                subtotal = subtotal.add(customTotal);
                continue;
            }

            ShopProduct shopProduct = productMap.get(requestedProductId);

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
                .offlineOrderId(request.getOfflineOrderId() != null && !request.getOfflineOrderId().isBlank()
                        ? request.getOfflineOrderId() : null)
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

        // The shared per-shop walk-in customer has a placeholder number (90000 + shop id).
        // It is not a real phone — sending to it silently goes nowhere.
        if (phone != null && phone.matches("^90000\\d{5}$")) {
            phone = null;
        }

        if (phone == null || phone.trim().isEmpty()) {
            throw new RuntimeException("A customer phone number is required to send the bill via WhatsApp");
        }

        String name = nameOverride != null && !nameOverride.trim().isEmpty()
                ? nameOverride.trim()
                : (order.getCustomer() != null ? order.getCustomer().getFullName() : null);
        // "Walk-in Customer" is the shared placeholder's name, not the real person's
        if (name != null && name.toLowerCase().contains("walk-in")) {
            name = null;
        }

        // Common flow: bill printed without a customer (order linked to the shared
        // walk-in record), then the owner adds the real customer and sends. Re-link
        // the order to the real customer so the message, PDF and purchase history
        // stop saying "Walk-in Customer".
        if (order.getCustomer() != null
                && order.getCustomer().getMobileNumber() != null
                && order.getCustomer().getMobileNumber().matches("^90000\\d{5}$")) {
            Customer real = customerRepository.findFirstByMobileNumberOrderByIdAsc(phone).orElse(null);
            if (real == null) {
                Customer newCustomer = Customer.builder()
                        .firstName(name != null ? name : "Customer")
                        .lastName("POS")
                        .mobileNumber(phone)
                        .email(phone + "@pos.local")
                        .createdBy(getCurrentUsername())
                        .updatedBy(getCurrentUsername())
                        .build();
                real = saveCustomerOrFetchExisting(newCustomer, phone);
            }
            order.setCustomer(real);
            orderRepository.save(order);
        }
        if (name == null && order.getCustomer() != null
                && order.getCustomer().getFullName() != null
                && !order.getCustomer().getFullName().toLowerCase().contains("walk-in")) {
            name = order.getCustomer().getFullName();
        }

        byte[] pdfBytes = billPdfService.generateBillPdf(order);

        try {
            String suffix = UUID.randomUUID().toString().substring(0, 8);
            Path billsDir = Paths.get(uploadDir, "bills");
            Files.createDirectories(billsDir);

            String pdfFileName = "bill_" + order.getOrderNumber() + "_" + suffix + ".pdf";
            Files.write(billsDir.resolve(pdfFileName), pdfBytes);
            String pdfUrl = apiBaseUrl + "/uploads/bills/" + pdfFileName;

            // Include the shop's own number in the shop_name template variable so
            // customers can tap it and chat with the shop directly (bills go out
            // from the platform WhatsApp number, so replies there don't reach the shop)
            String ownerPhone = order.getShop().getOwnerPhone();
            String shopLabel = order.getShop().getName()
                    + (ownerPhone != null && !ownerPhone.isBlank() ? ", Ph: " + ownerPhone : "");

            // Prefer sending the bill as an inline IMAGE — it shows full-size in the
            // chat immediately, unlike a PDF which customers must tap to download.
            boolean sent = false;
            byte[] jpegBytes = renderBillJpeg(pdfBytes, order.getOrderNumber());
            if (jpegBytes != null) {
                String imgFileName = "bill_" + order.getOrderNumber() + "_" + suffix + ".jpg";
                Files.write(billsDir.resolve(imgFileName), jpegBytes);
                String imgUrl = apiBaseUrl + "/uploads/bills/" + imgFileName;
                sent = whatsAppNotificationService.sendBillImage(
                        phone, name, shopLabel,
                        order.getOrderNumber(), order.getTotalAmount().toPlainString(), imgUrl);
                if (!sent) {
                    log.warn("Bill image template send failed for {} - falling back to PDF template", order.getOrderNumber());
                }
            }

            // Fallback: PDF document template (also used until bill_receipt_image is approved)
            if (!sent) {
                sent = whatsAppNotificationService.sendBillDocument(
                        phone,
                        name,
                        shopLabel,
                        order.getOrderNumber(),
                        order.getTotalAmount().toPlainString(),
                        pdfUrl,
                        "Bill-" + order.getOrderNumber() + ".pdf"
                );
            }

            if (!sent) {
                throw new RuntimeException("WhatsApp send failed. Possible reasons: bill_receipt template not yet approved, access token expired, or recipient not allowed (test numbers can only message registered recipients). Check backend logs for the exact WhatsApp API error.");
            }
            // Successful send: log it against the shop for usage-based billing
            shopWhatsAppUsageService.record(order.getShop().getId(), ShopWhatsAppUsageService.TYPE_BILL);
        } catch (java.io.IOException e) {
            log.error("Failed to store bill PDF for order {}", order.getOrderNumber(), e);
            throw new RuntimeException("Failed to save bill PDF", e);
        }
    }

    /**
     * Generate the bill as BOTH an image (opens instantly in the browser) and a
     * PDF (for download/print) and return their public URLs WITHOUT sending any
     * message. Used by the "share from the owner's own WhatsApp" flow: the
     * frontend opens wa.me with these links so the customer receives the bill
     * from the shop's own number and can reply to the shop directly.
     */
    @Transactional
    public Map<String, String> getBillShareLinks(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));

        byte[] pdfBytes = billPdfService.generateBillPdf(order);

        try {
            String suffix = UUID.randomUUID().toString().substring(0, 8);
            Path billsDir = Paths.get(uploadDir, "bills");
            Files.createDirectories(billsDir);

            Map<String, String> links = new HashMap<>();
            links.put("orderNumber", order.getOrderNumber());
            links.put("amount", order.getTotalAmount().toPlainString());
            links.put("shopName", order.getShop().getName());

            String pdfFileName = "bill_" + order.getOrderNumber() + "_" + suffix + ".pdf";
            Files.write(billsDir.resolve(pdfFileName), pdfBytes);
            links.put("pdfUrl", apiBaseUrl + "/uploads/bills/" + pdfFileName);

            byte[] jpegBytes = renderBillJpeg(pdfBytes, order.getOrderNumber());
            if (jpegBytes != null) {
                String imgFileName = "bill_" + order.getOrderNumber() + "_" + suffix + ".jpg";
                Files.write(billsDir.resolve(imgFileName), jpegBytes);
                links.put("imageUrl", apiBaseUrl + "/uploads/bills/" + imgFileName);
            }

            return links;
        } catch (java.io.IOException e) {
            log.error("Failed to store bill for sharing, order {}", order.getOrderNumber(), e);
            throw new RuntimeException("Failed to save bill for sharing", e);
        }
    }

    /**
     * Render page 1 of the bill PDF as a JPEG for inline WhatsApp display.
     * Returns null on any rendering problem so callers can fall back to the PDF.
     */
    private byte[] renderBillJpeg(byte[] pdfBytes, String orderNumber) {
        try (org.apache.pdfbox.pdmodel.PDDocument doc =
                     org.apache.pdfbox.pdmodel.PDDocument.load(pdfBytes)) {
            org.apache.pdfbox.rendering.PDFRenderer renderer =
                    new org.apache.pdfbox.rendering.PDFRenderer(doc);
            java.awt.image.BufferedImage image =
                    renderer.renderImageWithDPI(0, 300, org.apache.pdfbox.rendering.ImageType.RGB);

            // Thermal PDFs are initially measured on a very tall page. If that
            // measurement falls back to the safety height, PDFBox faithfully
            // renders thousands of blank pixels below the receipt and WhatsApp
            // scales the useful content into an unreadable vertical strip.
            // Crop only trailing white space; preserve the full receipt width
            // and a small bottom margin.
            image = cropTrailingWhiteSpace(image);

            // Java's default JPEG quality is heavily compressed, which blurs the
            // small receipt text. Force near-lossless quality explicitly.
            javax.imageio.ImageWriter writer = javax.imageio.ImageIO.getImageWritersByFormatName("jpg").next();
            javax.imageio.ImageWriteParam param = writer.getDefaultWriteParam();
            param.setCompressionMode(javax.imageio.ImageWriteParam.MODE_EXPLICIT);
            param.setCompressionQuality(0.95f);

            java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream();
            try (javax.imageio.stream.ImageOutputStream ios = javax.imageio.ImageIO.createImageOutputStream(out)) {
                writer.setOutput(ios);
                writer.write(null, new javax.imageio.IIOImage(image, null, null), param);
            } finally {
                writer.dispose();
            }
            return out.toByteArray();
        } catch (Exception e) {
            log.warn("Could not render bill {} as image - will send PDF instead: {}", orderNumber, e.getMessage());
            return null;
        }
    }

    private java.awt.image.BufferedImage cropTrailingWhiteSpace(java.awt.image.BufferedImage image) {
        int bottom = image.getHeight() - 1;
        while (bottom > 0 && isBlankImageRow(image, bottom)) {
            bottom--;
        }

        int padding = Math.max(16, image.getWidth() / 40);
        int croppedHeight = Math.min(image.getHeight(), bottom + 1 + padding);
        if (croppedHeight >= image.getHeight()) return image;

        java.awt.image.BufferedImage cropped = new java.awt.image.BufferedImage(
                image.getWidth(), croppedHeight, java.awt.image.BufferedImage.TYPE_INT_RGB);
        java.awt.Graphics2D graphics = cropped.createGraphics();
        try {
            graphics.setColor(java.awt.Color.WHITE);
            graphics.fillRect(0, 0, cropped.getWidth(), cropped.getHeight());
            graphics.drawImage(image, 0, 0, null);
        } finally {
            graphics.dispose();
        }
        return cropped;
    }

    private boolean isBlankImageRow(java.awt.image.BufferedImage image, int y) {
        // Sample every second pixel. Receipt text/borders span enough pixels at
        // 300 DPI that this remains accurate while avoiding a costly full scan.
        for (int x = 0; x < image.getWidth(); x += 2) {
            int rgb = image.getRGB(x, y);
            int red = (rgb >>> 16) & 0xff;
            int green = (rgb >>> 8) & 0xff;
            int blue = rgb & 0xff;
            if (red < 248 || green < 248 || blue < 248) return false;
        }
        return true;
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

        // POS-created customers get a placeholder "<phone>@pos.local" email — never send to it
        if (email != null && email.endsWith("@pos.local")) {
            email = null;
        }

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

        String customerEmail = request.getCustomerEmail() != null && request.getCustomerEmail().contains("@")
                ? request.getCustomerEmail().trim()
                : null;

        // If phone provided, try to find existing customer or create new
        if (customerPhone != null && !customerPhone.trim().isEmpty()) {
            Customer existing = customerRepository.findFirstByMobileNumberOrderByIdAsc(customerPhone).orElse(null);
            if (existing != null) {
                // Email typed at the POS is the freshest data - update it,
                // unless that email already belongs to a different customer
                if (customerEmail != null && !customerEmail.equalsIgnoreCase(existing.getEmail())) {
                    if (!customerRepository.existsByEmail(customerEmail)) {
                        existing.setEmail(customerEmail);
                        customerRepository.save(existing);
                    } else {
                        log.warn("POS: email {} already belongs to another customer - keeping existing email for {}",
                                customerEmail, customerPhone);
                    }
                }
                return existing;
            }

            // Create new customer with real phone number
            Customer newCustomer = Customer.builder()
                    .firstName(customerName != null && !customerName.trim().isEmpty()
                            ? customerName
                            : "Customer")
                    .lastName("POS")
                    .mobileNumber(customerPhone)
                    .email(customerEmail != null ? customerEmail : customerPhone + "@pos.local")
                    .createdBy(getCurrentUsername())
                    .updatedBy(getCurrentUsername())
                    .build();

            return saveCustomerOrFetchExisting(newCustomer, customerPhone);
        }

        // No phone provided - use shared walk-in customer for this shop
        // This avoids creating thousands of dummy customer records
        // Use a valid phone format: 9000000 + shopId (padded to 10 digits)
        String walkInPhone = String.format("90000%05d", shop.getId());
        Customer walkInCustomer = customerRepository.findFirstByMobileNumberOrderByIdAsc(walkInPhone).orElse(null);

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

            walkInCustomer = saveCustomerOrFetchExisting(walkInCustomer, walkInPhone);
            log.info("Created walk-in customer for shop: {}", shop.getId());
        }

        return walkInCustomer;
    }

    /**
     * Save a new customer, tolerating the create-create race: when offline orders
     * sync in a burst, two requests can both see "no customer" and both insert —
     * the loser hits the unique constraint on mobile_number. Fetch the winner
     * instead of failing the whole order with a red DB error on the POS screen.
     * The insert runs in its OWN transaction (REQUIRES_NEW): a constraint violation
     * inside the order's transaction would mark it rollback-only and doom the order
     * even if we caught the exception here.
     */
    private Customer saveCustomerOrFetchExisting(Customer newCustomer, String phone) {
        try {
            TransactionTemplate tt = new TransactionTemplate(transactionManager);
            tt.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
            return tt.execute(status -> customerRepository.save(newCustomer));
        } catch (DataIntegrityViolationException e) {
            log.warn("Customer with phone {} was created concurrently - using existing record", phone);
            return customerRepository.findFirstByMobileNumberOrderByIdAsc(phone)
                    .orElseThrow(() -> e);
        }
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
    public List<Map<String, Object>> searchCustomers(Long shopId, String query, int limit) {
        String q = query == null ? "" : query.trim();
        int size = Math.min(Math.max(limit, 1), 500);
        List<Object[]> rows = orderRepository.searchShopCustomers(shopId, q, PageRequest.of(0, size));
        List<Map<String, Object>> results = new ArrayList<>();
        for (Object[] row : rows) {
            String mobileNumber = (String) row[1];
            String firstName = (String) row[2];
            String lastName = (String) row[3];
            // POS-created customers get a placeholder "POS" last name - don't show it
            String name = (lastName == null || "POS".equalsIgnoreCase(lastName))
                    ? (firstName == null ? "" : firstName.trim())
                    : (firstName + " " + lastName).trim();
            Map<String, Object> entry = new HashMap<>();
            entry.put("customerId", row[0]);
            entry.put("customerName", name);
            entry.put("customerPhone", mobileNumber);
            entry.put("billCount", row[4]);
            entry.put("lastOrderDate", row[5] != null ? row[5].toString() : null);
            entry.put("totalSpent", row[6]);
            // Hide the "<phone>@pos.local" placeholder — only real emails are useful to the UI
            String email = (String) row[7];
            entry.put("customerEmail", email != null && !email.endsWith("@pos.local") ? email : null);
            results.add(entry);
        }
        return results;
    }

    /**
     * A customer's full purchase history at this shop, most recent first, with line items.
     */
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getCustomerOrderHistory(Long shopId, Long customerId) {
        List<Order> orders = orderRepository.findShopCustomerOrdersWithItems(shopId, customerId);
        List<Map<String, Object>> history = new ArrayList<>();
        for (Order order : orders) {
            Map<String, Object> entry = new HashMap<>();
            entry.put("orderId", order.getId());
            entry.put("orderNumber", order.getOrderNumber());
            entry.put("createdAt", order.getCreatedAt() != null ? order.getCreatedAt().toString() : null);
            entry.put("status", order.getStatus() != null ? order.getStatus().name() : null);
            entry.put("paymentMethod", order.getPaymentMethod() != null ? order.getPaymentMethod().name() : null);
            entry.put("totalAmount", order.getTotalAmount());
            List<Map<String, Object>> items = new ArrayList<>();
            if (order.getOrderItems() != null) {
                for (OrderItem item : order.getOrderItems()) {
                    Map<String, Object> itemEntry = new HashMap<>();
                    itemEntry.put("productName", item.getProductName());
                    itemEntry.put("quantity", item.getQuantity());
                    itemEntry.put("unitPrice", item.getUnitPrice());
                    itemEntry.put("totalPrice", item.getTotalPrice());
                    items.add(itemEntry);
                }
            }
            entry.put("items", items);
            history.add(entry);
        }
        return history;
    }

    /**
     * Send a WhatsApp offer message to selected customers of this shop.
     * Uses the approved marketing template; returns per-customer results.
     */
    /**
     * Store an offer campaign image and return its public URL, for use as the
     * IMAGE header of the shop_offer_image WhatsApp template.
     */
    public String storeOfferImage(Long shopId, org.springframework.web.multipart.MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new RuntimeException("No image file provided");
        }
        String contentType = file.getContentType() != null ? file.getContentType() : "";
        String extension;
        switch (contentType) {
            case "image/jpeg" -> extension = ".jpg";
            case "image/png" -> extension = ".png";
            default -> throw new RuntimeException("Only JPEG or PNG images are supported for WhatsApp offers");
        }
        // WhatsApp rejects image headers above 5MB
        if (file.getSize() > 5 * 1024 * 1024) {
            throw new RuntimeException("Image too large (max 5MB)");
        }
        try {
            String fileName = "offer_" + shopId + "_" + UUID.randomUUID().toString().substring(0, 8) + extension;
            Path offersDir = Paths.get(uploadDir, "offers");
            Files.createDirectories(offersDir);
            Files.write(offersDir.resolve(fileName), file.getBytes());
            return apiBaseUrl + "/uploads/offers/" + fileName;
        } catch (java.io.IOException e) {
            log.error("Failed to store offer image for shop {}", shopId, e);
            throw new RuntimeException("Failed to save offer image", e);
        }
    }

    public Map<String, Object> sendOfferToCustomers(Long shopId, List<Long> customerIds, String offerText, String imageUrl) {
        if (customerIds == null || customerIds.isEmpty()) {
            throw new RuntimeException("No customers selected");
        }
        if (offerText == null || offerText.trim().isEmpty()) {
            throw new RuntimeException("Offer text is required");
        }
        if (customerIds.size() > 500) {
            throw new RuntimeException("Too many customers selected (max 500 per campaign)");
        }

        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new RuntimeException("Shop not found: " + shopId));

        int sent = 0;
        List<Map<String, Object>> failures = new ArrayList<>();
        for (Long customerId : customerIds) {
            Customer customer = customerRepository.findById(customerId).orElse(null);
            if (customer == null || customer.getMobileNumber() == null || customer.getMobileNumber().isBlank()) {
                failures.add(Map.of("customerId", customerId, "reason", "No mobile number"));
                continue;
            }
            // Shared walk-in placeholder (90000 + shopId) is not a real number
            if (customer.getMobileNumber().matches("90000\\d{5}")) {
                failures.add(Map.of("customerId", customerId, "reason", "Walk-in customer (no real number)"));
                continue;
            }
            String name = customer.getFirstName() != null ? customer.getFirstName() : "Customer";
            boolean ok = whatsAppNotificationService.sendShopOffer(
                    customer.getMobileNumber(), name, shop.getName(), offerText.trim(), imageUrl);
            if (ok) {
                sent++;
                shopWhatsAppUsageService.record(shop.getId(), ShopWhatsAppUsageService.TYPE_MARKETING);
            } else {
                failures.add(Map.of("customerId", customerId, "reason", "WhatsApp send failed"));
            }
        }
        log.info("Shop {} offer campaign: {} sent, {} failed of {}", shopId, sent, failures.size(), customerIds.size());

        Map<String, Object> result = new HashMap<>();
        result.put("requested", customerIds.size());
        result.put("sent", sent);
        result.put("failed", failures.size());
        result.put("failures", failures);
        return result;
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
                .offlineOrderId(order.getOfflineOrderId())
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
