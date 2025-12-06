package com.shopmanagement.product.service;

import com.shopmanagement.product.dto.*;
import com.shopmanagement.product.entity.MasterProduct;
import com.shopmanagement.product.entity.MasterProductImage;
import com.shopmanagement.product.entity.ProductCategory;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.product.repository.MasterProductImageRepository;
import com.shopmanagement.product.repository.MasterProductRepository;
import com.shopmanagement.product.repository.ProductCategoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class BulkProductImportService {

    private final MasterProductService masterProductService;
    private final ShopProductService shopProductService;
    private final MasterProductRepository masterProductRepository;
    private final MasterProductImageRepository masterProductImageRepository;
    private final ProductCategoryRepository productCategoryRepository;

    @Value("${app.upload.dir}")
    private String uploadDir;

    @Value("${app.upload.product-images}")
    private String productImagesPath;

    /**
     * Import products from Excel for shop owners
     */
    public BulkImportResponse importProductsForShop(Long shopId, MultipartFile excelFile,
                                                     List<MultipartFile> images) {
        log.info("Starting bulk import for shop: {}", shopId);

        BulkImportResponse response = BulkImportResponse.builder()
                .totalRows(0)
                .successCount(0)
                .failureCount(0)
                .results(new ArrayList<>())
                .build();

        try {
            List<BulkImportRequest> requests = parseExcelFile(excelFile);
            response.setTotalRows(requests.size());

            for (BulkImportRequest request : requests) {
                BulkImportResponse.ImportResult result = processShopProductImport(shopId, request, images);
                response.addResult(result);

                if ("SUCCESS".equals(result.getStatus())) {
                    response.setSuccessCount(response.getSuccessCount() + 1);
                } else {
                    response.setFailureCount(response.getFailureCount() + 1);
                }
            }

            response.setMessage(String.format(
                    "Import completed. Total: %d, Success: %d, Failed: %d",
                    response.getTotalRows(), response.getSuccessCount(), response.getFailureCount()
            ));

        } catch (Exception e) {
            log.error("Error during bulk import for shop: {}", shopId, e);
            response.setMessage("Import failed: " + e.getMessage());
        }

        return response;
    }

    /**
     * Import master products (admin only)
     */
    public BulkImportResponse importMasterProducts(MultipartFile excelFile, List<MultipartFile> images) {
        log.info("Starting bulk master product import");

        BulkImportResponse response = BulkImportResponse.builder()
                .totalRows(0)
                .successCount(0)
                .failureCount(0)
                .results(new ArrayList<>())
                .build();

        try {
            List<BulkImportRequest> requests = parseExcelFile(excelFile);
            response.setTotalRows(requests.size());

            for (BulkImportRequest request : requests) {
                BulkImportResponse.ImportResult result = processMasterProductImport(request, images);
                response.addResult(result);

                if ("SUCCESS".equals(result.getStatus())) {
                    response.setSuccessCount(response.getSuccessCount() + 1);
                } else {
                    response.setFailureCount(response.getFailureCount() + 1);
                }
            }

            response.setMessage(String.format(
                    "Import completed. Total: %d, Success: %d, Failed: %d",
                    response.getTotalRows(), response.getSuccessCount(), response.getFailureCount()
            ));

        } catch (Exception e) {
            log.error("Error during master product bulk import", e);
            response.setMessage("Import failed: " + e.getMessage());
        }

        return response;
    }

    /**
     * Parse Excel file and extract product data
     */
    private List<BulkImportRequest> parseExcelFile(MultipartFile file) throws IOException {
        List<BulkImportRequest> requests = new ArrayList<>();

        try (InputStream inputStream = file.getInputStream();
             Workbook workbook = new XSSFWorkbook(inputStream)) {

            Sheet sheet = workbook.getSheetAt(0);
            int rowNum = 0;

            for (Row row : sheet) {
                // Skip header row
                if (rowNum == 0) {
                    rowNum++;
                    continue;
                }

                // Skip empty rows
                if (isRowEmpty(row)) {
                    continue;
                }

                BulkImportRequest request = parseRow(row, rowNum);
                requests.add(request);
                rowNum++;
            }
        }

        return requests;
    }

    /**
     * Parse a single row from Excel
     * Column mapping matches the actual Excel file structure (WITH Search Query and Download Link):
     * A: name, B: nameTamil, C: description, D: descriptionTamil, E: categoryName, F: brand, G: sku,
     * H: Search Query (SKIP), I: Download Link (SKIP), J: baseUnit, K: baseWeight, L: originalPrice,
     * M: sellingPrice, N: discountPercentage, O: costPrice, P: stockQuantity, Q: minStockLevel,
     * R: maxStockLevel, S: trackInventory, T: status, U: isFeatured, V: isAvailable, W: tags,
     * X: specifications, Y: imagePath, Z: imageFolder
     */
    private BulkImportRequest parseRow(Row row, int rowNumber) {
        String categoryName = getCellValueAsString(row.getCell(4));  // Column E (0-indexed as 4)
        Long categoryId = null;
        if (categoryName != null && !categoryName.isEmpty()) {
            categoryId = lookupCategoryByName(categoryName);
        }

        // Read all values
        String name = getCellValueAsString(row.getCell(0));
        String tags = getCellValueAsString(row.getCell(22));  // Fixed: Column W (index 22)

        // Log each row with key values
        log.info("parseRow #{}: name='{}', categoryId={}, tags='{}'", rowNumber, name, categoryId, tags);

        return BulkImportRequest.builder()
                .rowNumber(rowNumber)
                // Column 0 (A): Product Name
                .name(name)
                // Column 1 (B): Product Name (Tamil)
                .nameTamil(getCellValueAsString(row.getCell(1)))
                // Column 2 (C): Description
                .description(getCellValueAsString(row.getCell(2)))
                // Column 3 (D): Description (Tamil) - stored but not used
                // Column 4 (E): Category Name (looked up to get ID)
                .categoryId(categoryId)
                // Column 5 (F): Brand
                .brand(getCellValueAsString(row.getCell(5)))
                // Column 6 (G): SKU
                .sku(getCellValueAsString(row.getCell(6)))
                // Column 7 (H): Search Query (SKIP - not used)
                // Column 8 (I): Download Link (SKIP - not used)
                // Column 9 (J): Base Unit (e.g., kg, pieces, liters)
                .baseUnit(getCellValueAsString(row.getCell(9)))
                // Column 10 (K): Base Weight
                .baseWeight(getCellValueAsBigDecimal(row.getCell(10)))
                // Column 11 (L): Original Price (MRP)
                .originalPrice(getCellValueAsBigDecimal(row.getCell(11)))
                // Column 12 (M): Selling Price
                .sellingPrice(getCellValueAsBigDecimal(row.getCell(12)))
                // Column 13 (N): Discount Percentage
                .discountPercentage(getCellValueAsBigDecimal(row.getCell(13)))
                // Column 14 (O): Cost Price
                .costPrice(getCellValueAsBigDecimal(row.getCell(14)))
                // Column 15 (P): Stock Quantity
                .stockQuantity(getCellValueAsInteger(row.getCell(15)))
                // Column 16 (Q): Min Stock Level
                .minStockLevel(getCellValueAsInteger(row.getCell(16)))
                // Column 17 (R): Max Stock Level
                .maxStockLevel(getCellValueAsInteger(row.getCell(17)))
                // Column 18 (S): Track Inventory (true/false)
                .trackInventory(getCellValueAsBoolean(row.getCell(18)))
                // Column 19 (T): Status (ACTIVE, INACTIVE, etc.)
                .status(getCellValueAsString(row.getCell(19)))
                // Column 20 (U): Is Featured
                .isFeatured(getCellValueAsBoolean(row.getCell(20)))
                // Column 21 (V): Is Available
                .isAvailable(getCellValueAsBoolean(row.getCell(21)))
                // Column 22 (W): Tags (comma-separated)
                .tags(tags)
                // Column 23 (X): Specifications
                .specifications(getCellValueAsString(row.getCell(23)))
                // Column 24 (Y): Image Path (filename)
                .imagePath(getCellValueAsString(row.getCell(24)))
                // Column 25 (Z): Image Folder (subfolder name, optional)
                .imageFolder(getCellValueAsString(row.getCell(25)))
                // Note: barcode field removed as column H is now Search Query
                .barcode(null)
                .build();
    }

    /**
     * Look up category ID by category name, auto-create if not found
     */
    private Long lookupCategoryByName(String categoryName) {
        try {
            Optional<ProductCategory> category = productCategoryRepository.findByName(categoryName);
            if (category.isPresent()) {
                return category.get().getId();
            }

            // Auto-create category if it doesn't exist
            log.info("Category '{}' not found, auto-creating...", categoryName);
            ProductCategory newCategory = ProductCategory.builder()
                    .name(categoryName)
                    .slug(categoryName.toLowerCase().replaceAll("\\s+", "-"))
                    .description(categoryName)
                    .isActive(true)
                    .sortOrder(0)
                    .createdBy("BULK_IMPORT")
                    .updatedBy("BULK_IMPORT")
                    .build();
            ProductCategory saved = productCategoryRepository.save(newCategory);
            log.info("Category auto-created with ID: {}", saved.getId());
            return saved.getId();
        } catch (Exception e) {
            log.error("Error looking up/creating category '{}': {}", categoryName, e.getMessage());
            return null;
        }
    }

    /**
     * Process shop product import with independent transaction
     * Uses REQUIRES_NEW so each product import can succeed/fail independently
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public BulkImportResponse.ImportResult processShopProductImport(Long shopId,
                                                                       BulkImportRequest request,
                                                                       List<MultipartFile> images) {
        try {
            // First, check if master product exists or create it
            MasterProductRequest masterProductRequest = buildMasterProductRequest(request);
            MasterProductResponse masterProduct;

            try {
                // Try to find existing master product by SKU
                if (request.getSku() != null && !request.getSku().isEmpty()) {
                    masterProduct = masterProductService.getProductBySku(request.getSku());
                } else {
                    // Create new master product
                    masterProduct = masterProductService.createProduct(masterProductRequest);
                }
            } catch (Exception e) {
                // Master product doesn't exist, create it
                masterProduct = masterProductService.createProduct(masterProductRequest);
            }

            // Create shop product
            ShopProductRequest shopProductRequest = buildShopProductRequest(request, masterProduct.getId());
            ShopProductResponse shopProduct = shopProductService.addProductToShop(shopId, shopProductRequest);

            // Handle image upload
            String imageStatus = "No image";
            if (request.getImagePath() != null && !request.getImagePath().isEmpty()) {
                imageStatus = handleImageUpload(shopProduct.getId(), request.getImagePath(),
                                                request.getImageFolder(), images);
            }

            return BulkImportResponse.ImportResult.builder()
                    .rowNumber(request.getRowNumber())
                    .productName(request.getName())
                    .status("SUCCESS")
                    .message("Product imported successfully")
                    .productId(shopProduct.getId())
                    .imageUploadStatus(imageStatus)
                    .build();

        } catch (Exception e) {
            log.error("Error importing product at row {}: {}", request.getRowNumber(), e.getMessage());
            return BulkImportResponse.ImportResult.builder()
                    .rowNumber(request.getRowNumber())
                    .productName(request.getName())
                    .status("FAILED")
                    .message("Import failed: " + e.getMessage())
                    .build();
        }
    }

    /**
     * Process master product import with independent transaction
     * Uses REQUIRES_NEW so each product import can succeed/fail independently
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public BulkImportResponse.ImportResult processMasterProductImport(BulkImportRequest request,
                                                                         List<MultipartFile> images) {
        try {
            MasterProductRequest masterProductRequest = buildMasterProductRequest(request);
            MasterProductResponse masterProduct = masterProductService.createProduct(masterProductRequest);

            // Handle image upload
            String imageStatus = "No image";
            if (request.getImagePath() != null && !request.getImagePath().isEmpty()) {
                imageStatus = handleImageUpload(masterProduct.getId(), request.getImagePath(),
                                                request.getImageFolder(), images);
            }

            return BulkImportResponse.ImportResult.builder()
                    .rowNumber(request.getRowNumber())
                    .productName(request.getName())
                    .status("SUCCESS")
                    .message("Master product created successfully")
                    .productId(masterProduct.getId())
                    .imageUploadStatus(imageStatus)
                    .build();

        } catch (Exception e) {
            log.error("Error importing master product at row {}: {}", request.getRowNumber(), e.getMessage());
            return BulkImportResponse.ImportResult.builder()
                    .rowNumber(request.getRowNumber())
                    .productName(request.getName())
                    .status("FAILED")
                    .message("Import failed: " + e.getMessage())
                    .build();
        }
    }

    /**
     * Build MasterProductRequest from BulkImportRequest
     */
    private MasterProductRequest buildMasterProductRequest(BulkImportRequest request) {
        MasterProduct.ProductStatus status = MasterProduct.ProductStatus.ACTIVE;
        if (request.getStatus() != null) {
            try {
                status = MasterProduct.ProductStatus.valueOf(request.getStatus().toUpperCase());
            } catch (IllegalArgumentException e) {
                log.warn("Invalid status: {}, using ACTIVE", request.getStatus());
            }
        }

        log.info("buildMasterProductRequest: name='{}', tags='{}' -> preparing to save", request.getName(), request.getTags());

        return MasterProductRequest.builder()
                .name(request.getName())
                .nameTamil(request.getNameTamil())
                .description(request.getDescription())
                .sku(request.getSku())
                .barcode(request.getBarcode())
                .categoryId(request.getCategoryId())
                .brand(request.getBrand())
                .baseUnit(request.getBaseUnit())
                .baseWeight(request.getBaseWeight())
                .specifications(request.getSpecifications())
                .tags(request.getTags())
                .status(status)
                .isFeatured(request.getIsFeatured() != null ? request.getIsFeatured() : false)
                .isGlobal(request.getIsGlobal() != null ? request.getIsGlobal() : true)
                .build();
    }

    /**
     * Build ShopProductRequest from BulkImportRequest
     */
    private ShopProductRequest buildShopProductRequest(BulkImportRequest request, Long masterProductId) {
        // Calculate price if discount is provided
        BigDecimal sellingPrice = request.getSellingPrice();
        if (sellingPrice == null && request.getOriginalPrice() != null && request.getDiscountPercentage() != null) {
            BigDecimal discount = request.getOriginalPrice()
                    .multiply(request.getDiscountPercentage())
                    .divide(BigDecimal.valueOf(100));
            sellingPrice = request.getOriginalPrice().subtract(discount);
        }

        ShopProduct.ShopProductStatus status = ShopProduct.ShopProductStatus.ACTIVE;
        if (request.getShopProductStatus() != null) {
            try {
                status = ShopProduct.ShopProductStatus.valueOf(request.getShopProductStatus().toUpperCase());
            } catch (IllegalArgumentException e) {
                log.warn("Invalid shop product status: {}, using ACTIVE", request.getShopProductStatus());
            }
        }

        return ShopProductRequest.builder()
                .masterProductId(masterProductId)
                .price(sellingPrice)
                .originalPrice(request.getOriginalPrice())
                .costPrice(request.getCostPrice())
                .stockQuantity(request.getStockQuantity() != null ? request.getStockQuantity() : 0)
                .minStockLevel(request.getMinStockLevel())
                .maxStockLevel(request.getMaxStockLevel())
                .trackInventory(request.getTrackInventory() != null ? request.getTrackInventory() : true)
                .status(status)
                .isAvailable(request.getIsAvailable() != null ? request.getIsAvailable() : true)
                .isFeatured(request.getIsFeatured() != null ? request.getIsFeatured() : false)
                .customName(request.getCustomName())
                .customDescription(request.getCustomDescription())
                .tags(request.getTags())
                .build();
    }

    /**
     * Handle image upload for master product
     * Reads image from pre-copied folder structure: master/products/{folder}/{imageName}
     * Saves image reference to master_product_images table
     */
    private String handleImageUpload(Long productId, String imagePath, String imageFolder,
                                     List<MultipartFile> images) {
        try {
            if (imagePath == null || imagePath.trim().isEmpty()) {
                return "No image specified";
            }

            // Build the expected folder path: products/master/{folder}/ or products/master/
            String folder = imageFolder != null && !imageFolder.trim().isEmpty()
                            ? imageFolder.trim()
                            : "";

            // productImagesPath is absolute path like: D:/AAWS/nammaooru/uploads/products
            // We need to look in: D:/AAWS/nammaooru/uploads/products/master/{imagePath}
            Path imageFolderPath;
            String imageUrl;

            if (folder.isEmpty()) {
                // Images directly under products/master folder
                imageFolderPath = Paths.get(productImagesPath, "master");
                imageUrl = "/uploads/products/master/" + imagePath;
            } else {
                // Images in subfolder under products/master
                imageFolderPath = Paths.get(productImagesPath, "master", folder);
                imageUrl = "/uploads/products/master/" + folder + "/" + imagePath;
            }

            Path imageFilePath = imageFolderPath.resolve(imagePath.trim());

            // Check if image file exists (for logging only, don't block save)
            boolean fileExists = Files.exists(imageFilePath);
            if (!fileExists) {
                log.warn("Image file not found at: {} (path will be saved anyway)", imageFilePath);
            }

            // Get the master product
            MasterProduct masterProduct = masterProductRepository.findById(productId)
                    .orElseThrow(() -> new RuntimeException("Product not found"));

            // Check if this image already exists for this product
            long existingImageCount = masterProductImageRepository.countByMasterProductId(productId);
            boolean isPrimary = (existingImageCount == 0); // First image is primary

            // Create and save image record (even if file doesn't exist yet)
            MasterProductImage productImage = MasterProductImage.builder()
                    .masterProduct(masterProduct)
                    .imageUrl(imageUrl)
                    .altText(masterProduct.getName())
                    .isPrimary(isPrimary)
                    .sortOrder((int) existingImageCount)
                    .createdBy("BULK_IMPORT")
                    .build();

            masterProductImageRepository.save(productImage);

            String status = fileExists ? "Linked" : "Linked (file not found)";
            log.info("Image reference saved for product {}: {} - {}", productId, imageUrl, status);
            return status + ": " + imageUrl;

        } catch (Exception e) {
            log.error("Error handling image for product {}: {}", productId, e.getMessage());
            return "Image link failed: " + e.getMessage();
        }
    }

    /**
     * Find image file from uploaded files by name
     */
    private MultipartFile findImageFile(String imagePath, List<MultipartFile> images) {
        if (images == null || images.isEmpty()) {
            return null;
        }

        for (MultipartFile image : images) {
            if (image.getOriginalFilename().equals(imagePath)) {
                return image;
            }
        }
        return null;
    }

    // Helper methods for cell value extraction

    private String getCellValueAsString(Cell cell) {
        if (cell == null) {
            return null;
        }

        switch (cell.getCellType()) {
            case STRING:
                return cell.getStringCellValue().trim();
            case NUMERIC:
                return String.valueOf((long) cell.getNumericCellValue());
            case BOOLEAN:
                return String.valueOf(cell.getBooleanCellValue());
            case FORMULA:
                return cell.getCellFormula();
            default:
                return null;
        }
    }

    private Long getCellValueAsLong(Cell cell) {
        if (cell == null) {
            return null;
        }

        try {
            if (cell.getCellType() == CellType.NUMERIC) {
                return (long) cell.getNumericCellValue();
            } else if (cell.getCellType() == CellType.STRING) {
                String value = cell.getStringCellValue().trim();
                return value.isEmpty() ? null : Long.parseLong(value);
            }
        } catch (Exception e) {
            log.warn("Error parsing Long value from cell: {}", e.getMessage());
        }
        return null;
    }

    private Integer getCellValueAsInteger(Cell cell) {
        if (cell == null) {
            return null;
        }

        try {
            if (cell.getCellType() == CellType.NUMERIC) {
                return (int) cell.getNumericCellValue();
            } else if (cell.getCellType() == CellType.STRING) {
                String value = cell.getStringCellValue().trim();
                return value.isEmpty() ? null : Integer.parseInt(value);
            }
        } catch (Exception e) {
            log.warn("Error parsing Integer value from cell: {}", e.getMessage());
        }
        return null;
    }

    private BigDecimal getCellValueAsBigDecimal(Cell cell) {
        if (cell == null) {
            return null;
        }

        try {
            if (cell.getCellType() == CellType.NUMERIC) {
                return BigDecimal.valueOf(cell.getNumericCellValue());
            } else if (cell.getCellType() == CellType.STRING) {
                String value = cell.getStringCellValue().trim();
                return value.isEmpty() ? null : new BigDecimal(value);
            }
        } catch (Exception e) {
            log.warn("Error parsing BigDecimal value from cell: {}", e.getMessage());
        }
        return null;
    }

    private Boolean getCellValueAsBoolean(Cell cell) {
        if (cell == null) {
            return null;
        }

        try {
            if (cell.getCellType() == CellType.BOOLEAN) {
                return cell.getBooleanCellValue();
            } else if (cell.getCellType() == CellType.STRING) {
                String value = cell.getStringCellValue().trim().toLowerCase();
                return "true".equals(value) || "yes".equals(value) || "1".equals(value);
            } else if (cell.getCellType() == CellType.NUMERIC) {
                return cell.getNumericCellValue() != 0;
            }
        } catch (Exception e) {
            log.warn("Error parsing Boolean value from cell: {}", e.getMessage());
        }
        return false;
    }

    private boolean isRowEmpty(Row row) {
        if (row == null) {
            return true;
        }

        for (int cellNum = row.getFirstCellNum(); cellNum < row.getLastCellNum(); cellNum++) {
            Cell cell = row.getCell(cellNum);
            if (cell != null && cell.getCellType() != CellType.BLANK) {
                return false;
            }
        }
        return true;
    }
}
