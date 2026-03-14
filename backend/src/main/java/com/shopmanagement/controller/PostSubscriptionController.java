package com.shopmanagement.controller;

import com.razorpay.RazorpayException;
import com.shopmanagement.entity.PostSubscription;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.service.PostSubscriptionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/subscriptions")
@RequiredArgsConstructor
@Slf4j
public class PostSubscriptionController {

    private final PostSubscriptionService subscriptionService;
    private final UserRepository userRepository;

    /**
     * Get subscription config/pricing for a post type.
     * GET /api/subscriptions/config?postType=MARKETPLACE
     */
    @GetMapping("/config")
    public ResponseEntity<Map<String, Object>> getConfig(
            @RequestParam(defaultValue = "MARKETPLACE") String postType) {
        return ResponseEntity.ok(subscriptionService.getSubscriptionConfig(postType));
    }

    /**
     * Create a monthly subscription for a post type.
     * POST /api/subscriptions/create
     * Body: { "postType": "MARKETPLACE" }
     */
    @PostMapping("/create")
    public ResponseEntity<?> createSubscription(
            @RequestBody Map<String, String> request,
            Authentication authentication) {
        try {
            String username = authentication.getName();
            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            String postType = request.getOrDefault("postType", "MARKETPLACE");
            Map<String, Object> result = subscriptionService.createSubscription(user.getId(), postType);
            return ResponseEntity.ok(result);
        } catch (RazorpayException e) {
            log.error("Failed to create subscription: {}", e.getMessage());
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to create subscription: " + e.getMessage()));
        }
    }

    /**
     * Verify subscription after mandate setup (mobile calls after Razorpay checkout).
     * POST /api/subscriptions/verify
     * Body: { "subscriptionDbId": 1, "razorpaySubscriptionId": "sub_xxx", "razorpayPaymentId": "pay_xxx" }
     */
    @PostMapping("/verify")
    public ResponseEntity<?> verifySubscription(
            @RequestBody Map<String, Object> request,
            Authentication authentication) {
        try {
            String username = authentication.getName();
            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            Long subscriptionDbId = Long.valueOf(request.get("subscriptionDbId").toString());
            String razorpaySubscriptionId = (String) request.get("razorpaySubscriptionId");
            String razorpayPaymentId = (String) request.getOrDefault("razorpayPaymentId", "");

            PostSubscription sub = subscriptionService.verifyAndActivate(
                    subscriptionDbId, user.getId(), razorpaySubscriptionId, razorpayPaymentId);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "subscriptionId", sub.getId(),
                    "status", sub.getStatus().name(),
                    "message", "Subscription activated successfully"
            ));
        } catch (RazorpayException e) {
            log.error("Subscription verification failed: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Subscription verification failed: " + e.getMessage()));
        }
    }

    /**
     * Link subscription to a post after post is created.
     * POST /api/subscriptions/{dbId}/link-post
     * Body: { "postId": 123 }
     */
    @PostMapping("/{dbId}/link-post")
    public ResponseEntity<?> linkPost(
            @PathVariable Long dbId,
            @RequestBody Map<String, Long> request) {
        Long postId = request.get("postId");
        subscriptionService.linkSubscriptionToPost(dbId, postId);
        return ResponseEntity.ok(Map.of("success", true));
    }

    /**
     * Get current user's subscriptions.
     * GET /api/subscriptions/my
     */
    @GetMapping("/my")
    public ResponseEntity<List<PostSubscription>> getMySubscriptions(Authentication authentication) {
        String username = authentication.getName();
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return ResponseEntity.ok(subscriptionService.getUserSubscriptions(user.getId()));
    }

    /**
     * Check if current user has an active subscription.
     * GET /api/subscriptions/status
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getSubscriptionStatus(Authentication authentication) {
        String username = authentication.getName();
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        boolean active = subscriptionService.hasActiveSubscription(user.getId());
        List<PostSubscription> subs = subscriptionService.getUserSubscriptions(user.getId());

        return ResponseEntity.ok(Map.of(
                "hasActiveSubscription", active,
                "subscriptions", subs
        ));
    }

    /**
     * User cancels their own subscription.
     * POST /api/subscriptions/{dbId}/cancel
     */
    @PostMapping("/{dbId}/cancel")
    public ResponseEntity<?> cancelSubscription(
            @PathVariable Long dbId,
            Authentication authentication) {
        String username = authentication.getName();
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        PostSubscription sub = subscriptionService.getUserSubscriptions(user.getId())
                .stream()
                .filter(s -> s.getId().equals(dbId))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Subscription not found"));

        subscriptionService.cancelSubscriptionForPost(sub.getPostId());
        return ResponseEntity.ok(Map.of("success", true, "message", "Subscription cancelled successfully"));
    }

    /**
     * Admin cancel any subscription.
     * POST /api/subscriptions/admin/{dbId}/cancel
     */
    @PostMapping("/admin/{dbId}/cancel")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> adminCancelSubscription(@PathVariable Long dbId) {
        PostSubscription sub = subscriptionService.getUserSubscriptions(0L)
                .stream()
                .filter(s -> s.getId().equals(dbId))
                .findFirst()
                .orElse(null);

        if (sub == null) {
            // Find by id directly
            subscriptionService.cancelSubscriptionById(dbId);
        } else {
            subscriptionService.cancelSubscriptionForPost(sub.getPostId());
        }
        return ResponseEntity.ok(Map.of("success", true, "message", "Subscription cancelled by admin"));
    }

    /**
     * Admin view all subscriptions.
     * GET /api/subscriptions/admin/all
     */
    @GetMapping("/admin/all")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> getAllSubscriptions() {
        return ResponseEntity.ok(subscriptionService.getAllSubscriptions());
    }

    /**
     * Razorpay webhook endpoint — receives subscription events (no auth needed).
     * POST /api/subscriptions/webhook
     */
    @PostMapping("/webhook")
    public ResponseEntity<String> handleWebhook(
            @RequestBody String payload,
            @RequestHeader(value = "X-Razorpay-Signature", required = false) String signature) {
        try {
            subscriptionService.handleWebhook(payload, signature);
            return ResponseEntity.ok("OK");
        } catch (Exception e) {
            log.error("Webhook processing error: {}", e.getMessage());
            return ResponseEntity.ok("OK"); // Always return 200 to Razorpay
        }
    }
}
