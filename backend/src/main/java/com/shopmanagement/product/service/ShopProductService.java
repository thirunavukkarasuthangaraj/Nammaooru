package com.shopmanagement.product.service;

import com.shopmanagement.product.dto.ShopProductRequest;
import com.shopmanagement.product.dto.ShopProductResponse;
import com.shopmanagement.product.entity.MasterProduct;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.product.entity.ShopProductImage;
import com.shopmanagement.product.mapper.ProductMapper;
import com.shopmanagement.product.repository.MasterProductRepository;
import com.shopmanagement.product.repository.ShopProductRepository;
import com.shopmanagement.shop.entity.Shop;
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
        log.info("Product added to shop successfully: Shop {} - Product {}", shopId, savedProduct.getId());
        
        return productMapper.toResponse(savedProduct);
    }

    public ShopProductResponse updateShopProduct(Long shopId, Long productId, ShopProductRequest request) {
        log.info("Updating shop product: Shop {} - Product {}", shopId, productId);
        
        ShopProduct shopProduct = shopProductRepository.findById(productId)
                .filter(p -> p.getShop().getId().equals(shopId))
                .orElseThrow(() -> new RuntimeException("Shop product not found"));
        
        // Update fields
        productMapper.updateEntity(request, shopProduct);
        shopProduct.setUpdatedBy(getCurrentUsername());
        
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
        
        shopProductRepository.delete(shopProduct);
        log.info("Product removed from shop successfully: {}", productId);
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

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null ? authentication.getName() : "system";
    }
}