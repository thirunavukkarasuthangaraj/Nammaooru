package com.shopmanagement.controller;

import com.shopmanagement.dto.combo.ComboResponse;
import com.shopmanagement.dto.combo.CreateComboRequest;
import com.shopmanagement.service.ComboService;
import com.shopmanagement.service.FileUploadService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Slf4j
public class ComboController {

    private final ComboService comboService;
    private final FileUploadService fileUploadService;

    // ==================== SHOP OWNER APIs ====================

    /**
     * Create a new combo for a shop
     */
    @PostMapping("/shops/{shopId}/combos")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> createCombo(
            @PathVariable Long shopId,
            @Valid @RequestBody CreateComboRequest request) {
        log.info("POST /shops/{}/combos - Creating combo: {}", shopId, request.getName());

        try {
            ComboResponse combo = comboService.createCombo(shopId, request);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "0000");
            response.put("message", "Combo created successfully");
            response.put("data", combo);

            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            log.error("Error creating combo: {}", e.getMessage(), e);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "9999");
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Update an existing combo
     */
    @PutMapping("/shops/{shopId}/combos/{comboId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> updateCombo(
            @PathVariable Long shopId,
            @PathVariable Long comboId,
            @Valid @RequestBody CreateComboRequest request) {
        log.info("PUT /shops/{}/combos/{} - Updating combo", shopId, comboId);

        try {
            ComboResponse combo = comboService.updateCombo(shopId, comboId, request);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "0000");
            response.put("message", "Combo updated successfully");
            response.put("data", combo);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error updating combo: {}", e.getMessage(), e);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "9999");
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Delete a combo
     */
    @DeleteMapping("/shops/{shopId}/combos/{comboId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> deleteCombo(
            @PathVariable Long shopId,
            @PathVariable Long comboId) {
        log.info("DELETE /shops/{}/combos/{} - Deleting combo", shopId, comboId);

        try {
            comboService.deleteCombo(shopId, comboId);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "0000");
            response.put("message", "Combo deleted successfully");

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error deleting combo: {}", e.getMessage(), e);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "9999");
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Get combo by ID (shop owner view)
     */
    @GetMapping("/shops/{shopId}/combos/{comboId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> getCombo(
            @PathVariable Long shopId,
            @PathVariable Long comboId) {
        log.info("GET /shops/{}/combos/{} - Getting combo details", shopId, comboId);

        try {
            ComboResponse combo = comboService.getComboById(shopId, comboId);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "0000");
            response.put("data", combo);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error getting combo: {}", e.getMessage(), e);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "9999");
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Get all combos for a shop (paginated)
     */
    @GetMapping("/shops/{shopId}/combos")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> getShopCombos(
            @PathVariable Long shopId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("GET /shops/{}/combos - Getting combos, status: {}", shopId, status);

        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
            Page<ComboResponse> combos = comboService.getShopCombos(shopId, status, pageable);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "0000");
            response.put("data", combos);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error getting combos: {}", e.getMessage(), e);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "9999");
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Toggle combo active status
     */
    @PatchMapping("/shops/{shopId}/combos/{comboId}/toggle-status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> toggleComboStatus(
            @PathVariable Long shopId,
            @PathVariable Long comboId) {
        log.info("PATCH /shops/{}/combos/{}/toggle-status", shopId, comboId);

        try {
            ComboResponse combo = comboService.toggleComboStatus(shopId, comboId);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "0000");
            response.put("message", combo.getIsActive() ? "Combo activated" : "Combo deactivated");
            response.put("data", combo);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error toggling combo status: {}", e.getMessage(), e);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "9999");
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Upload combo banner image
     */
    @PostMapping(value = "/shops/{shopId}/combos/upload-image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> uploadComboImage(
            @PathVariable Long shopId,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "comboId", required = false) Long comboId) {
        log.info("POST /shops/{}/combos/upload-image - Uploading combo image", shopId);

        try {
            String imageUrl = fileUploadService.uploadComboImage(file, shopId, comboId);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "0000");
            response.put("message", "Image uploaded successfully");
            response.put("imageUrl", imageUrl);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error uploading combo image: {}", e.getMessage(), e);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "9999");
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    // ==================== CUSTOMER APIs ====================

    /**
     * Get all active combos across all shops (for dashboard)
     */
    @GetMapping("/customer/combos")
    public ResponseEntity<Map<String, Object>> getAllActiveCombos() {
        log.info("GET /customer/combos - Getting all active combos for dashboard");

        try {
            List<ComboResponse> combos = comboService.getAllActiveCombos();

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "0000");
            response.put("data", combos);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error getting all active combos: {}", e.getMessage(), e);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "9999");
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Get active combos for a shop (customer view)
     */
    @GetMapping("/customer/shops/{shopId}/combos")
    public ResponseEntity<Map<String, Object>> getActiveCombosForCustomer(
            @PathVariable Long shopId) {
        log.info("GET /customer/shops/{}/combos - Getting active combos for customer", shopId);

        try {
            List<ComboResponse> combos = comboService.getActiveCombosForCustomer(shopId);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "0000");
            response.put("data", combos);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error getting combos for customer: {}", e.getMessage(), e);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "9999");
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Get combo details for customer
     */
    @GetMapping("/customer/combos/{comboId}")
    public ResponseEntity<Map<String, Object>> getComboForCustomer(
            @PathVariable Long comboId) {
        log.info("GET /customer/combos/{} - Getting combo details for customer", comboId);

        try {
            ComboResponse combo = comboService.getComboForCustomer(comboId);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "0000");
            response.put("data", combo);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error getting combo for customer: {}", e.getMessage(), e);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "9999");
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }
}
