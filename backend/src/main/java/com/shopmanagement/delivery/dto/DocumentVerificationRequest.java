package com.shopmanagement.delivery.dto;

import com.shopmanagement.delivery.entity.DeliveryPartnerDocument;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DocumentVerificationRequest {

    @NotNull
    private DeliveryPartnerDocument.VerificationStatus verificationStatus;

    @Size(max = 1000)
    private String verificationNotes;
}