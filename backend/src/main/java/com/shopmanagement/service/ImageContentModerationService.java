package com.shopmanagement.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shopmanagement.config.GeminiConfig;
import com.shopmanagement.exception.ContentModerationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.time.Duration;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Image content moderation service with multiple provider support.
 * Provider is controlled via admin setting: content.moderation.provider
 * Supported values: OFF, NUDENET, GEMINI
 */
@Slf4j
@Service
public class ImageContentModerationService {

    private final GeminiConfig geminiConfig;
    private final SettingService settingService;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final AtomicInteger keyRotationCounter = new AtomicInteger(0);

    private static final long MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB

    private static final Set<String> IMAGE_CONTENT_TYPES = Set.of(
        "image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"
    );

    // NudeNet unsafe labels
    private static final Set<String> NUDENET_UNSAFE_LABELS = Set.of(
        "FEMALE_BREAST_EXPOSED", "FEMALE_GENITALIA_EXPOSED",
        "MALE_GENITALIA_EXPOSED", "BUTTOCKS_EXPOSED",
        "ANUS_EXPOSED", "BELLY_EXPOSED"
    );

    private static final String GEMINI_MODERATION_PROMPT =
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

    public ImageContentModerationService(GeminiConfig geminiConfig,
                                          SettingService settingService,
                                          RestTemplateBuilder restTemplateBuilder) {
        this.geminiConfig = geminiConfig;
        this.settingService = settingService;
        this.restTemplate = restTemplateBuilder
                .setConnectTimeout(Duration.ofSeconds(5))
                .setReadTimeout(Duration.ofSeconds(10))
                .build();
    }

    /**
     * Validate image content for appropriateness.
     * Provider is read from admin settings (content.moderation.provider).
     * Throws ContentModerationException if image is flagged as inappropriate.
     */
    public void validateImageContent(MultipartFile file) {
        String provider = getProvider();

        if ("OFF".equalsIgnoreCase(provider)) {
            log.debug("Content moderation is OFF, skipping check");
            return;
        }

        if (!isImageFile(file)) {
            log.debug("Skipping moderation for non-image file: {}", file.getContentType());
            return;
        }

        if (file.getSize() > MAX_IMAGE_SIZE) {
            throw new ContentModerationException(
                "Image size exceeds 5MB limit. Please upload a smaller image.");
        }

        try {
            log.info("Content moderation [{}] - file: {}, size: {} bytes",
                    provider, file.getOriginalFilename(), file.getSize());

            boolean isUnsafe;
            if ("NUDENET".equalsIgnoreCase(provider)) {
                isUnsafe = checkWithNudeNet(file);
            } else if ("GEMINI".equalsIgnoreCase(provider)) {
                isUnsafe = checkWithGemini(file);
            } else {
                log.warn("Unknown moderation provider '{}', skipping", provider);
                return;
            }

            if (isUnsafe) {
                log.warn("Content moderation [{}] BLOCKED image: {}", provider, file.getOriginalFilename());
                throw new ContentModerationException(
                    "Image contains inappropriate content and cannot be uploaded. " +
                    "Please upload an appropriate image suitable for a public marketplace.");
            }

            log.info("Content moderation [{}] PASSED for: {}", provider, file.getOriginalFilename());

        } catch (ContentModerationException e) {
            throw e;
        } catch (Exception e) {
            log.error("Content moderation [{}] error: {}", provider, e.getMessage());
            // Fail-open: allow upload if moderation service is down
            log.warn("Moderation service error, allowing upload (fail-open)");
        }
    }

    private String getProvider() {
        try {
            return settingService.getSettingValue("content.moderation.provider", "OFF");
        } catch (Exception e) {
            return "OFF";
        }
    }

    private double getThreshold() {
        try {
            return Double.parseDouble(settingService.getSettingValue("content.moderation.threshold", "0.6"));
        } catch (Exception e) {
            return 0.6;
        }
    }

    private String getNudeNetUrl() {
        try {
            return settingService.getSettingValue("content.moderation.nudenet.url", "http://localhost:8085/classify");
        } catch (Exception e) {
            return "http://localhost:8085/classify";
        }
    }

    // ==================== NudeNet Provider ====================

    /**
     * Check image using NudeNet classifier (open source, free).
     * NudeNet runs as a Docker container: docker run -p 8085:8080 notaitech/nudenet:classifier
     * API: POST /classify with multipart file
     * Response: {"predictions": {"file": {"unsafe": 0.95, "safe": 0.05}}}
     */
    private boolean checkWithNudeNet(MultipartFile file) throws Exception {
        String nudeNetUrl = getNudeNetUrl();
        double threshold = getThreshold();

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);

        // Build multipart request
        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("file", new ByteArrayResource(file.getBytes()) {
            @Override
            public String getFilename() {
                return file.getOriginalFilename() != null ? file.getOriginalFilename() : "image.jpg";
            }
        });

        HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

        ResponseEntity<String> response = restTemplate.exchange(
                nudeNetUrl, HttpMethod.POST, requestEntity, String.class);

        return parseNudeNetResponse(response.getBody(), threshold);
    }

    private boolean parseNudeNetResponse(String responseBody, double threshold) {
        try {
            JsonNode root = objectMapper.readTree(responseBody);

            // NudeNet v2 response format: {"predictions": [{"class": "SAFE", "score": 0.95},...]}
            // or: {"output": [{"class": "FEMALE_BREAST_EXPOSED", "score": 0.8},...]}
            // Handle both formats

            // Format 1: Simple predictions with unsafe/safe scores
            JsonNode predictions = root.path("predictions");
            if (predictions.isObject()) {
                // {"predictions": {"<filename>": {"unsafe": 0.95, "safe": 0.05}}}
                Iterator<JsonNode> fileNodes = predictions.elements();
                while (fileNodes.hasNext()) {
                    JsonNode fileNode = fileNodes.next();
                    double unsafeScore = fileNode.path("unsafe").asDouble(0.0);
                    log.info("NudeNet unsafe score: {} (threshold: {})", unsafeScore, threshold);
                    if (unsafeScore >= threshold) {
                        return true; // UNSAFE
                    }
                }
                return false;
            }

            // Format 2: Detailed label predictions
            JsonNode output = root.has("output") ? root.path("output") : root.path("predictions");
            if (output.isArray()) {
                for (JsonNode prediction : output) {
                    String label = prediction.path("class").asText(prediction.path("label").asText(""));
                    double score = prediction.path("score").asDouble(prediction.path("probability").asDouble(0.0));
                    if (NUDENET_UNSAFE_LABELS.contains(label.toUpperCase()) && score >= threshold) {
                        log.info("NudeNet flagged: {} = {} (threshold: {})", label, score, threshold);
                        return true; // UNSAFE
                    }
                }
                return false;
            }

            log.warn("Could not parse NudeNet response, defaulting to SAFE");
            return false;
        } catch (Exception e) {
            log.error("Error parsing NudeNet response: {}", e.getMessage());
            throw new RuntimeException("Failed to parse NudeNet response", e);
        }
    }

    // ==================== Gemini Provider ====================

    private boolean checkWithGemini(MultipartFile file) throws Exception {
        if (!geminiConfig.getEnabled()) {
            log.warn("Gemini is disabled, skipping moderation");
            return false;
        }

        String base64Image = Base64.getEncoder().encodeToString(file.getBytes());
        String contentType = file.getContentType() != null ? file.getContentType() : "image/jpeg";
        String verdict = callGeminiVisionAPI(base64Image, contentType);
        return "UNSAFE".equalsIgnoreCase(verdict.trim());
    }

    private String callGeminiVisionAPI(String base64Image, String mimeType) {
        String apiKey = getNextApiKey();
        String url = String.format("%s/%s:generateContent?key=%s",
                geminiConfig.getApiUrl(), geminiConfig.getModel(), apiKey);

        Map<String, Object> textPart = Map.of("text", GEMINI_MODERATION_PROMPT);
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

        return parseGeminiResponse(response.getBody());
    }

    private String getNextApiKey() {
        List<String> apiKeys = geminiConfig.getApiKeys();
        if (apiKeys == null || apiKeys.isEmpty()) {
            throw new IllegalStateException("No Gemini API keys configured");
        }
        int index = keyRotationCounter.getAndIncrement() % apiKeys.size();
        return apiKeys.get(index);
    }

    private String parseGeminiResponse(String responseBody) {
        try {
            JsonNode root = objectMapper.readTree(responseBody);

            JsonNode promptFeedback = root.path("promptFeedback");
            if (promptFeedback.has("blockReason")) {
                return "UNSAFE";
            }

            JsonNode candidates = root.path("candidates");
            if (candidates.isArray() && !candidates.isEmpty()) {
                String finishReason = candidates.get(0).path("finishReason").asText("");
                if ("SAFETY".equalsIgnoreCase(finishReason)) {
                    return "UNSAFE";
                }

                JsonNode parts = candidates.get(0).path("content").path("parts");
                if (parts.isArray() && !parts.isEmpty()) {
                    String text = parts.get(0).path("text").asText().trim();
                    if (text.toUpperCase().contains("UNSAFE")) {
                        return "UNSAFE";
                    }
                    return "SAFE";
                }
            }

            return "SAFE";
        } catch (Exception e) {
            log.error("Error parsing Gemini response: {}", e.getMessage());
            throw new RuntimeException("Failed to parse Gemini response", e);
        }
    }

    // ==================== Utilities ====================

    private boolean isImageFile(MultipartFile file) {
        String contentType = file.getContentType();
        if (contentType != null && IMAGE_CONTENT_TYPES.contains(contentType.toLowerCase())) {
            return true;
        }
        String filename = file.getOriginalFilename();
        if (filename != null) {
            String lower = filename.toLowerCase();
            return lower.endsWith(".jpg") || lower.endsWith(".jpeg") ||
                   lower.endsWith(".png") || lower.endsWith(".gif") ||
                   lower.endsWith(".webp");
        }
        return false;
    }
}
