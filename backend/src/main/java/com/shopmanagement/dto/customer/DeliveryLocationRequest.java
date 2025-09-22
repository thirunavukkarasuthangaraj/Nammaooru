package com.shopmanagement.dto.customer;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeliveryLocationRequest {

    @NotBlank(message = "Address type is required")
    private String addressType; // HOME, WORK, HOTEL, OTHER

    private String flatHouse;
    private String floor;

    @NotBlank(message = "Area is required")
    @Size(max = 200, message = "Area cannot exceed 200 characters")
    private String area;

    @Size(max = 100, message = "Landmark cannot exceed 100 characters")
    private String landmark;

    @Size(max = 100, message = "City cannot exceed 100 characters")
    private String city;

    @Size(max = 100, message = "State cannot exceed 100 characters")
    private String state;

    @Size(max = 10, message = "Pincode cannot exceed 10 characters")
    private String pincode;

    @NotNull(message = "Latitude is required")
    private Double latitude;

    @NotNull(message = "Longitude is required")
    private Double longitude;

    private Boolean isDefault;

    // Additional fields that might come from mobile app
    private String fullAddress;
    private String details;
}