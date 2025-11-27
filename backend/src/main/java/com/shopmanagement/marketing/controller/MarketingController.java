package com.shopmanagement.marketing.controller;

import com.shopmanagement.marketing.dto.MarketingMessageRequest;
import com.shopmanagement.marketing.dto.MarketingMessageResponse;
import com.shopmanagement.marketing.dto.TemplateInfo;
import com.shopmanagement.marketing.service.MarketingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * REST Controller for marketing message operations
 * Requires ADMIN or SUPER_ADMIN role for all operations
 */
@RestController
@RequestMapping("/api/marketing")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
public class MarketingController {

    private final MarketingService marketingService;

    /**
     * Send bulk marketing messages to customers
     *
     * @param request Marketing message request with template and target audience
     * @return Response with success statistics
     */
    @PostMapping("/send-bulk")
    public ResponseEntity<MarketingMessageResponse> sendBulkMarketingMessage(
            @Valid @RequestBody MarketingMessageRequest request) {

        log.info("Received bulk marketing message request: template={}, audience={}",
                 request.getTemplateName(), request.getTargetAudience());

        try {
            MarketingMessageResponse response = marketingService.sendBulkMarketingMessage(request);

            if (response.isSuccess()) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
            }

        } catch (Exception e) {
            log.error("Error sending bulk marketing messages", e);

            MarketingMessageResponse errorResponse = MarketingMessageResponse.builder()
                    .success(false)
                    .message("Error sending marketing messages: " + e.getMessage())
                    .totalCustomers(0)
                    .successCount(0)
                    .failureCount(0)
                    .templateUsed(request.getTemplateName())
                    .messageParam(request.getMessageParam())
                    .build();

            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Get list of available marketing templates
     *
     * @return List of available templates with descriptions
     */
    @GetMapping("/templates")
    public ResponseEntity<List<TemplateInfo>> getAvailableTemplates() {
        log.info("Fetching available marketing templates");

        try {
            List<TemplateInfo> templates = marketingService.getAvailableTemplates();
            return ResponseEntity.ok(templates);

        } catch (Exception e) {
            log.error("Error fetching templates", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Get marketing statistics
     *
     * @return Statistics about eligible customers for marketing
     */
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getMarketingStats() {
        log.info("Fetching marketing statistics");

        try {
            Map<String, Object> stats = marketingService.getMarketingStats();
            return ResponseEntity.ok(stats);

        } catch (Exception e) {
            log.error("Error fetching marketing stats", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
