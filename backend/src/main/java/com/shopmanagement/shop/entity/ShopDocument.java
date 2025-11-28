package com.shopmanagement.shop.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;
import lombok.EqualsAndHashCode;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "shop_documents")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class ShopDocument {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", nullable = false)
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Shop shop;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "document_type", nullable = false)
    private DocumentType documentType;

    @NotBlank
    @Size(max = 255)
    @Column(name = "document_name", nullable = false)
    private String documentName;

    @NotBlank
    @Size(max = 500)
    @Column(name = "file_path", nullable = false)
    private String filePath;

    @NotBlank
    @Size(max = 255)
    @Column(name = "original_filename", nullable = false)
    private String originalFilename;

    @Size(max = 100)
    @Column(name = "file_type")
    private String fileType;

    @Column(name = "file_size")
    private Long fileSize;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    @Column(name = "verification_status")
    private VerificationStatus verificationStatus = VerificationStatus.PENDING;

    @Size(max = 1000)
    @Column(name = "verification_notes")
    private String verificationNotes;

    @Size(max = 255)
    @Column(name = "verified_by")
    private String verifiedBy;

    @Column(name = "verified_at")
    private LocalDateTime verifiedAt;

    @Builder.Default
    @Column(name = "is_required")
    private Boolean isRequired = true;

    // Timestamps
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public enum DocumentType {
        BUSINESS_LICENSE("Business License"),
        GST_CERTIFICATE("GST Registration Certificate"),
        PAN_CARD("PAN Card"),
        AADHAR_CARD("Aadhar Card"),
        BANK_STATEMENT("Bank Account Statement"),
        ADDRESS_PROOF("Address Proof"),
        OWNER_PHOTO("Owner Photo"),
        SHOP_PHOTO("Shop Photo"),
        FOOD_LICENSE("Food License"), // For restaurants
        FSSAI_CERTIFICATE("FSSAI Food Safety Certificate"), // For food businesses
        DRUG_LICENSE("Drug License"), // For pharmacies
        TRADE_LICENSE("Trade License"),
        OTHER("Other Document");

        private final String displayName;

        DocumentType(String displayName) {
            this.displayName = displayName;
        }

        public String getDisplayName() {
            return displayName;
        }
    }

    public enum VerificationStatus {
        PENDING("Pending Verification"),
        VERIFIED("Verified"),
        REJECTED("Rejected"),
        EXPIRED("Expired");

        private final String displayName;

        VerificationStatus(String displayName) {
            this.displayName = displayName;
        }

        public String getDisplayName() {
            return displayName;
        }
    }
}