package com.shopmanagement.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shopmanagement.service.WhatsAppInboundService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;

/**
 * Meta WhatsApp Cloud API webhook (customer -> business messages).
 * Under /api/webhooks/** which is permitAll in SecurityConfig; authenticity is
 * enforced by the verify-token handshake (GET) and the X-Hub-Signature-256
 * HMAC check (POST) instead of a session.
 *
 * Meta app dashboard -> WhatsApp -> Configuration:
 *   Callback URL:  https://<domain>/api/webhooks/whatsapp
 *   Verify token:  value of whatsapp.meta.webhook-verify-token
 *   Subscribe to:  messages
 */
@RestController
@RequestMapping("/api/webhooks/whatsapp")
@RequiredArgsConstructor
@Slf4j
public class WhatsAppWebhookController {

    private final WhatsAppInboundService inboundService;
    private final ObjectMapper objectMapper;

    @Value("${whatsapp.meta.webhook-verify-token:}")
    private String verifyToken;

    @Value("${whatsapp.meta.app-secret:}")
    private String appSecret;

    /** Meta's one-time subscription handshake. */
    @GetMapping
    public ResponseEntity<String> verify(
            @RequestParam(name = "hub.mode", required = false) String mode,
            @RequestParam(name = "hub.verify_token", required = false) String token,
            @RequestParam(name = "hub.challenge", required = false) String challenge) {
        if ("subscribe".equals(mode) && verifyToken != null && !verifyToken.isBlank()
                && verifyToken.equals(token)) {
            log.info("WhatsApp webhook verified by Meta");
            return ResponseEntity.ok(challenge);
        }
        log.warn("WhatsApp webhook verification rejected (mode={}, token match={})",
                mode, verifyToken != null && verifyToken.equals(token));
        return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
    }

    /**
     * Message delivery. Raw body is needed for the signature check, so bind it
     * as String and parse manually. Always answers 200 after a valid signature —
     * a non-2xx makes Meta retry the same payload for days.
     */
    @PostMapping
    public ResponseEntity<Void> receive(
            @RequestBody String rawBody,
            @RequestHeader(name = "X-Hub-Signature-256", required = false) String signature) {
        if (appSecret != null && !appSecret.isBlank() && !isSignatureValid(rawBody, signature)) {
            log.warn("WhatsApp webhook rejected: bad X-Hub-Signature-256");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        try {
            JsonNode root = objectMapper.readTree(rawBody);
            inboundService.processWebhook(root);
        } catch (Exception e) {
            log.error("Unparseable WhatsApp webhook payload", e);
        }
        return ResponseEntity.ok().build();
    }

    /** X-Hub-Signature-256 = "sha256=" + HMAC-SHA256(rawBody, appSecret). */
    private boolean isSignatureValid(String rawBody, String signature) {
        if (signature == null || !signature.startsWith("sha256=")) {
            return false;
        }
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(appSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] hash = mac.doFinal(rawBody.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder("sha256=");
            for (byte b : hash) {
                hex.append(String.format("%02x", b));
            }
            return java.security.MessageDigest.isEqual(
                    hex.toString().getBytes(StandardCharsets.UTF_8),
                    signature.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            log.error("Failed computing webhook signature", e);
            return false;
        }
    }
}
