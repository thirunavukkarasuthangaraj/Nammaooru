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
}