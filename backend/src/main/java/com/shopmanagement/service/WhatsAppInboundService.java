package com.shopmanagement.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.shopmanagement.entity.WhatsAppIncomingMessage;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.product.repository.ShopProductRepository;
import com.shopmanagement.repository.WhatsAppIncomingMessageRepository;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.repository.ShopRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Processes inbound WhatsApp webhook payloads from the Meta Cloud API:
 * stores each customer message (order text) for the admin inbox, and answers
 * inside the free 24h service window. Short one-line queries ("rice",
 * "2kg onion") get a tappable product-list reply from the shop catalog; the
 * customer's tap comes back as a list_reply and is stored as a confirmed
 * product order. Everything else gets the generic acknowledgement.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WhatsAppInboundService {

    private static final String AUTO_REPLY =
            "*Namma Ooru Delivery* 🛵\n"
            + "வணக்கம்! உங்கள் ஆர்டர் கிடைத்தது ✅\n"
            + "Your message is received. We will confirm your order shortly.";

    /** "2kg onion" / "rice 1kg" — quantity+unit anywhere in the line. */
    private static final Pattern QTY_PATTERN = Pattern.compile(
            "(\\d+(?:\\.\\d+)?)\\s*(kg|kgs|gm|g|gram|grams|l|lt|ltr|litre|liter|ml|pc|pcs|piece|pieces|pkt|packet|dozen)?",
            Pattern.CASE_INSENSITIVE);

    private final WhatsAppIncomingMessageRepository repository;
    private final WhatsAppNotificationService whatsAppNotificationService;
    private final ShopProductRepository shopProductRepository;
    private final ShopRepository shopRepository;

    /** Optional fixed shop for the order bot; when blank, the single active shop is used. */
    @Value("${whatsapp.order.shop-id:}")
    private String configuredShopId;

    /** Public base for /uploads/... product images (Meta fetches them from here). */
    @Value("${app.api.base-url:https://api.nammaoorudelivary.in}")
    private String apiBaseUrl;

    /**
     * Walk the webhook payload (entry[].changes[].value.messages[]) and persist
     * every new customer message. Status/delivery-receipt callbacks (value.statuses)
     * carry no customer content and are ignored. Never throws: the webhook must
     * always answer 200 or Meta keeps retrying the same payload.
     */
    @Transactional
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

        // A tap on our product list comes back as interactive/list_reply with the
        // row id we sent ("sp:{shopProductId}:q:{qty}") — store it as a confirmed
        // product order so staff can bill it without guessing.
        boolean isProductPick = "interactive".equals(type)
                && message.path("interactive").has("list_reply");
        if (isProductPick) {
            JsonNode reply = message.path("interactive").path("list_reply");
            String title = reply.path("title").asText("");
            int qty = parsePickedQty(reply.path("id").asText(""));
            body = "✔ ORDER: " + title + (qty > 1 ? " × " + qty : "");
        }

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

        // Reply inside the free 24h window. Failure here is non-fatal — the
        // message is already in the inbox for staff to handle.
        try {
            boolean replied;
            if (isProductPick) {
                replied = whatsAppNotificationService.sendTextMessage(from,
                        "*Namma Ooru Delivery* 🛵\n✔ " + body.replace("✔ ORDER: ", "")
                        + " சேர்க்கப்பட்டது!\nAdded to your order. We will confirm the total shortly.");
            } else {
                replied = trySuggestProducts(from, type, body)
                        || whatsAppNotificationService.sendTextMessage(from, AUTO_REPLY);
            }
            if (replied) {
                saved.setAutoReplied(true);
                repository.save(saved);
            }
        } catch (Exception e) {
            log.error("Auto-reply to {} failed", from, e);
        }
    }

    /**
     * For short single-line queries, reply with a tappable list of matching
     * products from the shop catalog. Returns false (caller sends the generic
     * acknowledgement) for multi-line lists, no keyword, or no matches.
     */
    private boolean trySuggestProducts(String from, String type, String body) {
        if (!"text".equals(type) || body == null || body.contains("\n")) {
            return false;
        }
        Long shopId = resolveShopId();
        if (shopId == null) {
            return false;
        }

        int qty = 1;
        String text = body.toLowerCase();
        Matcher m = QTY_PATTERN.matcher(text);
        if (m.find() && !m.group().isBlank()) {
            String unit = m.group(2) == null ? "" : m.group(2).toLowerCase();
            double n = Double.parseDouble(m.group(1));
            // grams/ml describe pack size, not count
            qty = List.of("g", "gm", "gram", "grams", "ml").contains(unit) ? 1 : Math.max(1, (int) Math.round(n));
            text = text.replace(m.group(), " ");
        }
        String keyword = text.replaceAll("\\b(order|please|pls|need|want|send|and|the|for|venum|vennum)\\b", " ")
                .replaceAll("[^\\p{L}0-9 ]", " ")
                .trim().replaceAll("\\s+", " ");
        if (keyword.length() < 3) {
            return false;
        }

        List<ShopProduct> products = shopProductRepository
                .searchAvailableByShopIdAndName(shopId, keyword, PageRequest.of(0, 10)).getContent();
        if (products.isEmpty() && keyword.contains(" ")) {
            // Multi-word keyword found nothing — retry with the first word alone
            products = shopProductRepository
                    .searchAvailableByShopIdAndName(shopId, keyword.split(" ")[0], PageRequest.of(0, 10)).getContent();
        }
        if (products.isEmpty()) {
            return false;
        }

        // Product photos first (top 3 with an image) so the customer sees what
        // they're choosing, then the tappable list to actually pick.
        int photosSent = 0;
        for (ShopProduct sp : products) {
            if (photosSent >= 3) break;
            String imageUrl = sp.getPrimaryShopImageUrl();
            if (imageUrl == null || imageUrl.isBlank()) continue;
            if (imageUrl.startsWith("/")) {
                imageUrl = apiBaseUrl + imageUrl;
            }
            String caption = sp.getDisplayName() + " — ₹" + sp.getPrice().stripTrailingZeros().toPlainString();
            if (whatsAppNotificationService.sendImageMessage(from, imageUrl, caption)) {
                photosSent++;
            }
        }

        List<Map<String, String>> rows = new ArrayList<>();
        for (ShopProduct sp : products) {
            String name = sp.getDisplayName();
            rows.add(Map.of(
                    "id", "sp:" + sp.getId() + ":q:" + qty,
                    "title", name,
                    "description", "₹" + sp.getPrice().stripTrailingZeros().toPlainString()
                            + (qty > 1 ? "  ×  " + qty : "")));
        }
        String bodyText = "*Namma Ooru Delivery* 🛵\n"
                + "எங்களிடம் உள்ளவை — தேர்வு செய்யுங்கள் 👇\n"
                + "We have these matching \"" + keyword + "\" — tap to choose:";
        return whatsAppNotificationService.sendInteractiveList(from, bodyText, "View products", rows);
    }

    /** Row id format "sp:{shopProductId}:q:{qty}". */
    private int parsePickedQty(String rowId) {
        try {
            String[] parts = rowId.split(":");
            return parts.length >= 4 ? Math.max(1, Integer.parseInt(parts[3])) : 1;
        } catch (Exception e) {
            return 1;
        }
    }

    /** Configured shop, or the platform's single active shop; null disables the bot. */
    private Long resolveShopId() {
        if (configuredShopId != null && !configuredShopId.isBlank()) {
            try {
                return Long.valueOf(configuredShopId.trim());
            } catch (NumberFormatException e) {
                log.warn("Invalid whatsapp.order.shop-id: {}", configuredShopId);
            }
        }
        List<Shop> active = shopRepository.findAll().stream()
                .filter(s -> Boolean.TRUE.equals(s.getIsActive()))
                .toList();
        return active.size() == 1 ? active.get(0).getId() : null;
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
