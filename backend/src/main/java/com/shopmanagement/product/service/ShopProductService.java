package com.shopmanagement.product.service;

import com.shopmanagement.product.dto.ShopProductRequest;
import com.shopmanagement.product.dto.ShopProductResponse;
import com.shopmanagement.product.entity.MasterProduct;
import com.shopmanagement.product.entity.ProductCategory;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.product.entity.ShopProductImage;
import com.shopmanagement.product.exception.ProductNotFoundException;
import com.shopmanagement.product.mapper.ProductMapper;
import com.shopmanagement.product.repository.MasterProductRepository;
import com.shopmanagement.product.repository.ProductCategoryRepository;
import com.shopmanagement.product.repository.ShopProductRepository;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.exception.ShopNotFoundException;
import com.shopmanagement.shop.repository.ShopRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.stream.IntStream;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ShopProductService {

    private final ShopProductRepository shopProductRepository;
    private final MasterProductRepository masterProductRepository;
    private final ShopRepository shopRepository;
    private final ProductCategoryRepository categoryRepository;
    private final ProductMapper productMapper;

    @Transactional(readOnly = true)
    public Page<ShopProductResponse> getShopProducts(Long shopId, Specification<ShopProduct> spec, Pageable pageable) {
        // Add shop filter to specification
        Specification<ShopProduct> shopSpec = (root, query, cb) -> cb.equal(root.get("shop").get("id"), shopId);
        Specification<ShopProduct> combinedSpec = spec != null ? shopSpec.and(spec) : shopSpec;
        
        Page<ShopProduct> productPage = shopProductRepository.findAll(combinedSpec, pageable);
        
        // Load products with relationships for better performance
        List<Long> productIds = productPage.getContent().stream()
                .map(ShopProduct::getId)
                .toList();
                
        if (productIds.isEmpty()) {
            return productPage.map(productMapper::toResponse);
        }
        
        // Fetch shop images and master products separately to avoid MultipleBagFetchException
        List<ShopProduct> productsWithShopImages = shopProductRepository.findAllWithShopImagesAndMasterProduct(productIds);
        List<ShopProduct> productsWithMasterImages = shopProductRepository.findAllWithMasterProductImages(productIds);
        
        // Create maps for efficient lookup
        Map<Long, ShopProduct> shopImageMap = productsWithShopImages.stream()
                .collect(java.util.stream.Collectors.toMap(ShopProduct::getId, p -> p));
        Map<Long, ShopProduct> masterImageMap = productsWithMasterImages.stream()
                .collect(java.util.stream.Collectors.toMap(ShopProduct::getId, p -> p));
        
        return productPage.map(product -> {
            // Enrich product with images
            ShopProduct shopImageProduct = shopImageMap.get(product.getId());
            ShopProduct masterImageProduct = masterImageMap.get(product.getId());
            
            if (shopImageProduct != null && shopImageProduct.getShopImages() != null) {
                product.setShopImages(shopImageProduct.getShopImages());
            }
            if (masterImageProduct != null && masterImageProduct.getMasterProduct() != null 
                && masterImageProduct.getMasterProduct().getImages() != null) {
                product.getMasterProduct().setImages(masterImageProduct.getMasterProduct().getImages());
            }
            
            return productMapper.toResponse(product);
        });
    }

    @Transactional(readOnly = true)
    public ShopProductResponse getShopProduct(Long shopId, Long productId) {
        ShopProduct shopProduct = shopProductRepository.findById(productId)
                .filter(p -> p.getShop().getId().equals(shopId))
                .orElseThrow(() -> new RuntimeException("Shop product not found"));
        
        return productMapper.toResponse(shopProduct);
    }

    public ShopProductResponse addProductToShop(Long shopId, ShopProductRequest request) {
        log.info("Adding product to shop: {} - MasterProductId: {}, CustomName: {}", shopId, request.getMasterProductId(), request.getCustomName());

        // Validate required fields for CREATE operation
        if (request.getPrice() == null) {
            throw new IllegalArgumentException("Price is required when adding a product to shop");
        }
        // barcode1 is now optional - shops can add products without barcodes

        // Get shop
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new RuntimeException("Shop not found with id: " + shopId));

        MasterProduct masterProduct;

        // If masterProductId is provided, use existing master product
        if (request.getMasterProductId() != null) {
            masterProduct = masterProductRepository.findById(request.getMasterProductId())
                    .orElseThrow(() -> new RuntimeException("Master product not found with id: " + request.getMasterProductId()));

            // Check if product already exists in shop
            if (shopProductRepository.existsByShopAndMasterProduct(shop, masterProduct)) {
                throw new RuntimeException("Product already exists in shop");
            }
        } else {
            // Auto-create a master product for custom/offline products
            log.info("Creating master product for custom shop product: {}", request.getCustomName());

            String productName = request.getCustomName() != null ? request.getCustomName() : "Custom Product";
            String sku = (request.getSku() != null && !request.getSku().trim().isEmpty())
                    ? request.getSku().trim()
                    : "CUSTOM-" + System.currentTimeMillis();

            // Resolve category: use provided categoryId, or find by name, or default to "General"
            ProductCategory category = null;
            if (request.getCategoryId() != null) {
                category = categoryRepository.findById(request.getCategoryId()).orElse(null);
            }
            if (category == null && request.getCategoryName() != null && !request.getCategoryName().isBlank()) {
                category = categoryRepository.findByNameIgnoreCase(request.getCategoryName()).orElse(null);
            }
            if (category == null) {
                // Find or create a default "General" category - check by slug first to avoid duplicate key
                category = categoryRepository.findBySlug("general")
                        .or(() -> categoryRepository.findByName("General"))
                        .orElseGet(() -> {
                    log.info("Creating default 'General' category for offline product creation");
                    ProductCategory general = ProductCategory.builder()
                            .name("General")
                            .slug("general")
                            .isActive(true)
                            .sortOrder(0)
                            .createdBy(getCurrentUsername())
                            .updatedBy(getCurrentUsername())
                            .build();
                    return categoryRepository.save(general);
                });
            }

            masterProduct = MasterProduct.builder()
                    .name(productName)
                    .nameTamil(request.getNameTamil())
                    .description(request.getCustomDescription())
                    .sku(sku)
                    .barcode(request.getBarcode1())
                    .baseUnit(request.getBaseUnit() != null ? request.getBaseUnit() : "piece")
                    .category(category)
                    .status(MasterProduct.ProductStatus.ACTIVE)
                    .createdBy(getCurrentUsername())
                    .updatedBy(getCurrentUsername())
                    .build();

            masterProduct = masterProductRepository.save(masterProduct);
            log.info("Created master product with ID: {} for custom product: {} (category: {})", masterProduct.getId(), productName, category.getName());
        }
        
        // Create shop product
        ShopProduct shopProduct = ShopProduct.builder()
                .shop(shop)
                .masterProduct(masterProduct)
                .price(request.getPrice())
                .originalPrice(request.getOriginalPrice())
                .costPrice(request.getCostPrice())
                .stockQuantity(request.getStockQuantity())
                .minStockLevel(request.getMinStockLevel())
                .maxStockLevel(request.getMaxStockLevel())
                .trackInventory(request.getTrackInventory())
                .status(request.getStatus())
                .isAvailable(request.getIsAvailable())
                .isFeatured(request.getIsFeatured())
                .customName(request.getCustomName())
                .customDescription(request.getCustomDescription())
                .customAttributes(request.getCustomAttributes())
                .displayOrder(request.getDisplayOrder())
                .tags(request.getTags())
                .barcode1(request.getBarcode1() != null ? request.getBarcode1().trim() : null)
                .barcode2(request.getBarcode2() != null ? request.getBarcode2().trim() : null)
                .barcode3(request.getBarcode3() != null ? request.getBarcode3().trim() : null)
                .createdBy(getCurrentUsername())
                .updatedBy(getCurrentUsername())
                .build();
        
        // Add shop-specific images if provided
        if (request.getShopImageUrls() != null && !request.getShopImageUrls().isEmpty()) {
            List<ShopProductImage> images = IntStream.range(0, request.getShopImageUrls().size())
                    .mapToObj(i -> ShopProductImage.builder()
                            .shopProduct(shopProduct)
                            .imageUrl(request.getShopImageUrls().get(i))
                            .isPrimary(i == 0) // First image is primary
                            .sortOrder(i)
                            .createdBy(getCurrentUsername())
                            .build())
                    .toList();
            shopProduct.getShopImages().addAll(images);
        }
        
        ShopProduct savedProduct = shopProductRepository.save(shopProduct);
        
        // Update shop's product count
        updateShopProductCount(shop);
        
        log.info("Product added to shop successfully: Shop {} - Product {}", shopId, savedProduct.getId());
        
        return productMapper.toResponse(savedProduct);
    }

    public ShopProductResponse updateShopProduct(Long shopId, Long productId, ShopProductRequest request) {
        log.info("Updating shop product: Shop {} - Product {}", shopId, productId);

        ShopProduct shopProduct = shopProductRepository.findById(productId)
                .filter(p -> p.getShop().getId().equals(shopId))
                .orElseThrow(() -> new RuntimeException("Shop product not found"));

        log.debug("Current masterProduct: {}, Request masterProductId: {}", shopProduct.getMasterProduct().getId(), request.getMasterProductId());

        // Update fields (masterProductId is ignored for UPDATE operations)
        productMapper.updateEntity(request, shopProduct);
        shopProduct.setUpdatedBy(getCurrentUsername());

        // Update shop-specific unit/weight overrides (not master product)
        // These override the master product's defaults for this specific shop
        if (request.getBaseWeight() != null) {
            shopProduct.setBaseWeight(request.getBaseWeight());
        }
        if (request.getBaseUnit() != null) {
            shopProduct.setBaseUnit(request.getBaseUnit());
        }

        // Update MasterProduct fields (sku, barcode, voice search tags, Tamil name)
        MasterProduct masterProduct = shopProduct.getMasterProduct();
        boolean masterProductUpdated = false;

        if (request.getSku() != null && !request.getSku().trim().isEmpty()) {
            masterProduct.setSku(request.getSku().trim());
            masterProductUpdated = true;
            log.debug("Updating master product SKU to: {}", request.getSku());
        }

        if (request.getBarcode() != null) {
            String newBarcode = request.getBarcode().trim().isEmpty() ? null : request.getBarcode().trim();

            // Check for duplicate barcode (only if setting a non-null value)
            if (newBarcode != null) {
                boolean barcodeExists = masterProductRepository.existsByBarcodeAndIdNot(newBarcode, masterProduct.getId());
                if (barcodeExists) {
                    throw new RuntimeException("Barcode already exists: " + newBarcode + ". Please use a unique barcode.");
                }
            }

            masterProduct.setBarcode(newBarcode);
            masterProductUpdated = true;
            log.debug("Updating master product barcode to: {}", request.getBarcode());
        }

        if (request.getVoiceSearchTags() != null) {
            masterProduct.setTags(request.getVoiceSearchTags().trim().isEmpty() ? null : request.getVoiceSearchTags().trim());
            masterProductUpdated = true;
            log.debug("Updating master product voice search tags to: {}", request.getVoiceSearchTags());
        }

        if (request.getNameTamil() != null) {
            masterProduct.setNameTamil(request.getNameTamil().trim().isEmpty() ? null : request.getNameTamil().trim());
            masterProductUpdated = true;
            log.debug("Updating master product Tamil name to: {}", request.getNameTamil());
        }

        if (masterProductUpdated) {
            masterProduct.setUpdatedBy(getCurrentUsername());
            masterProductRepository.save(masterProduct);
            log.info("Master product {} updated with SKU/barcode/tags/Tamil name", masterProduct.getId());
        }

        // Update shop-level barcodes (barcode1, barcode2, barcode3) with duplicate validation
        Long barcodeShopId = shopProduct.getShop().getId();
        String barcode1 = request.getBarcode1() != null ? (request.getBarcode1().trim().isEmpty() ? null : request.getBarcode1().trim()) : shopProduct.getBarcode1();
        String barcode2 = request.getBarcode2() != null ? (request.getBarcode2().trim().isEmpty() ? null : request.getBarcode2().trim()) : shopProduct.getBarcode2();
        String barcode3 = request.getBarcode3() != null ? (request.getBarcode3().trim().isEmpty() ? null : request.getBarcode3().trim()) : shopProduct.getBarcode3();

        // Check for duplicate barcodes within same product
        if (barcode1 != null && barcode2 != null && barcode1.equalsIgnoreCase(barcode2)) {
            throw new RuntimeException("Barcode 1 and Barcode 2 cannot be the same.");
        }
        if (barcode1 != null && barcode3 != null && barcode1.equalsIgnoreCase(barcode3)) {
            throw new RuntimeException("Barcode 1 and Barcode 3 cannot be the same.");
        }
        if (barcode2 != null && barcode3 != null && barcode2.equalsIgnoreCase(barcode3)) {
            throw new RuntimeException("Barcode 2 and Barcode 3 cannot be the same.");
        }

        // Check for duplicate barcodes in other products
        if (barcode1 != null && shopProductRepository.existsByShopIdAndBarcodeAndIdNot(barcodeShopId, barcode1, productId)) {
            throw new RuntimeException("Barcode '" + barcode1 + "' already exists in this shop. Please use a unique barcode.");
        }
        if (barcode2 != null && shopProductRepository.existsByShopIdAndBarcodeAndIdNot(barcodeShopId, barcode2, productId)) {
            throw new RuntimeException("Barcode '" + barcode2 + "' already exists in this shop. Please use a unique barcode.");
        }
        if (barcode3 != null && shopProductRepository.existsByShopIdAndBarcodeAndIdNot(barcodeShopId, barcode3, productId)) {
            throw new RuntimeException("Barcode '" + barcode3 + "' already exists in this shop. Please use a unique barcode.");
        }

        shopProduct.setBarcode1(barcode1);
        shopProduct.setBarcode2(barcode2);
        shopProduct.setBarcode3(barcode3);

        // Update shop images if provided
        if (request.getShopImageUrls() != null) {
            shopProduct.getShopImages().clear();
            List<ShopProductImage> newImages = IntStream.range(0, request.getShopImageUrls().size())
                    .mapToObj(i -> ShopProductImage.builder()
                            .shopProduct(shopProduct)
                            .imageUrl(request.getShopImageUrls().get(i))
                            .isPrimary(i == 0)
                            .sortOrder(i)
                            .createdBy(getCurrentUsername())
                            .build())
                    .toList();
            shopProduct.getShopImages().addAll(newImages);
        }

        ShopProduct updatedProduct = shopProductRepository.save(shopProduct);
        log.info("Shop product updated successfully: {}", productId);

        return productMapper.toResponse(updatedProduct);
    }

    public void removeProductFromShop(Long shopId, Long productId) {
        log.info("Removing product from shop: Shop {} - Product {}", shopId, productId);

        ShopProduct shopProduct = shopProductRepository.findById(productId)
                .filter(p -> p.getShop().getId().equals(shopId))
                .orElseThrow(() -> new RuntimeException("Shop product not found"));

        // Get shop before updating the product
        Shop shop = shopProduct.getShop();

        // Soft delete: Set status to INACTIVE and make unavailable instead of deleting
        // This preserves order history and prevents foreign key violations
        shopProduct.setStatus(ShopProduct.ShopProductStatus.INACTIVE);
        shopProduct.setIsAvailable(false);
        shopProduct.setUpdatedBy(getCurrentUsername());
        shopProductRepository.save(shopProduct);

        // Update shop's product count
        updateShopProductCount(shop);

        log.info("Product removed from shop successfully (soft delete): {}", productId);
    }

    @Transactional(readOnly = true)
    public Page<ShopProductResponse> searchShopProducts(Long shopId, String search, Pageable pageable) {
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new RuntimeException("Shop not found with id: " + shopId));
        
        Page<ShopProduct> productPage = shopProductRepository.searchProductsInShop(shop, search, pageable);
        return productPage.map(productMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public List<ShopProductResponse> getFeaturedProducts(Long shopId) {
        List<ShopProduct> products = shopProductRepository.findFeaturedProductsByShop(shopId);
        return productMapper.toShopProductResponses(products);
    }

    @Transactional(readOnly = true)
    public List<ShopProductResponse> getLowStockProducts(Long shopId) {
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new RuntimeException("Shop not found with id: " + shopId));
        
        List<ShopProduct> products = shopProductRepository.findLowStockProducts(shop);
        return productMapper.toShopProductResponses(products);
    }

    public ShopProductResponse updateInventory(Long shopId, Long productId, Integer quantity, String operation) {
        log.info("Updating inventory: Shop {} - Product {} - Operation: {} - Quantity: {}", 
                shopId, productId, operation, quantity);
        
        ShopProduct shopProduct = shopProductRepository.findById(productId)
                .filter(p -> p.getShop().getId().equals(shopId))
                .orElseThrow(() -> new RuntimeException("Shop product not found"));
        
        if (!shopProduct.getTrackInventory()) {
            throw new RuntimeException("Inventory tracking is disabled for this product");
        }
        
        Integer currentStock = shopProduct.getStockQuantity();
        Integer newStock;
        
        switch (operation.toUpperCase()) {
            case "ADD":
                newStock = currentStock + quantity;
                break;
            case "SUBTRACT":
                newStock = currentStock - quantity;
                if (newStock < 0) {
                    throw new RuntimeException("Insufficient stock. Current: " + currentStock + ", Requested: " + quantity);
                }
                break;
            case "SET":
                newStock = quantity;
                break;
            default:
                throw new RuntimeException("Invalid operation. Use ADD, SUBTRACT, or SET");
        }
        
        shopProduct.setStockQuantity(newStock);
        
        // Update status based on stock
        if (newStock == 0) {
            shopProduct.setStatus(ShopProduct.ShopProductStatus.OUT_OF_STOCK);
            shopProduct.setIsAvailable(false);
        } else if (shopProduct.getStatus() == ShopProduct.ShopProductStatus.OUT_OF_STOCK) {
            shopProduct.setStatus(ShopProduct.ShopProductStatus.ACTIVE);
            shopProduct.setIsAvailable(true);
        }
        
        shopProduct.setUpdatedBy(getCurrentUsername());
        ShopProduct updatedProduct = shopProductRepository.save(shopProduct);
        
        log.info("Inventory updated: Product {} - Old stock: {} - New stock: {}", 
                productId, currentStock, newStock);
        
        return productMapper.toResponse(updatedProduct);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getShopProductStats(Long shopId) {
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new RuntimeException("Shop not found with id: " + shopId));
        
        long totalProducts = shopProductRepository.countAvailableProductsByShop(shop);
        long activeProducts = shopProductRepository.countByShopAndStatus(shop, ShopProduct.ShopProductStatus.ACTIVE);
        long outOfStock = shopProductRepository.countByShopAndStatus(shop, ShopProduct.ShopProductStatus.OUT_OF_STOCK);
        BigDecimal avgPrice = shopProductRepository.getAveragePriceForShop(shop);
        Object[] priceRange = shopProductRepository.getPriceRangeForShop(shop);
        
        return Map.of(
                "totalProducts", totalProducts,
                "activeProducts", activeProducts,
                "outOfStock", outOfStock,
                "averagePrice", avgPrice != null ? avgPrice : BigDecimal.ZERO,
                "minPrice", priceRange != null && priceRange[0] != null ? priceRange[0] : BigDecimal.ZERO,
                "maxPrice", priceRange != null && priceRange[1] != null ? priceRange[1] : BigDecimal.ZERO
        );
    }

    // Customer-facing methods
    public Page<ShopProductResponse> getAvailableShopProducts(Long shopId, String search, String category, Pageable pageable) {
        log.info("Fetching available products for shop: {} for customers", shopId);
        
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with id: " + shopId));
        
        Specification<ShopProduct> spec = Specification.where(
            (root, query, cb) -> cb.and(
                cb.equal(root.get("shop"), shop),
                cb.equal(root.get("isAvailable"), true),
                cb.equal(root.get("status"), ShopProduct.ShopProductStatus.ACTIVE)
            )
        );
        
        if (search != null && !search.isEmpty()) {
            String searchPattern = "%" + search.toLowerCase() + "%";
            spec = spec.and((root, query, cb) -> cb.or(
                cb.like(cb.lower(root.get("customName")), searchPattern),
                cb.like(cb.lower(root.get("customDescription")), searchPattern)
            ));
        }
        
        if (category != null && !category.isEmpty()) {
            spec = spec.and((root, query, cb) ->
                cb.equal(root.get("masterProduct").get("category").get("name"), category)
            );
        }
        
        Page<ShopProduct> products = shopProductRepository.findAll(spec, pageable);
        return products.map(productMapper::toResponse);
    }
    
    public ShopProductResponse getProductDetails(Long shopId, Long productId) {
        log.info("Fetching product details - shopId: {}, productId: {}", shopId, productId);
        
        ShopProduct product = shopProductRepository.findById(productId)
                .filter(p -> p.getShop().getId().equals(shopId))
                .orElseThrow(() -> new ProductNotFoundException("Product not found"));
        
        return productMapper.toResponse(product);
    }
    
    public List<String> getShopProductCategories(Long shopId) {
        log.info("Fetching product categories for shop: {}", shopId);

        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with id: " + shopId));

        return shopProductRepository.findDistinctCategoriesByShop(shop);
    }

    public int getShopProductCountByCategory(Long shopId, String categoryName) {
        log.info("Fetching product count for shop: {} and category: {}", shopId, categoryName);

        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with id: " + shopId));

        return shopProductRepository.countByShopAndCategory(shop, categoryName);
    }

    private void updateShopProductCount(Shop shop) {
        // Only count available (ACTIVE) products, excluding INACTIVE/deleted products
        long productCount = shopProductRepository.countAvailableProductsByShop(shop);
        shop.setProductCount((int) productCount);
        shopRepository.save(shop);
        log.debug("Updated product count for shop {}: {}", shop.getId(), productCount);
    }

    @Transactional(readOnly = true)
    public Page<com.shopmanagement.product.dto.MasterProductResponse> getAvailableMasterProducts(
            Long shopId, String search, Long categoryId, String brand, Pageable pageable) {
        log.info("Fetching available master products for shop: {}", shopId);
        
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new RuntimeException("Shop not found with id: " + shopId));
        
        // Create specification to filter master products
        Specification<MasterProduct> spec = Specification.where(null);
        
        // Filter out products already assigned to this shop
        spec = spec.and((root, query, cb) -> {
            var subquery = query.subquery(Long.class);
            var subRoot = subquery.from(ShopProduct.class);
            subquery.select(subRoot.get("masterProduct").get("id"))
                   .where(cb.equal(subRoot.get("shop"), shop));
            return cb.not(cb.in(root.get("id")).value(subquery));
        });
        
        // Apply search filter
        if (search != null && !search.isEmpty()) {
            String searchPattern = "%" + search.toLowerCase() + "%";
            spec = spec.and((root, query, cb) -> cb.or(
                cb.like(cb.lower(root.get("name")), searchPattern),
                cb.like(cb.lower(root.get("description")), searchPattern),
                cb.like(cb.lower(root.get("sku")), searchPattern),
                cb.like(cb.lower(root.get("barcode")), searchPattern),
                cb.like(cb.lower(root.get("brand")), searchPattern)
            ));
        }
        
        // Apply category filter
        if (categoryId != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("category").get("id"), categoryId));
        }
        
        // Apply brand filter
        if (brand != null && !brand.isEmpty()) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("brand"), brand));
        }
        
        // Only show active products
        spec = spec.and((root, query, cb) -> cb.equal(root.get("status"), MasterProduct.ProductStatus.ACTIVE));
        
        Page<MasterProduct> masterProducts = masterProductRepository.findAll(spec, pageable);

        // Fetch images for all products to avoid lazy loading issues
        List<Long> productIds = masterProducts.getContent().stream()
                .map(MasterProduct::getId)
                .toList();

        if (!productIds.isEmpty()) {
            // Load products with images
            List<MasterProduct> productsWithImages = masterProductRepository.findAllWithImages(productIds);
            java.util.Map<Long, MasterProduct> imageMap = productsWithImages.stream()
                    .collect(java.util.stream.Collectors.toMap(MasterProduct::getId, p -> p));

            // Enrich products with images
            masterProducts.getContent().forEach(product -> {
                MasterProduct productWithImages = imageMap.get(product.getId());
                if (productWithImages != null && productWithImages.getImages() != null) {
                    product.setImages(productWithImages.getImages());
                }
            });
        }

        // Convert to MasterProductResponse using ProductMapper
        return masterProducts.map(productMapper::toResponse);
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null ? authentication.getName() : "system";
    }

    /**
     * Find product by barcode in a specific shop
     * Used for POS barcode scanning
     */
    public ShopProductResponse findByBarcodeInShop(Long shopId, String barcode) {
        if (barcode == null || barcode.trim().isEmpty()) {
            return null;
        }

        // Find shop product by master product barcode
        ShopProduct shopProduct = shopProductRepository.findByShopIdAndMasterProductBarcode(shopId, barcode)
                .orElse(null);

        if (shopProduct == null) {
            // Also try SKU as fallback
            shopProduct = shopProductRepository.findByShopIdAndMasterProductSku(shopId, barcode)
                    .orElse(null);
        }

        if (shopProduct == null) {
            return null;
        }

        return productMapper.toResponse(shopProduct);
    }

    /**
     * Update product availability (active/inactive)
     */
    @Transactional
    public ShopProductResponse updateProductAvailability(Long shopId, Long productId, Boolean isAvailable) {
        log.info("Updating availability for product {} in shop {} to {}", productId, shopId, isAvailable);

        ShopProduct shopProduct = shopProductRepository.findById(productId)
                .orElseThrow(() -> new ProductNotFoundException("Shop product not found with id: " + productId));

        log.info("Found product {} belonging to shop {}, requested shop {}", productId, shopProduct.getShop().getId(), shopId);

        shopProduct.setIsAvailable(isAvailable);
        shopProduct.setStatus(isAvailable ? ShopProduct.ShopProductStatus.ACTIVE : ShopProduct.ShopProductStatus.INACTIVE);
        shopProduct.setUpdatedBy(getCurrentUsername());

        ShopProduct updated = shopProductRepository.save(shopProduct);
        log.info("Product {} availability updated to {}", productId, isAvailable);

        return productMapper.toResponse(updated);
    }

    /**
     * Quick update product price, MRP, stock, and barcode
     * Used for POS quick edit feature
     */
    public ShopProductResponse quickUpdateProduct(Long shopId, Long productId, ShopProductRequest request) {
        log.info("Quick updating product: Shop {} - Product {} - Price: {}, MRP: {}, Stock: {}, Barcode: {}",
                shopId, productId, request.getPrice(), request.getOriginalPrice(), request.getStockQuantity(), request.getBarcode());

        ShopProduct shopProduct = shopProductRepository.findById(productId)
                .filter(p -> p.getShop().getId().equals(shopId))
                .orElseThrow(() -> new ProductNotFoundException("Shop product not found"));

        // Update only the specified fields
        if (request.getPrice() != null) {
            shopProduct.setPrice(request.getPrice());
        }

        if (request.getOriginalPrice() != null) {
            shopProduct.setOriginalPrice(request.getOriginalPrice());
        }

        if (request.getStockQuantity() != null) {
            shopProduct.setStockQuantity(request.getStockQuantity());

            // Update status based on stock
            if (request.getStockQuantity() == 0) {
                shopProduct.setStatus(ShopProduct.ShopProductStatus.OUT_OF_STOCK);
                shopProduct.setIsAvailable(false);
            } else if (shopProduct.getStatus() == ShopProduct.ShopProductStatus.OUT_OF_STOCK) {
                shopProduct.setStatus(ShopProduct.ShopProductStatus.ACTIVE);
                shopProduct.setIsAvailable(true);
            }
        }

        // Update barcode on master product (with duplicate validation)
        if (request.getBarcode() != null) {
            MasterProduct masterProduct = shopProduct.getMasterProduct();
            String newBarcode = request.getBarcode().trim().isEmpty() ? null : request.getBarcode().trim();

            // Check for duplicate barcode (only if setting a non-null value)
            if (newBarcode != null) {
                boolean barcodeExists = masterProductRepository.existsByBarcodeAndIdNot(newBarcode, masterProduct.getId());
                if (barcodeExists) {
                    throw new RuntimeException("Barcode already exists: " + newBarcode + ". Please use a unique barcode.");
                }
            }

            masterProduct.setBarcode(newBarcode);
            masterProduct.setUpdatedBy(getCurrentUsername());
            masterProductRepository.save(masterProduct);
            log.info("Updated barcode for master product {}: {}", masterProduct.getId(), request.getBarcode());
        }

        // Update shop-level barcodes (barcode1, barcode2, barcode3) with duplicate validation
        Long barcodeShopId = shopProduct.getShop().getId();
        String barcode1 = request.getBarcode1() != null ? (request.getBarcode1().trim().isEmpty() ? null : request.getBarcode1().trim()) : shopProduct.getBarcode1();
        String barcode2 = request.getBarcode2() != null ? (request.getBarcode2().trim().isEmpty() ? null : request.getBarcode2().trim()) : shopProduct.getBarcode2();
        String barcode3 = request.getBarcode3() != null ? (request.getBarcode3().trim().isEmpty() ? null : request.getBarcode3().trim()) : shopProduct.getBarcode3();

        // Check for duplicate barcodes within same product
        if (barcode1 != null && barcode2 != null && barcode1.equalsIgnoreCase(barcode2)) {
            throw new RuntimeException("Barcode 1 and Barcode 2 cannot be the same.");
        }
        if (barcode1 != null && barcode3 != null && barcode1.equalsIgnoreCase(barcode3)) {
            throw new RuntimeException("Barcode 1 and Barcode 3 cannot be the same.");
        }
        if (barcode2 != null && barcode3 != null && barcode2.equalsIgnoreCase(barcode3)) {
            throw new RuntimeException("Barcode 2 and Barcode 3 cannot be the same.");
        }

        // Check for duplicate barcodes in other products (barcode1/2/3, SKU, and master barcode)
        if (barcode1 != null) {
            validateBarcodeNotDuplicate(barcodeShopId, barcode1, productId);
        }
        if (barcode2 != null) {
            validateBarcodeNotDuplicate(barcodeShopId, barcode2, productId);
        }
        if (barcode3 != null) {
            validateBarcodeNotDuplicate(barcodeShopId, barcode3, productId);
        }

        shopProduct.setBarcode1(barcode1);
        shopProduct.setBarcode2(barcode2);
        shopProduct.setBarcode3(barcode3);

        // Update SKU on master product
        if (request.getSku() != null) {
            MasterProduct masterProduct = shopProduct.getMasterProduct();
            String newSku = request.getSku().trim().isEmpty() ? null : request.getSku().trim();

            if (newSku != null) {
                // Validate SKU is not duplicate
                validateBarcodeNotDuplicate(barcodeShopId, newSku, productId);
            }

            masterProduct.setSku(newSku);
            masterProduct.setUpdatedBy(getCurrentUsername());
            masterProductRepository.save(masterProduct);
            log.info("Updated SKU for master product {}: {}", masterProduct.getId(), newSku);
        }

        shopProduct.setUpdatedBy(getCurrentUsername());
        ShopProduct updatedProduct = shopProductRepository.save(shopProduct);

        log.info("Product quick updated successfully: {}", productId);

        return productMapper.toResponse(updatedProduct);
    }

    /**
     * Validate that a barcode doesn't already exist in any barcode field, SKU, or master barcode
     */
    private void validateBarcodeNotDuplicate(Long shopId, String barcode, Long excludeProductId) {
        // Check against other products' barcode1, barcode2, barcode3
        if (shopProductRepository.existsByShopIdAndBarcodeAndIdNot(shopId, barcode, excludeProductId)) {
            throw new RuntimeException("Barcode '" + barcode + "' already exists in this shop. Please use a unique barcode.");
        }
        // Check against SKU
        if (shopProductRepository.existsByShopIdAndSkuAndIdNot(shopId, barcode, excludeProductId)) {
            throw new RuntimeException("Barcode '" + barcode + "' matches an existing product SKU. Please use a unique barcode.");
        }
        // Check against master product barcode
        if (shopProductRepository.existsByShopIdAndMasterBarcodeAndIdNot(shopId, barcode, excludeProductId)) {
            throw new RuntimeException("Barcode '" + barcode + "' matches an existing product barcode. Please use a unique barcode.");
        }
    }
}