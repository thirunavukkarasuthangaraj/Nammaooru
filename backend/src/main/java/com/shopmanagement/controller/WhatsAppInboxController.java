package com.shopmanagement.controller;

import com.shopmanagement.entity.WhatsAppIncomingMessage;
import com.shopmanagement.repository.WhatsAppIncomingMessageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Inbox of customer messages received on the business WhatsApp number
 * (orders sent as chat messages). Staff review NEW messages, optionally
 * assign them to the shop that will fulfil them, and mark them PROCESSED
 * once converted to a POS bill.
 *
 * Mapped under both /api/admin (ADMIN, SUPER_ADMIN) and /api/shop-owner
 * (also SHOP_OWNER) so shop owners can work the same inbox.
 */
@RestController
@RequestMapping({"/api/admin/whatsapp-inbox", "/api/shop-owner/whatsapp-inbox"})
@RequiredArgsConstructor
public class WhatsAppInboxController {

    private final WhatsAppIncomingMessageRepository repository;

    @GetMapping
    public ResponseEntity<Page<WhatsAppIncomingMessage>> list(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        PageRequest pageable = PageRequest.of(page, size);
        Page<WhatsAppIncomingMessage> result = (status == null || status.isBlank())
                ? repository.findAllByOrderByCreatedAtDesc(pageable)
                : repository.findByStatusOrderByCreatedAtDesc(status, pageable);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/summary")
    public ResponseEntity<Map<String, Long>> summary() {
        return ResponseEntity.ok(Map.of(
                "newCount", repository.countByStatus("NEW"),
                "processedCount", repository.countByStatus("PROCESSED")));
    }

    @PutMapping("/{id}/processed")
    public ResponseEntity<WhatsAppIncomingMessage> markProcessed(@PathVariable Long id) {
        return repository.findById(id)
                .map(message -> {
                    message.setStatus("PROCESSED");
                    return ResponseEntity.ok(repository.save(message));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    /** Assign (or reassign) the order to a shop. Body: {shopId, shopName}. */
    @PutMapping("/{id}/assign")
    public ResponseEntity<WhatsAppIncomingMessage> assignShop(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        return repository.findById(id)
                .map(message -> {
                    Object shopId = body.get("shopId");
                    message.setShopId(shopId != null ? Long.valueOf(String.valueOf(shopId)) : null);
                    Object shopName = body.get("shopName");
                    message.setShopName(shopName != null ? String.valueOf(shopName) : null);
                    return ResponseEntity.ok(repository.save(message));
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
