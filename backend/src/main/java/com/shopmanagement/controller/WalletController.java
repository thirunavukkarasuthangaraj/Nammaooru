package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.OrderPayment;
import com.shopmanagement.entity.User;
import com.shopmanagement.entity.Wallet;
import com.shopmanagement.entity.WalletTransaction;
import com.shopmanagement.entity.WalletWithdrawal;
import com.shopmanagement.repository.OrderPaymentRepository;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.service.OrderPaymentService;
import com.shopmanagement.service.WalletService;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.service.ShopService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/wallet")
@RequiredArgsConstructor
@Slf4j
public class WalletController {

    private final WalletService walletService;
    private final ShopService shopService;
    private final UserRepository userRepository;
    private final OrderRepository orderRepository;
    private final OrderPaymentRepository orderPaymentRepository;
    private final OrderPaymentService orderPaymentService;

    // ===== Shop owner =====

    /**
     * One-screen view of what a shop owner actually cares about: how much they
     * sold on a given day (any payment method), lifetime sales, and - separately
     * - how much the platform currently owes them for online-paid orders
     * (COD money they already hold themselves; see Wallet's own note on this).
     */
    @GetMapping("/shop/summary")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getShopPaymentSummary(
            Authentication authentication,
            @RequestParam(required = false) String date) {
        try {
            Shop shop = requireShop(authentication);
            return ResponseUtil.success(buildShopSummary(shop.getId(), date), "Summary retrieved");
        } catch (Exception e) {
            log.error("Error getting shop payment summary", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /**
     * Same summary, for the admin's per-shop Payments view - lets you check a shop's
     * balance before paying them without needing to be logged in as that shop.
     */
    @GetMapping("/admin/shop/{shopId}/summary")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getShopPaymentSummaryForAdmin(
            @PathVariable Long shopId,
            @RequestParam(required = false) String date) {
        try {
            return ResponseUtil.success(buildShopSummary(shopId, date), "Summary retrieved");
        } catch (Exception e) {
            log.error("Error getting shop payment summary for admin (shop {})", shopId, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /**
     * Every shop that has ever earned anything online, with its current balance - the
     * admin's entry point into "which shops do I owe money to right now."
     */
    @GetMapping("/admin/shops-summary")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAllShopsSummary(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        try {
            // Every shop, not just ones with an existing wallet row - a wallet only gets
            // created once a shop's first online order settles, so listing wallets alone
            // silently hid every shop that hasn't had one yet (looked like "only 1 shop
            // exists" instead of "only 1 shop has been paid online so far").
            Page<com.shopmanagement.shop.dto.ShopResponse> shops = shopService.getAllShops(PageRequest.of(page, size));
            Page<Map<String, Object>> mapped = shops.map(shop -> {
                Wallet wallet = walletService.getWallet(Wallet.WalletOwnerType.SHOP, shop.getId());
                Map<String, Object> row = new HashMap<>();
                row.put("shopId", shop.getId());
                row.put("shopName", shop.getName());
                row.put("balance", wallet.getBalance());
                row.put("totalEarned", wallet.getTotalEarned());
                row.put("totalWithdrawn", wallet.getTotalWithdrawn());
                return row;
            });
            return ResponseUtil.paginated(mapped);
        } catch (Exception e) {
            log.error("Error getting all shops summary", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private Map<String, Object> buildShopSummary(Long shopId, String date) {
        LocalDate targetDate = date != null ? LocalDate.parse(date) : LocalDate.now();
        LocalDateTime startOfDay = targetDate.atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1);

        // Online/app orders only - walk-in/POS counter sales don't have a Cash-vs-UPI
        // question (already collected in person) and would make this total not match
        // the online+cash split shown right below it. POS sales are reported elsewhere.
        BigDecimal daySales = orderRepository.getOnlineRevenueByShopAndDateRange(shopId, startOfDay, endOfDay);
        BigDecimal totalSales = orderRepository.getTotalOnlineRevenueByShop(shopId);
        Wallet wallet = walletService.getWallet(Wallet.WalletOwnerType.SHOP, shopId);

        Map<String, Object> daySplit = revenueByMethod(shopId, startOfDay, endOfDay);
        Map<String, Object> allTimeSplit = revenueByMethod(shopId, LocalDateTime.of(2000, 1, 1, 0, 0), LocalDateTime.now());

        Map<String, Object> summary = new HashMap<>();
        summary.put("date", targetDate.toString());
        summary.put("daySales", daySales != null ? daySales : BigDecimal.ZERO);
        summary.put("dayOrderCount", ((Number) daySplit.get("onlineCount")).intValue() + ((Number) daySplit.get("codCount")).intValue());
        summary.put("dayOnlineSales", daySplit.get("onlineSales"));
        summary.put("dayOnlineOrderCount", daySplit.get("onlineCount"));
        summary.put("dayCodSales", daySplit.get("codSales"));
        summary.put("dayCodOrderCount", daySplit.get("codCount"));
        summary.put("totalSales", totalSales != null ? totalSales : BigDecimal.ZERO);
        summary.put("totalOnlineSales", allTimeSplit.get("onlineSales"));
        summary.put("totalCodSales", allTimeSplit.get("codSales"));
        summary.put("walletBalance", wallet.getBalance());
        summary.put("totalEarned", wallet.getTotalEarned());
        summary.put("totalWithdrawn", wallet.getTotalWithdrawn());
        // So the admin can pay directly from this screen (Pay via UPI / bank transfer)
        // without a separate trip to the Withdrawals queue.
        summary.put("payoutMethod", wallet.getPayoutMethod() != null ? wallet.getPayoutMethod().name() : null);
        summary.put("upiId", wallet.getUpiId());
        summary.put("bankAccountHolderName", wallet.getBankAccountHolderName());
        summary.put("bankAccountNumber", wallet.getBankAccountNumber());
        summary.put("bankIfsc", wallet.getBankIfsc());
        // Razorpay settles to the bank account T+2 business days after the payment,
        // not instantly - shown so "why isn't today's online total in my balance yet"
        // has an answer on screen instead of looking broken.
        summary.put("expectedSettlementDate", targetDate.plusDays(2).toString());
        return summary;
    }

    /**
     * Unified order-level view for the Payments screen's transaction table - COD and
     * online orders together (OrderPayment alone only ever covers online orders, so
     * a shop owner using it exclusively would never see their cash sales here),
     * date-range filterable, with the Razorpay fee split into its MDR and GST
     * components for online rows.
     */
    @GetMapping("/shop/orders")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getShopOrderPayments(
            Authentication authentication,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Shop shop = requireShop(authentication);
            return ResponseUtil.paginated(buildShopOrders(shop.getId(), startDate, endDate, page, size));
        } catch (Exception e) {
            log.error("Error getting shop order payments", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /**
     * Same order list, for the admin's per-shop Payments view - what you'd validate
     * before paying a shop, without needing to be logged in as that shop.
     */
    @GetMapping("/admin/shop/{shopId}/orders")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getShopOrderPaymentsForAdmin(
            @PathVariable Long shopId,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            return ResponseUtil.paginated(buildShopOrders(shopId, startDate, endDate, page, size));
        } catch (Exception e) {
            log.error("Error getting shop order payments for admin (shop {})", shopId, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /**
     * Admin pays a shop directly from the Shop Payments screen - request + mark-paid in
     * one step, instead of waiting for the shop to submit a withdrawal request first.
     * amount defaults to the full wallet balance if not given.
     */
    @PostMapping("/admin/shop/{shopId}/release-payment")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> releasePaymentToShop(
            @PathVariable Long shopId, Authentication authentication,
            @RequestBody Map<String, String> body) {
        try {
            String payoutReference = body.get("payoutReference");
            if (payoutReference == null || payoutReference.isBlank()) {
                return ResponseUtil.badRequest("payoutReference is required (bank UTR / UPI transaction reference)");
            }
            BigDecimal amount = body.get("amount") != null && !body.get("amount").isBlank()
                    ? new BigDecimal(body.get("amount")) : null;
            WalletWithdrawal withdrawal = walletService.releasePayment(
                    Wallet.WalletOwnerType.SHOP, shopId, amount, payoutReference, authentication.getName());
            return ResponseUtil.success(withdrawalSummary(withdrawal), "Payment released");
        } catch (Exception e) {
            log.error("Error releasing payment to shop {}", shopId, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /**
     * Payout history - every release ever made to this shop (UTR, amount, date, who
     * processed it), regardless of status. What "where can I see history" points to.
     */
    @GetMapping("/admin/shop/{shopId}/payout-history")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getShopPayoutHistory(
            @PathVariable Long shopId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Page<Map<String, Object>> history = walletService.getWithdrawalHistoryForAdmin(
                    Wallet.WalletOwnerType.SHOP, shopId, PageRequest.of(page, size));
            return ResponseUtil.paginated(history);
        } catch (Exception e) {
            log.error("Error getting payout history for shop {}", shopId, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /**
     * Unified order-level view for the Payments screen's transaction table - COD and
     * online orders together (OrderPayment alone only ever covers online orders, so
     * a shop owner using it exclusively would never see their cash sales here),
     * date-range filterable, with the Razorpay fee split into its MDR and GST
     * components for online rows.
     */
    private Page<Map<String, Object>> buildShopOrders(Long shopId, String startDate, String endDate, int page, int size) {
        LocalDateTime start = startDate != null
                ? LocalDate.parse(startDate).atStartOfDay()
                : LocalDate.now().minusDays(30).atStartOfDay();
        LocalDateTime end = endDate != null
                ? LocalDate.parse(endDate).atStartOfDay().plusDays(1)
                : LocalDateTime.now();

        Page<Order> orders = orderRepository.findByShopIdAndCreatedAtBetweenOrderByCreatedAtDesc(
                shopId, start, end, PageRequest.of(page, size));

        // The REAL Razorpay rate (account-level, ~2.36%), not getGatewayFeePercent() -
        // that's what we charge the CUSTOMER (0, since it's absorbed) and is a pricing
        // decision, not the actual cost. Conflating the two here would make a real
        // deduction (confirmed against the Razorpay dashboard) look like it never
        // happened just because we chose not to pass it on.
        BigDecimal currentFeePercent = orderPaymentService.getRealRazorpayFeePercent();

        return orders.map(order -> {
            Map<String, Object> row = new HashMap<>();
            row.put("orderId", order.getId());
            row.put("orderNumber", order.getOrderNumber());
            row.put("paymentMethod", order.getPaymentMethod() != null ? order.getPaymentMethod().name() : null);
            row.put("subtotal", order.getSubtotal());
            row.put("taxAmount", order.getTaxAmount());
            row.put("deliveryFee", order.getDeliveryFee());
            row.put("totalAmount", order.getTotalAmount());
            row.put("orderStatus", order.getStatus() != null ? order.getStatus().name() : null);
            row.put("paymentStatus", order.getPaymentStatus() != null ? order.getPaymentStatus().name() : null);
            row.put("createdAt", order.getCreatedAt());

            boolean isOnline = order.getPaymentMethod() == Order.PaymentMethod.ONLINE_PAYMENT
                    || order.getPaymentMethod() == Order.PaymentMethod.UPI
                    || order.getPaymentMethod() == Order.PaymentMethod.CARD;
            row.put("isOnline", isOnline);

            BigDecimal razorpayMdr = BigDecimal.ZERO;
            BigDecimal gstOnFee = BigDecimal.ZERO;
            BigDecimal customerPaid = order.getTotalAmount();
            String gatewayStatus = null;
            if (isOnline) {
                OrderPayment payment = orderPaymentRepository.findByOrder_Id(order.getId()).orElse(null);
                if (payment != null) {
                    gatewayStatus = payment.getStatus().name();
                    customerPaid = payment.getTotalChargedAmount() != null ? payment.getTotalChargedAmount() : order.getTotalAmount();
                    // Only money that actually moved incurs a real Razorpay fee -
                    // a CREATED (never completed) or FAILED payment cost nothing.
                    boolean feeApplies = payment.getStatus() == OrderPayment.OrderPaymentStatus.PAID
                            || payment.getStatus() == OrderPayment.OrderPaymentStatus.REFUNDED
                            || payment.getStatus() == OrderPayment.OrderPaymentStatus.PARTIALLY_REFUNDED;
                    if (feeApplies && currentFeePercent.compareTo(BigDecimal.ZERO) > 0) {
                        BigDecimal totalFee = order.getTotalAmount()
                                .multiply(currentFeePercent)
                                .divide(new BigDecimal("100"), 2, java.math.RoundingMode.HALF_UP);
                        // Fee = MDR * 1.18 (2% MDR + 18% GST on that MDR), so MDR = fee / 1.18
                        razorpayMdr = totalFee.divide(new BigDecimal("1.18"), 2, java.math.RoundingMode.HALF_UP);
                        gstOnFee = totalFee.subtract(razorpayMdr);
                    }
                }
            }
            row.put("razorpayMdr", razorpayMdr);
            row.put("gstOnGatewayFee", gstOnFee);
            row.put("totalGatewayFee", razorpayMdr.add(gstOnFee));
            row.put("customerPaid", customerPaid);
            row.put("gatewayStatus", gatewayStatus);

            return row;
        });
    }

    @GetMapping("/shop/balance")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Wallet>> getShopBalance(Authentication authentication) {
        try {
            Shop shop = requireShop(authentication);
            return ResponseUtil.success(walletService.getWallet(Wallet.WalletOwnerType.SHOP, shop.getId()), "Balance retrieved");
        } catch (Exception e) {
            log.error("Error getting shop wallet balance", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/shop/transactions")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getShopTransactions(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Shop shop = requireShop(authentication);
            Page<WalletTransaction> txns = walletService.getTransactions(
                    Wallet.WalletOwnerType.SHOP, shop.getId(), PageRequest.of(page, size));
            return ResponseUtil.paginated(txns);
        } catch (Exception e) {
            log.error("Error getting shop wallet transactions", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping("/shop/withdraw")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<WalletWithdrawal>> requestShopWithdrawal(
            Authentication authentication, @RequestBody(required = false) Map<String, Object> body) {
        try {
            Shop shop = requireShop(authentication);
            BigDecimal amount = parseAmount(body);
            WalletWithdrawal withdrawal = walletService.requestWithdrawal(Wallet.WalletOwnerType.SHOP, shop.getId(), amount);
            return ResponseUtil.success(withdrawal, "Withdrawal requested");
        } catch (Exception e) {
            log.error("Error requesting shop withdrawal", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/shop/payout-details")
    @PreAuthorize("hasRole('SHOP_OWNER')")
    public ResponseEntity<ApiResponse<Wallet>> updateShopPayoutDetails(
            Authentication authentication, @RequestBody Map<String, String> body) {
        try {
            Shop shop = requireShop(authentication);
            Wallet wallet = updatePayoutDetailsFromBody(Wallet.WalletOwnerType.SHOP, shop.getId(), body);
            return ResponseUtil.success(wallet, "Payout details updated");
        } catch (Exception e) {
            log.error("Error updating shop payout details", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    // ===== Delivery partner =====

    @GetMapping("/delivery-partner/balance")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<Wallet>> getPartnerBalance(Authentication authentication) {
        try {
            User partner = requirePartner(authentication);
            return ResponseUtil.success(walletService.getWallet(Wallet.WalletOwnerType.DELIVERY_PARTNER, partner.getId()), "Balance retrieved");
        } catch (Exception e) {
            log.error("Error getting delivery partner wallet balance", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/delivery-partner/transactions")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPartnerTransactions(
            Authentication authentication,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            User partner = requirePartner(authentication);
            Page<WalletTransaction> txns = walletService.getTransactions(
                    Wallet.WalletOwnerType.DELIVERY_PARTNER, partner.getId(), PageRequest.of(page, size));
            return ResponseUtil.paginated(txns);
        } catch (Exception e) {
            log.error("Error getting delivery partner wallet transactions", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping("/delivery-partner/withdraw")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<WalletWithdrawal>> requestPartnerWithdrawal(
            Authentication authentication, @RequestBody(required = false) Map<String, Object> body) {
        try {
            User partner = requirePartner(authentication);
            BigDecimal amount = parseAmount(body);
            WalletWithdrawal withdrawal = walletService.requestWithdrawal(Wallet.WalletOwnerType.DELIVERY_PARTNER, partner.getId(), amount);
            return ResponseUtil.success(withdrawal, "Withdrawal requested");
        } catch (Exception e) {
            log.error("Error requesting delivery partner withdrawal", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/delivery-partner/payout-details")
    @PreAuthorize("hasRole('DELIVERY_PARTNER')")
    public ResponseEntity<ApiResponse<Wallet>> updatePartnerPayoutDetails(
            Authentication authentication, @RequestBody Map<String, String> body) {
        try {
            User partner = requirePartner(authentication);
            Wallet wallet = updatePayoutDetailsFromBody(Wallet.WalletOwnerType.DELIVERY_PARTNER, partner.getId(), body);
            return ResponseUtil.success(wallet, "Payout details updated");
        } catch (Exception e) {
            log.error("Error updating delivery partner payout details", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private Wallet updatePayoutDetailsFromBody(Wallet.WalletOwnerType ownerType, Long ownerId, Map<String, String> body) {
        Wallet.PayoutMethod method = Wallet.PayoutMethod.valueOf(body.get("payoutMethod"));
        return walletService.updatePayoutDetails(ownerType, ownerId, method,
                body.get("accountHolderName"), body.get("accountNumber"), body.get("ifsc"), body.get("upiId"));
    }

    // ===== Admin =====

    @GetMapping("/admin/config")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getConfig() {
        try {
            return ResponseUtil.success(Map.of("payoutMode", walletService.getPayoutMode()), "Config retrieved");
        } catch (Exception e) {
            log.error("Error getting wallet config", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/admin/config")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> updateConfig(@RequestBody Map<String, String> body) {
        try {
            if (body.get("payoutMode") != null) {
                walletService.setPayoutMode(body.get("payoutMode"));
            }
            return ResponseUtil.success(null, "Config updated");
        } catch (Exception e) {
            log.error("Error updating wallet config", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/admin/wallets")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> listWallets(
            @RequestParam Wallet.WalletOwnerType ownerType,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Page<Wallet> wallets = walletService.listWallets(ownerType, PageRequest.of(page, size));
            return ResponseUtil.paginated(wallets);
        } catch (Exception e) {
            log.error("Error listing wallets", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/admin/withdrawals/pending")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPendingWithdrawals(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Page<Map<String, Object>> withdrawals = walletService.getPendingWithdrawalsForAdmin(PageRequest.of(page, size));
            return ResponseUtil.paginated(withdrawals);
        } catch (Exception e) {
            log.error("Error listing pending withdrawals", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/admin/withdrawals/{id}/mark-paid")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> markWithdrawalPaid(
            @PathVariable Long id, Authentication authentication,
            @RequestBody Map<String, String> body) {
        try {
            String payoutReference = body.get("payoutReference");
            if (payoutReference == null || payoutReference.isBlank()) {
                return ResponseUtil.badRequest("payoutReference is required (bank UTR / transaction reference)");
            }
            WalletWithdrawal withdrawal = walletService.markWithdrawalPaid(id, payoutReference, authentication.getName());
            return ResponseUtil.success(withdrawalSummary(withdrawal), "Withdrawal marked as paid");
        } catch (Exception e) {
            log.error("Error marking withdrawal {} as paid", id, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/admin/withdrawals/{id}/reject")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> rejectWithdrawal(
            @PathVariable Long id, Authentication authentication,
            @RequestBody(required = false) Map<String, String> body) {
        try {
            String reason = body != null ? body.get("reason") : null;
            WalletWithdrawal withdrawal = walletService.rejectWithdrawal(id, reason, authentication.getName());
            return ResponseUtil.success(withdrawalSummary(withdrawal), "Withdrawal rejected");
        } catch (Exception e) {
            log.error("Error rejecting withdrawal {}", id, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    // Avoids serializing WalletWithdrawal's lazy `wallet` field directly - same
    // LazyInitializationException class of bug this app has hit before.
    private Map<String, Object> withdrawalSummary(WalletWithdrawal withdrawal) {
        Map<String, Object> row = new HashMap<>();
        row.put("id", withdrawal.getId());
        row.put("amount", withdrawal.getAmount());
        row.put("status", withdrawal.getStatus().name());
        row.put("payoutReference", withdrawal.getPayoutReference());
        row.put("notes", withdrawal.getNotes());
        row.put("processedAt", withdrawal.getProcessedAt());
        row.put("processedBy", withdrawal.getProcessedBy());
        return row;
    }

    private Map<String, Object> revenueByMethod(Long shopId, LocalDateTime start, LocalDateTime end) {
        BigDecimal onlineSales = BigDecimal.ZERO;
        BigDecimal codSales = BigDecimal.ZERO;
        int onlineCount = 0;
        int codCount = 0;
        for (Object[] row : orderRepository.getRevenueByShopGroupedByMethod(shopId, start, end)) {
            Order.PaymentMethod method = (Order.PaymentMethod) row[0];
            BigDecimal amount = (BigDecimal) row[1];
            long count = (Long) row[2];
            boolean isOnline = method == Order.PaymentMethod.ONLINE_PAYMENT
                    || method == Order.PaymentMethod.UPI
                    || method == Order.PaymentMethod.CARD;
            if (isOnline) {
                onlineSales = onlineSales.add(amount);
                onlineCount += count;
            } else {
                codSales = codSales.add(amount);
                codCount += count;
            }
        }
        Map<String, Object> result = new HashMap<>();
        result.put("onlineSales", onlineSales);
        result.put("onlineCount", onlineCount);
        result.put("codSales", codSales);
        result.put("codCount", codCount);
        return result;
    }

    private Shop requireShop(Authentication authentication) {
        Shop shop = shopService.getShopByOwner(authentication.getName());
        if (shop == null) {
            throw new RuntimeException("Shop not found for owner: " + authentication.getName());
        }
        return shop;
    }

    private User requirePartner(Authentication authentication) {
        return userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found: " + authentication.getName()));
    }

    private BigDecimal parseAmount(Map<String, Object> body) {
        if (body == null || body.get("amount") == null) return null; // null = withdraw full balance
        return new BigDecimal(body.get("amount").toString());
    }
}
