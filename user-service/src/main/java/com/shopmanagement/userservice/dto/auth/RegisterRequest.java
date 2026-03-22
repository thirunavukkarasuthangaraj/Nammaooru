package com.shopmanagement.userservice.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RegisterRequest {
    @NotBlank
    private String username;

    @NotBlank
    @Email
    private String email;

    @NotBlank
    private String password;

    private String fullName;

    @NotBlank(message = "First name is required")
    private String firstName;

    private String lastName;
    private String phoneNumber;

    @NotBlank(message = "Mobile number is required")
    private String mobileNumber;

    private String gender;
    private String role;
}
