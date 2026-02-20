package com.shopmanagement.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shopmanagement.config.GeminiConfig;
import com.shopmanagement.exception.ContentModerationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.time.Duration;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;

@Slf4j
@Service
public class ImageContentModerationService {

    private final GeminiConfig geminiConfig;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final AtomicInteger keyRotationCounter = new AtomicInteger(0);

    @Value("${content.moderation.enabled:true}")
    private boolean moderationEnabled;

    @Value("${content.moderation.timeout-seconds:8}")
    private int timeoutSeconds;

    @Value("${content.moderation.fail-open:true}")
    private boolean failOpen;

    @Value("${content.moderation.max-image-size-bytes:5242880}")
    private long maxImageSizeForModeration;

    private static final Set<String> IMAGE_CONTENT_TYPES = Set.of(
        "image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"
    );

    private static final String MODERATION_PROMPT =
        "You are a content moderation system. Analyze this image and determine if it contains ANY of the following:\n" +
        "- Nudity or sexually explicit content\n" +
        "- Sexually suggestive content\n" +
        "- Graphic violence or gore\n" +
        "- Hate symbols or extremist imagery\n" +
        "- Drug use or paraphernalia\n" +
        "- Weapons pointed at people\n\n" +
        "Respond with EXACTLY one word:\n" +
        "- SAFE if the image is appropriate for a public marketplace\n" +
        "- UNSAFE if the image contains any of the above\n\n" +
        "Response:";

    public ImageContentModerationService(GeminiConfig geminiConfig, RestTemplateBuilder restTemplateBuilder) {
        this.geminiConfig = geminiConfig;
        this.restTemplate = restTemplateBuilder
                .setConnectTimeout(Duration.ofSeconds(5))
                .setReadTimeout(Duration.ofSeconds(10))
                .build();
    }

    /**
     * Validate image content for appropriateness.
     * Throws ContentModerationException if image is flagged as inappropriate.
     * Skips non-image files and files exceeding size limit for moderation.
     */
    public void validateImageContent(MultipartFile file) {
        if (!moderationEnabled) {
            log.debug("Content moderation is disabled, skipping check");
            return;
        }

        if (!isImageFile(file)) {
            log.debug("Skipping moderation for non-image file: {}", file.getContentType());
            return;
        }

        if (file.getSize() > maxImageSizeForModeration) {
            log.warn("Image size {} bytes exceeds moderation limit of {} bytes",
                    file.getSize(), maxImageSizeForModeration);
            throw new ContentModerationException(
                "Image size exceeds 5MB limit. Please upload a smaller image.");
        }

        if (!geminiConfig.getEnabled()) {
            log.debug("Gemini AI is disabled, skipping content moderation");
            return;
        }

        try {
            log.info("Content moderation check - file: {}, size: {} bytes",
                    file.getOriginalFilename(), file.getSize());

            String base64Image = Base64.getEncoder().encodeToString(file.getBytes());
            String contentType = file.getContentType() != null ? file.getContentType() : "image/jpeg";

            String verdict = callGeminiVisionAPI(base64Image, contentType);

            if ("UNSAFE".equalsIgnoreCase(verdict.trim())) {
                log.warn("Content moderation BLOCKED image: {}", file.getOriginalFilename());
                throw new ContentModerationException(
                    "Image contains inappropriate content and cannot be uploaded. " +
                    "Please upload an appropriate image suitable for a public marketplace.");
            }

            log.info("Content moderation PASSED for: {}", file.getOriginalFilename());

        } catch (ContentModerationException e) {
            throw e; // Re-throw moderation failures
        } catch (Exception e) {
            log.error("Content moderation error: {}", e.getMessage());
            if (failOpen) {
                log.warn("Fail-open enabled: allowing upload despite moderation error");
            } else {
                throw new ContentModerationException(
                    "Unable to verify image content. Please try again later.", e);
            }
        }
    }

    private boolean isImageFile(MultipartFile file) {
        String contentType = file.getContentType();
        if (contentType != null && IMAGE_CONTENT_TYPES.contains(contentType.toLowerCase())) {
            return true;
        }
        // Fallback: check file extension
        String filename = file.getOriginalFilename();
        if (filename != null) {
            String lower = filename.toLowerCase();
            return lower.endsWith(".jpg") || lower.endsWith(".jpeg") ||
                   lower.endsWith(".png") || lower.endsWith(".gif") ||
                   lower.endsWith(".webp");
        }
        return false;
    }

    private String getNextApiKey() {
        List<String> apiKeys = geminiConfig.getApiKeys();
        if (apiKeys == null || apiKeys.isEmpty()) {
            throw new IllegalStateException("No Gemini API keys configured");
        }
        int index = keyRotationCounter.getAndIncrement() % apiKeys.size();
        return apiKeys.get(index);
    }

    private String callGeminiVisionAPI(String base64Image, String mimeType) {
        String apiKey = getNextApiKey();
        String url = String.format("%s/%s:generateContent?key=%s",
                geminiConfig.getApiUrl(), geminiConfig.getModel(), apiKey);

        // Build multimodal request: text prompt + inline image
        Map<String, Object> textPart = Map.of("text", MODERATION_PROMPT);
        Map<String, Object> imagePart = Map.of(
            "inline_data", Map.of(
                "mime_type", mimeType,
                "data", base64Image
            )
        );

        Map<String, Object> requestBody = Map.of(
            "contents", List.of(
                Map.of("parts", List.of(textPart, imagePart))
            ),
            "safetySettings", List.of(
                Map.of("category", "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold", "BLOCK_NONE"),
                Map.of("category", "HARM_CATEGORY_HATE_SPEECH", "threshold", "BLOCK_NONE"),
                Map.of("category", "HARM_CATEGORY_HARASSMENT", "threshold", "BLOCK_NONE"),
                Map.of("category", "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold", "BLOCK_NONE")
            ),
            "generationConfig", Map.of(
                "maxOutputTokens", 10,
                "temperature", 0.0
            )
        );

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        ResponseEntity<String> response = restTemplate.exchange(
                url, HttpMethod.POST, entity, String.class);

        return parseVerdictFromResponse(response.getBody());
    }

    private String parseVerdictFromResponse(String responseBody) {
        try {
            JsonNode root = objectMapper.readTree(responseBody);

            // Check if Gemini itself blocked the content due to safety
            // This happens for highly explicit images even with BLOCK_NONE
            JsonNode promptFeedback = root.path("promptFeedback");
            if (promptFeedback.has("blockReason")) {
                String blockReason = promptFeedback.path("blockReason").asText();
                log.warn("Gemini blocked image due to safety: {}", blockReason);
                return "UNSAFE";
            }

            JsonNode candidates = root.path("candidates");
            if (candidates.isArray() && !candidates.isEmpty()) {
                // Check if candidate was stopped due to safety
                String finishReason = candidates.get(0).path("finishReason").asText("");
                if ("SAFETY".equalsIgnoreCase(finishReason)) {
                    log.warn("Gemini flagged image with finishReason=SAFETY");
                    return "UNSAFE";
                }

                JsonNode parts = candidates.get(0).path("content").path("parts");
                if (parts.isArray() && !parts.isEmpty()) {
                    String text = parts.get(0).path("text").asText().trim();
                    log.debug("Gemini moderation verdict: {}", text);
                    if (text.toUpperCase().contains("UNSAFE")) {
                        return "UNSAFE";
                    }
                    return "SAFE";
                }
            }

            // No candidates and no block reason — unexpected response
            log.warn("Could not parse Gemini moderation response, defaulting to SAFE");
            return "SAFE";
        } catch (Exception e) {
            log.error("Error parsing Gemini moderation response: {}", e.getMessage());
            throw new RuntimeException("Failed to parse moderation response", e);
        }
    }
}
