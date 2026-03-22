package com.shopmanagement.userservice.dto.internal;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Set;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserBasicDTO {
    private Long id;
    private String username;
    private String email;
    private String firstName;
    private String lastName;
    private String mobileNumber;
    private String role;
    private String status;
    private String profileImageUrl;
    private Boolean isActive;
    private Boolean emailVerified;
    private Boolean mobileVerified;
    private Boolean isOnline;
    private Boolean isAvailable;
    private String rideStatus;
    private Double currentLatitude;
    private Double currentLongitude;
    private Set<Long> assignedShopIds;
}
