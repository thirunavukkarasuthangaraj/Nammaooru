package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.dto.order.CustomerOrderRequest;
import com.shopmanagement.dto.order.OrderResponse;
import com.shopmanagement.dto.order.OrderTrackingResponse;
import com.shopmanagement.service.OrderService;
import com.shopmanagement.service.FirebaseNotificationService;
import com.shopmanagement.service.CustomerService;
import com.shopmanagement.entity.Customer;
import com.shopmanagement.repository.CustomerRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.security.core.Authentication;
import com.shopmanagement.service.UserService;
import com.shopmanagement.entity.User;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.springframework.data.domain.Page;

@RestController
@RequestMapping("/api/customer")
@RequiredArgsConstructor
@Slf4j
public class CustomerOrderController {

    private final OrderService orderService;
    private final FirebaseNotificationService firebaseNotificationService;
    private final UserService userService;
    private final CustomerService customerService;
    private final CustomerRepository customerRepository;
    private final UserRepository userRepository;

    @PostMapping("/orders")
    public ResponseEntity<ApiResponse<OrderResponse>> createOrder(
            @RequestBody CustomerOrderRequest orderRequest, 
            Authentication authentication) {
        try {
            // Get authenticated user from JWT token
            if (authentication == null || !authentication.isAuthenticated()) {
                log.error("User not authenticated for order creation");
                return ResponseUtil.error("User must be authenticated to place an order");
            }
            
            String username = authentication.getName();
            User authenticatedUser = userRepository.findByUsername(username).orElse(null);
            if (authenticatedUser == null) {
                log.error("Authenticated user not found: {}", username);
                return ResponseUtil.error("User not found");
            }
            
            log.info("Creating order for authenticated user: {} (ID: {}) with shop ID: {}", 
                     username, authenticatedUser.getId(), orderRequest.getShopId());
            log.debug("User details - firstName: '{}', lastName: '{}', email: '{}', mobile: '{}'", 
                     authenticatedUser.getFirstName(), authenticatedUser.getLastName(), 
                     authenticatedUser.getEmail(), authenticatedUser.getMobileNumber());
            
            // Validate request
            if (orderRequest.getShopId() == null) {
                log.error("Shop ID is required");
                return ResponseUtil.error("Shop ID is required");
            }
            
            if (orderRequest.getItems() == null || orderRequest.getItems().isEmpty()) {
                log.error("Order items are required");
                return ResponseUtil.error("Order items are required");
            }
            
            if (orderRequest.getDeliveryAddress() == null) {
                log.error("Delivery address is required");
                return ResponseUtil.error("Delivery address is required");
            }
            
            if (orderRequest.getCustomerInfo() == null) {
                log.error("Customer information is required");
                return ResponseUtil.error("Customer information is required");
            }
            
            // Validate customer info
            if (orderRequest.getCustomerInfo().getFirstName() == null || 
                orderRequest.getCustomerInfo().getFirstName().trim().isEmpty()) {
                log.error("Customer first name is required");
                return ResponseUtil.error("Customer first name is required");
            }
            
            if (orderRequest.getCustomerInfo().getPhone() == null || 
                orderRequest.getCustomerInfo().getPhone().trim().isEmpty()) {
                log.error("Customer phone is required");
                return ResponseUtil.error("Customer phone is required");
            }
            
            // Find or create customer for this user
            // First try to find by mobile number (since that's unique), then by email
            Optional<Customer> customerOpt = customerService.findCustomerByEmailOrMobile(authenticatedUser.getMobileNumber());
            if (!customerOpt.isPresent()) {
                customerOpt = customerService.findCustomerByEmailOrMobile(authenticatedUser.getEmail());
            }
            
            Customer customer;
            if (customerOpt.isPresent()) {
                customer = customerOpt.get();
                log.debug("Found existing customer ID: {} with mobile: {} and email: {}", 
                         customer.getId(), customer.getMobileNumber(), customer.getEmail());
            } else {
                // Create a customer record for this user
                String lastName = (authenticatedUser.getLastName() != null && authenticatedUser.getLastName().trim().length() >= 2) 
                    ? authenticatedUser.getLastName() 
                    : "User"; // Default lastName if null or too short
                
                log.debug("Creating customer with - firstName: '{}', lastName: '{}', email: '{}', mobile: '{}'", 
                         authenticatedUser.getFirstName(), lastName, authenticatedUser.getEmail(), 
                         authenticatedUser.getMobileNumber());
                
                customer = Customer.builder()
                    .email(authenticatedUser.getEmail())
                    .firstName(authenticatedUser.getFirstName())
                    .lastName(lastName)
                    .mobileNumber(authenticatedUser.getMobileNumber())
                    .isActive(true)
                    .build();
                customer = customerRepository.save(customer);
            }
            
            // Set the customer ID in the order request
            orderRequest.setCustomerId(customer.getId());
            
            // Ensure customer info is populated with customer data
            if (orderRequest.getCustomerInfo() == null) {
                orderRequest.setCustomerInfo(new CustomerOrderRequest.CustomerInfoRequest());
            }
            
            // Always set customer info from the found/created customer record
            orderRequest.getCustomerInfo().setCustomerId(customer.getId());
            orderRequest.getCustomerInfo().setEmail(customer.getEmail());
            
            // Use customer data first, then fallback to authenticated user's info if needed
            if (orderRequest.getCustomerInfo().getFirstName() == null || orderRequest.getCustomerInfo().getFirstName().trim().isEmpty()) {
                orderRequest.getCustomerInfo().setFirstName(customer.getFirstName() != null ? customer.getFirstName() : authenticatedUser.getFirstName());
            }
            if (orderRequest.getCustomerInfo().getLastName() == null || orderRequest.getCustomerInfo().getLastName().trim().isEmpty()) {
                orderRequest.getCustomerInfo().setLastName(customer.getLastName() != null ? customer.getLastName() : authenticatedUser.getLastName());
            }
            if (orderRequest.getCustomerInfo().getPhone() == null || orderRequest.getCustomerInfo().getPhone().trim().isEmpty()) {
                orderRequest.getCustomerInfo().setPhone(customer.getMobileNumber() != null ? customer.getMobileNumber() : authenticatedUser.getMobileNumber());
            }
            
            OrderResponse order = orderService.createCustomerOrder(orderRequest);
            
            // Send Firebase notification if customer token is available
            try {
                if (orderRequest.getCustomerToken() != null && !orderRequest.getCustomerToken().isEmpty()) {
                    firebaseNotificationService.sendOrderNotification(
                        order.getOrderNumber(), 
                        "PLACED", 
                        orderRequest.getCustomerToken()
                    );
                }
            } catch (Exception notificationError) {
                log.warn("Failed to send Firebase notification: {}", notificationError.getMessage());
                // Don't fail the order creation if notification fails
            }
            
            return ResponseUtil.success(order, "Order created successfully");
            
        } catch (IllegalArgumentException e) {
            log.error("Invalid order request: {}", e.getMessage());
            return ResponseUtil.error("Invalid order data: " + e.getMessage());
        } catch (jakarta.validation.ConstraintViolationException e) {
            log.error("Customer validation failed: {}", e.getMessage());
            StringBuilder errorMsg = new StringBuilder("Validation errors: ");
            e.getConstraintViolations().forEach(violation -> {
                log.error("Validation error - Field: {}, Value: {}, Message: {}", 
                    violation.getPropertyPath(), violation.getInvalidValue(), violation.getMessage());
                errorMsg.append(violation.getPropertyPath()).append(": ").append(violation.getMessage()).append("; ");
            });
            return ResponseUtil.error(errorMsg.toString());
        } catch (RuntimeException e) {
            log.error("Error creating customer order: {}", e.getMessage(), e);
            return ResponseUtil.error("Failed to create order: " + e.getMessage());
        } catch (Exception e) {
            log.error("Unexpected error creating customer order", e);
            return ResponseUtil.error("Failed to create order. Please try again later.");
        }
    }

    @GetMapping("/orders/{orderId}")
    public ResponseEntity<ApiResponse<OrderResponse>> getOrderById(@PathVariable Long orderId) {
        try {
            log.info("Getting order details for order ID: {}", orderId);
            
            OrderResponse order = orderService.getOrderById(orderId);
            
            return ResponseUtil.success(order, "Order details retrieved successfully");
            
        } catch (Exception e) {
            log.error("Error retrieving order details for ID: {}", orderId, e);
            return ResponseUtil.error("Order not found");
        }
    }

    @GetMapping("/orders/{orderNumber}/tracking")
    public ResponseEntity<ApiResponse<OrderTrackingResponse>> getOrderTracking(@PathVariable String orderNumber) {
        try {
            log.info("Getting tracking info for order: {}", orderNumber);
            
            OrderTrackingResponse tracking = orderService.getOrderTracking(orderNumber);
            
            return ResponseUtil.success(tracking, "Order tracking retrieved successfully");
            
        } catch (Exception e) {
            log.error("Error retrieving order tracking for: {}", orderNumber, e);
            return ResponseUtil.error("Order tracking not found");
        }
    }

    @GetMapping("/orders")
    public ResponseEntity<ApiResponse<Page<OrderResponse>>> getMyOrders(
            @RequestParam(required = false) Long customerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String status,
            Authentication authentication) {
        
        try {
            Long finalCustomerId = customerId;
            
            // If no customerId provided, get from authenticated user
            if (finalCustomerId == null && authentication != null && authentication.isAuthenticated()) {
                String username = authentication.getName();
                User authenticatedUser = userRepository.findByUsername(username).orElse(null);
                if (authenticatedUser != null) {
                    // Find customer by email or mobile number
                    Optional<Customer> customerOpt = customerService.findCustomerByEmailOrMobile(authenticatedUser.getEmail());
                    if (!customerOpt.isPresent()) {
                        customerOpt = customerService.findCustomerByEmailOrMobile(authenticatedUser.getMobileNumber());
                    }
                    if (customerOpt.isPresent()) {
                        finalCustomerId = customerOpt.get().getId();
                        log.info("Found customer ID {} for authenticated user {}", finalCustomerId, username);
                    } else {
                        log.warn("No customer record found for authenticated user: {}", username);
                        return ResponseUtil.success(Page.empty(), "No orders found");
                    }
                } else {
                    log.error("Authenticated user not found: {}", username);
                    return ResponseUtil.error("User not found");
                }
            }
            
            log.info("Getting orders for customer ID: {} with status filter: {}", finalCustomerId, status);

            Page<OrderResponse> orders = orderService.getOrdersByCustomer(finalCustomerId, page, size, status);
            
            return ResponseUtil.success(orders, "Orders retrieved successfully");
            
        } catch (Exception e) {
            log.error("Error retrieving customer orders", e);
            return ResponseUtil.error("Failed to retrieve orders");
        }
    }

    @PostMapping("/orders/{orderId}/cancel")
    public ResponseEntity<ApiResponse<OrderResponse>> cancelOrder(
            @PathVariable Long orderId,
            @RequestBody Map<String, String> requestBody,
            @RequestParam(required = false) String customerToken) {
        
        try {
            String reason = requestBody.get("reason");
            log.info("Cancelling order ID: {} with reason: {}", orderId, reason);

            OrderResponse order = orderService.cancelOrder(orderId, reason);
            
            // Send cancellation notification
            if (customerToken != null && !customerToken.isEmpty()) {
                firebaseNotificationService.sendOrderNotification(
                    order.getOrderNumber(), 
                    "CANCELLED", 
                    customerToken
                );
            }
            
            return ResponseUtil.success(order, "Order cancelled successfully");
            
        } catch (Exception e) {
            log.error("Error cancelling order ID: {}", orderId, e);
            return ResponseUtil.error("Failed to cancel order");
        }
    }

    @PostMapping("/orders/{orderId}/rate")
    public ResponseEntity<ApiResponse<String>> rateOrder(
            @PathVariable Long orderId,
            @RequestParam int rating,
            @RequestParam(required = false) String review) {

        try {
            log.info("Rating order ID: {} with rating: {}", orderId, rating);

            orderService.rateOrder(orderId, rating, review);

            return ResponseUtil.success("Rating submitted successfully", "Order rated successfully");

        } catch (Exception e) {
            log.error("Error rating order ID: {}", orderId, e);
            return ResponseUtil.error("Failed to submit rating");
        }
    }

    @PostMapping("/orders/{orderId}/reorder")
    public ResponseEntity<ApiResponse<String>> reorderItems(
            @PathVariable Long orderId,
            Authentication authentication) {

        try {
            log.info("Reordering items from order ID: {}", orderId);

            // Get authenticated user
            if (authentication == null || !authentication.isAuthenticated()) {
                return ResponseUtil.error("User must be authenticated to reorder");
            }

            String username = authentication.getName();
            User authenticatedUser = userRepository.findByUsername(username).orElse(null);
            if (authenticatedUser == null) {
                return ResponseUtil.error("User not found");
            }

            // Call the service to add items from the order to the cart
            String result = orderService.reorderItems(orderId, authenticatedUser.getId());

            return ResponseUtil.success(result, "Items added to cart successfully");

        } catch (Exception e) {
            log.error("Error reordering from order ID: {}", orderId, e);
            return ResponseUtil.error("Failed to add items to cart");
        }
    }
}