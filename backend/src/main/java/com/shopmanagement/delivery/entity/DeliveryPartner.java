package com.shopmanagement.delivery.entity;

import com.shopmanagement.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "delivery_partners")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeliveryPartner {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "partner_id", unique = true, nullable = false, length = 20)
    private String partnerId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", unique = true)
    private User user;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(name = "phone_number", unique = true, nullable = false, length = 15)
    private String phoneNumber;

    @Column(name = "alternate_phone", length = 15)
    private String alternatePhone;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    @Enumerated(EnumType.STRING)
    @Column(length = 10)
    private Gender gender;

    @Column(name = "address_line1", nullable = false, length = 500)
    private String addressLine1;

    @Column(name = "address_line2", length = 500)
    private String addressLine2;

    @Column(nullable = false, length = 100)
    private String city;

    @Column(nullable = false, length = 100)
    private String state;

    @Column(name = "postal_code", nullable = false, length = 20)
    private String postalCode;

    @Column(length = 100)
    @Builder.Default
    private String country = "India";

    @Enumerated(EnumType.STRING)
    @Column(name = "vehicle_type", nullable = false, length = 20)
    private VehicleType vehicleType;

    @Column(name = "vehicle_number", unique = true, nullable = false, length = 20)
    private String vehicleNumber;

    @Column(name = "vehicle_model", length = 100)
    private String vehicleModel;

    @Column(name = "vehicle_color", length = 50)
    private String vehicleColor;

    @Column(name = "license_number", unique = true, nullable = false, length = 30)
    private String licenseNumber;

    @Column(name = "license_expiry_date", nullable = false)
    private LocalDate licenseExpiryDate;

    @Column(name = "bank_account_number", length = 20)
    private String bankAccountNumber;

    @Column(name = "bank_ifsc_code", length = 11)
    private String bankIfscCode;

    @Column(name = "bank_name", length = 100)
    private String bankName;

    @Column(name = "account_holder_name")
    private String accountHolderName;

    @Column(name = "service_areas")
    private String serviceAreas;

    @Column(name = "max_delivery_radius", precision = 8, scale = 2)
    @Builder.Default
    private BigDecimal maxDeliveryRadius = BigDecimal.valueOf(10);

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    @Builder.Default
    private PartnerStatus status = PartnerStatus.PENDING;

    @Enumerated(EnumType.STRING)
    @Column(name = "verification_status", length = 20)
    @Builder.Default
    private VerificationStatus verificationStatus = VerificationStatus.PENDING;

    @Column(name = "is_online")
    @Builder.Default
    private Boolean isOnline = false;

    @Column(name = "is_available")
    @Builder.Default
    private Boolean isAvailable = false;

    @Column(precision = 3, scale = 2)
    @Builder.Default
    private BigDecimal rating = BigDecimal.valueOf(5.00);

    @Column(name = "total_deliveries")
    @Builder.Default
    private Integer totalDeliveries = 0;

    @Column(name = "successful_deliveries")
    @Builder.Default
    private Integer successfulDeliveries = 0;

    @Column(name = "total_earnings", precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal totalEarnings = BigDecimal.ZERO;

    @Column(name = "current_latitude", precision = 10, scale = 6)
    private BigDecimal currentLatitude;

    @Column(name = "current_longitude", precision = 10, scale = 6)
    private BigDecimal currentLongitude;

    @Column(name = "last_location_update")
    private LocalDateTime lastLocationUpdate;

    @Column(name = "last_seen")
    private LocalDateTime lastSeen;

    @Column(name = "emergency_contact_name")
    private String emergencyContactName;

    @Column(name = "emergency_contact_phone", length = 15)
    private String emergencyContactPhone;

    @Column(name = "profile_image_url", length = 500)
    private String profileImageUrl;

    @OneToMany(mappedBy = "deliveryPartner", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<DeliveryPartnerDocument> documents;

    @OneToMany(mappedBy = "deliveryPartner", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<OrderAssignment> orderAssignments;

    @OneToMany(mappedBy = "deliveryPartner", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<PartnerEarning> earnings;

    @OneToMany(mappedBy = "deliveryPartner", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<PartnerAvailability> availabilities;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @Column(name = "created_by", length = 100)
    @Builder.Default
    private String createdBy = "system";

    @Column(name = "updated_by", length = 100)
    @Builder.Default
    private String updatedBy = "system";

    @PrePersist
    private void generatePartnerId() {
        if (partnerId == null) {
            partnerId = "DP" + String.format("%08d", System.currentTimeMillis() % 100000000);
        }
    }

    public boolean isActive() {
        return status == PartnerStatus.ACTIVE;
    }

    public boolean isVerified() {
        return verificationStatus == VerificationStatus.VERIFIED;
    }

    public boolean canTakeOrders() {
        return isActive() && isVerified() && isOnline && isAvailable;
    }

    public BigDecimal getSuccessRate() {
        if (totalDeliveries == 0) {
            return BigDecimal.valueOf(100);
        }
        return BigDecimal.valueOf(successfulDeliveries)
                .multiply(BigDecimal.valueOf(100))
                .divide(BigDecimal.valueOf(totalDeliveries), 2, BigDecimal.ROUND_HALF_UP);
    }

    public enum Gender {
        MALE, FEMALE, OTHER
    }

    public enum VehicleType {
        BIKE, SCOOTER, BICYCLE, CAR, AUTO
    }

    public enum PartnerStatus {
        PENDING, APPROVED, SUSPENDED, BLOCKED, ACTIVE
    }

    public enum VerificationStatus {
        PENDING, VERIFIED, REJECTED
    }
}