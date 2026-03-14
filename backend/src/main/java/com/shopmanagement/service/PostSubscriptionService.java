package com.shopmanagement.service;

import com.razorpay.Plan;
import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;
import com.razorpay.Subscription;
import com.razorpay.Utils;
import com.shopmanagement.config.RazorpayConfig;
import com.shopmanagement.entity.PostSubscription;
import com.shopmanagement.repository.PostSubscriptionRepository;
import lombok.extern.slf4j.Slf4j;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@Slf4j
public class PostSubscriptionService {

    private final PostSubscriptionRepository subscriptionRepository;
    private final RazorpayClient razorpayClient;
    private final RazorpayConfig razorpayConfig;
    private final SettingService settingService;

    // Cache plan IDs per post type (in-memory, reset on restart)
    private final Map<String, String> planIdCache = new HashMap<>();

    @Autowired
    public PostSubscriptionService(PostSubscriptionRepository subscriptionRepository,
                                   @Autowired(required = false) RazorpayClient razorpayClient,
                                   RazorpayConfig razorpayConfig,
                                   SettingService settingService) {
        this.subscriptionRepository = subscriptionRepository;
        this.razorpayClient = razorpayClient;
        this.razorpayConfig = razorpayConfig;
        this.settingService = settingService;
    }

    private boolean isTestMode() {
        return razorpayConfig.isTestMode();
    }

    private int getSubscriptionPrice(String postType) {
        String defaultPrice = settingService.getSettingValue("subscription.price.MARKETPLACE", "49");
        return Integer.parseInt(
                settingService.getSettingValue("subscription.price." + postType, defaultPrice));
    }

    /**
     * Get or create a Razorpay Plan for the given post type.
     * Plans are cached in memory per post type.
     */
    private String getOrCreatePlan(String postType, int amountRupees) throws RazorpayException {
        String cacheKey = postType + "_" + amountRupees;

        // Check memory cache first
        if (planIdCache.containsKey(cacheKey)) {
            return planIdCache.get(cacheKey);
        }

        // Check settings for persisted plan ID
        String settingKey = "subscription.plan_id." + postType;
        String existingPlanId = settingService.getSettingValue(settingKey, "");
        if (!existingPlanId.isEmpty()) {
            planIdCache.put(cacheKey, existingPlanId);
            return existingPlanId;
        }

        if (isTestMode()) {
            String mockPlanId = "plan_test_" + postType + "_" + amountRupees;
            planIdCache.put(cacheKey, mockPlanId);
            log.info("TEST MODE: Using mock plan: {}", mockPlanId);
            return mockPlanId;
        }

        // Create new plan in Razorpay
        JSONObject item = new JSONObject();
        item.put("name", "NammaOoru " + postType + " Monthly Plan");
        item.put("amount", amountRupees * 100); // in paise
        item.put("unit_amount", amountRupees * 100);
        item.put("currency", "INR");

        JSONObject planRequest = new JSONObject();
        planRequest.put("period", "monthly");
        planRequest.put("interval", 1);
        planRequest.put("item", item);

        Plan plan = razorpayClient.plans.create(planRequest);
        String planId = plan.get("id");

        // Store plan ID in settings for persistence
        settingService.saveSetting(settingKey, planId, "Razorpay plan ID for " + postType + " monthly subscription");
        planIdCache.put(cacheKey, planId);

        log.info("Created Razorpay plan: planId={}, postType={}, amount={}rs", planId, postType, amountRupees);
        return planId;
    }

    /**
     * Create a monthly subscription for a post.
     * Returns subscription details including the Razorpay subscription ID for mobile checkout.
     */
    @Transactional
    public Map<String, Object> createSubscription(Long userId, String postType) throws RazorpayException {
        int amountRupees = getSubscriptionPrice(postType);
        String currency = settingService.getSettingValue("paid_post.currency", "INR");

        String planId = getOrCreatePlan(postType, amountRupees);

        String subscriptionId;
        String shortUrl = null;

        if (isTestMode()) {
            subscriptionId = "sub_test_" + userId + "_" + System.currentTimeMillis();
            log.info("TEST MODE: Created mock subscription: {}", subscriptionId);
        } else {
            JSONObject subscriptionRequest = new JSONObject();
            subscriptionRequest.put("plan_id", planId);
            subscriptionRequest.put("total_count", 120); // up to 10 years, effectively unlimited
            subscriptionRequest.put("quantity", 1);
            subscriptionRequest.put("customer_notify", 1);

            Subscription subscription = razorpayClient.subscriptions.create(subscriptionRequest);
            subscriptionId = subscription.get("id");
            shortUrl = subscription.get("short_url");
        }

        PostSubscription postSubscription = PostSubscription.builder()
                .userId(userId)
                .postType(postType)
                .razorpayPlanId(planId)
                .razorpaySubscriptionId(subscriptionId)
                .amount(amountRupees)
                .currency(currency)
                .status(PostSubscription.SubscriptionStatus.CREATED)
                .build();

        PostSubscription saved = subscriptionRepository.save(postSubscription);
        log.info("Created subscription: id={}, subscriptionId={}, userId={}, postType={}, amount={}rs",
                saved.getId(), subscriptionId, userId, postType, amountRupees);

        Map<String, Object> result = new HashMap<>();
        result.put("subscriptionDbId", saved.getId());
        result.put("subscriptionId", subscriptionId);
        result.put("planId", planId);
        result.put("amount", amountRupees);
        result.put("amountPaise", amountRupees * 100);
        result.put("currency", currency);
        result.put("keyId", isTestMode() ? "TEST_MODE" : razorpayConfig.getActiveKeyId());
        result.put("testMode", isTestMode());
        if (shortUrl != null) result.put("shortUrl", shortUrl);
        return result;
    }

    /**
     * Called after post is created — links the subscription to the post.
     */
    @Transactional
    public void linkSubscriptionToPost(Long subscriptionDbId, Long postId) {
        subscriptionRepository.findById(subscriptionDbId).ifPresent(sub -> {
            sub.setPostId(postId);
            subscriptionRepository.save(sub);
            log.info("Linked subscription {} to post {}", subscriptionDbId, postId);
        });
    }

    /**
     * Activate subscription after first payment (called from webhook or test mode verify).
     */
    @Transactional
    public void activateSubscription(String razorpaySubscriptionId) {
        subscriptionRepository.findByRazorpaySubscriptionId(razorpaySubscriptionId).ifPresent(sub -> {
            sub.setStatus(PostSubscription.SubscriptionStatus.ACTIVE);
            sub.setStartAt(LocalDateTime.now());
            sub.setCurrentPeriodStart(LocalDateTime.now());
            sub.setCurrentPeriodEnd(LocalDateTime.now().plusMonths(1));
            subscriptionRepository.save(sub);
            log.info("Subscription activated: id={}, razorpayId={}", sub.getId(), razorpaySubscriptionId);
        });
    }

    /**
     * Mark subscription as authenticated (mandate set, first charge pending).
     */
    @Transactional
    public void authenticateSubscription(String razorpaySubscriptionId) {
        subscriptionRepository.findByRazorpaySubscriptionId(razorpaySubscriptionId).ifPresent(sub -> {
            if (sub.getStatus() == PostSubscription.SubscriptionStatus.CREATED) {
                sub.setStatus(PostSubscription.SubscriptionStatus.AUTHENTICATED);
                subscriptionRepository.save(sub);
                log.info("Subscription authenticated: id={}, razorpayId={}", sub.getId(), razorpaySubscriptionId);
            }
        });
    }

    /**
     * Cancel subscription — called when user deletes their post.
     * Cancels immediately at Razorpay and marks as cancelled in DB.
     */
    @Transactional
    public void cancelSubscriptionForPost(Long postId) {
        subscriptionRepository.findByPostId(postId).ifPresent(sub -> {
            if (sub.getStatus() == PostSubscription.SubscriptionStatus.ACTIVE
                    || sub.getStatus() == PostSubscription.SubscriptionStatus.AUTHENTICATED
                    || sub.getStatus() == PostSubscription.SubscriptionStatus.CREATED) {

                if (!isTestMode() && sub.getRazorpaySubscriptionId() != null
                        && !sub.getRazorpaySubscriptionId().startsWith("sub_test_")) {
                    try {
                        JSONObject cancelOptions = new JSONObject();
                        cancelOptions.put("cancel_at_cycle_end", 0); // cancel immediately
                        razorpayClient.subscriptions.cancel(sub.getRazorpaySubscriptionId(), cancelOptions);
                        log.info("Cancelled Razorpay subscription: {}", sub.getRazorpaySubscriptionId());
                    } catch (RazorpayException e) {
                        log.error("Failed to cancel Razorpay subscription {}: {}", sub.getRazorpaySubscriptionId(), e.getMessage());
                    }
                }

                sub.setStatus(PostSubscription.SubscriptionStatus.CANCELLED);
                sub.setCancelledAt(LocalDateTime.now());
                subscriptionRepository.save(sub);
                log.info("Subscription cancelled for post: postId={}, subscriptionId={}", postId, sub.getId());
            }
        });
    }

    /**
     * Handle Razorpay webhook events for subscriptions.
     */
    @Transactional
    public void handleWebhook(String payload, String webhookSignature) {
        // Verify webhook signature
        String webhookSecret = razorpayConfig.getWebhookSecret();
        if (webhookSecret != null && !webhookSecret.isEmpty() && !isTestMode()) {
            try {
                boolean isValid = Utils.verifyWebhookSignature(payload, webhookSignature, webhookSecret);
                if (!isValid) {
                    log.warn("Invalid webhook signature received");
                    return;
                }
            } catch (RazorpayException e) {
                log.error("Webhook signature verification failed: {}", e.getMessage());
                return;
            }
        }

        JSONObject event = new JSONObject(payload);
        String eventType = event.optString("event");
        log.info("Received Razorpay webhook: event={}", eventType);

        JSONObject payloadData = event.optJSONObject("payload");
        if (payloadData == null) return;

        JSONObject subscriptionData = payloadData.optJSONObject("subscription");
        if (subscriptionData == null) return;

        JSONObject subscriptionEntity = subscriptionData.optJSONObject("entity");
        if (subscriptionEntity == null) return;

        String subscriptionId = subscriptionEntity.optString("id");

        switch (eventType) {
            case "subscription.authenticated":
                authenticateSubscription(subscriptionId);
                break;
            case "subscription.charged":
                // Renewal or first charge successful
                activateSubscription(subscriptionId);
                updateSubscriptionPeriod(subscriptionId, subscriptionEntity);
                break;
            case "subscription.halted":
                haltSubscription(subscriptionId);
                break;
            case "subscription.cancelled":
                markCancelled(subscriptionId);
                break;
            case "subscription.completed":
                markCompleted(subscriptionId);
                break;
            default:
                log.debug("Unhandled subscription webhook event: {}", eventType);
        }
    }

    private void updateSubscriptionPeriod(String razorpaySubscriptionId, JSONObject subscriptionEntity) {
        subscriptionRepository.findByRazorpaySubscriptionId(razorpaySubscriptionId).ifPresent(sub -> {
            long currentStart = subscriptionEntity.optLong("current_start", 0);
            long currentEnd = subscriptionEntity.optLong("current_end", 0);
            if (currentStart > 0) {
                sub.setCurrentPeriodStart(LocalDateTime.ofEpochSecond(currentStart, 0,
                        java.time.ZoneOffset.UTC));
            }
            if (currentEnd > 0) {
                sub.setCurrentPeriodEnd(LocalDateTime.ofEpochSecond(currentEnd, 0,
                        java.time.ZoneOffset.UTC));
            }
            subscriptionRepository.save(sub);
        });
    }

    private void haltSubscription(String razorpaySubscriptionId) {
        subscriptionRepository.findByRazorpaySubscriptionId(razorpaySubscriptionId).ifPresent(sub -> {
            sub.setStatus(PostSubscription.SubscriptionStatus.HALTED);
            subscriptionRepository.save(sub);
            log.warn("Subscription halted (payment failed): id={}, razorpayId={}", sub.getId(), razorpaySubscriptionId);
        });
    }

    private void markCancelled(String razorpaySubscriptionId) {
        subscriptionRepository.findByRazorpaySubscriptionId(razorpaySubscriptionId).ifPresent(sub -> {
            sub.setStatus(PostSubscription.SubscriptionStatus.CANCELLED);
            sub.setCancelledAt(LocalDateTime.now());
            subscriptionRepository.save(sub);
        });
    }

    private void markCompleted(String razorpaySubscriptionId) {
        subscriptionRepository.findByRazorpaySubscriptionId(razorpaySubscriptionId).ifPresent(sub -> {
            sub.setStatus(PostSubscription.SubscriptionStatus.COMPLETED);
            subscriptionRepository.save(sub);
        });
    }

    /**
     * Verify subscription after mandate setup (mobile calls this).
     * For test mode, auto-activates.
     */
    @Transactional
    public PostSubscription verifyAndActivate(Long subscriptionDbId, Long userId,
                                               String razorpaySubscriptionId,
                                               String razorpayPaymentId) throws RazorpayException {
        PostSubscription sub = subscriptionRepository.findById(subscriptionDbId)
                .orElseThrow(() -> new RuntimeException("Subscription not found: " + subscriptionDbId));

        if (!sub.getUserId().equals(userId)) {
            throw new RuntimeException("Subscription does not belong to this user");
        }

        if (isTestMode()) {
            sub.setStatus(PostSubscription.SubscriptionStatus.ACTIVE);
            sub.setStartAt(LocalDateTime.now());
            sub.setCurrentPeriodStart(LocalDateTime.now());
            sub.setCurrentPeriodEnd(LocalDateTime.now().plusMonths(1));
            log.info("TEST MODE: Auto-activated subscription: {}", subscriptionDbId);
        } else {
            // Mandate authenticated — mark as authenticated (Razorpay will webhook when charged)
            sub.setStatus(PostSubscription.SubscriptionStatus.AUTHENTICATED);
            log.info("Subscription authenticated: subscriptionDbId={}, razorpayId={}", subscriptionDbId, razorpaySubscriptionId);
        }

        return subscriptionRepository.save(sub);
    }

    /**
     * Check if user has any active subscription (used to bypass post limits).
     */
    public boolean hasActiveSubscription(Long userId) {
        return subscriptionRepository.hasActiveSubscription(userId);
    }

    public List<PostSubscription> getUserSubscriptions(Long userId) {
        return subscriptionRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public Optional<PostSubscription> getSubscriptionForPost(Long postId) {
        return subscriptionRepository.findByPostId(postId);
    }

    @Transactional
    public void cancelSubscriptionById(Long subscriptionDbId) {
        subscriptionRepository.findById(subscriptionDbId).ifPresent(sub -> {
            if (sub.getPostId() != null) {
                cancelSubscriptionForPost(sub.getPostId());
            } else {
                // No postId linked yet — cancel directly
                if (!isTestMode() && sub.getRazorpaySubscriptionId() != null
                        && !sub.getRazorpaySubscriptionId().startsWith("sub_test_")) {
                    try {
                        JSONObject cancelOptions = new JSONObject();
                        cancelOptions.put("cancel_at_cycle_end", 0);
                        razorpayClient.subscriptions.cancel(sub.getRazorpaySubscriptionId(), cancelOptions);
                    } catch (RazorpayException e) {
                        log.error("Failed to cancel Razorpay subscription {}: {}", sub.getRazorpaySubscriptionId(), e.getMessage());
                    }
                }
                sub.setStatus(PostSubscription.SubscriptionStatus.CANCELLED);
                sub.setCancelledAt(LocalDateTime.now());
                subscriptionRepository.save(sub);
            }
        });
    }

    public List<PostSubscription> getAllSubscriptions() {
        return subscriptionRepository.findAll();
    }

    public Map<String, Object> getSubscriptionConfig(String postType) {
        boolean enabled = Boolean.parseBoolean(
                settingService.getSettingValue("subscription.enabled", "true"));
        int price = getSubscriptionPrice(postType);
        return Map.of(
                "enabled", enabled,
                "price", price,
                "currency", "INR",
                "intervalMonths", 1,
                "keyId", isTestMode() ? "TEST_MODE" : razorpayConfig.getActiveKeyId(),
                "testMode", isTestMode()
        );
    }
}
