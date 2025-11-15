package com.shopmanagement.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shopmanagement.config.GeminiConfig;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

@Slf4j
@Service
public class GeminiSearchService {

    private final GeminiConfig geminiConfig;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    // Round-robin counter for API key rotation
    private final AtomicInteger keyRotationCounter = new AtomicInteger(0);

    @Autowired
    public GeminiSearchService(GeminiConfig geminiConfig) {
        this.geminiConfig = geminiConfig;
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
        prompt.append("You are a smart product search assistant for a grocery delivery app in Tamil Nadu, India.\n\n");

        prompt.append("User's search query: \"").append(query).append("\"\n");
        prompt.append("(Query may be in Tamil script, Tamil transliteration in English, or English)\n\n");

        prompt.append("Available products (format: \"EnglishName | தமிழ்பெயர்\"):\n");
        for (int i = 0; i < Math.min(availableProducts.size(), 100); i++) {
            prompt.append((i+1)).append(". ").append(availableProducts.get(i)).append("\n");
        }

        prompt.append("\n=== IMPORTANT MATCHING RULES ===\n");
        prompt.append("1. Tamil Transliterations:\n");
        prompt.append("   - 'arisi', 'arasi', 'arasee' → அரிசி (rice)\n");
        prompt.append("   - 'sarkari', 'sarkarai', 'sakkarai' → சர்க்கரை (sugar)\n");
        prompt.append("   - 'pal', 'paal' → பால் (milk)\n");
        prompt.append("   - 'thakkali', 'tomato' → தக்காளி (tomato)\n");
        prompt.append("   - 'vengayam', 'onion' → வெங்காயம் (onion)\n\n");

        prompt.append("2. Product Type Matching:\n");
        prompt.append("   - If query is about rice/அரிசி, ONLY match rice products (பாஸ்மதி அரிசி, இட்லி அரிசி, etc.)\n");
        prompt.append("   - If query is about coffee, ONLY match coffee products (BRU, Nescafe, etc.)\n");
        prompt.append("   - DO NOT match unrelated products - be STRICT about product type\n\n");

        prompt.append("3. Matching Priority:\n");
        prompt.append("   a. Exact Tamil name match (அரிசி matches அரிசி)\n");
        prompt.append("   b. Tamil transliteration match (arisi/arasi matches அரிசி)\n");
        prompt.append("   c. English synonym match (rice matches அரிசி)\n");
        prompt.append("   d. Partial product name match (தக்காளி matches முழு தக்காளி)\n\n");

        prompt.append("4. Return Format:\n");
        prompt.append("   - Return ONLY products from the numbered list above\n");
        prompt.append("   - Return product names EXACTLY as shown (with | separator if present)\n");
        prompt.append("   - One product per line\n");
        prompt.append("   - If NO match found, return 'NONE'\n\n");

        prompt.append("Example:\n");
        prompt.append("Query: 'arisi' → Return: 'Basmati Rice | பாஸ்மதி அரிசி'\n");
        prompt.append("Query: 'coffee' → Return: 'BRU Coffee | பிரூ காபி'\n");
        prompt.append("Query: 'தக்காளி' → Return: 'Tomato | தக்காளி'\n\n");

        prompt.append("Your task: Find ALL products that match the query \"").append(query).append("\".\n");
        prompt.append("Remember: Be STRICT - only return products that are truly related to the query.");

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
