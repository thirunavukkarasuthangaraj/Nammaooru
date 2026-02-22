package com.shopmanagement.dto.user;

import com.shopmanagement.entity.User;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Set;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserUpdateRequest {
    
    @Size(min = 3, max = 50, message = "Username must be between 3 and 50 characters")
    @Pattern(regexp = "^[a-zA-Z0-9_]+$", message = "Username can only contain letters, numbers, and underscores")
    private String username;
    
    @Email(message = "Invalid email format")
    @Size(max = 100, message = "Email cannot exceed 100 characters")
    private String email;
    
    // Password is optional for updates - only validate if provided
    @Size(min = 4, max = 100, message = "Password must be between 4 and 100 characters")
    private String password;
    
    @Size(max = 100, message = "First name cannot exceed 100 characters")
    private String firstName;
    
    @Size(max = 100, message = "Last name cannot exceed 100 characters")
    private String lastName;
    
    @Pattern(regexp = "^[6-9][0-9]{9}$", message = "Invalid mobile number")
    private String mobileNumber;
    
    private User.UserRole role;
    
    private User.UserStatus status;
    
    private String profileImageUrl;
    
    @Size(max = 100, message = "Department cannot exceed 100 characters")
    private String department;
    
    @Size(max = 100, message = "Designation cannot exceed 100 characters")
    private String designation;
    
    private Long reportsTo;
    
    private Set<Long> permissionIds;
    
    private Boolean emailVerified;
    
    private Boolean mobileVerified;
    
    private Boolean twoFactorEnabled;
    
    private Boolean passwordChangeRequired;
}