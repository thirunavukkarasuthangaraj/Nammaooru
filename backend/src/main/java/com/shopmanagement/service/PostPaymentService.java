package com.shopmanagement.service;

import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;
import com.razorpay.Utils;
import com.shopmanagement.entity.PostPayment;
import com.shopmanagement.repository.PostPaymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Value;
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
@RequiredArgsConstructor
@Slf4j
public class PostPaymentService {

    private final PostPaymentRepository postPaymentRepository;
    private final RazorpayClient razorpayClient;
    private final SettingService settingService;

    @Value("${razorpay.key-id:}")
    private String razorpayKeyId;

    @Value("${razorpay.key-secret:}")
    private String razorpayKeySecret;

    private boolean isTestMode() {
        return razorpayKeyId == null || razorpayKeyId.isEmpty() || razorpayClient == null;
    }

    public Map<String, Object> getPaymentConfig() {
        boolean enabled = Boolean.parseBoolean(
                settingService.getSettingValue("paid_post.enabled", "true"));
        int price = Integer.parseInt(
                settingService.getSettingValue("paid_post.price", "10"));
        String currency = settingService.getSettingValue("paid_post.currency", "INR");

        Map<String, Object> config = new HashMap<>();
        config.put("enabled", enabled);
        config.put("price", price);
        config.put("currency", currency);
        config.put("razorpayKeyId", isTestMode() ? "TEST_MODE" : razorpayKeyId);
        config.put("testMode", isTestMode());
        return config;
    }

    @Transactional
    public Map<String, Object> createOrder(Long userId, String postType) throws RazorpayException {
        int priceInRupees = Integer.parseInt(
                settingService.getSettingValue("paid_post.price", "10"));
        int amountInPaise = priceInRupees * 100;
        String currency = settingService.getSettingValue("paid_post.currency", "INR");

        String orderId;
        if (isTestMode()) {
            // Test mode: generate fake order ID
            orderId = "test_order_" + userId + "_" + System.currentTimeMillis();
            log.info("TEST MODE: Created mock order: {}", orderId);
        } else {
            JSONObject orderRequest = new JSONObject();
            orderRequest.put("amount", amountInPaise);
            orderRequest.put("currency", currency);
            orderRequest.put("receipt", "post_" + userId + "_" + System.currentTimeMillis());

            Order razorpayOrder = razorpayClient.orders.create(orderRequest);
            orderId = razorpayOrder.get("id");
        }

        PostPayment payment = PostPayment.builder()
                .userId(userId)
                .razorpayOrderId(orderId)
                .amount(priceInRupees)
                .currency(currency)
                .postType(postType)
                .build();

        postPaymentRepository.save(payment);
        log.info("Created order: orderId={}, userId={}, postType={}, amount={}, testMode={}",
                orderId, userId, postType, priceInRupees, isTestMode());

        Map<String, Object> result = new HashMap<>();
        result.put("orderId", orderId);
        result.put("amount", amountInPaise);
        result.put("currency", currency);
        result.put("keyId", isTestMode() ? "TEST_MODE" : razorpayKeyId);
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

            boolean isValid = Utils.verifyPaymentSignature(attributes, razorpayKeySecret);
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
        long totalCollected = postPaymentRepository.sumAmountByStatusPaid();
        long totalConsumed = postPaymentRepository.sumAmountByStatusPaidAndConsumed();

        // Razorpay fee: ~2% + GST (18% on fee) = ~2.36% total
        double razorpayFeePercent = 2.36;
        long razorpayFee = Math.round(totalCollected * razorpayFeePercent / 100.0);
        long netAmount = totalCollected - razorpayFee;

        // GST on Razorpay fee (18% of the 2% base fee)
        long baseFee = Math.round(totalCollected * 2.0 / 100.0);
        long gstOnFee = Math.round(baseFee * 18.0 / 100.0);

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalPayments", totalPaid + totalFailed + totalCreated);
        stats.put("successfulPayments", totalPaid);
        stats.put("failedPayments", totalFailed);
        stats.put("pendingPayments", totalCreated);
        stats.put("totalCollected", totalCollected);
        stats.put("totalConsumed", totalConsumed);
        stats.put("razorpayFee", razorpayFee);
        stats.put("gstOnFee", gstOnFee);
        stats.put("netAmount", netAmount);

        // Breakdown by post type
        List<Object[]> byPostType = postPaymentRepository.getStatsByPostType();
        List<Map<String, Object>> postTypeStats = new ArrayList<>();
        for (Object[] row : byPostType) {
            Map<String, Object> pt = new HashMap<>();
            pt.put("postType", row[0]);
            pt.put("count", row[1]);
            pt.put("amount", row[2]);
            postTypeStats.add(pt);
        }
        stats.put("byPostType", postTypeStats);

        return stats;
    }
}
