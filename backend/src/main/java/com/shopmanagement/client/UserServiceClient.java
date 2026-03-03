package com.shopmanagement.client;

import com.shopmanagement.config.MicroserviceProperties;
import com.shopmanagement.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "microservice.user-service.enabled", havingValue = "true")
public class UserServiceClient {

    private final RestTemplate restTemplate;
    private final MicroserviceProperties microserviceProperties;

    public Optional<UserBasicDTO> getUserByUsername(String username) {
        try {
            String url = microserviceProperties.getUrl() + "/internal/users/by-username?username=" + username;
            log.info("Calling user-service: GET {}", url);
            ResponseEntity<UserBasicDTO> response = restTemplate.getForEntity(url, UserBasicDTO.class);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                return Optional.of(response.getBody());
            }
            return Optional.empty();
        } catch (Exception e) {
            log.error("Error calling user-service getUserByUsername: {}", e.getMessage());
            return Optional.empty();
        }
    }

    public Optional<UserBasicDTO> getUserByEmail(String email) {
        try {
            String url = microserviceProperties.getUrl() + "/internal/users/by-email?email=" + email;
            log.info("Calling user-service: GET {}", url);
            ResponseEntity<UserBasicDTO> response = restTemplate.getForEntity(url, UserBasicDTO.class);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                return Optional.of(response.getBody());
            }
            return Optional.empty();
        } catch (Exception e) {
            log.error("Error calling user-service getUserByEmail: {}", e.getMessage());
            return Optional.empty();
        }
    }

    public Optional<UserBasicDTO> getUserById(Long id) {
        try {
            String url = microserviceProperties.getUrl() + "/internal/users/" + id;
            log.info("Calling user-service: GET {}", url);
            ResponseEntity<UserBasicDTO> response = restTemplate.getForEntity(url, UserBasicDTO.class);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                return Optional.of(response.getBody());
            }
            return Optional.empty();
        } catch (Exception e) {
            log.error("Error calling user-service getUserById: {}", e.getMessage());
            return Optional.empty();
        }
    }

    public List<UserBasicDTO> getUsersByIds(List<Long> ids) {
        try {
            String url = microserviceProperties.getUrl() + "/internal/users/by-ids";
            log.info("Calling user-service: POST {}", url);
            ResponseEntity<List<UserBasicDTO>> response = restTemplate.exchange(
                    url, HttpMethod.POST,
                    new org.springframework.http.HttpEntity<>(ids),
                    new ParameterizedTypeReference<List<UserBasicDTO>>() {}
            );
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                return response.getBody();
            }
            return Collections.emptyList();
        } catch (Exception e) {
            log.error("Error calling user-service getUsersByIds: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    public List<UserBasicDTO> getUsersByRole(String role) {
        try {
            String url = microserviceProperties.getUrl() + "/internal/users/by-role?role=" + role;
            log.info("Calling user-service: GET {}", url);
            ResponseEntity<List<UserBasicDTO>> response = restTemplate.exchange(
                    url, HttpMethod.GET, null,
                    new ParameterizedTypeReference<List<UserBasicDTO>>() {}
            );
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                return response.getBody();
            }
            return Collections.emptyList();
        } catch (Exception e) {
            log.error("Error calling user-service getUsersByRole: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    /**
     * Converts a UserBasicDTO from user-service into the monolith's User entity.
     * Note: password is NOT available from the internal API, so JWT token validation
     * works fine but login authentication requires the user-service's own /api/auth/login.
     */
    public User toUserEntity(UserBasicDTO dto) {
        return User.builder()
                .id(dto.getId())
                .username(dto.getUsername())
                .email(dto.getEmail())
                .password("{noop}microservice-user")  // Placeholder — login goes through user-service
                .firstName(dto.getFirstName())
                .lastName(dto.getLastName())
                .mobileNumber(dto.getMobileNumber())
                .role(dto.getRole() != null ? User.UserRole.valueOf(dto.getRole()) : User.UserRole.USER)
                .status(dto.getStatus() != null ? User.UserStatus.valueOf(dto.getStatus()) : User.UserStatus.ACTIVE)
                .profileImageUrl(dto.getProfileImageUrl())
                .isActive(dto.getIsActive() != null ? dto.getIsActive() : true)
                .emailVerified(dto.getEmailVerified())
                .mobileVerified(dto.getMobileVerified())
                .isOnline(dto.getIsOnline())
                .isAvailable(dto.getIsAvailable())
                .rideStatus(dto.getRideStatus() != null ? User.RideStatus.valueOf(dto.getRideStatus()) : null)
                .currentLatitude(dto.getCurrentLatitude())
                .currentLongitude(dto.getCurrentLongitude())
                .assignedShopIds(dto.getAssignedShopIds() != null ? dto.getAssignedShopIds() : new HashSet<>())
                .build();
    }
}
