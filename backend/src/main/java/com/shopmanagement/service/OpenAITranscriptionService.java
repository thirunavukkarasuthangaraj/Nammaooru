package com.shopmanagement.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shopmanagement.config.OpenAIConfig;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.UUID;

/**
 * OpenAI Whisper API for audio transcription.
 * Excellent multilingual support including Tamil.
 * Cost: ~$0.006/minute.
 */
@Slf4j
@Service
public class OpenAITranscriptionService {

    private final OpenAIConfig openAIConfig;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient;

    @Autowired
    public OpenAITranscriptionService(OpenAIConfig openAIConfig) {
        this.openAIConfig = openAIConfig;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
    }

    public boolean isEnabled() {
        return Boolean.TRUE.equals(openAIConfig.getEnabled())
                && openAIConfig.getApiKey() != null
                && !openAIConfig.getApiKey().isBlank();
    }

    /**
     * Transcribe audio using OpenAI Whisper API.
     * Whisper automatically detects language (Tamil, English, etc.)
     *
     * @param audioBytes raw audio file bytes
     * @param mimeType   audio MIME type (audio/m4a, audio/wav, etc.)
     * @return transcribed text, or null if failed
     */
    public String transcribeAudio(byte[] audioBytes, String mimeType) {
        if (!isEnabled()) {
            log.warn("OpenAI transcription called but not enabled");
            return null;
        }

        try {
            // Determine file extension from mime type
            String extension = getExtension(mimeType);
            String filename = "audio_" + UUID.randomUUID().toString().substring(0, 8) + extension;

            // Build multipart form data manually for java.net.http
            String boundary = "----WhisperBoundary" + System.currentTimeMillis();

            byte[] requestBody = buildMultipartBody(boundary, audioBytes, filename, mimeType);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(openAIConfig.getApiUrl()))
                    .header("Authorization", "Bearer " + openAIConfig.getApiKey())
                    .header("Content-Type", "multipart/form-data; boundary=" + boundary)
                    .timeout(Duration.ofSeconds(30))
                    .POST(HttpRequest.BodyPublishers.ofByteArray(requestBody))
                    .build();

            log.info("Calling OpenAI Whisper API: model={}, audioSize={}KB",
                    openAIConfig.getModel(), audioBytes.length / 1024);

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() == 200) {
                JsonNode root = objectMapper.readTree(response.body());
                String text = root.path("text").asText("").trim();
                log.info("OpenAI Whisper transcription: '{}'", text);
                return text.isEmpty() ? null : text;
            } else {
                log.error("OpenAI Whisper API error: status={}, body={}", response.statusCode(), response.body());
                return null;
            }

        } catch (IOException | InterruptedException e) {
            log.error("OpenAI Whisper transcription error: {}", e.getMessage());
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            return null;
        }
    }

    /**
     * Build multipart/form-data request body with audio file + model field
     */
    private byte[] buildMultipartBody(String boundary, byte[] audioBytes, String filename, String mimeType) throws IOException {
        var baos = new java.io.ByteArrayOutputStream();

        // Add model field
        baos.write(("--" + boundary + "\r\n").getBytes());
        baos.write("Content-Disposition: form-data; name=\"model\"\r\n\r\n".getBytes());
        baos.write((openAIConfig.getModel() + "\r\n").getBytes());

        // Add language hint (optional — helps Whisper focus on Tamil)
        baos.write(("--" + boundary + "\r\n").getBytes());
        baos.write("Content-Disposition: form-data; name=\"language\"\r\n\r\n".getBytes());
        baos.write("ta\r\n".getBytes());

        // Add prompt hint to improve accuracy
        baos.write(("--" + boundary + "\r\n").getBytes());
        baos.write("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".getBytes());
        baos.write("This is a grocery shopping order in Tamil or Tanglish. Common items: onion, tomato, rice, garlic, coconut oil, dal, sugar, salt, milk.\r\n".getBytes());

        // Add audio file
        baos.write(("--" + boundary + "\r\n").getBytes());
        baos.write(("Content-Disposition: form-data; name=\"file\"; filename=\"" + filename + "\"\r\n").getBytes());
        baos.write(("Content-Type: " + mimeType + "\r\n\r\n").getBytes());
        baos.write(audioBytes);
        baos.write("\r\n".getBytes());

        // End boundary
        baos.write(("--" + boundary + "--\r\n").getBytes());

        return baos.toByteArray();
    }

    private String getExtension(String mimeType) {
        if (mimeType == null) return ".m4a";
        return switch (mimeType.toLowerCase()) {
            case "audio/wav", "audio/wave", "audio/x-wav" -> ".wav";
            case "audio/mp3", "audio/mpeg" -> ".mp3";
            case "audio/ogg", "audio/ogg; codecs=opus" -> ".ogg";
            case "audio/webm" -> ".webm";
            case "audio/flac" -> ".flac";
            default -> ".m4a";
        };
    }
}
