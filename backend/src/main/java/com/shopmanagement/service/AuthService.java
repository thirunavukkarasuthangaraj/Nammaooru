package com.shopmanagement.service;

import com.shopmanagement.dto.auth.AuthRequest;
import com.shopmanagement.dto.auth.AuthResponse;
import com.shopmanagement.dto.auth.RegisterRequest;
import com.shopmanagement.dto.auth.ChangePasswordRequest;
import com.shopmanagement.entity.User;
import com.shopmanagement.exception.AuthenticationFailedException;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.util.PhoneNumberUtil;
import org.springframework.beans.factory.annotation.Autowired;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    @Autowired
    private EmailService emailService;

    @Autowired
    private EmailOtpService emailOtpService;

    @Autowired
    private MobileOtpService mobileOtpService;

    public AuthResponse register(RegisterRequest request) {
        // Normalize email and username to lowercase
        String normalizedEmail = request.getEmail() != null ? request.getEmail().toLowerCase().trim() : null;
        String normalizedUsername = request.getUsername() != null ? request.getUsername().toLowerCase().trim() : null;

        // Normalize mobile to plain 10 digits ("+91 98765 43210" / "098765..." all
        // become "9876543210") — MSG91 refuses anything else, so an unnormalized
        // number registers fine but never receives its OTP
        if (request.getMobileNumber() != null && !request.getMobileNumber().trim().isEmpty()) {
            try {
                request.setMobileNumber(PhoneNumberUtil.normalize(request.getMobileNumber()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Please enter a valid 10-digit Indian mobile number");
            }
        }

        // Check if user already exists by mobile or email. Mobile first — it is
        // the OTP identity, so the row owning the mobile number must be the one
        // we reuse; otherwise updating another row's mobile_number to it
        // violates the unique constraint (users_mobile_number_key).
        User existingUser = null;

        if (request.getMobileNumber() != null) {
            existingUser = userRepository.findByMobileNumber(request.getMobileNumber()).orElse(null);
        }
        if (existingUser == null && normalizedEmail != null) {
            existingUser = userRepository.findByEmail(normalizedEmail).orElse(null);
        }

        if (existingUser != null) {
            // Customer registration must never touch a shop owner / delivery
            // partner / admin account — even an unverified one, or its
            // password and details would be overwritten by the reuse flow below
            if (existingUser.getRole() != User.UserRole.USER) {
                throw new RuntimeException(
                        "This mobile number belongs to a " +
                        existingUser.getRole().name().toLowerCase().replace('_', ' ') +
                        " account. Please use the login page instead.");
            }

            // If the existing user never verified OTP (not active), allow re-registration
            boolean isUnverified = !Boolean.TRUE.equals(existingUser.getMobileVerified())
                                   && !Boolean.TRUE.equals(existingUser.getEmailVerified());
            Boolean isActive = existingUser.getIsActive();

            if (isUnverified || !Boolean.TRUE.equals(isActive)) {
                // The mobile/email being registered may belong to a DIFFERENT row
                // than the one we're reusing — updating would hit a unique
                // constraint and leak a raw SQL error to the app. Reject cleanly.
                if (request.getMobileNumber() != null) {
                    User mobileOwner = userRepository.findByMobileNumber(request.getMobileNumber()).orElse(null);
                    if (mobileOwner != null && !mobileOwner.getId().equals(existingUser.getId())) {
                        throw new RuntimeException("Mobile number already exists");
                    }
                }
                if (normalizedEmail != null) {
                    User emailOwner = userRepository.findByEmail(normalizedEmail).orElse(null);
                    if (emailOwner != null && !emailOwner.getId().equals(existingUser.getId())) {
                        throw new RuntimeException("Email already registered with another account");
                    }
                }
                if (normalizedUsername != null) {
                    User usernameOwner = userRepository.findByUsername(normalizedUsername).orElse(null);
                    if (usernameOwner != null && !usernameOwner.getId().equals(existingUser.getId())) {
                        throw new RuntimeException("Username already taken");
                    }
                }

                // Update existing unverified user's details and resend OTP
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

                // Resend OTP
                try {
                    if (existingUser.getMobileNumber() != null && !existingUser.getMobileNumber().isEmpty()) {
                        com.shopmanagement.dto.mobile.MobileOtpRequest otpRequest =
                            com.shopmanagement.dto.mobile.MobileOtpRequest.builder()
                                .mobileNumber(existingUser.getMobileNumber())
                                .purpose("REGISTRATION")
                                .deviceType("WEB")
                                .deviceId("web-" + existingUser.getId())
                                .build();
                        mobileOtpService.generateAndSendOtp(otpRequest);
                    }
                } catch (Exception e) {
                    System.err.println("Failed to send OTP SMS on re-registration: " + e.getMessage());
                }

                var jwtToken = jwtService.generateToken(existingUser);
                return AuthResponse.builder()
                        .accessToken(jwtToken)
                        .tokenType("Bearer")
                        .userId(existingUser.getId())
                        .username(existingUser.getUsername())
                        .email(existingUser.getEmail())
                        .role(existingUser.getRole().name())
                        .profileImageUrl(existingUser.getProfileImageUrl())
                        .build();
            } else {
                // User is verified/active - don't allow duplicate registration
                if (normalizedEmail != null && normalizedEmail.equals(existingUser.getEmail())) {
                    throw new RuntimeException("Email already exists");
                }
                throw new RuntimeException("Mobile number already exists");
            }
        }

        // Only allow USER role for registration (customers)
        // Shop owners and delivery partners should be created by admin

        // Store full name in both firstName and lastName as per requirement
        String fullName = request.getFirstName() != null ? request.getFirstName().trim() : "";

        var user = User.builder()
                .username(normalizedUsername)
                .email(normalizedEmail)
                .password(passwordEncoder.encode(request.getPassword())) // Password is NOT lowercased - security requirement
                .firstName(fullName)
                .lastName(fullName)
                .gender(request.getGender())
                .mobileNumber(request.getMobileNumber())
                .role(User.UserRole.USER)  // Mobile users get USER role for customer functionality
                .emailVerified(false)
                .mobileVerified(false)
                .build();

        userRepository.save(user);

        // Send OTP SMS after successful registration using mobile OTP service
        try {
            if (user.getMobileNumber() != null && !user.getMobileNumber().isEmpty()) {
                com.shopmanagement.dto.mobile.MobileOtpRequest otpRequest =
                    com.shopmanagement.dto.mobile.MobileOtpRequest.builder()
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
        
        var jwtToken = jwtService.generateToken(user);
        
        return AuthResponse.builder()
                .accessToken(jwtToken)
                .tokenType("Bearer")
                .userId(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .role(user.getRole().name())
                .profileImageUrl(user.getProfileImageUrl())
                .build();
    }

    public AuthResponse authenticate(AuthRequest request) {
        // Support both new identifier field and legacy email field
        String loginIdentifier = request.getIdentifier() != null ? request.getIdentifier() : request.getEmail();

        if (loginIdentifier == null || loginIdentifier.isEmpty()) {
            throw new AuthenticationFailedException("Email or mobile number is required");
        }

        // Normalize identifier (trim and lowercase for email comparison)
        loginIdentifier = loginIdentifier.trim();

        // Find user by email or mobile number from local DB
        User user;

        // Check if identifier is a mobile number (contains only digits and optional +)
        if (loginIdentifier.matches("^[+]?[0-9]+$")) {
            // Try to find by mobile number
            user = userRepository.findByMobileNumber(loginIdentifier)
                    .orElseThrow(() -> new AuthenticationFailedException("Invalid mobile number or password"));
        } else {
            // Normalize email to lowercase for case-insensitive comparison
            String normalizedEmail = loginIdentifier.toLowerCase();
            String identifier = loginIdentifier;
            // Try email first, then username (welcome emails give shop owners a username)
            user = userRepository.findByEmail(normalizedEmail)
                    .or(() -> userRepository.findByUsername(identifier))
                    .orElseThrow(() -> new AuthenticationFailedException("Invalid email or password"));
        }

        // Authenticate with the found user's username
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        user.getUsername(),
                        request.getPassword()
                )
        );

        var jwtToken = jwtService.generateToken(user);

        // Update last login timestamp
        user.setLastLogin(java.time.LocalDateTime.now());
        userRepository.save(user);

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

    public void changePassword(ChangePasswordRequest request, String username) {
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new RuntimeException("New password and confirm password do not match");
        }
        
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Verify current password only if not temporary (handle null as false)
        Boolean isTemporary = user.getIsTemporaryPassword();
        if (isTemporary == null || !isTemporary) {
            // Only check current password if it's provided and not empty
            if (request.getCurrentPassword() != null && !request.getCurrentPassword().trim().isEmpty()) {
                if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
                    throw new RuntimeException("Current password is incorrect");
                }
            } else {
                throw new RuntimeException("Current password is required");
            }
        }
        
        // Update password
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
    
    public boolean userExistsByUsernameOrEmail(String username, String email) {
        return userRepository.existsByUsername(username) || userRepository.existsByEmail(email);
    }
    
    public User createShopOwnerUser(String username, String email, String mobileNumber, String temporaryPassword) {
        // Check if user already exists
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
                .status(User.UserStatus.ACTIVE)
                .isTemporaryPassword(true)
                .passwordChangeRequired(true)
                .build();

        return userRepository.save(user);
    }
    
    public User findUserByEmail(String email) {
        if (email == null) {
            return null;
        }
        // Normalize email to lowercase to match registration behavior
        String normalizedEmail = email.toLowerCase().trim();
        return userRepository.findByEmail(normalizedEmail).orElse(null);
    }

    public User findUserByMobileNumber(String mobileNumber) {
        return userRepository.findByMobileNumber(mobileNumber).orElse(null);
    }

    public String generateTokenForUser(User user) {
        return jwtService.generateToken(user);
    }

    public User upgradeUserToShopOwner(String email, String temporaryPassword) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User with email " + email + " not found"));

        // Upgrade to SHOP_OWNER role
        user.setRole(User.UserRole.SHOP_OWNER);
        user.setPassword(passwordEncoder.encode(temporaryPassword));
        user.setIsTemporaryPassword(true);
        user.setPasswordChangeRequired(true);
        // A customer account that never finished OTP verification can be left
        // with isActive=false/status!=ACTIVE — isEnabled() checks both, and
        // Spring Security rejects an otherwise-correct password with "User is
        // disabled" in that case. Becoming a shop owner should always unlock
        // login, so force both explicitly rather than trust whatever state
        // the row was already in.
        user.setIsActive(true);
        user.setStatus(User.UserStatus.ACTIVE);

        // Don't update mobile number - user already has it
        // Updating it causes unique constraint violation even if it's the same value

        return userRepository.save(user);
    }
}