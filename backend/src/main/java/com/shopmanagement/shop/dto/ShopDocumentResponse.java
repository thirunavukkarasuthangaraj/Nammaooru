package com.shopmanagement.shop.dto;

import com.shopmanagement.shop.entity.ShopDocument;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopDocumentResponse {
    
    private Long id;
    private Long shopId;
    private ShopDocument.DocumentType documentType;
    private String documentName;
    private String originalFilename;
    private String fileType;
    private Long fileSize;
    private ShopDocument.VerificationStatus verificationStatus;
    private String verificationNotes;
    private String verifiedBy;
    private LocalDateTime verifiedAt;
    private Boolean isRequired;
    private String downloadUrl;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}