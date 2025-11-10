package com.shopmanagement.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class GeminiSearchService {

    @Value("${gemini.api-key}")
    private String apiKey;

    @Value("${gemini.model:gemini-1.5-flash}")
    private String modelName;

    @Value("${gemini.api-url:https://generativelanguage.googleapis.com/v1beta/models}")
    private String apiUrl;

    @Value("${gemini.enabled:true}")
    private Boolean geminiEnabled;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Use Gemini AI to enhance product search with Tamil + English understanding
     */
    public List<String> enhanceSearchQuery(String query, List<String> availableProducts) {
        if (!geminiEnabled || query == null || query.trim().isEmpty()) {
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
        prompt.append("You are a smart product search assistant for a grocery delivery app in India.\n\n");
        prompt.append("User's search query (may be in Tamil, English, or mixed): \"").append(query).append("\"\n\n");

        prompt.append("Available products in the shop:\n");
        for (int i = 0; i < Math.min(availableProducts.size(), 50); i++) {
            prompt.append("- ").append(availableProducts.get(i)).append("\n");
        }

        prompt.append("\nTask: Find all products that match the user's query. Consider:\n");
        prompt.append("1. Tamil and English synonyms (e.g., 'rice' = 'அரிசி', 'sugar' = 'சர்க்கரை')\n");
        prompt.append("2. Phonetic transliteration (e.g., 'sarkari' or 'sarkarai' = 'சர்க்கரை' = 'sugar', 'arisi' = 'அரிசி' = 'rice')\n");
        prompt.append("3. Product categories (e.g., 'breakfast items' includes 'idli batter', 'dosa batter')\n");
        prompt.append("4. Common variations (e.g., 'milk' matches 'Fresh Milk', 'Cow Milk', 'Buffalo Milk')\n");
        prompt.append("5. Partial matches (e.g., 'toma' matches 'Tomatoes')\n\n");

        prompt.append("Return ONLY the matching product names, one per line, exactly as they appear in the available products list.\n");
        prompt.append("If no matches found, return the word 'NONE'.");

        return prompt.toString();
    }

    /**
     * Call Gemini 1.5 Flash API using REST
     */
    private String callGeminiAPI(String prompt) {
        try {
            String url = String.format("%s/%s:generateContent?key=%s", apiUrl, modelName, apiKey);

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

            log.debug("Calling Gemini API: {}", url);

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
                    log.debug("Gemini API Response: {}", responseText);
                    return responseText;
                }
            }

            log.warn("No valid response from Gemini API");
            return "";

        } catch (Exception e) {
            log.error("Error calling Gemini API: {}", e.getMessage(), e);
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
        return geminiEnabled;
    }
}
