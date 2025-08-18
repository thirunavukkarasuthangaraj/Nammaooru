package com.shopmanagement.controller;

import com.shopmanagement.dto.customer.*;
import com.shopmanagement.service.CustomerService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/customers")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class CustomerController {

    private final CustomerService customerService;

    @GetMapping
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<Page<CustomerResponse>> getAllCustomers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDirection) {
        
        log.info("Fetching all customers - page: {}, size: {}", page, size);
        Page<CustomerResponse> customers = customerService.getAllCustomers(page, size, sortBy, sortDirection);
        return ResponseEntity.ok(customers);
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
    public ResponseEntity<CustomerResponse> getCustomerById(@PathVariable Long id) {
        log.info("Fetching customer with ID: {}", id);
        CustomerResponse customer = customerService.getCustomerById(id);
        return ResponseEntity.ok(customer);
    }

    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> registerCustomer(
            @Valid @RequestBody CustomerRegistrationRequest request,
            HttpServletRequest httpRequest) {
        
        try {
            log.info("Customer registration request received for email: {}", request.getEmail());
            
            // Add IP address from request
            String ipAddress = getClientIpAddress(httpRequest);
            
            Map<String, Object> response = customerService.registerCustomer(request, ipAddress);
            
            if ((Boolean) response.get("success")) {
                return ResponseEntity.status(HttpStatus.CREATED).body(response);
            } else {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
            }
            
        } catch (Exception e) {
            log.error("Error registering customer for email: {}", request.getEmail(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                        "success", false,
                        "message", "Registration failed. Please try again.",
                        "errorCode", "REGISTRATION_ERROR"
                    ));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> loginCustomer(
            @Valid @RequestBody CustomerLoginRequest request,
            HttpServletRequest httpRequest) {
        
        try {
            log.info("Customer login request received for: {}", request.getEmailOrMobile());
            
            // Add IP address from request
            request.setIpAddress(getClientIpAddress(httpRequest));
            
            Map<String, Object> response = customerService.loginCustomer(request);
            
            if ((Boolean) response.get("success")) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
            }
            
        } catch (Exception e) {
            log.error("Error during customer login for: {}", request.getEmailOrMobile(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                        "success", false,
                        "message", "Login failed. Please try again.",
                        "errorCode", "LOGIN_ERROR"
                    ));
        }
    }

    @GetMapping("/profile")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<CustomerResponse> getCustomerProfile() {
        log.info("Fetching customer profile");
        CustomerResponse response = customerService.getCurrentCustomerProfile();
        return ResponseEntity.ok(response);
    }

    @GetMapping("/shops")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<Map<String, Object>> getAvailableShops(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String city,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) Double latitude,
            @RequestParam(required = false) Double longitude,
            @RequestParam(defaultValue = "10") Double radiusKm) {
        
        log.info("Fetching available shops - page: {}, size: {}, city: {}", page, size, city);
        
        Map<String, Object> response = customerService.getAvailableShops(
            page, size, city, category, latitude, longitude, radiusKm);
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/orders")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<Map<String, Object>> placeOrder(
            @Valid @RequestBody CustomerOrderRequest request) {
        
        try {
            log.info("Customer placing order for shop: {}", request.getShopId());
            
            Map<String, Object> response = customerService.placeOrder(request);
            
            if ((Boolean) response.get("success")) {
                return ResponseEntity.status(HttpStatus.CREATED).body(response);
            } else {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
            }
            
        } catch (Exception e) {
            log.error("Error placing customer order", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                        "success", false,
                        "message", "Failed to place order. Please try again.",
                        "errorCode", "ORDER_CREATION_ERROR"
                    ));
        }
    }

    @GetMapping("/cart")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<Map<String, Object>> getCart() {
        log.info("Fetching customer cart");
        Map<String, Object> response = customerService.getCustomerCart();
        return ResponseEntity.ok(response);
    }

    @PostMapping("/cart/add")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<Map<String, Object>> addToCart(
            @Valid @RequestBody CartItemRequest request) {
        
        try {
            log.info("Adding item to cart - product: {}, quantity: {}", 
                request.getShopProductId(), request.getQuantity());
            
            Map<String, Object> response = customerService.addToCart(request);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error adding item to cart", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                        "success", false,
                        "message", "Failed to add item to cart",
                        "errorCode", "CART_ERROR"
                    ));
        }
    }

    // Helper method
    private String getClientIpAddress(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        
        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isEmpty()) {
            return xRealIp;
        }
        
        return request.getRemoteAddr();
    }
}