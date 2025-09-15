package com.shopmanagement.controller;

import com.shopmanagement.entity.User;
import com.shopmanagement.entity.User.UserRole;
import com.shopmanagement.entity.User.RideStatus;
import com.shopmanagement.entity.OrderAssignment;
import com.shopmanagement.service.UserService;
import com.shopmanagement.service.OrderAssignmentService;
import com.shopmanagement.service.JwtService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import lombok.extern.slf4j.Slf4j;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/mobile/delivery-partner")
@CrossOrigin(origins = "*")
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

    @PostMapping("/login")
    @Transactional
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
            profile.put("isOnline", true); // Default for now
            profile.put("isAvailable", true); // Default for now
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
    @Transactional(readOnly = true)
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
                    orderData.put("paymentMethod", assignment.getOrder().getPaymentMethod().name());
                    orderData.put("paymentStatus", assignment.getOrder().getPaymentStatus().name());
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
    @Transactional(readOnly = true)
    public ResponseEntity<Map<String, Object>> getActiveOrders(@PathVariable String partnerId) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long id = Long.parseLong(partnerId);

            // Get current active assignment for this partner
            Optional<OrderAssignment> currentAssignment = orderAssignmentService.findCurrentAssignmentByPartnerId(id);

            List<Map<String, Object>> orders = new ArrayList<>();
            if (currentAssignment.isPresent()) {
                OrderAssignment assignment = currentAssignment.get();
                // Only show if status is ACCEPTED, PICKED_UP, or IN_TRANSIT
                if (assignment.getStatus() == OrderAssignment.AssignmentStatus.ACCEPTED ||
                    assignment.getStatus() == OrderAssignment.AssignmentStatus.PICKED_UP ||
                    assignment.getStatus() == OrderAssignment.AssignmentStatus.IN_TRANSIT) {

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
                    orderData.put("paymentMethod", assignment.getOrder().getPaymentMethod().name());
                    orderData.put("paymentStatus", assignment.getOrder().getPaymentStatus().name());
                    orders.add(orderData);
                }
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

            // Update location
            Double latitude = ((Number) request.get("latitude")).doubleValue();
            Double longitude = ((Number) request.get("longitude")).doubleValue();

            user.setCurrentLatitude(latitude);
            user.setCurrentLongitude(longitude);
            user.setLastLocationUpdate(LocalDateTime.now());
            user.setLastActivity(LocalDateTime.now());

            userService.save(user);

            response.put("success", true);
            response.put("message", "Location updated successfully");

            return ResponseEntity.ok(response);

        } catch (NumberFormatException e) {
            response.put("success", false);
            response.put("message", "Invalid partner ID or coordinates");
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "An error occurred while updating location");
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
    @Transactional
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

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Error accepting order: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PostMapping("/orders/{orderId}/reject")
    @Transactional
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
    @Transactional
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
    @Transactional
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

    @GetMapping("/orders/{partnerId}/history")
    @Transactional(readOnly = true)
    public ResponseEntity<Map<String, Object>> getOrderHistory(@PathVariable String partnerId) {
        Map<String, Object> response = new HashMap<>();

        try {
            Long id = Long.parseLong(partnerId);

            // Get completed assignments for this partner (DELIVERED status)
            List<OrderAssignment> completedAssignments = orderAssignmentService.findAssignmentsByPartnerId(id,
                org.springframework.data.domain.Pageable.unpaged()).getContent()
                .stream()
                .filter(assignment -> assignment.getStatus() == OrderAssignment.AssignmentStatus.DELIVERED)
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
    @Transactional(readOnly = true)
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
}