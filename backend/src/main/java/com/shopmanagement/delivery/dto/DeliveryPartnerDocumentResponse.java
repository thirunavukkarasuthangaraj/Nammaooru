package com.shopmanagement.delivery.dto;

import com.shopmanagement.delivery.entity.DeliveryPartnerDocument;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeliveryPartnerDocumentResponse {

    private Long id;
    private Long partnerId;
    private DeliveryPartnerDocument.DocumentType documentType;
    private String documentName;
    private String originalFilename;
    private String fileType;
    private Long fileSize;
    private DeliveryPartnerDocument.VerificationStatus verificationStatus;
    private String verificationNotes;
    private String verifiedBy;
    private LocalDateTime verifiedAt;
    private Boolean isRequired;
    private String downloadUrl;

    // Additional metadata for delivery partner documents
    private String licenseNumber;
    private String vehicleNumber;
    private LocalDateTime expiryDate;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}