package com.shopmanagement.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "customer_addresses")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerAddress {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;
    
    @Column(nullable = false, length = 50)
    @NotBlank(message = "Address type is required")
    private String addressType; // HOME, WORK, OTHER
    
    @Column(length = 100)
    private String addressLabel; // Custom label like "Mom's House", "Office", etc.
    
    @Column(nullable = false, length = 200)
    @NotBlank(message = "Address line 1 is required")
    private String addressLine1;
    
    @Column(length = 200)
    private String addressLine2;
    
    @Column(length = 100)
    private String landmark;
    
    @Column(nullable = false, length = 100)
    @NotBlank(message = "City is required")
    private String city;
    
    @Column(nullable = false, length = 100)
    @NotBlank(message = "State is required")
    private String state;
    
    @Column(nullable = false, length = 10)
    @NotBlank(message = "Postal code is required")
    @Pattern(regexp = "^[0-9]{6}$", message = "Please provide a valid 6-digit postal code")
    private String postalCode;
    
    @Column(nullable = false, length = 50)
    @Builder.Default
    private String country = "India";
    
    @Column
    private Double latitude;
    
    @Column
    private Double longitude;
    
    @Column
    @Builder.Default
    private Boolean isDefault = false;
    
    @Column
    @Builder.Default
    private Boolean isActive = true;
    
    // Contact Information for this address
    @Column(length = 100)
    private String contactPersonName;
    
    @Column(length = 15)
    @Pattern(regexp = "^[+]?[0-9]{10,15}$", message = "Please provide a valid mobile number")
    private String contactMobileNumber;
    
    // Delivery Instructions
    @Column(length = 500)
    private String deliveryInstructions;
    
    // Audit Fields
    @Column(nullable = false, length = 100)
    @Builder.Default
    private String createdBy = "system";
    
    @Column(nullable = false, length = 100)
    @Builder.Default
    private String updatedBy = "system";
    
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;
    
    // Helper Methods
    public String getFullAddress() {
        StringBuilder address = new StringBuilder();
        
        if (addressLine1 != null && !addressLine1.trim().isEmpty()) {
            address.append(addressLine1);
        }
        
        if (addressLine2 != null && !addressLine2.trim().isEmpty()) {
            if (address.length() > 0) address.append(", ");
            address.append(addressLine2);
        }
        
        if (landmark != null && !landmark.trim().isEmpty()) {
            if (address.length() > 0) address.append(", ");
            address.append("Near ").append(landmark);
        }
        
        if (city != null && !city.trim().isEmpty()) {
            if (address.length() > 0) address.append(", ");
            address.append(city);
        }
        
        if (state != null && !state.trim().isEmpty()) {
            if (address.length() > 0) address.append(", ");
            address.append(state);
        }
        
        if (postalCode != null && !postalCode.trim().isEmpty()) {
            if (address.length() > 0) address.append(" - ");
            address.append(postalCode);
        }
        
        if (country != null && !country.trim().isEmpty() && !"India".equals(country)) {
            if (address.length() > 0) address.append(", ");
            address.append(country);
        }
        
        return address.toString();
    }
    
    public String getAddressLabel() {
        if (addressLabel != null && !addressLabel.trim().isEmpty()) {
            return addressLabel;
        }
        return addressType;
    }
    
    // Address Types
    public enum AddressType {
        HOME, WORK, OTHER
    }
}