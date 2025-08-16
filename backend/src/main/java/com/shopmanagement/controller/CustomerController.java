package com.shopmanagement.controller;

import com.shopmanagement.dto.customer.*;
import com.shopmanagement.entity.Customer;
import com.shopmanagement.service.CustomerService;
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
@CrossOrigin(origins = "*", maxAge = 3600)
public class CustomerController {
    
    private final CustomerService customerService;
    
    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<CustomerResponse> createCustomer(@Valid @RequestBody CustomerRequest request) {
        log.info("Creating new customer with email: {}", request.getEmail());
        CustomerResponse response = customerService.createCustomer(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<CustomerResponse> getCustomerById(@PathVariable Long id) {
        log.info("Fetching customer with ID: {}", id);
        CustomerResponse response = customerService.getCustomerById(id);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/email/{email}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<CustomerResponse> getCustomerByEmail(@PathVariable String email) {
        log.info("Fetching customer with email: {}", email);
        CustomerResponse response = customerService.getCustomerByEmail(email);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/mobile/{mobileNumber}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<CustomerResponse> getCustomerByMobileNumber(@PathVariable String mobileNumber) {
        log.info("Fetching customer with mobile: {}", mobileNumber);
        CustomerResponse response = customerService.getCustomerByMobileNumber(mobileNumber);
        return ResponseEntity.ok(response);
    }
    
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<CustomerResponse> updateCustomer(@PathVariable Long id, @Valid @RequestBody CustomerRequest request) {
        log.info("Updating customer with ID: {}", id);
        CustomerResponse response = customerService.updateCustomer(id, request);
        return ResponseEntity.ok(response);
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> deleteCustomer(@PathVariable Long id) {
        log.info("Deleting customer with ID: {}", id);
        customerService.deleteCustomer(id);
        return ResponseEntity.ok(Map.of("message", "Customer deleted successfully"));
    }
    
    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Page<CustomerResponse>> getAllCustomers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDirection) {
        log.info("Fetching customers - page: {}, size: {}, sortBy: {}, direction: {}", page, size, sortBy, sortDirection);
        Page<CustomerResponse> response = customerService.getAllCustomers(page, size, sortBy, sortDirection);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/search")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Page<CustomerResponse>> searchCustomers(
            @RequestParam String searchTerm,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Searching customers with term: {}", searchTerm);
        Page<CustomerResponse> response = customerService.searchCustomers(searchTerm, page, size);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/status/{status}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Page<CustomerResponse>> getCustomersByStatus(
            @PathVariable String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching customers with status: {}", status);
        Customer.CustomerStatus customerStatus = Customer.CustomerStatus.valueOf(status.toUpperCase());
        Page<CustomerResponse> response = customerService.getCustomersByStatus(customerStatus, page, size);
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/{id}/verify-email")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<CustomerResponse> verifyEmail(@PathVariable Long id) {
        log.info("Verifying email for customer ID: {}", id);
        CustomerResponse response = customerService.verifyEmail(id);
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/{id}/verify-mobile")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<CustomerResponse> verifyMobile(@PathVariable Long id) {
        log.info("Verifying mobile for customer ID: {}", id);
        CustomerResponse response = customerService.verifyMobile(id);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/stats")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<CustomerStatsResponse> getCustomerStats() {
        log.info("Fetching customer statistics");
        CustomerStatsResponse response = customerService.getCustomerStats();
        return ResponseEntity.ok(response);
    }
}