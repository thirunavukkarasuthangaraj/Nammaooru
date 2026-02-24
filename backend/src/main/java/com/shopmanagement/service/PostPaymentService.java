package com.shopmanagement.service;

import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;
import com.razorpay.Utils;
import com.shopmanagement.entity.PostPayment;
import com.shopmanagement.config.RazorpayConfig;
import com.shopmanagement.repository.PostPaymentRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import lombok.extern.slf4j.Slf4j;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@Slf4j
public class PostPaymentService {

    private final PostPaymentRepository postPaymentRepository;
    private final RazorpayClient razorpayClient;
    private final RazorpayConfig razorpayConfig;
    private final SettingService settingService;
    private final EntityManager entityManager;

    private static final String GLOBAL_COUNT_QUERY =
        "SELECT " +
        "(SELECT COUNT(*) FROM marketplace_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM farmer_products WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM labour_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM travel_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM parcel_service_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM rental_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM real_estate_posts WHERE owner_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED')) + " +
        "(SELECT COUNT(*) FROM womens_corner_posts WHERE seller_user_id = :uid AND status IN ('PENDING_APPROVAL', 'APPROVED'))";

    @Autowired
    public PostPaymentService(PostPaymentRepository postPaymentRepository,
                              @Autowired(required = false) RazorpayClient razorpayClient,
                              RazorpayConfig razorpayConfig,
                              SettingService settingService,
                              EntityManager entityManager) {
        this.postPaymentRepository = postPaymentRepository;
        this.razorpayClient = razorpayClient;
        this.razorpayConfig = razorpayConfig;
        this.settingService = settingService;
        this.entityManager = entityManager;
    }

    private boolean isTestMode() {
        return razorpayConfig.isTestMode();
    }

    private double getProcessingFeePercent() {
        return Double.parseDouble(
                settingService.getSettingValue("paid_post.processing_fee_percent", "2.36"));
    }

    private static final Map<String, String> DURATION_SETTING_KEYS = Map.of(
            "MARKETPLACE", "marketplace.post.duration_days",
            "FARM_PRODUCTS", "farm_products.post.duration_days",
            "LABOURS", "labours.post.duration_days",
            "TRAVELS", "travels.post.duration_days",
            "PARCEL_SERVICE", "parcel_service.post.duration_days",
            "REAL_ESTATE", "real_estate.post.duration_days",
            "RENTAL", "rental.post.duration_days"
    );

    private static final Map<String, String> DURATION_DEFAULTS = Map.of(
            "MARKETPLACE", "30",
            "FARM_PRODUCTS", "60",
            "LABOURS", "60",
            "TRAVELS", "30",
            "PARCEL_SERVICE", "60",
            "REAL_ESTATE", "90",
            "RENTAL", "30"
    );

    public Map<String, Object> getPaymentConfig(String postType) {
        boolean enabled = Boolean.parseBoolean(
                settingService.getSettingValue("paid_post.enabled", "true"));
        String currency = settingService.getSettingValue("paid_post.currency", "INR");

        // Per-type price with global fallback
        String globalDefault = settingService.getSettingValue("paid_post.price", "10");
        int price;
        if (postType != null && !postType.isEmpty()) {
            price = Integer.parseInt(
                    settingService.getSettingValue("paid_post.price." + postType, globalDefault));
        } else {
            price = Integer.parseInt(globalDefault);
        }

        int processingFeePaise = (int) Math.ceil(price * getProcessingFeePercent());
        int totalAmountPaise = (price * 100) + processingFeePaise;

        // Per-type post duration
        int durationDays = 30; // default
        if (postType != null && !postType.isEmpty()) {
            String durationKey = DURATION_SETTING_KEYS.getOrDefault(postType, "marketplace.post.duration_days");
            String durationDefault = DURATION_DEFAULTS.getOrDefault(postType, "30");
            durationDays = Integer.parseInt(settingService.getSettingValue(durationKey, durationDefault));
        }

        // Banner config
        boolean bannerEnabled = Boolean.parseBoolean(
                settingService.getSettingValue("banner.enabled", "true"));
        String bannerGlobalDefault = settingService.getSettingValue("banner.price", "20");
        int bannerPrice;
        if (postType != null && !postType.isEmpty()) {
            bannerPrice = Integer.parseInt(
                    settingService.getSettingValue("banner.price." + postType, bannerGlobalDefault));
        } else {
            bannerPrice = Integer.parseInt(bannerGlobalDefault);
        }

        Map<String, Object> config = new HashMap<>();
        config.put("enabled", enabled);
        config.put("price", price);
        config.put("processingFeePaise", processingFeePaise);
        config.put("totalAmountPaise", totalAmountPaise);
        config.put("currency", currency);
        config.put("razorpayKeyId", isTestMode() ? "TEST_MODE" : razorpayConfig.getActiveKeyId());
        config.put("testMode", isTestMode());
        config.put("durationDays", durationDays);
        config.put("bannerEnabled", bannerEnabled);
        config.put("bannerPrice", bannerPrice);
        return config;
    }

    @Transactional
    public Map<String, Object> createOrder(Long userId, String postType) throws RazorpayException {
        return createOrder(userId, postType, false);
    }

    @Transactional
    public Map<String, Object> createOrder(Long userId, String postType, boolean includeBanner) throws RazorpayException {
        String globalDefault = settingService.getSettingValue("paid_post.price", "10");
        int postPriceRupees = Integer.parseInt(
                settingService.getSettingValue("paid_post.price." + postType, globalDefault));
        String currency = settingService.getSettingValue("paid_post.currency", "INR");

        // Check if free limit is reached - if not, post fee is 0
        boolean limitReached = isLimitReached(userId);
        int postFee = limitReached ? postPriceRupees : 0;

        // Banner fee
        int bannerFee = 0;
        if (includeBanner) {
            String bannerGlobalDefault = settingService.getSettingValue("banner.price", "20");
            bannerFee = Integer.parseInt(
                    settingService.getSettingValue("banner.price." + postType, bannerGlobalDefault));
        }

        int baseAmount = postFee + bannerFee;
        int processingFeePaise = (int) Math.ceil(baseAmount * getProcessingFeePercent());
        int totalAmountPaise = (baseAmount * 100) + processingFeePaise;

        String orderId;
        if (isTestMode()) {
            orderId = "test_order_" + userId + "_" + System.currentTimeMillis();
            log.info("TEST MODE: Created mock order: {}", orderId);
        } else {
            JSONObject orderRequest = new JSONObject();
            orderRequest.put("amount", totalAmountPaise);
            orderRequest.put("currency", currency);
            orderRequest.put("receipt", "post_" + userId + "_" + System.currentTimeMillis());

            Order razorpayOrder = razorpayClient.orders.create(orderRequest);
            orderId = razorpayOrder.get("id");
        }

        PostPayment payment = PostPayment.builder()
                .userId(userId)
                .razorpayOrderId(orderId)
                .amount(postFee)
                .bannerAmount(bannerFee)
                .includesBanner(includeBanner)
                .processingFee(processingFeePaise)
                .totalAmount(totalAmountPaise)
                .currency(currency)
                .postType(postType)
                .build();

        postPaymentRepository.save(payment);
        log.info("Created order: orderId={}, userId={}, postType={}, postFee={}, bannerFee={}, fee={}p, total={}p, testMode={}",
                orderId, userId, postType, postFee, bannerFee, processingFeePaise, totalAmountPaise, isTestMode());

        Map<String, Object> result = new HashMap<>();
        result.put("orderId", orderId);
        result.put("amount", totalAmountPaise);
        result.put("basePrice", postFee);
        result.put("bannerFee", bannerFee);
        result.put("includeBanner", includeBanner);
        result.put("processingFeePaise", processingFeePaise);
        result.put("currency", currency);
        result.put("keyId", isTestMode() ? "TEST_MODE" : razorpayConfig.getActiveKeyId());
        result.put("testMode", isTestMode());
        return result;
    }

    @Transactional
    public PostPayment verifyPayment(String razorpayOrderId, String razorpayPaymentId,
                                      String razorpaySignature) throws RazorpayException {
        PostPayment payment = postPaymentRepository.findByRazorpayOrderId(razorpayOrderId)
                .orElseThrow(() -> new RuntimeException("Payment order not found: " + razorpayOrderId));

        if (payment.getStatus() == PostPayment.PaymentStatus.PAID) {
            return payment;
        }

        if (isTestMode()) {
            // Test mode: skip signature verification, auto-approve
            log.info("TEST MODE: Auto-verifying payment for order: {}", razorpayOrderId);
        } else {
            // Verify signature with Razorpay
            JSONObject attributes = new JSONObject();
            attributes.put("razorpay_order_id", razorpayOrderId);
            attributes.put("razorpay_payment_id", razorpayPaymentId);
            attributes.put("razorpay_signature", razorpaySignature);

            boolean isValid = Utils.verifyPaymentSignature(attributes, razorpayConfig.getActiveKeySecret());
            if (!isValid) {
                payment.setStatus(PostPayment.PaymentStatus.FAILED);
                postPaymentRepository.save(payment);
                throw new RuntimeException("Payment signature verification failed");
            }
        }

        payment.setRazorpayPaymentId(razorpayPaymentId != null ? razorpayPaymentId : "test_pay_" + System.currentTimeMillis());
        payment.setRazorpaySignature(razorpaySignature != null ? razorpaySignature : "test_sig");
        payment.setStatus(PostPayment.PaymentStatus.PAID);
        payment.setPaidAt(LocalDateTime.now());

        PostPayment saved = postPaymentRepository.save(payment);
        log.info("Payment verified: orderId={}, paymentId={}, userId={}, testMode={}",
                razorpayOrderId, payment.getRazorpayPaymentId(), payment.getUserId(), isTestMode());
        return saved;
    }

    @Transactional
    public Map<String, Object> createBulkOrder(Long userId, String postType, int count) throws RazorpayException {
        if (count < 1 || count > 50) {
            throw new RuntimeException("Count must be between 1 and 50");
        }

        String globalDefault = settingService.getSettingValue("paid_post.price", "10");
        int pricePerPost = Integer.parseInt(
                settingService.getSettingValue("paid_post.price." + postType, globalDefault));
        String currency = settingService.getSettingValue("paid_post.currency", "INR");

        int totalBaseAmount = pricePerPost * count;
        int processingFeePaise = (int) Math.ceil(totalBaseAmount * getProcessingFeePercent());
        int totalAmountPaise = (totalBaseAmount * 100) + processingFeePaise;

        String orderId;
        if (isTestMode()) {
            orderId = "test_bulk_" + userId + "_" + System.currentTimeMillis();
            log.info("TEST MODE: Created mock bulk order: {}, count: {}", orderId, count);
        } else {
            JSONObject orderRequest = new JSONObject();
            orderRequest.put("amount", totalAmountPaise);
            orderRequest.put("currency", currency);
            orderRequest.put("receipt", "bulk_" + userId + "_" + System.currentTimeMillis());

            Order razorpayOrder = razorpayClient.orders.create(orderRequest);
            orderId = razorpayOrder.get("id");
        }

        // Create N PostPayment records sharing the same Razorpay orderId
        List<Long> tokenIds = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            PostPayment payment = PostPayment.builder()
                    .userId(userId)
                    .razorpayOrderId(orderId)
                    .amount(pricePerPost)
                    .processingFee((int) Math.ceil(pricePerPost * getProcessingFeePercent()))
                    .totalAmount((pricePerPost * 100) + (int) Math.ceil(pricePerPost * getProcessingFeePercent()))
                    .currency(currency)
                    .postType(postType)
                    .build();
            PostPayment saved = postPaymentRepository.save(payment);
            tokenIds.add(saved.getId());
        }

        log.info("Created bulk order: orderId={}, userId={}, postType={}, count={}, total={}p",
                orderId, userId, postType, count, totalAmountPaise);

        Map<String, Object> result = new HashMap<>();
        result.put("orderId", orderId);
        result.put("amount", totalAmountPaise);
        result.put("basePrice", totalBaseAmount);
        result.put("pricePerPost", pricePerPost);
        result.put("count", count);
        result.put("processingFeePaise", processingFeePaise);
        result.put("currency", currency);
        result.put("keyId", isTestMode() ? "TEST_MODE" : razorpayConfig.getActiveKeyId());
        result.put("testMode", isTestMode());
        result.put("tokenIds", tokenIds);
        return result;
    }

    @Transactional
    public List<Long> verifyBulkPayment(String razorpayOrderId, String razorpayPaymentId,
                                         String razorpaySignature) throws RazorpayException {
        List<PostPayment> payments = postPaymentRepository.findAllByRazorpayOrderId(razorpayOrderId);
        if (payments.isEmpty()) {
            throw new RuntimeException("Payment order not found: " + razorpayOrderId);
        }

        // Check if already verified
        if (payments.stream().allMatch(p -> p.getStatus() == PostPayment.PaymentStatus.PAID)) {
            return payments.stream().map(PostPayment::getId).toList();
        }

        if (isTestMode()) {
            log.info("TEST MODE: Auto-verifying bulk payment for order: {}", razorpayOrderId);
        } else {
            JSONObject attributes = new JSONObject();
            attributes.put("razorpay_order_id", razorpayOrderId);
            attributes.put("razorpay_payment_id", razorpayPaymentId);
            attributes.put("razorpay_signature", razorpaySignature);

            boolean isValid = Utils.verifyPaymentSignature(attributes, razorpayConfig.getActiveKeySecret());
            if (!isValid) {
                payments.forEach(p -> p.setStatus(PostPayment.PaymentStatus.FAILED));
                postPaymentRepository.saveAll(payments);
                throw new RuntimeException("Payment signature verification failed");
            }
        }

        List<Long> tokenIds = new ArrayList<>();
        for (PostPayment payment : payments) {
            payment.setRazorpayPaymentId(razorpayPaymentId != null ? razorpayPaymentId : "test_pay_" + System.currentTimeMillis());
            payment.setRazorpaySignature(razorpaySignature != null ? razorpaySignature : "test_sig");
            payment.setStatus(PostPayment.PaymentStatus.PAID);
            payment.setPaidAt(LocalDateTime.now());
            postPaymentRepository.save(payment);
            tokenIds.add(payment.getId());
        }

        log.info("Bulk payment verified: orderId={}, count={}, testMode={}",
                razorpayOrderId, tokenIds.size(), isTestMode());
        return tokenIds;
    }

    @Transactional
    public boolean consumeToken(Long tokenId, Long userId, Long postId) {
        PostPayment payment = postPaymentRepository.findById(tokenId).orElse(null);
        if (payment == null) return false;
        if (!payment.getUserId().equals(userId)) return false;
        if (payment.getStatus() != PostPayment.PaymentStatus.PAID) return false;
        if (payment.getConsumed()) return false;

        payment.setConsumed(true);
        payment.setConsumedPostId(postId);
        payment.setConsumedAt(LocalDateTime.now());
        postPaymentRepository.save(payment);
        log.info("Payment token consumed: tokenId={}, userId={}, postId={}", tokenId, userId, postId);
        return true;
    }

    public boolean isLimitReached(Long userId) {
        int freePostLimit = Integer.parseInt(
                settingService.getSettingValue("global.free_post_limit", "1"));
        if (freePostLimit < 0) return false; // unlimited
        if (freePostLimit == 0) return true;  // no free posts
        Query query = entityManager.createNativeQuery(GLOBAL_COUNT_QUERY);
        query.setParameter("uid", userId);
        long totalActiveCount = ((Number) query.getSingleResult()).longValue();
        return totalActiveCount >= freePostLimit;
    }

    public boolean hasValidToken(Long tokenId, Long userId) {
        PostPayment payment = postPaymentRepository.findById(tokenId).orElse(null);
        if (payment == null) return false;
        return payment.getUserId().equals(userId)
                && payment.getStatus() == PostPayment.PaymentStatus.PAID
                && !payment.getConsumed();
    }

    @Transactional(readOnly = true)
    public Page<PostPayment> getAllPayments(Pageable pageable) {
        return postPaymentRepository.findAllByOrderByCreatedAtDesc(pageable);
    }

    @Transactional(readOnly = true)
    public Page<PostPayment> getMyPayments(Long userId, Pageable pageable) {
        return postPaymentRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getPaymentStats() {
        long totalPaid = postPaymentRepository.countByStatus(PostPayment.PaymentStatus.PAID);
        long totalFailed = postPaymentRepository.countByStatus(PostPayment.PaymentStatus.FAILED);
        long totalCreated = postPaymentRepository.countByStatus(PostPayment.PaymentStatus.CREATED);
        // totalAmount and processingFee are stored in paise, amount in rupees
        long totalCollectedPaise = postPaymentRepository.sumTotalAmountByStatusPaid();
        long baseAmountRupees = postPaymentRepository.sumAmountByStatusPaid();
        long processingFeePaise = postPaymentRepository.sumProcessingFeeByStatusPaid();

        // Convert to rupees for display
        double totalCollected = totalCollectedPaise / 100.0;
        double processingFeeCollected = processingFeePaise / 100.0;

        // Razorpay fee breakdown: 2% base fee + 18% GST on fee
        double razorpayBaseFee = totalCollected * 2.0 / 100.0;
        double gstOnFee = razorpayBaseFee * 18.0 / 100.0;
        double totalRazorpayFee = razorpayBaseFee + gstOnFee;
        double netAmount = totalCollected - totalRazorpayFee;

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalPayments", totalPaid + totalFailed + totalCreated);
        stats.put("successfulPayments", totalPaid);
        stats.put("failedPayments", totalFailed);
        stats.put("pendingPayments", totalCreated);
        stats.put("totalCollected", Math.round(totalCollected * 100.0) / 100.0);
        stats.put("baseAmountCollected", baseAmountRupees);
        stats.put("processingFeeCollected", Math.round(processingFeeCollected * 100.0) / 100.0);
        stats.put("razorpayFee", Math.round(totalRazorpayFee * 100.0) / 100.0);
        stats.put("gstOnFee", Math.round(gstOnFee * 100.0) / 100.0);
        stats.put("netAmount", Math.round(netAmount * 100.0) / 100.0);

        // Breakdown by post type (totalAmount is in paise, convert to rupees)
        List<Object[]> byPostType = postPaymentRepository.getStatsByPostType();
        List<Map<String, Object>> postTypeStats = new ArrayList<>();
        for (Object[] row : byPostType) {
            Map<String, Object> pt = new HashMap<>();
            pt.put("postType", row[0]);
            pt.put("count", row[1]);
            long amountPaise = ((Number) row[2]).longValue();
            pt.put("amount", Math.round(amountPaise / 100.0 * 100.0) / 100.0);
            postTypeStats.add(pt);
        }
        stats.put("byPostType", postTypeStats);

        return stats;
    }
}
