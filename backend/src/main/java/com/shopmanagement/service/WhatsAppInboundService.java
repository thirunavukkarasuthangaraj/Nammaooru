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

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Processes inbound WhatsApp webhook payloads from the Meta Cloud API and
 * runs the order bot inside the free 24h service window:
 *
 *   customer: "atta"            -> product photos + tappable list   (row: PROCESSED)
 *   customer: taps a product    -> cart row + summary with total and
 *                                  [Confirm order] [Add more]       (row: CART)
 *   customer: taps Confirm      -> ONE consolidated NEW inbox row
 *                                  "CONFIRMED ORDER ..." and the cart
 *                                  rows become PROCESSED
 *
 * Anything the bot can't handle (multi-line lists, no product match, media)
 * stays a NEW row with the generic acknowledgement so staff pick it up.
 * The webhook must always answer 200 or Meta keeps retrying the payload.
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

    /** Cart row body: "✔ Elite Atta 5kg × 2 — ₹580" (qty part optional). */
    private static final Pattern CART_LINE = Pattern.compile("^✔ (.+?)(?: × (\\d+))? — ₹([\\d.]+)$");

    /** Cart rows older than this no longer count towards the running order. */
    private static final int CART_WINDOW_HOURS = 24;

    private final WhatsAppIncomingMessageRepository repository;
    private final WhatsAppNotificationService whatsAppNotificationService;
    private final ShopProductRepository shopProductRepository;
    private final ShopRepository shopRepository;

    /** Optional fixed shop for the order bot; when blank, the single active shop is used. */
    @Value("${whatsapp.order.shop-id:}")
    private String configuredShopId;

    /**
     * Meta Commerce Catalogue id connected to the WABA. When set, search
     * replies become multi-product messages (image thumbnails + native
     * quantity selector + cart); when blank, the plain text list is used.
     */
    @Value("${whatsapp.order.catalog-id:}")
    private String catalogId;

    /** Public base for /uploads/... product images (Meta fetches them from here). */
    @Value("${app.api.base-url:https://api.nammaoorudelivary.in}")
    private String apiBaseUrl;

    /**
     * Product photos sent before the list. Default 0: full-size image messages
     * flood the chat and bury the tappable list (tested 2026-08-21); compact
     * image cards need the Catalogue instead.
     */
    @Value("${whatsapp.order.photo-count:0}")
    private int photoCount;

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
        JsonNode interactive = message.path("interactive");

        try {
            if (interactive.has("list_reply")) {
                handleProductPick(waMessageId, from, profileName, message);
            } else if (interactive.has("button_reply")) {
                handleButtonReply(waMessageId, from, profileName, message);
            } else if ("order".equals(type)) {
                handleCatalogOrder(waMessageId, from, profileName, message);
            } else {
                handleRegularMessage(waMessageId, from, profileName, message, type);
            }
        } catch (Exception e) {
            // Never lose the message: store it as NEW for staff even when the
            // bot flow blows up mid-way.
            log.error("Order-bot handling failed for {} from {}", waMessageId, from, e);
            if (!repository.existsByWaMessageId(waMessageId)) {
                saveRow(waMessageId, from, profileName, type, extractBody(message, type), "NEW", message);
            }
        }
    }

    // ---------- regular text / media ----------

    private void handleRegularMessage(String waMessageId, String from, String profileName,
                                      JsonNode message, String type) {
        String body = extractBody(message, type);

        // Short single-line text -> try the product picker
        if ("text".equals(type) && body != null && !body.contains("\n")
                && trySuggestProducts(from, body)) {
            // Bot answered the query; keep it out of the staff "New" tab
            WhatsAppIncomingMessage saved = saveRow(waMessageId, from, profileName, type, body, "PROCESSED", message);
            saved.setAutoReplied(true);
            repository.save(saved);
            return;
        }

        WhatsAppIncomingMessage saved = saveRow(waMessageId, from, profileName, type, body, "NEW", message);
        if (whatsAppNotificationService.sendTextMessage(from, AUTO_REPLY)) {
            saved.setAutoReplied(true);
            repository.save(saved);
        }
    }

    // ---------- product pick (list_reply) ----------

    private void handleProductPick(String waMessageId, String from, String profileName, JsonNode message) {
        JsonNode reply = message.path("interactive").path("list_reply");
        String title = reply.path("title").asText("");
        String rowId = reply.path("id").asText("");

        // Tap on the "remove item" list: id "rm:{cartRowDbId}"
        if (rowId.startsWith("rm:")) {
            handleRemovePick(waMessageId, from, profileName, rowId, message);
            return;
        }

        int qty = parsePickedQty(rowId);

        // qty 0 = the customer picked a product without typing an amount —
        // ask "how many?" with a tappable 1..10 list before adding to cart.
        if (qty == 0) {
            saveRow(waMessageId, from, profileName, "interactive", "[qty? " + title + "]", "PROCESSED", message);
            BigDecimal unit = lookupPrice(rowId);
            String spPart = rowId.split(":")[1];
            List<Map<String, String>> rows = new ArrayList<>();
            for (int n = 1; n <= 10; n++) {
                rows.add(Map.of(
                        "id", "sp:" + spPart + ":q:" + n,
                        "title", String.valueOf(n),
                        "description", "₹" + unit.multiply(BigDecimal.valueOf(n)).stripTrailingZeros().toPlainString()));
            }
            whatsAppNotificationService.sendInteractiveList(from,
                    "*Namma Ooru Delivery* 🛵\n" + title + " — எத்தனை வேண்டும்?\nHow many do you need?",
                    "Select quantity", rows);
            return;
        }
        BigDecimal unitPrice = lookupPrice(rowId);
        BigDecimal lineTotal = unitPrice.multiply(BigDecimal.valueOf(qty));

        String body = "✔ " + title + (qty > 1 ? " × " + qty : "")
                + " — ₹" + lineTotal.stripTrailingZeros().toPlainString();
        WhatsAppIncomingMessage saved = saveRow(waMessageId, from, profileName, "interactive", body, "CART", message);

        if (sendCartSummary(from)) {
            saved.setAutoReplied(true);
            repository.save(saved);
        }
    }

    /** The running order + Confirm / Add more / Remove buttons. */
    private boolean sendCartSummary(String from) {
        String summary = buildCartSummary(from);
        Map<String, String> buttons = new LinkedHashMap<>();
        buttons.put("confirm_order", "✅ Confirm order");
        buttons.put("add_more", "➕ Add more");
        buttons.put("remove_item", "🗑 Remove item");
        return whatsAppNotificationService.sendInteractiveButtons(from, summary, buttons);
    }

    /** "Add 1"/"Add 2" tapped directly on a product card — id "add:{spId}:{qty}". */
    private void handleQuickAdd(String waMessageId, String from, String profileName,
                                String buttonId, JsonNode message) {
        String[] parts = buttonId.split(":");
        Long spId = Long.valueOf(parts[1]);
        int qty = Math.max(1, Integer.parseInt(parts[2]));
        BigDecimal unitPrice = shopProductRepository.findById(spId).map(ShopProduct::getPrice).orElse(BigDecimal.ZERO);
        String name = shopProductRepository.findById(spId).map(ShopProduct::getDisplayName).orElse("Item");
        BigDecimal lineTotal = unitPrice.multiply(BigDecimal.valueOf(qty));

        String body = "✔ " + name + (qty > 1 ? " × " + qty : "")
                + " — ₹" + lineTotal.stripTrailingZeros().toPlainString();
        WhatsAppIncomingMessage saved = saveRow(waMessageId, from, profileName, "interactive", body, "CART", message);
        if (sendCartSummary(from)) {
            saved.setAutoReplied(true);
            repository.save(saved);
        }
    }

    /** Customer tapped an entry in the remove list — drop that cart row. */
    private void handleRemovePick(String waMessageId, String from, String profileName,
                                  String rowId, JsonNode message) {
        saveRow(waMessageId, from, profileName, "interactive", "[removed item]", "PROCESSED", message);
        try {
            Long cartRowId = Long.valueOf(rowId.substring(3));
            repository.findById(cartRowId)
                    .filter(row -> from.equals(row.getFromNumber()) && "CART".equals(row.getStatus()))
                    .ifPresent(row -> {
                        row.setStatus("REMOVED");
                        repository.save(row);
                    });
        } catch (NumberFormatException ignored) {
        }
        if (cartRows(from).isEmpty()) {
            whatsAppNotificationService.sendTextMessage(from,
                    "*Namma Ooru Delivery* 🛵\nஉங்கள் ஆர்டர் காலியாக உள்ளது.\n"
                    + "Item removed. Type a product name to add again 👇");
        } else {
            sendCartSummary(from);
        }
    }

    // ---------- confirm / add-more buttons ----------

    private void handleButtonReply(String waMessageId, String from, String profileName, JsonNode message) {
        String buttonId = message.path("interactive").path("button_reply").path("id").asText("");

        // Quick-add from a product card: "add:{shopProductId}:{qty}"
        if (buttonId.startsWith("add:")) {
            handleQuickAdd(waMessageId, from, profileName, buttonId, message);
            return;
        }

        // "Other options" on a product card: "opts:{keyword}" -> plain list of alternatives
        if (buttonId.startsWith("opts:")) {
            saveRow(waMessageId, from, profileName, "interactive", "[other options]", "PROCESSED", message);
            String keyword = buttonId.substring(5);
            Long shopId = resolveShopId();
            if (shopId != null) {
                List<ShopProduct> products = shopProductRepository
                        .searchAvailableByShopIdAndName(shopId, keyword, PageRequest.of(0, 10)).getContent();
                List<Map<String, String>> rows = new ArrayList<>();
                for (ShopProduct sp : products) {
                    rows.add(Map.of(
                            "id", "sp:" + sp.getId() + ":q:0",
                            "title", sp.getDisplayName(),
                            "description", "₹" + sp.getPrice().stripTrailingZeros().toPlainString()));
                }
                whatsAppNotificationService.sendInteractiveList(from,
                        "*Namma Ooru Delivery* 🛵\n\"" + keyword + "\" க்கான மற்ற பொருட்கள் 👇\nOther options for \"" + keyword + "\":",
                        "View products", rows);
            }
            return;
        }

        if ("confirm_order".equals(buttonId)) {
            List<WhatsAppIncomingMessage> cart = cartRows(from);
            if (cart.isEmpty()) {
                saveRow(waMessageId, from, profileName, "interactive", "[confirm with empty cart]", "PROCESSED", message);
                whatsAppNotificationService.sendTextMessage(from,
                        "*Namma Ooru Delivery* 🛵\nஉங்கள் ஆர்டரில் பொருட்கள் இல்லை.\n"
                        + "Type a product name (e.g. rice) to start your order 👇");
                return;
            }

            StringBuilder orderBody = new StringBuilder();
            BigDecimal total = BigDecimal.ZERO;
            for (WhatsAppIncomingMessage row : cart) {
                Matcher m = CART_LINE.matcher(row.getBody() == null ? "" : row.getBody());
                if (m.matches()) {
                    total = total.add(new BigDecimal(m.group(3)));
                    orderBody.append(m.group(1))
                            .append(m.group(2) != null ? " × " + m.group(2) : "")
                            .append(" — ₹").append(m.group(3)).append('\n');
                }
            }

            String consolidated = "✅ CONFIRMED ORDER — ₹" + total.stripTrailingZeros().toPlainString()
                    + "\n" + orderBody.toString().trim();
            // The confirm tap's own message id anchors the consolidated row, so
            // Meta retries can never create the order twice.
            WhatsAppIncomingMessage orderRow =
                    saveRow(waMessageId, from, profileName, "order", consolidated, "NEW", message);
            deleteTemporaryOrderRows(from);

            // Receipt-style confirmation: the customer sees the final cart
            boolean replied = whatsAppNotificationService.sendTextMessage(from,
                    "*Namma Ooru Delivery* 🛵\n"
                    + "உங்கள் ஆர்டர் உறுதி செய்யப்பட்டது ✅\n"
                    + "*Your confirmed order:*\n"
                    + orderBody.toString().trim() + "\n"
                    + "*மொத்தம் / Total: ₹" + total.stripTrailingZeros().toPlainString() + "*\n"
                    + "We will deliver soon 🛵 நன்றி!");
            if (replied) {
                orderRow.setAutoReplied(true);
                repository.save(orderRow);
            }
            return;
        }

        if ("remove_item".equals(buttonId)) {
            List<WhatsAppIncomingMessage> cart = cartRows(from);
            saveRow(waMessageId, from, profileName, "interactive", "[remove item]", "PROCESSED", message);
            if (cart.isEmpty()) {
                whatsAppNotificationService.sendTextMessage(from,
                        "*Namma Ooru Delivery* 🛵\nஉங்கள் ஆர்டர் காலியாக உள்ளது.\n"
                        + "Nothing to remove — type a product name to start 👇");
                return;
            }
            List<Map<String, String>> rows = new ArrayList<>();
            for (WhatsAppIncomingMessage row : cart) {
                if (rows.size() >= 10) break;  // WhatsApp list limit
                Matcher m = CART_LINE.matcher(row.getBody() == null ? "" : row.getBody());
                if (m.matches()) {
                    rows.add(Map.of(
                            "id", "rm:" + row.getId(),
                            "title", m.group(1) + (m.group(2) != null ? " × " + m.group(2) : ""),
                            "description", "₹" + m.group(3)));
                }
            }
            whatsAppNotificationService.sendInteractiveList(from,
                    "*Namma Ooru Delivery* 🛵\nநீக்க வேண்டிய பொருளை தேர்வு செய்யுங்கள் 👇\n"
                    + "Tap the item you want to remove:",
                    "Remove item", rows);
            return;
        }

        // "add_more" (or any other button): nudge for the next item
        saveRow(waMessageId, from, profileName, "interactive", "[add more]", "PROCESSED", message);
        whatsAppNotificationService.sendTextMessage(from,
                "*Namma Ooru Delivery* 🛵\nஅடுத்த பொருளின் பெயரை அனுப்புங்கள் 👇\n"
                + "Type the next item name (e.g. rice, sugar, oil)");
    }

    // ---------- catalogue cart order ----------

    /**
     * The customer sent their WhatsApp Catalogue cart (message type "order"):
     * product_items[] with product_retailer_id ("sp{shopProductId}" from our
     * feed), quantity and item_price. Becomes ONE consolidated NEW inbox row.
     */
    private void handleCatalogOrder(String waMessageId, String from, String profileName, JsonNode message) {
        JsonNode order = message.path("order");
        StringBuilder lines = new StringBuilder();
        BigDecimal total = BigDecimal.ZERO;

        for (JsonNode item : order.path("product_items")) {
            String retailerId = item.path("product_retailer_id").asText("");
            int qty = Math.max(1, item.path("quantity").asInt(1));
            BigDecimal price = new BigDecimal(item.path("item_price").asText("0"));

            String name = retailerId;
            if (retailerId.startsWith("sp")) {
                try {
                    name = shopProductRepository.findById(Long.valueOf(retailerId.substring(2)))
                            .map(ShopProduct::getDisplayName)
                            .orElse(retailerId);
                } catch (NumberFormatException ignored) {
                }
            }
            BigDecimal lineTotal = price.multiply(BigDecimal.valueOf(qty));
            total = total.add(lineTotal);
            lines.append(name)
                    .append(qty > 1 ? " × " + qty : "")
                    .append(" — ₹").append(lineTotal.stripTrailingZeros().toPlainString())
                    .append('\n');
        }

        String body = "✅ CONFIRMED ORDER (catalogue cart) — ₹" + total.stripTrailingZeros().toPlainString()
                + "\n" + lines.toString().trim();
        WhatsAppIncomingMessage orderRow =
                saveRow(waMessageId, from, profileName, "order", body, "NEW", message);
        deleteTemporaryOrderRows(from);

        boolean replied = whatsAppNotificationService.sendTextMessage(from,
                "*Namma Ooru Delivery* 🛵\n"
                + "உங்கள் ஆர்டர் கிடைத்தது ✅\n"
                + lines.toString().trim() + "\n"
                + "*மொத்தம் / Total: ₹" + total.stripTrailingZeros().toPlainString() + "*\n"
                + "We will confirm and deliver soon 🛵 நன்றி!");
        if (replied) {
            orderRow.setAutoReplied(true);
            repository.save(orderRow);
        }
    }

    // ---------- product suggestions ----------

    /**
     * For short single-line queries, send product photos + a tappable list of
     * matching products. Returns false (caller stores NEW + generic ack) when
     * there is no usable keyword or no match.
     */
    private boolean trySuggestProducts(String from, String body) {
        Long shopId = resolveShopId();
        if (shopId == null) {
            return false;
        }

        int qty = 1;
        boolean qtyTyped = false;
        String text = body.toLowerCase();
        Matcher m = QTY_PATTERN.matcher(text);
        if (m.find() && !m.group().isBlank()) {
            String unit = m.group(2) == null ? "" : m.group(2).toLowerCase();
            double n = Double.parseDouble(m.group(1));
            // grams/ml describe pack size, not count
            qty = List.of("g", "gm", "gram", "grams", "ml").contains(unit) ? 1 : Math.max(1, (int) Math.round(n));
            qtyTyped = true;
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
            products = shopProductRepository
                    .searchAvailableByShopIdAndName(shopId, keyword.split(" ")[0], PageRequest.of(0, 10)).getContent();
        }
        if (products.isEmpty()) {
            return false;
        }

        // Optional product photos before the tappable list (off by default).
        int photosSent = photoCount; // disable separate photo bubbles
        for (ShopProduct sp : products) {
            if (photosSent >= photoCount) break;
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

        // With a connected catalogue, reply with a multi-product message:
        // image thumbnails, native quantity selector and cart — the customer
        // sends their cart back as an "order" webhook handled above.
        if (catalogId != null && !catalogId.isBlank()) {
            List<String> retailerIds = new ArrayList<>();
            for (ShopProduct sp : products) {
                retailerIds.add("sp" + sp.getId());
            }
            return whatsAppNotificationService.sendProductList(from,
                    "Namma Ooru Delivery 🛵",
                    "எங்களிடம் உள்ளவை — தேர்வு செய்து cart-ல் சேர்க்கவும் 👇\n"
                            + "Matching \"" + keyword + "\" — tap, choose quantity, add to cart:",
                    catalogId, retailerIds);
        }

        // No catalogue configured: up to 3 separate, self-contained cards —
        // each its own bubble with photo + name + price + quick "Add" buttons.
        // Every card is directly tappable (unlike plain photo messages), so
        // the customer sees multiple real options with images at once.
        int cardLimit = 0; // legacy image cards disabled; use one compact list below
        boolean anySent = false;
        for (int i = 0; i < cardLimit; i++) {
            ShopProduct sp = products.get(i);
            String imageUrl = sp.getPrimaryShopImageUrl();
            if (imageUrl != null && !imageUrl.isBlank() && imageUrl.startsWith("/")) {
                imageUrl = apiBaseUrl + imageUrl;
            }
            String cardBody = "*" + sp.getDisplayName() + "*\n₹" + sp.getPrice().stripTrailingZeros().toPlainString();

            Map<String, String> cardButtons = new LinkedHashMap<>();
            if (qtyTyped) {
                cardButtons.put("add:" + sp.getId() + ":" + qty, "➕ Add " + qty);
            } else {
                cardButtons.put("add:" + sp.getId() + ":1", "➕ Add 1");
                cardButtons.put("add:" + sp.getId() + ":2", "➕ Add 2");
            }
            // Last card gets "More options" when the catalog has extra matches
            // beyond the 3 shown, so nothing is hidden from the customer.
            if (i == cardLimit - 1 && products.size() > cardLimit) {
                cardButtons.put("opts:" + keyword, "🔎 More options");
            }
            if (whatsAppNotificationService.sendInteractiveButtons(from, imageUrl, cardBody, cardButtons)) {
                anySent = true;
            }
        }
        List<Map<String, String>> compactRows = new ArrayList<>();
        for (ShopProduct sp : products) {
            if (compactRows.size() >= 10) break;
            compactRows.add(Map.of(
                    "id", "sp:" + sp.getId() + ":q:" + (qtyTyped ? qty : 0),
                    "title", sp.getDisplayName(),
                    "description", "Rs." + sp.getPrice().stripTrailingZeros().toPlainString()));
        }
        return whatsAppNotificationService.sendInteractiveList(from,
                "*Namma Ooru Delivery*\nMatching \"" + keyword + "\" - select one product. "
                        + "Choose quantity, then use Add more to search the next item:",
                "View products", compactRows);
    }

    // ---------- helpers ----------

    private WhatsAppIncomingMessage saveRow(String waMessageId, String from, String profileName,
                                            String type, String body, String status, JsonNode message) {
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
                .status(status)
                .receivedAt(receivedAt)
                .build());
        log.info("Stored incoming WhatsApp {} message {} from {} as {}", type, saved.getId(), from, status);
        return saved;
    }

    /** This customer's unconfirmed picks from the last CART_WINDOW_HOURS. */
    private List<WhatsAppIncomingMessage> cartRows(String from) {
        return repository.findByFromNumberAndStatusAndCreatedAtAfterOrderByCreatedAtAsc(
                from, "CART", LocalDateTime.now().minusHours(CART_WINDOW_HOURS));
    }

    /** Keep confirmed orders; discard this customer's recent temporary bot/cart rows. */
    private void deleteTemporaryOrderRows(String from) {
        List<WhatsAppIncomingMessage> temporaryRows =
                repository.findByFromNumberAndMessageTypeNotAndCreatedAtAfter(
                        from, "order", LocalDateTime.now().minusHours(CART_WINDOW_HOURS));
        if (!temporaryRows.isEmpty()) {
            repository.deleteAll(temporaryRows);
            log.info("Deleted {} temporary WhatsApp rows for confirmed order from {}",
                    temporaryRows.size(), from);
        }
    }

    /** Numbered summary of the cart with a grand total, for the buttons message. */
    private String buildCartSummary(String from) {
        List<WhatsAppIncomingMessage> cart = cartRows(from);
        StringBuilder sb = new StringBuilder("*Namma Ooru Delivery* 🛵\nஉங்கள் ஆர்டர் / Your order:\n");
        BigDecimal total = BigDecimal.ZERO;
        int i = 1;
        for (WhatsAppIncomingMessage row : cart) {
            Matcher m = CART_LINE.matcher(row.getBody() == null ? "" : row.getBody());
            if (m.matches()) {
                total = total.add(new BigDecimal(m.group(3)));
                sb.append(i++).append(". ").append(m.group(1))
                        .append(m.group(2) != null ? " × " + m.group(2) : "")
                        .append(" — ₹").append(m.group(3)).append('\n');
            }
        }
        sb.append("மொத்தம் / Total: ₹").append(total.stripTrailingZeros().toPlainString());
        return sb.toString();
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

    private BigDecimal lookupPrice(String rowId) {
        try {
            String[] parts = rowId.split(":");
            Long spId = Long.valueOf(parts[1]);
            return shopProductRepository.findById(spId)
                    .map(ShopProduct::getPrice)
                    .orElse(BigDecimal.ZERO);
        } catch (Exception e) {
            return BigDecimal.ZERO;
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
