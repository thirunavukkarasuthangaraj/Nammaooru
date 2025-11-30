package com.shopmanagement.product.service;

import com.shopmanagement.product.dto.MasterProductResponse;
import com.shopmanagement.product.dto.VoiceSearchGroupedResponse;
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

import java.util.*;
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
        log.info("Searching products by keywords: {}", keywords);

        // Get all active products with tags
        List<MasterProduct> allProducts = masterProductRepository.findByStatusOrderByCreatedAtDesc(MasterProduct.ProductStatus.ACTIVE);
        log.info("Total active products in database: {}", allProducts.size());

        // Split keywords and convert to lowercase for case-insensitive matching
        // Note: Tamil text won't be affected by toLowerCase() which is fine
        String[] keywordArray = keywords.split("[,\\s]+");
        log.info("Parsed {} keywords from query: '{}' -> {}", keywordArray.length, keywords, java.util.Arrays.toString(keywordArray));

        // Filter products that match keywords in their tags
        List<MasterProduct> results = allProducts.stream()
                .filter(product -> matchesKeywords(product, keywordArray))
                .collect(Collectors.toList());

        log.info("Found {} matching products", results.size());
        results.forEach(p -> log.info("  - {} (tags: {})", p.getName(), p.getTags()));

        return results;
    }

    /**
     * Check if product matches keywords across multiple fields
     * Uses fuzzy matching to handle typos and variations
     * Priority: tags > name > nameTamil > brand > category > description
     */
    private boolean matchesKeywords(MasterProduct product, String[] keywords) {
        // Build searchable text from multiple fields for better matching
        StringBuilder searchableText = new StringBuilder();

        // Tags (highest priority)
        if (product.getTags() != null && !product.getTags().isEmpty()) {
            searchableText.append(product.getTags()).append(" ");
        }

        // Product name (English)
        if (product.getName() != null) {
            searchableText.append(product.getName()).append(" ");
        }

        // Product name (Tamil) - for Tamil language search
        if (product.getNameTamil() != null) {
            searchableText.append(product.getNameTamil()).append(" ");
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
        log.debug("Search matching product: {} - searchable text contains: {}", product.getName(), searchableText.toString().substring(0, Math.min(100, searchableText.length())));

        // Check if ANY keyword matches using fuzzy matching (handles typos)
        for (String keyword : keywords) {
            if (keyword.length() > 0) {
                String keywordLower = keyword.toLowerCase();

                // Try exact match first (fastest)
                if (searchableTextLower.contains(keywordLower)) {
                    log.debug("  -> Exact match for keyword: '{}' in {}", keyword, product.getName());
                    return true;
                }

                // For Tamil text, also try direct match without toLowerCase
                if (searchableText.toString().contains(keyword)) {
                    log.debug("  -> Direct match for Tamil keyword: '{}' in {}", keyword, product.getName());
                    return true;
                }

                // Try fuzzy match (handles typos with 80% similarity threshold)
                if (fuzzyMatch(searchableTextLower, keywordLower, 0.80)) {
                    log.debug("  -> Fuzzy match for keyword: '{}' in {}", keyword, product.getName());
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * Fuzzy matching using word-level similarity
     * Splits text into words and checks similarity of each word against keyword
     */
    private boolean fuzzyMatch(String text, String keyword, double threshold) {
        String[] words = text.split("[\\s,]+"); // Split by spaces and commas

        for (String word : words) {
            if (word.length() > 0) {
                double similarity = calculateSimilarity(word, keyword);
                if (similarity >= threshold) {
                    log.debug("    Fuzzy: '{}' vs '{}' = {}", word, keyword, String.format("%.2f", similarity));
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Calculate similarity between two strings using Levenshtein distance
     * Returns value between 0.0 (completely different) and 1.0 (identical)
     */
    private double calculateSimilarity(String s1, String s2) {
        // Shorter string length for prefix matching (e.g., "puz" should match "puzhugal")
        int minLen = Math.min(s1.length(), s2.length());
        int maxLen = Math.max(s1.length(), s2.length());

        // Check prefix match first (for voice search, user might say partial word)
        if (s1.startsWith(s2) || s2.startsWith(s1)) {
            return minLen / (double) maxLen;  // Partial match score
        }

        // Levenshtein distance for typo tolerance
        int distance = levenshteinDistance(s1, s2);
        return 1.0 - (distance / (double) maxLen);
    }

    /**
     * Calculate Levenshtein distance between two strings
     * Measures minimum edits (insert, delete, substitute) needed to transform one string to another
     */
    private int levenshteinDistance(String s1, String s2) {
        int[][] dp = new int[s1.length() + 1][s2.length() + 1];

        for (int i = 0; i <= s1.length(); i++) {
            dp[i][0] = i;
        }
        for (int j = 0; j <= s2.length(); j++) {
            dp[0][j] = j;
        }

        for (int i = 1; i <= s1.length(); i++) {
            for (int j = 1; j <= s2.length(); j++) {
                int cost = s1.charAt(i - 1) == s2.charAt(j - 1) ? 0 : 1;
                dp[i][j] = Math.min(Math.min(
                        dp[i - 1][j] + 1,      // deletion
                        dp[i][j - 1] + 1),     // insertion
                        dp[i - 1][j - 1] + cost); // substitution
            }
        }

        return dp[s1.length()][s2.length()];
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
     * Results are ranked by relevance (exact matches first)
     */
    public List<MasterProductResponse> voiceSearchProducts(String voiceQuery) {
        log.info("Voice search query: '{}'", voiceQuery);

        try {
            List<MasterProduct> products = searchProductsByKeywords(voiceQuery);
            log.info("Voice search found {} products for query: '{}'", products.size(), voiceQuery);

            // Sort by relevance: products with exact tag matches first
            List<MasterProduct> rankedProducts = rankByRelevance(products, voiceQuery);

            List<MasterProductResponse> results = rankedProducts.stream()
                    .limit(50) // Return more results for voice search
                    .map(productMapper::toResponse)
                    .collect(Collectors.toList());

            log.info("Returning {} results for voice search", results.size());
            return results;

        } catch (Exception e) {
            log.error("Voice search failed: {}", e.getMessage(), e);
            return new ArrayList<>();
        }
    }

    /**
     * Rank products by relevance to the search query
     * Products with exact tag matches come first
     */
    private List<MasterProduct> rankByRelevance(List<MasterProduct> products, String query) {
        String[] keywords = query.toLowerCase().split("[,\\s]+");

        return products.stream()
                .sorted((p1, p2) -> {
                    int score1 = calculateRelevanceScore(p1, keywords);
                    int score2 = calculateRelevanceScore(p2, keywords);
                    return Integer.compare(score2, score1); // Higher score first
                })
                .collect(Collectors.toList());
    }

    /**
     * Calculate relevance score for a product based on keywords
     * Higher score = more relevant (exact matches score higher than fuzzy)
     */
    private int calculateRelevanceScore(MasterProduct product, String[] keywords) {
        int score = 0;
        String searchableText = buildSearchableText(product).toLowerCase();
        String[] words = searchableText.split("[\\s,]+");

        for (String keyword : keywords) {
            if (keyword.length() > 0) {
                // Exact match in tags (highest priority)
                if (product.getTags() != null && product.getTags().toLowerCase().contains(keyword)) {
                    score += 100;
                }
                // Exact match in Tamil name (high priority for Tamil-speaking customers)
                else if (product.getNameTamil() != null && product.getNameTamil().toLowerCase().contains(keyword)) {
                    score += 75;
                }
                // Exact match in English name
                else if (product.getName() != null && product.getName().toLowerCase().contains(keyword)) {
                    score += 50;
                }
                // Fuzzy match in any field
                else if (fuzzyMatch(searchableText, keyword, 0.80)) {
                    score += 25;
                }
                // Word-level fuzzy match
                for (String word : words) {
                    if (word.length() > 0 && calculateSimilarity(word, keyword) >= 0.80) {
                        score += 10;
                    }
                }
            }
        }

        return score;
    }

    /**
     * Build searchable text from product fields
     */
    private String buildSearchableText(MasterProduct product) {
        StringBuilder text = new StringBuilder();
        if (product.getTags() != null) text.append(product.getTags()).append(" ");
        if (product.getName() != null) text.append(product.getName()).append(" ");
        if (product.getBrand() != null) text.append(product.getBrand()).append(" ");
        if (product.getCategory() != null && product.getCategory().getName() != null) {
            text.append(product.getCategory().getName()).append(" ");
        }
        if (product.getDescription() != null) text.append(product.getDescription()).append(" ");
        return text.toString();
    }

    /**
     * Search products with multiple keywords and group results by keyword
     * Best for voice search with 5-10+ items
     * Returns organized results grouped by each keyword
     */
    public List<VoiceSearchGroupedResponse> voiceSearchGrouped(String voiceQuery) {
        log.info("Grouped voice search query: '{}'", voiceQuery);

        try {
            List<MasterProduct> allProducts = masterProductRepository.findByStatusOrderByCreatedAtDesc(MasterProduct.ProductStatus.ACTIVE);
            log.info("Total active products: {}", allProducts.size());

            // Split into individual keywords
            String[] keywords = voiceQuery.toLowerCase().split("[,\\s]+");
            keywords = Arrays.stream(keywords)
                    .filter(k -> k.length() > 0)
                    .toArray(String[]::new);

            log.info("Parsed {} keywords: {}", keywords.length, Arrays.toString(keywords));

            List<VoiceSearchGroupedResponse> groupedResults = new ArrayList<>();

            // For each keyword, find and group matching products
            for (String keyword : keywords) {
                List<MasterProduct> matchingProducts = findProductsForKeyword(allProducts, keyword);

                // Rank by relevance for this specific keyword
                List<MasterProduct> rankedProducts = matchingProducts.stream()
                        .sorted((p1, p2) -> Integer.compare(
                                calculateKeywordRelevance(p2, keyword),
                                calculateKeywordRelevance(p1, keyword)
                        ))
                        .limit(5) // Top 5 per keyword
                        .collect(Collectors.toList());

                if (!rankedProducts.isEmpty()) {
                    List<MasterProductResponse> responses = rankedProducts.stream()
                            .map(productMapper::toResponse)
                            .collect(Collectors.toList());

                    groupedResults.add(VoiceSearchGroupedResponse.builder()
                            .keyword(keyword)
                            .count(matchingProducts.size()) // Show total matching, but return top 5
                            .products(responses)
                            .build());

                    log.info("Keyword '{}': Found {} products, returning top 5", keyword, matchingProducts.size());
                }
            }

            log.info("Returning {} keyword groups", groupedResults.size());
            return groupedResults;

        } catch (Exception e) {
            log.error("Grouped voice search failed: {}", e.getMessage(), e);
            return new ArrayList<>();
        }
    }

    /**
     * Find products matching a single keyword
     */
    private List<MasterProduct> findProductsForKeyword(List<MasterProduct> products, String keyword) {
        return products.stream()
                .filter(product -> matchesKeywordSingle(product, keyword))
                .collect(Collectors.toList());
    }

    /**
     * Check if product matches a single keyword
     */
    private boolean matchesKeywordSingle(MasterProduct product, String keyword) {
        String searchableText = buildSearchableText(product).toLowerCase();

        // Exact match
        if (searchableText.contains(keyword)) {
            return true;
        }

        // Fuzzy match
        return fuzzyMatch(searchableText, keyword, 0.80);
    }

    /**
     * Calculate relevance score for a specific keyword
     */
    private int calculateKeywordRelevance(MasterProduct product, String keyword) {
        int score = 0;
        String searchableText = buildSearchableText(product).toLowerCase();

        // Tags match (highest priority)
        if (product.getTags() != null && product.getTags().toLowerCase().contains(keyword)) {
            score += 100;
        }
        // Tamil name match (high priority for Tamil-speaking customers)
        else if (product.getNameTamil() != null && product.getNameTamil().toLowerCase().contains(keyword)) {
            score += 75;
        }
        // English name match
        else if (product.getName() != null && product.getName().toLowerCase().contains(keyword)) {
            score += 50;
        }
        // Fuzzy match
        else if (fuzzyMatch(searchableText, keyword, 0.80)) {
            score += 25;
        }

        return score;
    }

    /**
     * Populate Tamil names in tags field for better searchability
     * This adds Tamil product names to the tags field so Tamil language search works
     */
    @Transactional
    public void populateTamilNamesInTags() {
        log.info("Starting bidirectional (English + Tamil) names population in tags field...");

        List<MasterProduct> allProducts = masterProductRepository.findAll();
        int updated = 0;

        for (MasterProduct product : allProducts) {
            StringBuilder newTags = new StringBuilder();

            // 1. Add English product name (for Tamil speakers searching in English)
            if (product.getName() != null && !product.getName().isEmpty()) {
                newTags.append(product.getName());
            }

            // 2. Add Tamil product name (for English speakers or Tamil script searches)
            if (product.getNameTamil() != null && !product.getNameTamil().isEmpty()) {
                if (newTags.length() > 0) {
                    newTags.append(", ");
                }
                newTags.append(product.getNameTamil());
            }

            // 3. Add category name (for broader searches)
            if (product.getCategory() != null && product.getCategory().getName() != null) {
                if (newTags.length() > 0) {
                    newTags.append(", ");
                }
                newTags.append(product.getCategory().getName());
            }

            // 4. Add brand if exists
            if (product.getBrand() != null && !product.getBrand().isEmpty()) {
                if (newTags.length() > 0) {
                    newTags.append(", ");
                }
                newTags.append(product.getBrand());
            }

            // 5. Add SKU for product code searches
            if (product.getSku() != null && !product.getSku().isEmpty()) {
                if (newTags.length() > 0) {
                    newTags.append(", ");
                }
                newTags.append(product.getSku());
            }

            String finalTags = newTags.toString();
            if (!finalTags.isEmpty() && !finalTags.equals(product.getTags())) {
                product.setTags(finalTags);
                masterProductRepository.save(product);
                updated++;
                log.debug("Updated tags for: {} -> {}", product.getName(), finalTags);
            }
        }

        log.info("Bidirectional tags population completed. Updated {} products", updated);
    }
}
