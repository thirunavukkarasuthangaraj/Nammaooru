package com.shopmanagement.product.controller;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shopmanagement.dto.ApiResponse;
import com.shopmanagement.product.dto.MasterProductResponse;
import com.shopmanagement.product.dto.VoiceSearchGroupedResponse;
import com.shopmanagement.product.service.ProductAISearchService;
import com.shopmanagement.service.GeminiSearchService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/products/search")
@RequiredArgsConstructor
@Slf4j
public class ProductAISearchController {

    private final ProductAISearchService productAISearchService;
    private final GeminiSearchService geminiSearchService;
    private final ObjectMapper objectMapper;

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
     * Supports natural language multi-product queries:
     * - "rice and dal" → searches for both rice and dal
     * - "milk & bread & cheese" → searches for milk, bread, and cheese
     */
    @PostMapping("/voice")
    public ResponseEntity<ApiResponse<List<MasterProductResponse>>> voiceSearchProducts(
            @RequestParam(name = "q") String voiceQuery
    ) {
        // Preprocess voice query to convert natural language to comma-separated format
        String processedQuery = preprocessVoiceQuery(voiceQuery);
        log.info("Voice search request: original={}, processed={}", voiceQuery, processedQuery);

        try {
            List<MasterProductResponse> results = productAISearchService.voiceSearchProducts(processedQuery);

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
     * Supports: "rice and dal" or "milk & bread & cheese & butter & eggs" (up to 5+ products)
     */
    @PostMapping("/voice/grouped")
    public ResponseEntity<ApiResponse<List<VoiceSearchGroupedResponse>>> voiceSearchGrouped(
            @RequestParam(name = "q") String voiceQuery
    ) {
        // Preprocess voice query to convert natural language to comma-separated format
        String processedQuery = preprocessVoiceQuery(voiceQuery);
        log.info("Grouped voice search request: original={}, processed={}", voiceQuery, processedQuery);

        try {
            List<VoiceSearchGroupedResponse> results = productAISearchService.voiceSearchGrouped(processedQuery);

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
     * Populate Tamil names in tags for better search
     * This endpoint updates all products to include their Tamil names in the tags field
     */
    @PostMapping("/populate-tamil-tags")
    public ResponseEntity<ApiResponse<String>> populateTamilTagsInProducts() {
        log.info("Populate Tamil tags request received");

        try {
            productAISearchService.populateTamilNamesInTags();
            return ResponseEntity.ok(ApiResponse.success(
                    "Tamil names have been added to product tags",
                    "Tamil language search will now work better"
            ));
        } catch (Exception e) {
            log.error("Error populating Tamil tags: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to populate Tamil tags: " + e.getMessage()));
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

    /**
     * Parse a photo of a handwritten shopping list using Gemini Vision AI.
     * Supports Tamil and English handwriting.
     * Returns a list of parsed item names.
     */
    @PostMapping("/parse-image")
    public ResponseEntity<ApiResponse<Map<String, Object>>> parseShoppingListImage(
            @RequestParam("image") MultipartFile image
    ) {
        log.info("Parse shopping list image: size={}KB, type={}", image.getSize() / 1024, image.getContentType());

        try {
            byte[] imageBytes = image.getBytes();
            String mimeType = image.getContentType() != null ? image.getContentType() : "image/jpeg";

            String prompt = "You are reading a handwritten shopping list. " +
                    "The list may be in Tamil (தமிழ்), English, or a mix of both. " +
                    "Extract each item from the list. " +
                    "Return ONLY a valid JSON array of strings, each string being one item with quantity if mentioned. " +
                    "Example: [\"அரிசி 5kg\", \"பருப்பு 1kg\", \"oil 1 litre\", \"sugar\"]. " +
                    "If you cannot read the image or it's not a shopping list, return [].";

            String aiResponse = geminiSearchService.callGeminiVisionAPI(prompt, imageBytes, mimeType);

            // Extract JSON array from response (Gemini might wrap it in markdown)
            String jsonStr = aiResponse.trim();
            if (jsonStr.contains("[")) {
                jsonStr = jsonStr.substring(jsonStr.indexOf("["), jsonStr.lastIndexOf("]") + 1);
            }

            List<String> items;
            try {
                items = objectMapper.readValue(jsonStr, new TypeReference<List<String>>() {});
            } catch (Exception e) {
                log.warn("Failed to parse AI response as JSON, splitting by lines: {}", aiResponse);
                items = new ArrayList<>();
                for (String line : aiResponse.split("\\n")) {
                    String cleaned = line.trim().replaceFirst("^[-•*\\d.]+\\s*", "");
                    if (!cleaned.isEmpty() && !cleaned.equals("[]")) {
                        items.add(cleaned);
                    }
                }
            }

            log.info("Parsed {} items from shopping list image", items.size());

            return ResponseEntity.ok(ApiResponse.success(
                    Map.of("items", items, "rawText", aiResponse),
                    "Parsed " + items.size() + " items from image"
            ));

        } catch (Exception e) {
            log.error("Error parsing shopping list image: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Failed to parse image: " + e.getMessage()));
        }
    }

    /**
     * Voice audio transcription — send audio clip to Gemini for transcription.
     * Gemini understands Tamil, English, Tanglish — much better than device STT.
     * Cost: ~$0.0001 per 5-sec clip (just transcription, no product catalog).
     */
    @PostMapping("/voice-audio")
    public ResponseEntity<ApiResponse<Map<String, Object>>> transcribeVoiceAudio(
            @RequestParam("audio") MultipartFile audio
    ) {
        log.info("Voice audio transcription: size={}KB, type={}", audio.getSize() / 1024, audio.getContentType());

        try {
            byte[] audioBytes = audio.getBytes();
            String mimeType = audio.getContentType() != null ? audio.getContentType() : "audio/wav";

            String prompt = "Listen to this audio clip. The person is speaking in Tamil, English, or Tanglish (mixed). " +
                    "They are ordering grocery/household products from a shop. " +
                    "Transcribe ONLY the product names and quantities they mention. " +
                    "Return a simple comma-separated list of product names in English. " +
                    "Examples: \"onion, tomato, rice 5kg\" or \"garlic, coconut oil\". " +
                    "If you hear Tamil words, translate to English product names. " +
                    "If unclear, give your best guess. Return ONLY product names, nothing else.";

            String aiResponse = geminiSearchService.callGeminiVisionAPI(prompt, audioBytes, mimeType);

            String transcribed = aiResponse != null ? aiResponse.trim() : "";
            log.info("Voice audio transcription result: '{}'", transcribed);

            return ResponseEntity.ok(ApiResponse.success(
                    Map.of("transcription", transcribed),
                    "Audio transcribed successfully"
            ));

        } catch (Exception e) {
            log.error("Error transcribing voice audio: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Transcription failed: " + e.getMessage()));
        }
    }

    /**
     * Preprocess voice query to convert natural language to comma-separated format
     * Examples:
     *   "rice and dal" → "rice,dal"
     *   "milk & bread" → "milk,bread"
     *   "oil or salt or spice" → "oil,salt,spice"
     *   "rice" → "rice" (no change)
     */
    private String preprocessVoiceQuery(String query) {
        if (query == null || query.trim().isEmpty()) {
            return query;
        }

        // If already contains commas, assume it's properly formatted
        if (query.contains(",")) {
            return query.trim();
        }

        // Convert natural language conjunctions to commas
        String processed = query
                .replaceAll("\\s+and\\s+", ",")  // "rice and dal" → "rice,dal"
                .replaceAll("\\s+&\\s+", ",")    // "rice & dal" → "rice,dal"
                .replaceAll("\\s+or\\s+", ",")   // "rice or dal" → "rice,dal"
                .trim();

        log.debug("Voice query preprocessing: \"{}\" → \"{}\"", query, processed);
        return processed;
    }
}
