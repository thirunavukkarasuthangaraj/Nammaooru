package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.dto.customer.*;
import com.shopmanagement.service.CustomerService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/customer")
@RequiredArgsConstructor
@Slf4j
public class CustomerMobileController {

    private final CustomerService customerService;

    @GetMapping("/delivery-locations")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<ApiResponse<List<DeliveryLocationResponse>>> getDeliveryLocations() {
        try {
            log.info("Fetching delivery locations for current user");

            // For now, return a sample response - in a real implementation,
            // this would fetch from the database based on the authenticated user
            List<DeliveryLocationResponse> locations = new ArrayList<>();

            // Add a default location for Thirupattur
            DeliveryLocationResponse defaultLocation = DeliveryLocationResponse.builder()
                    .id(1L)
                    .addressType("HOME")
                    .area("Thirupattur")
                    .city("Thirupattur")
                    .state("Tamil Nadu")
                    .pincode("635601")
                    .fullAddress("Thirupattur, Tamil Nadu 635601")
                    .latitude(12.4997)
                    .longitude(78.5553)
                    .isDefault(true)
                    .isActive(true)
                    .displayLabel("Home - Thirupattur")
                    .shortAddress("Thirupattur, TN")
                    .build();

            locations.add(defaultLocation);

            return ResponseEntity.ok(ApiResponse.success(locations, "Delivery locations fetched successfully"));

        } catch (Exception e) {
            log.error("Error fetching delivery locations", e);
            return ResponseEntity.status(500)
                    .body(ApiResponse.error("Failed to fetch delivery locations", "DELIVERY_LOCATIONS_ERROR"));
        }
    }

    @PostMapping("/delivery-locations")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<ApiResponse<DeliveryLocationResponse>> addDeliveryLocation(
            @RequestBody DeliveryLocationRequest request) {
        try {
            log.info("Adding new delivery location for current user");

            // For now, return a sample response - in a real implementation,
            // this would save to the database
            DeliveryLocationResponse response = DeliveryLocationResponse.builder()
                    .id(System.currentTimeMillis()) // Generate temporary ID
                    .addressType(request.getAddressType())
                    .flatHouse(request.getFlatHouse())
                    .floor(request.getFloor())
                    .area(request.getArea())
                    .landmark(request.getLandmark())
                    .city(request.getCity())
                    .state(request.getState())
                    .pincode(request.getPincode())
                    .fullAddress(String.format("%s, %s, %s %s",
                            request.getArea(), request.getCity(), request.getState(), request.getPincode()))
                    .latitude(request.getLatitude())
                    .longitude(request.getLongitude())
                    .isDefault(request.getIsDefault())
                    .isActive(true)
                    .displayLabel(request.getAddressType() + " - " + request.getArea())
                    .shortAddress(request.getArea() + ", " + request.getCity())
                    .build();

            return ResponseEntity.ok(ApiResponse.success(response, "Delivery location added successfully"));

        } catch (Exception e) {
            log.error("Error adding delivery location", e);
            return ResponseEntity.status(500)
                    .body(ApiResponse.error("Failed to add delivery location", "ADD_LOCATION_ERROR"));
        }
    }

    @PutMapping("/delivery-locations/{id}")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<ApiResponse<DeliveryLocationResponse>> updateDeliveryLocation(
            @PathVariable Long id,
            @RequestBody DeliveryLocationRequest request) {
        try {
            log.info("Updating delivery location with ID: {}", id);

            // For now, return a sample response - in a real implementation,
            // this would update in the database
            DeliveryLocationResponse response = DeliveryLocationResponse.builder()
                    .id(id)
                    .addressType(request.getAddressType())
                    .flatHouse(request.getFlatHouse())
                    .floor(request.getFloor())
                    .area(request.getArea())
                    .landmark(request.getLandmark())
                    .city(request.getCity())
                    .state(request.getState())
                    .pincode(request.getPincode())
                    .fullAddress(String.format("%s, %s, %s %s",
                            request.getArea(), request.getCity(), request.getState(), request.getPincode()))
                    .latitude(request.getLatitude())
                    .longitude(request.getLongitude())
                    .isDefault(request.getIsDefault())
                    .isActive(true)
                    .displayLabel(request.getAddressType() + " - " + request.getArea())
                    .shortAddress(request.getArea() + ", " + request.getCity())
                    .build();

            return ResponseEntity.ok(ApiResponse.success(response, "Delivery location updated successfully"));

        } catch (Exception e) {
            log.error("Error updating delivery location with ID: {}", id, e);
            return ResponseEntity.status(500)
                    .body(ApiResponse.error("Failed to update delivery location", "UPDATE_LOCATION_ERROR"));
        }
    }

    @DeleteMapping("/delivery-locations/{id}")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<ApiResponse<String>> deleteDeliveryLocation(@PathVariable Long id) {
        try {
            log.info("Deleting delivery location with ID: {}", id);

            // For now, just return success - in a real implementation,
            // this would delete from the database
            return ResponseEntity.ok(ApiResponse.success("", "Delivery location deleted successfully"));

        } catch (Exception e) {
            log.error("Error deleting delivery location with ID: {}", id, e);
            return ResponseEntity.status(500)
                    .body(ApiResponse.error("Failed to delete delivery location", "DELETE_LOCATION_ERROR"));
        }
    }
}