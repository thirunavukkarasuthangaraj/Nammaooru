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
public class CustomerAddressRequest {
    
    @NotNull(message = "Customer ID is required")
    private Long customerId;
    
    @NotBlank(message = "Address type is required")
    private String addressType; // HOME, WORK, OTHER
    
    private String addressLabel;
    
    @NotBlank(message = "Address line 1 is required")
    @Size(max = 200, message = "Address line 1 cannot exceed 200 characters")
    private String addressLine1;
    
    @Size(max = 200, message = "Address line 2 cannot exceed 200 characters")
    private String addressLine2;
    
    @Size(max = 100, message = "Landmark cannot exceed 100 characters")
    private String landmark;
    
    @NotBlank(message = "City is required")
    @Size(max = 100, message = "City cannot exceed 100 characters")
    private String city;
    
    @NotBlank(message = "State is required")
    @Size(max = 100, message = "State cannot exceed 100 characters")
    private String state;
    
    @NotBlank(message = "Postal code is required")
    @Pattern(regexp = "^[0-9]{6}$", message = "Please provide a valid 6-digit postal code")
    private String postalCode;
    
    @Size(max = 50, message = "Country cannot exceed 50 characters")
    private String country;
    
    private Double latitude;
    private Double longitude;
    
    private Boolean isDefault;
    private Boolean isActive;
    
    // Contact Information
    @Size(max = 100, message = "Contact person name cannot exceed 100 characters")
    private String contactPersonName;
    
    @Pattern(regexp = "^[+]?[0-9]{10,15}$", message = "Please provide a valid mobile number")
    private String contactMobileNumber;
    
    // Delivery Instructions
    @Size(max = 500, message = "Delivery instructions cannot exceed 500 characters")
    private String deliveryInstructions;
}