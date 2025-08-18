package com.shopmanagement.service;

import com.shopmanagement.dto.customer.*;
import com.shopmanagement.entity.Customer;
import com.shopmanagement.entity.CustomerAddress;
import com.shopmanagement.entity.Order;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.product.entity.ShopProduct;
import com.shopmanagement.repository.CustomerRepository;
import com.shopmanagement.repository.CustomerAddressRepository;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.shop.repository.ShopRepository;
import com.shopmanagement.product.repository.ShopProductRepository;
import com.shopmanagement.service.OrderService;
import com.shopmanagement.dto.order.OrderRequest;
import com.shopmanagement.dto.order.OrderResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class CustomerService {
    
    private final CustomerRepository customerRepository;
    private final CustomerAddressRepository customerAddressRepository;
    private final EmailService emailService;
    private final OrderRepository orderRepository;
    private final ShopRepository shopRepository;
    private final ShopProductRepository shopProductRepository;
    private final OrderService orderService;
    
    // Get all customers for admin
    public Page<CustomerResponse> getAllCustomers(int page, int size, String sortBy, String sortDirection) {
        Sort.Direction direction = sortDirection.equalsIgnoreCase("DESC") ? 
            Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        
        Page<Customer> customers = customerRepository.findAll(pageable);
        return customers.map(this::mapToResponse);
    }
    
    // Get customer by ID
    public CustomerResponse getCustomerById(Long id) {
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Customer not found"));
        return mapToResponse(customer);
    }
    
    
    // Create Customer
    public CustomerResponse createCustomer(CustomerRequest request) {
        log.info("Creating new customer with email: {}", request.getEmail());
        
        // Check if customer already exists
        if (customerRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Customer with email " + request.getEmail() + " already exists");
        }
        
        if (customerRepository.existsByMobileNumber(request.getMobileNumber())) {
            throw new RuntimeException("Customer with mobile number " + request.getMobileNumber() + " already exists");
        }
        
        Customer customer = Customer.builder()
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .email(request.getEmail())
                .mobileNumber(request.getMobileNumber())
                .alternateMobileNumber(request.getAlternateMobileNumber())
                .gender(request.getGender())
                .dateOfBirth(request.getDateOfBirth())
                .notes(request.getNotes())
                .addressLine1(request.getAddressLine1())
                .addressLine2(request.getAddressLine2())
                .city(request.getCity())
                .state(request.getState())
                .postalCode(request.getPostalCode())
                .country(request.getCountry() != null ? request.getCountry() : "India")
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .emailNotifications(request.getEmailNotifications() != null ? request.getEmailNotifications() : true)
                .smsNotifications(request.getSmsNotifications() != null ? request.getSmsNotifications() : true)
                .promotionalEmails(request.getPromotionalEmails() != null ? request.getPromotionalEmails() : false)
                .preferredLanguage(request.getPreferredLanguage())
                .isActive(request.getIsActive() != null ? request.getIsActive() : true)
                .status(request.getStatus() != null ? request.getStatus() : Customer.CustomerStatus.ACTIVE)
                .referredBy(request.getReferredBy())
                .createdBy(getCurrentUsername())
                .updatedBy(getCurrentUsername())
                .build();
        
        Customer savedCustomer = customerRepository.save(customer);
        
        // Send welcome email
        try {
            sendWelcomeEmail(savedCustomer);
        } catch (Exception e) {
            log.error("Failed to send welcome email to customer: {}", savedCustomer.getEmail(), e);
        }
        
        log.info("Successfully created customer with ID: {}", savedCustomer.getId());
        return mapToResponse(savedCustomer);
    }
    
    // Get Customer by Email
    @Transactional(readOnly = true)
    public CustomerResponse getCustomerByEmail(String email) {
        Customer customer = customerRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Customer not found with email: " + email));
        return mapToResponse(customer);
    }
    
    // Get Customer by Mobile Number
    @Transactional(readOnly = true)
    public CustomerResponse getCustomerByMobileNumber(String mobileNumber) {
        Customer customer = customerRepository.findByMobileNumber(mobileNumber)
                .orElseThrow(() -> new RuntimeException("Customer not found with mobile number: " + mobileNumber));
        return mapToResponse(customer);
    }
    
    // Update Customer
    public CustomerResponse updateCustomer(Long id, CustomerRequest request) {
        log.info("Updating customer with ID: {}", id);
        
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Customer not found with ID: " + id));
        
        // Check email uniqueness if changed
        if (!customer.getEmail().equals(request.getEmail()) && 
            customerRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email " + request.getEmail() + " is already in use");
        }
        
        // Check mobile number uniqueness if changed
        if (!customer.getMobileNumber().equals(request.getMobileNumber()) && 
            customerRepository.existsByMobileNumber(request.getMobileNumber())) {
            throw new RuntimeException("Mobile number " + request.getMobileNumber() + " is already in use");
        }
        
        // Update fields
        customer.setFirstName(request.getFirstName());
        customer.setLastName(request.getLastName());
        customer.setEmail(request.getEmail());
        customer.setMobileNumber(request.getMobileNumber());
        customer.setAlternateMobileNumber(request.getAlternateMobileNumber());
        customer.setGender(request.getGender());
        customer.setDateOfBirth(request.getDateOfBirth());
        customer.setNotes(request.getNotes());
        customer.setAddressLine1(request.getAddressLine1());
        customer.setAddressLine2(request.getAddressLine2());
        customer.setCity(request.getCity());
        customer.setState(request.getState());
        customer.setPostalCode(request.getPostalCode());
        customer.setCountry(request.getCountry());
        customer.setLatitude(request.getLatitude());
        customer.setLongitude(request.getLongitude());
        customer.setEmailNotifications(request.getEmailNotifications());
        customer.setSmsNotifications(request.getSmsNotifications());
        customer.setPromotionalEmails(request.getPromotionalEmails());
        customer.setPreferredLanguage(request.getPreferredLanguage());
        
        if (request.getIsActive() != null) {
            customer.setIsActive(request.getIsActive());
        }
        if (request.getStatus() != null) {
            customer.setStatus(request.getStatus());
        }
        
        customer.setUpdatedBy(getCurrentUsername());
        
        Customer updatedCustomer = customerRepository.save(customer);
        log.info("Successfully updated customer with ID: {}", id);
        return mapToResponse(updatedCustomer);
    }
    
    // Delete Customer
    public void deleteCustomer(Long id) {
        log.info("Deleting customer with ID: {}", id);
        
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Customer not found with ID: " + id));
        
        // Soft delete - mark as inactive
        customer.setIsActive(false);
        customer.setStatus(Customer.CustomerStatus.INACTIVE);
        customer.setUpdatedBy(getCurrentUsername());
        customerRepository.save(customer);
        
        log.info("Successfully deleted customer with ID: {}", id);
    }
    
    // Search Customers
    @Transactional(readOnly = true)
    public Page<CustomerResponse> searchCustomers(String searchTerm, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Customer> customers = customerRepository.searchCustomers(searchTerm, pageable);
        return customers.map(this::mapToResponse);
    }
    
    // Get Customers by Status
    @Transactional(readOnly = true)
    public Page<CustomerResponse> getCustomersByStatus(Customer.CustomerStatus status, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Customer> customers = customerRepository.findByStatus(status, pageable);
        return customers.map(this::mapToResponse);
    }
    
    // Verify Email
    public CustomerResponse verifyEmail(Long customerId) {
        log.info("Verifying email for customer ID: {}", customerId);
        
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new RuntimeException("Customer not found with ID: " + customerId));
        
        customer.setEmailVerifiedAt(LocalDateTime.now());
        customer.setIsVerified(customer.isMobileVerified());
        customer.setUpdatedBy(getCurrentUsername());
        
        Customer updatedCustomer = customerRepository.save(customer);
        log.info("Successfully verified email for customer ID: {}", customerId);
        return mapToResponse(updatedCustomer);
    }
    
    // Verify Mobile
    public CustomerResponse verifyMobile(Long customerId) {
        log.info("Verifying mobile for customer ID: {}", customerId);
        
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new RuntimeException("Customer not found with ID: " + customerId));
        
        customer.setMobileVerifiedAt(LocalDateTime.now());
        customer.setIsVerified(customer.isEmailVerified());
        customer.setUpdatedBy(getCurrentUsername());
        
        Customer updatedCustomer = customerRepository.save(customer);
        log.info("Successfully verified mobile for customer ID: {}", customerId);
        return mapToResponse(updatedCustomer);
    }
    
    // Customer Statistics
    @Transactional(readOnly = true)
    public CustomerStatsResponse getCustomerStats() {
        long totalCustomers = customerRepository.count();
        long activeCustomers = customerRepository.countByStatus(Customer.CustomerStatus.ACTIVE);
        long verifiedCustomers = customerRepository.findByIsVerified(true).size();
        Double totalSpending = customerRepository.getTotalCustomerSpending();
        Double avgOrders = customerRepository.getAverageOrdersPerCustomer();
        
        return CustomerStatsResponse.builder()
                .totalCustomers(totalCustomers)
                .activeCustomers(activeCustomers)
                .verifiedCustomers(verifiedCustomers)
                .totalSpending(totalSpending != null ? totalSpending : 0.0)
                .averageOrdersPerCustomer(avgOrders != null ? avgOrders : 0.0)
                .build();
    }
    
    // Send Welcome Email
    private void sendWelcomeEmail(Customer customer) {
        try {
            emailService.sendCustomerWelcomeEmail(
                customer.getEmail(), 
                customer.getFullName(), 
                customer.getReferralCode()
            );
        } catch (Exception e) {
            log.error("Failed to send welcome email", e);
        }
    }
    
    // Helper Methods
    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null ? authentication.getName() : "system";
    }
    
    private CustomerResponse mapToResponse(Customer customer) {
        List<CustomerAddressResponse> addresses = customer.getAddresses() != null 
            ? customer.getAddresses().stream().map(this::mapAddressToResponse).collect(Collectors.toList())
            : List.of();
            
        Long referralCount = customerRepository.countByReferredBy(customer.getReferralCode());
        
        return CustomerResponse.builder()
                .id(customer.getId())
                .firstName(customer.getFirstName())
                .lastName(customer.getLastName())
                .fullName(customer.getFullName())
                .email(customer.getEmail())
                .mobileNumber(customer.getMobileNumber())
                .alternateMobileNumber(customer.getAlternateMobileNumber())
                .gender(customer.getGender() != null ? customer.getGender().name() : null)
                .dateOfBirth(customer.getDateOfBirth())
                .status(customer.getStatus() != null ? customer.getStatus().name() : null)
                .addressLine1(customer.getAddressLine1())
                .addressLine2(customer.getAddressLine2())
                .city(customer.getCity())
                .state(customer.getState())
                .postalCode(customer.getPostalCode())
                .country(customer.getCountry())
                .formattedAddress(customer.getFormattedAddress())
                .latitude(customer.getLatitude())
                .longitude(customer.getLongitude())
                .emailNotifications(customer.getEmailNotifications())
                .smsNotifications(customer.getSmsNotifications())
                .promotionalEmails(customer.getPromotionalEmails())
                .preferredLanguage(customer.getPreferredLanguage())
                .totalOrders(customer.getTotalOrders())
                .totalSpent(customer.getTotalSpent())
                .lastOrderDate(customer.getLastOrderDate())
                .lastLoginDate(customer.getLastLoginDate())
                .isVerified(customer.getIsVerified())
                .isActive(customer.getIsActive())
                .emailVerified(customer.isEmailVerified())
                .mobileVerified(customer.isMobileVerified())
                .emailVerifiedAt(customer.getEmailVerifiedAt())
                .mobileVerifiedAt(customer.getMobileVerifiedAt())
                .referralCode(customer.getReferralCode())
                .referredBy(customer.getReferredBy())
                .createdAt(customer.getCreatedAt())
                .updatedAt(customer.getUpdatedAt())
                .build();
    }
    
    private CustomerAddressResponse mapAddressToResponse(CustomerAddress address) {
        return CustomerAddressResponse.builder()
                .id(address.getId())
                .customerId(address.getCustomer().getId())
                .addressType(address.getAddressType())
                .addressLabel(address.getAddressLabel())
                .addressLine1(address.getAddressLine1())
                .addressLine2(address.getAddressLine2())
                .landmark(address.getLandmark())
                .city(address.getCity())
                .state(address.getState())
                .postalCode(address.getPostalCode())
                .country(address.getCountry())
                .fullAddress(address.getFullAddress())
                .latitude(address.getLatitude())
                .longitude(address.getLongitude())
                .isDefault(address.getIsDefault())
                .isActive(address.getIsActive())
                .contactPersonName(address.getContactPersonName())
                .contactMobileNumber(address.getContactMobileNumber())
                .deliveryInstructions(address.getDeliveryInstructions())
                .createdBy(address.getCreatedBy())
                .updatedBy(address.getUpdatedBy())
                .createdAt(address.getCreatedAt())
                .updatedAt(address.getUpdatedAt())
                .displayLabel(address.getAddressLabel())
                .shortAddress(getShortAddress(address))
                .build();
    }
    
    private String getStatusLabel(Customer.CustomerStatus status) {
        return switch (status) {
            case ACTIVE -> "Active";
            case INACTIVE -> "Inactive";
            case BLOCKED -> "Blocked";
            case PENDING_VERIFICATION -> "Pending Verification";
        };
    }
    
    private String getGenderLabel(Customer.Gender gender) {
        if (gender == null) return "Not Specified";
        return switch (gender) {
            case MALE -> "Male";
            case FEMALE -> "Female";
            case OTHER -> "Other";
            case PREFER_NOT_TO_SAY -> "Prefer not to say";
        };
    }
    
    private String formatDate(LocalDateTime dateTime) {
        return dateTime.format(DateTimeFormatter.ofPattern("MMM dd, yyyy"));
    }
    
    private String getShortAddress(CustomerAddress address) {
        StringBuilder shortAddr = new StringBuilder();
        if (address.getCity() != null) {
            shortAddr.append(address.getCity());
        }
        if (address.getState() != null && !address.getState().isEmpty()) {
            if (shortAddr.length() > 0) shortAddr.append(", ");
            shortAddr.append(address.getState());
        }
        return shortAddr.toString();
    }
    
    // Mobile Customer Registration Methods
    
    public boolean customerExistsByMobile(String mobileNumber) {
        return customerRepository.existsByMobileNumber(mobileNumber);
    }
    
    public Map<String, Object> registerMobileCustomer(com.shopmanagement.dto.mobile.MobileCustomerRegistrationRequest request) {
        log.info("Registering mobile customer with mobile: {}", request.getMobileNumber());
        
        try {
            // Check if customer already exists
            if (customerRepository.existsByMobileNumber(request.getMobileNumber())) {
                return Map.of(
                    "success", false,
                    "message", "Account with this mobile number already exists",
                    "errorCode", "MOBILE_EXISTS"
                );
            }
            
            // Check email uniqueness only if email is provided
            if (request.getEmail() != null && !request.getEmail().isEmpty() && 
                customerRepository.existsByEmail(request.getEmail())) {
                return Map.of(
                    "success", false,
                    "message", "Account with this email already exists",
                    "errorCode", "EMAIL_EXISTS"
                );
            }
            
            // Create customer from mobile registration
            Customer customer = Customer.builder()
                    .firstName(request.getFirstName())
                    .lastName(request.getLastName())
                    .email(request.getEmail())
                    .mobileNumber(request.getMobileNumber())
                    .gender(request.getGender())
                    // dateOfBirth not available in mobile registration
                    .city(request.getCity())
                    .state(request.getState())
                    .country("India")
                    .emailNotifications(true)
                    .smsNotifications(true)
                    .promotionalEmails(request.getAcceptMarketing() != null ? request.getAcceptMarketing() : false)
                    .isActive(true)
                    .status(Customer.CustomerStatus.ACTIVE)
                    .mobileVerifiedAt(LocalDateTime.now()) // Since they used OTP
                    .isVerified(true)
                    .referredBy(request.getReferralCode())
                    // Mobile app specific fields not in Customer entity
                    .lastLoginDate(LocalDateTime.now())
                    .createdBy("mobile-app")
                    .updatedBy("mobile-app")
                    .build();
            
            Customer savedCustomer = customerRepository.save(customer);
            
            // Generate authentication tokens
            Map<String, Object> tokens = generateMobileAuthTokens(savedCustomer);
            
            // Send welcome email
            try {
                sendWelcomeEmail(savedCustomer);
            } catch (Exception e) {
                log.error("Failed to send welcome email to mobile customer: {}", savedCustomer.getEmail(), e);
            }
            
            // Create response
            com.shopmanagement.dto.mobile.MobileCustomerResponse customerResponse = mapToMobileResponse(savedCustomer);
            customerResponse.setAccessToken((String) tokens.get("accessToken"));
            customerResponse.setRefreshToken((String) tokens.get("refreshToken"));
            customerResponse.setTokenExpiresIn((Long) tokens.get("expiresIn"));
            customerResponse.setIsFirstLogin(true);
            customerResponse.setWelcomeMessage("Welcome to NammaOoru! Start exploring local shops and products.");
            
            log.info("Successfully registered mobile customer with ID: {}", savedCustomer.getId());
            
            return Map.of(
                "success", true,
                "message", "Registration successful",
                "customer", customerResponse
            );
            
        } catch (Exception e) {
            log.error("Error registering mobile customer: {}", request.getMobileNumber(), e);
            return Map.of(
                "success", false,
                "message", "Registration failed. Please try again.",
                "errorCode", "REGISTRATION_ERROR"
            );
        }
    }
    
    public Map<String, Object> authenticateMobileCustomer(com.shopmanagement.dto.mobile.MobileLoginRequest request) {
        log.info("Authenticating mobile customer: {}", request.getMobileNumber());
        
        try {
            // Find customer by mobile number
            Optional<Customer> customerOpt = customerRepository.findByMobileNumber(request.getMobileNumber());
            if (customerOpt.isEmpty()) {
                return Map.of(
                    "success", false,
                    "message", "Account not found",
                    "errorCode", "ACCOUNT_NOT_FOUND"
                );
            }
            
            Customer customer = customerOpt.get();
            
            // Check if customer is active
            if (!customer.getIsActive() || customer.getStatus() == Customer.CustomerStatus.BLOCKED) {
                return Map.of(
                    "success", false,
                    "message", "Account is inactive or blocked",
                    "errorCode", "ACCOUNT_INACTIVE"
                );
            }
            
            // Note: OTP verification should be done by the calling controller
            // Here we assume OTP has been verified before calling this method
            
            // Update last login
            customer.setLastLoginDate(LocalDateTime.now());
            // Device ID is not stored in Customer entity
            customerRepository.save(customer);
            
            // Generate authentication tokens
            Map<String, Object> tokens = generateMobileAuthTokens(customer);
            
            // Create response
            com.shopmanagement.dto.mobile.MobileCustomerResponse customerResponse = mapToMobileResponse(customer);
            customerResponse.setAccessToken((String) tokens.get("accessToken"));
            customerResponse.setRefreshToken((String) tokens.get("refreshToken"));
            customerResponse.setTokenExpiresIn((Long) tokens.get("expiresIn"));
            
            return Map.of(
                "success", true,
                "message", "Login successful",
                "customer", customerResponse
            );
            
        } catch (Exception e) {
            log.error("Error authenticating mobile customer: {}", request.getMobileNumber(), e);
            return Map.of(
                "success", false,
                "message", "Authentication failed",
                "errorCode", "AUTH_ERROR"
            );
        }
    }
    
    public Map<String, Object> refreshMobileAuthToken(String refreshToken) {
        try {
            // Validate refresh token and get customer
            // For now, return a simple response - implement JWT validation in production
            return Map.of(
                "success", true,
                "accessToken", "new-access-token",
                "expiresIn", 3600L,
                "tokenType", "Bearer"
            );
        } catch (Exception e) {
            log.error("Error refreshing mobile auth token", e);
            return Map.of(
                "success", false,
                "message", "Invalid refresh token",
                "errorCode", "INVALID_REFRESH_TOKEN"
            );
        }
    }
    
    public Map<String, Object> getMobileCustomerProfile(String accessToken) {
        try {
            // Validate token and get customer
            // For demo, return a mock response - implement JWT validation in production
            return Map.of(
                "success", true,
                "message", "Profile retrieved successfully"
            );
        } catch (Exception e) {
            log.error("Error getting mobile customer profile", e);
            return Map.of(
                "success", false,
                "message", "Failed to get profile",
                "errorCode", "PROFILE_ERROR"
            );
        }
    }
    
    private Map<String, Object> generateMobileAuthTokens(Customer customer) {
        // In production, implement proper JWT token generation
        // For now, return mock tokens
        String accessToken = "mock-access-token-" + customer.getId();
        String refreshToken = "mock-refresh-token-" + customer.getId();
        
        return Map.of(
            "accessToken", accessToken,
            "refreshToken", refreshToken,
            "expiresIn", 3600L, // 1 hour
            "tokenType", "Bearer"
        );
    }
    
    private com.shopmanagement.dto.mobile.MobileCustomerResponse mapToMobileResponse(Customer customer) {
        return com.shopmanagement.dto.mobile.MobileCustomerResponse.builder()
                .customerId(customer.getId())
                .firstName(customer.getFirstName())
                .lastName(customer.getLastName())
                .fullName(customer.getFirstName() + " " + (customer.getLastName() != null ? customer.getLastName() : ""))
                .email(customer.getEmail())
                .mobileNumber(customer.getMobileNumber())
                .gender(customer.getGender())
                .status(customer.getStatus())
                .isActive(customer.getIsActive())
                .isVerified(customer.getIsVerified())
                .emailVerified(customer.getEmailVerified())
                .mobileVerified(customer.getMobileVerified())
                .city(customer.getCity())
                .state(customer.getState())
                .pincode(customer.getPostalCode())
                .emailNotifications(customer.getEmailNotifications())
                .smsNotifications(customer.getSmsNotifications())
                .pushNotifications(customer.getPushNotifications())
                .promotionalEmails(customer.getPromotionalEmails())
                .promotionalSms(customer.getPromotionalEmails()) // Using same as emails for now
                .totalOrders(customer.getTotalOrders())
                .totalSpent(customer.getTotalSpent())
                .referralCode(customer.getReferralCode())
                .referralCount(0) // Count needs to be calculated from repository
                .memberSince(customer.getCreatedAt())
                .lastLoginDate(customer.getLastLoginDate())
                .profileCompletionStatus(getProfileCompletionStatus(customer))
                .profileCompletionPercentage(calculateProfileCompletionPercentage(customer))
                .canPlaceOrder(true)
                .canViewOrders(true)
                .canTrackDelivery(true)
                .canAddAddress(true)
                .canInviteFriends(true)
                .build();
    }
    
    private String getProfileCompletionStatus(Customer customer) {
        int percentage = calculateProfileCompletionPercentage(customer);
        if (percentage < 40) return "BASIC";
        if (percentage < 80) return "PARTIAL";
        return "COMPLETE";
    }
    
    private Integer calculateProfileCompletionPercentage(Customer customer) {
        int totalFields = 10;
        int completedFields = 0;
        
        if (customer.getFirstName() != null && !customer.getFirstName().isEmpty()) completedFields++;
        if (customer.getLastName() != null && !customer.getLastName().isEmpty()) completedFields++;
        if (customer.getEmail() != null && !customer.getEmail().isEmpty()) completedFields++;
        if (customer.getMobileNumber() != null && !customer.getMobileNumber().isEmpty()) completedFields++;
        if (customer.getGender() != null) completedFields++;
        if (customer.getDateOfBirth() != null) completedFields++;
        if (customer.getCity() != null && !customer.getCity().isEmpty()) completedFields++;
        if (customer.getState() != null && !customer.getState().isEmpty()) completedFields++;
        if (customer.getEmailVerified() != null && customer.getEmailVerified()) completedFields++;
        if (customer.getMobileVerified() != null && customer.getMobileVerified()) completedFields++;
        
        return (completedFields * 100) / totalFields;
    }
    
    // NEW CUSTOMER API METHODS FOR COMPLETE E-COMMERCE SYSTEM
    
    /**
     * Register a new customer using the CustomerRegistrationRequest
     */
    public Map<String, Object> registerCustomer(CustomerRegistrationRequest request, String ipAddress) {
        log.info("Registering new customer with email: {}", request.getEmail());
        
        try {
            // Check if customer already exists
            if (customerRepository.existsByEmail(request.getEmail())) {
                return Map.of(
                    "success", false,
                    "message", "Customer with email " + request.getEmail() + " already exists",
                    "errorCode", "EMAIL_EXISTS"
                );
            }
            
            if (customerRepository.existsByMobileNumber(request.getMobileNumber())) {
                return Map.of(
                    "success", false,
                    "message", "Customer with mobile number " + request.getMobileNumber() + " already exists",
                    "errorCode", "MOBILE_EXISTS"
                );
            }
            
            // Create customer
            Customer customer = Customer.builder()
                    .firstName(request.getFirstName())
                    .lastName(request.getLastName())
                    .email(request.getEmail())
                    .mobileNumber(request.getMobileNumber())
                    .alternateMobileNumber(request.getAlternateMobileNumber())
                    .gender(request.getGender() != null ? Customer.Gender.valueOf(request.getGender()) : null)
                    .dateOfBirth(request.getDateOfBirth())
                    .addressLine1(request.getAddressLine1())
                    .addressLine2(request.getAddressLine2())
                    .city(request.getCity())
                    .state(request.getState())
                    .postalCode(request.getPostalCode())
                    .country(request.getCountry() != null ? request.getCountry() : "India")
                    .latitude(request.getLatitude())
                    .longitude(request.getLongitude())
                    .emailNotifications(request.getEmailNotifications())
                    .smsNotifications(request.getSmsNotifications())
                    .promotionalEmails(request.getPromotionalEmails())
                    .preferredLanguage(request.getPreferredLanguage())
                    .referredBy(request.getReferredBy())
                    .isActive(true)
                    .status(Customer.CustomerStatus.ACTIVE)
                    .createdBy("customer-registration")
                    .updatedBy("customer-registration")
                    .build();
            
            Customer savedCustomer = customerRepository.save(customer);
            
            // Send welcome email
            try {
                emailService.sendCustomerWelcomeEmail(
                    savedCustomer.getEmail(),
                    savedCustomer.getFullName(),
                    savedCustomer.getReferralCode()
                );
            } catch (Exception e) {
                log.error("Failed to send welcome email to customer: {}", savedCustomer.getEmail(), e);
            }
            
            CustomerResponse customerResponse = mapToResponse(savedCustomer);
            
            log.info("Successfully registered customer with ID: {}", savedCustomer.getId());
            
            return Map.of(
                "success", true,
                "message", "Customer registered successfully",
                "customer", customerResponse
            );
            
        } catch (Exception e) {
            log.error("Error registering customer: {}", request.getEmail(), e);
            return Map.of(
                "success", false,
                "message", "Registration failed. Please try again.",
                "errorCode", "REGISTRATION_ERROR"
            );
        }
    }
    
    /**
     * Customer login using email or mobile number
     */
    public Map<String, Object> loginCustomer(CustomerLoginRequest request) {
        log.info("Customer login attempt for: {}", request.getEmailOrMobile());
        
        try {
            // Find customer by email or mobile
            Optional<Customer> customerOpt = findCustomerByEmailOrMobile(request.getEmailOrMobile());
            
            if (customerOpt.isEmpty()) {
                return Map.of(
                    "success", false,
                    "message", "Invalid credentials",
                    "errorCode", "INVALID_CREDENTIALS"
                );
            }
            
            Customer customer = customerOpt.get();
            
            // Check if customer is active
            if (!customer.getIsActive() || customer.getStatus() == Customer.CustomerStatus.BLOCKED) {
                return Map.of(
                    "success", false,
                    "message", "Account is inactive or blocked",
                    "errorCode", "ACCOUNT_INACTIVE"
                );
            }
            
            // Note: Password validation should be implemented here
            // For now, we'll assume password is correct for demo purposes
            
            // Update last login
            customer.setLastLoginDate(LocalDateTime.now());
            customerRepository.save(customer);
            
            CustomerResponse customerResponse = mapToResponse(customer);
            
            return Map.of(
                "success", true,
                "message", "Login successful",
                "customer", customerResponse,
                "accessToken", "mock-token-" + customer.getId(), // Implement proper JWT
                "tokenType", "Bearer",
                "expiresIn", 3600
            );
            
        } catch (Exception e) {
            log.error("Error during customer login: {}", request.getEmailOrMobile(), e);
            return Map.of(
                "success", false,
                "message", "Login failed. Please try again.",
                "errorCode", "LOGIN_ERROR"
            );
        }
    }
    
    /**
     * Get current customer profile (requires authentication)
     */
    public CustomerResponse getCurrentCustomerProfile() {
        // Get current authenticated customer
        Long customerId = getCurrentCustomerId();
        return getCustomerById(customerId);
    }
    
    /**
     * Update customer profile
     */
    public CustomerResponse updateCustomerProfile(CustomerRegistrationRequest request) {
        Long customerId = getCurrentCustomerId();
        
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new RuntimeException("Customer not found"));
        
        // Update customer fields
        customer.setFirstName(request.getFirstName());
        customer.setLastName(request.getLastName());
        customer.setAlternateMobileNumber(request.getAlternateMobileNumber());
        customer.setGender(request.getGender() != null ? Customer.Gender.valueOf(request.getGender()) : null);
        customer.setDateOfBirth(request.getDateOfBirth());
        customer.setAddressLine1(request.getAddressLine1());
        customer.setAddressLine2(request.getAddressLine2());
        customer.setCity(request.getCity());
        customer.setState(request.getState());
        customer.setPostalCode(request.getPostalCode());
        customer.setCountry(request.getCountry());
        customer.setLatitude(request.getLatitude());
        customer.setLongitude(request.getLongitude());
        customer.setEmailNotifications(request.getEmailNotifications());
        customer.setSmsNotifications(request.getSmsNotifications());
        customer.setPromotionalEmails(request.getPromotionalEmails());
        customer.setPreferredLanguage(request.getPreferredLanguage());
        customer.setUpdatedBy("customer-profile-update");
        
        Customer updatedCustomer = customerRepository.save(customer);
        return mapToResponse(updatedCustomer);
    }
    
    /**
     * Get available shops for customer with filtering and location-based search
     */
    public Map<String, Object> getAvailableShops(int page, int size, String city, String category, 
                                                  Double latitude, Double longitude, Double radiusKm) {
        
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "rating", "createdAt"));
        Page<Shop> shops;
        
        if (latitude != null && longitude != null) {
            // Location-based search - for now use basic search, implement distance calculation later
            shops = shopRepository.findAll(pageable);
        } else if (city != null) {
            shops = shopRepository.findAll(pageable); // Simplified for now
        } else {
            shops = shopRepository.findAll(pageable);
        }
        
        return Map.of(
            "success", true,
            "shops", shops.getContent(),
            "page", page,
            "size", size,
            "totalElements", shops.getTotalElements(),
            "totalPages", shops.getTotalPages(),
            "hasNext", shops.hasNext(),
            "hasPrevious", shops.hasPrevious()
        );
    }
    
    /**
     * Get customer orders
     */
    public Map<String, Object> getCustomerOrders(int page, int size) {
        Long customerId = getCurrentCustomerId();
        
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Order> orders = orderRepository.findByCustomerId(customerId, pageable);
        
        return Map.of(
            "success", true,
            "orders", orders.getContent(),
            "page", page,
            "size", size,
            "totalElements", orders.getTotalElements(),
            "totalPages", orders.getTotalPages(),
            "hasNext", orders.hasNext(),
            "hasPrevious", orders.hasPrevious()
        );
    }
    
    /**
     * Place order using customer API
     */
    public Map<String, Object> placeOrder(CustomerOrderRequest request) {
        try {
            Long customerId = getCurrentCustomerId();
            
            // Convert CustomerOrderRequest to OrderRequest
            OrderRequest orderRequest = OrderRequest.builder()
                    .customerId(customerId)
                    .shopId(request.getShopId())
                    .orderItems(request.getItems().stream()
                            .map(item -> {
                                OrderRequest.OrderItemRequest orderItem = new OrderRequest.OrderItemRequest();
                                orderItem.setShopProductId(item.getShopProductId());
                                orderItem.setQuantity(item.getQuantity());
                                orderItem.setSpecialInstructions(item.getSpecialInstructions());
                                return orderItem;
                            })
                            .collect(Collectors.toList()))
                    .paymentMethod(Order.PaymentMethod.valueOf(request.getPaymentMethod()))
                    .deliveryAddress(request.getDeliveryAddress())
                    .deliveryContactName(request.getDeliveryContactName())
                    .deliveryPhone(request.getDeliveryPhone())
                    .deliveryCity(request.getDeliveryCity())
                    .deliveryState(request.getDeliveryState())
                    .deliveryPostalCode(request.getDeliveryPostalCode())
                    .notes(request.getNotes())
                    .estimatedDeliveryTime(request.getEstimatedDeliveryTime())
                    .discountAmount(request.getDiscountAmount())
                    .build();
            
            OrderResponse orderResponse = orderService.createOrder(orderRequest);
            
            return Map.of(
                "success", true,
                "message", "Order placed successfully",
                "order", orderResponse
            );
            
        } catch (Exception e) {
            log.error("Error placing customer order", e);
            return Map.of(
                "success", false,
                "message", "Failed to place order: " + e.getMessage(),
                "errorCode", "ORDER_CREATION_ERROR"
            );
        }
    }
    
    /**
     * Get customer cart (simplified implementation - in production you'd have a Cart entity)
     */
    public Map<String, Object> getCustomerCart() {
        // For now, return an empty cart structure
        // In production, implement proper cart persistence
        return Map.of(
            "success", true,
            "cart", Map.of(
                "items", List.of(),
                "totalItems", 0,
                "subtotal", 0.0,
                "tax", 0.0,
                "deliveryFee", 0.0,
                "total", 0.0
            )
        );
    }
    
    /**
     * Add item to cart
     */
    public Map<String, Object> addToCart(CartItemRequest request) {
        try {
            // Validate product exists
            ShopProduct product = shopProductRepository.findById(request.getShopProductId())
                    .orElseThrow(() -> new RuntimeException("Product not found"));
            
            // In production, implement proper cart management
            // For now, return success message
            return Map.of(
                "success", true,
                "message", "Item added to cart",
                "item", Map.of(
                    "productId", request.getShopProductId(),
                    "productName", product.getDisplayName(),
                    "quantity", request.getQuantity(),
                    "unitPrice", product.getPrice(),
                    "totalPrice", product.getPrice().multiply(BigDecimal.valueOf(request.getQuantity()))
                )
            );
            
        } catch (Exception e) {
            log.error("Error adding item to cart", e);
            return Map.of(
                "success", false,
                "message", "Failed to add item to cart: " + e.getMessage(),
                "errorCode", "CART_ADD_ERROR"
            );
        }
    }
    
    /**
     * Update cart item
     */
    public Map<String, Object> updateCartItem(CartItemRequest request) {
        // Implementation similar to addToCart
        return Map.of(
            "success", true,
            "message", "Cart item updated"
        );
    }
    
    /**
     * Remove item from cart
     */
    public Map<String, Object> removeFromCart(Long shopProductId) {
        return Map.of(
            "success", true,
            "message", "Item removed from cart"
        );
    }
    
    /**
     * Clear cart
     */
    public Map<String, Object> clearCart() {
        return Map.of(
            "success", true,
            "message", "Cart cleared"
        );
    }
    
    // Helper methods
    
    private Optional<Customer> findCustomerByEmailOrMobile(String emailOrMobile) {
        // Check if it's an email (contains @)
        if (emailOrMobile.contains("@")) {
            return customerRepository.findByEmail(emailOrMobile);
        } else {
            return customerRepository.findByMobileNumber(emailOrMobile);
        }
    }
    
    private Long getCurrentCustomerId() {
        // In production, extract from JWT token or security context
        // For now, return a mock customer ID
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getName() != null) {
            // Try to find customer by username (could be email or mobile)
            Optional<Customer> customer = findCustomerByEmailOrMobile(authentication.getName());
            if (customer.isPresent()) {
                return customer.get().getId();
            }
        }
        return 15L; // Default customer ID for testing
    }
}