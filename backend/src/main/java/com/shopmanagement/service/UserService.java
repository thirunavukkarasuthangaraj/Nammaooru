package com.shopmanagement.service;

import com.shopmanagement.dto.user.UserRequest;
import com.shopmanagement.dto.user.UserUpdateRequest;
import com.shopmanagement.dto.user.UserResponse;
import com.shopmanagement.entity.Permission;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.PermissionRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {
    
    private final UserRepository userRepository;
    private final PermissionRepository permissionRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    
    @Transactional
    public UserResponse createUser(UserRequest request) {
        log.info("Creating user: {}", request.getUsername());
        
        // Check if username or email already exists
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("Username already exists: " + request.getUsername());
        }
        
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already exists: " + request.getEmail());
        }
        
        // Get permissions if specified
        Set<Permission> permissions = null;
        if (request.getPermissionIds() != null && !request.getPermissionIds().isEmpty()) {
            permissions = permissionRepository.findByIdIn(request.getPermissionIds())
                    .stream().collect(Collectors.toSet());
        }
        
        // Create user
        User user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .mobileNumber(request.getMobileNumber())
                .role(request.getRole())
                .status(request.getStatus() != null ? request.getStatus() : User.UserStatus.ACTIVE)
                .profileImageUrl(request.getProfileImageUrl())
                .department(request.getDepartment())
                .designation(request.getDesignation())
                .reportsTo(request.getReportsTo())
                .permissions(permissions)
                .emailVerified(request.getEmailVerified() != null ? request.getEmailVerified() : false)
                .mobileVerified(request.getMobileVerified() != null ? request.getMobileVerified() : false)
                .twoFactorEnabled(request.getTwoFactorEnabled() != null ? request.getTwoFactorEnabled() : false)
                .passwordChangeRequired(request.getPasswordChangeRequired() != null ? request.getPasswordChangeRequired() : false)
                .isTemporaryPassword(true)
                .lastPasswordChange(LocalDateTime.now())
                .createdBy(getCurrentUsername())
                .updatedBy(getCurrentUsername())
                .build();
        
        User savedUser = userRepository.save(user);
        
        // Send welcome email
        try {
            emailService.sendWelcomeEmail(savedUser.getEmail(), savedUser.getFullName(), savedUser.getUsername());
        } catch (Exception e) {
            log.error("Failed to send welcome email to user: {}", savedUser.getUsername(), e);
        }
        
        log.info("User created successfully: {}", savedUser.getUsername());
        return mapToResponse(savedUser);
    }
    
    public UserResponse getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
        return mapToResponse(user);
    }
    
    public UserResponse getUserByUsername(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found with username: " + username));
        return mapToResponse(user);
    }
    
    public UserResponse getUserByEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found with email: " + email));
        return mapToResponse(user);
    }
    
    @Transactional
    public UserResponse updateUser(Long id, UserRequest request) {
        log.info("Updating user: {}", id);
        
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
        
        // Check if username or email changed and already exists
        if (!user.getUsername().equals(request.getUsername()) && 
            userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("Username already exists: " + request.getUsername());
        }
        
        if (!user.getEmail().equals(request.getEmail()) && 
            userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already exists: " + request.getEmail());
        }
        
        // Update permissions if specified
        if (request.getPermissionIds() != null) {
            Set<Permission> permissions = permissionRepository.findByIdIn(request.getPermissionIds())
                    .stream().collect(Collectors.toSet());
            user.setPermissions(permissions);
        }
        
        // Update user fields
        user.setUsername(request.getUsername());
        user.setEmail(request.getEmail());
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setMobileNumber(request.getMobileNumber());
        user.setRole(request.getRole());
        if (request.getStatus() != null) {
            user.setStatus(request.getStatus());
        }
        user.setProfileImageUrl(request.getProfileImageUrl());
        user.setDepartment(request.getDepartment());
        user.setDesignation(request.getDesignation());
        user.setReportsTo(request.getReportsTo());
        if (request.getEmailVerified() != null) {
            user.setEmailVerified(request.getEmailVerified());
        }
        if (request.getMobileVerified() != null) {
            user.setMobileVerified(request.getMobileVerified());
        }
        if (request.getTwoFactorEnabled() != null) {
            user.setTwoFactorEnabled(request.getTwoFactorEnabled());
        }
        if (request.getPasswordChangeRequired() != null) {
            user.setPasswordChangeRequired(request.getPasswordChangeRequired());
        }
        user.setUpdatedBy(getCurrentUsername());
        
        // Update password if provided
        if (request.getPassword() != null && !request.getPassword().trim().isEmpty()) {
            user.setPassword(passwordEncoder.encode(request.getPassword()));
            user.setIsTemporaryPassword(true);
            user.setPasswordChangeRequired(true);
            user.setLastPasswordChange(LocalDateTime.now());
        }
        
        User updatedUser = userRepository.save(user);
        log.info("User updated successfully: {}", updatedUser.getUsername());
        return mapToResponse(updatedUser);
    }
    
    @Transactional
    public UserResponse updateUser(Long id, UserUpdateRequest request) {
        log.info("Updating user with UserUpdateRequest: {}", id);
        
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
        
        // Only update fields that are provided (not null)
        if (request.getUsername() != null && !user.getUsername().equals(request.getUsername()) && 
            userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("Username already exists: " + request.getUsername());
        }
        
        if (request.getEmail() != null && !user.getEmail().equals(request.getEmail()) && 
            userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already exists: " + request.getEmail());
        }
        
        // Update permissions if specified
        if (request.getPermissionIds() != null) {
            Set<Permission> permissions = permissionRepository.findByIdIn(request.getPermissionIds())
                    .stream().collect(Collectors.toSet());
            user.setPermissions(permissions);
        }
        
        // Update user fields only if provided
        if (request.getUsername() != null) user.setUsername(request.getUsername());
        if (request.getEmail() != null) user.setEmail(request.getEmail());
        if (request.getFirstName() != null) user.setFirstName(request.getFirstName());
        if (request.getLastName() != null) user.setLastName(request.getLastName());
        if (request.getMobileNumber() != null) user.setMobileNumber(request.getMobileNumber());
        if (request.getRole() != null) user.setRole(request.getRole());
        if (request.getStatus() != null) user.setStatus(request.getStatus());
        if (request.getProfileImageUrl() != null) user.setProfileImageUrl(request.getProfileImageUrl());
        if (request.getDepartment() != null) user.setDepartment(request.getDepartment());
        if (request.getDesignation() != null) user.setDesignation(request.getDesignation());
        if (request.getReportsTo() != null) user.setReportsTo(request.getReportsTo());
        if (request.getEmailVerified() != null) user.setEmailVerified(request.getEmailVerified());
        if (request.getMobileVerified() != null) user.setMobileVerified(request.getMobileVerified());
        if (request.getTwoFactorEnabled() != null) user.setTwoFactorEnabled(request.getTwoFactorEnabled());
        if (request.getPasswordChangeRequired() != null) user.setPasswordChangeRequired(request.getPasswordChangeRequired());
        
        user.setUpdatedBy(getCurrentUsername());
        
        // Update password only if provided
        if (request.getPassword() != null && !request.getPassword().trim().isEmpty()) {
            user.setPassword(passwordEncoder.encode(request.getPassword()));
            user.setIsTemporaryPassword(true);
            user.setPasswordChangeRequired(true);
            user.setLastPasswordChange(LocalDateTime.now());
        }
        
        User updatedUser = userRepository.save(user);
        log.info("User updated successfully: {}", updatedUser.getUsername());
        return mapToResponse(updatedUser);
    }
    
    @Transactional
    public void deleteUser(Long id) {
        log.info("Deleting user: {}", id);
        
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
        
        userRepository.delete(user);
        log.info("User deleted successfully: {}", user.getUsername());
    }
    
    @Transactional
    public UserResponse toggleUserStatus(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
        
        user.setIsActive(!user.getIsActive());
        user.setUpdatedBy(getCurrentUsername());
        
        User updatedUser = userRepository.save(user);
        log.info("User status toggled: {} - Active: {}", user.getUsername(), user.getIsActive());
        return mapToResponse(updatedUser);
    }
    
    @Transactional
    public UserResponse lockUser(Long id, String reason) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
        
        user.setAccountLockedUntil(LocalDateTime.now().plusDays(30)); // Lock for 30 days
        user.setUpdatedBy(getCurrentUsername());
        
        User lockedUser = userRepository.save(user);
        log.info("User locked: {} - Reason: {}", user.getUsername(), reason);
        return mapToResponse(lockedUser);
    }
    
    @Transactional
    public UserResponse unlockUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
        
        user.setAccountLockedUntil(null);
        user.setFailedLoginAttempts(0);
        user.setUpdatedBy(getCurrentUsername());
        
        User unlockedUser = userRepository.save(user);
        log.info("User unlocked: {}", user.getUsername());
        return mapToResponse(unlockedUser);
    }
    
    @Transactional
    public void resetPassword(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
        
        String tempPassword = generateTemporaryPassword();
        user.setPassword(passwordEncoder.encode(tempPassword));
        user.setIsTemporaryPassword(true);
        user.setPasswordChangeRequired(true);
        user.setLastPasswordChange(LocalDateTime.now());
        user.setUpdatedBy(getCurrentUsername());
        
        userRepository.save(user);
        
        try {
            emailService.sendPasswordResetEmail(user.getEmail(), user.getFullName(), tempPassword);
        } catch (Exception e) {
            log.error("Failed to send password reset email to user: {}", user.getUsername(), e);
        }
        
        log.info("Password reset for user: {}", user.getUsername());
    }
    
    public Page<UserResponse> getAllUsers(int page, int size, String sortBy, String sortDirection) {
        Sort.Direction direction = sortDirection.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        
        Page<User> users = userRepository.findAll(pageable);
        return users.map(this::mapToResponse);
    }
    
    public Page<UserResponse> getUsersByRole(User.UserRole role, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "firstName"));
        Page<User> users = userRepository.findByRole(role, pageable);
        return users.map(this::mapToResponse);
    }
    
    public Page<UserResponse> getUsersByStatus(User.UserStatus status, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "firstName"));
        Page<User> users = userRepository.findByStatus(status, pageable);
        return users.map(this::mapToResponse);
    }
    
    public Page<UserResponse> getUsersByDepartment(String department, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "firstName"));
        Page<User> users = userRepository.findByDepartment(department, pageable);
        return users.map(this::mapToResponse);
    }
    
    public Page<UserResponse> searchUsers(String searchTerm, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "firstName"));
        Page<User> users = userRepository.searchUsers(searchTerm, pageable);
        return users.map(this::mapToResponse);
    }
    
    public List<UserResponse> getSubordinates(Long managerId) {
        List<User> subordinates = userRepository.findByReportsTo(managerId);
        return subordinates.stream().map(this::mapToResponse).collect(Collectors.toList());
    }
    
    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null ? authentication.getName() : "system";
    }
    
    private String generateTemporaryPassword() {
        return "TempPass" + System.currentTimeMillis();
    }
    
    private UserResponse mapToResponse(User user) {
        String reportsToName = null;
        if (user.getReportsTo() != null) {
            User manager = userRepository.findById(user.getReportsTo()).orElse(null);
            if (manager != null) {
                reportsToName = manager.getFullName();
            }
        }
        
        Set<UserResponse.PermissionResponse> permissionResponses = null;
        if (user.getPermissions() != null) {
            permissionResponses = user.getPermissions().stream()
                    .map(permission -> UserResponse.PermissionResponse.builder()
                            .id(permission.getId())
                            .name(permission.getName())
                            .description(permission.getDescription())
                            .category(permission.getCategory())
                            .resourceType(permission.getResourceType())
                            .actionType(permission.getActionType())
                            .build())
                    .collect(Collectors.toSet());
        }
        
        long daysBetween = ChronoUnit.DAYS.between(user.getCreatedAt(), LocalDateTime.now());
        String accountAge = daysBetween == 0 ? "Today" :
                           daysBetween == 1 ? "1 day ago" :
                           daysBetween + " days ago";
        
        String lastLoginFormatted = user.getLastLogin() != null ? 
                user.getLastLogin().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")) : "Never";
        
        return UserResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .fullName(user.getFullName())
                .mobileNumber(user.getMobileNumber())
                .role(user.getRole())
                .status(user.getStatus())
                .profileImageUrl(user.getProfileImageUrl())
                .lastLogin(user.getLastLogin())
                .failedLoginAttempts(user.getFailedLoginAttempts())
                .accountLockedUntil(user.getAccountLockedUntil())
                .emailVerified(user.getEmailVerified())
                .mobileVerified(user.getMobileVerified())
                .twoFactorEnabled(user.getTwoFactorEnabled())
                .department(user.getDepartment())
                .designation(user.getDesignation())
                .reportsTo(user.getReportsTo())
                .reportsToName(reportsToName)
                .permissions(permissionResponses)
                .isActive(user.getIsActive())
                .isTemporaryPassword(user.getIsTemporaryPassword())
                .passwordChangeRequired(user.getPasswordChangeRequired())
                .lastPasswordChange(user.getLastPasswordChange())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .createdBy(user.getCreatedBy())
                .updatedBy(user.getUpdatedBy())
                .roleLabel(user.getRole().name())
                .statusLabel(user.getStatus().name())
                .isLocked(user.isLocked())
                .isAdmin(user.isAdmin())
                .accountAge(accountAge)
                .lastLoginFormatted(lastLoginFormatted)
                .build();
    }
}