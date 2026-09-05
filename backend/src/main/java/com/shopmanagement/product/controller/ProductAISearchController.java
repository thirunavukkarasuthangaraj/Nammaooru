package com.shopmanagement.product.controller;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shopmanagement.dto.ApiResponse;
import com.shopmanagement.product.dto.MasterProductResponse;
import com.shopmanagement.product.dto.VoiceSearchGroupedResponse;
import com.shopmanagement.product.service.ProductAISearchService;
import com.shopmanagement.service.GeminiSearchService;
import com.shopmanagement.service.GroqService;
import com.shopmanagement.service.OpenAITranscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/products/search")
@RequiredArgsConstructor
@Slf4j
public class ProductAISearchController {

    private final ProductAISearchService productAISearchService;
    private final GeminiSearchService geminiSearchService;
    private final GroqService groqService;
    private final OpenAITranscriptionService openAITranscriptionService;
    private final ObjectMapper objectMapper;

    @Value("${voice.transcription.provider:gemini}")
    private String transcriptionProvider;

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
     * Resolve a single Tamil / Tanglish grocery word to its English keyword(s).
     * Lightweight helper for the POS live-search: the frontend keeps matching
     * against the shop's own product list locally and only calls this when its
     * built-in offline Tamil dictionary has no hit. Returns comma-separated
     * lowercase English keywords the frontend then re-filters with locally.
     */
    @GetMapping("/resolve-keyword")
    public ResponseEntity<ApiResponse<Map<String, Object>>> resolveKeyword(
            @RequestParam(name = "q") String query
    ) {
        log.info("Resolve keyword request: q={}", query);
        try {
            String prompt = "You translate ONE Indian grocery/household item into English. " +
                    "The input is a single item spoken in Tamil, Tanglish (romanized Tamil), or English: \"" + query + "\". " +
                    "Reply with ONLY the common English product keyword(s), comma-separated, lowercase, no other words, no explanation. " +
                    "Examples: 'முட்டை' -> egg | 'muttai' -> egg | 'பால்' -> milk | 'sarkkarai' -> sugar | " +
                    "'கடலை' -> gram,groundnut | 'thakkali' -> tomato. " +
                    "If you cannot map it, reply with the input word unchanged.";

            // Groq first — fast and currently the reliable provider in prod.
            // Gemini is a backup only, so a Gemini outage never slows this down.
            String raw;
            try {
                if (!groqService.isEnabled()) throw new IllegalStateException("Groq not enabled");
                raw = groqService.generateText(prompt);
            } catch (Exception groqError) {
                log.warn("Groq failed ({}), falling back to Gemini", groqError.getMessage());
                raw = geminiSearchService.generateText(prompt);
            }
            List<String> keywords = new ArrayList<>();
            if (raw != null) {
                for (String part : raw.replaceAll("[\\r\\n]+", ",").split(",")) {
                    String k = part.trim().toLowerCase();
                    // keep only short single-word/phrase keywords; drop any stray sentences
                    if (!k.isEmpty() && k.length() <= 30 && !keywords.contains(k)) {
                        keywords.add(k);
                    }
                }
            }

            Map<String, Object> result = new HashMap<>();
            result.put("query", query);
            result.put("keywords", keywords);
            return ResponseEntity.ok(ApiResponse.success(result, "Resolved " + keywords.size() + " keyword(s)"));
        } catch (Exception e) {
            // Surface the ROOT cause (e.g. HTTP 429 quota / 404 bad model) — the
            // wrapper "Failed to generate text" alone is undiagnosable without
            // server log access.
            Throwable root = e;
            while (root.getCause() != null && root.getCause() != root) root = root.getCause();
            String detail = root.getMessage() != null ? root.getMessage() : e.getMessage();
            log.error("Error resolving keyword: {}", detail);
            return ResponseEntity.badRequest().body(ApiResponse.error("Resolve failed: " + detail));
        }
    }

    /**
     * Parse a quick shop-owner price-update phrase — spoken or typed, Tamil/Tanglish/English —
     * into structured {item, weight, unit, price}. Used by the Daily Updates screen so an owner
     * can say/type "vengayam 1kg 100 rs" and have it resolve straight to an editable row.
     * One Gemini call does both the Tamil->English translation and the field extraction.
     */
    @GetMapping("/parse-price-entry")
    public ResponseEntity<ApiResponse<Map<String, Object>>> parsePriceEntry(
            @RequestParam(name = "text") String text
    ) {
        log.info("Parse price entry request: text={}", text);
        try {
            String prompt = "Parse this shop-owner price update sentence, spoken in Tamil, Tanglish (romanized Tamil), " +
                    "or English, for a grocery/household item: \"" + text + "\". " +
                    "Extract the product name translated to plain English, the pack size if mentioned " +
                    "(a number plus unit like kg/g/ml/l/pcs), and the price in rupees. " +
                    "Reply with ONLY valid JSON, no markdown fences, no explanation, in exactly this shape: " +
                    "{\"item\":\"<english product name>\",\"weight\":<number or null>,\"unit\":\"<kg|g|ml|l|pcs|null>\",\"price\":<number or null>}. " +
                    "Examples: " +
                    "'vengayam 1 kg 100 rs' -> {\"item\":\"onion\",\"weight\":1,\"unit\":\"kg\",\"price\":100} | " +
                    "'thakkali 500g 45' -> {\"item\":\"tomato\",\"weight\":500,\"unit\":\"g\",\"price\":45} | " +
                    "'muttai 6 pieces 60 rupees' -> {\"item\":\"egg\",\"weight\":6,\"unit\":\"pcs\",\"price\":60} | " +
                    "'paal 1 litre 55 rupees' -> {\"item\":\"milk\",\"weight\":1,\"unit\":\"l\",\"price\":55} | " +
                    "'sugar 40' -> {\"item\":\"sugar\",\"weight\":null,\"unit\":null,\"price\":40}. " +
                    "If no pack size is mentioned, set weight and unit to null. If you cannot find a price, set price to null.";

            // Groq first — fast and currently the reliable provider in prod.
            // Gemini is a backup only, so a Gemini outage never slows this down.
            String raw;
            try {
                if (!groqService.isEnabled()) throw new IllegalStateException("Groq not enabled");
                raw = groqService.generateText(prompt);
            } catch (Exception groqError) {
                log.warn("Groq failed ({}), falling back to Gemini", groqError.getMessage());
                raw = geminiSearchService.generateText(prompt);
            }

            String jsonStr = raw != null ? raw.trim() : "";
            if (jsonStr.startsWith("```")) {
                jsonStr = jsonStr.replaceAll("```json", "").replaceAll("```", "").trim();
            }
            if (jsonStr.contains("{")) {
                jsonStr = jsonStr.substring(jsonStr.indexOf("{"), jsonStr.lastIndexOf("}") + 1);
            }

            Map<String, Object> parsed = objectMapper.readValue(jsonStr, new TypeReference<Map<String, Object>>() {});
            return ResponseEntity.ok(ApiResponse.success(parsed, "Parsed price entry"));
        } catch (Exception e) {
            Throwable root = e;
            while (root.getCause() != null && root.getCause() != root) root = root.getCause();
            String detail = root.getMessage() != null ? root.getMessage() : e.getMessage();
            log.error("Error parsing price entry: {}", detail);
            return ResponseEntity.badRequest().body(ApiResponse.error("Parse failed: " + detail));
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
     * Voice audio transcription — send audio clip to AI for transcription.
     * Supports both Gemini and OpenAI Whisper (configurable via VOICE_TRANSCRIPTION_PROVIDER).
     * Gemini cost: ~$0.0001 per 5-sec clip. OpenAI Whisper cost: ~$0.006/minute.
     */
    @PostMapping("/voice-audio")
    public ResponseEntity<ApiResponse<Map<String, Object>>> transcribeVoiceAudio(
            @RequestParam("audio") MultipartFile audio,
            @RequestParam(name = "context", defaultValue = "grocery-list") String context
    ) {
        log.info("Voice audio transcription: size={}KB, type={}, provider={}, context={}",
                audio.getSize() / 1024, audio.getContentType(), transcriptionProvider, context);

        try {
            byte[] audioBytes = audio.getBytes();
            String mimeType = audio.getContentType() != null ? audio.getContentType() : "audio/wav";
            String transcribed;
            String usedProvider;

            // Use OpenAI Whisper if configured and enabled
            if ("openai".equalsIgnoreCase(transcriptionProvider) && openAITranscriptionService.isEnabled()) {
                log.info("Using OpenAI Whisper for transcription");
                transcribed = openAITranscriptionService.transcribeAudio(audioBytes, mimeType);
                usedProvider = "openai";

                // Fallback to Gemini/Groq if OpenAI fails
                if (transcribed == null || transcribed.isBlank()) {
                    log.warn("OpenAI Whisper returned empty, falling back to Gemini/Groq");
                    TranscriptionResult fallback = transcribeWithGeminiOrGroq(audioBytes, mimeType, audio.getOriginalFilename(), context);
                    transcribed = fallback.text;
                    usedProvider = fallback.provider + "-fallback";
                }
            } else {
                // Default: Groq (Whisper) first, Gemini automatically if Groq fails
                TranscriptionResult result = transcribeWithGeminiOrGroq(audioBytes, mimeType, audio.getOriginalFilename(), context);
                transcribed = result.text;
                usedProvider = result.provider;
            }

            transcribed = transcribed != null ? transcribed.trim() : "";
            log.info("Voice audio transcription result ({}): '{}'", usedProvider, transcribed);

            Map<String, Object> result = new HashMap<>();
            result.put("transcription", transcribed);
            result.put("provider", usedProvider);

            return ResponseEntity.ok(ApiResponse.success(result, "Audio transcribed successfully"));

        } catch (Exception e) {
            log.error("Error transcribing voice audio: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Transcription failed: " + e.getMessage()));
        }
    }

    private record TranscriptionResult(String text, String provider) {}

    /**
     * Transcribes with Groq's Whisper endpoint first — fast and currently the
     * reliable provider in prod. Falls back to Gemini only if Groq is disabled
     * or fails, so a Gemini outage never slows voice entry down.
     */
    private TranscriptionResult transcribeWithGeminiOrGroq(byte[] audioBytes, String mimeType, String filename, String context) {
        if (groqService.isEnabled()) {
            try {
                return new TranscriptionResult(groqService.transcribeAudio(audioBytes, filename), "groq");
            } catch (Exception groqError) {
                log.warn("Groq audio transcription failed ({}), falling back to Gemini", groqError.getMessage());
            }
        }
        return new TranscriptionResult(transcribeWithGemini(audioBytes, mimeType, context), "gemini");
    }

    /**
     * Transcribe audio using Gemini Vision API
     */
    private String transcribeWithGemini(byte[] audioBytes, String mimeType, String context) {
        String prompt = "price-entry".equals(context)
                ? "Listen to this audio clip. A shop owner is speaking a quick price update for a grocery item, " +
                    "in Tamil, English, or Tanglish (mixed). Transcribe the FULL sentence as plain text, " +
                    "keeping the item name, pack size (like 1kg, 500g), and price exactly as spoken — " +
                    "do NOT drop the numbers or the price. Translate any Tamil words to English. " +
                    "Example: they might say something like \"onion 1kg 100 rupees\" or \"vengayam 500 grams 25 rs\". " +
                    "Return ONLY the transcribed sentence, nothing else."
                : "Listen to this audio clip. The person is speaking in Tamil, English, or Tanglish (mixed). " +
                "They are ordering grocery/household products from a shop. " +
                "Transcribe ONLY the product names and quantities they mention. " +
                "Return a simple comma-separated list of product names in English. " +
                "Examples: \"onion, tomato, rice 5kg\" or \"garlic, coconut oil\". " +
                "If you hear Tamil words, translate to English product names. " +
                "If unclear, give your best guess. Return ONLY product names, nothing else.";

        String aiResponse = geminiSearchService.callGeminiVisionAPI(prompt, audioBytes, mimeType);
        return aiResponse != null ? aiResponse.trim() : "";
    }

    /**
     * Voice choice understanding — send audio + options context to Gemini.
     * When user is shown 2-3 product options, they speak to pick one.
     * Gemini hears raw audio + knows the options → returns structured choice.
     * Cost: ~$0.0001-0.0002 per choice (same as transcription).
     */
    @PostMapping("/voice-choice")
    public ResponseEntity<ApiResponse<Map<String, Object>>> understandVoiceChoice(
            @RequestParam("audio") MultipartFile audio,
            @RequestParam("options") String optionsJson
    ) {
        log.info("Voice choice understanding: audioSize={}KB, options={}", audio.getSize() / 1024, optionsJson);

        try {
            byte[] audioBytes = audio.getBytes();
            String mimeType = audio.getContentType() != null ? audio.getContentType() : "audio/wav";

            // Parse options to build readable list for Gemini
            List<Map<String, Object>> options = objectMapper.readValue(
                    optionsJson, new TypeReference<List<Map<String, Object>>>() {});

            StringBuilder optionsList = new StringBuilder();
            for (Map<String, Object> opt : options) {
                int idx = ((Number) opt.get("index")).intValue();
                String name = opt.get("name").toString();
                Object price = opt.get("price");
                optionsList.append(idx).append(". ").append(name);
                if (price != null) optionsList.append(" ₹").append(price);
                optionsList.append("\n");
            }

            String prompt = "Listen to this audio. The person was shown these grocery options:\n" +
                    optionsList +
                    "They are either: picking one option (by number or name), asking for a different product, " +
                    "saying 'done/enough/போதும்', or saying 'remove [product]'. " +
                    "They speak Tamil, English, or Tanglish (mixed Tamil+English). " +
                    "Common Tamil numbers: ஒன்று/ஒண்ணு=1, இரண்டு/ரெண்டு=2, மூன்று/மூணு=3. " +
                    "Return ONLY valid JSON (no markdown, no explanation):\n" +
                    "{\"action\":\"select\",\"index\":N} if they picked option N, or\n" +
                    "{\"action\":\"search\",\"query\":\"product name\"} if they asked for a different product, or\n" +
                    "{\"action\":\"done\"} if they said done/enough/stop, or\n" +
                    "{\"action\":\"remove\",\"query\":\"product name\"} if they want to remove something.";

            String aiResponse = geminiSearchService.callGeminiVisionAPI(prompt, audioBytes, mimeType);

            // Parse Gemini's JSON response
            String jsonStr = aiResponse != null ? aiResponse.trim() : "";
            // Strip markdown code fences if present
            if (jsonStr.startsWith("```")) {
                jsonStr = jsonStr.replaceAll("```json", "").replaceAll("```", "").trim();
            }
            if (jsonStr.contains("{")) {
                jsonStr = jsonStr.substring(jsonStr.indexOf("{"), jsonStr.lastIndexOf("}") + 1);
            }

            Map<String, Object> result;
            try {
                result = objectMapper.readValue(jsonStr, new TypeReference<Map<String, Object>>() {});
            } catch (Exception e) {
                log.warn("Failed to parse Gemini choice response as JSON: {}", aiResponse);
                // Fallback: treat as new search query
                result = Map.of("action", "search", "query", aiResponse != null ? aiResponse.trim() : "");
            }

            log.info("Voice choice result: {}", result);

            return ResponseEntity.ok(ApiResponse.success(result, "Voice choice understood"));

        } catch (Exception e) {
            log.error("Error understanding voice choice: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Voice choice failed: " + e.getMessage()));
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
