package com.shopmanagement.delivery.dto;

import com.shopmanagement.delivery.entity.DeliveryPartnerDocument;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DocumentUploadRequest {

    @NotNull
    private DeliveryPartnerDocument.DocumentType documentType;

    @NotBlank
    @Size(max = 255)
    private String documentName;

    // Optional metadata fields
    @Size(max = 255)
    private String licenseNumber;

    @Size(max = 255)
    private String vehicleNumber;

    private LocalDateTime expiryDate;

    // JSON metadata string for additional information
    @Size(max = 1000)
    private String metadata;
}