package com.shopmanagement.product.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.product.dto.MasterProductRequest;
import com.shopmanagement.product.dto.MasterProductResponse;
import com.shopmanagement.product.entity.MasterProduct;
import com.shopmanagement.product.service.MasterProductService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/products/master")
@RequiredArgsConstructor
@Slf4j
public class MasterProductController {

    private final MasterProductService masterProductService;

    @GetMapping
    public ResponseEntity<ApiResponse<Page<MasterProductResponse>>> getAllProducts(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String brand,
            @RequestParam(required = false) MasterProduct.ProductStatus status,
            @RequestParam(required = false) Boolean isFeatured,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "updatedAt") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDirection) {
        
        log.info("Fetching master products - page: {}, size: {}", page, size);
        
        Sort.Direction direction = sortDirection.equalsIgnoreCase("ASC") ? Sort.Direction.ASC : Sort.Direction.DESC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        
        Specification<MasterProduct> spec = Specification.where(null);
        
        if (categoryId != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("category").get("id"), categoryId));
        }
        
        if (brand != null && !brand.isEmpty()) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("brand"), brand));
        }
        
        if (status != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("status"), status));
        }
        
        if (isFeatured != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("isFeatured"), isFeatured));
        }
        
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
        
        Page<MasterProductResponse> products = masterProductService.getAllProducts(spec, pageable);
        
        return ResponseEntity.ok(ApiResponse.success(
                products,
                "Master products fetched successfully"
        ));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<MasterProductResponse>> getProductById(@PathVariable Long id) {
        log.info("Fetching master product by ID: {}", id);
        MasterProductResponse product = masterProductService.getProductById(id);
        return ResponseEntity.ok(ApiResponse.success(
                product,
                "Master product fetched successfully"
        ));
    }

    @GetMapping("/sku/{sku}")
    public ResponseEntity<ApiResponse<MasterProductResponse>> getProductBySku(@PathVariable String sku) {
        log.info("Fetching master product by SKU: {}", sku);
        MasterProductResponse product = masterProductService.getProductBySku(sku);
        return ResponseEntity.ok(ApiResponse.success(
                product,
                "Master product fetched successfully"
        ));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<ApiResponse<MasterProductResponse>> createProduct(
            @Valid @RequestBody MasterProductRequest request) {
        log.info("Creating master product: {}", request.getName());
        MasterProductResponse product = masterProductService.createProduct(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(
                product,
                "Master product created successfully"
        ));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<ApiResponse<MasterProductResponse>> updateProduct(
            @PathVariable Long id,
            @Valid @RequestBody MasterProductRequest request) {
        log.info("Updating master product: {}", id);
        MasterProductResponse product = masterProductService.updateProduct(id, request);
        return ResponseEntity.ok(ApiResponse.success(
                product,
                "Master product updated successfully"
        ));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteProduct(@PathVariable Long id) {
        log.info("Deleting master product: {}", id);
        masterProductService.deleteProduct(id);
        return ResponseEntity.ok(ApiResponse.success(
                (Void) null,
                "Master product deleted successfully"
        ));
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<Page<MasterProductResponse>>> searchProducts(
            @RequestParam String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Searching master products with query: {}", query);
        Pageable pageable = PageRequest.of(page, size);
        Page<MasterProductResponse> products = masterProductService.searchProducts(query, pageable);
        return ResponseEntity.ok(ApiResponse.success(
                products,
                "Search results fetched successfully"
        ));
    }

    @GetMapping("/featured")
    public ResponseEntity<ApiResponse<List<MasterProductResponse>>> getFeaturedProducts() {
        log.info("Fetching featured master products");
        List<MasterProductResponse> products = masterProductService.getFeaturedProducts();
        return ResponseEntity.ok(ApiResponse.success(
                products,
                "Featured products fetched successfully"
        ));
    }

    @GetMapping("/category/{categoryId}")
    public ResponseEntity<ApiResponse<Page<MasterProductResponse>>> getProductsByCategory(
            @PathVariable Long categoryId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching products by category: {}", categoryId);
        Pageable pageable = PageRequest.of(page, size);
        Page<MasterProductResponse> products = masterProductService.getProductsByCategory(categoryId, pageable);
        return ResponseEntity.ok(ApiResponse.success(
                products,
                "Products fetched successfully for category"
        ));
    }

    @GetMapping("/brands")
    public ResponseEntity<ApiResponse<List<String>>> getAllBrands() {
        log.info("Fetching all product brands");
        List<String> brands = masterProductService.getAllBrands();
        return ResponseEntity.ok(ApiResponse.success(
                brands,
                "Brands fetched successfully"
        ));
    }
}