package com.shopmanagement.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.shopmanagement.entity.WhatsAppIncomingMessage;
import com.shopmanagement.repository.WhatsAppIncomingMessageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;

/**
 * Processes inbound WhatsApp webhook payloads from the Meta Cloud API:
 * stores each customer message (order text) for the admin inbox and sends a
 * one-time acknowledgement reply inside the free 24h service window.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WhatsAppInboundService {

    private static final String AUTO_REPLY =
            "*Namma Ooru Delivery* 🛵\n"
            + "வணக்கம்! உங்கள் ஆர்டர் கிடைத்தது ✅\n"
            + "Your message is received. We will confirm your order shortly.";

    private final WhatsAppIncomingMessageRepository repository;
    private final WhatsAppNotificationService whatsAppNotificationService;

    /**
     * Walk the webhook payload (entry[].changes[].value.messages[]) and persist
     * every new customer message. Status/delivery-receipt callbacks (value.statuses)
     * carry no customer content and are ignored. Never throws: the webhook must
     * always answer 200 or Meta keeps retrying the same payload.
     */
    public void processWebhook(JsonNode root) {
        try {
            for (JsonNode entry : root.path("entry")) {
                for (JsonNode change : entry.path("changes")) {
                    JsonNode value = change.path("value");
                    if (!value.has("messages")) {
                        continue; // statuses / template quality callbacks etc.
                    }
                    String profileName = value.path("contacts").path(0).path("profile").path("name").asText(null);
                    for (JsonNode message : value.path("messages")) {
                        handleMessage(message, profileName);
                    }
                }
            }
        } catch (Exception e) {
            log.error("Failed processing WhatsApp webhook payload", e);
        }
    }

    private void handleMessage(JsonNode message, String profileName) {
        String waMessageId = message.path("id").asText(null);
        String from = message.path("from").asText(null);
        if (waMessageId == null || from == null) {
            return;
        }
        if (repository.existsByWaMessageId(waMessageId)) {
            return; // Meta retried a payload we already stored
        }

        String type = message.path("type").asText("unknown");
        String body = extractBody(message, type);

        LocalDateTime receivedAt = null;
        long epochSeconds = message.path("timestamp").asLong(0);
        if (epochSeconds > 0) {
            receivedAt = LocalDateTime.ofInstant(Instant.ofEpochSecond(epochSeconds), ZoneId.systemDefault());
        }

        WhatsAppIncomingMessage saved = repository.save(WhatsAppIncomingMessage.builder()
                .waMessageId(waMessageId)
                .fromNumber(from)
                .profileName(profileName)
                .messageType(type)
                .body(body)
                .receivedAt(receivedAt)
                .build());
        log.info("Stored incoming WhatsApp {} message {} from {}", type, saved.getId(), from);

        // Acknowledge so the customer knows the order reached us. Failure here is
        // non-fatal — the message is already in the inbox for staff to handle.
        try {
            boolean replied = whatsAppNotificationService.sendTextMessage(from, AUTO_REPLY);
            if (replied) {
                saved.setAutoReplied(true);
                repository.save(saved);
            }
        } catch (Exception e) {
            log.error("Auto-reply to {} failed", from, e);
        }
    }

    /** Human-readable content for the admin inbox, per Meta message type. */
    private String extractBody(JsonNode message, String type) {
        switch (type) {
            case "text":
                return message.path("text").path("body").asText(null);
            case "button":
                return message.path("button").path("text").asText(null);
            case "interactive":
                JsonNode interactive = message.path("interactive");
                String replyTitle = interactive.path("button_reply").path("title").asText(null);
                if (replyTitle == null) {
                    replyTitle = interactive.path("list_reply").path("title").asText(null);
                }
                return replyTitle;
            case "image":
            case "video":
            case "document":
            case "audio":
                String caption = message.path(type).path("caption").asText(null);
                return caption != null ? caption : "[" + type + "]";
            case "location":
                JsonNode loc = message.path("location");
                return "location: " + loc.path("latitude").asText() + "," + loc.path("longitude").asText();
            default:
                return "[" + type + "]";
        }
    }
}
