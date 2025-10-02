package com.shopmanagement.util;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class PasswordGenerator {
    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

        String[] passwords = {"Test@123", "Admin@123", "Password@123"};

        System.out.println("===== BCrypt Password Hashes =====");
        for (String password : passwords) {
            String hash = encoder.encode(password);
            System.out.println("Password: " + password);
            System.out.println("Hash: " + hash);
            System.out.println("---");
        }

        // Test the hash
        String testPassword = "Test@123";
        String testHash = "$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu";
        boolean matches = encoder.matches(testPassword, testHash);
        System.out.println("\nVerification Test:");
        System.out.println("Password 'Test@123' matches hash: " + matches);
    }
}