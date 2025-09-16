package com.shopmanagement.controller;

import com.shopmanagement.entity.DeliveryFeeRange;
import com.shopmanagement.service.DeliveryFeeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/super-admin/delivery-fees")
@RequiredArgsConstructor
@PreAuthorize("hasRole('SUPER_ADMIN')")
public class SuperAdminDeliveryFeeController {

    private final DeliveryFeeService deliveryFeeService;

    @GetMapping
    public ResponseEntity<Map<String, Object>> getAllDeliveryFeeRanges() {
        try {
            List<DeliveryFeeRange> ranges = deliveryFeeService.getAllRanges();
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", ranges,
                "message", "Delivery fee ranges retrieved successfully"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Error retrieving delivery fee ranges: " + e.getMessage()
            ));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getDeliveryFeeRange(@PathVariable Long id) {
        try {
            DeliveryFeeRange range = deliveryFeeService.getRangeById(id);
            if (range != null) {
                return ResponseEntity.ok(Map.of(
                    "success", true,
                    "data", range,
                    "message", "Delivery fee range retrieved successfully"
                ));
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Error retrieving delivery fee range: " + e.getMessage()
            ));
        }
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> createDeliveryFeeRange(@RequestBody DeliveryFeeRange range) {
        try {
            DeliveryFeeRange savedRange = deliveryFeeService.saveRange(range);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", savedRange,
                "message", "Delivery fee range created successfully"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Error creating delivery fee range: " + e.getMessage()
            ));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<Map<String, Object>> updateDeliveryFeeRange(@PathVariable Long id, @RequestBody DeliveryFeeRange range) {
        try {
            range.setId(id);
            DeliveryFeeRange updatedRange = deliveryFeeService.saveRange(range);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", updatedRange,
                "message", "Delivery fee range updated successfully"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Error updating delivery fee range: " + e.getMessage()
            ));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, Object>> deleteDeliveryFeeRange(@PathVariable Long id) {
        try {
            deliveryFeeService.deleteRange(id);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Delivery fee range deleted successfully"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Error deleting delivery fee range: " + e.getMessage()
            ));
        }
    }

    @PatchMapping("/{id}/toggle-status")
    public ResponseEntity<Map<String, Object>> toggleRangeStatus(@PathVariable Long id) {
        try {
            DeliveryFeeRange range = deliveryFeeService.getRangeById(id);
            if (range != null) {
                range.setIsActive(!range.getIsActive());
                DeliveryFeeRange updatedRange = deliveryFeeService.saveRange(range);
                return ResponseEntity.ok(Map.of(
                    "success", true,
                    "data", updatedRange,
                    "message", "Delivery fee range status updated successfully"
                ));
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Error updating delivery fee range status: " + e.getMessage()
            ));
        }
    }
}