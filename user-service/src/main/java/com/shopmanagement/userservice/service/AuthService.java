package com.shopmanagement.userservice.service;

import com.shopmanagement.userservice.dto.auth.AuthRequest;
import com.shopmanagement.userservice.dto.auth.AuthResponse;
import com.shopmanagement.userservice.dto.auth.RegisterRequest;
import com.shopmanagement.userservice.dto.auth.ChangePasswordRequest;
import com.shopmanagement.userservice.dto.mobile.MobileOtpRequest;
import com.shopmanagement.userservice.entity.User;
import com.shopmanagement.userservice.exception.AuthenticationFailedException;
import com.shopmanagement.userservice.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    @Autowired
    private MobileOtpService mobileOtpService;

    public AuthResponse register(RegisterRequest request) {
        String normalizedEmail = request.getEmail() != null ? request.getEmail().toLowerCase().trim() : null;
        String normalizedUsername = request.getUsername() != null ? request.getUsername().toLowerCase().trim() : null;

        User existingUser = null;
        if (normalizedEmail != null) {
            existingUser = userRepository.findByEmail(normalizedEmail).orElse(null);
        }
        if (existingUser == null && request.getMobileNumber() != null) {
            existingUser = userRepository.findByMobileNumber(request.getMobileNumber()).orElse(null);
        }

        if (existingUser != null) {
            boolean isUnverified = !Boolean.TRUE.equals(existingUser.getMobileVerified())
                                   && !Boolean.TRUE.equals(existingUser.getEmailVerified());
            Boolean isActive = existingUser.getIsActive();

            if (isUnverified || !Boolean.TRUE.equals(isActive)) {
                String fullName = request.getFirstName() != null ? request.getFirstName().trim() : "";
                existingUser.setUsername(normalizedUsername);
                existingUser.setEmail(normalizedEmail);
                existingUser.setPassword(passwordEncoder.encode(request.getPassword()));
                existingUser.setFirstName(fullName);
                existingUser.setLastName(fullName);
                existingUser.setGender(request.getGender());
                existingUser.setMobileNumber(request.getMobileNumber());
                existingUser.setMobileVerified(false);
                existingUser.setEmailVerified(false);
                userRepository.save(existingUser);

                sendRegistrationOtp(existingUser);

                var jwtToken = jwtService.generateToken(existingUser);
                return buildAuthResponse(existingUser, jwtToken);
            } else {
                if (normalizedEmail != null && normalizedEmail.equals(existingUser.getEmail())) {
                    throw new RuntimeException("Email already exists");
                }
                throw new RuntimeException("Mobile number already exists");
            }
        }

        String fullName = request.getFirstName() != null ? request.getFirstName().trim() : "";
        var user = User.builder()
                .username(normalizedUsername)
                .email(normalizedEmail)
                .password(passwordEncoder.encode(request.getPassword()))
                .firstName(fullName)
                .lastName(fullName)
                .gender(request.getGender())
                .mobileNumber(request.getMobileNumber())
                .role(User.UserRole.USER)
                .emailVerified(false)
                .mobileVerified(false)
                .build();

        userRepository.save(user);
        sendRegistrationOtp(user);

        var jwtToken = jwtService.generateToken(user);
        return buildAuthResponse(user, jwtToken);
    }

    public AuthResponse authenticate(AuthRequest request) {
        String loginIdentifier = request.getIdentifier() != null ? request.getIdentifier() : request.getEmail();
        if (loginIdentifier == null || loginIdentifier.isEmpty()) {
            throw new AuthenticationFailedException("Email or mobile number is required");
        }

        loginIdentifier = loginIdentifier.trim();
        User user;

        if (loginIdentifier.matches("^[+]?[0-9]+$")) {
            user = userRepository.findByMobileNumber(loginIdentifier)
                    .orElseThrow(() -> new AuthenticationFailedException("Invalid mobile number or password"));
        } else {
            String normalizedEmail = loginIdentifier.toLowerCase();
            user = userRepository.findByEmail(normalizedEmail)
                    .orElseThrow(() -> new AuthenticationFailedException("Invalid email or password"));
        }

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(user.getUsername(), request.getPassword()));

        var jwtToken = jwtService.generateToken(user);
        user.setLastLogin(LocalDateTime.now());
        userRepository.save(user);

        return buildAuthResponse(user, jwtToken);
    }

    public void changePassword(ChangePasswordRequest request, String username) {
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new RuntimeException("New password and confirm password do not match");
        }

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Boolean isTemporary = user.getIsTemporaryPassword();
        if (isTemporary == null || !isTemporary) {
            if (request.getCurrentPassword() != null && !request.getCurrentPassword().trim().isEmpty()) {
                if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
                    throw new RuntimeException("Current password is incorrect");
                }
            } else {
                throw new RuntimeException("Current password is required");
            }
        }

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        user.setIsTemporaryPassword(false);
        user.setPasswordChangeRequired(false);
        user.setLastPasswordChange(LocalDateTime.now());
        userRepository.save(user);
    }

    public Map<String, Object> getPasswordStatus(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        Map<String, Object> status = new HashMap<>();
        status.put("isTemporaryPassword", user.getIsTemporaryPassword());
        status.put("passwordChangeRequired", user.getPasswordChangeRequired());
        status.put("lastPasswordChange", user.getLastPasswordChange());
        return status;
    }

    public User createShopOwnerUser(String username, String email, String mobileNumber, String temporaryPassword) {
        if (userRepository.existsByUsername(username) || userRepository.existsByEmail(email)) {
            throw new RuntimeException("User with this username or email already exists");
        }
        User user = User.builder()
                .username(username)
                .email(email)
                .mobileNumber(mobileNumber)
                .password(passwordEncoder.encode(temporaryPassword))
                .role(User.UserRole.SHOP_OWNER)
                .isActive(true)
                .isTemporaryPassword(true)
                .passwordChangeRequired(true)
                .build();
        return userRepository.save(user);
    }

    public User findUserByEmail(String email) {
        if (email == null) return null;
        return userRepository.findByEmail(email.toLowerCase().trim()).orElse(null);
    }

    public User findUserByMobileNumber(String mobileNumber) {
        return userRepository.findByMobileNumber(mobileNumber).orElse(null);
    }

    public String generateTokenForUser(User user) {
        return jwtService.generateToken(user);
    }

    private void sendRegistrationOtp(User user) {
        try {
            if (user.getMobileNumber() != null && !user.getMobileNumber().isEmpty()) {
                MobileOtpRequest otpRequest = MobileOtpRequest.builder()
                        .mobileNumber(user.getMobileNumber())
                        .purpose("REGISTRATION")
                        .deviceType("WEB")
                        .deviceId("web-" + user.getId())
                        .build();
                mobileOtpService.generateAndSendOtp(otpRequest);
            }
        } catch (Exception e) {
            System.err.println("Failed to send OTP SMS: " + e.getMessage());
        }
    }

    private AuthResponse buildAuthResponse(User user, String jwtToken) {
        return AuthResponse.builder()
                .accessToken(jwtToken)
                .tokenType("Bearer")
                .userId(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .role(user.getRole().name())
                .passwordChangeRequired(user.getPasswordChangeRequired())
                .isTemporaryPassword(user.getIsTemporaryPassword())
                .profileImageUrl(user.getProfileImageUrl())
                .build();
    }
}
