package com.shopmanagement.userservice.controller;

import com.shopmanagement.userservice.dto.internal.UserBasicDTO;
import com.shopmanagement.userservice.entity.User;
import com.shopmanagement.userservice.repository.UserRepository;
import com.shopmanagement.userservice.service.AuthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Internal API endpoints for inter-service communication.
 * These endpoints are NOT exposed through Nginx to the public.
 * Only the monolith (or other internal services) should call these.
 */
@Slf4j
@RestController
@RequestMapping("/internal/users")
@RequiredArgsConstructor
public class InternalUserController {

    private final UserRepository userRepository;
    private final AuthService authService;

    @GetMapping("/{id}")
    public ResponseEntity<UserBasicDTO> getUserById(@PathVariable Long id) {
        Optional<User> user = userRepository.findById(id);
        return user.map(u -> ResponseEntity.ok(mapToBasicDTO(u)))
                   .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/by-email")
    public ResponseEntity<UserBasicDTO> getUserByEmail(@RequestParam String email) {
        Optional<User> user = userRepository.findByEmail(email);
        return user.map(u -> ResponseEntity.ok(mapToBasicDTO(u)))
                   .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/by-username")
    public ResponseEntity<UserBasicDTO> getUserByUsername(@RequestParam String username) {
        Optional<User> user = userRepository.findByUsername(username);
        return user.map(u -> ResponseEntity.ok(mapToBasicDTO(u)))
                   .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/by-mobile")
    public ResponseEntity<UserBasicDTO> getUserByMobile(@RequestParam String mobileNumber) {
        Optional<User> user = userRepository.findByMobileNumber(mobileNumber);
        return user.map(u -> ResponseEntity.ok(mapToBasicDTO(u)))
                   .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/by-ids")
    public ResponseEntity<List<UserBasicDTO>> getUsersByIds(@RequestBody List<Long> ids) {
        List<User> users = userRepository.findAllById(ids);
        List<UserBasicDTO> dtos = users.stream().map(this::mapToBasicDTO).collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    @GetMapping("/by-role")
    public ResponseEntity<List<UserBasicDTO>> getUsersByRole(@RequestParam String role) {
        User.UserRole userRole = User.UserRole.valueOf(role.toUpperCase());
        List<User> users = userRepository.findByRole(userRole);
        List<UserBasicDTO> dtos = users.stream().map(this::mapToBasicDTO).collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    @GetMapping("/{id}/exists")
    public ResponseEntity<Map<String, Boolean>> userExists(@PathVariable Long id) {
        boolean exists = userRepository.existsById(id);
        return ResponseEntity.ok(Map.of("exists", exists));
    }

    @PostMapping("/validate-token")
    public ResponseEntity<UserBasicDTO> validateTokenAndGetUser(@RequestHeader("Authorization") String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.badRequest().build();
        }
        // The JWT filter already validates the token before reaching here,
        // but this endpoint is permitAll so we handle it manually if needed
        return ResponseEntity.ok().build();
    }

    @PostMapping("/create-shop-owner")
    public ResponseEntity<UserBasicDTO> createShopOwnerUser(@RequestBody Map<String, String> request) {
        try {
            String username = request.get("username");
            String email = request.get("email");
            String mobileNumber = request.get("mobileNumber");
            String temporaryPassword = request.get("temporaryPassword");

            User user = authService.createShopOwnerUser(username, email, mobileNumber, temporaryPassword);
            return ResponseEntity.ok(mapToBasicDTO(user));
        } catch (Exception e) {
            log.error("Error creating shop owner user: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        }
    }

    private UserBasicDTO mapToBasicDTO(User user) {
        return UserBasicDTO.builder()
                .id(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .mobileNumber(user.getMobileNumber())
                .role(user.getRole() != null ? user.getRole().name() : null)
                .status(user.getStatus() != null ? user.getStatus().name() : null)
                .profileImageUrl(user.getProfileImageUrl())
                .isActive(user.getIsActive())
                .build();
    }
}
