package com.shopmanagement.dto.auth;

import lombok.Data;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Email;

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
    private String firstName;
    private String lastName;
    private String phoneNumber;
    private String mobileNumber;
    private String role;
}
