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
        // Configure RestTemplate with 10 second timeout for both connection and read
        this.restTemplate = restTemplateBuilder
                .setConnectTimeout(Duration.ofSeconds(10))
                .setReadTimeout(Duration.ofSeconds(10))
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

            // Build request body
            Map<String, Object> requestBody = Map.of(
                "contents", List.of(
                    Map.of("parts", List.of(
                        Map.of("text", prompt)
                    ))
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
