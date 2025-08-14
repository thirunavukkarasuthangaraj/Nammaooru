package com.shopmanagement.shop.controller;

import com.shopmanagement.shop.dto.DocumentVerificationRequest;
import com.shopmanagement.shop.dto.ShopDocumentResponse;
import com.shopmanagement.shop.entity.ShopDocument;
import com.shopmanagement.shop.service.ShopDocumentService;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import jakarta.validation.Valid;
import java.io.IOException;
import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/documents")
@RequiredArgsConstructor
@CrossOrigin(origins = "http://localhost:4200")
public class ShopDocumentController {

    private final ShopDocumentService documentService;

    @GetMapping("/shop/{shopId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<List<ShopDocumentResponse>> getShopDocuments(@PathVariable Long shopId) {
        List<ShopDocumentResponse> documents = documentService.getShopDocuments(shopId);
        return ResponseEntity.ok(documents);
    }

    @PostMapping("/shop/{shopId}/upload")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<?> uploadDocument(
            @PathVariable Long shopId,
            @RequestParam("documentType") ShopDocument.DocumentType documentType,
            @RequestParam("documentName") String documentName,
            @RequestParam("file") MultipartFile file) {
        
        try {
            ShopDocumentResponse response = documentService.uploadDocument(
                    shopId, documentType, documentName, file);
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

    @PutMapping("/{documentId}/verify")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ShopDocumentResponse> verifyDocument(
            @PathVariable Long documentId,
            @Valid @RequestBody DocumentVerificationRequest request,
            Principal principal) {
        
        ShopDocumentResponse response = documentService.verifyDocument(
                documentId, request, principal.getName());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{documentId}/download")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Resource> downloadDocument(@PathVariable Long documentId) {
        try {
            Resource resource = documentService.downloadDocument(documentId);
            
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType("application/octet-stream"))
                    .header(HttpHeaders.CONTENT_DISPOSITION, 
                            "attachment; filename=\"" + resource.getFilename() + "\"")
                    .body(resource);
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{documentId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> deleteDocument(@PathVariable Long documentId) {
        try {
            documentService.deleteDocument(documentId);
            return ResponseEntity.ok(Map.of("message", "Document deleted successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Failed to delete document"));
        }
    }

    @GetMapping("/types")
    public ResponseEntity<Map<String, Object>> getDocumentTypes() {
        return ResponseEntity.ok(Map.of(
                "documentTypes", ShopDocument.DocumentType.values(),
                "verificationStatuses", ShopDocument.VerificationStatus.values()
        ));
    }
}