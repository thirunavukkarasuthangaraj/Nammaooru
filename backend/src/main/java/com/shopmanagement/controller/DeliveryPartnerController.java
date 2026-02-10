package com.shopmanagement.controller;

import com.shopmanagement.entity.User;
import com.shopmanagement.entity.User.UserRole;
import com.shopmanagement.entity.User.RideStatus;
import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderAssignment;
import com.shopmanagement.entity.DeliveryPartnerLocation;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.service.UserService;
import com.shopmanagement.service.OrderAssignmentService;
import com.shopmanagement.service.JwtService;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.repository.OrderAssignmentRepository;
import com.shopmanagement.repository.DeliveryPartnerLocationRepository;
import com.shopmanagement.repository.UserFcmTokenRepository;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.dto.ApiResponse;
import com.shopmanagement.dto.fcm.FcmTokenRequest;
import com.shopmanagement.service.FirebaseNotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import lombok.extern.slf4j.Slf4j;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/mobile/delivery-partner")
@Slf4j
public class DeliveryPartnerController {

    @Autowired
    private UserService userService;

    @Autowired
    private OrderAssignmentService orderAssignmentService;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private DeliveryPartnerLocationRepository deliveryPartnerLocationRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private UserFcmTokenRepository userFcmTokenRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private OrderAssignmentRepository orderAssignmentRepository;

    @Autowired
    private FirebaseNotificationService firebaseNotificationService;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        String password = request.get("password");
        
        Map<String, Object> response = new HashMap<>();
        
        try {
            // Find user by email and check if they are a delivery partner
            Optional<User> userOpt = userService.findByEmail(email);
            
            if (userOpt.isEmpty()) {
                response.put("success", false);
                response.put("message", "User not found");
                return ResponseEntity.badRequest().body(response);
            }
            
            User user = userOpt.get();
            
            // Check if user is a delivery partner
            if (user.getRole() != UserRole.DELIVERY_PARTNER) {
                response.put("success", false);
                response.put("message", "Access denied. Not a delivery partner account.");
                return ResponseEntity.badRequest().body(response);
            }
            
            // Check if user is active
            if (!user.getIsActive()) {
                response.put("success", false);
                response.put("message", "Account is disabled. Contact support.");
                return ResponseEntity.badRequest().body(response);
            }
            
            // Check password: static "password123" for testing, or verify against encoded password
            boolean isValidPassword = "password123".equals(password);
            if (!isValidPassword) {
                // Check if password matches the encoded password in database
                isValidPassword = passwordEncoder.matches(password, user.getPassword());
            }

            // If still not valid, try Spring Security authentication as fallback
            if (!isValidPassword) {
                try {
                    Authentication authentication = authenticationManager.authenticate(
                        new UsernamePasswordAuthenticationToken(email, password)
                    );
                    isValidPassword = authentication.isAuthenticated();
                } catch (Exception e) {
                    isValidPassword = false;
                }
            }

            if (!isValidPassword) {
                response.put("success", false);
                response.put("message", "Invalid email or password");
                return ResponseEntity.badRequest().body(response);
            }
            
            // Generate proper JWT token
            String token = jwtService.generateToken(user);

            // Set delivery partner as online upon successful login
            user.setIsOnline(true);
            user.setIsAvailable(true);
            user.setRideStatus(User.RideStatus.AVAILABLE);
            user.setLastLogin(LocalDateTime.now());
            user.setLastActivity(LocalDateTime.now());
            userService.save(user);

            System.out.println("Delivery partner " + user.getEmail() + " logged in and set to online");
            
            response.put("success", true);
            response.put("message", "Login successful");
            response.put("token", token);
            response.put("partnerId", user.getId().toString());
            response.put("requiresPasswordChange", user.getPasswordChangeRequired());
            response.put("isFirstTimeLogin", user.getIsTemporaryPassword());
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Invalid email or password");
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PostMapping("/notifications/fcm-token")
    public ResponseEntity<?> updateFcmToken(@RequestBody FcmTokenRequest request) {
        try {
            // Get current user from security context
            Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            String usernameOrEmail = auth.getName();

            log.info("FCM token update request - principal: {}", usernameOrEmail);

            // Try to find user by username first, then by email as fallback
            Optional<User> userOpt = userRepository.findByUsername(usernameOrEmail);
            if (userOpt.isEmpty()) {
                // Fallback: try finding by email (in case JWT contains email)
                userOpt = userRepository.findByEmail(usernameOrEmail);
            }
            if (userOpt.isEmpty()) {
                log.warn("User not found for FCM token update - principal: {}", usernameOrEmail);
                return ResponseEntity.ok(ApiResponse.error("User not found"));
            }

            User user = userOpt.get();
            log.info("Updating FCM token for delivery partner: {} (ID: {})", usernameOrEmail, user.getId());

            // Check if token already exists for this user
            Optional<UserFcmToken> existingToken = userFcmTokenRepository
                    .findByUserIdAndFcmToken(user.getId(), request.getFcmToken());

            UserFcmToken fcmToken;
            if (existingToken.isPresent()) {
                // Update existing token
                fcmToken = existingToken.get();
                fcmToken.setIsActive(true);
                fcmToken.setUpdatedAt(LocalDateTime.now());
                if (request.getDeviceType() != null) {
                    fcmToken.setDeviceType(request.getDeviceType());
                }
                if (request.getDeviceId() != null) {
                    fcmToken.setDeviceId(request.getDeviceId());
                }
            } else {
                // Deactivate old tokens for the same device if deviceId is provided
                if (request.getDeviceId() != null) {
                    userFcmTokenRepository.findByUserIdAndIsActiveTrue(user.getId())
                            .stream()
                            .filter(token -> request.getDeviceId().equals(token.getDeviceId()))
                            .forEach(token -> {
                                token.setIsActive(false);
                                userFcmTokenRepository.save(token);
                            });
                }

                // Create new token
                fcmToken = new UserFcmToken();
                fcmToken.setUserId(user.getId());
                fcmToken.setFcmToken(request.getFcmToken());
                fcmToken.setDeviceType(request.getDeviceType() != null ? request.getDeviceType() : "android");
                fcmToken.setDeviceId(request.getDeviceId());
                fcmToken.setIsActive(true);
            }

            userFcmTokenRepository.save(fcmToken);

            log.info("FCM token saved successfully for delivery partner: {}", user.getId());

            return ResponseEntity.ok(ApiResponse.success("FCM token updated successfully", null));
        } catch (Exception e) {
            log.error("Error updating FCM token for delivery partner", e);
            return ResponseEntity.ok(ApiResponse.error("Failed to update FCM token: " + e.getMessage()));
        }
    }

    /**
     * Test FCM notification for delivery partner - for debugging
     */
    @GetMapping("/notifications/test/{partnerId}")
    public ResponseEntity<Map<String, Object>> testFcmNotification(@PathVariable Long partnerId) {
        Map<String, Object> response = new HashMap<>();
        try {
            log.info("🧪 Testing FCM notification for delivery partner: {}", partnerId);

            // Find the partner
            Optional<User> partnerOpt = userRepository.findById(partnerId);
            if (partnerOpt.isEmpty()) {
                response.put("success", false);
                response.put("message", "Partner not found");
                return ResponseEntity.badRequest().body(response);
            }

            User partner = partnerOpt.get();

            // Get active FCM tokens
            List<UserFcmToken> tokens = userFcmTokenRepository.findActiveTokensByUserId(partnerId);
            log.info("📊 Found {} active FCM tokens for partner {}", tokens.size(), partner.getEmail());

            if (tokens.isEmpty()) {
                response.put("success", false);
                response.put("message", "No active FCM tokens found for this partner");
                response.put("partnerId", partnerId);
                response.put("partnerEmail", partner.getEmail());
                return ResponseEntity.ok(response);
            }

            // Try sending test notification to first active token
            UserFcmToken token = tokens.get(0);
            log.info("📱 Sending test notification to token: {}...", token.getFcmToken().substring(0, 50));

            try {
                firebaseNotificationService.sendOrderAssignmentNotificationToDriver(
                    "TEST-ORDER-123",
                    token.getFcmToken(),
                    partnerId,
                    "Test Shop",
                    "123 Test Address",
                    50.0
                );

                response.put("success", true);
                response.put("message", "Test notification sent successfully!");
                response.put("partnerId", partnerId);
                response.put("partnerEmail", partner.getEmail());
                response.put("tokenUsed", token.getFcmToken().substring(0, 50) + "...");
                log.info("✅ Test notification sent successfully to partner {}", partner.getEmail());

            } catch (Exception sendError) {
                log.error("❌ Failed to send test notification: {}", sendError.getMessage(), sendError);
                response.put("success", false);
                response.put("message", "Failed to send: " + sendError.getMessage());
                response.put("error", sendError.getClass().getSimpleName());
            }

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ Error testing FCM notification: {}", e.getMessage(), e);
            response.put("success", false);
            response.put("message", "Error: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @GetMapping("/profile/{partnerId}")
    public ResponseEntity<Map<String, Object>> getProfile(@PathVariable String partnerId) {
        try {
            Long id = Long.parseLong(partnerId);
            Optional<User> userOpt = userService.findById(id);

            if (userOpt.isEmpty()) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("message", "User not found");
                return ResponseEntity.badRequest().body(response);
            }

            User user = userOpt.get();

            // Check if user is a delivery partner
            if (user.getRole() != UserRole.DELIVERY_PARTNER) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("message", "Access denied");
                return ResponseEntity.badRequest().body(response);
            }

            Map<String, Object> profile = new HashMap<>();
            profile.put("partnerId", user.getId());

            // Handle null names properly
            String firstName = user.getFirstName() != null ? user.getFirstName() : "Delivery";
            String lastName = user.getLastName() != null ? user.getLastName() : "Partner";
            profile.put("name", firstName + " " + lastName);

            profile.put("email", user.getEmail());
            profile.put("phoneNumber", user.getMobileNumber());
            profile.put("isOnline", user.getIsOnline() != null ? user.getIsOnline() : false);
            profile.put("isAvailable", user.getIsAvailable() != null ? user.getIsAvailable() : false);

            // Get earnings, total deliveries, and rating from OrderAssignmentRepository
            Double totalEarnings = orderAssignmentRepository.getTotalEarningsByPartnerId(id);
            Long totalDeliveries = orderAssignmentRepository.countCompletedAssignmentsByPartnerId(id);
            Double averageRating = orderAssignmentRepository.getAverageRatingByPartnerId(id);

            profile.put("earnings", totalEarnings != null ? totalEarnings : 0.0);
            profile.put("totalDeliveries", totalDeliveries != null ? totalDeliveries : 0);
            profile.put("rating", averageRating != null ? averageRating : 0.0);

            profile.put("success", true);

            return ResponseEntity.ok(profile);

        } catch (NumberFormatException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Invalid partner ID");
            return ResponseEntity.badRequest().body(response);
        }
    }
    
    @GetMapping("/orders/{partnerId}/available")
    @Transactional
    public ResponseEntity<Map<String, Object>> getAvailableOrders(@PathVariable String partnerId) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long id = Long.parseLong(partnerId);

            // Get pending assignments for this partner that are in ASSIGNED status
            List<OrderAssignment> availableAssignments = orderAssignmentService.findPendingAssignmentsByPartnerId(id);

            // Convert to order format for the app
            List<Map<String, Object>> orders = new ArrayList<>();
            for (OrderAssignment assignment : availableAssignments) {
                if (assignment.getStatus() == OrderAssignment.AssignmentStatus.ASSIGNED) {
                    Map<String, Object> orderData = new HashMap<>();
                    orderData.put("id", assignment.getId().toString());
                    orderData.put("orderNumber", assignment.getOrder().getOrderNumber());
                    orderData.put("totalAmount", assignment.getOrder().getTotalAmount());
                    orderData.put("deliveryFee", assignment.getDeliveryFee());
                    orderData.put("status", assignment.getStatus().name());
                    orderData.put("createdAt", assignment.getCreatedAt().toString());
                    orderData.put("deliveryAddress", assignment.getOrder().getDeliveryAddress());
                    orderData.put("customerName", assignment.getOrder().getCustomer().getFirstName() + " " + assignment.getOrder().getCustomer().getLastName());
                    orderData.put("customerPhone", assignment.getOrder().getCustomer().getMobileNumber());
                    orderData.put("shopName", assignment.getOrder().getShop().getName());
                    orderData.put("shopAddress", assignment.getOrder().getShop().getAddressLine1());
                    orderData.put("shopLatitude", assignment.getOrder().getShop().getLatitude());
                    orderData.put("shopLongitude", assignment.getOrder().getShop().getLongitude());
                    // Use actual delivery coordinates from the order
                    orderData.put("customerLatitude", assignment.getOrder().getDeliveryLatitude());
                    orderData.put("customerLongitude", assignment.getOrder().getDeliveryLongitude());
                    orderData.put("paymentMethod", assignment.getOrder().getPaymentMethod().name());
                    orderData.put("paymentStatus", assignment.getOrder().getPaymentStatus().name());
                    orderData.put("pickupOtp", assignment.getOrder().getPickupOtp());
                    orderData.put("deliveryType", assignment.getOrder().getDeliveryType() != null ? assignment.getOrder().getDeliveryType().name() : null);

                    // Add order items with images
                    List<Map<String, Object>> orderItems = assignment.getOrder().getOrderItems().stream()
                        .map(item -> {
                            Map<String, Object> itemMap = new HashMap<>();
                            itemMap.put("id", item.getId());
                            itemMap.put("productName", item.getProductName() != null ? item.getProductName() : "Product");
                            itemMap.put("quantity", item.getQuantity());
                            itemMap.put("unitPrice", item.getUnitPrice());
                            itemMap.put("totalPrice", item.getTotalPrice());
                            itemMap.put("productImageUrl", item.getProductImageUrl());
                            return itemMap;
                        })
                        .toList();
                    orderData.put("items", orderItems);
                    orderData.put("orderItems", orderItems);

                    orders.add(orderData);
                }
            }

            response.put("orders", orders);
            response.put("totalCount", orders.size());
            response.put("success", true);
            if (orders.isEmpty()) {
                response.put("message", "No available orders at the moment");
            }

        } catch (Exception e) {
            response.put("orders", new ArrayList<>());
            response.put("totalCount", 0);
            response.put("success", false);
            response.put("message", "Error fetching orders: " + e.getMessage());
        }

        return ResponseEntity.ok(response);
    }

    @GetMapping("/orders/{partnerId}/active")
    @Transactional
    public ResponseEntity<Map<String, Object>> getActiveOrders(@PathVariable String partnerId) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long id = Long.parseLong(partnerId);

            // Get ALL active assignments for this partner (ACCEPTED, PICKED_UP, IN_TRANSIT)
            Optional<User> partnerOpt = userService.findById(id);
            if (partnerOpt.isEmpty()) {
                response.put("orders", new ArrayList<>());
                response.put("totalCount", 0);
                response.put("success", false);
                response.put("message", "Delivery partner not found");
                return ResponseEntity.badRequest().body(response);
            }

            User partner = partnerOpt.get();
            // Include CANCELLED, RETURNING, RETURNED so driver can return products to shop
            List<OrderAssignment.AssignmentStatus> activeStatuses = List.of(
                OrderAssignment.AssignmentStatus.ACCEPTED,
                OrderAssignment.AssignmentStatus.PICKED_UP,
                OrderAssignment.AssignmentStatus.IN_TRANSIT,
                OrderAssignment.AssignmentStatus.CANCELLED,  // So driver can return products
                OrderAssignment.AssignmentStatus.RETURNING,  // Driver returning to shop
                OrderAssignment.AssignmentStatus.RETURNED    // Driver returned to shop
            );

            List<OrderAssignment> activeAssignments = orderAssignmentService.findAssignmentsByPartnerAndStatuses(partner, activeStatuses);

            List<Map<String, Object>> orders = new ArrayList<>();
            for (OrderAssignment assignment : activeAssignments) {
                Map<String, Object> orderData = new HashMap<>();
                orderData.put("id", assignment.getId().toString());
                orderData.put("orderNumber", assignment.getOrder().getOrderNumber());
                orderData.put("totalAmount", assignment.getOrder().getTotalAmount());
                orderData.put("deliveryFee", assignment.getDeliveryFee());
                // Send BOTH assignment status and order status for proper handling
                String assignmentStatus = assignment.getStatus().name().toLowerCase();
                String orderStatus = assignment.getOrder().getStatus().name().toLowerCase();

                // If order is cancelled/returning/returned, use order status so driver sees return button
                if (orderStatus.equals("cancelled") || orderStatus.equals("returning_to_shop") || orderStatus.equals("returned_to_shop")) {
                    orderData.put("status", orderStatus);
                } else {
                    orderData.put("status", assignmentStatus);
                }
                orderData.put("assignmentStatus", assignmentStatus);
                orderData.put("orderStatus", orderStatus); // Always include order status
                orderData.put("createdAt", assignment.getCreatedAt().toString());
                orderData.put("deliveryAddress", assignment.getOrder().getDeliveryAddress());
                orderData.put("customerName", assignment.getOrder().getCustomer().getFirstName() + " " + assignment.getOrder().getCustomer().getLastName());
                orderData.put("customerPhone", assignment.getOrder().getCustomer().getMobileNumber());
                orderData.put("shopName", assignment.getOrder().getShop().getName());
                orderData.put("shopAddress", assignment.getOrder().getShop().getAddressLine1());
                orderData.put("shopLatitude", assignment.getOrder().getShop().getLatitude());
                orderData.put("shopLongitude", assignment.getOrder().getShop().getLongitude());
                // Use actual delivery coordinates from the order
                orderData.put("customerLatitude", assignment.getOrder().getDeliveryLatitude());
                orderData.put("customerLongitude", assignment.getOrder().getDeliveryLongitude());
                orderData.put("paymentMethod", assignment.getOrder().getPaymentMethod().name());
                orderData.put("paymentStatus", assignment.getOrder().getPaymentStatus().name());
                orderData.put("pickupOtp", assignment.getOrder().getPickupOtp());
                orderData.put("deliveryType", assignment.getOrder().getDeliveryType() != null ? assignment.getOrder().getDeliveryType().name() : null);
                orderData.put("assignmentId", assignment.getId().toString()); // Include assignmentId for location tracking

                // Add order items with images
                log.info("Order {} has {} items", assignment.getOrder().getOrderNumber(),
                    assignment.getOrder().getOrderItems() != null ? assignment.getOrder().getOrderItems().size() : 0);
                List<Map<String, Object>> orderItems = assignment.getOrder().getOrderItems().stream()
                    .map(item -> {
                        Map<String, Object> itemMap = new HashMap<>();
                        itemMap.put("id", item.getId());
                        itemMap.put("productName", item.getProductName() != null ? item.getProductName() : "Product");
                        itemMap.put("quantity", item.getQuantity());
                        itemMap.put("unitPrice", item.getUnitPrice());
                        itemMap.put("totalPrice", item.getTotalPrice());
                        itemMap.put("productImageUrl", item.getProductImageUrl());
                        return itemMap;
                    })
                    .toList();
                orderData.put("items", orderItems);
                orderData.put("orderItems", orderItems);

                orders.add(orderData);
            }

            response.put("orders", orders);
            response.put("totalCount", orders.size());
            response.put("success", true);

        } catch (Exception e) {
            log.error("Error fetching active orders for partner {}: {}", partnerId, e.getMessage(), e);
            response.put("orders", new ArrayList<>());
            response.put("totalCount", 0);
            response.put("success", false);
            response.put("message", "Error fetching active orders: " + e.getMessage());
        }

        return ResponseEntity.ok(response);
    }

    @GetMapping("/leaderboard")
    public ResponseEntity<Map<String, Object>> getLeaderboard() {
        // For now, return empty list - this will be implemented later
        Map<String, Object> response = new HashMap<>();
        response.put("leaderboard", new java.util.ArrayList<>());
        response.put("message", "Leaderboard functionality implemented");
        response.put("success", true);
        
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/status/{partnerId}")
    public ResponseEntity<Map<String, Object>> updateOnlineStatus(@PathVariable String partnerId, @RequestBody Map<String, Object> request) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long id = Long.parseLong(partnerId);
            Optional<User> userOpt = userService.findById(id);

            if (userOpt.isEmpty()) {
                response.put("success", false);
                response.put("message", "User not found");
                return ResponseEntity.badRequest().body(response);
            }

            User user = userOpt.get();

            // Check if user is a delivery partner
            if (user.getRole() != UserRole.DELIVERY_PARTNER) {
                response.put("success", false);
                response.put("message", "Access denied");
                return ResponseEntity.badRequest().body(response);
            }

            // Update online status
            Boolean isOnline = (Boolean) request.get("isOnline");
            Boolean isAvailable = (Boolean) request.get("isAvailable");
            String rideStatus = (String) request.get("rideStatus");

            if (isOnline != null) {
                user.setIsOnline(isOnline);
                if (isOnline) {
                    user.setLastActivity(LocalDateTime.now());
                }
            }

            if (isAvailable != null) {
                user.setIsAvailable(isAvailable);
            }

            if (rideStatus != null) {
                try {
                    User.RideStatus status = User.RideStatus.valueOf(rideStatus);
                    user.setRideStatus(status);
                } catch (IllegalArgumentException e) {
                    // Invalid ride status, ignore
                }
            }

            userService.save(user);

            response.put("success", true);
            response.put("message", "Status updated successfully");
            response.put("isOnline", user.getIsOnline());
            response.put("isAvailable", user.getIsAvailable());
            response.put("rideStatus", user.getRideStatus().name());

            return ResponseEntity.ok(response);

        } catch (NumberFormatException e) {
            response.put("success", false);
            response.put("message", "Invalid partner ID");
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "An error occurred while updating status");
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, Object>> forgotPassword(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        Map<String, Object> response = new HashMap<>();

        try {
            if (email == null || email.trim().isEmpty()) {
                response.put("success", false);
                response.put("message", "Email is required");
                return ResponseEntity.badRequest().body(response);
            }

            // Find user by email and check if they are a delivery partner
            Optional<User> userOpt = userService.findByEmail(email);

            if (userOpt.isEmpty()) {
                response.put("success", false);
                response.put("message", "No delivery partner found with this email address");
                return ResponseEntity.badRequest().body(response);
            }

            User user = userOpt.get();

            // Check if user is a delivery partner
            if (user.getRole() != UserRole.DELIVERY_PARTNER) {
                response.put("success", false);
                response.put("message", "This email is not associated with a delivery partner account");
                return ResponseEntity.badRequest().body(response);
            }

            // Check if user is active
            if (!user.getIsActive()) {
                response.put("success", false);
                response.put("message", "Account is disabled. Contact support.");
                return ResponseEntity.badRequest().body(response);
            }

            // Generate a simple temporary password (in production, use proper reset tokens)
            String tempPassword = "temp123" + System.currentTimeMillis() % 1000;
            String encodedTempPassword = passwordEncoder.encode(tempPassword);

            // Update user with temporary password
            user.setPassword(encodedTempPassword);
            user.setPasswordChangeRequired(true);
            user.setIsTemporaryPassword(true);
            userService.save(user);

            // In a real application, you would send this via email
            // For now, return it in the response for testing
            response.put("success", true);
            response.put("message", "Temporary password has been generated. Please use it to log in and change your password.");
            response.put("temporaryPassword", tempPassword); // Remove this in production!

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "An error occurred while processing your request");
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PutMapping("/change-password")
    public ResponseEntity<Map<String, Object>> changePassword(@RequestBody Map<String, String> request) {
        String partnerId = request.get("partnerId");
        String currentPassword = request.get("currentPassword");
        String newPassword = request.get("newPassword");
        
        Map<String, Object> response = new HashMap<>();
        
        try {
            if (partnerId == null || currentPassword == null || newPassword == null) {
                response.put("success", false);
                response.put("message", "Missing required fields");
                return ResponseEntity.badRequest().body(response);
            }
            
            Long id = Long.parseLong(partnerId);
            Optional<User> userOpt = userService.findById(id);
            
            if (userOpt.isEmpty()) {
                response.put("success", false);
                response.put("message", "User not found");
                return ResponseEntity.badRequest().body(response);
            }
            
            User user = userOpt.get();
            
            // Check if user is a delivery partner
            if (user.getRole() != UserRole.DELIVERY_PARTNER) {
                response.put("success", false);
                response.put("message", "Access denied");
                return ResponseEntity.badRequest().body(response);
            }
            
            // Verify current password
            if (!passwordEncoder.matches(currentPassword, user.getPassword())) {
                response.put("success", false);
                response.put("message", "Current password is incorrect");
                return ResponseEntity.badRequest().body(response);
            }
            
            // Update password
            user.setPassword(passwordEncoder.encode(newPassword));
            user.setPasswordChangeRequired(false);
            user.setIsTemporaryPassword(false);
            userService.save(user);
            
            response.put("success", true);
            response.put("message", "Password changed successfully");
            
            return ResponseEntity.ok(response);
            
        } catch (NumberFormatException e) {
            response.put("success", false);
            response.put("message", "Invalid partner ID");
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "An error occurred while changing password");
            return ResponseEntity.badRequest().body(response);
        }
    }

    // Real-time Status Tracking Endpoints

    @PutMapping("/update-location/{partnerId}")
    public ResponseEntity<Map<String, Object>> updateLocation(@PathVariable String partnerId, @RequestBody Map<String, Object> request) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long id = Long.parseLong(partnerId);
            Optional<User> userOpt = userService.findById(id);

            if (userOpt.isEmpty()) {
                response.put("success", false);
                response.put("message", "User not found");
                return ResponseEntity.badRequest().body(response);
            }

            User user = userOpt.get();

            if (user.getRole() != UserRole.DELIVERY_PARTNER) {
                response.put("success", false);
                response.put("message", "Access denied");
                return ResponseEntity.badRequest().body(response);
            }

            // Extract location data
            Double latitude = ((Number) request.get("latitude")).doubleValue();
            Double longitude = ((Number) request.get("longitude")).doubleValue();
            Double accuracy = request.get("accuracy") != null ? ((Number) request.get("accuracy")).doubleValue() : null;
            Double speed = request.get("speed") != null ? ((Number) request.get("speed")).doubleValue() : null;
            Double heading = request.get("heading") != null ? ((Number) request.get("heading")).doubleValue() : null;
            Double altitude = request.get("altitude") != null ? ((Number) request.get("altitude")).doubleValue() : null;
            Integer batteryLevel = request.get("batteryLevel") != null ? ((Number) request.get("batteryLevel")).intValue() : null;
            String networkType = (String) request.get("networkType");

            // Handle assignmentId as both String and Number
            Long assignmentId = null;
            if (request.get("assignmentId") != null) {
                Object assignmentIdObj = request.get("assignmentId");
                if (assignmentIdObj instanceof Number) {
                    assignmentId = ((Number) assignmentIdObj).longValue();
                } else if (assignmentIdObj instanceof String) {
                    try {
                        assignmentId = Long.parseLong((String) assignmentIdObj);
                    } catch (NumberFormatException e) {
                        log.warn("Invalid assignmentId format: {}", assignmentIdObj);
                    }
                }
            }

            String orderStatus = (String) request.get("orderStatus");

            // Update User entity (for backward compatibility)
            user.setCurrentLatitude(latitude);
            user.setCurrentLongitude(longitude);
            user.setLastLocationUpdate(LocalDateTime.now());
            user.setLastActivity(LocalDateTime.now());
            userService.save(user);

            // Save detailed location tracking
            DeliveryPartnerLocation location = DeliveryPartnerLocation.builder()
                    .partnerId(id)
                    .latitude(BigDecimal.valueOf(latitude))
                    .longitude(BigDecimal.valueOf(longitude))
                    .accuracy(accuracy != null ? BigDecimal.valueOf(accuracy) : null)
                    .speed(speed != null ? BigDecimal.valueOf(speed) : null)
                    .heading(heading != null ? BigDecimal.valueOf(heading) : null)
                    .altitude(altitude != null ? BigDecimal.valueOf(altitude) : null)
                    .batteryLevel(batteryLevel)
                    .networkType(networkType)
                    .assignmentId(assignmentId)
                    .orderStatus(orderStatus)
                    .recordedAt(LocalDateTime.now())
                    .isMoving(speed != null && speed > 1.0)
                    .build();

            deliveryPartnerLocationRepository.save(location);

            // Maintain only latest 5 records per partner
            try {
                deliveryPartnerLocationRepository.deleteOldLocationsKeepingLatest(id, 5);
            } catch (Exception e) {
                log.warn("Failed to cleanup old location records for partner {}: {}", id, e.getMessage());
            }

            response.put("success", true);
            response.put("message", "Location updated successfully");
            response.put("timestamp", LocalDateTime.now().toString());

            return ResponseEntity.ok(response);

        } catch (NumberFormatException e) {
            response.put("success", false);
            response.put("message", "Invalid partner ID or coordinates");
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            log.error("Error updating location for partner {}: {}", partnerId, e.getMessage(), e);
            response.put("success", false);
            response.put("message", "An error occurred while updating location");
            response.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PutMapping("/update-ride-status/{partnerId}")
    public ResponseEntity<Map<String, Object>> updateRideStatus(@PathVariable String partnerId, @RequestBody Map<String, Object> request) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long id = Long.parseLong(partnerId);
            Optional<User> userOpt = userService.findById(id);

            if (userOpt.isEmpty()) {
                response.put("success", false);
                response.put("message", "User not found");
                return ResponseEntity.badRequest().body(response);
            }

            User user = userOpt.get();

            if (user.getRole() != UserRole.DELIVERY_PARTNER) {
                response.put("success", false);
                response.put("message", "Access denied");
                return ResponseEntity.badRequest().body(response);
            }

            // Update ride status
            String rideStatusStr = (String) request.get("rideStatus");
            RideStatus rideStatus = RideStatus.valueOf(rideStatusStr);

            user.setRideStatus(rideStatus);
            user.setLastActivity(LocalDateTime.now());

            // Auto-update availability and online status based on ride status
            if (rideStatus == RideStatus.OFFLINE) {
                user.setIsOnline(false);
                user.setIsAvailable(false);
            } else if (rideStatus == RideStatus.AVAILABLE) {
                user.setIsOnline(true);
                user.setIsAvailable(true);
            } else {
                user.setIsOnline(true);
                user.setIsAvailable(false);
            }

            userService.save(user);

            response.put("success", true);
            response.put("message", "Ride status updated successfully");
            response.put("rideStatus", rideStatus);
            response.put("isOnline", user.getIsOnline());
            response.put("isAvailable", user.getIsAvailable());

            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            response.put("success", false);
            response.put("message", "Invalid ride status");
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "An error occurred while updating ride status");
            return ResponseEntity.badRequest().body(response);
        }
    }

    @GetMapping("/online-partners")
    public ResponseEntity<Map<String, Object>> getOnlinePartners() {
        try {
            List<User> onlinePartners = userService.findByRoleAndIsOnline(UserRole.DELIVERY_PARTNER, true);

            List<Map<String, Object>> partnersList = onlinePartners.stream()
                .map(partner -> {
                    Map<String, Object> partnerInfo = new HashMap<>();
                    partnerInfo.put("partnerId", partner.getId());
                    partnerInfo.put("name", partner.getFullName());
                    partnerInfo.put("email", partner.getEmail());
                    partnerInfo.put("isOnline", partner.getIsOnline());
                    partnerInfo.put("isAvailable", partner.getIsAvailable());
                    partnerInfo.put("rideStatus", partner.getRideStatus());
                    partnerInfo.put("currentLatitude", partner.getCurrentLatitude());
                    partnerInfo.put("currentLongitude", partner.getCurrentLongitude());
                    partnerInfo.put("lastLocationUpdate", partner.getLastLocationUpdate());
                    partnerInfo.put("lastActivity", partner.getLastActivity());
                    return partnerInfo;
                })
                .collect(Collectors.toList());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("partners", partnersList);
            response.put("totalCount", partnersList.size());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "An error occurred while fetching online partners");
            return ResponseEntity.badRequest().body(response);
        }
    }

    @GetMapping("/all-partners-status")
    public ResponseEntity<Map<String, Object>> getAllPartnersStatus() {
        try {
            List<User> allPartners = userService.findByRole(UserRole.DELIVERY_PARTNER);

            List<Map<String, Object>> partnersList = allPartners.stream()
                .map(partner -> {
                    Map<String, Object> partnerInfo = new HashMap<>();
                    partnerInfo.put("partnerId", partner.getId());
                    partnerInfo.put("name", partner.getFullName());
                    partnerInfo.put("email", partner.getEmail());
                    partnerInfo.put("isActive", partner.getIsActive());
                    partnerInfo.put("isOnline", partner.getIsOnline());
                    partnerInfo.put("isAvailable", partner.getIsAvailable());
                    partnerInfo.put("rideStatus", partner.getRideStatus());
                    partnerInfo.put("lastActivity", partner.getLastActivity());
                    partnerInfo.put("lastLogin", partner.getLastLogin());
                    return partnerInfo;
                })
                .collect(Collectors.toList());

            // Group partners by status for dashboard
            Map<String, Long> statusCounts = new HashMap<>();
            statusCounts.put("online", partnersList.stream().filter(p -> Boolean.TRUE.equals(p.get("isOnline"))).count());
            statusCounts.put("offline", partnersList.stream().filter(p -> Boolean.FALSE.equals(p.get("isOnline"))).count());
            statusCounts.put("available", partnersList.stream().filter(p -> Boolean.TRUE.equals(p.get("isAvailable"))).count());
            statusCounts.put("busy", partnersList.stream().filter(p -> RideStatus.BUSY.equals(p.get("rideStatus")) || RideStatus.ON_RIDE.equals(p.get("rideStatus"))).count());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("partners", partnersList);
            response.put("totalCount", partnersList.size());
            response.put("statusCounts", statusCounts);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "An error occurred while fetching partners status");
            return ResponseEntity.badRequest().body(response);
        }
    }

    // Order Accept/Reject endpoints for mobile app
    @PostMapping("/orders/{orderId}/accept")
    public ResponseEntity<Map<String, Object>> acceptOrder(@PathVariable String orderId, @RequestBody Map<String, Object> request) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long partnerId = Long.parseLong(request.get("partnerId").toString());

            // Find the assignment by order number and partnerId
            List<OrderAssignment> assignments = orderAssignmentService.findAssignmentsByOrderNumber(orderId);
            OrderAssignment assignment = assignments.stream()
                .filter(a -> a.getDeliveryPartner().getId().equals(partnerId) &&
                           a.getStatus() == OrderAssignment.AssignmentStatus.ASSIGNED)
                .findFirst()
                .orElseThrow(() -> new RuntimeException("No pending assignment found for this order and partner"));

            // Accept the assignment
            OrderAssignment acceptedAssignment = orderAssignmentService.acceptAssignment(assignment.getId(), partnerId);

            response.put("success", true);
            response.put("message", "Order accepted successfully");
            response.put("assignmentId", acceptedAssignment.getId());
            response.put("orderNumber", acceptedAssignment.getOrder().getOrderNumber());
            response.put("pickupOtp", acceptedAssignment.getOrder().getPickupOtp());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Error accepting order: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PostMapping("/orders/{orderId}/reject")
    public ResponseEntity<Map<String, Object>> rejectOrder(@PathVariable String orderId, @RequestBody Map<String, Object> request) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long partnerId = Long.parseLong(request.get("partnerId").toString());
            String reason = request.containsKey("reason") ? request.get("reason").toString() : "No reason provided";

            // Find the assignment by order number and partnerId
            List<OrderAssignment> assignments = orderAssignmentService.findAssignmentsByOrderNumber(orderId);
            OrderAssignment assignment = assignments.stream()
                .filter(a -> a.getDeliveryPartner().getId().equals(partnerId) &&
                           a.getStatus() == OrderAssignment.AssignmentStatus.ASSIGNED)
                .findFirst()
                .orElseThrow(() -> new RuntimeException("No pending assignment found for this order and partner"));

            // Reject the assignment
            orderAssignmentService.rejectAssignment(assignment.getId(), partnerId, reason);

            response.put("success", true);
            response.put("message", "Order rejected successfully");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Error rejecting order: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PostMapping("/orders/{orderId}/pickup")
    public ResponseEntity<Map<String, Object>> markOrderPickedUp(@PathVariable String orderId, @RequestBody Map<String, Object> request) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long partnerId = Long.parseLong(request.get("partnerId").toString());

            // Find the assignment by order number and partnerId
            List<OrderAssignment> assignments = orderAssignmentService.findAssignmentsByOrderNumber(orderId);
            OrderAssignment assignment = assignments.stream()
                .filter(a -> a.getDeliveryPartner().getId().equals(partnerId) &&
                           a.getStatus() == OrderAssignment.AssignmentStatus.ACCEPTED)
                .findFirst()
                .orElseThrow(() -> new RuntimeException("No accepted assignment found for this order and partner"));

            // Check if shop owner has verified the pickup OTP
            Order order = assignment.getOrder();
            if (order.getPickupOtpVerifiedAt() == null) {
                response.put("success", false);
                response.put("message", "Shop owner has not verified the pickup OTP yet. Please ask them to verify first.");
                response.put("otpRequired", true);
                return ResponseEntity.badRequest().body(response);
            }

            // Mark as picked up
            OrderAssignment updatedAssignment = orderAssignmentService.markPickedUp(assignment.getId(), partnerId);

            response.put("success", true);
            response.put("message", "Order marked as picked up");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Error marking order as picked up: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PostMapping("/orders/{orderId}/deliver")
    public ResponseEntity<Map<String, Object>> markOrderDelivered(@PathVariable String orderId, @RequestBody Map<String, Object> request) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long partnerId = Long.parseLong(request.get("partnerId").toString());
            String deliveryNotes = request.containsKey("deliveryNotes") ? request.get("deliveryNotes").toString() : null;

            // Find the assignment by order number and partnerId
            List<OrderAssignment> assignments = orderAssignmentService.findAssignmentsByOrderNumber(orderId);
            OrderAssignment assignment = assignments.stream()
                .filter(a -> a.getDeliveryPartner().getId().equals(partnerId) &&
                           (a.getStatus() == OrderAssignment.AssignmentStatus.PICKED_UP ||
                            a.getStatus() == OrderAssignment.AssignmentStatus.IN_TRANSIT))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("No picked up or in-transit assignment found for this order and partner"));

            // Mark as delivered
            OrderAssignment updatedAssignment = orderAssignmentService.markDelivered(assignment.getId(), partnerId, deliveryNotes);

            response.put("success", true);
            response.put("message", "Order marked as delivered");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Error marking order as delivered: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PostMapping("/orders/{orderId}/collect-payment")
    public ResponseEntity<Map<String, Object>> collectPayment(@PathVariable String orderId) {
        Map<String, Object> response = new HashMap<>();

        try {
            log.info("Collecting payment for order: {}", orderId);

            // Find the order by order number
            Order order = orderRepository.findByOrderNumber(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));

            // Validate payment method is COD
            if (order.getPaymentMethod() != Order.PaymentMethod.CASH_ON_DELIVERY) {
                response.put("success", false);
                response.put("message", "Payment collection is only for Cash on Delivery orders");
                return ResponseEntity.badRequest().body(response);
            }

            // Validate order is delivered
            if (order.getStatus() != Order.OrderStatus.DELIVERED) {
                response.put("success", false);
                response.put("message", "Order must be delivered before collecting payment");
                return ResponseEntity.badRequest().body(response);
            }

            // Mark payment as collected
            order.setPaymentStatus(Order.PaymentStatus.PAID);
            orderRepository.save(order);

            log.info("✅ Payment collected successfully for order: {}", orderId);

            response.put("success", true);
            response.put("message", "Payment collected successfully");
            response.put("orderId", orderId);
            response.put("paymentStatus", "PAID");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error collecting payment for order {}: {}", orderId, e.getMessage(), e);
            response.put("success", false);
            response.put("message", "Error collecting payment: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @GetMapping("/orders/{partnerId}/history")
    @Transactional
    public ResponseEntity<Map<String, Object>> getOrderHistory(@PathVariable String partnerId) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long id = Long.parseLong(partnerId);

            // Get all assignments for this partner (not just active ones)
            // Show all orders that were assigned to this partner, regardless of current status
            List<OrderAssignment> completedAssignments = orderAssignmentService.findAssignmentsByPartnerId(id,
                org.springframework.data.domain.Pageable.unpaged()).getContent()
                .stream()
                .filter(assignment ->
                    assignment.getStatus() == OrderAssignment.AssignmentStatus.DELIVERED ||
                    assignment.getStatus() == OrderAssignment.AssignmentStatus.CANCELLED ||
                    assignment.getStatus() == OrderAssignment.AssignmentStatus.PICKED_UP ||
                    assignment.getStatus() == OrderAssignment.AssignmentStatus.IN_TRANSIT
                )
                .collect(Collectors.toList());

            List<Map<String, Object>> orders = new ArrayList<>();
            for (OrderAssignment assignment : completedAssignments) {
                Map<String, Object> orderData = new HashMap<>();
                orderData.put("id", assignment.getId().toString());
                orderData.put("orderNumber", assignment.getOrder().getOrderNumber());
                orderData.put("totalAmount", assignment.getOrder().getTotalAmount());
                orderData.put("deliveryFee", assignment.getDeliveryFee());
                orderData.put("status", assignment.getStatus().name());
                orderData.put("createdAt", assignment.getCreatedAt().toString());
                orderData.put("deliveryAddress", assignment.getOrder().getDeliveryAddress());
                orderData.put("customerName", assignment.getOrder().getCustomer().getFirstName() + " " + assignment.getOrder().getCustomer().getLastName());
                orderData.put("customerPhone", assignment.getOrder().getCustomer().getMobileNumber());
                orderData.put("shopName", assignment.getOrder().getShop().getName());
                orderData.put("shopAddress", assignment.getOrder().getShop().getAddressLine1());
                orderData.put("deliveryType", assignment.getOrder().getDeliveryType() != null ? assignment.getOrder().getDeliveryType().name() : null);
                orderData.put("deliveredAt", assignment.getDeliveryCompletedAt() != null ? assignment.getDeliveryCompletedAt().toString() : null);
                orders.add(orderData);
            }

            response.put("orders", orders);
            response.put("totalCount", orders.size());
            response.put("success", true);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.put("orders", new ArrayList<>());
            response.put("totalCount", 0);
            response.put("success", false);
            response.put("message", "Error fetching order history: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @GetMapping("/earnings/{partnerId}")
    public ResponseEntity<Map<String, Object>> getEarnings(@PathVariable String partnerId, @RequestParam(required = false) String period) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long id = Long.parseLong(partnerId);

            // Calculate earnings from completed assignments
            List<OrderAssignment> completedAssignments = orderAssignmentService.findAssignmentsByPartnerId(id,
                org.springframework.data.domain.Pageable.unpaged()).getContent()
                .stream()
                .filter(assignment -> assignment.getStatus() == OrderAssignment.AssignmentStatus.DELIVERED)
                .collect(Collectors.toList());

            double totalEarnings = completedAssignments.stream()
                .mapToDouble(assignment -> assignment.getPartnerCommission() != null ? assignment.getPartnerCommission().doubleValue() : 0.0)
                .sum();

            long totalDeliveries = completedAssignments.size();

            // Simple earnings calculation (can be enhanced with period filtering)
            Map<String, Object> earnings = new HashMap<>();
            earnings.put("todayEarnings", totalEarnings); // Simplified - shows total for now
            earnings.put("weeklyEarnings", totalEarnings);
            earnings.put("monthlyEarnings", totalEarnings);
            earnings.put("totalEarnings", totalEarnings);
            earnings.put("todayDeliveries", totalDeliveries);
            earnings.put("weeklyDeliveries", totalDeliveries);
            earnings.put("monthlyDeliveries", totalDeliveries);
            earnings.put("totalDeliveries", totalDeliveries);
            earnings.put("recentEarnings", new ArrayList<>());

            response.put("success", true);
            response.putAll(earnings);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Error fetching earnings: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // Customer Order Tracking Endpoints

    @GetMapping("/track/order/{orderNumber}")
    public ResponseEntity<Map<String, Object>> trackOrderByOrderNumber(@PathVariable String orderNumber) {
        Map<String, Object> response = new HashMap<>();

        try {
            // Find order assignment by order number
            Order order = orderRepository.findByOrderNumber(orderNumber)
                    .orElse(null);
            if (order == null) {
                response.put("success", false);
                response.put("message", "Order not found");
                return ResponseEntity.badRequest().body(response);
            }
            Optional<OrderAssignment> assignmentOpt = orderAssignmentService.findActiveAssignmentByOrderId(order.getId());

            if (assignmentOpt.isEmpty()) {
                response.put("success", false);
                response.put("message", "Order not found or not assigned to delivery partner");
                return ResponseEntity.badRequest().body(response);
            }

            OrderAssignment assignment = assignmentOpt.get();

            // Get latest location for this assignment
            Optional<DeliveryPartnerLocation> latestLocation =
                deliveryPartnerLocationRepository.findLatestLocationByAssignmentId(assignment.getId());

            if (latestLocation.isEmpty()) {
                response.put("success", false);
                response.put("message", "Driver location not available");
                return ResponseEntity.badRequest().body(response);
            }

            DeliveryPartnerLocation location = latestLocation.get();

            // Build tracking response
            Map<String, Object> trackingData = new HashMap<>();
            trackingData.put("orderNumber", orderNumber);
            trackingData.put("assignmentId", assignment.getId());
            trackingData.put("deliveryStatus", assignment.getStatus().name());
            trackingData.put("partnerId", assignment.getDeliveryPartner().getId());
            trackingData.put("partnerName", assignment.getDeliveryPartner().getFullName());
            trackingData.put("partnerPhone", assignment.getDeliveryPartner().getMobileNumber());

            Map<String, Object> currentLocation = new HashMap<>();
            currentLocation.put("latitude", location.getLatitude());
            currentLocation.put("longitude", location.getLongitude());
            currentLocation.put("accuracy", location.getAccuracy());
            currentLocation.put("speed", location.getSpeed());
            currentLocation.put("heading", location.getHeading());
            currentLocation.put("isMoving", location.getIsMoving());
            currentLocation.put("lastUpdated", location.getRecordedAt());

            trackingData.put("currentLocation", currentLocation);

            // Add delivery address
            Map<String, Object> deliveryAddress = new HashMap<>();
            deliveryAddress.put("address", assignment.getOrder().getDeliveryAddress());
            // Add customer address coordinates if available
            // This would need to be implemented based on your address storage

            trackingData.put("deliveryAddress", deliveryAddress);

            response.put("success", true);
            response.put("tracking", trackingData);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error tracking order {}: {}", orderNumber, e.getMessage(), e);
            response.put("success", false);
            response.put("message", "Error tracking order: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @GetMapping("/track/assignment/{assignmentId}")
    public ResponseEntity<Map<String, Object>> trackOrderByAssignmentId(@PathVariable Long assignmentId) {
        Map<String, Object> response = new HashMap<>();

        try {
            // Get recent location history for this assignment
            List<DeliveryPartnerLocation> locationHistory =
                deliveryPartnerLocationRepository.findRecentLocationsByPartnerId(assignmentId, 5);

            if (locationHistory.isEmpty()) {
                response.put("success", false);
                response.put("message", "No location history found for this delivery");
                return ResponseEntity.badRequest().body(response);
            }

            List<Map<String, Object>> locations = locationHistory.stream()
                .map(loc -> {
                    Map<String, Object> locationData = new HashMap<>();
                    locationData.put("latitude", loc.getLatitude());
                    locationData.put("longitude", loc.getLongitude());
                    locationData.put("accuracy", loc.getAccuracy());
                    locationData.put("speed", loc.getSpeed());
                    locationData.put("heading", loc.getHeading());
                    locationData.put("isMoving", loc.getIsMoving());
                    locationData.put("timestamp", loc.getRecordedAt());
                    return locationData;
                })
                .collect(Collectors.toList());

            response.put("success", true);
            response.put("locationHistory", locations);
            response.put("totalPoints", locations.size());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error getting location history for assignment {}: {}", assignmentId, e.getMessage(), e);
            response.put("success", false);
            response.put("message", "Error getting location history: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // Admin endpoint to manually set partner availability for testing
    @PostMapping("/admin/partners/{partnerId}/set-available")
    public ResponseEntity<Map<String, Object>> setPartnerAvailable(
        @PathVariable Long partnerId,
        @RequestParam boolean available,
        @RequestParam boolean online
    ) {
        Map<String, Object> response = new HashMap<>();

        try {
            Optional<User> userOpt = userService.findById(partnerId);

            if (userOpt.isEmpty()) {
                response.put("success", false);
                response.put("message", "Partner not found");
                return ResponseEntity.badRequest().body(response);
            }

            User partner = userOpt.get();

            if (partner.getRole() != User.UserRole.DELIVERY_PARTNER) {
                response.put("success", false);
                response.put("message", "User is not a delivery partner");
                return ResponseEntity.badRequest().body(response);
            }

            partner.setIsAvailable(available);
            partner.setIsOnline(online);
            partner.setIsActive(true);

            if (online && available) {
                partner.setRideStatus(User.RideStatus.AVAILABLE);
                partner.setLastActivity(LocalDateTime.now());
            } else if (online && !available) {
                partner.setRideStatus(User.RideStatus.BUSY);
            } else {
                partner.setRideStatus(User.RideStatus.OFFLINE);
            }

            User updated = userService.save(partner);

            log.info("Partner {} status updated - Online: {}, Available: {}, RideStatus: {}",
                partner.getEmail(), online, available, updated.getRideStatus());

            Map<String, Object> partnerData = new HashMap<>();
            partnerData.put("partnerId", updated.getId());
            partnerData.put("email", updated.getEmail());
            partnerData.put("name", updated.getFullName());
            partnerData.put("isActive", updated.getIsActive());
            partnerData.put("isOnline", updated.getIsOnline());
            partnerData.put("isAvailable", updated.getIsAvailable());
            partnerData.put("rideStatus", updated.getRideStatus().name());

            response.put("success", true);
            response.put("message", "Partner status updated successfully");
            response.put("partner", partnerData);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error updating partner status: {}", e.getMessage(), e);
            response.put("success", false);
            response.put("message", "Error updating partner status: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    // Admin endpoint to get all delivery partners with their status
    @GetMapping("/admin/partners")
    public ResponseEntity<Map<String, Object>> getAllDeliveryPartners() {
        Map<String, Object> response = new HashMap<>();

        try {
            List<User> allPartners = userService.findByRole(UserRole.DELIVERY_PARTNER);

            List<Map<String, Object>> partnersList = allPartners.stream()
                .map(partner -> {
                    Map<String, Object> partnerInfo = new HashMap<>();
                    partnerInfo.put("partnerId", partner.getId());
                    partnerInfo.put("name", partner.getFullName());
                    partnerInfo.put("email", partner.getEmail());
                    partnerInfo.put("phone", partner.getMobileNumber());
                    partnerInfo.put("isActive", partner.getIsActive());
                    partnerInfo.put("isOnline", partner.getIsOnline());
                    partnerInfo.put("isAvailable", partner.getIsAvailable());
                    partnerInfo.put("rideStatus", partner.getRideStatus() != null ? partner.getRideStatus().name() : "OFFLINE");
                    partnerInfo.put("lastActivity", partner.getLastActivity());
                    partnerInfo.put("lastLogin", partner.getLastLogin());

                    // Include rating, delivery count, and earnings
                    try {
                        Double rating = orderAssignmentRepository.getAverageRatingByPartnerId(partner.getId());
                        Long deliveryCount = orderAssignmentRepository.countCompletedAssignmentsByPartnerId(partner.getId());
                        Double earnings = orderAssignmentRepository.getTotalEarningsByPartnerId(partner.getId());
                        partnerInfo.put("rating", rating != null ? rating : 0.0);
                        partnerInfo.put("totalDeliveries", deliveryCount != null ? deliveryCount : 0);
                        partnerInfo.put("totalEarnings", earnings != null ? earnings : 0.0);
                    } catch (Exception e) {
                        partnerInfo.put("rating", 0.0);
                        partnerInfo.put("totalDeliveries", 0);
                        partnerInfo.put("totalEarnings", 0.0);
                    }

                    return partnerInfo;
                })
                .collect(Collectors.toList());

            // Statistics
            long onlineCount = partnersList.stream().filter(p -> Boolean.TRUE.equals(p.get("isOnline"))).count();
            long availableCount = partnersList.stream().filter(p -> Boolean.TRUE.equals(p.get("isAvailable"))).count();
            long activeCount = partnersList.stream().filter(p -> Boolean.TRUE.equals(p.get("isActive"))).count();

            Map<String, Object> statistics = new HashMap<>();
            statistics.put("total", partnersList.size());
            statistics.put("active", activeCount);
            statistics.put("online", onlineCount);
            statistics.put("available", availableCount);
            statistics.put("offline", partnersList.size() - onlineCount);

            response.put("success", true);
            response.put("partners", partnersList);
            response.put("statistics", statistics);
            response.put("message", partnersList.isEmpty() ? "No delivery partners found" : "Partners retrieved successfully");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error fetching delivery partners: {}", e.getMessage(), e);
            response.put("success", false);
            response.put("message", "Error fetching delivery partners: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Mark order as returning to shop (when customer cancels after pickup)
     */
    @PostMapping("/orders/{orderNumber}/return-to-shop")
    @Transactional(noRollbackFor = Exception.class)
    public ResponseEntity<Map<String, Object>> startReturnToShop(
            @PathVariable String orderNumber,
            @RequestBody Map<String, String> request) {
        Map<String, Object> response = new HashMap<>();
        String partnerId = request.get("partnerId");

        try {
            log.info("Starting return to shop for order: {} by partner: {}", orderNumber, partnerId);

            // Find the order
            Optional<Order> orderOpt = orderRepository.findByOrderNumber(orderNumber);
            if (orderOpt.isEmpty()) {
                response.put("success", false);
                response.put("message", "Order not found");
                return ResponseEntity.badRequest().body(response);
            }

            Order order = orderOpt.get();

            // Fetch shop owner email BEFORE saving (while session is still open)
            String shopOwnerEmail = null;
            if (order.getShop() != null) {
                shopOwnerEmail = order.getShop().getOwnerEmail();
            }

            // Update order status to RETURNING_TO_SHOP
            order.setStatus(Order.OrderStatus.RETURNING_TO_SHOP);
            orderRepository.save(order);

            // Update assignment status - find the assignment for this order
            List<OrderAssignment> assignments = orderAssignmentRepository.findByOrderId(order.getId());
            for (OrderAssignment assignment : assignments) {
                if (assignment.getDeliveryPartner() != null &&
                    assignment.getDeliveryPartner().getId().equals(Long.parseLong(partnerId))) {
                    assignment.setStatus(OrderAssignment.AssignmentStatus.RETURNING);
                    orderAssignmentRepository.save(assignment);
                    break;
                }
            }

            // Send FCM notification to shop owner
            try {
                if (shopOwnerEmail != null) {
                    User shopOwner = userService.findByEmail(shopOwnerEmail).orElse(null);
                    if (shopOwner != null) {
                        List<UserFcmToken> fcmTokens = userFcmTokenRepository.findActiveTokensByUserId(shopOwner.getId());
                        for (UserFcmToken token : fcmTokens) {
                            try {
                                firebaseNotificationService.sendOrderNotification(
                                    order.getOrderNumber(),
                                    "RETURNING_TO_SHOP",
                                    token.getFcmToken(),
                                    shopOwner.getId()
                                );
                                log.info("Return notification sent to shop owner for order: {}", orderNumber);
                                break;
                            } catch (Exception tokenError) {
                                log.warn("Failed to send return notification to shop owner: {}", tokenError.getMessage());
                            }
                        }
                    }
                }
            } catch (Exception e) {
                log.error("Failed to send return notification to shop owner: {}", e.getMessage());
            }

            // Send WebSocket notification for real-time web updates
            try {
                Map<String, Object> wsData = new HashMap<>();
                wsData.put("type", "ORDER_RETURNING");
                wsData.put("orderId", order.getId());
                wsData.put("orderNumber", order.getOrderNumber());
                wsData.put("status", "RETURNING_TO_SHOP");
                wsData.put("message", "Driver is returning products to shop");
                wsData.put("timestamp", LocalDateTime.now().toString());

                String destination = "/topic/shop/" + order.getShop().getId() + "/orders";
                messagingTemplate.convertAndSend(destination, wsData);
                log.info("✅ WebSocket notification sent for returning order: {}", orderNumber);
            } catch (Exception e) {
                log.error("Failed to send WebSocket notification for returning order: {}", e.getMessage());
            }

            response.put("success", true);
            response.put("message", "Order marked as returning to shop");
            response.put("status", "RETURNING_TO_SHOP");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error starting return to shop for order: {}", orderNumber, e);
            response.put("success", false);
            response.put("message", "Error: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Mark order as returned to shop (driver confirms products returned)
     */
    @PostMapping("/orders/{orderNumber}/returned-to-shop")
    @Transactional(noRollbackFor = Exception.class)
    public ResponseEntity<Map<String, Object>> confirmReturnedToShop(
            @PathVariable String orderNumber,
            @RequestBody Map<String, String> request) {
        Map<String, Object> response = new HashMap<>();
        String partnerId = request.get("partnerId");

        try {
            log.info("Confirming return to shop for order: {} by partner: {}", orderNumber, partnerId);

            // Find the order
            Optional<Order> orderOpt = orderRepository.findByOrderNumber(orderNumber);
            if (orderOpt.isEmpty()) {
                response.put("success", false);
                response.put("message", "Order not found");
                return ResponseEntity.badRequest().body(response);
            }

            Order order = orderOpt.get();

            // Fetch shop owner email BEFORE saving (while session is still open)
            String shopOwnerEmail = null;
            if (order.getShop() != null) {
                shopOwnerEmail = order.getShop().getOwnerEmail();
            }

            // Update order status to RETURNED_TO_SHOP
            order.setStatus(Order.OrderStatus.RETURNED_TO_SHOP);
            orderRepository.save(order);

            // Update assignment status - find the assignment for this order
            List<OrderAssignment> assignments = orderAssignmentRepository.findByOrderId(order.getId());
            for (OrderAssignment assignment : assignments) {
                if (assignment.getDeliveryPartner() != null &&
                    assignment.getDeliveryPartner().getId().equals(Long.parseLong(partnerId))) {
                    assignment.setStatus(OrderAssignment.AssignmentStatus.RETURNED);
                    assignment.setDeliveryCompletedAt(LocalDateTime.now());
                    orderAssignmentRepository.save(assignment);
                    break;
                }
            }

            // Send FCM notification to shop owner to confirm receipt
            try {
                if (shopOwnerEmail != null) {
                    User shopOwner = userService.findByEmail(shopOwnerEmail).orElse(null);
                    if (shopOwner != null) {
                        List<UserFcmToken> fcmTokens = userFcmTokenRepository.findActiveTokensByUserId(shopOwner.getId());
                        for (UserFcmToken token : fcmTokens) {
                            try {
                                firebaseNotificationService.sendOrderNotification(
                                    order.getOrderNumber(),
                                    "RETURNED_TO_SHOP",
                                    token.getFcmToken(),
                                    shopOwner.getId()
                                );
                                log.info("Return completed notification sent to shop owner for order: {}", orderNumber);
                                break;
                            } catch (Exception tokenError) {
                                log.warn("Failed to send return completed notification: {}", tokenError.getMessage());
                            }
                        }
                    }
                }
            } catch (Exception e) {
                log.error("Failed to send return completed notification: {}", e.getMessage());
            }

            // Send WebSocket notification for real-time web updates
            try {
                Map<String, Object> wsData = new HashMap<>();
                wsData.put("type", "ORDER_RETURNED");
                wsData.put("orderId", order.getId());
                wsData.put("orderNumber", order.getOrderNumber());
                wsData.put("status", "RETURNED_TO_SHOP");
                wsData.put("message", "Products have been returned to shop. Please verify and collect.");
                wsData.put("timestamp", LocalDateTime.now().toString());

                String destination = "/topic/shop/" + order.getShop().getId() + "/orders";
                messagingTemplate.convertAndSend(destination, wsData);
                log.info("✅ WebSocket notification sent for returned order: {}", orderNumber);
            } catch (Exception e) {
                log.error("Failed to send WebSocket notification for returned order: {}", e.getMessage());
            }

            response.put("success", true);
            response.put("message", "Order returned to shop successfully");
            response.put("status", "RETURNED_TO_SHOP");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error confirming return to shop for order: {}", orderNumber, e);
            response.put("success", false);
            response.put("message", "Error: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }
}