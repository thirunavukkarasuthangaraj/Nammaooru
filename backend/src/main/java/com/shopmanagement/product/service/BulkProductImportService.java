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
     * Standard Column Mapping (0-indexed):
     * A(0):  name           - Product name (required)
     * B(1):  nameTamil      - Tamil name
     * C(2):  description    - Product description
     * D(3):  category       - Category name (auto-created if not exists)
     * E(4):  brand          - Brand name
     * F(5):  sku            - SKU code (used to find existing products)
     * G(6):  (SKIP)         - Search Query
     * H(7):  (SKIP)         - Download Link
     * I(8):  baseUnit       - Unit of measurement (kg, piece, etc.)
     * J(9):  baseWeight     - Weight value
     * K(10): originalPrice  - MRP/Original price
     * L(11): sellingPrice   - Selling price
     * M(12): discountPct    - Discount percentage
     * N(13): costPrice      - Cost price
     * O(14): stockQuantity  - Current stock
     * P(15): minStockLevel  - Minimum stock alert level
     * Q(16): maxStockLevel  - Maximum stock level
     * R(17): trackInventory - Track inventory (TRUE/FALSE)
     * S(18): status         - ACTIVE/INACTIVE
     * T(19): isFeatured     - Featured product (TRUE/FALSE)
     * U(20): isAvailable    - Available for sale (TRUE/FALSE)
     * V(21): (SKIP)         - Reserved/Empty
     * W(22): tags           - Comma-separated tags
     * X(23): specifications - Product specifications
     * Y(24): imagePath      - Image filename (e.g., product.jpg)
     * Z(25): imageFolder    - Subfolder under /uploads/products/master/
     */
    private BulkImportRequest parseRow(Row row, int rowNumber) {
        String categoryName = getCellValueAsString(row.getCell(3));  // D: Category
        Long categoryId = lookupCategoryByName(categoryName);

        String name = getCellValueAsString(row.getCell(0));          // A: Item Name
        String tags = getCellValueAsString(row.getCell(22));         // W: tags
        String imagePath = getCellValueAsString(row.getCell(24));    // Y: imagePath
        String imageFolder = getCellValueAsString(row.getCell(25));  // Z: imageFolder

        log.info("parseRow #{}: name='{}', category='{}', imagePath='{}'", rowNumber, name, categoryName, imagePath);

        return BulkImportRequest.builder()
                .rowNumber(rowNumber)
                .name(name)                                                    // A(0)
                .nameTamil(getCellValueAsString(row.getCell(1)))              // B(1)
                .description(getCellValueAsString(row.getCell(2)))            // C(2)
                .categoryId(categoryId)                                        // D(3)
                .brand(getCellValueAsString(row.getCell(4)))                  // E(4)
                .sku(getCellValueAsString(row.getCell(5)))                    // F(5)
                .baseUnit(getCellValueAsString(row.getCell(8)))               // I(8)
                .baseWeight(getCellValueAsBigDecimal(row.getCell(9)))         // J(9)
                .originalPrice(getCellValueAsBigDecimal(row.getCell(10)))     // K(10)
                .sellingPrice(getCellValueAsBigDecimal(row.getCell(11)))      // L(11)
                .discountPercentage(getCellValueAsBigDecimal(row.getCell(12)))// M(12)
                .costPrice(getCellValueAsBigDecimal(row.getCell(13)))         // N(13)
                .stockQuantity(getCellValueAsInteger(row.getCell(14)))        // O(14)
                .minStockLevel(getCellValueAsInteger(row.getCell(15)))        // P(15)
                .maxStockLevel(getCellValueAsInteger(row.getCell(16)))        // Q(16)
                .trackInventory(getCellValueAsBoolean(row.getCell(17)))       // R(17)
                .status(getCellValueAsString(row.getCell(18)))                // S(18)
                .isFeatured(getCellValueAsBoolean(row.getCell(19)))           // T(19)
                .isAvailable(getCellValueAsBoolean(row.getCell(20)))          // U(20)
                .tags(tags)                                                    // W(22)
                .specifications(getCellValueAsString(row.getCell(23)))        // X(23)
                .imagePath(imagePath)                                          // Y(24)
                .imageFolder(imageFolder)                                      // Z(25)
                .barcode(null)
                .build();
    }

    /**
     * Look up category ID by category name, auto-create if not found
     * NEVER returns null - always returns a valid category ID
     */
    private Long lookupCategoryByName(String categoryName) {
        try {
            if (categoryName == null || categoryName.trim().isEmpty()) {
                log.warn("Category name is empty, using default category");
                return getOrCreateDefaultCategory();
            }

            String trimmedName = categoryName.trim();

            // Try case-insensitive lookup first
            Optional<ProductCategory> category = productCategoryRepository.findByNameIgnoreCase(trimmedName);
            if (category.isPresent()) {
                log.info("Found category '{}' with ID: {}", trimmedName, category.get().getId());
                return category.get().getId();
            }

            // Auto-create category if it doesn't exist
            log.info("Category '{}' not found, auto-creating...", trimmedName);
            String slug = trimmedName.toLowerCase()
                    .replaceAll("[^a-z0-9\\s-]", "")
                    .replaceAll("\\s+", "-")
                    .replaceAll("-+", "-");

            // Ensure slug is unique
            String baseSlug = slug;
            int counter = 1;
            while (productCategoryRepository.existsBySlug(slug)) {
                slug = baseSlug + "-" + counter;
                counter++;
            }

            ProductCategory newCategory = ProductCategory.builder()
                    .name(trimmedName)
                    .slug(slug)
                    .description(trimmedName)
                    .isActive(true)
                    .sortOrder(0)
                    .createdBy("BULK_IMPORT")
                    .updatedBy("BULK_IMPORT")
                    .build();
            ProductCategory saved = productCategoryRepository.save(newCategory);
            log.info("Category auto-created with ID: {}", saved.getId());
            return saved.getId();
        } catch (Exception e) {
            log.error("Error looking up/creating category '{}': {}", categoryName, e.getMessage(), e);
            // FALLBACK: Never return null - use default category
            return getOrCreateDefaultCategory();
        }
    }

    /**
     * Get or create a default "Uncategorized" category - guaranteed to return a valid ID
     */
    private Long getOrCreateDefaultCategory() {
        try {
            Optional<ProductCategory> defaultCat = productCategoryRepository.findByNameIgnoreCase("Uncategorized");
            if (defaultCat.isPresent()) {
                return defaultCat.get().getId();
            }

            // Create default category
            ProductCategory newCategory = ProductCategory.builder()
                    .name("Uncategorized")
                    .slug("uncategorized-" + System.currentTimeMillis())
                    .description("Uncategorized products")
                    .isActive(true)
                    .sortOrder(999)
                    .createdBy("BULK_IMPORT")
                    .updatedBy("BULK_IMPORT")
                    .build();
            ProductCategory saved = productCategoryRepository.save(newCategory);
            log.info("Default 'Uncategorized' category created with ID: {}", saved.getId());
            return saved.getId();
        } catch (Exception e) {
            log.error("CRITICAL: Failed to create default category: {}", e.getMessage(), e);
            // Last resort - try to find ANY category
            List<ProductCategory> anyCategory = productCategoryRepository.findAll();
            if (!anyCategory.isEmpty()) {
                log.warn("Using first available category as fallback: {}", anyCategory.get(0).getName());
                return anyCategory.get(0).getId();
            }
            throw new RuntimeException("No categories available and cannot create one. Please create at least one category first.");
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

            // Handle image upload - use masterProduct.getId() NOT shopProduct.getId()
            String imageStatus = "No image";
            if (request.getImagePath() != null && !request.getImagePath().isEmpty()) {
                imageStatus = handleImageUpload(masterProduct.getId(), request.getImagePath(),
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
     *
     * For BULK IMPORT/UPDATE:
     * - If image already exists with same URL, ensure it's set as primary
     * - If new image, set as primary and demote existing primary
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
                imageUrl = "/uploads/products/master/" + imagePath.trim();
            } else {
                // Images in subfolder under products/master
                imageFolderPath = Paths.get(productImagesPath, "master", folder);
                imageUrl = "/uploads/products/master/" + folder + "/" + imagePath.trim();
            }

            Path imageFilePath = imageFolderPath.resolve(imagePath.trim());

            // Check if image file exists (for logging only, don't block save)
            boolean fileExists = Files.exists(imageFilePath);
            if (!fileExists) {
                log.warn("Image file not found at: {} (path will be saved anyway)", imageFilePath);
            }

            // Get reference to master product
            MasterProduct masterProduct = masterProductRepository.getReferenceById(productId);

            // Check if this exact image URL already exists for this product
            Optional<MasterProductImage> existingImage = masterProductImageRepository
                    .findByMasterProductIdAndImageUrl(productId, imageUrl);

            if (existingImage.isPresent()) {
                // Image already exists - make sure it's set as primary
                MasterProductImage img = existingImage.get();
                if (!Boolean.TRUE.equals(img.getIsPrimary())) {
                    // Clear all primary flags for this product
                    masterProductImageRepository.clearPrimaryForProduct(productId);
                    img.setIsPrimary(true);
                    masterProductImageRepository.save(img);
                    log.info("Existing image set as primary for product {}: {}", productId, imageUrl);
                    return "Updated to primary: " + imageUrl;
                }
                return "Already primary: " + imageUrl;
            }

            // New image - clear existing primary and add this as primary
            masterProductImageRepository.clearPrimaryForProduct(productId);

            long existingImageCount = masterProductImageRepository.countByMasterProductId(productId);

            // Create and save new image record as PRIMARY
            MasterProductImage productImage = MasterProductImage.builder()
                    .masterProduct(masterProduct)
                    .imageUrl(imageUrl)
                    .altText(imagePath.trim())
                    .isPrimary(true)  // Always primary for bulk import
                    .sortOrder(0)     // Primary image at top
                    .createdBy("BULK_IMPORT")
                    .build();

            masterProductImageRepository.save(productImage);

            String status = fileExists ? "Linked as primary" : "Linked as primary (file not found)";
            log.info("Image saved for product {}: {} - {}", productId, imageUrl, status);
            return status + ": " + imageUrl;

        } catch (Exception e) {
            log.error("Error handling image for product {}: {}", productId, e.getMessage(), e);
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
