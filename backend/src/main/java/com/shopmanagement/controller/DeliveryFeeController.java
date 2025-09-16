package com.shopmanagement.controller;

import com.shopmanagement.entity.DeliveryFeeRange;
import com.shopmanagement.service.DeliveryFeeService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/delivery-fees")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class DeliveryFeeController {

    private final DeliveryFeeService deliveryFeeService;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> getAllRanges() {
        try {
            List<DeliveryFeeRange> ranges = deliveryFeeService.getAllRanges();

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", ranges);
            response.put("totalRanges", ranges.size());

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error fetching delivery fee ranges: {}", e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    @GetMapping("/active")
    public ResponseEntity<Map<String, Object>> getActiveRanges() {
        try {
            List<DeliveryFeeRange> ranges = deliveryFeeService.getAllActiveRanges();

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", ranges);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error fetching active delivery fee ranges: {}", e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> createRange(@RequestBody DeliveryFeeRange range) {
        try {
            DeliveryFeeRange createdRange = deliveryFeeService.createRange(range);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Delivery fee range created successfully");
            response.put("data", createdRange);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error creating delivery fee range: {}", e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> updateRange(@PathVariable Long id, @RequestBody DeliveryFeeRange range) {
        try {
            DeliveryFeeRange updatedRange = deliveryFeeService.updateRange(id, range);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Delivery fee range updated successfully");
            response.put("data", updatedRange);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error updating delivery fee range {}: {}", id, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> deleteRange(@PathVariable Long id) {
        try {
            deliveryFeeService.deleteRange(id);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Delivery fee range deleted successfully");

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error deleting delivery fee range {}: {}", id, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Object>> getRangeById(@PathVariable Long id) {
        try {
            DeliveryFeeRange range = deliveryFeeService.getRangeById(id);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", range);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error fetching delivery fee range {}: {}", id, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    @PostMapping("/calculate")
    public ResponseEntity<Map<String, Object>> calculateFee(@RequestBody Map<String, Double> coordinates) {
        try {
            Double shopLat = coordinates.get("shopLat");
            Double shopLon = coordinates.get("shopLon");
            Double customerLat = coordinates.get("customerLat");
            Double customerLon = coordinates.get("customerLon");

            Double distance = deliveryFeeService.calculateDistance(shopLat, shopLon, customerLat, customerLon);
            BigDecimal deliveryFee = deliveryFeeService.calculateDeliveryFee(distance);
            BigDecimal partnerCommission = deliveryFeeService.calculatePartnerCommission(distance);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("distance", Math.round(distance * 100.0) / 100.0); // Round to 2 decimal places
            response.put("deliveryFee", deliveryFee);
            response.put("partnerCommission", partnerCommission);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error calculating delivery fee: {}", e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }
}