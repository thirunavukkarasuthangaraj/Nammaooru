package com.shopmanagement.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/admin/fix")
@RequiredArgsConstructor
@CrossOrigin(originPatterns = {"*"}, allowCredentials = "false")
public class DataFixController {

    private final JdbcTemplate jdbcTemplate;

    @PostMapping("/track-inventory")
    public ResponseEntity<Map<String, Object>> fixTrackInventory() {
        try {
            String sql = "UPDATE shop_products SET track_inventory = true WHERE track_inventory IS NULL";
            int updated = jdbcTemplate.update(sql);
            
            log.info("Fixed track_inventory for {} shop products", updated);
            
            return ResponseEntity.ok(Map.of(
                "status", "success",
                "message", "Fixed track_inventory for " + updated + " products",
                "updatedCount", updated
            ));
        } catch (Exception e) {
            log.error("Failed to fix track_inventory", e);
            return ResponseEntity.badRequest().body(Map.of(
                "status", "error",
                "message", "Failed to fix track_inventory: " + e.getMessage()
            ));
        }
    }

    @PostMapping("/user-shop-linkage")
    public ResponseEntity<Map<String, Object>> fixUserShopLinkage() {
        try {
            // Add user_id column to shops table if not exists
            String alterTableSql = """
                ALTER TABLE shops 
                ADD COLUMN IF NOT EXISTS user_id BIGINT,
                ADD CONSTRAINT IF NOT EXISTS fk_shops_user_id 
                FOREIGN KEY (user_id) REFERENCES users(id)
                """;
            
            try {
                jdbcTemplate.execute(alterTableSql);
            } catch (Exception e) {
                log.info("user_id column might already exist: " + e.getMessage());
            }
            
            // Link existing shops to users based on owner_email
            String linkSql = """
                UPDATE shops 
                SET user_id = (
                    SELECT u.id 
                    FROM users u 
                    WHERE u.email = shops.owner_email
                )
                WHERE user_id IS NULL 
                AND owner_email IN (SELECT email FROM users)
                """;
            
            int linked = jdbcTemplate.update(linkSql);
            
            log.info("Linked {} shops to users", linked);
            
            return ResponseEntity.ok(Map.of(
                "status", "success", 
                "message", "Linked " + linked + " shops to users",
                "linkedCount", linked
            ));
        } catch (Exception e) {
            log.error("Failed to fix user-shop linkage", e);
            return ResponseEntity.badRequest().body(Map.of(
                "status", "error",
                "message", "Failed to fix user-shop linkage: " + e.getMessage()
            ));
        }
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getFixStatus() {
        try {
            // Check track_inventory issues
            String nullTrackSql = "SELECT COUNT(*) FROM shop_products WHERE track_inventory IS NULL";
            Integer nullTrackCount = jdbcTemplate.queryForObject(nullTrackSql, Integer.class);
            
            // Check user-shop linkage
            String unlinkedShopsSql = "SELECT COUNT(*) FROM shops WHERE user_id IS NULL";
            Integer unlinkedShopsCount = jdbcTemplate.queryForObject(unlinkedShopsSql, Integer.class);
            
            // Check total shops and products
            String totalShopsSql = "SELECT COUNT(*) FROM shops";
            Integer totalShops = jdbcTemplate.queryForObject(totalShopsSql, Integer.class);
            
            String totalProductsSql = "SELECT COUNT(*) FROM shop_products";
            Integer totalProducts = jdbcTemplate.queryForObject(totalProductsSql, Integer.class);
            
            return ResponseEntity.ok(Map.of(
                "status", "success",
                "data", Map.of(
                    "nullTrackInventoryCount", nullTrackCount,
                    "unlinkedShopsCount", unlinkedShopsCount,
                    "totalShops", totalShops,
                    "totalProducts", totalProducts,
                    "needsTrackInventoryFix", nullTrackCount > 0,
                    "needsUserShopLinkageFix", unlinkedShopsCount > 0
                )
            ));
        } catch (Exception e) {
            log.error("Failed to get fix status", e);
            return ResponseEntity.badRequest().body(Map.of(
                "status", "error",
                "message", "Failed to get fix status: " + e.getMessage()
            ));
        }
    }
}