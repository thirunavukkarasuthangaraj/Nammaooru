package com.shopmanagement.product.service;

import com.shopmanagement.product.dto.MasterProductResponse;
import com.shopmanagement.product.entity.MasterProduct;
import com.shopmanagement.product.mapper.ProductMapper;
import com.shopmanagement.product.repository.MasterProductRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class ProductAISearchService {

    private final MasterProductRepository masterProductRepository;
    private final ProductMapper productMapper;

    /**
     * Search products based on natural language query using tag matching
     */
    public Page<MasterProductResponse> searchProductsByAI(String query, Pageable pageable) {
        log.info("AI Search query: {}", query);

        try {
            // Extract keywords from query
            List<MasterProduct> products = searchProductsByKeywords(query);

            // Apply pagination
            int start = (int) pageable.getOffset();
            int end = Math.min((start + pageable.getPageSize()), products.size());

            List<MasterProductResponse> pageContent = products.subList(start, end)
                    .stream()
                    .map(productMapper::toResponse)
                    .collect(Collectors.toList());

            return new PageImpl<>(pageContent, pageable, products.size());

        } catch (Exception e) {
            log.error("Error during AI search for query: {}", query, e);
            throw new RuntimeException("AI search failed: " + e.getMessage());
        }
    }

    /**
     * Search products by keywords in tags field
     */
    private List<MasterProduct> searchProductsByKeywords(String keywords) {
        log.debug("Searching products by keywords: {}", keywords);

        // Get all active products with tags
        List<MasterProduct> allProducts = masterProductRepository.findByStatusOrderByCreatedAtDesc(MasterProduct.ProductStatus.ACTIVE);

        // Split keywords and convert to lowercase for case-insensitive matching
        String[] keywordArray = keywords.toLowerCase().split("[,\\s]+");

        // Filter products that match keywords in their tags
        return allProducts.stream()
                .filter(product -> matchesKeywords(product, keywordArray))
                .collect(Collectors.toList());
    }

    /**
     * Check if product matches keywords across multiple fields
     * Priority: tags > name > brand > category > description
     */
    private boolean matchesKeywords(MasterProduct product, String[] keywords) {
        // Build searchable text from multiple fields for better matching
        StringBuilder searchableText = new StringBuilder();

        // Tags (highest priority)
        if (product.getTags() != null && !product.getTags().isEmpty()) {
            searchableText.append(product.getTags()).append(" ");
        }

        // Product name
        if (product.getName() != null) {
            searchableText.append(product.getName()).append(" ");
        }

        // Brand
        if (product.getBrand() != null) {
            searchableText.append(product.getBrand()).append(" ");
        }

        // Category name
        if (product.getCategory() != null && product.getCategory().getName() != null) {
            searchableText.append(product.getCategory().getName()).append(" ");
        }

        // Description
        if (product.getDescription() != null) {
            searchableText.append(product.getDescription()).append(" ");
        }

        String searchableTextLower = searchableText.toString().toLowerCase();
        log.debug("Voice search matching product: {} - searchable text: {}", product.getName(), searchableTextLower);

        // Check if ANY keyword matches (OR logic)
        for (String keyword : keywords) {
            if (keyword.length() > 0 && searchableTextLower.contains(keyword)) {
                log.debug("  -> Matched keyword: '{}'", keyword);
                return true;
            }
        }

        return false;
    }

    /**
     * Get product by ID
     */
    @Transactional(readOnly = true)
    public MasterProductResponse getProductWithAIDescription(Long productId) {
        MasterProduct product = masterProductRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Product not found with id: " + productId));

        return productMapper.toResponse(product);
    }

    /**
     * Search products with voice/text query
     * Returns up to 50 results for better user experience
     */
    public List<MasterProductResponse> voiceSearchProducts(String voiceQuery) {
        log.info("Voice search query: {}", voiceQuery);

        try {
            List<MasterProduct> products = searchProductsByKeywords(voiceQuery);
            log.info("Voice search found {} products for query: '{}'", products.size(), voiceQuery);

            return products.stream()
                    .limit(50) // Return more results for voice search (increased from 10)
                    .map(productMapper::toResponse)
                    .collect(Collectors.toList());

        } catch (Exception e) {
            log.error("Voice search failed: {}", e.getMessage());
            return new ArrayList<>();
        }
    }
}
