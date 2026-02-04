package com.shopmanagement.dto.user;

import com.shopmanagement.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Set;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserResponse {
    
    private Long id;
    private String username;
    private String email;
    private String firstName;
    private String lastName;
    private String fullName;
    private String mobileNumber;
    private User.UserRole role;
    private User.UserStatus status;
    private String profileImageUrl;
    private LocalDateTime lastLogin;
    private Integer failedLoginAttempts;
    private LocalDateTime accountLockedUntil;
    private Boolean emailVerified;
    private Boolean mobileVerified;
    private Boolean twoFactorEnabled;
    private String department;
    private String designation;
    private Long reportsTo;
    private String reportsToName;
    private Set<PermissionResponse> permissions;
    private Boolean isActive;
    private Boolean isTemporaryPassword;
    private Boolean passwordChangeRequired;
    private LocalDateTime lastPasswordChange;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String createdBy;
    private String updatedBy;
    
    // Shop-specific driver assignment (driver can serve multiple shops)
    private Set<Long> assignedShopIds;

    // Helper fields
    private String roleLabel;
    private String statusLabel;
    private boolean isLocked;
    private boolean isAdmin;
    private String accountAge;
    private String lastLoginFormatted;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class PermissionResponse {
        private Long id;
        private String name;
        private String description;
        private String category;
        private String resourceType;
        private String actionType;
    }
}