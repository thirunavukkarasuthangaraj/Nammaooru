package com.shopmanagement.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shopmanagement.config.GeminiConfig;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

@Slf4j
@Service
public class GeminiSearchService {

    private final GeminiConfig geminiConfig;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    // Round-robin counter for API key rotation
    private final AtomicInteger keyRotationCounter = new AtomicInteger(0);

    @Autowired
    public GeminiSearchService(GeminiConfig geminiConfig, RestTemplateBuilder restTemplateBuilder) {
        this.geminiConfig = geminiConfig;
        // Configure RestTemplate with timeouts (15s read for large AI search prompts)
        this.restTemplate = restTemplateBuilder
                .setConnectTimeout(Duration.ofSeconds(10))
                .setReadTimeout(Duration.ofSeconds(15))
                .build();
    }

    /**
     * Get next API key using round-robin rotation
     */
    private String getNextApiKey() {
        List<String> apiKeys = geminiConfig.getApiKeys();
        if (apiKeys == null || apiKeys.isEmpty()) {
            throw new IllegalStateException("No Gemini API keys configured");
        }

        int index = keyRotationCounter.getAndIncrement() % apiKeys.size();
        String key = apiKeys.get(index);

        log.debug("🔄 Using API key #{} (Total keys: {})", index + 1, apiKeys.size());
        return key;
    }

    /**
     * Use Gemini AI to enhance product search with Tamil + English understanding
     */
    public List<String> enhanceSearchQuery(String query, List<String> availableProducts) {
        if (!geminiConfig.getEnabled() || query == null || query.trim().isEmpty()) {
            return List.of(query);
        }

        try {
            log.info("🤖 Gemini AI Search - Query: {}", query);

            // Build AI prompt
            String prompt = buildSearchPrompt(query, availableProducts);

            // Call Gemini API
            String aiResponse = callGeminiAPI(prompt);

            // Parse AI response to get matching product names
            List<String> matchingProducts = parseAIResponse(aiResponse);

            log.info("✅ Gemini AI found {} matching products", matchingProducts.size());
            return matchingProducts;

        } catch (Exception e) {
            log.error("❌ Error calling Gemini AI: {}", e.getMessage(), e);
            // Fallback to original query if AI fails
            return List.of(query);
        }
    }

    /**
     * AI-powered product search: sends product catalog + query to Gemini,
     * returns ranked list of matching product IDs.
     */
    public List<Long> aiSearchProducts(String query, String productCatalog) {
        if (!geminiConfig.getEnabled() || query == null || query.trim().isEmpty()) {
            return List.of();
        }

        try {
            log.info("🧠 Gemini AI Product Search - Query: '{}'", query);

            // High-leverage prompt: explicit Tanglish examples + STT-error mappings + strict JSON output.
            // Tamil village customers speak Tanglish (Tamil words in Latin/English script), and STT mangles
            // it constantly. The catalog has products with English+Tamil names; we need to match across both.
            String prompt = "You are a product search engine for a Tamil village grocery shop.\n" +
                    "Customers speak Tamil, English, or Tanglish (Tamil words in English script).\n" +
                    "Their voice input often has speech-to-text errors. Your job: find the products they meant.\n\n" +
                    "MATCHING RULES (apply in order):\n" +
                    "1. Tamil script (தக்காளி) → match products with that Tamil name OR English equivalent (Tomato)\n" +
                    "2. Tanglish (\"thakkali\", \"thakali\", \"takkali\", \"dakkali\") → match Tomato\n" +
                    "3. English (\"tomato\", \"tomatto\") → match Tomato + Tamil தக்காளி\n" +
                    "4. STT errors — these all mean the SAME product:\n" +
                    "   • onion/union/only-on/oniyan/vengayam/vangayam/wengayam → வெங்காயம் (Onion)\n" +
                    "   • tomato/tamato/to-motto/thakkali/takkali/dakali → தக்காளி (Tomato)\n" +
                    "   • rice/arisi/arice/race/arisee → அரிசி (Rice)\n" +
                    "   • dal/doll/dhal/paruppu/parupu → பருப்பு (Dal/Lentils)\n" +
                    "   • sugar/sugaar/sakkarai/chakkarai/should-gar → சர்க்கரை (Sugar)\n" +
                    "   • oil/ennai/yennai → எண்ணெய் (Oil)\n" +
                    "   • potato/pot-auto/urulai-kizhangu → உருளைக்கிழங்கு (Potato)\n" +
                    "   • coconut/coco-not/thengai/thenkai → தேங்காய் (Coconut)\n" +
                    "   • garlic/poondu/poonthu → பூண்டு (Garlic)\n" +
                    "   • ginger/inji/ingee → இஞ்சி (Ginger)\n" +
                    "   • milk/paal → பால் (Milk)\n" +
                    "5. Intent queries — \"breakfast items\" → idli mix/dosa batter/bread; \"cooking oil\" → all oil products\n" +
                    "6. If product has multiple weights (500g, 1kg), return ALL matching SKUs\n" +
                    "7. NEVER invent products. Match ONLY against the catalog below.\n" +
                    "8. If nothing in the catalog matches, return [].\n\n" +
                    "OUTPUT FORMAT (strict):\n" +
                    "Return ONLY a JSON array of product IDs (integers), ordered by relevance (best first), max 20.\n" +
                    "No prose, no markdown, no code fences. Just the array.\n" +
                    "Examples: [42,15,7]  OR  []\n\n" +
                    "Product Catalog (format: id|englishName|tamilName|category):\n" +
                    productCatalog + "\n\n" +
                    "Customer voice query: \"" + query + "\"\n" +
                    "Matching product IDs:";

            String aiResponse = callGeminiAPI(prompt);

            // Parse the JSON array of IDs from response
            List<Long> productIds = parseProductIds(aiResponse);
            log.info("✅ Gemini AI Search returned {} product IDs", productIds.size());
            return productIds;

        } catch (Exception e) {
            log.error("❌ Gemini AI Product Search failed: {}", e.getMessage());
            return List.of();
        }
    }

    /**
     * Parse a JSON array of product IDs from Gemini response.
     * Handles responses that may contain markdown formatting or extra text.
     */
    private List<Long> parseProductIds(String aiResponse) {
        if (aiResponse == null || aiResponse.trim().isEmpty()) {
            return List.of();
        }

        try {
            // Extract JSON array from response (may be wrapped in markdown code blocks)
            String cleaned = aiResponse.trim();
            // Remove markdown code block if present
            cleaned = cleaned.replaceAll("```json\\s*", "").replaceAll("```\\s*", "");
            // Find the JSON array in the response
            int start = cleaned.indexOf('[');
            int end = cleaned.lastIndexOf(']');
            if (start == -1 || end == -1 || end <= start) {
                log.warn("No JSON array found in Gemini response: {}", aiResponse);
                return List.of();
            }
            cleaned = cleaned.substring(start, end + 1);

            JsonNode arrayNode = objectMapper.readTree(cleaned);
            if (!arrayNode.isArray()) {
                return List.of();
            }

            List<Long> ids = new ArrayList<>();
            for (JsonNode node : arrayNode) {
                if (node.isNumber()) {
                    ids.add(node.asLong());
                }
            }
            return ids;

        } catch (Exception e) {
            log.warn("Failed to parse product IDs from Gemini response: {}", e.getMessage());
            return List.of();
        }
    }

    /**
     * Build a smart prompt for Gemini to understand product search
     */
    private String buildSearchPrompt(String query, List<String> availableProducts) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("You are a product search assistant. Match the user's query to products from the list below.\n\n");

        prompt.append("QUERY: \"").append(query).append("\"\n\n");

        prompt.append("AVAILABLE PRODUCTS:\n");
        for (int i = 0; i < Math.min(availableProducts.size(), 100); i++) {
            prompt.append(availableProducts.get(i)).append("\n");
        }

        prompt.append("\nINSTRUCTIONS:\n");
        prompt.append("1. The query can be in Tamil script (தமிழ்), Tamil transliteration (arisi, paal), or English\n");
        prompt.append("2. Match products where the query word appears in the product name (English or Tamil part)\n");
        prompt.append("3. For transliterated queries, match the Tamil equivalent (e.g., 'arisi' = அரிசி = rice)\n");
        prompt.append("4. If query has multiple words, find matches for EACH word and return ALL matching products\n");
        prompt.append("5. Return ONLY products from the list above - copy the exact product name\n");
        prompt.append("6. One product per line\n");
        prompt.append("7. If no match found, return 'NONE'\n\n");

        prompt.append("Return matching products for: \"").append(query).append("\"");

        return prompt.toString();
    }

    /**
     * Call Gemini 1.5 Flash API using REST with automatic API key rotation
     */
    private String callGeminiAPI(String prompt) {
        // Get next API key using round-robin
        String currentApiKey = getNextApiKey();

        try {
            String url = String.format("%s/%s:generateContent?key=%s",
                geminiConfig.getApiUrl(), geminiConfig.getModel(), currentApiKey);

            // Build request body — low temperature for deterministic search/extraction.
            // Higher temperature only hurts product matching (we want the same answer twice).
            Map<String, Object> requestBody = Map.of(
                "contents", List.of(
                    Map.of("parts", List.of(
                        Map.of("text", prompt)
                    ))
                ),
                "generationConfig", Map.of(
                    "temperature", 0.1,
                    "topP", 0.9,
                    "maxOutputTokens", 1024
                )
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            log.debug("Calling Gemini API with rotated key");

            ResponseEntity<String> response = restTemplate.exchange(
                url,
                HttpMethod.POST,
                entity,
                String.class
            );

            // Parse response
            JsonNode root = objectMapper.readTree(response.getBody());
            JsonNode candidates = root.path("candidates");

            if (candidates.isArray() && candidates.size() > 0) {
                JsonNode content = candidates.get(0).path("content").path("parts");
                if (content.isArray() && content.size() > 0) {
                    String responseText = content.get(0).path("text").asText();
                    log.debug("✅ Gemini API Response received");
                    return responseText;
                }
            }

            log.warn("No valid response from Gemini API");
            return "";

        } catch (RestClientException e) {
            log.error("⏱️ Gemini API timeout or connection error: {}", e.getMessage());
            throw new RuntimeException("Gemini API timeout - please try again", e);
        } catch (Exception e) {
            log.error("❌ Error calling Gemini API: {}", e.getMessage());
            throw new RuntimeException("Failed to call Gemini API", e);
        }
    }

    /**
     * Parse AI response to extract product names
     */
    private List<String> parseAIResponse(String aiResponse) {
        List<String> products = new ArrayList<>();

        if (aiResponse == null || aiResponse.trim().isEmpty() || aiResponse.trim().equalsIgnoreCase("NONE")) {
            return products;
        }

        // Split by newlines and clean up
        String[] lines = aiResponse.split("\\n");
        for (String line : lines) {
            String cleaned = line.trim();
            // Remove bullet points, numbers, etc.
            cleaned = cleaned.replaceFirst("^[-•*\\d.]+\\s*", "");

            if (!cleaned.isEmpty() && !cleaned.equalsIgnoreCase("NONE")) {
                products.add(cleaned);
            }
        }

        return products;
    }

    /**
     * Convert mixed Tamil/transliterated text to clean English transliteration using Gemini
     * Example: "thakakalaி vengkayama poonatu" -> "takkaali vengayama poonadu"
     */
    public String transliterateTamilToEnglish(String mixedText) {
        if (!geminiConfig.getEnabled() || mixedText == null || mixedText.trim().isEmpty()) {
            return mixedText;
        }

        try {
            log.info("🔄 Transliterating Tamil to English: {}", mixedText);

            String prompt = "Convert this text to proper English transliteration of Tamil words. " +
                    "If text contains Tamil script, convert to English phonetic spelling. " +
                    "If text is already English or mixed, clean it up to proper transliteration. " +
                    "Return ONLY the transliterated text, nothing else.\n" +
                    "Text to convert: \"" + mixedText + "\"";

            String aiResponse = callGeminiAPI(prompt).trim();

            if (aiResponse != null && !aiResponse.isEmpty()) {
                log.info("✅ Transliterated result: {}", aiResponse);
                return aiResponse;
            }

            return mixedText; // Return original if conversion fails

        } catch (Exception e) {
            log.error("⚠️ Error transliterating text: {}", e.getMessage());
            return mixedText; // Return original on error
        }
    }

    /**
     * General-purpose text generation using Gemini AI.
     * Calls Gemini with the given prompt and returns the raw text response.
     */
    public String generateText(String prompt) {
        if (!geminiConfig.getEnabled()) {
            throw new IllegalStateException("Gemini AI is not enabled");
        }

        try {
            log.info("Generating text with Gemini AI");
            String response = callGeminiAPI(prompt);
            if (response != null && !response.trim().isEmpty()) {
                return response.trim();
            }
            throw new RuntimeException("Empty response from Gemini API");
        } catch (Exception e) {
            log.error("Error generating text with Gemini: {}", e.getMessage());
            throw new RuntimeException("Failed to generate text with Gemini", e);
        }
    }

    /**
     * Call Gemini Vision API with an image for analysis (e.g., reading handwritten shopping lists).
     * Uses the same round-robin key rotation as text API.
     */
    public String callGeminiVisionAPI(String prompt, byte[] imageBytes, String mimeType) {
        if (!geminiConfig.getEnabled()) {
            throw new IllegalStateException("Gemini AI is not enabled");
        }

        String currentApiKey = getNextApiKey();

        try {
            String url = String.format("%s/%s:generateContent?key=%s",
                geminiConfig.getApiUrl(), geminiConfig.getModel(), currentApiKey);

            // Encode image to base64
            String base64Image = java.util.Base64.getEncoder().encodeToString(imageBytes);

            // Build multimodal request body with text + image
            Map<String, Object> requestBody = Map.of(
                "contents", List.of(
                    Map.of("parts", List.of(
                        Map.of("text", prompt),
                        Map.of("inlineData", Map.of(
                            "mimeType", mimeType,
                            "data", base64Image
                        ))
                    ))
                )
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            log.info("Calling Gemini Vision API");

            ResponseEntity<String> response = restTemplate.exchange(
                url, HttpMethod.POST, entity, String.class
            );

            JsonNode root = objectMapper.readTree(response.getBody());
            JsonNode candidates = root.path("candidates");

            if (candidates.isArray() && candidates.size() > 0) {
                JsonNode content = candidates.get(0).path("content").path("parts");
                if (content.isArray() && content.size() > 0) {
                    String responseText = content.get(0).path("text").asText();
                    log.info("Gemini Vision API response received");
                    return responseText;
                }
            }

            log.warn("No valid response from Gemini Vision API");
            return "[]";

        } catch (RestClientException e) {
            log.error("Gemini Vision API timeout: {}", e.getMessage());
            throw new RuntimeException("Gemini Vision API timeout", e);
        } catch (Exception e) {
            log.error("Error calling Gemini Vision API: {}", e.getMessage());
            throw new RuntimeException("Failed to call Gemini Vision API", e);
        }
    }

    /**
     * Check if Gemini AI is enabled
     */
    public boolean isEnabled() {
        return geminiConfig.getEnabled();
    }

    /**
     * Get API key configuration info for monitoring
     */
    public Map<String, Object> getApiKeyInfo() {
        List<String> apiKeys = geminiConfig.getApiKeys();
        return Map.of(
            "totalKeys", apiKeys != null ? apiKeys.size() : 0,
            "currentKeyIndex", keyRotationCounter.get() % (apiKeys != null && !apiKeys.isEmpty() ? apiKeys.size() : 1),
            "perKeyRpm", geminiConfig.getRateLimit() != null ? geminiConfig.getRateLimit().getPerKeyRpm() : 15,
            "totalRpm", geminiConfig.getRateLimit() != null ? geminiConfig.getRateLimit().getTotalRpm() : 60,
            "enabled", geminiConfig.getEnabled()
        );
    }
}
