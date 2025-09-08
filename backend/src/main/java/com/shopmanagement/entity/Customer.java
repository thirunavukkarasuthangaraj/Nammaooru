package com.shopmanagement.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "customers")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Customer {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, length = 100)
    @NotBlank(message = "First name is required")
    @Size(min = 2, max = 50, message = "First name must be between 2 and 50 characters")
    private String firstName;
    
    @Column(nullable = false, length = 100)
    @NotBlank(message = "Last name is required")
    @Size(min = 2, max = 50, message = "Last name must be between 2 and 50 characters")
    private String lastName;
    
    @Column(unique = true, nullable = false, length = 100)
    @NotBlank(message = "Email is required")
    @Email(message = "Please provide a valid email address")
    private String email;
    
    @Column(unique = true, nullable = false, length = 20)
    @NotBlank(message = "Mobile number is required")
    @Pattern(regexp = "^[+]?[0-9\\s\\-\\(\\)]{10,20}$", message = "Please provide a valid mobile number")
    private String mobileNumber;
    
    @Column(length = 15)
    @Pattern(regexp = "^[+]?[0-9]{10,15}$", message = "Please provide a valid alternate mobile number")
    private String alternateMobileNumber;
    
    @Column(length = 10)
    @Enumerated(EnumType.STRING)
    private Gender gender;
    
    @Column
    private LocalDate dateOfBirth;
    
    @Column(length = 20)
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private CustomerStatus status = CustomerStatus.ACTIVE;
    
    @Column(length = 500)
    private String notes;
    
    // Address Information
    @Column(length = 200)
    private String addressLine1;
    
    @Column(length = 200)
    private String addressLine2;
    
    @Column(length = 100)
    private String city;
    
    @Column(length = 100)
    private String state;
    
    @Column(length = 10)
    private String postalCode;
    
    @Column(length = 50)
    @Builder.Default
    private String country = "India";
    
    @Column
    private Double latitude;
    
    @Column
    private Double longitude;
    
    // Preferences
    @Column
    @Builder.Default
    private Boolean emailNotifications = true;
    
    @Column
    @Builder.Default
    private Boolean smsNotifications = true;
    
    @Column
    @Builder.Default
    private Boolean promotionalEmails = false;
    
    @Column(length = 50)
    private String preferredLanguage;
    
    // Customer Metrics
    @Column
    @Builder.Default
    private Integer totalOrders = 0;
    
    @Column
    @Builder.Default
    private Double totalSpent = 0.0;
    
    @Column
    private LocalDateTime lastOrderDate;
    
    @Column
    private LocalDateTime lastLoginDate;
    
    // Account Information
    @Column
    @Builder.Default
    private Boolean isVerified = false;
    
    @Column
    @Builder.Default
    private Boolean isActive = true;
    
    @Column
    private LocalDateTime emailVerifiedAt;
    
    @Column
    private LocalDateTime mobileVerifiedAt;
    
    @Column(length = 50)
    private String referralCode;
    
    @Column(length = 50)
    private String referredBy;
    
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
    
    // Relationships
    @OneToMany(mappedBy = "customer", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<CustomerAddress> addresses;
    
    // Enums
    public enum Gender {
        MALE, FEMALE, OTHER, PREFER_NOT_TO_SAY
    }
    
    public enum CustomerStatus {
        ACTIVE, INACTIVE, BLOCKED, PENDING_VERIFICATION
    }
    
    // Helper Methods
    public String getFullName() {
        return firstName + " " + lastName;
    }
    
    public String getDisplayName() {
        return firstName;
    }
    
    public boolean isEmailVerified() {
        return emailVerifiedAt != null;
    }
    
    public boolean isMobileVerified() {
        return mobileVerifiedAt != null;
    }
    
    public boolean isFullyVerified() {
        return isEmailVerified() && isMobileVerified();
    }
    
    // Additional getters for compatibility
    public Boolean getEmailVerified() {
        return isEmailVerified();
    }
    
    public Boolean getMobileVerified() {
        return isMobileVerified();
    }
    
    public Boolean getPushNotifications() {
        return smsNotifications; // Using SMS notifications as push notifications
    }
    
    public void setPushNotifications(Boolean pushNotifications) {
        this.smsNotifications = pushNotifications;
    }
    
    public Boolean getMarketingEmails() {
        return promotionalEmails;
    }
    
    public void setMarketingEmails(Boolean marketingEmails) {
        this.promotionalEmails = marketingEmails;
    }
    
    public Boolean getSecurityAlerts() {
        return true; // Default to true for security alerts
    }
    
    public void setSecurityAlerts(Boolean securityAlerts) {
        // Currently not stored, but method provided for compatibility
    }
    
    public String getFormattedAddress() {
        StringBuilder address = new StringBuilder();
        if (addressLine1 != null && !addressLine1.trim().isEmpty()) {
            address.append(addressLine1);
        }
        if (addressLine2 != null && !addressLine2.trim().isEmpty()) {
            if (address.length() > 0) address.append(", ");
            address.append(addressLine2);
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
        return address.toString();
    }
    
    @PrePersist
    protected void onCreate() {
        if (referralCode == null || referralCode.isEmpty()) {
            referralCode = generateReferralCode();
        }
    }
    
    private String generateReferralCode() {
        String namePrefix = (firstName != null && firstName.length() >= 2) 
            ? firstName.substring(0, 2).toUpperCase() 
            : "CU";
        String timestamp = String.valueOf(System.currentTimeMillis()).substring(7);
        return namePrefix + timestamp;
    }
}