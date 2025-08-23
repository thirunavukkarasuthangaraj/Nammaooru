package com.shopmanagement.util;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class PasswordHashGenerator {
    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        
        // Get password from command line argument or use default
        String rawPassword = args.length > 0 ? args[0] : "Nammaooru2025";
        
        // Validate password strength
        if (rawPassword.length() < 8) {
            System.out.println("❌ Password must be at least 8 characters long");
            return;
        }
        
        String encodedPassword = encoder.encode(rawPassword);
        
        System.out.println("=== Secure Password Hash Generator ===");
        System.out.println("Compatible with Spring Boot BCryptPasswordEncoder");
        System.out.println();
        System.out.println("📋 Results:");
        System.out.println("Password: " + rawPassword);
        System.out.println("BCrypt Hash: " + encodedPassword);
        System.out.println();
        System.out.println("📝 SQL Commands:");
        System.out.println("UPDATE users SET password = '" + encodedPassword + "' WHERE username = 'superadmin';");
        System.out.println("UPDATE users SET password = '" + encodedPassword + "' WHERE username = 'admin';");
        System.out.println();
        System.out.println("✅ Hash generated successfully!");
        System.out.println("This hash is 100% compatible with your production system.");
    }
}