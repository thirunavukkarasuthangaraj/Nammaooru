package com.shopmanagement.shop.service;

import com.shopmanagement.shop.dto.DocumentVerificationRequest;
import com.shopmanagement.shop.dto.ShopDocumentResponse;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.entity.ShopDocument;
import com.shopmanagement.shop.exception.ShopNotFoundException;
import com.shopmanagement.shop.repository.ShopDocumentRepository;
import com.shopmanagement.shop.repository.ShopRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class ShopDocumentService {

    private final ShopDocumentRepository documentRepository;
    private final ShopRepository shopRepository;

    @Value("${app.upload.documents.path:uploads/documents/shops}")
    private String documentUploadPath;

    @Value("${app.upload.max-file-size:10MB}")
    private String maxFileSize;

    public List<ShopDocumentResponse> getShopDocuments(Long shopId) {
        return documentRepository.findByShopIdOrderByCreatedAtDesc(shopId)
                .stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    public ShopDocumentResponse uploadDocument(Long shopId, 
                                             ShopDocument.DocumentType documentType,
                                             String documentName,
                                             MultipartFile file) throws IOException {
        
        // Validate shop exists
        Shop shop = shopRepository.findById(shopId)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found with id: " + shopId));

        // Validate file
        validateFile(file);

        // Check if document type already exists for this shop
        boolean documentExists = documentRepository.existsByShopIdAndDocumentType(shopId, documentType);
        if (documentExists) {
            // Delete old document and replace with new one
            List<ShopDocument> existingDocs = documentRepository.findByShopIdAndDocumentType(shopId, documentType);
            for (ShopDocument existingDoc : existingDocs) {
                deleteDocumentFile(existingDoc.getFilePath());
                documentRepository.delete(existingDoc);
            }
        }

        // Generate unique filename
        String originalFilename = StringUtils.cleanPath(file.getOriginalFilename());
        String fileExtension = getFileExtension(originalFilename);
        String uniqueFilename = generateUniqueFilename(shop.getShopId(), documentType, fileExtension);

        // Create directory structure
        Path uploadDir = createUploadDirectory(shop.getShopId());
        
        // Save file
        Path filePath = uploadDir.resolve(uniqueFilename);
        Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

        // Save document record
        ShopDocument document = ShopDocument.builder()
                .shop(shop)
                .documentType(documentType)
                .documentName(documentName)
                .filePath(filePath.toString())
                .originalFilename(originalFilename)
                .fileType(file.getContentType())
                .fileSize(file.getSize())
                .verificationStatus(ShopDocument.VerificationStatus.PENDING)
                .isRequired(isRequiredDocument(documentType, shop.getBusinessType()))
                .build();

        document = documentRepository.save(document);

        log.info("Document uploaded successfully: {} for shop: {}", documentType, shopId);
        
        return convertToResponse(document);
    }

    public ShopDocumentResponse verifyDocument(Long documentId, DocumentVerificationRequest request, String verifiedBy) {
        ShopDocument document = documentRepository.findById(documentId)
                .orElseThrow(() -> new RuntimeException("Document not found"));

        document.setVerificationStatus(request.getVerificationStatus());
        document.setVerificationNotes(request.getVerificationNotes());
        document.setVerifiedBy(verifiedBy);
        document.setVerifiedAt(LocalDateTime.now());

        document = documentRepository.save(document);

        log.info("Document {} verification status updated to {} by {}", 
                 documentId, request.getVerificationStatus(), verifiedBy);

        return convertToResponse(document);
    }

    public Resource downloadDocument(Long documentId) {
        ShopDocument document = documentRepository.findById(documentId)
                .orElseThrow(() -> new RuntimeException("Document not found"));

        try {
            Path filePath = Paths.get(document.getFilePath());
            Resource resource = new UrlResource(filePath.toUri());
            
            if (resource.exists()) {
                return resource;
            } else {
                throw new RuntimeException("File not found: " + document.getFilePath());
            }
        } catch (MalformedURLException e) {
            throw new RuntimeException("File not found: " + document.getFilePath(), e);
        }
    }

    public void deleteDocument(Long documentId) {
        ShopDocument document = documentRepository.findById(documentId)
                .orElseThrow(() -> new RuntimeException("Document not found"));

        // Delete physical file
        deleteDocumentFile(document.getFilePath());

        // Delete database record
        documentRepository.delete(document);

        log.info("Document deleted successfully: {}", documentId);
    }

    private void validateFile(MultipartFile file) {
        if (file.isEmpty()) {
            throw new RuntimeException("Please select a file to upload");
        }

        // Check file size (10MB max)
        if (file.getSize() > 10 * 1024 * 1024) {
            throw new RuntimeException("File size too large. Maximum size allowed is 10MB");
        }

        // Check file type
        String contentType = file.getContentType();
        if (contentType == null || !isAllowedFileType(contentType)) {
            throw new RuntimeException("Invalid file type. Only PDF, JPG, PNG, and DOCX files are allowed");
        }
    }

    private boolean isAllowedFileType(String contentType) {
        return contentType.equals("application/pdf") ||
               contentType.equals("image/jpeg") ||
               contentType.equals("image/jpg") ||
               contentType.equals("image/png") ||
               contentType.equals("application/vnd.openxmlformats-officedocument.wordprocessingml.document") ||
               contentType.equals("application/msword");
    }

    private String getFileExtension(String filename) {
        if (filename == null || filename.lastIndexOf('.') == -1) {
            return "";
        }
        return filename.substring(filename.lastIndexOf('.'));
    }

    private String generateUniqueFilename(String shopId, ShopDocument.DocumentType documentType, String extension) {
        return String.format("%s_%s_%s_%s%s", 
                shopId, 
                documentType.name(),
                System.currentTimeMillis(),
                UUID.randomUUID().toString().substring(0, 8),
                extension);
    }

    private Path createUploadDirectory(String shopId) throws IOException {
        // Create absolute path for upload directory
        Path uploadDir = Paths.get(documentUploadPath).toAbsolutePath().resolve(shopId);
        log.info("Creating upload directory: {}", uploadDir.toString());
        
        if (!Files.exists(uploadDir)) {
            Files.createDirectories(uploadDir);
            log.info("Created upload directory: {}", uploadDir.toString());
        }
        return uploadDir;
    }

    private void deleteDocumentFile(String filePath) {
        try {
            Path path = Paths.get(filePath);
            Files.deleteIfExists(path);
        } catch (IOException e) {
            log.error("Error deleting file: {}", filePath, e);
        }
    }

    private boolean isRequiredDocument(ShopDocument.DocumentType documentType, Shop.BusinessType businessType) {
        // Basic required documents for all shops
        switch (documentType) {
            case BUSINESS_LICENSE:
            case GST_CERTIFICATE:
            case PAN_CARD:
            case AADHAR_CARD:
            case ADDRESS_PROOF:
            case OWNER_PHOTO:
            case SHOP_PHOTO:
                return true;
            case FOOD_LICENSE:
                return businessType == Shop.BusinessType.RESTAURANT;
            case FSSAI_CERTIFICATE:
                // FSSAI required for all food-related businesses
                return businessType == Shop.BusinessType.RESTAURANT || 
                       businessType == Shop.BusinessType.GROCERY;
            case DRUG_LICENSE:
                return businessType == Shop.BusinessType.PHARMACY;
            default:
                return false;
        }
    }

    private ShopDocumentResponse convertToResponse(ShopDocument document) {
        return ShopDocumentResponse.builder()
                .id(document.getId())
                .shopId(document.getShop().getId())
                .documentType(document.getDocumentType())
                .documentName(document.getDocumentName())
                .originalFilename(document.getOriginalFilename())
                .fileType(document.getFileType())
                .fileSize(document.getFileSize())
                .verificationStatus(document.getVerificationStatus())
                .verificationNotes(document.getVerificationNotes())
                .verifiedBy(document.getVerifiedBy())
                .verifiedAt(document.getVerifiedAt())
                .isRequired(document.getIsRequired())
                .downloadUrl("/api/documents/" + document.getId() + "/download")
                .createdAt(document.getCreatedAt())
                .updatedAt(document.getUpdatedAt())
                .build();
    }
}