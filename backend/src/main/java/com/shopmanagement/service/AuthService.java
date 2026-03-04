package com.shopmanagement.service;

import com.shopmanagement.client.UserBasicDTO;
import com.shopmanagement.client.UserServiceClient;
import com.shopmanagement.config.MicroserviceProperties;
import com.shopmanagement.dto.auth.AuthRequest;
import com.shopmanagement.dto.auth.AuthResponse;
import com.shopmanagement.dto.auth.RegisterRequest;
import com.shopmanagement.dto.auth.ChangePasswordRequest;
import com.shopmanagement.entity.User;
import com.shopmanagement.event.LoginEvent;
import com.shopmanagement.exception.AuthenticationFailedException;
import com.shopmanagement.repository.UserRepository;
import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.ratelimiter.annotation.RateLimiter;
import io.github.resilience4j.retry.annotation.Retry;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

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
    private final MicroserviceProperties microserviceProperties;
    private final RestTemplate restTemplate;
    private final ApplicationEventPublisher eventPublisher;

    @Autowired(required = false)
    private UserServiceClient userServiceClient;

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

        // Check if user already exists by email or mobile
        User existingUser = null;

        if (normalizedEmail != null) {
            existingUser = userRepository.findByEmail(normalizedEmail).orElse(null);
        }
        if (existingUser == null && request.getMobileNumber() != null) {
            existingUser = userRepository.findByMobileNumber(request.getMobileNumber()).orElse(null);
        }

        if (existingUser != null) {
            // If the existing user never verified OTP (not active), allow re-registration
            boolean isUnverified = !Boolean.TRUE.equals(existingUser.getMobileVerified())
                                   && !Boolean.TRUE.equals(existingUser.getEmailVerified());
            Boolean isActive = existingUser.getIsActive();

            if (isUnverified || !Boolean.TRUE.equals(isActive)) {
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

        // Microservice mode: delegate login to user-service
        if (microserviceProperties.isEnabled() && userServiceClient != null) {
            log.info("Microservice login: looking up user by identifier '{}'", loginIdentifier);
            return authenticateViaMicroservice(loginIdentifier, request.getPassword());
        }

        // Local mode: find user by email or mobile number from local DB
        User user;

        // Check if identifier is a mobile number (contains only digits and optional +)
        if (loginIdentifier.matches("^[+]?[0-9]+$")) {
            // Try to find by mobile number
            user = userRepository.findByMobileNumber(loginIdentifier)
                    .orElseThrow(() -> new AuthenticationFailedException("Invalid mobile number or password"));
        } else {
            // Normalize email to lowercase for case-insensitive comparison
            String normalizedEmail = loginIdentifier.toLowerCase();
            // Try to find by email
            user = userRepository.findByEmail(normalizedEmail)
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

    /**
     * Authenticate by calling the user-service's own login endpoint.
     * Protected by Resilience4j:
     *   - Bulkhead: max 10 concurrent calls (prevents overwhelming user-service)
     *   - RateLimiter: max 50 calls per second (prevents brute force)
     *   - CircuitBreaker: stops calling user-service if it's down (50% failure rate → OPEN)
     *   - Retry: retries up to 3 times on connection errors (not on wrong password)
     *
     * Order of execution: Retry → CircuitBreaker → RateLimiter → Bulkhead → actual call
     */
    @Bulkhead(name = "userServiceLogin")
    @RateLimiter(name = "userServiceLogin")
    @CircuitBreaker(name = "userServiceLogin", fallbackMethod = "loginFallback")
    @Retry(name = "userServiceLogin")
    public AuthResponse authenticateViaMicroservice(String identifier, String password) {
        String url = microserviceProperties.getUrl() + "/api/auth/login";
        log.info("[Resilience4j] Calling user-service login: POST {}", url);

        Map<String, String> loginRequest = new HashMap<>();
        loginRequest.put("email", identifier);
        loginRequest.put("password", password);

        try {
            org.springframework.http.ResponseEntity<Map> response = restTemplate.postForEntity(url, loginRequest, Map.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                Map body = response.getBody();
                Map data = (Map) body.get("data");
                if (data == null) {
                    throw new AuthenticationFailedException("Invalid response from user-service");
                }

                log.info("[Resilience4j] User-service login SUCCESS for '{}'", identifier);

                // Publish login success event
                eventPublisher.publishEvent(new LoginEvent(this, identifier, LoginEvent.Result.SUCCESS, "microservice", null));

                return AuthResponse.builder()
                        .accessToken((String) data.get("accessToken"))
                        .tokenType("Bearer")
                        .userId(data.get("userId") != null ? Long.valueOf(data.get("userId").toString()) : null)
                        .username((String) data.get("username"))
                        .email((String) data.get("email"))
                        .role((String) data.get("role"))
                        .passwordChangeRequired((Boolean) data.get("passwordChangeRequired"))
                        .isTemporaryPassword((Boolean) data.get("isTemporaryPassword"))
                        .profileImageUrl((String) data.get("profileImageUrl"))
                        .build();
            }
            // Publish login failure event
            eventPublisher.publishEvent(new LoginEvent(this, identifier, LoginEvent.Result.FAILURE, "microservice", "Invalid response from user-service"));
            throw new AuthenticationFailedException("Invalid username or password");
        } catch (org.springframework.web.client.HttpClientErrorException e) {
            // 401/403 = wrong password, don't retry this
            log.warn("[Resilience4j] User-service returned client error: {}", e.getStatusCode());
            eventPublisher.publishEvent(new LoginEvent(this, identifier, LoginEvent.Result.FAILURE, "microservice", "Client error: " + e.getStatusCode()));
            throw new AuthenticationFailedException("Invalid username or password");
        }
        // Other exceptions (ConnectException, SocketTimeout, etc.) bubble up for Retry to catch
    }

    /**
     * Fallback when Circuit Breaker is OPEN (user-service is down).
     * Tries to authenticate against local database as backup.
     */
    private AuthResponse loginFallback(String identifier, String password, Throwable throwable) {
        log.error("[Resilience4j] CIRCUIT BREAKER OPEN - user-service is down! Error: {}. Trying local DB fallback...",
                throwable.getMessage());

        // If the original error was wrong password, don't fallback - just throw
        if (throwable instanceof AuthenticationFailedException) {
            throw (AuthenticationFailedException) throwable;
        }

        // Try local database as fallback
        try {
            User user;
            if (identifier.matches("^[+]?[0-9]+$")) {
                user = userRepository.findByMobileNumber(identifier).orElse(null);
            } else {
                user = userRepository.findByEmail(identifier.toLowerCase()).orElse(null);
            }

            if (user != null) {
                authenticationManager.authenticate(
                        new UsernamePasswordAuthenticationToken(user.getUsername(), password));

                var jwtToken = jwtService.generateToken(user);
                log.info("[Resilience4j] LOCAL DB FALLBACK SUCCESS for '{}'", identifier);

                // Publish fallback login event
                eventPublisher.publishEvent(new LoginEvent(this, identifier, LoginEvent.Result.FALLBACK, "local-db", null));

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
        } catch (Exception e) {
            log.error("[Resilience4j] Local DB fallback also failed: {}", e.getMessage());
        }

        eventPublisher.publishEvent(new LoginEvent(this, identifier, LoginEvent.Result.FAILURE, "fallback", throwable.getMessage()));
        throw new AuthenticationFailedException(
                "Authentication service unavailable. Circuit breaker is OPEN. Please try again later.");
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

        // Don't update mobile number - user already has it
        // Updating it causes unique constraint violation even if it's the same value

        return userRepository.save(user);
    }
}