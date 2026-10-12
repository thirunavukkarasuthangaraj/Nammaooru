package com.shopmanagement.controller;

import com.shopmanagement.entity.DeliveryHours;
import com.shopmanagement.service.DeliveryHoursService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.DayOfWeek;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * When a shop delivers, which is a different question from when it is open.
 *
 * Deliberately mirrors BusinessHoursController, because the web screen for editing these
 * is a copy of the opening-hours screen and the two should behave identically.
 */
@RestController
@RequestMapping("/api/delivery-hours")
@RequiredArgsConstructor
@Slf4j
public class DeliveryHoursController {

    private final DeliveryHoursService deliveryHoursService;

    /**
     * Public: the customer app needs these to show delivery windows before the customer
     * is identified, and they are no more sensitive than a shop's posted opening times.
     */
    @GetMapping("/shop/{shopId}")
    public ResponseEntity<List<DeliveryHours>> getByShop(@PathVariable Long shopId) {
        return ResponseEntity.ok(deliveryHoursService.getByShop(shopId));
    }

    @GetMapping("/shop/{shopId}/day/{dayOfWeek}")
    public ResponseEntity<DeliveryHours> getByShopAndDay(@PathVariable Long shopId,
                                                         @PathVariable DayOfWeek dayOfWeek) {
        return deliveryHoursService.getByShopAndDay(shopId, dayOfWeek)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Whether this shop's delivery hours still match its opening hours. Drives the
     * "Same as opening hours" toggle on the editor so it loads in the right state.
     */
    @GetMapping("/shop/{shopId}/matches-business-hours")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, Boolean>> matchesBusinessHours(@PathVariable Long shopId) {
        Map<String, Boolean> body = new HashMap<>();
        body.put("matches", deliveryHoursService.matchesBusinessHours(shopId));
        return ResponseEntity.ok(body);
    }

    /**
     * Replace the whole week at once. The editor saves seven days together, so a
     * per-day save would leave a half-updated week if the browser died mid-save.
     */
    @PutMapping("/shop/{shopId}/bulk")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<List<DeliveryHours>> replaceWeek(
            @PathVariable Long shopId,
            @Valid @RequestBody List<DeliveryHours> week) {
        log.info("Replacing delivery hours for shop {}", shopId);
        return ResponseEntity.ok(deliveryHoursService.replaceWeek(shopId, week));
    }

    /** Backs the "Same as opening hours" toggle being switched back on. */
    @PostMapping("/shop/{shopId}/copy-from-business-hours")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<List<DeliveryHours>> copyFromBusinessHours(@PathVariable Long shopId) {
        log.info("Copying opening hours into delivery hours for shop {}", shopId);
        return ResponseEntity.ok(deliveryHoursService.copyFromBusinessHours(shopId));
    }
}
