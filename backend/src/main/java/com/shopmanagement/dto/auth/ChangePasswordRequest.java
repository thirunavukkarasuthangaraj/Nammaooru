package com.shopmanagement.dto.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ChangePasswordRequest {

    // Current password can be empty for temporary passwords
    private String currentPassword;

    @NotBlank(message = "New password is required")
    @Size(min = 4, max = 100, message = "Password must be between 4 and 100 characters")
    private String newPassword;

    @NotBlank(message = "Confirm password is required")
    private String confirmPassword;
}