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
 * Admin inbox for customer messages received on the business WhatsApp number
 * (orders sent as chat messages). Staff review NEW messages and mark them
 * PROCESSED once converted to a POS bill. /api/admin/** already requires
 * ADMIN or SUPER_ADMIN in SecurityConfig.
 */
@RestController
@RequestMapping("/api/admin/whatsapp-inbox")
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
}
