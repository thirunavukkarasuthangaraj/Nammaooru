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
import com.shopmanagement.repository.ShopWhatsAppUsageRepository;
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
    private final ShopWhatsAppUsageRepository shopWhatsAppUsageRepository;
    private final RazorpayClient razorpayClient;
    private final RazorpayConfig razorpayConfig;
    private final SettingService settingService;
    private final ShopPaymentInvoiceService shopPaymentInvoiceService;

    private static final String DURATION_SETTING_KEY = "shop_payment_collect.duration_days";
    private static final String BILL_RATE_SETTING_KEY = "shop_payment_collect.whatsapp_rate_paise";
    private static final String MARKETING_RATE_SETTING_KEY = "shop_payment_collect.whatsapp_marketing_rate_paise";
    private static final String GST_SETTING_KEY = "shop_payment_collect.gst_percent";

    @Autowired
    public ShopPaymentCollectService(ShopRepository shopRepository,
                                      ShopPaymentPriceRepository shopPaymentPriceRepository,
                                      ShopPaymentCollectionRepository shopPaymentCollectionRepository,
                                      ShopWhatsAppUsageRepository shopWhatsAppUsageRepository,
                                      @Autowired(required = false) RazorpayClient razorpayClient,
                                      RazorpayConfig razorpayConfig,
                                      SettingService settingService,
                                      ShopPaymentInvoiceService shopPaymentInvoiceService) {
        this.shopRepository = shopRepository;
        this.shopPaymentPriceRepository = shopPaymentPriceRepository;
        this.shopPaymentCollectionRepository = shopPaymentCollectionRepository;
        this.shopWhatsAppUsageRepository = shopWhatsAppUsageRepository;
        this.razorpayClient = razorpayClient;
        this.razorpayConfig = razorpayConfig;
        this.settingService = settingService;
        this.shopPaymentInvoiceService = shopPaymentInvoiceService;
    }

    private boolean isTestMode() {
        return razorpayConfig.isTestMode();
    }

    public int getDurationDays() {
        return Integer.parseInt(settingService.getSettingValue(DURATION_SETTING_KEY, "30"));
    }

    /** Per-shop duration override wins over the global setting (yearly payers etc). */
    private int effectiveDurationDays(ShopPaymentPrice price) {
        return (price != null && price.getDurationDays() != null && price.getDurationDays() > 0)
                ? price.getDurationDays()
                : getDurationDays();
    }

    // ===== WhatsApp usage billing (all rates in paise, from config) =====

    public int getBillRatePaise() {
        return Integer.parseInt(settingService.getSettingValue(BILL_RATE_SETTING_KEY, "45"));
    }

    public int getMarketingRatePaise() {
        return Integer.parseInt(settingService.getSettingValue(MARKETING_RATE_SETTING_KEY, "100"));
    }

    public int getGstPercent() {
        return Integer.parseInt(settingService.getSettingValue(GST_SETTING_KEY, "18"));
    }

    /** Per-shop bill-message rate override wins over the global setting. */
    private int effectiveBillRatePaise(ShopPaymentPrice price) {
        return (price != null && price.getWhatsappRatePaise() != null && price.getWhatsappRatePaise() > 0)
                ? price.getWhatsappRatePaise()
                : getBillRatePaise();
    }

    /** Unbilled WhatsApp usage for a shop as of "now": message counts and charge in paise. */
    private long[] usageBreakdown(Long shopId, ShopPaymentPrice price) {
        return usageBreakdown(shopId, price, LocalDateTime.now());
    }

    /**
     * Unbilled WhatsApp usage for a shop as of a fixed cutoff. Order creation and payment
     * settlement MUST use the same cutoff instant so the exact set of messages that were
     * charged is the exact set that gets marked settled — never more, never fewer.
     */
    private long[] usageBreakdown(Long shopId, ShopPaymentPrice price, LocalDateTime cutoff) {
        long billCount = shopWhatsAppUsageRepository
                .countByShopIdAndSettledFalseAndMessageTypeAndCreatedAtLessThanEqual(
                        shopId, ShopWhatsAppUsageService.TYPE_BILL, cutoff);
        long marketingCount = shopWhatsAppUsageRepository
                .countByShopIdAndSettledFalseAndMessageTypeAndCreatedAtLessThanEqual(
                        shopId, ShopWhatsAppUsageService.TYPE_MARKETING, cutoff);
        long usagePaise = billCount * effectiveBillRatePaise(price) + marketingCount * getMarketingRatePaise();
        return new long[]{billCount, marketingCount, usagePaise};
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
                ShopPaymentPrice shopPrice = shopPaymentPriceRepository.findByShopId(shop.getId()).orElse(null);
                window.setValidUntil(joined.plusDays(effectiveDurationDays(shopPrice)));
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
    public ShopPaymentPrice setPrice(Long shopId, int amount, Integer durationDays, Integer whatsappRatePaise, Long adminUserId) {
        if (!shopRepository.existsById(shopId)) {
            throw new RuntimeException("Shop not found: " + shopId);
        }
        ShopPaymentPrice price = shopPaymentPriceRepository.findByShopId(shopId)
                .orElse(ShopPaymentPrice.builder().shopId(shopId).build());
        price.setAmount(amount);
        price.setDurationDays(durationDays != null && durationDays > 0 ? durationDays : null);
        price.setWhatsappRatePaise(whatsappRatePaise != null && whatsappRatePaise > 0 ? whatsappRatePaise : null);
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
                    .validUntil(joined.plusDays(effectiveDurationDays(price)))
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
        long[] usage = usageBreakdown(shop.getId(), price);
        row.put("amount", price != null ? price.getAmount() : 0);
        row.put("durationDays", price != null ? price.getDurationDays() : null);
        row.put("whatsappRatePaise", price != null ? price.getWhatsappRatePaise() : null);
        row.put("unbilledMessages", usage[0] + usage[1]);
        row.put("usageAmountPaise", usage[2]);
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

        long[] usage = usageBreakdown(shopId, price);
        long usagePaise = usage[2];
        int gstPercent = getGstPercent();
        long gstPaise = Math.round((amount * 100L + usagePaise) * gstPercent / 100.0);
        long totalPaise = amount * 100L + usagePaise + gstPaise;

        Map<String, Object> status = new HashMap<>();
        status.put("shopId", shopId);
        status.put("shopName", shopName);
        status.put("joinedAt", joinedAt);
        status.put("amount", amount);
        status.put("billMsgCount", usage[0]);
        status.put("marketingMsgCount", usage[1]);
        status.put("usageAmountPaise", usagePaise);
        status.put("gstPercent", gstPercent);
        status.put("gstAmountPaise", gstPaise);
        status.put("totalAmountPaise", totalPaise);
        status.put("currency", currency);
        status.put("durationDays", effectiveDurationDays(price));
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

        // Invoice = platform fee + unbilled WhatsApp usage + GST (all config-driven).
        // The cutoff is fixed here and reused at verification so exactly these messages
        // (no more, no fewer) get marked settled once payment succeeds.
        LocalDateTime usageCutoff = LocalDateTime.now();
        long[] usage = usageBreakdown(shopId, price, usageCutoff);
        long usagePaise = usage[2];
        long gstPaise = Math.round((amountRupees * 100L + usagePaise) * getGstPercent() / 100.0);
        long totalPaise = amountRupees * 100L + usagePaise + gstPaise;

        String orderId;
        if (isTestMode()) {
            orderId = "test_order_shop_" + shopId + "_" + System.currentTimeMillis();
            log.info("TEST MODE: Created mock shop payment order: {}", orderId);
        } else {
            JSONObject orderRequest = new JSONObject();
            orderRequest.put("amount", totalPaise);
            orderRequest.put("currency", currency);
            orderRequest.put("receipt", "shop_pay_" + shopId + "_" + System.currentTimeMillis());
            Order razorpayOrder = razorpayClient.orders.create(orderRequest);
            orderId = razorpayOrder.get("id");
        }

        ShopPaymentCollection collection = ShopPaymentCollection.builder()
                .shopId(shopId)
                .amount(amountRupees)
                .usageCount((int) (usage[0] + usage[1]))
                .usageAmount((int) usagePaise)
                .gstAmount((int) gstPaise)
                .usageCutoff(usageCutoff)
                .currency(currency)
                .razorpayOrderId(orderId)
                .build();
        shopPaymentCollectionRepository.save(collection);
        log.info("Created shop payment order: shopId={}, platform={}, usagePaise={}, gstPaise={}, totalPaise={}, testMode={}",
                shopId, amountRupees, usagePaise, gstPaise, totalPaise, isTestMode());
        return toOrderResult(collection);
    }

    private Map<String, Object> toOrderResult(ShopPaymentCollection collection) {
        long totalPaise = collection.getAmount() * 100L
                + (collection.getUsageAmount() != null ? collection.getUsageAmount() : 0)
                + (collection.getGstAmount() != null ? collection.getGstAmount() : 0);
        Map<String, Object> result = new HashMap<>();
        result.put("orderId", collection.getRazorpayOrderId());
        result.put("amount", totalPaise);
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

        ShopPaymentPrice shopPrice = shopPaymentPriceRepository.findByShopId(collection.getShopId()).orElse(null);
        collection.setRazorpayPaymentId(razorpayPaymentId != null ? razorpayPaymentId : "test_pay_" + System.currentTimeMillis());
        collection.setRazorpaySignature(razorpaySignature != null ? razorpaySignature : "test_sig");
        collection.setStatus(ShopPaymentCollection.CollectionStatus.PAID);
        collection.setPaidAt(now);
        collection.setValidUntil(base.plusDays(effectiveDurationDays(shopPrice)));
        ShopPaymentCollection saved = shopPaymentCollectionRepository.save(collection);

        // The messages billed on this invoice are exactly those counted at order-creation
        // time (see usageCutoff in createOrder) — anything sent during checkout rolls to
        // the next cycle. Fall back to createdAt only for pre-usageCutoff legacy rows.
        LocalDateTime settleUpTo = collection.getUsageCutoff() != null
                ? collection.getUsageCutoff() : collection.getCreatedAt();
        int settledMessages = shopWhatsAppUsageRepository.settleUpTo(
                collection.getShopId(), settleUpTo, saved.getId());

        recomputeBlockedFlag(collection.getShopId());
        log.info("Shop payment verified: shopId={}, orderId={}, validUntil={}, settledMessages={}, testMode={}",
                collection.getShopId(), razorpayOrderId, saved.getValidUntil(), settledMessages, isTestMode());

        // Receipt to the owner via email + WhatsApp (async; a send failure never fails the payment)
        if (saved.getAmount() != null && saved.getAmount() > 0) {
            shopRepository.findById(saved.getShopId())
                    .ifPresent(shop -> shopPaymentInvoiceService.sendPaymentReceipt(shop, saved));
        }
        return saved;
    }

    // ===== Billing config (superadmin-editable; all values come from settings) =====

    @Transactional(readOnly = true)
    public Map<String, Object> getBillingConfig() {
        Map<String, Object> config = new HashMap<>();
        config.put("durationDays", getDurationDays());
        config.put("billRatePaise", getBillRatePaise());
        config.put("marketingRatePaise", getMarketingRatePaise());
        config.put("gstPercent", getGstPercent());
        return config;
    }

    @Transactional
    public void updateBillingConfig(Integer billRatePaise, Integer marketingRatePaise, Integer gstPercent) {
        if (billRatePaise != null) {
            if (billRatePaise < 0) throw new RuntimeException("Bill message rate cannot be negative");
            settingService.saveSetting(BILL_RATE_SETTING_KEY, String.valueOf(billRatePaise),
                    "Per WhatsApp message charge to shops (paise)");
        }
        if (marketingRatePaise != null) {
            if (marketingRatePaise < 0) throw new RuntimeException("Marketing message rate cannot be negative");
            settingService.saveSetting(MARKETING_RATE_SETTING_KEY, String.valueOf(marketingRatePaise),
                    "Per WhatsApp marketing message charge to shops (paise)");
        }
        if (gstPercent != null) {
            if (gstPercent < 0 || gstPercent > 100) throw new RuntimeException("GST percent must be 0-100");
            settingService.saveSetting(GST_SETTING_KEY, String.valueOf(gstPercent),
                    "GST percent applied to pay-and-use invoices");
        }
    }

    /** Overall unbilled-usage summary across all shops, for the superadmin dashboard. */
    @Transactional(readOnly = true)
    public Map<String, Object> getUsageSummary() {
        long totalBill = 0;
        long totalMarketing = 0;
        long totalPaise = 0;
        for (ShopPaymentPrice price : shopPaymentPriceRepository.findAll()) {
            long[] usage = usageBreakdown(price.getShopId(), price);
            totalBill += usage[0];
            totalMarketing += usage[1];
            totalPaise += usage[2];
        }
        Map<String, Object> summary = new HashMap<>();
        summary.put("unbilledBillMessages", totalBill);
        summary.put("unbilledMarketingMessages", totalMarketing);
        summary.put("unbilledUsagePaise", totalPaise);
        return summary;
    }
}
