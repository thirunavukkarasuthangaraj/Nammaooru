package com.shopmanagement.product.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.product.dto.BulkImportResponse;
import com.shopmanagement.product.service.BulkProductImportService;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.service.ShopService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/products/bulk-import")
@RequiredArgsConstructor
@Slf4j
public class BulkProductImportController {

    private final BulkProductImportService bulkProductImportService;
    private final ShopService shopService;

    /**
     * Super Admin - Import Master Products from Excel with images
     * Images are stored in the master catalog and organized by folder
     */
    @PostMapping(value = "/master", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<BulkImportResponse>> importMasterProducts(
            @RequestParam("file") MultipartFile excelFile,
            @RequestParam(value = "images", required = false) List<MultipartFile> images) {

        log.info("Super Admin importing master products from Excel");

        try {
            // Validate Excel file
            if (excelFile.isEmpty()) {
                return ResponseEntity.badRequest().body(ApiResponse.error("Excel file is required"));
            }

            String filename = excelFile.getOriginalFilename();
            if (filename == null || !filename.endsWith(".xlsx")) {
                return ResponseEntity.badRequest().body(ApiResponse.error(
                        "Invalid file format. Please upload an Excel file (.xlsx)"
                ));
            }

            // Process import
            BulkImportResponse response = bulkProductImportService.importMasterProducts(
                    excelFile,
                    images != null ? images : new ArrayList<>()
            );

            if (response.getSuccessCount() > 0) {
                return ResponseEntity.ok(ApiResponse.success(
                        response,
                        "Master products imported successfully"
                ));
            } else {
                return ResponseEntity.status(HttpStatus.PARTIAL_CONTENT).body(ApiResponse.<BulkImportResponse>builder()
                        .statusCode("PARTIAL")
                        .message("No products were imported successfully. Check the error details.")
                        .data(response)
                        .build()
                );
            }

        } catch (Exception e) {
            log.error("Error during master product bulk import", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                    ApiResponse.error("Import failed: " + e.getMessage())
            );
        }
    }

    /**
     * Shop Owner - Import products to their shop from Excel
     * References master products and sets shop-specific pricing
     */
    @PostMapping(value = "/shop-products", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('SHOP_OWNER') or hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<BulkImportResponse>> importShopProducts(
            @RequestParam("file") MultipartFile excelFile,
            @RequestParam(value = "images", required = false) List<MultipartFile> images) {

        log.info("Shop owner importing products from Excel");

        try {
            // Get current user's shop
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String currentUsername = authentication.getName();

            Shop currentShop = shopService.getShopByOwner(currentUsername);
            if (currentShop == null) {
                return ResponseEntity.badRequest().body(ApiResponse.error(
                        "No shop found for current user. Please ensure you have a shop registered."
                ));
            }

            // Validate Excel file
            if (excelFile.isEmpty()) {
                return ResponseEntity.badRequest().body(ApiResponse.error("Excel file is required"));
            }

            String filename = excelFile.getOriginalFilename();
            if (filename == null || !filename.endsWith(".xlsx")) {
                return ResponseEntity.badRequest().body(ApiResponse.error(
                        "Invalid file format. Please upload an Excel file (.xlsx)"
                ));
            }

            // Process import
            BulkImportResponse response = bulkProductImportService.importProductsForShop(
                    currentShop.getId(),
                    excelFile,
                    images != null ? images : new ArrayList<>()
            );

            if (response.getSuccessCount() > 0) {
                return ResponseEntity.ok(ApiResponse.success(
                        response,
                        "Products imported successfully to your shop"
                ));
            } else {
                return ResponseEntity.status(HttpStatus.PARTIAL_CONTENT).body(ApiResponse.<BulkImportResponse>builder()
                        .statusCode("PARTIAL")
                        .message("No products were imported successfully. Check the error details.")
                        .data(response)
                        .build()
                );
            }

        } catch (Exception e) {
            log.error("Error during shop product bulk import", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                    ApiResponse.error("Import failed: " + e.getMessage())
            );
        }
    }

    /**
     * Get Excel template information
     */
    @GetMapping("/template-info")
    public ResponseEntity<ApiResponse<TemplateInfo>> getTemplateInfo(
            @RequestParam(required = false, defaultValue = "master") String type) {

        TemplateInfo info = new TemplateInfo();
        info.setType(type);

        if ("master".equalsIgnoreCase(type)) {
            info.setDescription("Template for importing Master Products (Super Admin only)");
            info.setColumns(getMasterProductColumns());
        } else {
            info.setDescription("Template for importing Shop Products");
            info.setColumns(getShopProductColumns());
        }

        return ResponseEntity.ok(ApiResponse.success(info, "Template information retrieved"));
    }

    private List<ColumnInfo> getMasterProductColumns() {
        List<ColumnInfo> columns = new ArrayList<>();
        columns.add(new ColumnInfo("A", "name", "Product Name", "string", true, "Example: Fresh Tomatoes"));
        columns.add(new ColumnInfo("B", "description", "Description", "string", false, "Product description"));
        columns.add(new ColumnInfo("C", "categoryId", "Category ID", "number", true, "1, 2, 3, etc."));
        columns.add(new ColumnInfo("D", "brand", "Brand", "string", false, "Brand name"));
        columns.add(new ColumnInfo("E", "sku", "SKU", "string", false, "Auto-generated if empty"));
        columns.add(new ColumnInfo("F", "barcode", "Barcode", "string", false, "Product barcode"));
        columns.add(new ColumnInfo("G", "baseUnit", "Base Unit", "string", false, "kg, pieces, liters"));
        columns.add(new ColumnInfo("H", "baseWeight", "Base Weight", "number", false, "1, 0.5, 2"));
        columns.add(new ColumnInfo("I", "originalPrice", "Original Price (MRP)", "number", false, "100.00"));
        columns.add(new ColumnInfo("J", "sellingPrice", "Selling Price", "number", false, "90.00"));
        columns.add(new ColumnInfo("K", "discountPercentage", "Discount %", "number", false, "10"));
        columns.add(new ColumnInfo("L", "costPrice", "Cost Price", "number", false, "80.00"));
        columns.add(new ColumnInfo("M", "stockQuantity", "Stock Quantity", "number", false, "100"));
        columns.add(new ColumnInfo("N", "minStockLevel", "Min Stock", "number", false, "10"));
        columns.add(new ColumnInfo("O", "maxStockLevel", "Max Stock", "number", false, "500"));
        columns.add(new ColumnInfo("P", "trackInventory", "Track Inventory", "boolean", false, "TRUE/FALSE"));
        columns.add(new ColumnInfo("Q", "status", "Status", "string", false, "ACTIVE, INACTIVE"));
        columns.add(new ColumnInfo("R", "isFeatured", "Is Featured", "boolean", false, "TRUE/FALSE"));
        columns.add(new ColumnInfo("S", "isAvailable", "Is Available", "boolean", false, "TRUE/FALSE"));
        columns.add(new ColumnInfo("T", "tags", "Tags", "string", false, "organic,fresh,local"));
        columns.add(new ColumnInfo("U", "specifications", "Specifications", "string", false, "Additional specs"));
        columns.add(new ColumnInfo("V", "imagePath", "Image Filename", "string", false, "tomato.jpg"));
        columns.add(new ColumnInfo("W", "imageFolder", "Image Folder", "string", false, "vegetables"));
        return columns;
    }

    private List<ColumnInfo> getShopProductColumns() {
        List<ColumnInfo> columns = new ArrayList<>();
        columns.add(new ColumnInfo("A", "name", "Product Name", "string", true, "Example: Fresh Tomatoes"));
        columns.add(new ColumnInfo("B", "description", "Description", "string", false, "Product description"));
        columns.add(new ColumnInfo("C", "categoryId", "Category ID", "number", true, "1, 2, 3, etc."));
        columns.add(new ColumnInfo("D", "brand", "Brand", "string", false, "Brand name"));
        columns.add(new ColumnInfo("E", "sku", "SKU", "string", false, "Master product SKU"));
        columns.add(new ColumnInfo("I", "originalPrice", "Original Price (MRP)", "number", true, "100.00"));
        columns.add(new ColumnInfo("J", "sellingPrice", "Selling Price", "number", true, "90.00"));
        columns.add(new ColumnInfo("K", "discountPercentage", "Discount %", "number", false, "10"));
        columns.add(new ColumnInfo("L", "costPrice", "Cost Price", "number", false, "80.00"));
        columns.add(new ColumnInfo("M", "stockQuantity", "Stock Quantity", "number", false, "100"));
        columns.add(new ColumnInfo("N", "minStockLevel", "Min Stock", "number", false, "10"));
        columns.add(new ColumnInfo("O", "maxStockLevel", "Max Stock", "number", false, "500"));
        columns.add(new ColumnInfo("P", "trackInventory", "Track Inventory", "boolean", false, "TRUE/FALSE"));
        columns.add(new ColumnInfo("S", "isAvailable", "Is Available", "boolean", false, "TRUE/FALSE"));
        columns.add(new ColumnInfo("T", "tags", "Tags", "string", false, "organic,fresh,local"));
        return columns;
    }

    // DTOs for template info
    @lombok.Data
    public static class TemplateInfo {
        private String type;
        private String description;
        private List<ColumnInfo> columns;
    }

    @lombok.Data
    @lombok.AllArgsConstructor
    public static class ColumnInfo {
        private String column;
        private String fieldName;
        private String displayName;
        private String dataType;
        private Boolean required;
        private String example;
    }
}
