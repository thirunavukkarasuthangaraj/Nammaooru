package com.shopmanagement.service;

import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;
import com.razorpay.Utils;
import com.shopmanagement.config.RazorpayConfig;
import com.shopmanagement.entity.ShopPaymentCollection;
import com.shopmanagement.entity.ShopPaymentPrice;
import com.shopmanagement.repository.ShopPaymentCollectionRepository;
import com.shopmanagement.repository.ShopPaymentPriceRepository;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.repository.ShopRepository;
import lombok.extern.slf4j.Slf4j;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@Slf4j
public class ShopPaymentCollectService {

    private final ShopRepository shopRepository;
    private final ShopPaymentPriceRepository shopPaymentPriceRepository;
    private final ShopPaymentCollectionRepository shopPaymentCollectionRepository;
    private final RazorpayClient razorpayClient;
    private final RazorpayConfig razorpayConfig;
    private final SettingService settingService;

    private static final String DURATION_SETTING_KEY = "shop_payment_collect.duration_days";

    @Autowired
    public ShopPaymentCollectService(ShopRepository shopRepository,
                                      ShopPaymentPriceRepository shopPaymentPriceRepository,
                                      ShopPaymentCollectionRepository shopPaymentCollectionRepository,
                                      @Autowired(required = false) RazorpayClient razorpayClient,
                                      RazorpayConfig razorpayConfig,
                                      SettingService settingService) {
        this.shopRepository = shopRepository;
        this.shopPaymentPriceRepository = shopPaymentPriceRepository;
        this.shopPaymentCollectionRepository = shopPaymentCollectionRepository;
        this.razorpayClient = razorpayClient;
        this.razorpayConfig = razorpayConfig;
        this.settingService = settingService;
    }

    private boolean isTestMode() {
        return razorpayConfig.isTestMode();
    }

    public int getDurationDays() {
        return Integer.parseInt(settingService.getSettingValue(DURATION_SETTING_KEY, "30"));
    }

    @Transactional
    public void setDurationDays(int days) {
        if (days < 1) {
            throw new RuntimeException("Duration must be at least 1 day");
        }
        settingService.saveSetting(DURATION_SETTING_KEY, String.valueOf(days), "Days of access granted per pay-and-use payment");

        // Re-anchor free windows (never-paid shops) to join date + the new duration so a
        // shorter duration takes effect immediately. Real paid periods keep what was bought.
        List<ShopPaymentCollection> freeWindows = shopPaymentCollectionRepository
                .findByStatusAndRazorpayOrderIdStartingWith(ShopPaymentCollection.CollectionStatus.PAID, "grace_");
        for (ShopPaymentCollection window : freeWindows) {
            shopRepository.findById(window.getShopId()).ifPresent(shop -> {
                LocalDateTime joined = shop.getCreatedAt() != null ? shop.getCreatedAt() : window.getCreatedAt();
                window.setValidUntil(joined.plusDays(days));
                shopPaymentCollectionRepository.save(window);
            });
        }
        recomputeAllBlockedFlags();
    }

    @Transactional(readOnly = true)
    public boolean isCurrentlyPaid(Long shopId) {
        ShopPaymentPrice price = shopPaymentPriceRepository.findByShopId(shopId).orElse(null);
        if (price == null || price.getAmount() == null || price.getAmount() <= 0) {
            return true; // no price set -> not required to pay
        }
        return shopPaymentCollectionRepository.existsByShopIdAndStatusAndValidUntilGreaterThanEqual(
                shopId, ShopPaymentCollection.CollectionStatus.PAID, LocalDateTime.now());
    }

    @Transactional
    public void recomputeBlockedFlag(Long shopId) {
        Shop shop = shopRepository.findById(shopId).orElse(null);
        if (shop == null) return;
        boolean shouldBeBlocked = !isCurrentlyPaid(shopId);
        if (shouldBeBlocked != Boolean.TRUE.equals(shop.getPaymentBlocked())) {
            shop.setPaymentBlocked(shouldBeBlocked);
            shopRepository.save(shop);
        }
    }

    /** Runs daily at 00:05 so shops whose paid period expired get locked/hidden automatically. */
    @Scheduled(cron = "0 5 0 * * *")
    @Transactional
    public void recomputeAllBlockedFlags() {
        List<ShopPaymentPrice> prices = shopPaymentPriceRepository.findAll();
        int changed = 0;
        for (ShopPaymentPrice price : prices) {
            if (price.getAmount() == null || price.getAmount() <= 0) continue;
            Shop shop = shopRepository.findById(price.getShopId()).orElse(null);
            if (shop == null) continue;
            boolean shouldBeBlocked = !isCurrentlyPaid(shop.getId());
            if (shouldBeBlocked != Boolean.TRUE.equals(shop.getPaymentBlocked())) {
                shop.setPaymentBlocked(shouldBeBlocked);
                shopRepository.save(shop);
                changed++;
            }
        }
        log.info("Daily pay-and-use recheck complete: {} shops changed", changed);
    }

    @Transactional
    public ShopPaymentPrice setPrice(Long shopId, int amount, Long adminUserId) {
        if (!shopRepository.existsById(shopId)) {
            throw new RuntimeException("Shop not found: " + shopId);
        }
        ShopPaymentPrice price = shopPaymentPriceRepository.findByShopId(shopId)
                .orElse(ShopPaymentPrice.builder().shopId(shopId).build());
        price.setAmount(amount);
        price.setUpdatedBy(adminUserId);
        ShopPaymentPrice saved = shopPaymentPriceRepository.save(price);

        // Business rule: the payment clock starts at the shop's JOIN date, not when the
        // price is set. The free window = join date + one billing duration, so a shop
        // older than one period owes immediately the moment a price is set.
        if (amount > 0 && !shopPaymentCollectionRepository.existsByShopIdAndStatus(shopId, ShopPaymentCollection.CollectionStatus.PAID)) {
            LocalDateTime now = LocalDateTime.now();
            LocalDateTime joined = shopRepository.findById(shopId)
                    .map(Shop::getCreatedAt)
                    .orElse(null);
            if (joined == null) joined = now;
            ShopPaymentCollection grace = ShopPaymentCollection.builder()
                    .shopId(shopId)
                    .amount(0)
                    .currency(price.getCurrency())
                    .razorpayOrderId("grace_" + shopId + "_" + now.toEpochSecond(java.time.ZoneOffset.UTC))
                    .status(ShopPaymentCollection.CollectionStatus.PAID)
                    .paidAt(now)
                    .validUntil(joined.plusDays(getDurationDays()))
                    .build();
            shopPaymentCollectionRepository.save(grace);
            log.info("Free window for shop {} runs from join date {} until {}", shopId, joined, grace.getValidUntil());
        }

        recomputeBlockedFlag(shopId);
        return saved;
    }

    @Transactional(readOnly = true)
    public Page<Map<String, Object>> listShopsWithStatus(Pageable pageable) {
        Page<Shop> shops = shopRepository.findAll(pageable);
        return shops.map(this::toSuperAdminRow);
    }

    private Map<String, Object> toSuperAdminRow(Shop shop) {
        ShopPaymentPrice price = shopPaymentPriceRepository.findByShopId(shop.getId()).orElse(null);
        ShopPaymentCollection latestPaid = shopPaymentCollectionRepository
                .findFirstByShopIdAndStatusOrderByValidUntilDesc(shop.getId(), ShopPaymentCollection.CollectionStatus.PAID)
                .orElse(null);
        Map<String, Object> row = new HashMap<>();
        row.put("shopId", shop.getId());
        row.put("shopName", shop.getName());
        row.put("ownerName", shop.getOwnerName());
        row.put("ownerPhone", shop.getOwnerPhone());
        row.put("amount", price != null ? price.getAmount() : 0);
        row.put("currency", price != null ? price.getCurrency() : "INR");
        row.put("paymentBlocked", Boolean.TRUE.equals(shop.getPaymentBlocked()));
        row.put("validUntil", latestPaid != null ? latestPaid.getValidUntil() : null);
        return row;
    }

    @Transactional(readOnly = true)
    public Page<ShopPaymentCollection> getHistory(Long shopId, Pageable pageable) {
        return shopPaymentCollectionRepository.findByShopIdOrderByCreatedAtDesc(shopId, pageable);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getStatusForShop(Long shopId, String shopName) {
        ShopPaymentPrice price = shopPaymentPriceRepository.findByShopId(shopId).orElse(null);
        int amount = price != null ? price.getAmount() : 0;
        String currency = price != null ? price.getCurrency() : "INR";
        boolean paid = isCurrentlyPaid(shopId);
        ShopPaymentCollection latestPaid = shopPaymentCollectionRepository
                .findFirstByShopIdAndStatusOrderByValidUntilDesc(shopId, ShopPaymentCollection.CollectionStatus.PAID)
                .orElse(null);
        LocalDateTime joinedAt = shopRepository.findById(shopId).map(Shop::getCreatedAt).orElse(null);

        Map<String, Object> status = new HashMap<>();
        status.put("shopId", shopId);
        status.put("shopName", shopName);
        status.put("joinedAt", joinedAt);
        status.put("amount", amount);
        status.put("currency", currency);
        status.put("durationDays", getDurationDays());
        status.put("paid", paid);
        status.put("paymentRequired", amount > 0);
        status.put("validUntil", latestPaid != null ? latestPaid.getValidUntil() : null);
        status.put("keyId", isTestMode() ? "TEST_MODE" : razorpayConfig.getActiveKeyId());
        status.put("testMode", isTestMode());
        return status;
    }

    @Transactional
    public Map<String, Object> createOrder(Long shopId) throws RazorpayException {
        ShopPaymentPrice price = shopPaymentPriceRepository.findByShopId(shopId)
                .orElseThrow(() -> new RuntimeException("No payment amount configured for this shop"));
        if (price.getAmount() == null || price.getAmount() <= 0) {
            throw new RuntimeException("No payment amount configured for this shop");
        }
        if (isCurrentlyPaid(shopId)) {
            throw new RuntimeException("Already paid and active for this shop");
        }

        int amountRupees = price.getAmount();
        String currency = price.getCurrency();
        int amountPaise = amountRupees * 100;

        String orderId;
        if (isTestMode()) {
            orderId = "test_order_shop_" + shopId + "_" + System.currentTimeMillis();
            log.info("TEST MODE: Created mock shop payment order: {}", orderId);
        } else {
            JSONObject orderRequest = new JSONObject();
            orderRequest.put("amount", amountPaise);
            orderRequest.put("currency", currency);
            orderRequest.put("receipt", "shop_pay_" + shopId + "_" + System.currentTimeMillis());
            Order razorpayOrder = razorpayClient.orders.create(orderRequest);
            orderId = razorpayOrder.get("id");
        }

        ShopPaymentCollection collection = ShopPaymentCollection.builder()
                .shopId(shopId)
                .amount(amountRupees)
                .currency(currency)
                .razorpayOrderId(orderId)
                .build();
        shopPaymentCollectionRepository.save(collection);
        log.info("Created shop payment order: shopId={}, amount={}, testMode={}",
                shopId, amountRupees, isTestMode());
        return toOrderResult(collection);
    }

    private Map<String, Object> toOrderResult(ShopPaymentCollection collection) {
        Map<String, Object> result = new HashMap<>();
        result.put("orderId", collection.getRazorpayOrderId());
        result.put("amount", collection.getAmount() * 100);
        result.put("currency", collection.getCurrency());
        result.put("keyId", isTestMode() ? "TEST_MODE" : razorpayConfig.getActiveKeyId());
        result.put("testMode", isTestMode());
        return result;
    }

    @Transactional
    public ShopPaymentCollection verifyPayment(Long expectedShopId, String razorpayOrderId, String razorpayPaymentId,
                                                String razorpaySignature) throws RazorpayException {
        ShopPaymentCollection collection = shopPaymentCollectionRepository.findByRazorpayOrderId(razorpayOrderId)
                .orElseThrow(() -> new RuntimeException("Payment order not found: " + razorpayOrderId));

        if (!collection.getShopId().equals(expectedShopId)) {
            throw new RuntimeException("Order does not belong to this shop");
        }

        if (collection.getStatus() == ShopPaymentCollection.CollectionStatus.PAID) {
            return collection;
        }

        if (isTestMode()) {
            log.info("TEST MODE: Auto-verifying shop payment for order: {}", razorpayOrderId);
        } else {
            JSONObject attributes = new JSONObject();
            attributes.put("razorpay_order_id", razorpayOrderId);
            attributes.put("razorpay_payment_id", razorpayPaymentId);
            attributes.put("razorpay_signature", razorpaySignature);

            boolean isValid = Utils.verifyPaymentSignature(attributes, razorpayConfig.getActiveKeySecret());
            if (!isValid) {
                collection.setStatus(ShopPaymentCollection.CollectionStatus.FAILED);
                shopPaymentCollectionRepository.save(collection);
                throw new RuntimeException("Payment signature verification failed");
            }
        }

        LocalDateTime now = LocalDateTime.now();
        ShopPaymentCollection currentlyActive = shopPaymentCollectionRepository
                .findFirstByShopIdAndStatusOrderByValidUntilDesc(collection.getShopId(), ShopPaymentCollection.CollectionStatus.PAID)
                .orElse(null);
        LocalDateTime base = (currentlyActive != null && currentlyActive.getValidUntil() != null
                && currentlyActive.getValidUntil().isAfter(now)) ? currentlyActive.getValidUntil() : now;

        collection.setRazorpayPaymentId(razorpayPaymentId != null ? razorpayPaymentId : "test_pay_" + System.currentTimeMillis());
        collection.setRazorpaySignature(razorpaySignature != null ? razorpaySignature : "test_sig");
        collection.setStatus(ShopPaymentCollection.CollectionStatus.PAID);
        collection.setPaidAt(now);
        collection.setValidUntil(base.plusDays(getDurationDays()));
        ShopPaymentCollection saved = shopPaymentCollectionRepository.save(collection);

        recomputeBlockedFlag(collection.getShopId());
        log.info("Shop payment verified: shopId={}, orderId={}, validUntil={}, testMode={}",
                collection.getShopId(), razorpayOrderId, saved.getValidUntil(), isTestMode());
        return saved;
    }
}
