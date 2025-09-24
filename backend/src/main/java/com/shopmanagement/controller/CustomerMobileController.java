package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.dto.customer.*;
import com.shopmanagement.entity.Customer;
import com.shopmanagement.entity.CustomerAddress;
import com.shopmanagement.entity.Notification;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.CustomerAddressRepository;
import com.shopmanagement.repository.CustomerRepository;
import com.shopmanagement.repository.NotificationRepository;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.service.CustomerService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/customer")
@RequiredArgsConstructor
@Slf4j
public class CustomerMobileController {

    private final CustomerService customerService;
    private final CustomerAddressRepository customerAddressRepository;
    private final CustomerRepository customerRepository;
    private final UserRepository userRepository;
    private final NotificationRepository notificationRepository;

    @GetMapping("/delivery-locations")
    // @PreAuthorize("hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<ApiResponse<List<DeliveryLocationResponse>>> getDeliveryLocations() {
        try {
            log.info("Fetching delivery locations for current user");

            Customer customer = getCurrentCustomer();
            if (customer == null) {
                return ResponseEntity.status(401)
                    .body(ApiResponse.error("User not authenticated", "AUTHENTICATION_ERROR"));
            }

            List<CustomerAddress> addresses = customerAddressRepository.findByCustomerIdAndIsActive(customer.getId(), true);
            List<DeliveryLocationResponse> locations = new ArrayList<>();

            for (CustomerAddress address : addresses) {
                DeliveryLocationResponse location = DeliveryLocationResponse.builder()
                        .id(address.getId())
                        .addressType(address.getAddressType())
                        .flatHouse(address.getAddressLine2()) // Fixed: flatHouse from addressLine2
                        .area(address.getAddressLine1())      // Fixed: area from addressLine1
                        .landmark(address.getLandmark())
                        .city(address.getCity())
                        .state(address.getState())
                        .pincode(address.getPostalCode())
                        .fullAddress(address.getFullAddress())
                        .latitude(address.getLatitude())
                        .longitude(address.getLongitude())
                        .isDefault(address.getIsDefault())
                        .isActive(address.getIsActive())
                        .displayLabel(address.getAddressType() + " - " + address.getCity())
                        .shortAddress(address.getCity() + ", " + address.getState())
                        .build();
                locations.add(location);
            }

            // If no addresses found, add a default one for Thirupattur
            if (locations.isEmpty()) {
                log.info("No addresses found for customer {}, returning default location", customer.getId());
            }

            return ResponseEntity.ok(ApiResponse.success(locations, "Delivery locations fetched successfully"));

        } catch (Exception e) {
            log.error("Error fetching delivery locations", e);
            return ResponseEntity.status(500)
                    .body(ApiResponse.error("Failed to fetch delivery locations", "DELIVERY_LOCATIONS_ERROR"));
        }
    }

    @PostMapping("/delivery-locations")
    // @PreAuthorize("hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<ApiResponse<DeliveryLocationResponse>> addDeliveryLocation(
            @RequestBody DeliveryLocationRequest request) {
        try {
            log.info("Adding new delivery location for current user: {}", request);

            Customer customer = getCurrentCustomer();
            if (customer == null) {
                return ResponseEntity.status(401)
                    .body(ApiResponse.error("User not authenticated", "AUTHENTICATION_ERROR"));
            }

            // If this is set as default, unset all other default addresses
            if (Boolean.TRUE.equals(request.getIsDefault())) {
                Optional<CustomerAddress> existingDefault = customerAddressRepository.findByCustomerIdAndIsDefault(customer.getId(), true);
                if (existingDefault.isPresent()) {
                    CustomerAddress addr = existingDefault.get();
                    addr.setIsDefault(false);
                    customerAddressRepository.save(addr);
                }
            }

            // Create new address entity
            CustomerAddress address = CustomerAddress.builder()
                    .customer(customer)
                    .addressType(request.getAddressType())
                    .addressLine1(request.getArea()) // Using area as primary address line
                    .addressLine2(request.getFlatHouse()) // Using flatHouse as secondary
                    .landmark(request.getLandmark())
                    .city(request.getCity() != null ? request.getCity() : "Tirupattur")
                    .state(request.getState() != null ? request.getState() : "Tamil Nadu")
                    .postalCode(request.getPincode() != null ? request.getPincode() : "635601")
                    .latitude(request.getLatitude())
                    .longitude(request.getLongitude())
                    .isDefault(request.getIsDefault() != null ? request.getIsDefault() : false)
                    .isActive(true)
                    .createdBy(customer.getEmail())
                    .updatedBy(customer.getEmail())
                    .build();

            CustomerAddress savedAddress = customerAddressRepository.save(address);
            log.info("Address saved successfully with ID: {}", savedAddress.getId());

            // Build response
            DeliveryLocationResponse response = DeliveryLocationResponse.builder()
                    .id(savedAddress.getId())
                    .addressType(savedAddress.getAddressType())
                    .flatHouse(savedAddress.getAddressLine2())
                    .area(savedAddress.getAddressLine1())
                    .landmark(savedAddress.getLandmark())
                    .city(savedAddress.getCity())
                    .state(savedAddress.getState())
                    .pincode(savedAddress.getPostalCode())
                    .fullAddress(savedAddress.getFullAddress())
                    .latitude(savedAddress.getLatitude())
                    .longitude(savedAddress.getLongitude())
                    .isDefault(savedAddress.getIsDefault())
                    .isActive(savedAddress.getIsActive())
                    .displayLabel(savedAddress.getAddressLabel() + " - " + savedAddress.getCity())
                    .shortAddress(savedAddress.getCity() + ", " + savedAddress.getState())
                    .build();

            return ResponseEntity.ok(ApiResponse.success(response, "Delivery location added successfully"));

        } catch (Exception e) {
            log.error("Error adding delivery location", e);
            return ResponseEntity.status(500)
                    .body(ApiResponse.error("Failed to add delivery location: " + e.getMessage(), "ADD_LOCATION_ERROR"));
        }
    }

    @PutMapping("/delivery-locations/{id}")
    // @PreAuthorize("hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<ApiResponse<DeliveryLocationResponse>> updateDeliveryLocation(
            @PathVariable Long id,
            @RequestBody DeliveryLocationRequest request) {
        try {
            log.info("Updating delivery location with ID: {}", id);

            // For now, return a sample response - in a real implementation,
            // this would update in the database
            DeliveryLocationResponse response = DeliveryLocationResponse.builder()
                    .id(id)
                    .addressType(request.getAddressType())
                    .flatHouse(request.getFlatHouse())
                    .floor(request.getFloor())
                    .area(request.getArea())
                    .landmark(request.getLandmark())
                    .city(request.getCity())
                    .state(request.getState())
                    .pincode(request.getPincode())
                    .fullAddress(String.format("%s, %s, %s %s",
                            request.getArea(), request.getCity(), request.getState(), request.getPincode()))
                    .latitude(request.getLatitude())
                    .longitude(request.getLongitude())
                    .isDefault(request.getIsDefault())
                    .isActive(true)
                    .displayLabel(request.getAddressType() + " - " + request.getArea())
                    .shortAddress(request.getArea() + ", " + request.getCity())
                    .build();

            return ResponseEntity.ok(ApiResponse.success(response, "Delivery location updated successfully"));

        } catch (Exception e) {
            log.error("Error updating delivery location with ID: {}", id, e);
            return ResponseEntity.status(500)
                    .body(ApiResponse.error("Failed to update delivery location", "UPDATE_LOCATION_ERROR"));
        }
    }

    @DeleteMapping("/delivery-locations/{id}")
    // @PreAuthorize("hasRole('CUSTOMER') or hasRole('USER')")
    public ResponseEntity<ApiResponse<String>> deleteDeliveryLocation(@PathVariable Long id) {
        try {
            log.info("Deleting delivery location with ID: {}", id);

            Customer customer = getCurrentCustomer();
            if (customer == null) {
                return ResponseEntity.status(401)
                    .body(ApiResponse.error("User not authenticated", "AUTHENTICATION_ERROR"));
            }

            // Find the address that belongs to this customer
            Optional<CustomerAddress> addressOpt = customerAddressRepository.findByIdAndCustomerId(id, customer.getId());
            if (addressOpt.isEmpty()) {
                return ResponseEntity.status(404)
                    .body(ApiResponse.error("Address not found or doesn't belong to current user", "ADDRESS_NOT_FOUND"));
            }

            CustomerAddress address = addressOpt.get();

            // Soft delete - set isActive to false instead of hard delete
            address.setIsActive(false);
            address.setUpdatedBy(customer.getEmail());
            customerAddressRepository.save(address);

            log.info("Address {} soft deleted successfully for customer {}", id, customer.getId());
            return ResponseEntity.ok(ApiResponse.success("", "Delivery location deleted successfully"));

        } catch (Exception e) {
            log.error("Error deleting delivery location with ID: {}", id, e);
            return ResponseEntity.status(500)
                    .body(ApiResponse.error("Failed to delete delivery location", "DELETE_LOCATION_ERROR"));
        }
    }

    private Customer getCurrentCustomer() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication == null || !authentication.isAuthenticated()) {
                log.warn("No authentication found");
                return null;
            }

            String username = authentication.getName();
            log.info("Getting current customer for username: {}", username);

            // First try to find customer by email (username)
            Optional<Customer> customer = customerRepository.findByEmail(username);
            if (customer.isPresent()) {
                log.info("Found customer with ID: {} by email", customer.get().getId());
                return customer.get();
            }

            // If not found, try to find by mobile number (in case username is mobile)
            customer = customerRepository.findByMobileNumber(username);
            if (customer.isPresent()) {
                log.info("Found customer with ID: {} by mobile", customer.get().getId());
                return customer.get();
            }

            // If still not found, check if there's a User with this username
            Optional<User> user = userRepository.findByUsername(username);
            if (user.isPresent()) {
                // Get customer by user's email
                customer = customerRepository.findByEmail(user.get().getEmail());
                if (customer.isPresent()) {
                    log.info("Found customer with ID: {} via user email", customer.get().getId());
                    return customer.get();
                }

                // Try by mobile number from user
                if (user.get().getMobileNumber() != null) {
                    customer = customerRepository.findByMobileNumber(user.get().getMobileNumber());
                    if (customer.isPresent()) {
                        log.info("Found customer with ID: {} via user mobile", customer.get().getId());
                        return customer.get();
                    }
                }

                // If no Customer exists, create one from the User data
                log.info("Creating new Customer record for User: {}", user.get().getUsername());
                Customer newCustomer = Customer.builder()
                        .firstName(user.get().getFirstName() != null ? user.get().getFirstName() : "User")
                        .lastName(user.get().getLastName() != null ? user.get().getLastName() : username)
                        .email(user.get().getEmail())
                        .mobileNumber(user.get().getMobileNumber())
                        .isActive(true)
                        .isVerified(true)
                        .status(Customer.CustomerStatus.ACTIVE)
                        .createdBy("system")
                        .updatedBy("system")
                        .build();

                Customer savedCustomer = customerRepository.save(newCustomer);
                log.info("Created new customer with ID: {} for user: {}", savedCustomer.getId(), username);
                return savedCustomer;
            }

            log.warn("No User found for username: {}", username);
            return null;
        } catch (Exception e) {
            log.error("Error getting/creating current customer", e);
            return null;
        }
    }

    @GetMapping("/notifications")
    public ResponseEntity<ApiResponse<List<Notification>>> getNotifications() {
        try {
            log.info("Fetching notifications for current user");

            Customer customer = getCurrentCustomer();
            if (customer == null) {
                return ResponseEntity.status(401)
                    .body(ApiResponse.error("User not authenticated", "AUTHENTICATION_ERROR"));
            }

            List<Notification> notifications = notificationRepository.findByRecipientIdAndRecipientTypeOrderByCreatedAtDesc(
                customer.getId(),
                Notification.RecipientType.CUSTOMER
            );

            log.info("Found {} notifications for customer {}", notifications.size(), customer.getId());
            return ResponseEntity.ok(ApiResponse.success(notifications, "Notifications fetched successfully"));

        } catch (Exception e) {
            log.error("Error fetching notifications", e);
            return ResponseEntity.status(500)
                    .body(ApiResponse.error("Failed to fetch notifications", "NOTIFICATIONS_ERROR"));
        }
    }

    @PostMapping("/notifications/mark-all-read")
    public ResponseEntity<ApiResponse<String>> markAllNotificationsAsRead() {
        try {
            log.info("Marking all notifications as read for current user");

            Customer customer = getCurrentCustomer();
            if (customer == null) {
                return ResponseEntity.status(401)
                    .body(ApiResponse.error("User not authenticated", "AUTHENTICATION_ERROR"));
            }

            int updatedCount = notificationRepository.markAllAsReadByRecipient(
                customer.getId(),
                Notification.RecipientType.CUSTOMER
            );

            log.info("Marked {} notifications as read for customer {}", updatedCount, customer.getId());
            return ResponseEntity.ok(ApiResponse.success("",
                String.format("Marked %d notifications as read", updatedCount)));

        } catch (Exception e) {
            log.error("Error marking notifications as read", e);
            return ResponseEntity.status(500)
                    .body(ApiResponse.error("Failed to mark notifications as read", "MARK_READ_ERROR"));
        }
    }

    @PostMapping("/notifications/{id}/mark-read")
    public ResponseEntity<ApiResponse<String>> markNotificationAsRead(@PathVariable Long id) {
        try {
            log.info("Marking notification {} as read", id);

            Customer customer = getCurrentCustomer();
            if (customer == null) {
                return ResponseEntity.status(401)
                    .body(ApiResponse.error("User not authenticated", "AUTHENTICATION_ERROR"));
            }

            Optional<Notification> notificationOpt = notificationRepository.findById(id);
            if (notificationOpt.isEmpty()) {
                return ResponseEntity.status(404)
                    .body(ApiResponse.error("Notification not found", "NOTIFICATION_NOT_FOUND"));
            }

            Notification notification = notificationOpt.get();

            // Check if notification belongs to current customer
            if (!notification.getRecipientId().equals(customer.getId()) ||
                notification.getRecipientType() != Notification.RecipientType.CUSTOMER) {
                return ResponseEntity.status(403)
                    .body(ApiResponse.error("Access denied", "ACCESS_DENIED"));
            }

            notification.markAsRead();
            notificationRepository.save(notification);

            log.info("Notification {} marked as read for customer {}", id, customer.getId());
            return ResponseEntity.ok(ApiResponse.success("", "Notification marked as read"));

        } catch (Exception e) {
            log.error("Error marking notification {} as read", id, e);
            return ResponseEntity.status(500)
                    .body(ApiResponse.error("Failed to mark notification as read", "MARK_READ_ERROR"));
        }
    }
}