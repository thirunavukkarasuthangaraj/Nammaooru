package com.shopmanagement.service;

import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;
import com.razorpay.Refund;
import com.razorpay.Utils;
import com.shopmanagement.config.RazorpayConfig;
import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderPayment;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.OrderPaymentRepository;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Map;

/**
 * Razorpay integration for customer order payments — separate from ShopPaymentCollectService
 * (SaaS billing) and PostPaymentService (classifieds), which use the same RazorpayClient bean
 * but for unrelated money flows.
 *
 * Business rule (explicit from product owner): the customer pays Razorpay's gateway fee on
 * top of the order total, and on cancellation the fee is NOT refunded — only the order amount
 * itself comes back. Neither the shop nor the platform absorbs the gateway cost either way.
 */
@Service
@Slf4j
public class OrderPaymentService {

    private final OrderRepository orderRepository;
    private final OrderPaymentRepository orderPaymentRepository;
    private final UserRepository userRepository;
    private final RazorpayClient razorpayClient;
    private final RazorpayConfig razorpayConfig;
    private final SettingService settingService;

    // Razorpay's actual merchant discount rate (MDR) depends on your negotiated agreement
    // and payment method (UPI/card/netbanking differ) — this default is a placeholder and
    // MUST be corrected via the settings key below to match your real Razorpay MDR, or the
    // platform will over- or under-charge customers relative to what Razorpay actually deducts.
    private static final String GATEWAY_FEE_PERCENT_KEY = "order_payment.gateway_fee_percent";
    private static final String DEFAULT_GATEWAY_FEE_PERCENT = "2.36"; // 2% MDR + 18% GST on that fee, typical card/UPI rate

    public OrderPaymentService(OrderRepository orderRepository,
                                OrderPaymentRepository orderPaymentRepository,
                                UserRepository userRepository,
                                @Autowired(required = false) RazorpayClient razorpayClient,
                                RazorpayConfig razorpayConfig,
                                SettingService settingService) {
        this.orderRepository = orderRepository;
        this.orderPaymentRepository = orderPaymentRepository;
        this.userRepository = userRepository;
        this.razorpayClient = razorpayClient;
        this.razorpayConfig = razorpayConfig;
        this.settingService = settingService;
    }

    /**
     * Must run inside an active transaction — order.getCustomer() is a lazy @ManyToOne.
     * Touching it from a non-transactional context (e.g. a plain controller method that
     * does its own orderRepository.findById() first) throws LazyInitializationException
     * ("could not initialize proxy ... no Session") the moment a field on it is read,
     * because Spring Data's per-call transaction for that findById already closed by then.
     */
    private void verifyOwnership(Order order, Authentication authentication) {
        User user = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));

        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_SUPER_ADMIN"));
        if (isAdmin) return;

        boolean owns = order.getCustomer() != null && (
                (order.getCustomer().getMobileNumber() != null && order.getCustomer().getMobileNumber().equals(user.getMobileNumber()))
                || (order.getCustomer().getEmail() != null && order.getCustomer().getEmail().equalsIgnoreCase(user.getEmail())));
        if (!owns) {
            throw new RuntimeException("This order does not belong to you");
        }
    }

    private boolean isTestMode() {
        return razorpayConfig.isTestMode();
    }

    public BigDecimal getGatewayFeePercent() {
        return new BigDecimal(settingService.getSettingValue(GATEWAY_FEE_PERCENT_KEY, DEFAULT_GATEWAY_FEE_PERCENT));
    }

    @Transactional
    public void setGatewayFeePercent(BigDecimal percent) {
        if (percent == null || percent.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Gateway fee percent cannot be negative");
        }
        settingService.saveSetting(GATEWAY_FEE_PERCENT_KEY, percent.toPlainString(),
                "Percent added to the order total and charged to the customer to cover Razorpay's fee. "
                + "Set this to match your actual Razorpay MDR — check your Razorpay dashboard/agreement.");
    }

    @Transactional
    public Map<String, Object> createOrder(Long orderId, Authentication authentication) throws RazorpayException {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));
        verifyOwnership(order, authentication);

        orderPaymentRepository.findByOrder_Id(orderId).ifPresent(existing -> {
            if (existing.getStatus() == OrderPayment.OrderPaymentStatus.PAID) {
                throw new RuntimeException("Order is already paid");
            }
        });

        BigDecimal orderAmount = order.getTotalAmount();
        BigDecimal feePercent = getGatewayFeePercent();
        BigDecimal gatewayFee = orderAmount.multiply(feePercent)
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        BigDecimal totalCharged = orderAmount.add(gatewayFee);
        long totalPaise = totalCharged.multiply(BigDecimal.valueOf(100)).setScale(0, RoundingMode.HALF_UP).longValue();

        String razorpayOrderId;
        if (isTestMode() || razorpayClient == null) {
            razorpayOrderId = "test_order_" + orderId + "_" + System.currentTimeMillis();
            log.info("TEST MODE: Created mock order-payment order: {}", razorpayOrderId);
        } else {
            JSONObject orderRequest = new JSONObject();
            orderRequest.put("amount", totalPaise);
            orderRequest.put("currency", "INR");
            orderRequest.put("receipt", "order_" + orderId + "_" + System.currentTimeMillis());
            com.razorpay.Order razorpayOrder = razorpayClient.orders.create(orderRequest);
            razorpayOrderId = razorpayOrder.get("id");
        }

        OrderPayment payment = OrderPayment.builder()
                .order(order)
                .razorpayOrderId(razorpayOrderId)
                .orderAmount(orderAmount)
                .gatewayFeeAmount(gatewayFee)
                .totalChargedAmount(totalCharged)
                .status(OrderPayment.OrderPaymentStatus.CREATED)
                .build();
        orderPaymentRepository.save(payment);

        log.info("Created order-payment: orderId={}, orderAmount={}, gatewayFee={}, totalCharged={}, testMode={}",
                orderId, orderAmount, gatewayFee, totalCharged, isTestMode());

        return Map.of(
                "orderId", orderId,
                "razorpayOrderId", razorpayOrderId,
                "amountPaise", totalPaise,
                "orderAmount", orderAmount,
                "gatewayFeeAmount", gatewayFee,
                "totalChargedAmount", totalCharged,
                "currency", "INR",
                "keyId", isTestMode() ? "TEST_MODE" : razorpayConfig.getActiveKeyId(),
                "testMode", isTestMode()
        );
    }

    @Transactional
    public OrderPayment verifyPayment(String razorpayOrderId, String razorpayPaymentId, String razorpaySignature,
                                       Authentication authentication) throws RazorpayException {
        OrderPayment payment = orderPaymentRepository.findByRazorpayOrderId(razorpayOrderId)
                .orElseThrow(() -> new RuntimeException("Payment order not found: " + razorpayOrderId));
        verifyOwnership(payment.getOrder(), authentication);

        if (payment.getStatus() == OrderPayment.OrderPaymentStatus.PAID) {
            return payment; // idempotent — already confirmed, possibly by the webhook
        }

        if (isTestMode() || razorpayClient == null) {
            log.info("TEST MODE: Auto-verifying order payment for {}", razorpayOrderId);
        } else {
            JSONObject attributes = new JSONObject();
            attributes.put("razorpay_order_id", razorpayOrderId);
            attributes.put("razorpay_payment_id", razorpayPaymentId);
            attributes.put("razorpay_signature", razorpaySignature);
            boolean valid = Utils.verifyPaymentSignature(attributes, razorpayConfig.getActiveKeySecret());
            if (!valid) {
                payment.setStatus(OrderPayment.OrderPaymentStatus.FAILED);
                payment.setFailureReason("Signature verification failed");
                orderPaymentRepository.save(payment);
                throw new RuntimeException("Payment signature verification failed");
            }
        }

        markPaid(payment, razorpayPaymentId, razorpaySignature);
        return payment;
    }

    /** Shared by verifyPayment (client callback) and the webhook handler — either path can win the race. */
    private void markPaid(OrderPayment payment, String razorpayPaymentId, String razorpaySignature) {
        payment.setRazorpayPaymentId(razorpayPaymentId != null ? razorpayPaymentId : "test_pay_" + System.currentTimeMillis());
        payment.setRazorpaySignature(razorpaySignature);
        payment.setStatus(OrderPayment.OrderPaymentStatus.PAID);
        orderPaymentRepository.save(payment);

        Order order = payment.getOrder();
        order.setPaymentStatus(Order.PaymentStatus.PAID);
        orderRepository.save(order);
        log.info("Order payment confirmed: orderId={}, razorpayOrderId={}, razorpayPaymentId={}",
                order.getId(), payment.getRazorpayOrderId(), payment.getRazorpayPaymentId());
    }

    /**
     * Refund on cancellation. Per business rule, the gateway fee is NOT refunded — only the
     * order amount. Razorpay itself also never returns its own fee on a refund regardless,
     * so this is consistent with what Razorpay would do to the platform's settlement anyway.
     */
    @Transactional
    public OrderPayment refundForCancellation(Long orderId) {
        OrderPayment payment = orderPaymentRepository.findByOrder_Id(orderId)
                .orElse(null);
        if (payment == null || payment.getStatus() != OrderPayment.OrderPaymentStatus.PAID) {
            log.info("No paid online payment to refund for order {} (payment={})", orderId,
                    payment == null ? "none" : payment.getStatus());
            return payment;
        }

        BigDecimal refundAmount = payment.getOrderAmount();
        long refundPaise = refundAmount.multiply(BigDecimal.valueOf(100)).setScale(0, RoundingMode.HALF_UP).longValue();

        String refundId;
        if (isTestMode() || razorpayClient == null) {
            refundId = "test_refund_" + orderId + "_" + System.currentTimeMillis();
            log.info("TEST MODE: Mock refund for order {}: {}", orderId, refundId);
        } else {
            try {
                JSONObject refundRequest = new JSONObject();
                refundRequest.put("amount", refundPaise);
                refundRequest.put("speed", "normal");
                JSONObject notes = new JSONObject();
                notes.put("orderId", String.valueOf(orderId));
                notes.put("reason", "order_cancelled");
                refundRequest.put("notes", notes);
                Refund refund = razorpayClient.payments.refund(payment.getRazorpayPaymentId(), refundRequest);
                refundId = refund.get("id");
            } catch (RazorpayException e) {
                log.error("Razorpay refund failed for order {}: {}", orderId, e.getMessage(), e);
                throw new RuntimeException("Refund failed: " + e.getMessage(), e);
            }
        }

        payment.setRazorpayRefundId(refundId);
        payment.setRefundAmount(refundAmount);
        payment.setRefundFeeAmount(payment.getGatewayFeeAmount()); // kept by the gateway, not returned
        payment.setStatus(OrderPayment.OrderPaymentStatus.REFUNDED);
        orderPaymentRepository.save(payment);

        log.info("Refunded order {}: amount={}, gatewayFeeKept={}, razorpayRefundId={}",
                orderId, refundAmount, payment.getGatewayFeeAmount(), refundId);
        return payment;
    }

    /**
     * Webhook is the reliability backstop — if the customer's app loses connectivity right
     * after Razorpay Checkout succeeds, the client-side verifyPayment call may never reach
     * the server, leaving the order stuck as unpaid even though money was actually captured.
     * The webhook independently confirms payment.captured events server-to-server.
     */
    @Transactional
    public void handleWebhook(String payload, String signature) {
        if (razorpayConfig.getWebhookSecret() == null || razorpayConfig.getWebhookSecret().isEmpty()) {
            log.warn("Webhook received but no webhook secret configured — ignoring for safety");
            return;
        }
        try {
            boolean valid = Utils.verifyWebhookSignature(payload, signature, razorpayConfig.getWebhookSecret());
            if (!valid) {
                log.warn("Webhook signature verification failed — ignoring");
                return;
            }
        } catch (RazorpayException e) {
            log.error("Webhook signature verification error: {}", e.getMessage());
            return;
        }

        JSONObject event = new JSONObject(payload);
        String eventType = event.optString("event", "");
        log.info("Razorpay webhook received: {}", eventType);

        if ("payment.captured".equals(eventType)) {
            JSONObject paymentEntity = event.getJSONObject("payload").getJSONObject("payment").getJSONObject("entity");
            String razorpayOrderId = paymentEntity.optString("order_id", null);
            String razorpayPaymentId = paymentEntity.optString("id", null);
            if (razorpayOrderId == null) return;
            orderPaymentRepository.findByRazorpayOrderId(razorpayOrderId).ifPresent(payment -> {
                if (payment.getStatus() != OrderPayment.OrderPaymentStatus.PAID) {
                    markPaid(payment, razorpayPaymentId, null);
                    log.info("Order payment confirmed via webhook: razorpayOrderId={}", razorpayOrderId);
                }
            });
        } else if ("payment.failed".equals(eventType)) {
            JSONObject paymentEntity = event.getJSONObject("payload").getJSONObject("payment").getJSONObject("entity");
            String razorpayOrderId = paymentEntity.optString("order_id", null);
            String reason = paymentEntity.optString("error_description", "Payment failed");
            if (razorpayOrderId == null) return;
            orderPaymentRepository.findByRazorpayOrderId(razorpayOrderId).ifPresent(payment -> {
                if (payment.getStatus() == OrderPayment.OrderPaymentStatus.CREATED) {
                    payment.setStatus(OrderPayment.OrderPaymentStatus.FAILED);
                    payment.setFailureReason(reason);
                    orderPaymentRepository.save(payment);
                    log.info("Order payment marked FAILED via webhook: razorpayOrderId={}, reason={}", razorpayOrderId, reason);
                }
            });
        }
    }

    @Transactional(readOnly = true)
    public Page<OrderPayment> listAll(Pageable pageable) {
        return orderPaymentRepository.findAllByOrderByCreatedAtDesc(pageable);
    }
}
