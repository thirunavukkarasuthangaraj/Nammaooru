package com.shopmanagement.dto.auth;

public class AuthRequest {
    private String identifier; // Can be email or mobile number
    private String password;

    // Legacy fields for backward compatibility
    private String username;
    private String email;

    public String getIdentifier() { return identifier; }
    public void setIdentifier(String identifier) { this.identifier = identifier; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    // Legacy getters/setters
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
}
