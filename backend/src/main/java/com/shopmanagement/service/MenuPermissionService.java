package com.shopmanagement.service;

import com.shopmanagement.entity.Permission;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.PermissionRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class MenuPermissionService {

    private final UserRepository userRepository;
    private final PermissionRepository permissionRepository;

    private static final String MENU_PERMISSION_CATEGORY = "SHOP_OWNER_MENU";

    /**
     * Get all available menu permissions for shop owners
     */
    public List<Permission> getAllMenuPermissions() {
        return permissionRepository.findByCategory(MENU_PERMISSION_CATEGORY);
    }

    /**
     * Get menu permissions for a specific user
     */
    public Set<String> getUserMenuPermissions(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));

        if (user.getPermissions() == null) {
            return new HashSet<>();
        }

        return user.getPermissions().stream()
                .filter(p -> MENU_PERMISSION_CATEGORY.equals(p.getCategory()))
                .map(Permission::getName)
                .collect(Collectors.toSet());
    }

    /**
     * Get menu permissions for current logged-in user
     */
    public Set<String> getCurrentUserMenuPermissions() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getName() == null) {
            return new HashSet<>();
        }

        User user = userRepository.findByUsername(auth.getName())
                .orElse(null);

        if (user == null) {
            return new HashSet<>();
        }

        // Super admin and admin have all menu access
        if (user.getRole() == User.UserRole.SUPER_ADMIN || user.getRole() == User.UserRole.ADMIN) {
            return getAllMenuPermissions().stream()
                    .map(Permission::getName)
                    .collect(Collectors.toSet());
        }

        if (user.getPermissions() == null) {
            return new HashSet<>();
        }

        return user.getPermissions().stream()
                .filter(p -> MENU_PERMISSION_CATEGORY.equals(p.getCategory()))
                .map(Permission::getName)
                .collect(Collectors.toSet());
    }

    /**
     * Update menu permissions for a user (Super Admin only)
     */
    @Transactional
    public void updateUserMenuPermissions(Long userId, Set<Long> permissionIds) {
        log.info("Updating menu permissions for user: {}", userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));

        // Get existing non-menu permissions
        Set<Permission> existingNonMenuPermissions = user.getPermissions() != null
                ? user.getPermissions().stream()
                    .filter(p -> !MENU_PERMISSION_CATEGORY.equals(p.getCategory()))
                    .collect(Collectors.toSet())
                : new HashSet<>();

        // Get new menu permissions from IDs
        Set<Permission> newMenuPermissions = new HashSet<>();
        if (permissionIds != null && !permissionIds.isEmpty()) {
            List<Permission> permissions = permissionRepository.findByIdIn(permissionIds);
            newMenuPermissions = permissions.stream()
                    .filter(p -> MENU_PERMISSION_CATEGORY.equals(p.getCategory()))
                    .collect(Collectors.toSet());
        }

        // Combine non-menu permissions with new menu permissions
        Set<Permission> allPermissions = new HashSet<>(existingNonMenuPermissions);
        allPermissions.addAll(newMenuPermissions);

        user.setPermissions(allPermissions);
        user.setUpdatedBy(getCurrentUsername());

        userRepository.save(user);
        log.info("Menu permissions updated for user: {} - permissions: {}", userId,
                newMenuPermissions.stream().map(Permission::getName).collect(Collectors.joining(", ")));
    }

    /**
     * Add a single menu permission to a user
     */
    @Transactional
    public void addMenuPermission(Long userId, String permissionName) {
        log.info("Adding menu permission {} to user: {}", permissionName, userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));

        Permission permission = permissionRepository.findByName(permissionName)
                .orElseThrow(() -> new RuntimeException("Permission not found: " + permissionName));

        if (!MENU_PERMISSION_CATEGORY.equals(permission.getCategory())) {
            throw new RuntimeException("Permission is not a menu permission: " + permissionName);
        }

        if (user.getPermissions() == null) {
            user.setPermissions(new HashSet<>());
        }

        user.getPermissions().add(permission);
        user.setUpdatedBy(getCurrentUsername());

        userRepository.save(user);
        log.info("Menu permission {} added to user: {}", permissionName, userId);
    }

    /**
     * Remove a single menu permission from a user
     */
    @Transactional
    public void removeMenuPermission(Long userId, String permissionName) {
        log.info("Removing menu permission {} from user: {}", permissionName, userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));

        if (user.getPermissions() != null) {
            user.getPermissions().removeIf(p -> permissionName.equals(p.getName()));
            user.setUpdatedBy(getCurrentUsername());
            userRepository.save(user);
        }

        log.info("Menu permission {} removed from user: {}", permissionName, userId);
    }

    /**
     * Grant all menu permissions to a user
     */
    @Transactional
    public void grantAllMenuPermissions(Long userId) {
        log.info("Granting all menu permissions to user: {}", userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));

        List<Permission> allMenuPermissions = permissionRepository.findByCategory(MENU_PERMISSION_CATEGORY);

        if (user.getPermissions() == null) {
            user.setPermissions(new HashSet<>());
        }

        user.getPermissions().addAll(allMenuPermissions);
        user.setUpdatedBy(getCurrentUsername());

        userRepository.save(user);
        log.info("All menu permissions granted to user: {}", userId);
    }

    /**
     * Revoke all menu permissions from a user
     */
    @Transactional
    public void revokeAllMenuPermissions(Long userId) {
        log.info("Revoking all menu permissions from user: {}", userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));

        if (user.getPermissions() != null) {
            user.getPermissions().removeIf(p -> MENU_PERMISSION_CATEGORY.equals(p.getCategory()));
            user.setUpdatedBy(getCurrentUsername());
            userRepository.save(user);
        }

        log.info("All menu permissions revoked from user: {}", userId);
    }

    /**
     * Check if a user has a specific menu permission
     */
    public boolean hasMenuPermission(Long userId, String permissionName) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null || user.getPermissions() == null) {
            return false;
        }

        // Super admin and admin have all permissions
        if (user.getRole() == User.UserRole.SUPER_ADMIN || user.getRole() == User.UserRole.ADMIN) {
            return true;
        }

        return user.getPermissions().stream()
                .anyMatch(p -> permissionName.equals(p.getName()));
    }

    /**
     * Get all shop owners with their menu permissions
     */
    public List<UserMenuPermissionDto> getAllShopOwnersWithPermissions() {
        List<User> shopOwners = userRepository.findByRole(User.UserRole.SHOP_OWNER);
        List<Permission> allMenuPermissions = permissionRepository.findByCategory(MENU_PERMISSION_CATEGORY);

        return shopOwners.stream()
                .map(user -> {
                    Set<String> userMenuPermissions = user.getPermissions() != null
                            ? user.getPermissions().stream()
                                .filter(p -> MENU_PERMISSION_CATEGORY.equals(p.getCategory()))
                                .map(Permission::getName)
                                .collect(Collectors.toSet())
                            : new HashSet<>();

                    return new UserMenuPermissionDto(
                            user.getId(),
                            user.getUsername(),
                            user.getFullName(),
                            user.getEmail(),
                            userMenuPermissions,
                            allMenuPermissions.stream()
                                .map(Permission::getName)
                                .collect(Collectors.toList())
                    );
                })
                .collect(Collectors.toList());
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null ? authentication.getName() : "system";
    }

    // DTO for returning user with menu permissions
    public record UserMenuPermissionDto(
            Long userId,
            String username,
            String fullName,
            String email,
            Set<String> menuPermissions,
            List<String> allAvailablePermissions
    ) {}
}
