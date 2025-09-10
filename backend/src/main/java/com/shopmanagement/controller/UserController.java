package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.dto.user.UserRequest;
import com.shopmanagement.dto.user.UserUpdateRequest;
import com.shopmanagement.dto.user.UserResponse;
import com.shopmanagement.entity.User;
import com.shopmanagement.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@Slf4j
public class UserController {
    
    private final UserService userService;
    
    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<UserResponse>> createUser(@Valid @RequestBody UserRequest request) {
        log.info("Creating user: {}", request.getUsername());
        UserResponse response = userService.createUser(request);
        return ResponseUtil.created(response, "User created successfully");
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or #id == authentication.principal.id")
    public ResponseEntity<ApiResponse<UserResponse>> getUserById(@PathVariable Long id) {
        log.info("Fetching user with ID: {}", id);
        UserResponse response = userService.getUserById(id);
        return ResponseUtil.success(response);
    }
    
    @GetMapping("/username/{username}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or #username == authentication.name")
    public ResponseEntity<ApiResponse<UserResponse>> getUserByUsername(@PathVariable String username) {
        log.info("Fetching user with username: {}", username);
        UserResponse response = userService.getUserByUsername(username);
        return ResponseUtil.success(response);
    }
    
    @GetMapping("/email/{email}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<UserResponse>> getUserByEmail(@PathVariable String email) {
        log.info("Fetching user with email: {}", email);
        UserResponse response = userService.getUserByEmail(email);
        return ResponseUtil.success(response);
    }
    
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or #id == authentication.principal.id")
    public ResponseEntity<ApiResponse<UserResponse>> updateUser(@PathVariable Long id, @Valid @RequestBody UserUpdateRequest request) {
        log.info("Updating user: {}", id);
        UserResponse response = userService.updateUser(id, request);
        return ResponseUtil.updated(response);
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteUser(@PathVariable Long id) {
        log.info("Deleting user: {}", id);
        userService.deleteUser(id);
        return ResponseUtil.deleted();
    }
    
    @PutMapping("/{id}/toggle-status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<UserResponse>> toggleUserStatus(@PathVariable Long id) {
        log.info("Toggling status for user: {}", id);
        UserResponse response = userService.toggleUserStatus(id);
        return ResponseUtil.updated(response);
    }
    
    @PutMapping("/{id}/lock")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<UserResponse>> lockUser(@PathVariable Long id, @RequestParam String reason) {
        log.info("Locking user: {} with reason: {}", id, reason);
        UserResponse response = userService.lockUser(id, reason);
        return ResponseUtil.success(response, "User locked successfully");
    }
    
    @PutMapping("/{id}/unlock")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<UserResponse>> unlockUser(@PathVariable Long id) {
        log.info("Unlocking user: {}", id);
        UserResponse response = userService.unlockUser(id);
        return ResponseUtil.success(response, "User unlocked successfully");
    }
    
    @PostMapping("/{id}/reset-password")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> resetPassword(@PathVariable Long id) {
        log.info("Resetting password for user: {}", id);
        userService.resetPassword(id);
        return ResponseUtil.success(null, "Password reset successfully");
    }
    
    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAllUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "firstName") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDirection) {
        log.info("Fetching all users - page: {}, size: {}", page, size);
        Page<UserResponse> response = userService.getAllUsers(page, size, sortBy, sortDirection);
        return ResponseUtil.paginated(response);
    }
    
    @GetMapping("/role/{role}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getUsersByRole(
            @PathVariable String role,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching users with role: {}", role);
        User.UserRole userRole = User.UserRole.valueOf(role.toUpperCase());
        Page<UserResponse> response = userService.getUsersByRole(userRole, page, size);
        return ResponseUtil.paginated(response);
    }
    
    @GetMapping("/status/{status}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getUsersByStatus(
            @PathVariable String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching users with status: {}", status);
        User.UserStatus userStatus = User.UserStatus.valueOf(status.toUpperCase());
        Page<UserResponse> response = userService.getUsersByStatus(userStatus, page, size);
        return ResponseUtil.paginated(response);
    }
    
    @GetMapping("/department/{department}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getUsersByDepartment(
            @PathVariable String department,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching users in department: {}", department);
        Page<UserResponse> response = userService.getUsersByDepartment(department, page, size);
        return ResponseUtil.paginated(response);
    }
    
    @GetMapping("/search")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> searchUsers(
            @RequestParam String searchTerm,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Searching users with term: {}", searchTerm);
        Page<UserResponse> response = userService.searchUsers(searchTerm, page, size);
        return ResponseUtil.paginated(response);
    }
    
    @GetMapping("/{id}/subordinates")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or #id == authentication.principal.id")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getSubordinates(@PathVariable Long id) {
        log.info("Fetching subordinates for user: {}", id);
        List<UserResponse> response = userService.getSubordinates(id);
        return ResponseUtil.list(response);
    }
    
    @GetMapping("/roles")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getUserRoles() {
        Map<String, Object> roles = Map.of(
                "userRoles", User.UserRole.values(),
                "userStatuses", User.UserStatus.values()
        );
        return ResponseUtil.success(roles);
    }
}