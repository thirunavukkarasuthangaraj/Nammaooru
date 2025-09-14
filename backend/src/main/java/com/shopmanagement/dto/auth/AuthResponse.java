package com.shopmanagement.dto.auth;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AuthResponse {
    private String token;
    private String accessToken;
    private String type;
    private String tokenType;
    private String username;
    private String email;
    private String role;
    private Long userId;
    private boolean requiresOtp;
    private Boolean passwordChangeRequired;
    private Boolean isTemporaryPassword;
}
