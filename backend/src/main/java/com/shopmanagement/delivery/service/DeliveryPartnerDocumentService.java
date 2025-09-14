package com.shopmanagement.delivery.service;

import com.shopmanagement.delivery.dto.DeliveryPartnerDocumentResponse;
import com.shopmanagement.delivery.dto.DocumentVerificationRequest;
import com.shopmanagement.delivery.entity.DeliveryPartnerDocument;
import com.shopmanagement.delivery.repository.DeliveryPartnerDocumentRepository;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.delivery.exception.DeliveryPartnerNotFoundException;
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
public class DeliveryPartnerDocumentService {

    private final DeliveryPartnerDocumentRepository documentRepository;
    private final UserRepository userRepository;

    @Value("${app.upload.documents.path.delivery-partners:uploads/documents/delivery-partners}")
    private String documentUploadPath;

    @Value("${app.upload.max-file-size:10MB}")
    private String maxFileSize;

    @Value("${app.base-url:}")
    private String baseUrl;

    public List<DeliveryPartnerDocumentResponse> getPartnerDocuments(Long partnerId) {
        return documentRepository.findByDeliveryPartnerIdOrderByCreatedAtDesc(partnerId)
                .stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    public DeliveryPartnerDocumentResponse uploadDocument(Long partnerId,
                                                        DeliveryPartnerDocument.DocumentType documentType,
                                                        String documentName,
                                                        MultipartFile file,
                                                        String licenseNumber,
                                                        String vehicleNumber) throws IOException {

        // Validate delivery partner exists
        User deliveryPartner = userRepository.findById(partnerId)
                .orElseThrow(() -> new DeliveryPartnerNotFoundException("Delivery partner not found with id: " + partnerId));

        // Validate if user is a delivery partner
        if (deliveryPartner.getRole() != User.UserRole.DELIVERY_PARTNER) {
            throw new RuntimeException("User is not a delivery partner");
        }

        // Validate file
        validateFile(file);

        // Check if document type already exists for this partner
        boolean documentExists = documentRepository.existsByDeliveryPartnerIdAndDocumentType(partnerId, documentType);
        if (documentExists) {
            // Delete old document and replace with new one
            List<DeliveryPartnerDocument> existingDocs = documentRepository.findByDeliveryPartnerIdAndDocumentType(partnerId, documentType);
            for (DeliveryPartnerDocument existingDoc : existingDocs) {
                deleteDocumentFile(existingDoc.getFilePath());
                documentRepository.delete(existingDoc);
            }
        }

        // Generate unique filename
        String originalFilename = StringUtils.cleanPath(file.getOriginalFilename());
        String fileExtension = getFileExtension(originalFilename);
        String uniqueFilename = generateUniqueFilename(partnerId.toString(), documentType, fileExtension);

        // Create directory structure
        Path uploadDir = createUploadDirectory(partnerId.toString());

        // Save file
        Path filePath = uploadDir.resolve(uniqueFilename);
        Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

        // Save document record
        DeliveryPartnerDocument document = DeliveryPartnerDocument.builder()
                .deliveryPartner(deliveryPartner)
                .documentType(documentType)
                .documentName(documentName)
                .filePath(filePath.toString())
                .originalFilename(originalFilename)
                .fileType(file.getContentType())
                .fileSize(file.getSize())
                .verificationStatus(DeliveryPartnerDocument.VerificationStatus.PENDING)
                .isRequired(isRequiredDocument(documentType))
                .licenseNumber(licenseNumber)
                .vehicleNumber(vehicleNumber)
                .build();

        document = documentRepository.save(document);

        log.info("Document uploaded successfully: {} for delivery partner: {}", documentType, partnerId);

        return convertToResponse(document);
    }

    public DeliveryPartnerDocumentResponse verifyDocument(Long documentId, DocumentVerificationRequest request, String verifiedBy) {
        DeliveryPartnerDocument document = documentRepository.findById(documentId)
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
        DeliveryPartnerDocument document = documentRepository.findById(documentId)
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

    public DeliveryPartnerDocument getDocumentById(Long documentId) {
        return documentRepository.findById(documentId)
                .orElseThrow(() -> new RuntimeException("Document not found"));
    }

    public void deleteDocument(Long documentId) {
        DeliveryPartnerDocument document = documentRepository.findById(documentId)
                .orElseThrow(() -> new RuntimeException("Document not found"));

        // Delete physical file
        deleteDocumentFile(document.getFilePath());

        // Delete database record
        documentRepository.delete(document);

        log.info("Document deleted successfully: {}", documentId);
    }

    public List<DeliveryPartnerDocument.DocumentType> getRequiredDocumentTypes() {
        return List.of(
            DeliveryPartnerDocument.DocumentType.DRIVER_PHOTO,
            DeliveryPartnerDocument.DocumentType.DRIVING_LICENSE,
            DeliveryPartnerDocument.DocumentType.VEHICLE_PHOTO,
            DeliveryPartnerDocument.DocumentType.RC_BOOK
        );
    }

    public boolean isAllDocumentsUploaded(Long partnerId) {
        List<DeliveryPartnerDocument.DocumentType> requiredTypes = getRequiredDocumentTypes();
        long uploadedRequiredDocs = documentRepository.findByPartnerIdAndDocumentTypes(partnerId, requiredTypes).size();
        return uploadedRequiredDocs == requiredTypes.size();
    }

    public boolean isAllDocumentsVerified(Long partnerId) {
        long verifiedRequiredDocs = documentRepository.countVerifiedRequiredDocumentsByPartnerId(partnerId);
        return verifiedRequiredDocs == getRequiredDocumentTypes().size();
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

    private String generateUniqueFilename(String partnerId, DeliveryPartnerDocument.DocumentType documentType, String extension) {
        return String.format("partner_%s_%s_%s_%s%s",
                partnerId,
                documentType.name(),
                System.currentTimeMillis(),
                UUID.randomUUID().toString().substring(0, 8),
                extension);
    }

    private Path createUploadDirectory(String partnerId) throws IOException {
        // Create absolute path for upload directory
        Path uploadDir = Paths.get(documentUploadPath).toAbsolutePath().resolve(partnerId);
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

    private boolean isRequiredDocument(DeliveryPartnerDocument.DocumentType documentType) {
        return getRequiredDocumentTypes().contains(documentType);
    }

    private DeliveryPartnerDocumentResponse convertToResponse(DeliveryPartnerDocument document) {
        return DeliveryPartnerDocumentResponse.builder()
                .id(document.getId())
                .partnerId(document.getDeliveryPartner().getId())
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
                .licenseNumber(document.getLicenseNumber())
                .vehicleNumber(document.getVehicleNumber())
                .expiryDate(document.getExpiryDate())
                .downloadUrl(buildDownloadUrl(document))
                .createdAt(document.getCreatedAt())
                .updatedAt(document.getUpdatedAt())
                .build();
    }

    private String buildDownloadUrl(DeliveryPartnerDocument document) {
        String downloadPath = "/api/delivery/partners/" + document.getDeliveryPartner().getId() +
                              "/documents/" + document.getId() + "/download";

        if (baseUrl != null && !baseUrl.isEmpty()) {
            return baseUrl + downloadPath;
        }
        return downloadPath; // Return relative URL if baseUrl is not configured
    }
}