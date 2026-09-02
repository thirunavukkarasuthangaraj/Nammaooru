package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.User;
import com.shopmanagement.entity.Wallet;
import com.shopmanagement.entity.WalletTransaction;
import com.shopmanagement.entity.WalletWithdrawal;
import com.shopmanagement.repository.UserRepository;
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
import java.util.Map;

@RestController
@RequestMapping("/api/wallet")
@RequiredArgsConstructor
@Slf4j
public class WalletController {

    private final WalletService walletService;
    private final ShopService shopService;
    private final UserRepository userRepository;

    // ===== Shop owner =====

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
            Page<WalletWithdrawal> withdrawals = walletService.getPendingWithdrawals(PageRequest.of(page, size));
            return ResponseUtil.paginated(withdrawals);
        } catch (Exception e) {
            log.error("Error listing pending withdrawals", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/admin/withdrawals/{id}/mark-paid")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<WalletWithdrawal>> markWithdrawalPaid(
            @PathVariable Long id, Authentication authentication,
            @RequestBody Map<String, String> body) {
        try {
            String payoutReference = body.get("payoutReference");
            if (payoutReference == null || payoutReference.isBlank()) {
                return ResponseUtil.badRequest("payoutReference is required (bank UTR / transaction reference)");
            }
            WalletWithdrawal withdrawal = walletService.markWithdrawalPaid(id, payoutReference, authentication.getName());
            return ResponseUtil.success(withdrawal, "Withdrawal marked as paid");
        } catch (Exception e) {
            log.error("Error marking withdrawal {} as paid", id, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/admin/withdrawals/{id}/reject")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<WalletWithdrawal>> rejectWithdrawal(
            @PathVariable Long id, Authentication authentication,
            @RequestBody(required = false) Map<String, String> body) {
        try {
            String reason = body != null ? body.get("reason") : null;
            WalletWithdrawal withdrawal = walletService.rejectWithdrawal(id, reason, authentication.getName());
            return ResponseUtil.success(withdrawal, "Withdrawal rejected");
        } catch (Exception e) {
            log.error("Error rejecting withdrawal {}", id, e);
            return ResponseUtil.error(e.getMessage());
        }
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
