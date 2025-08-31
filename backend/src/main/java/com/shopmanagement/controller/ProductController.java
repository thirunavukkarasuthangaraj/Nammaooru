package com.shopmanagement.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import com.shopmanagement.product.entity.MasterProduct;
import com.shopmanagement.product.repository.MasterProductRepository;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/products")
@RequiredArgsConstructor
@Slf4j
public class ProductController {

    private final MasterProductRepository masterProductRepository;

    @GetMapping
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Page<MasterProduct>> getAllProducts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "name") String sortBy,
            @RequestParam(defaultValue = "ASC") String sortDirection) {
        
        log.info("Fetching all products - page: {}, size: {}", page, size);
        
        Sort.Direction direction = sortDirection.equalsIgnoreCase("DESC") ? 
            Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        
        Page<MasterProduct> products = masterProductRepository.findAll(pageable);
        return ResponseEntity.ok(products);
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<MasterProduct> getProductById(@PathVariable Long id) {
        log.info("Fetching product with ID: {}", id);
        MasterProduct product = masterProductRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found"));
        return ResponseEntity.ok(product);
    }
    
    @GetMapping("/search")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Page<MasterProduct>> searchProducts(
            @RequestParam String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        log.info("Searching products with query: {}", query);
        Pageable pageable = PageRequest.of(page, size);
        // Simple search - just return all products for now
        Page<MasterProduct> products = masterProductRepository.findAll(pageable);
        return ResponseEntity.ok(products);
    }
    
    @GetMapping("/stats")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getProductStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalProducts", masterProductRepository.count());
        stats.put("activeProducts", masterProductRepository.count()); // Simplified
        stats.put("featuredProducts", 5L); // Placeholder
        return ResponseEntity.ok(stats);
    }
}