package com.shopmanagement.service;

import com.shopmanagement.dto.auth.AuthRequest;
import com.shopmanagement.dto.auth.AuthResponse;
import com.shopmanagement.dto.auth.RegisterRequest;
import com.shopmanagement.dto.auth.ChangePasswordRequest;
import com.shopmanagement.entity.User;
import com.shopmanagement.exception.AuthenticationFailedException;
import com.shopmanagement.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import lombok.RequiredArgsConstructor;
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
    private EmailService emailService;
    
    @Autowired
    private EmailOtpService emailOtpService;

    public AuthResponse register(RegisterRequest request) {
        // Username is not unique anymore, can be duplicate
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already exists");
        }
        if (request.getMobileNumber() != null && userRepository.existsByMobileNumber(request.getMobileNumber())) {
            throw new RuntimeException("Mobile number already exists");
        }

        // Only allow USER role for registration (customers)
        // Shop owners and delivery partners should be created by admin
        var user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .mobileNumber(request.getMobileNumber())
                .role(User.UserRole.USER)  // Mobile users get USER role for customer functionality
                .emailVerified(false)
                .mobileVerified(false)
                .build();
        
        userRepository.save(user);
        
        // Send OTP email after successful registration using new secure OTP service
        try {
            String userName = request.getFirstName() + " " + request.getLastName();
            emailOtpService.generateAndSendOtp(user.getEmail(), "REGISTRATION", userName);
        } catch (Exception e) {
            System.err.println("Failed to send OTP email: " + e.getMessage());
        }
        
        var jwtToken = jwtService.generateToken(user);
        
        return AuthResponse.builder()
                .accessToken(jwtToken)
                .tokenType("Bearer")
                .userId(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .role(user.getRole().name())
                .build();
    }

    public AuthResponse authenticate(AuthRequest request) {
        // Support both new identifier field and legacy email field
        String loginIdentifier = request.getIdentifier() != null ? request.getIdentifier() : request.getEmail();

        if (loginIdentifier == null || loginIdentifier.isEmpty()) {
            throw new AuthenticationFailedException("Email or mobile number is required");
        }

        // Find user by email or mobile number
        User user;

        // Check if identifier is a mobile number (contains only digits and optional +)
        if (loginIdentifier.matches("^[+]?[0-9]+$")) {
            // Try to find by mobile number
            user = userRepository.findByMobileNumber(loginIdentifier)
                    .orElseThrow(() -> new AuthenticationFailedException("Invalid mobile number or password"));
        } else {
            // Try to find by email
            user = userRepository.findByEmail(loginIdentifier)
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

        return AuthResponse.builder()
                .accessToken(jwtToken)
                .tokenType("Bearer")
                .userId(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .role(user.getRole().name())
                .passwordChangeRequired(user.getPasswordChangeRequired())
                .isTemporaryPassword(user.getIsTemporaryPassword())
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
    
    public User createShopOwnerUser(String username, String email, String temporaryPassword) {
        // Check if user already exists
        if (userRepository.existsByUsername(username) || userRepository.existsByEmail(email)) {
            throw new RuntimeException("User with this username or email already exists");
        }
        
        User user = User.builder()
                .username(username)
                .email(email)
                .password(passwordEncoder.encode(temporaryPassword))
                .role(User.UserRole.SHOP_OWNER)
                .isActive(true)
                .isTemporaryPassword(true)
                .passwordChangeRequired(true)
                .build();
        
        return userRepository.save(user);
    }
    
    public User findUserByEmail(String email) {
        return userRepository.findByEmail(email).orElse(null);
    }
    
    public String generateTokenForUser(User user) {
        return jwtService.generateToken(user);
    }
}