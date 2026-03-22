package com.shopmanagement.userservice.dto.auth;

import lombok.Data;

@Data
public class AuthRequest {
    private String identifier;
    private String password;
    private String username;
    private String email;
}
