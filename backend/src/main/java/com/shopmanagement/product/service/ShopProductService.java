package com.shopmanagement.product.service;

import com.shopmanagement.product.dto.ShopProductRequest;
import com.shopmanagement.product.dto.ShopProductResponse;
import com.shopmanagement.product.entity.MasterProduct;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.product.entity.ShopProductImage;
import com.shopmanagement.product.exception.ProductNotFoundException;
import com.shopmanagement.product.mapper.ProductMapper;
import com.shopmanagement.product.repository.MasterProductRepository;
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
        log.info("Adding product to shop: {} - Product: {}", shopId, request.getMasterProductId());

        // Validate required fields for CREATE operation
        if (request.getMasterProductId() == null) {
            throw new IllegalArgumentException("Master product ID is required when adding a product to shop");
        }
        if (request.getPrice() == null) {
            throw new IllegalArgumentException("Price is required when adding a product to shop");
        }

        // Get shop
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new RuntimeException("Shop not found with id: " + shopId));
        
        // Get master product
        MasterProduct masterProduct = masterProductRepository.findById(request.getMasterProductId())
                .orElseThrow(() -> new RuntimeException("Master product not found with id: " + request.getMasterProductId()));
        
        // Check if product already exists in shop
        if (shopProductRepository.existsByShopAndMasterProduct(shop, masterProduct)) {
            throw new RuntimeException("Product already exists in shop");
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
}