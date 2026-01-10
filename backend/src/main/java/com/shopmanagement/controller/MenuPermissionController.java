package com.shopmanagement.controller;

import com.shopmanagement.entity.Permission;
import com.shopmanagement.service.MenuPermissionService;
import com.shopmanagement.service.MenuPermissionService.UserMenuPermissionDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Slf4j
@RestController
@RequestMapping("/api/menu-permissions")
@RequiredArgsConstructor
public class MenuPermissionController {

    private final MenuPermissionService menuPermissionService;

    /**
     * Get all available menu permissions (for super admin UI)
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> getAllMenuPermissions() {
        log.info("Fetching all menu permissions");
        List<Permission> permissions = menuPermissionService.getAllMenuPermissions();

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("data", permissions);
        response.put("message", "Menu permissions fetched successfully");

        return ResponseEntity.ok(response);
    }

    /**
     * Get current user's menu permissions
     */
    @GetMapping("/my-permissions")
    public ResponseEntity<Map<String, Object>> getMyMenuPermissions() {
        log.info("Fetching current user's menu permissions");
        Set<String> permissions = menuPermissionService.getCurrentUserMenuPermissions();

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("data", permissions);
        response.put("message", "User menu permissions fetched successfully");

        return ResponseEntity.ok(response);
    }

    /**
     * Get menu permissions for a specific user (super admin only)
     */
    @GetMapping("/user/{userId}")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> getUserMenuPermissions(@PathVariable Long userId) {
        log.info("Fetching menu permissions for user: {}", userId);
        Set<String> permissions = menuPermissionService.getUserMenuPermissions(userId);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("data", permissions);
        response.put("message", "User menu permissions fetched successfully");

        return ResponseEntity.ok(response);
    }

    /**
     * Update menu permissions for a user (super admin only)
     */
    @PutMapping("/user/{userId}")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> updateUserMenuPermissions(
            @PathVariable Long userId,
            @RequestBody UpdatePermissionsRequest request) {
        log.info("Updating menu permissions for user: {}", userId);
        menuPermissionService.updateUserMenuPermissions(userId, request.permissionIds());

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Menu permissions updated successfully");

        return ResponseEntity.ok(response);
    }

    /**
     * Add a single menu permission to a user
     */
    @PostMapping("/user/{userId}/add")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> addMenuPermission(
            @PathVariable Long userId,
            @RequestBody PermissionNameRequest request) {
        log.info("Adding menu permission {} to user: {}", request.permissionName(), userId);
        menuPermissionService.addMenuPermission(userId, request.permissionName());

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Menu permission added successfully");

        return ResponseEntity.ok(response);
    }

    /**
     * Remove a single menu permission from a user
     */
    @PostMapping("/user/{userId}/remove")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> removeMenuPermission(
            @PathVariable Long userId,
            @RequestBody PermissionNameRequest request) {
        log.info("Removing menu permission {} from user: {}", request.permissionName(), userId);
        menuPermissionService.removeMenuPermission(userId, request.permissionName());

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "Menu permission removed successfully");

        return ResponseEntity.ok(response);
    }

    /**
     * Grant all menu permissions to a user
     */
    @PostMapping("/user/{userId}/grant-all")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> grantAllMenuPermissions(@PathVariable Long userId) {
        log.info("Granting all menu permissions to user: {}", userId);
        menuPermissionService.grantAllMenuPermissions(userId);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "All menu permissions granted successfully");

        return ResponseEntity.ok(response);
    }

    /**
     * Revoke all menu permissions from a user
     */
    @PostMapping("/user/{userId}/revoke-all")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> revokeAllMenuPermissions(@PathVariable Long userId) {
        log.info("Revoking all menu permissions from user: {}", userId);
        menuPermissionService.revokeAllMenuPermissions(userId);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("message", "All menu permissions revoked successfully");

        return ResponseEntity.ok(response);
    }

    /**
     * Get all shop owners with their menu permissions (for super admin management UI)
     */
    @GetMapping("/shop-owners")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> getAllShopOwnersWithPermissions() {
        log.info("Fetching all shop owners with menu permissions");
        List<UserMenuPermissionDto> shopOwners = menuPermissionService.getAllShopOwnersWithPermissions();

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("data", shopOwners);
        response.put("message", "Shop owners with permissions fetched successfully");

        return ResponseEntity.ok(response);
    }

    /**
     * Check if a user has a specific menu permission
     */
    @GetMapping("/user/{userId}/check/{permissionName}")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> checkMenuPermission(
            @PathVariable Long userId,
            @PathVariable String permissionName) {
        log.info("Checking menu permission {} for user: {}", permissionName, userId);
        boolean hasPermission = menuPermissionService.hasMenuPermission(userId, permissionName);

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", "0000");
        response.put("data", hasPermission);
        response.put("message", hasPermission ? "User has permission" : "User does not have permission");

        return ResponseEntity.ok(response);
    }

    // Request DTOs
    public record UpdatePermissionsRequest(Set<Long> permissionIds) {}
    public record PermissionNameRequest(String permissionName) {}
}
