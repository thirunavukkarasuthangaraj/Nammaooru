package com.shopmanagement.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;
import java.util.List;
import java.util.Map;

/**
 * Groq AI text generation (OpenAI-compatible chat completions API).
 * Used as a FALLBACK when Gemini fails or its free-tier quota is exhausted —
 * Groq's free tier (~14.4k requests/day) far exceeds Gemini's current one.
 */
@Service
@Slf4j
public class GroqService {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${groq.enabled:true}")
    private boolean enabled;

    @Value("${groq.api-key:}")
    private String apiKey;

    @Value("${groq.model:openai/gpt-oss-20b}")
    private String model;

    @Value("${groq.api-url:https://api.groq.com/openai/v1/chat/completions}")
    private String apiUrl;

    @Value("${groq.whisper-model:whisper-large-v3-turbo}")
    private String whisperModel;

    @Value("${groq.audio-api-url:https://api.groq.com/openai/v1/audio/transcriptions}")
    private String audioApiUrl;

    public GroqService(RestTemplateBuilder restTemplateBuilder, ObjectMapper objectMapper) {
        // Same timeout convention as GeminiSearchService
        this.restTemplate = restTemplateBuilder
                .setConnectTimeout(Duration.ofSeconds(10))
                .setReadTimeout(Duration.ofSeconds(15))
                .build();
        this.objectMapper = objectMapper;
    }

    public boolean isEnabled() {
        return enabled && apiKey != null && !apiKey.isBlank();
    }

    /**
     * General-purpose text generation using Groq. Same contract as
     * GeminiSearchService.generateText: returns trimmed text, throws on failure.
     */
    public String generateText(String prompt) {
        if (!isEnabled()) {
            throw new IllegalStateException("Groq is not enabled or has no API key");
        }

        try {
            Map<String, Object> requestBody = Map.of(
                    "model", model,
                    "messages", List.of(Map.of("role", "user", "content", prompt)),
                    // Deterministic output for search/extraction, same as the Gemini config
                    "temperature", 0.1,
                    "max_tokens", 1024
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            ResponseEntity<String> response = restTemplate.exchange(
                    apiUrl, HttpMethod.POST, entity, String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            String text = root.path("choices").path(0).path("message").path("content").asText();
            if (text != null && !text.trim().isEmpty()) {
                log.debug("Groq API response received");
                return text.trim();
            }
            throw new RuntimeException("Empty response from Groq API");
        } catch (Exception e) {
            log.error("Error calling Groq API: {}", e.getMessage());
            throw new RuntimeException("Failed to generate text with Groq: " + e.getMessage(), e);
        }
    }

    /**
     * Audio transcription via Groq's Whisper-compatible endpoint. Used as a FALLBACK
     * when Gemini's audio understanding fails (e.g. Gemini quota/key issue) — same
     * fallback role as generateText plays for text prompts.
     */
    public String transcribeAudio(byte[] audioBytes, String filename) {
        if (!isEnabled()) {
            throw new IllegalStateException("Groq is not enabled or has no API key");
        }

        try {
            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", new ByteArrayResource(audioBytes) {
                @Override
                public String getFilename() {
                    return filename != null && !filename.isBlank() ? filename : "audio.webm";
                }
            });
            body.add("model", whisperModel);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);
            headers.setBearerAuth(apiKey);

            HttpEntity<MultiValueMap<String, Object>> entity = new HttpEntity<>(body, headers);

            ResponseEntity<String> response = restTemplate.exchange(
                    audioApiUrl, HttpMethod.POST, entity, String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            String text = root.path("text").asText();
            if (text != null && !text.trim().isEmpty()) {
                log.debug("Groq audio transcription received");
                return text.trim();
            }
            throw new RuntimeException("Empty transcription from Groq API");
        } catch (Exception e) {
            log.error("Error calling Groq audio transcription API: {}", e.getMessage());
            throw new RuntimeException("Failed to transcribe audio with Groq: " + e.getMessage(), e);
        }
    }
}
