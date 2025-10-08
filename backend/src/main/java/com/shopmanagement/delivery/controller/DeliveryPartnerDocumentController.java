package com.shopmanagement.delivery.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.delivery.dto.DeliveryPartnerDocumentResponse;
import com.shopmanagement.delivery.dto.DocumentVerificationRequest;
import com.shopmanagement.delivery.entity.DeliveryPartnerDocument;
import com.shopmanagement.delivery.service.DeliveryPartnerDocumentService;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

import jakarta.validation.Valid;
import java.io.IOException;
import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/delivery/partners")
@RequiredArgsConstructor
public class DeliveryPartnerDocumentController {

    private final DeliveryPartnerDocumentService documentService;

    @GetMapping("/{partnerId}/documents")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<List<DeliveryPartnerDocumentResponse>>> getPartnerDocuments(@PathVariable Long partnerId) {
        List<DeliveryPartnerDocumentResponse> documents = documentService.getPartnerDocuments(partnerId);
        return ResponseUtil.success(documents, "Documents retrieved successfully");
    }

    @PostMapping("/{partnerId}/documents/upload")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<?> uploadDocument(
            @PathVariable Long partnerId,
            @RequestParam("documentType") String documentType,
            @RequestParam("documentName") String documentName,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "licenseNumber", required = false) String licenseNumber,
            @RequestParam(value = "vehicleNumber", required = false) String vehicleNumber,
            @RequestParam(value = "metadata", required = false) String metadata) {

        try {
            DeliveryPartnerDocument.DocumentType docType = DeliveryPartnerDocument.DocumentType.valueOf(documentType);
            DeliveryPartnerDocumentResponse response = documentService.uploadDocument(
                    partnerId, docType, documentName, file, licenseNumber, vehicleNumber);
            return ResponseEntity.ok(response);
        } catch (IOException e) {
            return ResponseEntity.status(500)
                    .body(Map.of("error", "File upload failed: " + e.getMessage()));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(500)
                    .body(Map.of("error", "An unexpected error occurred: " + e.getMessage()));
        }
    }

    @PutMapping("/{partnerId}/documents/{documentId}/verify")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<DeliveryPartnerDocumentResponse> verifyDocument(
            @PathVariable Long partnerId,
            @PathVariable Long documentId,
            @Valid @RequestBody DocumentVerificationRequest request,
            Principal principal) {

        DeliveryPartnerDocumentResponse response = documentService.verifyDocument(
                documentId, request, principal.getName());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/documents/{documentId}/view")
    public ResponseEntity<Resource> viewDocument(@PathVariable Long documentId) {
        try {
            Resource resource = documentService.downloadDocument(documentId);
            DeliveryPartnerDocument document = documentService.getDocumentById(documentId);

            String contentType = "application/octet-stream";
            if (document.getFileType() != null) {
                contentType = document.getFileType();
            }

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + resource.getFilename() + "\"")
                    .header(HttpHeaders.CACHE_CONTROL, "max-age=3600")
                    .body(resource);
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/{partnerId}/documents/{documentId}/download")
    public ResponseEntity<Resource> downloadDocument(
            @PathVariable Long partnerId,
            @PathVariable Long documentId,
            @RequestParam(value = "token", required = false) String token) {
        try {
            // Allow public access with valid token for viewing documents
            // In production, validate the token properly

            Resource resource = documentService.downloadDocument(documentId);

            // Get the document from database to determine content type
            DeliveryPartnerDocument document = documentService.getDocumentById(documentId);

            String contentType = "application/octet-stream"; // default
            if (document.getFileType() != null) {
                contentType = document.getFileType();
            }

            // For images and PDFs, use inline disposition so they display in browser
            String disposition = "attachment";
            if (contentType.startsWith("image/") || contentType.equals("application/pdf")) {
                disposition = "inline";
            }

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .header(HttpHeaders.CONTENT_DISPOSITION,
                            disposition + "; filename=\"" + resource.getFilename() + "\"")
                    .header(HttpHeaders.CACHE_CONTROL, "max-age=3600")
                    .body(resource);
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{partnerId}/documents/{documentId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> deleteDocument(
            @PathVariable Long partnerId,
            @PathVariable Long documentId) {
        try {
            documentService.deleteDocument(documentId);
            return ResponseEntity.ok(Map.of("message", "Document deleted successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Failed to delete document"));
        }
    }

    @GetMapping("/{partnerId}/documents/status")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<Map<String, Object>> getDocumentStatus(@PathVariable Long partnerId) {
        List<DeliveryPartnerDocument.DocumentType> requiredTypes = documentService.getRequiredDocumentTypes();
        boolean allUploaded = documentService.isAllDocumentsUploaded(partnerId);
        boolean allVerified = documentService.isAllDocumentsVerified(partnerId);

        return ResponseEntity.ok(Map.of(
                "requiredDocuments", requiredTypes,
                "allDocumentsUploaded", allUploaded,
                "allDocumentsVerified", allVerified,
                "verificationStatuses", DeliveryPartnerDocument.VerificationStatus.values()
        ));
    }

    @GetMapping("/documents/types")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<Map<String, Object>> getDocumentTypes() {
        return ResponseEntity.ok(Map.of(
                "documentTypes", DeliveryPartnerDocument.DocumentType.values(),
                "verificationStatuses", DeliveryPartnerDocument.VerificationStatus.values(),
                "requiredDocuments", documentService.getRequiredDocumentTypes()
        ));
    }
}