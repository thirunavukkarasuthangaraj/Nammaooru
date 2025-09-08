package com.shopmanagement.controller;

import com.shopmanagement.entity.BusinessHours;
import com.shopmanagement.service.BusinessHoursService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.DayOfWeek;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/business-hours")
@RequiredArgsConstructor
@Slf4j
public class BusinessHoursController {
    
    private final BusinessHoursService businessHoursService;
    
    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<List<BusinessHours>> getAllBusinessHours() {
        log.debug("Getting all business hours");
        List<BusinessHours> businessHours = businessHoursService.getAllBusinessHoursByShop(null);
        return ResponseEntity.ok(businessHours);
    }
    
    @GetMapping("/shop/{shopId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<List<BusinessHours>> getBusinessHoursByShop(@PathVariable Long shopId) {
        log.debug("Getting business hours for shop ID: {}", shopId);
        List<BusinessHours> businessHours = businessHoursService.getAllBusinessHoursByShop(shopId);
        return ResponseEntity.ok(businessHours);
    }
    
    @GetMapping("/shop/{shopId}/open")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<List<BusinessHours>> getOpenHoursByShop(@PathVariable Long shopId) {
        log.debug("Getting open hours for shop ID: {}", shopId);
        List<BusinessHours> openHours = businessHoursService.getOpenHoursByShop(shopId);
        return ResponseEntity.ok(openHours);
    }
    
    @GetMapping("/shop/{shopId}/day/{dayOfWeek}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<BusinessHours> getBusinessHoursByShopAndDay(
            @PathVariable Long shopId, 
            @PathVariable DayOfWeek dayOfWeek) {
        log.debug("Getting business hours for shop ID: {} and day: {}", shopId, dayOfWeek);
        return businessHoursService.getBusinessHoursByShopAndDay(shopId, dayOfWeek)
            .map(hours -> ResponseEntity.ok(hours))
            .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/shop/{shopId}/status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER') or hasRole('CUSTOMER')")
    public ResponseEntity<Map<String, Boolean>> getShopOpenStatus(@PathVariable Long shopId) {
        log.debug("Checking if shop is open now: {}", shopId);
        boolean isOpen = businessHoursService.isShopOpenNow(shopId);
        return ResponseEntity.ok(Map.of("isOpen", isOpen));
    }
    
    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<BusinessHours> createBusinessHours(@Valid @RequestBody BusinessHours businessHours) {
        log.debug("Creating business hours for shop ID: {}", businessHours.getShopId());
        BusinessHours created = businessHoursService.createBusinessHours(businessHours);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    
    @PostMapping("/shop/{shopId}/default")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<List<BusinessHours>> createDefaultBusinessHours(@PathVariable Long shopId) {
        log.debug("Creating default business hours for shop ID: {}", shopId);
        List<BusinessHours> defaultHours = businessHoursService.createDefaultBusinessHours(shopId);
        return ResponseEntity.status(HttpStatus.CREATED).body(defaultHours);
    }
    
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<BusinessHours> updateBusinessHours(
            @PathVariable Long id, 
            @Valid @RequestBody BusinessHours businessHours) {
        log.debug("Updating business hours with ID: {}", id);
        BusinessHours updated = businessHoursService.updateBusinessHours(id, businessHours);
        return ResponseEntity.ok(updated);
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Void> deleteBusinessHours(@PathVariable Long id) {
        log.debug("Deleting business hours with ID: {}", id);
        businessHoursService.deleteBusinessHours(id);
        return ResponseEntity.noContent().build();
    }
    
    @DeleteMapping("/shop/{shopId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Void> deleteAllBusinessHoursByShop(@PathVariable Long shopId) {
        log.debug("Deleting all business hours for shop ID: {}", shopId);
        businessHoursService.deleteAllBusinessHoursByShop(shopId);
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/enums")
    public ResponseEntity<Map<String, Object>> getBusinessHoursEnums() {
        return ResponseEntity.ok(Map.of(
                "daysOfWeek", DayOfWeek.values()
        ));
    }
}