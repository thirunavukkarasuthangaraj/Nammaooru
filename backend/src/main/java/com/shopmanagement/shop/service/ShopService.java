package com.shopmanagement.shop.service;

import com.shopmanagement.shop.dto.ShopCreateRequest;
import com.shopmanagement.shop.dto.ShopResponse;
import com.shopmanagement.shop.dto.ShopUpdateRequest;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.exception.ShopNotFoundException;
import com.shopmanagement.shop.mapper.ShopMapper;
import com.shopmanagement.shop.repository.ShopRepository;
import com.shopmanagement.shop.util.ShopSlugGenerator;
import com.shopmanagement.service.EmailService;
import com.shopmanagement.service.AuthService;
import com.shopmanagement.entity.User;
import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderItem;
import com.shopmanagement.entity.OrderAssignment;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.repository.OrderAssignmentRepository;
import com.shopmanagement.product.repository.ShopProductRepository;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.dto.order.OrderResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.UUID;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ShopService {

    private final ShopRepository shopRepository;
    private final ShopMapper shopMapper;
    private final ShopSlugGenerator slugGenerator;
    private final EmailService emailService;
    private final AuthService authService;
    private final UserRepository userRepository;
    private final OrderRepository orderRepository;
    private final OrderAssignmentRepository orderAssignmentRepository;
    private final ShopProductRepository shopProductRepository;
    private final com.shopmanagement.service.BusinessHoursService businessHoursService;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;

    public ShopResponse createShop(ShopCreateRequest request) {
        log.info("Creating new shop: {}", request.getName());
        
        String shopId = generateShopId();
        String slug = generateUniqueSlug(request.getName(), request.getCity());
        
        Shop shop = shopMapper.toEntity(request);
        shop.setShopId(shopId);
        shop.setSlug(slug);
        shop.setCreatedBy(getCurrentUsername());
        shop.setStatus(Shop.ShopStatus.PENDING);
        
        if (request.getCountry() == null || request.getCountry().isEmpty()) {
            shop.setCountry("India");
        }
        
        Shop savedShop = shopRepository.save(shop);
        log.info("Shop created successfully with ID: {} - Status: {}", savedShop.getShopId(), savedShop.getStatus());
        
        // Send shop registration confirmation email
        try {
            sendShopRegistrationConfirmationEmail(savedShop);
        } catch (Exception e) {
            log.error("Failed to send shop registration confirmation email for shop: {}", savedShop.getShopId(), e);
        }
        
        return shopMapper.toResponse(savedShop);
    }

    @Transactional(readOnly = true)
    public Page<ShopResponse> getAllShops(Specification<Shop> spec, Pageable pageable) {
        if (spec != null) {
            return shopRepository.findAll(spec, pageable)
                    .map(shopMapper::toResponse);
        }
        return shopRepository.findAll(pageable)
                .map(shopMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<ShopResponse> getAllShops(Pageable pageable) {
        return getAllShops(null, pageable);
    }

    @Transactional(readOnly = true)
    public Page<ShopResponse> getActiveShops(Pageable pageable) {
        return shopRepository.findByIsActiveTrue(pageable)
                .map(shopMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<ShopResponse> getShopsByStatus(Shop.ShopStatus status, Pageable pageable) {
        return shopRepository.findByStatus(status, pageable)
                .map(shopMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<ShopResponse> getShopsByBusinessType(Shop.BusinessType businessType, Pageable pageable) {
        return shopRepository.findByBusinessType(businessType, pageable)
                .map(shopMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<ShopResponse> getShopsAwaitingApproval(Pageable pageable) {
        return shopRepository.findByStatus(Shop.ShopStatus.PENDING, pageable)
                .map(shopMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<ShopResponse> getAllShopsForApproval(Pageable pageable) {
        // Get all shops regardless of status for admin review
        return shopRepository.findAll(pageable)
                .map(shopMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public long countShopsByStatus(Shop.ShopStatus status) {
        return shopRepository.countByStatus(status);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getDocumentVerificationStatus(Long shopId) {
        // Get shop to ensure it exists
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new RuntimeException("Shop not found with id: " + shopId));

        Map<String, Object> status = new HashMap<>();
        status.put("shopId", shopId);
        status.put("shopName", shop.getName());
        status.put("overallStatus", shop.getStatus().name());

        // Mock document verification status - replace with actual logic
        Map<String, Object> documents = new HashMap<>();
        documents.put("businessLicense", Map.of("status", "VERIFIED", "uploadedAt", "2025-09-15T10:30:00"));
        documents.put("gstCertificate", Map.of("status", "VERIFIED", "uploadedAt", "2025-09-15T10:35:00"));
        documents.put("panCard", Map.of("status", "VERIFIED", "uploadedAt", "2025-09-15T10:40:00"));
        documents.put("addressProof", Map.of("status", "VERIFIED", "uploadedAt", "2025-09-15T10:45:00"));

        status.put("documents", documents);
        status.put("allDocumentsVerified", true);
        status.put("lastUpdated", LocalDateTime.now());

        return status;
    }

    @Transactional(readOnly = true)
    public Page<ShopResponse> searchShops(String searchTerm, Pageable pageable) {
        return shopRepository.searchShops(searchTerm, pageable)
                .map(shopMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<ShopResponse> filterShops(Specification<Shop> spec, Pageable pageable) {
        Page<Shop> shopPage = shopRepository.findAll(spec, pageable);
        
        // Fetch complete shop data with images and documents separately to avoid MultipleBagFetchException
        List<Long> shopIds = shopPage.getContent().stream()
                .map(Shop::getId)
                .toList();
        
        if (shopIds.isEmpty()) {
            return shopPage.map(shopMapper::toResponse);
        }
        
        // Fetch shops with images and documents separately
        List<Shop> shopsWithImages = shopRepository.findAllWithImagesByIds(shopIds);
        List<Shop> shopsWithDocuments = shopRepository.findAllWithDocumentsByIds(shopIds);
        
        // Create maps for quick lookup
        Map<Long, Shop> imageMap = shopsWithImages.stream()
                .collect(Collectors.toMap(Shop::getId, shop -> shop));
        Map<Long, Shop> documentMap = shopsWithDocuments.stream()
                .collect(Collectors.toMap(Shop::getId, shop -> shop));
        
        // Map to responses maintaining the original order
        List<ShopResponse> responses = shopPage.getContent().stream()
                .map(shop -> {
                    // Enrich shop with images and documents
                    Shop shopWithImages = imageMap.get(shop.getId());
                    Shop shopWithDocuments = documentMap.get(shop.getId());
                    
                    if (shopWithImages != null && shopWithImages.getImages() != null) {
                        shop.setImages(shopWithImages.getImages());
                    }
                    if (shopWithDocuments != null && shopWithDocuments.getDocuments() != null) {
                        shop.setDocuments(shopWithDocuments.getDocuments());
                    }
                    
                    return shopMapper.toResponse(shop);
                })
                .toList();
        
        return new org.springframework.data.domain.PageImpl<>(
            responses, pageable, shopPage.getTotalElements());
    }

    @Transactional(readOnly = true)
    public ShopResponse getShopById(Long id) {
        Shop shop = shopRepository.findById(id)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with id: " + id));
        return shopMapper.toResponse(shop);
    }

    @Transactional(readOnly = true)
    public ShopResponse getShopByShopId(String shopId) {
        Shop shop = shopRepository.findByShopId(shopId)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with shop ID: " + shopId));
        return shopMapper.toResponse(shop);
    }

    @Transactional(readOnly = true)
    public ShopResponse getShopBySlug(String slug) {
        Shop shop = shopRepository.findBySlug(slug)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with slug: " + slug));
        return shopMapper.toResponse(shop);
    }

    public ShopResponse updateShop(Long id, ShopUpdateRequest request) {
        log.info("Updating shop with ID: {}", id);
        
        Shop shop = shopRepository.findById(id)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with id: " + id));

        shopMapper.updateEntityFromRequest(request, shop);
        shop.setUpdatedBy(getCurrentUsername());
        
        if (request.getName() != null && !request.getName().equals(shop.getName()) && request.getCity() != null) {
            String newSlug = generateUniqueSlug(request.getName(), request.getCity());
            shop.setSlug(newSlug);
        }

        Shop updatedShop = shopRepository.save(shop);
        log.info("Shop updated successfully: {}", updatedShop.getShopId());
        
        return shopMapper.toResponse(updatedShop);
    }

    public void deleteShop(Long id) {
        log.info("Soft deleting shop with ID: {}", id);

        Shop shop = shopRepository.findById(id)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with id: " + id));

        // Check if shop has active orders
        boolean hasActiveOrders = orderRepository.existsByShopIdAndStatusIn(
            shop.getId(),
            List.of(Order.OrderStatus.PENDING, Order.OrderStatus.CONFIRMED,
                   Order.OrderStatus.PREPARING, Order.OrderStatus.READY_FOR_PICKUP,
                   Order.OrderStatus.OUT_FOR_DELIVERY)
        );

        if (hasActiveOrders) {
            throw new RuntimeException("Cannot delete shop with active orders. Please complete or cancel all active orders first.");
        }

        // Soft delete: Set shop as inactive and status as SUSPENDED
        shop.setIsActive(false);
        shop.setStatus(Shop.ShopStatus.SUSPENDED);
        shop.setUpdatedBy(getCurrentUsername());

        shopRepository.save(shop);
        log.info("Shop soft deleted successfully (marked as inactive): {}", shop.getShopId());
    }

    // Customer-facing methods
    public Page<ShopResponse> getActiveShops(Pageable pageable, String search, String category) {
        log.info("Fetching active shops for customers - search: {}, category: {}", search, category);

        Specification<Shop> spec = Specification.where(
            (root, query, cb) -> cb.and(
                cb.equal(root.get("status"), Shop.ShopStatus.APPROVED),
                cb.equal(root.get("isActive"), true)
            )
        );

        if (search != null && !search.isEmpty()) {
            String searchPattern = "%" + search.toLowerCase() + "%";
            spec = spec.and((root, query, cb) -> cb.or(
                cb.like(cb.lower(root.get("name")), searchPattern),
                cb.like(cb.lower(root.get("businessName")), searchPattern),
                cb.like(cb.lower(root.get("description")), searchPattern)
            ));
        }

        if (category != null && !category.isEmpty()) {
            spec = spec.and((root, query, cb) ->
                cb.equal(root.get("businessType"), Shop.BusinessType.valueOf(category.toUpperCase()))
            );
        }

        Page<Shop> shops = shopRepository.findAll(spec, pageable);
        return shops.map(shop -> {
            ShopResponse response = shopMapper.toResponse(shop);
            // Calculate real-time business hours status
            try {
                boolean isOpenNow = businessHoursService.isShopOpenNow(shop.getId());
                response.setIsOpenNow(isOpenNow);
                log.debug("Shop {} ({}) - isOpenNow: {}", shop.getName(), shop.getId(), isOpenNow);
            } catch (Exception e) {
                log.warn("Failed to check business hours for shop {}: {}", shop.getId(), e.getMessage());
                // Fallback to isActive if business hours check fails
                response.setIsOpenNow(shop.getIsActive());
            }
            return response;
        });
    }

    public ShopResponse approveShop(Long id) {
        return updateShopStatus(id, Shop.ShopStatus.APPROVED);
    }

    public ShopResponse approveShop(Long id, String notes) {
        return updateShopStatus(id, Shop.ShopStatus.APPROVED, notes);
    }

    public ShopResponse rejectShop(Long id) {
        return updateShopStatus(id, Shop.ShopStatus.REJECTED);
    }

    public ShopResponse rejectShop(Long id, String reason) {
        return updateShopStatus(id, Shop.ShopStatus.REJECTED, reason);
    }

    public ShopResponse suspendShop(Long id) {
        return updateShopStatus(id, Shop.ShopStatus.SUSPENDED);
    }

    private ShopResponse updateShopStatus(Long id, Shop.ShopStatus status) {
        return updateShopStatus(id, status, null);
    }

    private ShopResponse updateShopStatus(Long id, Shop.ShopStatus status, String notes) {
        log.info("Updating shop status to {} for shop ID: {} with notes: {}", status, id, notes);
        
        Shop shop = shopRepository.findById(id)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with id: " + id));
        
        shop.setStatus(status);
        // Note: updatedBy will be set to shop owner username in APPROVED case
        
        if (status == Shop.ShopStatus.APPROVED) {
            shop.setIsVerified(true);
            
            // Create shop owner user account and send welcome email
            try {
                log.info("Starting user creation process for shop: {}", shop.getName());
                String username = generateUsername(shop.getOwnerName());
                String temporaryPassword = generateTemporaryPassword();
                log.info("Generated credentials - Username: {}, Password length: {}", username, temporaryPassword.length());
                
                // Check if user already exists
                boolean userExists = authService.userExistsByUsernameOrEmail(username, shop.getOwnerEmail());
                if (userExists) {
                    log.warn("User already exists with username: {} or email: {}", username, shop.getOwnerEmail());
                    // Try with different username
                    username = generateUsername(shop.getOwnerName() + System.currentTimeMillis());
                    log.info("Generated new username: {}", username);
                }
                
                // Create user account
                User shopOwnerUser = authService.createShopOwnerUser(username, shop.getOwnerEmail(), temporaryPassword);
                log.info("Successfully created shop owner user: {} for shop: {}", username, shop.getName());
                
                // Update shop to be owned by the newly created user
                shop.setCreatedBy(username);
                shop.setUpdatedBy(username);
                
                // Send welcome email with credentials
                try {
                    emailService.sendShopOwnerWelcomeEmail(
                        shop.getOwnerEmail(),
                        shop.getOwnerName(),
                        shop.getOwnerEmail(),
                        temporaryPassword,
                        shop.getName()
                    );
                    log.info("Welcome email sent successfully to: {}", shop.getOwnerEmail());
                } catch (Exception emailError) {
                    log.error("Failed to send welcome email to: {} for shop: {}", shop.getOwnerEmail(), shop.getName(), emailError);
                    // Email failed but user was created - this is a partial success
                    // Admin should be notified to manually send credentials
                }
                
            } catch (Exception e) {
                log.error("Failed to create user account for shop: {} - Error: {}", shop.getName(), e.getMessage(), e);
                // Continue with shop approval even if user creation fails
                // This can be handled manually by admin later
                // If user creation failed, set updatedBy to current admin
                shop.setUpdatedBy(getCurrentUsername());
            }
        } else {
            // For rejected/suspended statuses, set updatedBy to current admin
            shop.setUpdatedBy(getCurrentUsername());
        }
        
        Shop updatedShop = shopRepository.save(shop);
        log.info("Shop status updated successfully: {}", updatedShop.getShopId());
        
        return shopMapper.toResponse(updatedShop);
    }
    
    private String generateUsername(String ownerName) {
        // Generate username from owner name
        String baseUsername = ownerName.toLowerCase()
                .replaceAll("[^a-z0-9]", "")
                .substring(0, Math.min(ownerName.length(), 10));
        
        // Add random numbers to ensure uniqueness
        String randomSuffix = String.valueOf((int)(Math.random() * 1000));
        return baseUsername + randomSuffix;
    }
    
    private String generateTemporaryPassword() {
        // Generate a secure temporary password
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        StringBuilder password = new StringBuilder();
        for (int i = 0; i < 12; i++) {
            password.append(chars.charAt((int) (Math.random() * chars.length())));
        }
        return password.toString();
    }

    @Transactional(readOnly = true)
    public List<ShopResponse> getNearbyShops(BigDecimal latitude, BigDecimal longitude, double radiusInMiles) {
        List<Shop> nearbyShops = shopRepository.findShopsWithinRadius(latitude, longitude, radiusInMiles);
        return nearbyShops.stream()
                .map(shopMapper::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ShopResponse> getFeaturedShops() {
        List<Shop> featuredShops = shopRepository.findFeaturedShops();
        return featuredShops.stream()
                .map(shopMapper::toResponse)
                .collect(Collectors.toList());
    }

    private String generateShopId() {
        String shopId;
        do {
            shopId = "SH" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        } while (shopRepository.existsByShopId(shopId));
        return shopId;
    }

    private String generateUniqueSlug(String name, String city) {
        String baseSlug = slugGenerator.generateUniqueSlug(name, city);
        String slug = baseSlug;
        int counter = 1;
        
        while (shopRepository.existsBySlug(slug)) {
            slug = baseSlug + "-" + counter;
            counter++;
        }
        
        return slug;
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null ? authentication.getName() : "system";
    }

    // Statistics methods
    public long getTotalShopsCount() {
        return shopRepository.count();
    }

    public long getActiveShopsCount() {
        return shopRepository.countByIsActiveTrue();
    }

    public long getPendingShopsCount() {
        return shopRepository.countByStatus(Shop.ShopStatus.PENDING);
    }

    public long getRejectedShopsCount() {
        return shopRepository.countByStatus(Shop.ShopStatus.REJECTED);
    }

    public long getSuspendedShopsCount() {
        return shopRepository.countByStatus(Shop.ShopStatus.SUSPENDED);
    }

    public ShopResponse getCurrentUserShop() {
        String currentUsername = getCurrentUsername();
        log.info("Getting shop for current user: {}", currentUsername);
        
        // For shop owners, find their shop by createdBy
        // For admin users, just return the first active shop as a demo
        if ("admin".equals(currentUsername)) {
            log.info("Admin user accessing shop demo - returning first active shop");
            Page<Shop> activeShopsPage = shopRepository.findByIsActiveTrue(PageRequest.of(0, 1));
            if (activeShopsPage.isEmpty()) {
                throw new ShopNotFoundException("No active shops available for demo");
            }
            return shopMapper.toResponse(activeShopsPage.getContent().get(0));
        }
        
        Shop shop = shopRepository.findByCreatedBy(currentUsername)
            .orElseThrow(() -> new ShopNotFoundException("No shop found for current user"));
        
        return shopMapper.toResponse(shop);
    }

    @Transactional(readOnly = true)
    public Shop getShopByOwner(String username) {
        log.info("Getting shop entity for user: {}", username);
        
        // For admin users, return first active shop as demo
        if ("admin".equals(username) || "superadmin".equals(username)) {
            log.info("Admin user accessing shop demo - returning first active shop");
            Page<Shop> activeShopsPage = shopRepository.findByIsActiveTrue(PageRequest.of(0, 1));
            if (activeShopsPage.isEmpty()) {
                return null;
            }
            return activeShopsPage.getContent().get(0);
        }
        
        // First try to find by createdBy (for shops created by the user directly)
        Shop shop = shopRepository.findByCreatedBy(username).orElse(null);
        if (shop != null) {
            return shop;
        }
        
        // If not found, try to find by owner email matching the user's email
        // Get the user's email from the database
        User user = userRepository.findByUsername(username).orElse(null);
        if (user != null && user.getEmail() != null) {
            log.info("Looking for shop by owner email: {}", user.getEmail());
            return shopRepository.findByOwnerEmail(user.getEmail()).orElse(null);
        }
        
        return null;
    }

    private void sendShopRegistrationConfirmationEmail(Shop shop) {
        try {
            emailService.sendShopRegistrationConfirmationEmail(
                shop.getOwnerEmail(),
                shop.getOwnerName(),
                shop.getName(),
                shop.getShopId()
            );
            log.info("Shop registration confirmation email sent to: {}", shop.getOwnerEmail());
        } catch (Exception e) {
            log.error("Failed to send shop registration confirmation email for shop: {}", shop.getShopId(), e);
            throw e;
        }
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getApprovalStats() {
        long totalShops = getTotalShopsCount();
        long pendingShops = getPendingShopsCount();
        long approvedShops = shopRepository.countByStatus(Shop.ShopStatus.APPROVED);
        long rejectedShops = getRejectedShopsCount();
        long suspendedShops = getSuspendedShopsCount();
        
        return Map.of(
            "total", totalShops,
            "pending", pendingShops,
            "approved", approvedShops,
            "rejected", rejectedShops,
            "suspended", suspendedShops,
            "pendingPercentage", totalShops > 0 ? (pendingShops * 100.0 / totalShops) : 0,
            "approvedPercentage", totalShops > 0 ? (approvedShops * 100.0 / totalShops) : 0
        );
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getShopDashboard(String shopId) {
        Shop shop = shopRepository.findByShopId(shopId)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with shop ID: " + shopId));

        Map<String, Object> dashboard = new HashMap<>();

        // Basic shop info
        dashboard.put("shopInfo", Map.of(
            "shopId", shop.getShopId(),
            "name", shop.getName(),
            "status", shop.getStatus().toString(),
            "isActive", shop.getIsActive(),
            "isVerified", shop.getIsVerified(),
            "businessType", shop.getBusinessType().toString(),
            "city", shop.getCity(),
            "state", shop.getState()
        ));

        // Calculate real order metrics
        Long totalOrders = orderRepository.countOrdersByShop(shop.getId());
        BigDecimal totalRevenue = orderRepository.getTotalRevenueByShop(shop.getId());
        if (totalRevenue == null) totalRevenue = BigDecimal.ZERO;

        BigDecimal avgOrderValue = orderRepository.getAverageOrderValueByShop(shop.getId());
        if (avgOrderValue == null) avgOrderValue = BigDecimal.ZERO;

        // Get status breakdown
        List<Object[]> statusBreakdownData = orderRepository.getOrderStatusDistribution(shop.getId());
        Map<String, Long> statusBreakdown = new HashMap<>();
        statusBreakdown.put("PENDING", 0L);
        statusBreakdown.put("CONFIRMED", 0L);
        statusBreakdown.put("PREPARING", 0L);
        statusBreakdown.put("READY", 0L);
        statusBreakdown.put("OUT_FOR_DELIVERY", 0L);
        statusBreakdown.put("DELIVERED", 0L);
        statusBreakdown.put("CANCELLED", 0L);

        long completedOrders = 0;
        for (Object[] row : statusBreakdownData) {
            String orderStatus = row[0].toString();
            Long count = (Long) row[1];
            statusBreakdown.put(orderStatus, count);
            if ("DELIVERED".equals(orderStatus)) {
                completedOrders += count;
            }
        }

        // Get today's orders (requires a custom query - using approximate for now)
        LocalDateTime todayStart = LocalDateTime.now().toLocalDate().atStartOfDay();
        Long todayOrders = orderRepository.countByShopIdAndCreatedAtAfter(shop.getId(), todayStart);
        if (todayOrders == null) todayOrders = 0L;

        BigDecimal todayRevenue = orderRepository.getTotalRevenueByShopAndDate(shop.getId(), todayStart);
        if (todayRevenue == null) todayRevenue = BigDecimal.ZERO;

        // Get monthly revenue (last 30 days)
        LocalDateTime monthStart = LocalDateTime.now().minusDays(30);
        BigDecimal monthlyRevenue = orderRepository.getTotalRevenueByShopAndDate(shop.getId(), monthStart);
        if (monthlyRevenue == null) monthlyRevenue = BigDecimal.ZERO;

        dashboard.put("orderMetrics", Map.of(
            "totalOrders", totalOrders != null ? totalOrders.intValue() : 0,
            "todayOrders", todayOrders.intValue(),
            "pendingOrders", statusBreakdown.get("PENDING").intValue(),
            "completedOrders", (int) completedOrders,
            "cancelledOrders", statusBreakdown.get("CANCELLED").intValue(),
            "totalRevenue", totalRevenue,
            "todayRevenue", todayRevenue,
            "monthlyRevenue", monthlyRevenue,
            "averageOrderValue", avgOrderValue
        ));

        // Calculate real product metrics
        long totalProducts = shopProductRepository.countByShop(shop);
        long activeProducts = shopProductRepository.countAvailableProductsByShop(shop);
        long inactiveProducts = totalProducts - activeProducts;
        long outOfStockProducts = shopProductRepository.findOutOfStockProducts(shop).size();
        long lowStockProducts = shopProductRepository.findLowStockProducts(shop).size();

        dashboard.put("productMetrics", Map.of(
            "totalProducts", (int) totalProducts,
            "activeProducts", (int) activeProducts,
            "inactiveProducts", (int) inactiveProducts,
            "outOfStockProducts", (int) outOfStockProducts,
            "lowStockProducts", (int) lowStockProducts
        ));

        // Performance metrics
        dashboard.put("performanceMetrics", Map.of(
            "rating", shop.getRating() != null ? shop.getRating() : BigDecimal.ZERO,
            "totalReviews", 0,
            "completionRate", 0.0,
            "responseTime", "N/A",
            "customerSatisfaction", 0.0
        ));

        // Recent activity (mock data for now)
        dashboard.put("recentActivity", List.of());

        // Quick stats for the last 30 days
        Long monthlyOrders = orderRepository.countByShopIdAndCreatedAtAfter(shop.getId(), monthStart);
        if (monthlyOrders == null) monthlyOrders = 0L;

        dashboard.put("last30Days", Map.of(
            "newOrders", monthlyOrders.intValue(),
            "revenue", monthlyRevenue,
            "newCustomers", 0,
            "avgOrderValue", monthlyOrders > 0 ? monthlyRevenue.divide(BigDecimal.valueOf(monthlyOrders), 2, BigDecimal.ROUND_HALF_UP) : BigDecimal.ZERO
        ));

        return dashboard;
    }
    
    @Transactional(readOnly = true)
    public Map<String, Object> getShopOrders(String shopId, Pageable pageable, String status, String dateFrom, String dateTo) {
        Shop shop = shopRepository.findByShopId(shopId)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with shop ID: " + shopId));

        // Fetch orders from the database using the shop's internal ID with status filter
        Page<Order> orderPage;
        if (status != null && !status.isEmpty()) {
            // Filter by status with order items eagerly loaded
            Order.OrderStatus orderStatus = Order.OrderStatus.valueOf(status.toUpperCase());
            orderPage = orderRepository.findByShopIdAndStatusWithOrderItems(shop.getId(), orderStatus, pageable);
        } else {
            // Get all orders with order items eagerly loaded
            orderPage = orderRepository.findByShopIdWithOrderItems(shop.getId(), pageable);
        }

        // Query for active assignments for all orders
        List<Long> orderIds = orderPage.getContent().stream()
                .map(Order::getId)
                .collect(Collectors.toList());

        List<OrderAssignment.AssignmentStatus> activeStatuses = List.of(
                OrderAssignment.AssignmentStatus.ASSIGNED,
                OrderAssignment.AssignmentStatus.ACCEPTED,
                OrderAssignment.AssignmentStatus.PICKED_UP,
                OrderAssignment.AssignmentStatus.IN_TRANSIT
        );

        Map<Long, Boolean> orderAssignmentMap = new HashMap<>();
        for (Long orderId : orderIds) {
            Optional<OrderAssignment> activeAssignment = orderAssignmentRepository
                    .findActiveAssignmentByOrderId(orderId, activeStatuses);
            orderAssignmentMap.put(orderId, activeAssignment.isPresent());
        }

        // Convert to response DTOs with assignment info
        List<OrderResponse> orderResponses = orderPage.getContent().stream()
                .map(order -> convertToOrderResponse(order, orderAssignmentMap.get(order.getId())))
                .toList();
        
        // Calculate summary statistics
        Long totalOrders = orderRepository.countOrdersByShop(shop.getId());
        BigDecimal totalRevenue = orderRepository.getTotalRevenueByShop(shop.getId());
        if (totalRevenue == null) totalRevenue = BigDecimal.ZERO;
        
        BigDecimal avgOrderValue = orderRepository.getAverageOrderValueByShop(shop.getId());
        if (avgOrderValue == null) avgOrderValue = BigDecimal.ZERO;
        
        // Get status breakdown
        List<Object[]> statusBreakdownData = orderRepository.getOrderStatusDistribution(shop.getId());
        Map<String, Long> statusBreakdown = new HashMap<>();
        statusBreakdown.put("PENDING", 0L);
        statusBreakdown.put("CONFIRMED", 0L);
        statusBreakdown.put("PREPARING", 0L);
        statusBreakdown.put("READY", 0L);
        statusBreakdown.put("OUT_FOR_DELIVERY", 0L);
        statusBreakdown.put("DELIVERED", 0L);
        statusBreakdown.put("CANCELLED", 0L);
        
        for (Object[] row : statusBreakdownData) {
            String orderStatus = row[0].toString();
            Long count = (Long) row[1];
            statusBreakdown.put(orderStatus, count);
        }
        
        Map<String, Object> ordersData = new HashMap<>();
        ordersData.put("orders", orderResponses);
        ordersData.put("totalElements", orderPage.getTotalElements());
        ordersData.put("totalPages", orderPage.getTotalPages());
        ordersData.put("currentPage", orderPage.getNumber());
        ordersData.put("pageSize", orderPage.getSize());
        ordersData.put("hasNext", orderPage.hasNext());
        ordersData.put("hasPrevious", orderPage.hasPrevious());
        
        // Summary data
        ordersData.put("summary", Map.of(
            "totalOrders", totalOrders,
            "totalRevenue", totalRevenue,
            "avgOrderValue", avgOrderValue,
            "statusBreakdown", statusBreakdown
        ));
        
        return ordersData;
    }
    
    @Transactional(readOnly = true)
    public Map<String, Object> getShopAnalytics(String shopId, int days) {
        Shop shop = shopRepository.findByShopId(shopId)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with shop ID: " + shopId));
        
        Map<String, Object> analytics = new HashMap<>();
        
        // Time period info
        LocalDateTime endDate = LocalDateTime.now();
        LocalDateTime startDate = endDate.minusDays(days);
        
        analytics.put("period", Map.of(
            "startDate", startDate.toString(),
            "endDate", endDate.toString(),
            "days", days
        ));
        
        // Sales analytics (mock data for now)
        analytics.put("salesAnalytics", Map.of(
            "totalRevenue", BigDecimal.ZERO,
            "totalOrders", 0,
            "avgOrderValue", BigDecimal.ZERO,
            "revenueGrowth", 0.0,
            "orderGrowth", 0.0,
            "dailyRevenue", List.of(),
            "dailyOrders", List.of(),
            "hourlyPattern", Map.of(),
            "weekdayPattern", Map.of()
        ));
        
        // Customer analytics
        analytics.put("customerAnalytics", Map.of(
            "totalCustomers", 0,
            "newCustomers", 0,
            "returningCustomers", 0,
            "customerRetentionRate", 0.0,
            "avgOrdersPerCustomer", 0.0,
            "topCustomers", List.of()
        ));
        
        // Product analytics
        analytics.put("productAnalytics", Map.of(
            "totalProducts", 0,
            "bestSellingProducts", List.of(),
            "lowPerformingProducts", List.of(),
            "categoryPerformance", Map.of(),
            "stockAnalysis", Map.of(
                "totalItems", 0,
                "lowStock", 0,
                "outOfStock", 0,
                "overStock", 0
            )
        ));
        
        // Performance metrics
        analytics.put("performanceMetrics", Map.of(
            "orderFulfillmentRate", 0.0,
            "avgDeliveryTime", "N/A",
            "customerSatisfactionScore", 0.0,
            "returnRate", 0.0,
            "cancellationRate", 0.0
        ));
        
        // Geographic analytics
        analytics.put("geographicAnalytics", Map.of(
            "ordersByLocation", Map.of(),
            "deliveryZones", List.of(),
            "topDeliveryAreas", List.of()
        ));
        
        return analytics;
    }
    
    private OrderResponse convertToOrderResponse(Order order) {
        return convertToOrderResponse(order, null);
    }

    private OrderResponse convertToOrderResponse(Order order, Boolean assignedToDeliveryPartner) {
        // Convert order items to response DTOs
        List<OrderResponse.OrderItemResponse> orderItemResponses = order.getOrderItems() != null
                ? order.getOrderItems().stream()
                        .map(this::convertToOrderItemResponse)
                        .toList()
                : new ArrayList<>();

        // Use the provided assignedToDeliveryPartner value if available, otherwise try to get from order
        Boolean isAssigned = assignedToDeliveryPartner != null ?
                assignedToDeliveryPartner :
                order.getAssignedToDeliveryPartner();

        return OrderResponse.builder()
                .id(order.getId())
                .orderNumber(order.getOrderNumber())
                .status(order.getStatus())
                .paymentStatus(order.getPaymentStatus())
                .paymentMethod(order.getPaymentMethod())
                .customerId(order.getCustomer() != null ? order.getCustomer().getId() : null)
                .customerName(order.getCustomer() != null ?
                    order.getCustomer().getFirstName() + " " + order.getCustomer().getLastName() : null)
                .customerEmail(order.getCustomer() != null ? order.getCustomer().getEmail() : null)
                .customerPhone(order.getCustomer() != null ? order.getCustomer().getMobileNumber() : null)
                .shopId(order.getShop() != null ? order.getShop().getId() : null)
                .shopName(order.getShop() != null ? order.getShop().getName() : null)
                .shopAddress(order.getShop() != null ? order.getShop().getAddressLine1() : null)
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
                .estimatedDeliveryTime(order.getEstimatedDeliveryTime())
                .actualDeliveryTime(order.getActualDeliveryTime())
                .orderItems(orderItemResponses)
                .assignedToDeliveryPartner(isAssigned)
                .createdAt(order.getCreatedAt())
                .updatedAt(order.getUpdatedAt())
                .build();
    }

    private OrderResponse.OrderItemResponse convertToOrderItemResponse(OrderItem orderItem) {
        return OrderResponse.OrderItemResponse.builder()
                .id(orderItem.getId())
                .shopProductId(orderItem.getShopProduct() != null ? orderItem.getShopProduct().getId() : null)
                .productName(orderItem.getProductName())
                .productDescription(orderItem.getShopProduct() != null && orderItem.getShopProduct().getMasterProduct() != null
                        ? orderItem.getShopProduct().getMasterProduct().getDescription()
                        : null)
                .productSku(orderItem.getShopProduct() != null && orderItem.getShopProduct().getMasterProduct() != null
                        ? orderItem.getShopProduct().getMasterProduct().getSku()
                        : null)
                .productImageUrl(orderItem.getShopProduct() != null && orderItem.getShopProduct().getMasterProduct() != null
                        ? orderItem.getShopProduct().getMasterProduct().getPrimaryImageUrl()
                        : null)
                .quantity(orderItem.getQuantity())
                .unitPrice(orderItem.getUnitPrice())
                .totalPrice(orderItem.getTotalPrice())
                .specialInstructions(orderItem.getSpecialInstructions())
                .build();
    }

}