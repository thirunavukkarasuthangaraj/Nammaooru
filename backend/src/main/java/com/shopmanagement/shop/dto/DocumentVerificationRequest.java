package com.shopmanagement.shop.dto;

import com.shopmanagement.shop.entity.ShopDocument;
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
    private ShopDocument.VerificationStatus verificationStatus;
    
    @Size(max = 1000)
    private String verificationNotes;
}