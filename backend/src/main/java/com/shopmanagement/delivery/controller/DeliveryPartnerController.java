package com.shopmanagement.delivery.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.delivery.dto.*;
import com.shopmanagement.delivery.entity.DeliveryPartner;
import com.shopmanagement.delivery.service.DeliveryPartnerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/delivery/partners")
@RequiredArgsConstructor
@Slf4j
public class DeliveryPartnerController {

    private final DeliveryPartnerService deliveryPartnerService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<DeliveryPartnerResponse>> registerPartner(
            @Valid @RequestBody DeliveryPartnerRegistrationRequest request) {
        log.info("Partner registration request received for email: {}", request.getEmail());
        
        try {
            DeliveryPartnerResponse response = deliveryPartnerService.registerPartner(request);
            return ResponseUtil.success(response, "Partner registration submitted successfully");
        } catch (Exception e) {
            log.error("Error registering partner: {}", e.getMessage());
            return ResponseUtil.error("Registration failed: " + e.getMessage());
        }
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<DeliveryPartnerResponse>> getPartnerById(@PathVariable Long id) {
        return deliveryPartnerService.getPartnerById(id)
                .map(partner -> ResponseUtil.success(partner))
                .orElse(ResponseUtil.error("Partner not found"));
    }

    @GetMapping("/partner-id/{partnerId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<DeliveryPartnerResponse>> getPartnerByPartnerId(@PathVariable String partnerId) {
        return deliveryPartnerService.getPartnerByPartnerId(partnerId)
                .map(partner -> ResponseUtil.success(partner))
                .orElse(ResponseUtil.error("Partner not found"));
    }

    @GetMapping("/user/{userId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or (hasRole('DELIVERY_PARTNER') and @deliveryPartnerService.getPartnerByUserId(#userId).isPresent() and @deliveryPartnerService.getPartnerByUserId(#userId).get().getUserId() == authentication.principal.id)")
    public ResponseEntity<ApiResponse<DeliveryPartnerResponse>> getPartnerByUserId(@PathVariable Long userId) {
        return deliveryPartnerService.getPartnerByUserId(userId)
                .map(partner -> ResponseUtil.success(partner))
                .orElse(ResponseUtil.error("Partner not found"));
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<Page<DeliveryPartnerResponse>>> getAllPartners(Pageable pageable) {
        Page<DeliveryPartnerResponse> partners = deliveryPartnerService.getAllPartners(pageable);
        return ResponseUtil.success(partners);
    }

    @GetMapping("/search")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<Page<DeliveryPartnerResponse>>> searchPartners(
            @RequestParam String term, Pageable pageable) {
        Page<DeliveryPartnerResponse> partners = deliveryPartnerService.searchPartners(term, pageable);
        return ResponseUtil.success(partners);
    }

    @GetMapping("/status/{status}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<List<DeliveryPartnerResponse>>> getPartnersByStatus(
            @PathVariable DeliveryPartner.PartnerStatus status) {
        List<DeliveryPartnerResponse> partners = deliveryPartnerService.getPartnersByStatus(status);
        return ResponseUtil.success(partners);
    }

    @GetMapping("/available")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<List<DeliveryPartnerResponse>>> getAvailablePartners() {
        List<DeliveryPartnerResponse> partners = deliveryPartnerService.getAvailablePartners();
        return ResponseUtil.success(partners);
    }

    @GetMapping("/nearby")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<List<DeliveryPartnerResponse>>> getNearbyPartners(
            @RequestParam BigDecimal latitude,
            @RequestParam BigDecimal longitude) {
        List<DeliveryPartnerResponse> partners = deliveryPartnerService.getNearbyPartners(latitude, longitude);
        return ResponseUtil.success(partners);
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<DeliveryPartnerResponse>> updatePartnerStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> request) {
        try {
            DeliveryPartner.PartnerStatus status = DeliveryPartner.PartnerStatus.valueOf(request.get("status"));
            DeliveryPartnerResponse response = deliveryPartnerService.updatePartnerStatus(id, status);
            return ResponseUtil.success(response, "Partner status updated successfully");
        } catch (Exception e) {
            log.error("Error updating partner status: {}", e.getMessage());
            return ResponseUtil.error("Failed to update status: " + e.getMessage());
        }
    }

    @PutMapping("/{id}/verification-status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<DeliveryPartnerResponse>> updateVerificationStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> request) {
        try {
            DeliveryPartner.VerificationStatus status = DeliveryPartner.VerificationStatus.valueOf(request.get("verificationStatus"));
            DeliveryPartnerResponse response = deliveryPartnerService.updateVerificationStatus(id, status);
            return ResponseUtil.success(response, "Verification status updated successfully");
        } catch (Exception e) {
            log.error("Error updating verification status: {}", e.getMessage());
            return ResponseUtil.error("Failed to update verification status: " + e.getMessage());
        }
    }

    @PutMapping("/{id}/online-status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or (hasRole('DELIVERY_PARTNER') and @deliveryPartnerService.getPartnerById(#id).isPresent())")
    public ResponseEntity<ApiResponse<DeliveryPartnerResponse>> updateOnlineStatus(
            @PathVariable Long id,
            @RequestBody Map<String, Boolean> request) {
        try {
            Boolean isOnline = request.get("isOnline");
            DeliveryPartnerResponse response = deliveryPartnerService.updateOnlineStatus(id, isOnline);
            return ResponseUtil.success(response, "Online status updated successfully");
        } catch (Exception e) {
            log.error("Error updating online status: {}", e.getMessage());
            return ResponseUtil.error("Failed to update online status: " + e.getMessage());
        }
    }

    @PutMapping("/{id}/availability")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<DeliveryPartnerResponse>> updateAvailability(
            @PathVariable Long id,
            @RequestBody Map<String, Boolean> request) {
        try {
            Boolean isAvailable = request.get("isAvailable");
            DeliveryPartnerResponse response = deliveryPartnerService.updateAvailabilityStatus(id, isAvailable);
            return ResponseUtil.success(response, "Availability updated successfully");
        } catch (Exception e) {
            log.error("Error updating availability: {}", e.getMessage());
            return ResponseUtil.error("Failed to update availability: " + e.getMessage());
        }
    }

    @PutMapping("/{id}/location")
    @PreAuthorize("hasRole('DELIVERY_PARTNER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<DeliveryPartnerResponse>> updateLocation(
            @PathVariable Long id,
            @RequestBody Map<String, BigDecimal> request) {
        try {
            BigDecimal latitude = request.get("latitude");
            BigDecimal longitude = request.get("longitude");
            DeliveryPartnerResponse response = deliveryPartnerService.updateLocation(id, latitude, longitude);
            return ResponseUtil.success(response, "Location updated successfully");
        } catch (Exception e) {
            log.error("Error updating location: {}", e.getMessage());
            return ResponseUtil.error("Failed to update location: " + e.getMessage());
        }
    }

    @GetMapping("/stats/counts")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getPartnerCounts() {
        Map<String, Long> counts = Map.of(
                "PENDING", deliveryPartnerService.getPartnerCountByStatus(DeliveryPartner.PartnerStatus.PENDING),
                "ACTIVE", deliveryPartnerService.getPartnerCountByStatus(DeliveryPartner.PartnerStatus.ACTIVE),
                "SUSPENDED", deliveryPartnerService.getPartnerCountByStatus(DeliveryPartner.PartnerStatus.SUSPENDED),
                "BLOCKED", deliveryPartnerService.getPartnerCountByStatus(DeliveryPartner.PartnerStatus.BLOCKED)
        );
        return ResponseUtil.success(counts);
    }

    @GetMapping("/expiring-licenses")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<List<DeliveryPartnerResponse>>> getPartnersWithExpiringLicenses(
            @RequestParam(defaultValue = "30") int days) {
        List<DeliveryPartnerResponse> partners = deliveryPartnerService.getPartnersWithExpiringLicenses(days);
        return ResponseUtil.success(partners);
    }
}