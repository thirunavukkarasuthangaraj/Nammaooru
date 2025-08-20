package com.shopmanagement.util;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class PasswordHashGenerator {
    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String rawPassword = "nammaooruthiru@123";
        String encodedPassword = encoder.encode(rawPassword);
        
        System.out.println("Original Password: " + rawPassword);
        System.out.println("BCrypt Hash: " + encodedPassword);
        System.out.println("\nSQL Update Command:");
        System.out.println("UPDATE users SET password = '" + encodedPassword + "' WHERE username = 'superadmin';");
    }
}