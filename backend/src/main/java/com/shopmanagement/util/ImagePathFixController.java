package com.shopmanagement.util;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/fix-images")
@RequiredArgsConstructor
@Slf4j
public class ImagePathFixController {

    private final JdbcTemplate jdbcTemplate;

    @PostMapping
    public Map<String, Object> fixImagePaths() {
        log.info("Starting image path fix...");

        try {
            // Fix shop product images with /opt/ paths
            int shopOptFixed = jdbcTemplate.update(
                "UPDATE shop_product_images " +
                "SET image_url = REPLACE(image_url, '/opt/shop-management/uploads/', '/uploads/') " +
                "WHERE image_url LIKE '/opt/shop-management/uploads/%'"
            );

            // Fix shop product images with /app/ paths
            int shopAppFixed = jdbcTemplate.update(
                "UPDATE shop_product_images " +
                "SET image_url = REPLACE(image_url, '/app/uploads/', '/uploads/') " +
                "WHERE image_url LIKE '/app/uploads/%'"
            );

            // Fix master product images with /opt/ paths
            int masterOptFixed = jdbcTemplate.update(
                "UPDATE master_product_images " +
                "SET image_url = REPLACE(image_url, '/opt/shop-management/uploads/', '/uploads/') " +
                "WHERE image_url LIKE '/opt/shop-management/uploads/%'"
            );

            // Fix master product images with /app/ paths
            int masterAppFixed = jdbcTemplate.update(
                "UPDATE master_product_images " +
                "SET image_url = REPLACE(image_url, '/app/uploads/', '/uploads/') " +
                "WHERE image_url LIKE '/app/uploads/%'"
            );

            // Count fixed images
            Integer shopImageCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM shop_product_images WHERE image_url LIKE '/uploads/products/%'",
                Integer.class
            );

            Integer masterImageCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM master_product_images WHERE image_url LIKE '/uploads/products/%'",
                Integer.class
            );

            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("shopImagesFixed", shopOptFixed + shopAppFixed);
            result.put("masterImagesFixed", masterOptFixed + masterAppFixed);
            result.put("totalShopImages", shopImageCount);
            result.put("totalMasterImages", masterImageCount);
            result.put("message", "Image paths have been normalized successfully!");

            log.info("Image path fix completed: Shop={}, Master={}",
                shopOptFixed + shopAppFixed, masterOptFixed + masterAppFixed);

            return result;

        } catch (Exception e) {
            log.error("Error fixing image paths", e);
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("error", e.getMessage());
            return error;
        }
    }
}
