package com.shopmanagement.product.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.product.dto.ProductCategoryRequest;
import com.shopmanagement.product.dto.ProductCategoryResponse;
import com.shopmanagement.product.service.ProductCategoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.InetAddress;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/products/categories")
@RequiredArgsConstructor
@Slf4j
public class ProductCategoryController {

    private final ProductCategoryService categoryService;

    @Value("${app.upload.dir:./uploads}")
    private String uploadDir;

    private static final long MAX_DOWNLOAD_IMAGE_BYTES = 8L * 1024 * 1024;

    private static final HttpClient IMAGE_HTTP_CLIENT = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    @GetMapping
    public ResponseEntity<ApiResponse<Page<ProductCategoryResponse>>> getAllCategories(
            @RequestParam(required = false) Long parentId,
            @RequestParam(required = false) Boolean isActive,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String sortDirection) {

        log.info("Fetching categories - page: {}, size: {}, parentId: {}", page, size, parentId);

        // ALWAYS sort by sortOrder first (ascending), then by name (ascending)
        // This ensures categories appear in priority order regardless of frontend request
        Pageable pageable = PageRequest.of(page, size,
            Sort.by(Sort.Order.asc("sortOrder"), Sort.Order.asc("name")));

        Page<ProductCategoryResponse> categories = categoryService.getCategories(
                parentId, isActive, search, pageable);

        return ResponseEntity.ok(ApiResponse.success(categories, "Categories fetched successfully"));
    }

    @GetMapping("/uncategorized-count")
    public ResponseEntity<ApiResponse<Long>> getUncategorizedProductCount() {
        return ResponseEntity.ok(ApiResponse.success(
                categoryService.getUncategorizedProductCount(),
                "Uncategorized product count fetched successfully"));
    }

    @GetMapping("/tree")
    public ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> getCategoryTree(
            @RequestParam(required = false) Long rootId,
            @RequestParam(defaultValue = "true") Boolean activeOnly) {
        log.info("Fetching category tree - rootId: {}, activeOnly: {}", rootId, activeOnly);
        List<ProductCategoryResponse> tree = categoryService.getCategoryTree(rootId, activeOnly);
        return ResponseEntity.ok(ApiResponse.success(tree, "Category tree fetched successfully"));
    }

    @GetMapping("/root")
    public ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> getRootCategories(
            @RequestParam(defaultValue = "true") Boolean activeOnly) {
        log.info("Fetching root categories - activeOnly: {}", activeOnly);
        List<ProductCategoryResponse> categories = categoryService.getRootCategories(activeOnly);
        return ResponseEntity.ok(ApiResponse.success(categories, "Root categories fetched successfully"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> getCategoryById(@PathVariable Long id) {
        log.info("Fetching category by ID: {}", id);
        ProductCategoryResponse category = categoryService.getCategoryById(id);
        return ResponseEntity.ok(ApiResponse.success(category, "Category fetched successfully"));
    }

    @GetMapping("/slug/{slug}")
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> getCategoryBySlug(@PathVariable String slug) {
        log.info("Fetching category by slug: {}", slug);
        ProductCategoryResponse category = categoryService.getCategoryBySlug(slug);
        return ResponseEntity.ok(ApiResponse.success(category, "Category fetched successfully"));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> createCategory(
            @Valid @RequestBody ProductCategoryRequest request) {
        log.info("Creating category: {}", request.getName());
        ProductCategoryResponse category = categoryService.createCategory(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(category, "Category created successfully"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> updateCategory(
            @PathVariable Long id,
            @Valid @RequestBody ProductCategoryRequest request) {
        log.info("Updating category: {}", id);
        ProductCategoryResponse category = categoryService.updateCategory(id, request);
        return ResponseEntity.ok(ApiResponse.success(category, "Category updated successfully"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteCategory(@PathVariable Long id) {
        log.info("Deleting category: {}", id);
        categoryService.deleteCategory(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Category deleted successfully"));
    }

    @GetMapping("/{id}/subcategories")
    public ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> getSubcategories(
            @PathVariable Long id,
            @RequestParam(defaultValue = "true") Boolean activeOnly) {
        log.info("Fetching subcategories for category: {}", id);
        List<ProductCategoryResponse> subcategories = categoryService.getSubcategories(id, activeOnly);
        return ResponseEntity.ok(ApiResponse.success(subcategories, "Subcategories fetched successfully"));
    }

    @GetMapping("/{id}/path")
    public ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> getCategoryPath(@PathVariable Long id) {
        log.info("Fetching category path for: {}", id);
        List<ProductCategoryResponse> path = categoryService.getCategoryPath(id);
        return ResponseEntity.ok(ApiResponse.success(path, "Category path fetched successfully"));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> updateCategoryStatus(
            @PathVariable Long id,
            @RequestParam Boolean isActive) {
        log.info("Updating category status: {} - active: {}", id, isActive);
        ProductCategoryResponse category = categoryService.updateCategoryStatus(id, isActive);
        return ResponseEntity.ok(ApiResponse.success(category, "Category status updated successfully"));
    }

    @PatchMapping("/reorder")
    public ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> reorderCategories(
            @RequestBody List<Long> categoryIds) {
        log.info("Reordering categories: {}", categoryIds.size());
        List<ProductCategoryResponse> categories = categoryService.reorderCategories(categoryIds);
        return ResponseEntity.ok(ApiResponse.success(categories, "Categories reordered successfully"));
    }

    @PostMapping(value = "/with-image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> createCategoryWithImage(
            @RequestParam("name") String name,
            @RequestParam(value = "nameTamil", required = false) String nameTamil,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "parentId", required = false) Long parentId,
            @RequestParam(value = "image", required = false) MultipartFile imageFile) {

        log.info("Creating category with image: {}", name);

        try {
            // Create category request
            ProductCategoryRequest request = ProductCategoryRequest.builder()
                    .name(name)
                    .nameTamil(nameTamil)
                    .description(description)
                    .parentId(parentId)
                    .isActive(true)
                    .build();

            // Handle image upload if provided
            if (imageFile != null && !imageFile.isEmpty()) {
                String imageUrl = saveImage(imageFile);
                request.setIconUrl(imageUrl);
            }

            ProductCategoryResponse category = categoryService.createCategory(request);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success(category, "Category created successfully with image"));
        } catch (IOException e) {
            log.error("Error uploading image: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Failed to upload image"));
        }
    }

    @PostMapping("/{id}/image")
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> uploadCategoryImage(
            @PathVariable Long id,
            @RequestParam("image") MultipartFile imageFile) {

        log.info("Uploading image for category: {}", id);

        try {
            if (imageFile.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Please select an image file"));
            }

            String imageUrl = saveImage(imageFile);
            ProductCategoryResponse category = categoryService.updateCategoryImage(id, imageUrl);

            return ResponseEntity.ok(ApiResponse.success(category, "Image uploaded successfully"));
        } catch (IOException e) {
            log.error("Error uploading image: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Failed to upload image"));
        }
    }

    private String saveImage(MultipartFile file) throws IOException {
        // Use the configured upload directory
        String categoryUploadDir = uploadDir + "/categories";
        Path uploadPath = Paths.get(categoryUploadDir);

        if (!Files.exists(uploadPath)) {
            Files.createDirectories(uploadPath);
        }

        // Generate unique filename
        String originalFilename = file.getOriginalFilename();
        String extension = originalFilename != null ?
                originalFilename.substring(originalFilename.lastIndexOf(".")) : ".jpg";
        String filename = UUID.randomUUID().toString() + extension;

        // Save file
        Path filePath = uploadPath.resolve(filename);
        Files.copy(file.getInputStream(), filePath);

        // Return the URL path
        return "/uploads/categories/" + filename;
    }

    /**
     * Download an image from a URL (picked in the image search dialog) and
     * store it as the category's icon - same "search & pick" flow as the
     * bulk-edit product image picker, applied to category images.
     */
    @PostMapping("/{id}/image-from-url")
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> uploadCategoryImageFromUrl(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {

        String sourceUrl = body != null ? body.get("url") : null;
        if (sourceUrl == null || !(sourceUrl.startsWith("http://") || sourceUrl.startsWith("https://"))) {
            return ResponseEntity.badRequest().body(ApiResponse.error("A valid image URL is required"));
        }

        try {
            URI uri = URI.create(sourceUrl);
            // Block SSRF against internal hosts
            InetAddress address = InetAddress.getByName(uri.getHost());
            if (address.isLoopbackAddress() || address.isSiteLocalAddress()
                    || address.isLinkLocalAddress() || address.isAnyLocalAddress()) {
                return ResponseEntity.badRequest().body(ApiResponse.error("URL not allowed"));
            }

            HttpRequest request = HttpRequest.newBuilder(uri)
                    .timeout(Duration.ofSeconds(15))
                    .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0 Safari/537.36")
                    .header("Accept", "image/*,*/*;q=0.8")
                    .GET()
                    .build();
            HttpResponse<byte[]> response = IMAGE_HTTP_CLIENT.send(request, HttpResponse.BodyHandlers.ofByteArray());

            if (response.statusCode() != 200 || response.body() == null || response.body().length == 0) {
                return ResponseEntity.badRequest().body(ApiResponse.error(
                        "Could not download image (HTTP " + response.statusCode() + ")"));
            }
            byte[] bytes = response.body();
            if (bytes.length > MAX_DOWNLOAD_IMAGE_BYTES) {
                return ResponseEntity.badRequest().body(ApiResponse.error("Image is too large (max 8MB)"));
            }

            String contentType = response.headers().firstValue("Content-Type").orElse("image/jpeg");
            int semicolon = contentType.indexOf(';');
            if (semicolon > 0) {
                contentType = contentType.substring(0, semicolon).trim();
            }
            if (!contentType.startsWith("image/")) {
                return ResponseEntity.badRequest().body(ApiResponse.error("URL is not an image"));
            }
            String extension = switch (contentType) {
                case "image/png" -> "png";
                case "image/webp" -> "webp";
                case "image/gif" -> "gif";
                default -> "jpg";
            };

            String imageUrl = saveImageBytes(bytes, extension);
            ProductCategoryResponse category = categoryService.updateCategoryImage(id, imageUrl);

            return ResponseEntity.ok(ApiResponse.success(category, "Image updated successfully"));
        } catch (IOException | InterruptedException e) {
            log.error("Failed to download category image from URL: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Could not download this image - try another one"));
        }
    }

    private String saveImageBytes(byte[] bytes, String extension) throws IOException {
        String categoryUploadDir = uploadDir + "/categories";
        Path uploadPath = Paths.get(categoryUploadDir);

        if (!Files.exists(uploadPath)) {
            Files.createDirectories(uploadPath);
        }

        String filename = UUID.randomUUID() + "." + extension;
        Path filePath = uploadPath.resolve(filename);
        Files.write(filePath, bytes);

        return "/uploads/categories/" + filename;
    }
}
