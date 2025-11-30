package com.shopmanagement.product.controller;

import com.shopmanagement.dto.ApiResponse;
import com.shopmanagement.product.dto.MasterProductResponse;
import com.shopmanagement.product.dto.VoiceSearchGroupedResponse;
import com.shopmanagement.product.service.ProductAISearchService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/products/search")
@RequiredArgsConstructor
@Slf4j
public class ProductAISearchController {

    private final ProductAISearchService productAISearchService;

    /**
     * Search products using AI (Gemini) based on natural language query
     */
    @GetMapping("/ai")
    public ResponseEntity<ApiResponse<Page<MasterProductResponse>>> searchProductsByAI(
            @RequestParam(name = "q") String query,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "10") int size
    ) {
        log.info("AI Search request: query={}, page={}, size={}", query, page, size);

        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<MasterProductResponse> results = productAISearchService.searchProductsByAI(query, pageable);

            return ResponseEntity.ok(ApiResponse.success(
                    results,
                    "Found " + results.getTotalElements() + " products matching your search"
            ));
        } catch (Exception e) {
            log.error("Error during AI search: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Search failed: " + e.getMessage()));
        }
    }

    /**
     * Voice search - converts voice query to text and searches
     */
    @PostMapping("/voice")
    public ResponseEntity<ApiResponse<List<MasterProductResponse>>> voiceSearchProducts(
            @RequestParam(name = "q") String voiceQuery
    ) {
        log.info("Voice search request: query={}", voiceQuery);

        try {
            List<MasterProductResponse> results = productAISearchService.voiceSearchProducts(voiceQuery);

            return ResponseEntity.ok(ApiResponse.success(
                    results,
                    "Found " + results.size() + " products matching your voice search"
            ));
        } catch (Exception e) {
            log.error("Error during voice search: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Voice search failed: " + e.getMessage()));
        }
    }

    /**
     * Voice search with grouped results - best for multi-item searches (5-10+ items)
     * Returns results grouped and organized by keyword
     */
    @PostMapping("/voice/grouped")
    public ResponseEntity<ApiResponse<List<VoiceSearchGroupedResponse>>> voiceSearchGrouped(
            @RequestParam(name = "q") String voiceQuery
    ) {
        log.info("Grouped voice search request: query={}", voiceQuery);

        try {
            List<VoiceSearchGroupedResponse> results = productAISearchService.voiceSearchGrouped(voiceQuery);

            int totalProducts = results.stream().mapToInt(VoiceSearchGroupedResponse::getCount).sum();
            return ResponseEntity.ok(ApiResponse.success(
                    results,
                    "Found " + results.size() + " keyword groups with " + totalProducts + " total products"
            ));
        } catch (Exception e) {
            log.error("Error during grouped voice search: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Grouped voice search failed: " + e.getMessage()));
        }
    }

    /**
     * Get product with AI-generated description
     */
    @GetMapping("/{id}/with-description")
    public ResponseEntity<ApiResponse<MasterProductResponse>> getProductWithAIDescription(
            @PathVariable Long id
    ) {
        log.info("Get product with AI description: id={}", id);

        try {
            MasterProductResponse product = productAISearchService.getProductWithAIDescription(id);
            return ResponseEntity.ok(ApiResponse.success(product, "Product retrieved with AI description"));
        } catch (Exception e) {
            log.error("Error retrieving product: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to retrieve product: " + e.getMessage()));
        }
    }

    /**
     * Smart search - understands context and intent
     */
    @GetMapping("/smart")
    public ResponseEntity<ApiResponse<Page<MasterProductResponse>>> smartSearch(
            @RequestParam(name = "q") String query,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "10") int size
    ) {
        log.info("Smart search request: query={}", query);

        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<MasterProductResponse> results = productAISearchService.searchProductsByAI(query, pageable);

            return ResponseEntity.ok(ApiResponse.success(
                    results,
                    "Smart search found " + results.getTotalElements() + " products"
            ));
        } catch (Exception e) {
            log.error("Error during smart search: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Smart search failed: " + e.getMessage()));
        }
    }
}
