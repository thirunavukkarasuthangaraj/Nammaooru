package com.shopmanagement.userservice.dto.user;

import com.shopmanagement.userservice.entity.User;
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

    @Size(min = 3, max = 50)
    @Pattern(regexp = "^[a-zA-Z0-9_]+$", message = "Username can only contain letters, numbers, and underscores")
    private String username;

    @Email(message = "Invalid email format")
    @Size(max = 100)
    private String email;

    @Size(min = 4, max = 100)
    private String password;

    @Size(max = 100)
    private String firstName;

    @Size(max = 100)
    private String lastName;

    @Pattern(regexp = "^[6-9][0-9]{9}$", message = "Invalid mobile number")
    private String mobileNumber;

    private User.UserRole role;
    private User.UserStatus status;
    private String profileImageUrl;

    @Size(max = 100)
    private String department;

    @Size(max = 100)
    private String designation;

    private Long reportsTo;
    private Set<Long> permissionIds;
    private Boolean emailVerified;
    private Boolean mobileVerified;
    private Boolean twoFactorEnabled;
    private Boolean passwordChangeRequired;
}
