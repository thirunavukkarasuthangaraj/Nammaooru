package com.shopmanagement.controller;

import com.shopmanagement.entity.User;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/test")
@RequiredArgsConstructor
public class TestController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @PostMapping("/reset-admin-password")
    public String resetAdminPassword() {
        User admin = userRepository.findByUsername("admin")
                .orElse(null);
        
        if (admin != null) {
            admin.setPassword(passwordEncoder.encode("admin123"));
            userRepository.save(admin);
            return "Admin password reset to 'admin123' successfully";
        }
        
        return "Admin user not found";
    }
    
    @PostMapping("/reset-superadmin-password")
    public String resetSuperAdminPassword() {
        User superadmin = userRepository.findByUsername("superadmin")
                .orElse(null);
        
        if (superadmin != null) {
            superadmin.setPassword(passwordEncoder.encode("password"));
            userRepository.save(superadmin);
            return "Superadmin password reset to 'password' successfully";
        }
        
        return "Superadmin user not found";
    }
    
    @PostMapping("/reset-shopowner-password")
    public String resetShopOwnerPassword() {
        User shopowner = userRepository.findByUsername("shopowner1")
                .orElse(null);
        
        if (shopowner != null) {
            shopowner.setPassword(passwordEncoder.encode("password"));
            userRepository.save(shopowner);
            return "ShopOwner1 password reset to 'password' successfully";
        }
        
        return "ShopOwner1 user not found";
    }
    
    @GetMapping("/check-admin")
    public String checkAdmin() {
        User admin = userRepository.findByUsername("admin")
                .orElse(null);
        
        if (admin != null) {
            return "Admin exists - Username: " + admin.getUsername() + 
                   ", Email: " + admin.getEmail() + 
                   ", Role: " + admin.getRole() +
                   ", Enabled: " + admin.isEnabled();
        }
        
        return "Admin user not found";
    }
    
    @GetMapping("/test-password/{username}/{password}")
    public String testPassword(@PathVariable String username, @PathVariable String password) {
        User user = userRepository.findByUsername(username).orElse(null);
        if (user == null) {
            return "User not found";
        }
        
        boolean matches = passwordEncoder.matches(password, user.getPassword());
        return "User: " + username + 
               ", Password matches: " + matches +
               ", Hash: " + user.getPassword().substring(0, 20) + "..." +
               ", Enabled: " + user.isEnabled() +
               ", Active: " + user.getIsActive() +
               ", Status: " + user.getStatus();
    }
    
    @PostMapping("/create-superadmin")
    public String createSuperAdmin() {
        // Check if superadmin already exists
        if (userRepository.existsByUsername("superadmin") || userRepository.existsByEmail("superadmin@shopmanagement.com")) {
            // If exists, update the email and password
            User existingSuperadmin = userRepository.findByUsername("superadmin").orElse(null);
            if (existingSuperadmin != null) {
                existingSuperadmin.setEmail("superadmin@shopmanagement.com");
                existingSuperadmin.setPassword(passwordEncoder.encode("password"));
                existingSuperadmin.setRole(User.UserRole.SUPER_ADMIN);
                existingSuperadmin.setIsActive(true);
                existingSuperadmin.setEmailVerified(true);
                userRepository.save(existingSuperadmin);
                return "Superadmin user updated successfully - Email: superadmin@shopmanagement.com, Password: password";
            }
        }
        
        // Create new superadmin user
        User superadmin = User.builder()
                .username("superadmin")
                .email("superadmin@shopmanagement.com")
                .password(passwordEncoder.encode("password"))
                .firstName("Super")
                .lastName("Admin")
                .role(User.UserRole.SUPER_ADMIN)
                .status(User.UserStatus.ACTIVE)
                .isActive(true)
                .emailVerified(true)
                .mobileVerified(false)
                .twoFactorEnabled(false)
                .isTemporaryPassword(false)
                .passwordChangeRequired(false)
                .failedLoginAttempts(0)
                .createdBy("system")
                .build();
        
        userRepository.save(superadmin);
        return "Superadmin user created successfully - Email: superadmin@shopmanagement.com, Password: password";
    }
    
    @PostMapping("/create-custom-superadmin")
    public String createCustomSuperAdmin() {
        String customEmail = "thiruna2394@gmail.com";
        String customPassword = "Super@123";
        
        // Check if user already exists with this email
        User existingUser = userRepository.findByEmail(customEmail).orElse(null);
        if (existingUser != null) {
            existingUser.setPassword(passwordEncoder.encode(customPassword));
            existingUser.setRole(User.UserRole.SUPER_ADMIN);
            existingUser.setIsActive(true);
            existingUser.setEmailVerified(true);
            existingUser.setStatus(User.UserStatus.ACTIVE);
            userRepository.save(existingUser);
            return "User updated to superadmin successfully - Email: " + customEmail + ", Password: " + customPassword;
        }
        
        // Create new custom superadmin user
        User superadmin = User.builder()
                .username("superadmin_custom")
                .email(customEmail)
                .password(passwordEncoder.encode(customPassword))
                .firstName("Super")
                .lastName("Admin")
                .mobileNumber("9876543210")
                .role(User.UserRole.SUPER_ADMIN)
                .status(User.UserStatus.ACTIVE)
                .isActive(true)
                .emailVerified(true)
                .mobileVerified(true)
                .twoFactorEnabled(false)
                .isTemporaryPassword(false)
                .passwordChangeRequired(false)
                .failedLoginAttempts(0)
                .createdBy("system")
                .build();
        
        userRepository.save(superadmin);
        return "Custom superadmin user created successfully - Email: " + customEmail + ", Password: " + customPassword;
    }
}