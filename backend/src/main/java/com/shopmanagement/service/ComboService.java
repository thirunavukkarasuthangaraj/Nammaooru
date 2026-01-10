package com.shopmanagement.service;

import com.shopmanagement.dto.combo.ComboResponse;
import com.shopmanagement.dto.combo.CreateComboRequest;
import com.shopmanagement.entity.ComboItem;
import com.shopmanagement.entity.ProductCombo;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.product.repository.ShopProductRepository;
import com.shopmanagement.repository.ComboItemRepository;
import com.shopmanagement.repository.ProductComboRepository;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.repository.ShopRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ComboService {

    private final ProductComboRepository comboRepository;
    private final ComboItemRepository comboItemRepository;
    private final ShopRepository shopRepository;
    private final ShopProductRepository shopProductRepository;

    /**
     * Create a new combo
     */
    @Transactional
    public ComboResponse createCombo(Long shopId, CreateComboRequest request) {
        log.info("Creating combo '{}' for shop {}", request.getName(), shopId);

        // Validate shop exists
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new RuntimeException("Shop not found: " + shopId));

        // Check if combo name already exists
        if (comboRepository.existsByShopIdAndNameIgnoreCase(shopId, request.getName())) {
            throw new RuntimeException("A combo with this name already exists");
        }

        // Validate dates
        if (request.getEndDate().isBefore(request.getStartDate())) {
            throw new RuntimeException("End date must be after start date");
        }

        // Calculate original price from items
        BigDecimal originalPrice = calculateOriginalPrice(request.getItems());

        // Validate combo price is less than original price
        if (request.getComboPrice().compareTo(originalPrice) >= 0) {
            throw new RuntimeException("Combo price must be less than original price (₹" + originalPrice + ")");
        }

        // Create combo entity
        ProductCombo combo = ProductCombo.builder()
                .shop(shop)
                .name(request.getName())
                .nameTamil(request.getNameTamil())
                .description(request.getDescription())
                .descriptionTamil(request.getDescriptionTamil())
                .bannerImageUrl(request.getBannerImageUrl())
                .comboPrice(request.getComboPrice())
                .originalPrice(originalPrice)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .isActive(request.getIsActive() != null ? request.getIsActive() : true)
                .maxQuantityPerOrder(request.getMaxQuantityPerOrder() != null ? request.getMaxQuantityPerOrder() : 5)
                .totalQuantityAvailable(request.getTotalQuantityAvailable())
                .displayOrder(request.getDisplayOrder() != null ? request.getDisplayOrder() : 0)
                .build();

        // Save combo first to get ID
        combo = comboRepository.save(combo);

        // Add items
        int order = 0;
        for (CreateComboRequest.ComboItemRequest itemRequest : request.getItems()) {
            ShopProduct product = shopProductRepository.findById(itemRequest.getShopProductId())
                    .orElseThrow(() -> new RuntimeException("Product not found: " + itemRequest.getShopProductId()));

            // Validate product belongs to same shop
            if (!product.getShop().getId().equals(shopId)) {
                throw new RuntimeException("Product " + itemRequest.getShopProductId() + " does not belong to this shop");
            }

            // Get product names
            String productName = product.getCustomName() != null ? product.getCustomName() :
                    (product.getMasterProduct() != null ? product.getMasterProduct().getName() : "Unknown Product");
            String productNameTamil = product.getMasterProduct() != null ? product.getMasterProduct().getNameTamil() : null;

            ComboItem item = ComboItem.builder()
                    .combo(combo)
                    .shopProduct(product)
                    .quantity(itemRequest.getQuantity() != null ? itemRequest.getQuantity() : 1)
                    .productName(productName)
                    .productNameTamil(productNameTamil)
                    .displayOrder(itemRequest.getDisplayOrder() != null ? itemRequest.getDisplayOrder() : order++)
                    .build();

            combo.addItem(item);
        }

        combo = comboRepository.save(combo);
        log.info("Created combo {} with {} items", combo.getId(), combo.getItemCount());

        return mapToResponse(combo, true);
    }

    /**
     * Update an existing combo
     */
    @Transactional
    public ComboResponse updateCombo(Long shopId, Long comboId, CreateComboRequest request) {
        log.info("Updating combo {} for shop {}", comboId, shopId);

        ProductCombo combo = comboRepository.findByIdAndShopId(comboId, shopId)
                .orElseThrow(() -> new RuntimeException("Combo not found"));

        // Check if name already exists (excluding current combo)
        if (comboRepository.existsByShopIdAndNameIgnoreCaseAndIdNot(shopId, request.getName(), comboId)) {
            throw new RuntimeException("A combo with this name already exists");
        }

        // Validate dates
        if (request.getEndDate().isBefore(request.getStartDate())) {
            throw new RuntimeException("End date must be after start date");
        }

        // Calculate original price from items
        BigDecimal originalPrice = calculateOriginalPrice(request.getItems());

        // Validate combo price
        if (request.getComboPrice().compareTo(originalPrice) >= 0) {
            throw new RuntimeException("Combo price must be less than original price (₹" + originalPrice + ")");
        }

        // Update combo fields
        combo.setName(request.getName());
        combo.setNameTamil(request.getNameTamil());
        combo.setDescription(request.getDescription());
        combo.setDescriptionTamil(request.getDescriptionTamil());
        combo.setBannerImageUrl(request.getBannerImageUrl());
        combo.setComboPrice(request.getComboPrice());
        combo.setOriginalPrice(originalPrice);
        combo.setStartDate(request.getStartDate());
        combo.setEndDate(request.getEndDate());
        combo.setIsActive(request.getIsActive() != null ? request.getIsActive() : true);
        combo.setMaxQuantityPerOrder(request.getMaxQuantityPerOrder() != null ? request.getMaxQuantityPerOrder() : 5);
        combo.setTotalQuantityAvailable(request.getTotalQuantityAvailable());
        combo.setDisplayOrder(request.getDisplayOrder() != null ? request.getDisplayOrder() : 0);

        // Delete existing items explicitly to avoid duplicate key constraint
        comboItemRepository.deleteByComboId(combo.getId());
        comboItemRepository.flush();
        combo.getItems().clear();

        int order = 0;
        for (CreateComboRequest.ComboItemRequest itemRequest : request.getItems()) {
            ShopProduct product = shopProductRepository.findById(itemRequest.getShopProductId())
                    .orElseThrow(() -> new RuntimeException("Product not found: " + itemRequest.getShopProductId()));

            if (!product.getShop().getId().equals(shopId)) {
                throw new RuntimeException("Product " + itemRequest.getShopProductId() + " does not belong to this shop");
            }

            // Get product names
            String productName = product.getCustomName() != null ? product.getCustomName() :
                    (product.getMasterProduct() != null ? product.getMasterProduct().getName() : "Unknown Product");
            String productNameTamil = product.getMasterProduct() != null ? product.getMasterProduct().getNameTamil() : null;

            ComboItem item = ComboItem.builder()
                    .combo(combo)
                    .shopProduct(product)
                    .quantity(itemRequest.getQuantity() != null ? itemRequest.getQuantity() : 1)
                    .productName(productName)
                    .productNameTamil(productNameTamil)
                    .displayOrder(itemRequest.getDisplayOrder() != null ? itemRequest.getDisplayOrder() : order++)
                    .build();

            combo.addItem(item);
        }

        combo = comboRepository.save(combo);
        log.info("Updated combo {} with {} items", combo.getId(), combo.getItemCount());

        return mapToResponse(combo, true);
    }

    /**
     * Delete a combo
     */
    @Transactional
    public void deleteCombo(Long shopId, Long comboId) {
        log.info("Deleting combo {} for shop {}", comboId, shopId);

        ProductCombo combo = comboRepository.findByIdAndShopId(comboId, shopId)
                .orElseThrow(() -> new RuntimeException("Combo not found"));

        comboRepository.delete(combo);
        log.info("Deleted combo {}", comboId);
    }

    /**
     * Get combo by ID
     */
    @Transactional(readOnly = true)
    public ComboResponse getComboById(Long shopId, Long comboId) {
        ProductCombo combo = comboRepository.findByIdAndShopId(comboId, shopId)
                .orElseThrow(() -> new RuntimeException("Combo not found"));

        return mapToResponse(combo, true);
    }

    /**
     * Get all combos for a shop (paginated)
     */
    @Transactional(readOnly = true)
    public Page<ComboResponse> getShopCombos(Long shopId, String status, Pageable pageable) {
        Page<ProductCombo> combos;

        if ("active".equalsIgnoreCase(status)) {
            combos = comboRepository.findByShopIdAndIsActive(shopId, true, pageable);
        } else if ("inactive".equalsIgnoreCase(status)) {
            combos = comboRepository.findByShopIdAndIsActive(shopId, false, pageable);
        } else {
            combos = comboRepository.findByShopId(shopId, pageable);
        }

        return combos.map(combo -> mapToResponse(combo, false));
    }

    /**
     * Get active combos for customer view
     */
    @Transactional(readOnly = true)
    public List<ComboResponse> getActiveCombosForCustomer(Long shopId) {
        List<ProductCombo> combos = comboRepository.findActiveCombosForCustomer(shopId, LocalDate.now());

        return combos.stream()
                .filter(this::isComboAvailable) // Filter out combos with out-of-stock items
                .map(combo -> mapToResponse(combo, true))
                .collect(Collectors.toList());
    }

    /**
     * Get combo details for customer
     */
    @Transactional(readOnly = true)
    public ComboResponse getComboForCustomer(Long comboId) {
        ProductCombo combo = comboRepository.findById(comboId)
                .orElseThrow(() -> new RuntimeException("Combo not found"));

        if (!combo.isCurrentlyActive()) {
            throw new RuntimeException("This combo is not currently available");
        }

        return mapToResponse(combo, true);
    }

    /**
     * Get all active combos across all shops for dashboard
     */
    @Transactional(readOnly = true)
    public List<ComboResponse> getAllActiveCombos() {
        List<ProductCombo> combos = comboRepository.findAllActiveCombos(LocalDate.now());

        return combos.stream()
                .filter(this::isComboAvailable) // Filter out combos with out-of-stock items
                .map(combo -> mapToResponse(combo, true))
                .collect(Collectors.toList());
    }

    /**
     * Toggle combo active status
     */
    @Transactional
    public ComboResponse toggleComboStatus(Long shopId, Long comboId) {
        ProductCombo combo = comboRepository.findByIdAndShopId(comboId, shopId)
                .orElseThrow(() -> new RuntimeException("Combo not found"));

        combo.setIsActive(!combo.getIsActive());
        combo = comboRepository.save(combo);

        log.info("Toggled combo {} status to {}", comboId, combo.getIsActive());
        return mapToResponse(combo, false);
    }

    /**
     * Increment combo sold count
     */
    @Transactional
    public void incrementSoldCount(Long comboId, int quantity) {
        ProductCombo combo = comboRepository.findById(comboId)
                .orElseThrow(() -> new RuntimeException("Combo not found"));

        combo.setTotalSold(combo.getTotalSold() + quantity);
        comboRepository.save(combo);
    }

    // Helper methods

    private BigDecimal calculateOriginalPrice(List<CreateComboRequest.ComboItemRequest> items) {
        BigDecimal total = BigDecimal.ZERO;

        for (CreateComboRequest.ComboItemRequest item : items) {
            ShopProduct product = shopProductRepository.findById(item.getShopProductId())
                    .orElseThrow(() -> new RuntimeException("Product not found: " + item.getShopProductId()));

            BigDecimal itemTotal = product.getPrice().multiply(BigDecimal.valueOf(item.getQuantity() != null ? item.getQuantity() : 1));
            total = total.add(itemTotal);
        }

        return total;
    }

    private boolean isComboAvailable(ProductCombo combo) {
        // Check if all items are in stock
        for (ComboItem item : combo.getItems()) {
            ShopProduct product = item.getShopProduct();
            // If product is null or has insufficient stock, combo is not available
            if (product == null) {
                return false;
            }
            Integer stockQty = product.getStockQuantity();
            if (stockQty == null || stockQty < item.getQuantity()) {
                return false;
            }
        }

        // Check if total quantity limit reached
        if (combo.getTotalQuantityAvailable() != null &&
            combo.getTotalSold() != null &&
            combo.getTotalSold() >= combo.getTotalQuantityAvailable()) {
            return false;
        }

        return true;
    }

    private String determineStatus(ProductCombo combo) {
        if (!combo.getIsActive()) return "INACTIVE";
        if (combo.isExpired()) return "EXPIRED";
        if (combo.isScheduled()) return "SCHEDULED";
        if (!isComboAvailable(combo)) return "OUT_OF_STOCK";
        return "ACTIVE";
    }

    private ComboResponse mapToResponse(ProductCombo combo, boolean includeItems) {
        ComboResponse.ComboResponseBuilder builder = ComboResponse.builder()
                .id(combo.getId())
                .shopId(combo.getShop().getId())
                .shopCode(combo.getShop().getShopId())
                .shopName(combo.getShop().getName())
                .name(combo.getName())
                .nameTamil(combo.getNameTamil())
                .description(combo.getDescription())
                .descriptionTamil(combo.getDescriptionTamil())
                .bannerImageUrl(combo.getBannerImageUrl())
                .comboPrice(combo.getComboPrice())
                .originalPrice(combo.getOriginalPrice())
                .savings(combo.getSavings())
                .discountPercentage(combo.getDiscountPercentage())
                .startDate(combo.getStartDate())
                .endDate(combo.getEndDate())
                .isActive(combo.getIsActive())
                .maxQuantityPerOrder(combo.getMaxQuantityPerOrder())
                .totalQuantityAvailable(combo.getTotalQuantityAvailable())
                .totalSold(combo.getTotalSold())
                .displayOrder(combo.getDisplayOrder())
                .itemCount(combo.getItemCount())
                .status(determineStatus(combo))
                .isAvailable(isComboAvailable(combo))
                .createdAt(combo.getCreatedAt())
                .updatedAt(combo.getUpdatedAt())
                .createdBy(combo.getCreatedBy());

        if (includeItems) {
            List<ComboResponse.ComboItemResponse> items = combo.getItems().stream()
                    .map(this::mapItemToResponse)
                    .collect(Collectors.toList());
            builder.items(items);
        }

        return builder.build();
    }

    private ComboResponse.ComboItemResponse mapItemToResponse(ComboItem item) {
        ShopProduct product = item.getShopProduct();

        // Handle case where shop product might have been deleted
        if (product == null) {
            log.warn("ComboItem {} has null ShopProduct - using stored values", item.getId());
            return ComboResponse.ComboItemResponse.builder()
                    .id(item.getId())
                    .shopProductId(0L)
                    .productName(item.getProductName() != null ? item.getProductName() : "Product Unavailable")
                    .productNameTamil(item.getProductNameTamil())
                    .productDescription(null)
                    .quantity(item.getQuantity())
                    .unitPrice(BigDecimal.ZERO)
                    .totalPrice(BigDecimal.ZERO)
                    .unit("")
                    .imageUrl(null)
                    .stockQuantity(0)
                    .inStock(false)
                    .displayOrder(item.getDisplayOrder())
                    .build();
        }

        // Use stored names from ComboItem, fallback to product relation for backward compatibility
        String productName = item.getProductName() != null ? item.getProductName() :
                (product.getCustomName() != null ? product.getCustomName() :
                (product.getMasterProduct() != null ? product.getMasterProduct().getName() : "Unknown Product"));

        String productNameTamil = item.getProductNameTamil() != null ? item.getProductNameTamil() :
                (product.getMasterProduct() != null ? product.getMasterProduct().getNameTamil() : null);

        String imageUrl = product.getPrimaryShopImageUrl();

        // Build unit string with null safety
        String unit = "";
        if (product.getBaseUnit() != null && product.getBaseWeight() != null) {
            unit = product.getBaseWeight() + " " + product.getBaseUnit();
        } else if (product.getMasterProduct() != null) {
            BigDecimal baseWeight = product.getMasterProduct().getBaseWeight();
            String baseUnit = product.getMasterProduct().getBaseUnit();
            if (baseWeight != null && baseUnit != null) {
                unit = baseWeight + " " + baseUnit;
            }
        }

        BigDecimal price = product.getPrice() != null ? product.getPrice() : BigDecimal.ZERO;
        Integer stockQty = product.getStockQuantity() != null ? product.getStockQuantity() : 0;

        return ComboResponse.ComboItemResponse.builder()
                .id(item.getId())
                .shopProductId(product.getId())
                .productName(productName)
                .productNameTamil(productNameTamil)
                .productDescription(product.getCustomDescription())
                .quantity(item.getQuantity())
                .unitPrice(price)
                .totalPrice(price.multiply(BigDecimal.valueOf(item.getQuantity())))
                .unit(unit)
                .imageUrl(imageUrl)
                .stockQuantity(stockQty)
                .inStock(stockQty >= item.getQuantity())
                .displayOrder(item.getDisplayOrder())
                .build();
    }
}
