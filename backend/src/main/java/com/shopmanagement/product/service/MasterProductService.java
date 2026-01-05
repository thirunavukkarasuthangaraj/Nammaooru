package com.shopmanagement.product.service;

import com.shopmanagement.product.dto.MasterProductRequest;
import com.shopmanagement.product.dto.MasterProductResponse;
import com.shopmanagement.product.entity.MasterProduct;
import com.shopmanagement.product.entity.MasterProductImage;
import com.shopmanagement.product.entity.ProductCategory;
import com.shopmanagement.product.mapper.ProductMapper;
import com.shopmanagement.product.repository.MasterProductRepository;
import com.shopmanagement.product.repository.ProductCategoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.IntStream;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class MasterProductService {

    private final MasterProductRepository masterProductRepository;
    private final ProductCategoryRepository categoryRepository;
    private final ProductMapper productMapper;

    @Transactional(readOnly = true)
    public Page<MasterProductResponse> getAllProducts(Specification<MasterProduct> spec, Pageable pageable) {
        Page<MasterProduct> productPage = masterProductRepository.findAll(spec, pageable);
        
        // Load images for better performance
        List<Long> productIds = productPage.getContent().stream()
                .map(MasterProduct::getId)
                .toList();
                
        List<MasterProduct> productsWithImages = productIds.isEmpty() ? 
            List.of() : masterProductRepository.findAllWithImages(productIds);
        
        return productPage.map(product -> {
            MasterProduct enrichedProduct = productsWithImages.stream()
                    .filter(p -> p.getId().equals(product.getId()))
                    .findFirst()
                    .orElse(product);
            return productMapper.toResponse(enrichedProduct);
        });
    }

    @Transactional(readOnly = true)
    public MasterProductResponse getProductById(Long id) {
        MasterProduct product = masterProductRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Master product not found with id: " + id));
        return productMapper.toResponse(product);
    }

    @Transactional(readOnly = true)
    public MasterProductResponse getProductBySku(String sku) {
        MasterProduct product = masterProductRepository.findBySku(sku)
                .orElseThrow(() -> new RuntimeException("Master product not found with SKU: " + sku));
        return productMapper.toResponse(product);
    }

    public MasterProductResponse createProduct(MasterProductRequest request) {
        log.info("Creating master product: {}", request.getName());

        // Get category - handle null categoryId
        if (request.getCategoryId() == null) {
            throw new RuntimeException("Category ID is required. Please provide a valid category.");
        }
        ProductCategory category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new RuntimeException("Category not found with id: " + request.getCategoryId()));

        // Auto-generate SKU if not provided
        String sku = request.getSku();
        if (sku == null || sku.trim().isEmpty()) {
            sku = generateSku(category, request.getName(), request.getBrand());
            log.info("Auto-generated SKU: {}", sku);
        }

        // Validate unique constraints
        validateUniqueFields(sku, request.getBarcode(), null);

        // Create master product
        MasterProduct product = MasterProduct.builder()
                .name(request.getName())
                .nameTamil(request.getNameTamil())
                .description(request.getDescription())
                .sku(sku)
                .barcode(request.getBarcode())
                .category(category)
                .brand(request.getBrand())
                .baseUnit(request.getBaseUnit())
                .baseWeight(request.getBaseWeight())
                .specifications(request.getSpecifications())
                .tags(request.getTags())
                .status(request.getStatus())
                .isFeatured(request.getIsFeatured())
                .isGlobal(request.getIsGlobal())
                .createdBy(getCurrentUsername())
                .updatedBy(getCurrentUsername())
                .build();
        
        // Add images if provided
        if (request.getImageUrls() != null && !request.getImageUrls().isEmpty()) {
            List<MasterProductImage> images = IntStream.range(0, request.getImageUrls().size())
                    .mapToObj(i -> MasterProductImage.builder()
                            .masterProduct(product)
                            .imageUrl(request.getImageUrls().get(i))
                            .isPrimary(i == 0) // First image is primary
                            .sortOrder(i)
                            .createdBy(getCurrentUsername())
                            .build())
                    .toList();
            product.getImages().addAll(images);
        }
        
        MasterProduct savedProduct = masterProductRepository.save(product);
        log.info("Master product created successfully with ID: {}", savedProduct.getId());
        
        return productMapper.toResponse(savedProduct);
    }

    public MasterProductResponse updateProduct(Long id, MasterProductRequest request) {
        log.info("Updating master product: {}", id);
        
        MasterProduct product = masterProductRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Master product not found with id: " + id));
        
        // Validate unique constraints (excluding current product)
        validateUniqueFields(request.getSku(), request.getBarcode(), id);
        
        // Get category if changed
        if (!product.getCategory().getId().equals(request.getCategoryId())) {
            ProductCategory category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new RuntimeException("Category not found with id: " + request.getCategoryId()));
            product.setCategory(category);
        }
        
        // Update fields
        product.setName(request.getName());
        product.setNameTamil(request.getNameTamil());
        product.setDescription(request.getDescription());
        product.setSku(request.getSku());
        product.setBarcode(request.getBarcode());
        product.setBrand(request.getBrand());
        product.setBaseUnit(request.getBaseUnit());
        product.setBaseWeight(request.getBaseWeight());
        product.setSpecifications(request.getSpecifications());
        product.setTags(request.getTags());
        product.setStatus(request.getStatus());
        product.setIsFeatured(request.getIsFeatured());
        product.setIsGlobal(request.getIsGlobal());
        product.setUpdatedBy(getCurrentUsername());
        
        // Update images if provided
        if (request.getImageUrls() != null) {
            product.getImages().clear();
            List<MasterProductImage> newImages = IntStream.range(0, request.getImageUrls().size())
                    .mapToObj(i -> MasterProductImage.builder()
                            .masterProduct(product)
                            .imageUrl(request.getImageUrls().get(i))
                            .isPrimary(i == 0)
                            .sortOrder(i)
                            .createdBy(getCurrentUsername())
                            .build())
                    .toList();
            product.getImages().addAll(newImages);
        }
        
        MasterProduct updatedProduct = masterProductRepository.save(product);
        log.info("Master product updated successfully: {}", id);
        
        return productMapper.toResponse(updatedProduct);
    }

    public void deleteProduct(Long id) {
        log.info("Deleting master product: {}", id);
        
        MasterProduct product = masterProductRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Master product not found with id: " + id));
        
        // Check if product is used in any shops
        if (!product.getShopProducts().isEmpty()) {
            throw new RuntimeException("Cannot delete product that is used in shops. Please remove from all shops first.");
        }
        
        masterProductRepository.delete(product);
        log.info("Master product deleted successfully: {}", id);
    }

    @Transactional(readOnly = true)
    public Page<MasterProductResponse> searchProducts(String search, Pageable pageable) {
        Page<MasterProduct> productPage = masterProductRepository.searchProducts(search, pageable);
        return productPage.map(productMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public List<MasterProductResponse> getFeaturedProducts() {
        List<MasterProduct> products = masterProductRepository.findFeaturedProducts();
        return products.stream()
                .map(productMapper::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public Page<MasterProductResponse> getProductsByCategory(Long categoryId, Pageable pageable) {
        Page<MasterProduct> productPage = masterProductRepository.findByCategoryId(categoryId, pageable);
        return productPage.map(productMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public List<String> getAllBrands() {
        return masterProductRepository.findAllBrands();
    }

    /**
     * Generate a unique SKU based on category, product name, and brand
     * Format: CAT-BRAND-NAME-UNIQUEID
     * Example: GRO-AMUL-MILK-001
     */
    private String generateSku(ProductCategory category, String productName, String brand) {
        // Extract category prefix (first 3 letters, uppercase)
        String categoryPrefix = category.getName()
                .replaceAll("[^a-zA-Z]", "")
                .substring(0, Math.min(3, category.getName().length()))
                .toUpperCase();

        // Extract brand prefix (first 3-4 letters, uppercase)
        String brandPrefix = "";
        if (brand != null && !brand.trim().isEmpty()) {
            brandPrefix = brand
                    .replaceAll("[^a-zA-Z]", "")
                    .substring(0, Math.min(4, brand.length()))
                    .toUpperCase();
        }

        // Extract product name prefix (first 3-4 letters, uppercase)
        String namePrefix = productName
                .replaceAll("[^a-zA-Z]", "")
                .substring(0, Math.min(4, productName.length()))
                .toUpperCase();

        // Generate unique counter
        String baseSku = categoryPrefix + "-" + (brandPrefix.isEmpty() ? "" : brandPrefix + "-") + namePrefix;

        // Find unique SKU by appending counter
        String sku = baseSku;
        int counter = 1;
        while (masterProductRepository.existsBySku(sku)) {
            sku = baseSku + "-" + String.format("%03d", counter);
            counter++;
            if (counter > 999) {
                // Fallback to timestamp if counter exceeds 999
                sku = baseSku + "-" + System.currentTimeMillis();
                break;
            }
        }

        return sku;
    }

    private void validateUniqueFields(String sku, String barcode, Long excludeId) {
        if (sku != null && !sku.trim().isEmpty()) {
            if (excludeId == null) {
                if (masterProductRepository.existsBySku(sku)) {
                    throw new RuntimeException("SKU already exists: " + sku);
                }
            } else {
                if (masterProductRepository.existsBySkuAndIdNot(sku, excludeId)) {
                    throw new RuntimeException("SKU already exists: " + sku);
                }
            }
        }

        if (barcode != null && !barcode.trim().isEmpty()) {
            if (excludeId == null) {
                if (masterProductRepository.existsByBarcode(barcode)) {
                    throw new RuntimeException("Barcode already exists: " + barcode);
                }
            } else {
                if (masterProductRepository.existsByBarcodeAndIdNot(barcode, excludeId)) {
                    throw new RuntimeException("Barcode already exists: " + barcode);
                }
            }
        }
    }

public MasterProductResponse updateVoiceFields(Long id, String nameTamil, String tags) {        log.info("Updating voice fields for product {}: nameTamil={}, tags={}", id, nameTamil, tags);        MasterProduct product = masterProductRepository.findById(id)                .orElseThrow(() -> new RuntimeException("Master product not found: " + id));                if (nameTamil != null) {            product.setNameTamil(nameTamil);        }        if (tags != null) {            product.setTags(tags);        }        product.setUpdatedBy(getCurrentUsername());                MasterProduct saved = masterProductRepository.save(product);        return productMapper.toResponse(saved);    }
    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null ? authentication.getName() : "system";
    }
}