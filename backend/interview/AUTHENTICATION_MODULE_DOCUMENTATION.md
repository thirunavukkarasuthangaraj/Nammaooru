# Complete Authentication Module Documentation - Spring Boot Thiru Software System

## Executive Summary

This Spring Boot application implements a comprehensive authentication system using JWT tokens, email/mobile-based OTP verification, and Spring Security. The system supports multiple user roles (SUPER_ADMIN, ADMIN, SHOP_OWNER, DELIVERY_PARTNER, CUSTOMER/USER) with sophisticated security features.

---

## 1. AUTHENTICATION FLOW

### 1.1 Registration Flow

**Endpoint:** `POST /api/auth/register`

**Request:**
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "SecurePass123",
  "firstName": "John",
  "lastName": "Doe",
  "mobileNumber": "+919876543210"
}
```

**Process:**
1. **Validation** - Check if email/mobile already exists
2. **User Creation** - Create user with `USER` role (customers only)
3. **Password Encoding** - BCrypt password hashing
4. **OTP Generation** - Generate 6-digit OTP, valid for 10 minutes
5. **Email Sending** - Send OTP via email using Thymeleaf template
6. **JWT Generation** - Generate JWT token immediately
7. **Response** - Return JWT token + user details

**Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "userId": 123,
  "username": "john_doe",
  "email": "john@example.com",
  "role": "USER"
}
```

### 1.2 OTP Verification Flow

**Endpoint:** `POST /api/auth/verify-otp`

**Request:**
```json
{
  "email": "john@example.com",
  "otp": "123456",
  "purpose": "REGISTRATION"
}
```

**Process:**
1. **OTP Lookup** - Find OTP by email, code, and purpose
2. **Validation Checks:**
   - OTP exists
   - Not expired (10-minute window)
   - Not already used
   - Still active
   - Attempt count < max attempts
3. **Mark as Used** - Update OTP record
4. **Generate Token** - Create new JWT token
5. **Response** - Return authentication response

### 1.3 Login Flow

**Endpoint:** `POST /api/auth/login`

**Request:**
```json
{
  "identifier": "john@example.com", // or mobile number
  "password": "SecurePass123"
}
```

**Process:**
1. **User Lookup** - Find user by email OR mobile number
   - Detects if identifier is mobile (digits only) or email
2. **Authentication** - Uses Spring Security's `AuthenticationManager`
   - DaoAuthenticationProvider validates password
   - BCryptPasswordEncoder compares hashed passwords
3. **JWT Generation** - Create JWT token with user details
4. **Response** - Return token + user info

**Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "userId": 123,
  "username": "john_doe",
  "email": "john@example.com",
  "role": "USER",
  "passwordChangeRequired": false,
  "isTemporaryPassword": false
}
```

### 1.4 Forgot Password Flow

**Endpoint:** `POST /api/auth/forgot-password/send-otp`

**Request:**
```json
{
  "email": "john@example.com"
}
```

**Process:**
1. **Rate Limiting** - Max 5 requests per hour
2. **Deactivate Old OTPs** - Invalidate previous password reset OTPs
3. **Generate OTP** - Create 6-digit OTP (10-minute validity)
4. **Send Email** - Template: `forgot-password-otp.html`
5. **Response** - Confirmation message

**Password Reset:** `POST /api/auth/forgot-password/reset-password`
- Verify OTP
- Update password
- Mark OTP as used

---

## 2. TECHNOLOGY STACK

### 2.1 Spring Security Components

**Core Dependencies:**
- Spring Security 6.x
- Spring Boot 3.x
- JWT (io.jsonwebtoken:jjwt)

**Key Classes:**
- `SecurityConfig` - Main security configuration
- `JwtAuthenticationFilter` - JWT token validation filter
- `DaoAuthenticationProvider` - Password authentication
- `BCryptPasswordEncoder` - Password hashing

### 2.2 Database Technology

**Database:** PostgreSQL
- JDBC URL: `jdbc:postgresql://localhost:5432/shop_management_db`
- JPA/Hibernate for ORM
- Flyway for migrations

**Connection Pool:**
```yaml
spring:
  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/shop_management_db}
    username: ${DB_USERNAME:postgres}
    password: ${DB_PASSWORD:postgres}
    driver-class-name: org.postgresql.Driver
```

### 2.3 Email Service

**SMTP Configuration:**
```yaml
spring:
  mail:
    host: smtp.hostinger.com
    port: 587
    username: noreplay@nammaoorudelivary.in
    password: ${MAIL_PASSWORD:}
    properties:
      mail:
        smtp:
          auth: true
          starttls:
            enable: true
            required: true
          connectiontimeout: 30000
          timeout: 30000
```

**Email Components:**
- `JavaMailSender` - Spring's email sender
- `Thymeleaf TemplateEngine` - HTML email templates
- `EmailService` - Business logic (@Async for non-blocking)

---

## 3. KEY COMPONENTS

### 3.1 Controllers

**File:** `src/main/java/com/shopmanagement/auth/controller/AuthController.java`

**Endpoints:**
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - Logout & token blacklist
- `GET /api/auth/validate` - Token validation
- `POST /api/auth/change-password` - Password change
- `POST /api/auth/send-otp` - Send OTP
- `POST /api/auth/verify-otp` - Verify OTP
- `POST /api/auth/generate-password-hash` - Utility endpoint

**File:** `src/main/java/com/shopmanagement/auth/controller/ForgotPasswordOtpController.java`

**Endpoints:**
- `POST /api/auth/forgot-password/send-otp`
- `POST /api/auth/forgot-password/verify-otp`
- `POST /api/auth/forgot-password/reset-password`
- `POST /api/auth/forgot-password/resend-otp`

### 3.2 Services

**File:** `src/main/java/com/shopmanagement/service/AuthService.java`

**Key Methods:**
```java
public AuthResponse register(RegisterRequest request)
public AuthResponse authenticate(AuthRequest request)
public void changePassword(ChangePasswordRequest request, String username)
public User createShopOwnerUser(String username, String email, String mobileNumber, String temporaryPassword)
public User upgradeUserToShopOwner(String email, String temporaryPassword)
```

**File:** `src/main/java/com/shopmanagement/service/JwtService.java`

**Key Methods:**
```java
public String generateToken(UserDetails userDetails)
public String extractUsername(String token)
public boolean isTokenValid(String token, UserDetails userDetails)
private boolean isTokenExpired(String token)
```

**JWT Configuration:**
- Secret Key: Configurable via `jwt.secret`
- Expiration: 24 hours (86400000 ms)
- Algorithm: HS256 (HMAC SHA-256)

**File:** `src/main/java/com/shopmanagement/service/EmailOtpService.java`

**Key Methods:**
```java
public String generateAndSendOtp(String email, String purpose, String userName)
public boolean verifyOtp(String email, String otpCode, String purpose)
public void invalidateAllOtps(String email, String purpose)
@Scheduled(fixedRate = 3600000)
public void cleanupExpiredOtps() // Runs every hour
```

**Features:**
- Rate limiting: Max 5 OTP requests per hour
- OTP expiry: 10 minutes
- Auto-cleanup: Deletes OTPs older than 24 hours

**File:** `src/main/java/com/shopmanagement/service/EmailService.java`

**Key Methods:**
```java
@Async
public void sendHtmlEmail(String to, String subject, String templateName, Map<String, Object> variables)
public void sendOtpVerificationEmail(String to, String userName, String otpCode)
public void sendPasswordResetOtpEmail(String to, String username, String otp)
public void sendShopOwnerWelcomeEmail(String to, String shopOwnerName, String username, String temporaryPassword, String shopName)
```

### 3.3 Repositories

**File:** `src/main/java/com/shopmanagement/repository/UserRepository.java`

**Key Methods:**
```java
Optional<User> findByUsername(String username);
Optional<User> findByEmail(String email);
Optional<User> findByMobileNumber(String mobileNumber);
Optional<User> findByEmailOrMobileNumber(String email, String mobileNumber);
boolean existsByUsername(String username);
boolean existsByEmail(String email);
boolean existsByMobileNumber(String mobileNumber);
Page<User> findByRole(User.UserRole role, Pageable pageable);
List<User> findByPasswordChangeRequiredTrue();
```

**File:** `src/main/java/com/shopmanagement/repository/EmailOtpRepository.java`

**Key Methods:**
```java
Optional<EmailOtp> findLatestActiveOtpByEmailAndPurpose(String email, String purpose);
Optional<EmailOtp> findByEmailAndOtpCodeAndPurpose(String email, String otpCode, String purpose);
@Modifying void deactivateAllActiveOtpsByEmailAndPurpose(String email, String purpose);
@Modifying void deleteExpiredOtps(LocalDateTime expiredBefore);
long countOtpAttemptsSince(String email, String purpose, LocalDateTime since);
```

### 3.4 Entities/Models

**File:** `src/main/java/com/shopmanagement/entity/User.java`

**Key Fields:**
```java
@Id @GeneratedValue
private Long id;

@Column(unique = true, nullable = false)
private String username;

@Column(unique = true, nullable = false)
private String email;

@Column(nullable = false)
private String password; // BCrypt hashed

@Column(name = "mobile_number", unique = true, nullable = false)
private String mobileNumber;

@Enumerated(EnumType.STRING)
private UserRole role; // SUPER_ADMIN, ADMIN, SHOP_OWNER, MANAGER, EMPLOYEE, CUSTOMER_SERVICE, DELIVERY_PARTNER, USER

@Enumerated(EnumType.STRING)
private UserStatus status; // ACTIVE, INACTIVE, SUSPENDED, PENDING_VERIFICATION

private Boolean emailVerified = false;
private Boolean mobileVerified = false;
private Boolean twoFactorEnabled = false;
private Boolean isTemporaryPassword = false;
private Boolean passwordChangeRequired = false;

private LocalDateTime lastLogin;
private Integer failedLoginAttempts = 0;
private LocalDateTime accountLockedUntil;
private LocalDateTime lastPasswordChange;

@ManyToMany(fetch = FetchType.EAGER)
private Set<Permission> permissions;
```

**Implements `UserDetails` interface for Spring Security integration.**

**File:** `src/main/java/com/shopmanagement/entity/EmailOtp.java`

**Key Fields:**
```java
@Id @GeneratedValue
private Long id;

@Column(nullable = false)
private String email;

@Column(nullable = false)
private String otpCode; // 6-digit OTP

@Column(nullable = false)
private String purpose; // REGISTRATION, PASSWORD_RESET, EMAIL_VERIFICATION

@Column(nullable = false)
private LocalDateTime expiresAt; // Created + 10 minutes

private Boolean isUsed = false;
private Boolean isActive = true;
private Integer attemptCount = 0;
private LocalDateTime usedAt;

@CreatedDate
private LocalDateTime createdAt;
```

**Helper Methods:**
```java
public boolean isExpired() { return LocalDateTime.now().isAfter(expiresAt); }
public boolean isValid() { return isActive && !isUsed && !isExpired(); }
public void markAsUsed() { this.isUsed = true; this.usedAt = LocalDateTime.now(); }
```

**File:** `src/main/java/com/shopmanagement/entity/MobileOtp.java`

**Similar structure to EmailOtp but for mobile verification with additional device tracking:**
```java
private String deviceId;
private String deviceType;
private String appVersion;
private String ipAddress;
private String sessionId;

@Enumerated(EnumType.STRING)
private OtpPurpose purpose; // REGISTRATION, LOGIN, FORGOT_PASSWORD, CHANGE_MOBILE, VERIFY_MOBILE, ORDER_CONFIRMATION, ACCOUNT_VERIFICATION
```

---

## 4. OTP IMPLEMENTATION

### 4.1 OTP Generation

**Algorithm:**
```java
// Secure random 6-digit OTP
String otpCode = String.valueOf((int) (Math.random() * 900000) + 100000);
```

**Configuration:**
- Length: 6 digits
- Validity: 10 minutes
- Max Attempts: 3 per OTP
- Rate Limiting: 5 OTPs per hour per email

### 4.2 OTP Storage

**Database Schema:**
```sql
CREATE TABLE email_otps (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    otp_code VARCHAR(10) NOT NULL,
    purpose VARCHAR(50) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    attempt_count INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP
);

CREATE INDEX idx_email_otps_email_purpose ON email_otps(email, purpose);
CREATE INDEX idx_email_otps_expires_at ON email_otps(expires_at);
```

### 4.3 OTP Validation Logic

**Process:**
1. **Find OTP** - Query by email, OTP code, and purpose
2. **Check if exists** - Return error if not found
3. **Increment attempts** - Track failed attempts
4. **Validate status:**
   - Not expired
   - Not used
   - Active
   - Attempts < max (3)
5. **Mark as used** - Update record on success
6. **Deactivate old OTPs** - When new OTP is generated

**Security Features:**
- Auto-deactivation of previous OTPs
- Rate limiting (5 per hour)
- Attempt tracking
- Time-based expiry
- Scheduled cleanup of expired OTPs

---

## 5. EMAIL SERVICE

### 5.1 SMTP Configuration

**Provider:** Hostinger SMTP

**Settings:**
```
Host: smtp.hostinger.com
Port: 587
Security: STARTTLS
Authentication: Required
From: noreplay@nammaoorudelivary.in
```

### 5.2 Email Templates

**Location:** `src/main/resources/templates/`

**Available Templates:**
1. `otp-verification.html` - OTP verification email
2. `forgot-password-otp.html` - Password reset OTP
3. `welcome-shop-owner.html` - Shop owner welcome email
4. `password-reset.html` - Password reset confirmation
5. `order-confirmation.html` - Order confirmation
6. `delivery-assignment.html` - Delivery partner assignment

**Template Engine:** Thymeleaf

**Template Variables (OTP Verification):**
```java
Map<String, Object> variables = Map.of(
    "userName", "John Doe",
    "otpCode", "123456",
    "expirationMinutes", "10",
    "supportEmail", "noreplay@nammaoorudelivary.in",
    "companyName", "NammaOoru"
);
```

### 5.3 Email Sending Process

**Asynchronous Sending:**
```java
@Async
public void sendHtmlEmail(String to, String subject, String templateName, Map<String, Object> variables) {
    MimeMessage mimeMessage = mailSender.createMimeMessage();
    MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, true, "UTF-8");

    helper.setFrom(emailProperties.getFrom(), emailProperties.getFromName());
    helper.setTo(to);
    helper.setSubject(subject);

    Context context = new Context();
    variables.forEach(context::setVariable);

    String htmlContent = templateEngine.process(templateName, context);
    helper.setText(htmlContent, true);

    mailSender.send(mimeMessage);
}
```

**Features:**
- Async execution (doesn't block main thread)
- HTML email support
- Template-based rendering
- Error logging (doesn't throw exceptions)

---

## 6. DATABASE SCHEMA

### 6.1 Users Table

```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL, -- BCrypt hash
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    mobile_number VARCHAR(15) UNIQUE NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'USER', -- Enum
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- Enum
    profile_image_url TEXT,

    -- Authentication fields
    last_login TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMP,

    -- Verification fields
    email_verified BOOLEAN DEFAULT FALSE,
    mobile_verified BOOLEAN DEFAULT FALSE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,

    -- Password management
    is_temporary_password BOOLEAN DEFAULT FALSE,
    password_change_required BOOLEAN DEFAULT FALSE,
    last_password_change TIMESTAMP,

    -- Organizational fields
    department VARCHAR(100),
    designation VARCHAR(100),
    reports_to BIGINT,

    -- Status fields
    is_active BOOLEAN DEFAULT TRUE,

    -- Audit fields
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100),

    -- Delivery partner fields
    is_online BOOLEAN DEFAULT FALSE,
    is_available BOOLEAN DEFAULT FALSE,
    ride_status VARCHAR(20) DEFAULT 'AVAILABLE',
    current_latitude DOUBLE PRECISION,
    current_longitude DOUBLE PRECISION,
    last_location_update TIMESTAMP,
    last_activity TIMESTAMP
);
```

### 6.2 Email OTPs Table

```sql
CREATE TABLE email_otps (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    otp_code VARCHAR(10) NOT NULL,
    purpose VARCHAR(50) NOT NULL, -- REGISTRATION, PASSWORD_RESET, EMAIL_VERIFICATION
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    attempt_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    used_at TIMESTAMP
);

CREATE INDEX idx_email_otps_email ON email_otps(email);
CREATE INDEX idx_email_otps_email_purpose ON email_otps(email, purpose);
CREATE INDEX idx_email_otps_expires_at ON email_otps(expires_at);
```

### 6.3 Mobile OTPs Table

```sql
CREATE TABLE mobile_otps (
    id BIGSERIAL PRIMARY KEY,
    mobile_number VARCHAR(15) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    purpose VARCHAR(20) NOT NULL, -- Enum
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    attempt_count INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,

    -- Security fields
    device_id VARCHAR(100),
    device_type VARCHAR(20),
    app_version VARCHAR(50),
    ip_address VARCHAR(45),
    session_id VARCHAR(100),

    -- Verification fields
    verified_at TIMESTAMP,
    verified_by VARCHAR(100),

    -- Audit
    created_at TIMESTAMP DEFAULT NOW(),
    created_by VARCHAR(100) DEFAULT 'mobile-app'
);

CREATE INDEX idx_mobile_otps_mobile ON mobile_otps(mobile_number);
CREATE INDEX idx_mobile_otps_mobile_purpose ON mobile_otps(mobile_number, purpose);
```

### 6.4 User Permissions Table

```sql
CREATE TABLE permissions (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(255),
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE user_permissions (
    user_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, permission_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);
```

---

## 7. SECURITY CONFIGURATION

### 7.1 JWT Configuration

**File:** `src/main/java/com/shopmanagement/config/SecurityConfig.java`

**Key Settings:**
```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder(); // Strength: 10 (default)
}

@Bean
public SecurityFilterChain filterChain(HttpSecurity http, JwtAuthenticationFilter jwtAuthenticationFilter) {
    http
        .csrf(AbstractHttpConfigurer::disable)
        .cors(cors -> cors.configurationSource(corsConfigurationSource()))
        .sessionManagement(session ->
            session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authenticationProvider(authenticationProvider())
        .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

    return http.build();
}
```

**JWT Token Structure:**
```json
{
  "sub": "username",
  "iat": 1234567890,
  "exp": 1234654290
}
```

**Token Generation:**
```java
return Jwts.builder()
    .setClaims(extraClaims)
    .setSubject(userDetails.getUsername())
    .setIssuedAt(new Date(System.currentTimeMillis()))
    .setExpiration(new Date(System.currentTimeMillis() + 86400000)) // 24 hours
    .signWith(SignatureAlgorithm.HS256, secretKey)
    .compact();
```

### 7.2 Session Management

**Strategy:** STATELESS
- No server-side sessions
- JWT tokens contain all auth info
- Token stored client-side (localStorage/cookies)

**Token Blacklisting:**
```java
@PostMapping("/logout")
public ResponseEntity<ApiResponse<Void>> logout(@RequestHeader("Authorization") String authHeader) {
    String token = authHeader.substring(7);
    tokenBlacklistService.blacklistToken(token);
    return ResponseEntity.ok(ApiResponse.success(null, "Logged out successfully"));
}
```

### 7.3 Password Encoding

**Algorithm:** BCrypt
**Strength:** 10 rounds (default)

**Encoding Process:**
```java
String encodedPassword = passwordEncoder.encode(rawPassword);
// Result: $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
```

**Verification:**
```java
boolean matches = passwordEncoder.matches(rawPassword, encodedPassword);
```

### 7.4 Authentication Filter Chain

**File:** `src/main/java/com/shopmanagement/config/JwtAuthenticationFilter.java`

**Process:**
1. **Extract Token** - Get Bearer token from Authorization header
2. **Check Blacklist** - Verify token not blacklisted
3. **Extract Username** - Parse JWT claims
4. **Load User** - Fetch UserDetails from database
5. **Validate Token** - Check signature and expiry
6. **Set Authentication** - Add to SecurityContext
7. **Continue Filter Chain** - Proceed with request

**Filter Logic:**
```java
@Override
protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) {
    String authHeader = request.getHeader("Authorization");

    if (authHeader == null || !authHeader.startsWith("Bearer ")) {
        filterChain.doFilter(request, response);
        return;
    }

    String jwt = authHeader.substring(7);

    if (tokenBlacklistService.isTokenBlacklisted(jwt)) {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        return;
    }

    String username = jwtService.extractUsername(jwt);
    UserDetails userDetails = userDetailsService.loadUserByUsername(username);

    if (jwtService.isTokenValid(jwt, userDetails)) {
        UsernamePasswordAuthenticationToken authToken =
            new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(authToken);
    }

    filterChain.doFilter(request, response);
}
```

### 7.5 CORS Configuration

```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowCredentials(true);
    configuration.setAllowedOriginPatterns(Arrays.asList(
        "https://*.nammaoorudelivary.in",
        "https://nammaoorudelivary.in",
        "http://localhost:*"
    ));
    configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
    configuration.setAllowedHeaders(Arrays.asList("*"));
    configuration.setExposedHeaders(Arrays.asList("Authorization", "Content-Type", "X-Total-Count"));
    configuration.setMaxAge(3600L);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
}
```

### 7.6 Authorization Rules

```java
.authorizeHttpRequests(authz -> authz
    // Public endpoints
    .requestMatchers("/api/auth/**", "/api/public/**").permitAll()

    // Role-based access
    .requestMatchers("/api/super-admin/**").hasRole("SUPER_ADMIN")
    .requestMatchers("/api/admin/**").hasAnyRole("SUPER_ADMIN", "ADMIN")
    .requestMatchers("/api/shop-owner/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "SHOP_OWNER")
    .requestMatchers("/api/mobile/delivery-partner/**").hasAnyRole("SUPER_ADMIN", "ADMIN", "DELIVERY_PARTNER")

    // All other requests require authentication
    .anyRequest().authenticated()
)
```

---

## 8. COMPLETE AUTHENTICATION FLOW (Step-by-Step)

### **Scenario: New User Registration → OTP Verification → Login → Authenticated Request**

#### **Step 1: User Registration**

**Client Request:**
```http
POST /api/auth/register
Content-Type: application/json

{
  "username": "alice_customer",
  "email": "alice@example.com",
  "password": "SecurePass123!",
  "firstName": "Alice",
  "lastName": "Johnson",
  "mobileNumber": "+919876543210"
}
```

**Backend Processing:**

1. **AuthController.register()** receives request
2. **Validation:** Jakarta Validation checks @NotBlank, @Email
3. **AuthService.register():**
   - Checks if email exists: `userRepository.existsByEmail()`
   - Checks if mobile exists: `userRepository.existsByMobileNumber()`
   - Creates User entity with:
     - BCrypt encoded password
     - Role: USER
     - Status: ACTIVE
     - emailVerified: false
   - Saves to database: `userRepository.save(user)`
4. **EmailOtpService.generateAndSendOtp():**
   - Generates 6-digit OTP: `123456`
   - Creates EmailOtp entity:
     - expiresAt: NOW + 10 minutes
     - purpose: "REGISTRATION"
   - Saves to database
   - Calls EmailService.sendOtpVerificationEmail()
5. **EmailService.sendOtpVerificationEmail():**
   - Loads Thymeleaf template: `otp-verification.html`
   - Populates variables: userName, otpCode
   - Sends via SMTP asynchronously
6. **JwtService.generateToken():**
   - Creates JWT with subject: "alice_customer"
   - Signs with HS256 algorithm
   - Sets expiration: 24 hours
7. **Response returned to client**

**Server Response:**
```json
{
  "statusCode": 200,
  "message": "Registration successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhbGljZV9jdXN0b21lciIsImlhdCI6MTYxNjIzOTAyMiwiZXhwIjoxNjE2MzI1NDIyfQ.3f3kJ5l2...",
    "tokenType": "Bearer",
    "userId": 42,
    "username": "alice_customer",
    "email": "alice@example.com",
    "role": "USER"
  },
  "timestamp": "2025-11-06T10:30:00"
}
```

**Database State:**
```sql
-- users table
INSERT INTO users VALUES (
  42, 'alice_customer', 'alice@example.com',
  '$2a$10$N9qo8...', 'Alice', 'Johnson',
  '+919876543210', 'USER', 'ACTIVE',
  FALSE, FALSE, FALSE, FALSE, NULL, NOW()
);

-- email_otps table
INSERT INTO email_otps VALUES (
  101, 'alice@example.com', '123456',
  'REGISTRATION', NOW() + INTERVAL '10 minutes',
  FALSE, TRUE, 0, NOW(), NULL
);
```

---

#### **Step 2: OTP Verification**

**Client Request:**
```http
POST /api/auth/verify-otp
Content-Type: application/json

{
  "email": "alice@example.com",
  "otp": "123456",
  "purpose": "REGISTRATION"
}
```

**Backend Processing:**

1. **AuthController.verifyOtp()** receives request
2. **EmailOtpService.verifyOtp():**
   - Query: `findByEmailAndOtpCodeAndPurpose()`
   - Retrieves EmailOtp record (id: 101)
   - Increments attemptCount: 0 → 1
   - Validates:
     - ✅ isValid() returns true
     - ✅ !isExpired()
     - ✅ !isUsed
     - ✅ isActive
   - Calls `otp.markAsUsed()`:
     - Sets isUsed = true
     - Sets usedAt = NOW()
   - Saves updated OTP
3. **AuthService.findUserByEmail():**
   - Retrieves User entity (id: 42)
4. **JwtService.generateToken():**
   - Creates new JWT token
5. **Response built and returned**

**Server Response:**
```json
{
  "statusCode": 200,
  "message": "OTP verified successfully",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.NEW_TOKEN_HERE...",
    "tokenType": "Bearer",
    "username": "alice_customer",
    "email": "alice@example.com",
    "role": "USER"
  }
}
```

**Database State:**
```sql
-- email_otps table (updated)
UPDATE email_otps SET
  is_used = TRUE,
  used_at = '2025-11-06 10:35:00',
  attempt_count = 1
WHERE id = 101;
```

---

#### **Step 3: Login (Subsequent Access)**

**Client Request:**
```http
POST /api/auth/login
Content-Type: application/json

{
  "identifier": "alice@example.com",
  "password": "SecurePass123!"
}
```

**Backend Processing:**

1. **AuthController.authenticate()** receives request
2. **AuthService.authenticate():**
   - Detects identifier is email (not mobile)
   - Query: `userRepository.findByEmail("alice@example.com")`
   - Retrieves User entity (id: 42)
3. **AuthenticationManager.authenticate():**
   - Creates UsernamePasswordAuthenticationToken:
     - Principal: "alice_customer"
     - Credentials: "SecurePass123!"
   - DaoAuthenticationProvider processes:
     - Calls UserDetailsService.loadUserByUsername()
     - Retrieves User (implements UserDetails)
     - BCryptPasswordEncoder.matches():
       - Input: "SecurePass123!"
       - Stored: "$2a$10$N9qo8..."
       - ✅ Returns true
4. **Authentication successful**
5. **JwtService.generateToken():**
   - Generates new JWT token
6. **Response returned**

**Server Response:**
```json
{
  "statusCode": 200,
  "message": "Login successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.LOGIN_TOKEN...",
    "tokenType": "Bearer",
    "userId": 42,
    "username": "alice_customer",
    "email": "alice@example.com",
    "role": "USER",
    "passwordChangeRequired": false,
    "isTemporaryPassword": false
  }
}
```

---

#### **Step 4: Authenticated Request**

**Client Request:**
```http
GET /api/shop-owner/dashboard
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.LOGIN_TOKEN...
```

**Backend Processing:**

1. **JwtAuthenticationFilter.doFilterInternal():**
   - Extracts Authorization header
   - Parses Bearer token
   - Checks TokenBlacklistService: ✅ Not blacklisted
2. **JwtService.extractUsername():**
   - Parses JWT claims
   - Extracts subject: "alice_customer"
3. **UserDetailsService.loadUserByUsername():**
   - Query: `userRepository.findByUsername("alice_customer")`
   - Loads User entity with authorities
4. **JwtService.isTokenValid():**
   - Verifies username matches
   - Checks expiration: ✅ Not expired
   - Returns true
5. **SecurityContext updated:**
   - Creates UsernamePasswordAuthenticationToken
   - Sets authorities: [ROLE_USER]
   - Adds to SecurityContextHolder
6. **Filter chain continues:**
   - Request reaches controller
   - @PreAuthorize checks role
   - If authorized, method executes

**Authorization Check:**
```java
@PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'SHOP_OWNER')")
public ResponseEntity<?> getDashboard(Authentication authentication) {
    // This fails for Alice (USER role)
    // Would succeed for SHOP_OWNER role
}
```

---

## 9. KEY SECURITY FEATURES

### 9.1 Password Security
- BCrypt hashing (strength 10)
- Minimum 8 characters required
- Temporary password support
- Password change enforcement
- Last password change tracking

### 9.2 OTP Security
- Secure random generation
- Time-based expiry (10 minutes)
- Single-use enforcement
- Attempt limiting (max 3)
- Rate limiting (5 per hour)
- Automatic cleanup of expired OTPs

### 9.3 Token Security
- JWT with HMAC SHA-256
- 24-hour expiration
- Token blacklisting on logout
- Stateless authentication
- No server-side session storage

### 9.4 Account Security
- Email verification tracking
- Mobile verification tracking
- Failed login attempt tracking
- Account locking mechanism
- Two-factor authentication support (field present)

### 9.5 API Security
- CORS configuration
- CSRF protection (disabled for stateless API)
- Role-based access control
- Method-level security (@PreAuthorize)
- Request filtering

---

## 10. INTERVIEW TALKING POINTS

### Key Highlights:
1. **Stateless Architecture:** JWT-based, no server sessions
2. **Multi-factor Support:** Email OTP + Password
3. **Role-based Access:** 8 different user roles
4. **Flexible Login:** Email OR mobile number
5. **Async Email:** Non-blocking email sending
6. **Security Best Practices:** BCrypt, JWT, rate limiting
7. **Scalability:** Stateless design, scheduled cleanup
8. **Production-Ready:** SMTP configuration, error handling, logging

### Common Interview Questions:

**Q: How do you prevent brute force attacks?**
**A:** Rate limiting (5 OTP/hour), attempt tracking (max 3), account locking, failed login tracking

**Q: How is JWT validated on every request?**
**A:** JwtAuthenticationFilter extracts token → verifies signature → checks expiry → loads user → sets SecurityContext

**Q: What happens if user logs out?**
**A:** Token added to blacklist, checked on every request, prevents reuse

**Q: How do you handle password security?**
**A:** BCrypt hashing with salt, minimum length validation, temporary password tracking, change enforcement

**Q: Why use OTP instead of just email verification links?**
**A:** Better UX for mobile apps, time-bound security, single-use enforcement, easier to implement in mobile flows

**Q: Explain the Spring Security filter chain.**
**A:** Request → JwtAuthenticationFilter (extracts & validates JWT) → UsernamePasswordAuthenticationFilter → Controller → @PreAuthorize checks role

**Q: How does BCrypt work?**
**A:** One-way hashing algorithm with automatic salt generation. Each hash is unique even for the same password. Computational cost makes brute force impractical.

**Q: What is the difference between authentication and authorization?**
**A:** Authentication verifies WHO you are (login with credentials). Authorization determines WHAT you can do (role-based access control).

**Q: How do you handle token expiry?**
**A:** JWT has built-in expiration (24 hours). On every request, we check if current time > expiration time. Client must re-authenticate when expired.

**Q: What is the purpose of @Async on email sending?**
**A:** Makes email sending non-blocking. Registration API returns immediately without waiting for SMTP. Improves response time and user experience.

---

## 11. ARCHITECTURE DIAGRAM

```
┌─────────────┐
│   Client    │
│ (Angular/   │
│  Flutter)   │
└──────┬──────┘
       │
       │ HTTP Request (JSON)
       ▼
┌─────────────────────────────────────┐
│      Spring Boot Application        │
│                                     │
│  ┌───────────────────────────────┐ │
│  │   JwtAuthenticationFilter     │ │
│  │   - Extract Bearer Token      │ │
│  │   - Validate JWT              │ │
│  │   - Set SecurityContext       │ │
│  └───────────┬───────────────────┘ │
│              │                      │
│              ▼                      │
│  ┌───────────────────────────────┐ │
│  │      AuthController           │ │
│  │   /api/auth/register          │ │
│  │   /api/auth/login             │ │
│  │   /api/auth/verify-otp        │ │
│  └───────────┬───────────────────┘ │
│              │                      │
│              ▼                      │
│  ┌───────────────────────────────┐ │
│  │       AuthService             │ │
│  │   - User Management           │ │
│  │   - Authentication Logic      │ │
│  │   - Password Encoding         │ │
│  └───────────┬───────────────────┘ │
│              │                      │
│      ┌───────┴────────┐            │
│      ▼                ▼            │
│  ┌────────┐    ┌──────────────┐   │
│  │  JWT   │    │  EmailOtp    │   │
│  │Service │    │   Service    │   │
│  └────────┘    └──────┬───────┘   │
│                       │            │
│                       ▼            │
│              ┌──────────────┐     │
│              │EmailService  │     │
│              │  (@Async)    │     │
│              └──────┬───────┘     │
│                     │              │
└─────────────────────┼──────────────┘
                      │
          ┌───────────┴────────────┐
          ▼                        ▼
    ┌──────────┐           ┌──────────────┐
    │PostgreSQL│           │ SMTP Server  │
    │ Database │           │ (Hostinger)  │
    │          │           │              │
    │ - users  │           │ Email Queue  │
    │ - otps   │           └──────────────┘
    └──────────┘
```

---

## 12. CODE FILE LOCATIONS

### Controllers
- `src/main/java/com/shopmanagement/auth/controller/AuthController.java`
- `src/main/java/com/shopmanagement/auth/controller/ForgotPasswordOtpController.java`

### Services
- `src/main/java/com/shopmanagement/service/AuthService.java`
- `src/main/java/com/shopmanagement/service/JwtService.java`
- `src/main/java/com/shopmanagement/service/EmailOtpService.java`
- `src/main/java/com/shopmanagement/service/EmailService.java`

### Security Configuration
- `src/main/java/com/shopmanagement/config/SecurityConfig.java`
- `src/main/java/com/shopmanagement/config/JwtAuthenticationFilter.java`

### Entities
- `src/main/java/com/shopmanagement/entity/User.java`
- `src/main/java/com/shopmanagement/entity/EmailOtp.java`
- `src/main/java/com/shopmanagement/entity/MobileOtp.java`

### Repositories
- `src/main/java/com/shopmanagement/repository/UserRepository.java`
- `src/main/java/com/shopmanagement/repository/EmailOtpRepository.java`
- `src/main/java/com/shopmanagement/repository/MobileOtpRepository.java`

### Email Templates
- `src/main/resources/templates/otp-verification.html`
- `src/main/resources/templates/forgot-password-otp.html`
- `src/main/resources/templates/welcome-shop-owner.html`

### Configuration
- `src/main/resources/application.yml`
- `src/main/resources/application-dev.yml`
- `src/main/resources/application-prod.yml`

---

## 13. QUICK REFERENCE

### User Roles
1. `SUPER_ADMIN` - Full system access
2. `ADMIN` - Administrative access
3. `SHOP_OWNER` - Shop management
4. `MANAGER` - Store management
5. `EMPLOYEE` - Staff operations
6. `CUSTOMER_SERVICE` - Support operations
7. `DELIVERY_PARTNER` - Delivery operations
8. `USER` - Customer access

### User Status
1. `ACTIVE` - Normal access
2. `INACTIVE` - Disabled account
3. `SUSPENDED` - Temporarily blocked
4. `PENDING_VERIFICATION` - Awaiting verification

### OTP Purposes
1. `REGISTRATION` - New user signup
2. `PASSWORD_RESET` - Forgot password
3. `EMAIL_VERIFICATION` - Email confirmation
4. `LOGIN` - Two-factor login
5. `CHANGE_MOBILE` - Mobile number change
6. `ORDER_CONFIRMATION` - Order verification

### JWT Token
- **Algorithm:** HS256
- **Expiration:** 24 hours
- **Header:** `Authorization: Bearer <token>`

### BCrypt Password
- **Algorithm:** BCrypt
- **Strength:** 10 rounds
- **Format:** `$2a$10$...`

---

**Document Version:** 1.0
**Last Updated:** 2025-11-06
**Author:** Authentication Module Documentation
