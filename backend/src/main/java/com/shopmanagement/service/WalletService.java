package com.shopmanagement.service;

import com.shopmanagement.entity.Order;
import com.shopmanagement.entity.User;
import com.shopmanagement.entity.Wallet;
import com.shopmanagement.entity.WalletTransaction;
import com.shopmanagement.entity.WalletWithdrawal;
import com.shopmanagement.repository.OrderRepository;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.repository.WalletRepository;
import com.shopmanagement.repository.WalletTransactionRepository;
import com.shopmanagement.repository.WalletWithdrawalRepository;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.repository.ShopRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class WalletService {

    private final SettingService settingService;

    private static final String PAYOUT_MODE_KEY = "wallet.payout_mode"; // MANUAL | AUTOMATIC
    private static final String DEFAULT_PAYOUT_MODE = "MANUAL";

    public String getPayoutMode() {
        return settingService.getSettingValue(PAYOUT_MODE_KEY, DEFAULT_PAYOUT_MODE);
    }

    public boolean isAutomatedPayoutMode() {
        return "AUTOMATIC".equalsIgnoreCase(getPayoutMode());
    }

    @Transactional
    public void setPayoutMode(String mode) {
        if (!"MANUAL".equalsIgnoreCase(mode) && !"AUTOMATIC".equalsIgnoreCase(mode)) {
            throw new IllegalArgumentException("payoutMode must be MANUAL or AUTOMATIC");
        }
        settingService.saveSetting(PAYOUT_MODE_KEY, mode.toUpperCase(),
                "MANUAL = admin transfers and marks withdrawals paid by hand. "
                + "AUTOMATIC = intended for Razorpay Route/RazorpayX once configured; "
                + "currently still falls back to manual since no payout provider is wired up.");
    }

    private final WalletRepository walletRepository;
    private final WalletTransactionRepository walletTransactionRepository;
    private final WalletWithdrawalRepository walletWithdrawalRepository;
    private final OrderRepository orderRepository;
    private final ShopRepository shopRepository;
    private final UserRepository userRepository;

    @Transactional
    public Wallet getOrCreateWallet(Wallet.WalletOwnerType ownerType, Long ownerId) {
        return walletRepository.findByOwnerTypeAndOwnerId(ownerType, ownerId)
                .orElseGet(() -> walletRepository.save(Wallet.builder()
                        .ownerType(ownerType)
                        .ownerId(ownerId)
                        .build()));
    }

    @Transactional(readOnly = true)
    public Wallet getWallet(Wallet.WalletOwnerType ownerType, Long ownerId) {
        return walletRepository.findByOwnerTypeAndOwnerId(ownerType, ownerId)
                .orElseGet(() -> Wallet.builder()
                        .ownerType(ownerType).ownerId(ownerId)
                        .balance(BigDecimal.ZERO).totalEarned(BigDecimal.ZERO).totalWithdrawn(BigDecimal.ZERO)
                        .build());
    }

    /**
     * Credit a wallet for a delivered order's settlement. Idempotent — retrying the same
     * (wallet, order) settlement is a no-op instead of double-crediting, guarded both here
     * and by the DB's partial unique index as a last line of defense against races.
     */
    @Transactional
    public void creditForOrder(Wallet.WalletOwnerType ownerType, Long ownerId, Long orderId, BigDecimal amount, String notes) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            log.warn("Skipping wallet credit for order {}: non-positive amount {}", orderId, amount);
            return;
        }
        boolean alreadySettled = walletTransactionRepository
                .findByWallet_IdAndOrder_IdAndReason(
                        getOrCreateWallet(ownerType, ownerId).getId(), orderId,
                        WalletTransaction.TransactionReason.ORDER_SETTLEMENT)
                .isPresent();
        if (alreadySettled) {
            log.info("Wallet already settled for order {} ({} {}), skipping duplicate credit", orderId, ownerType, ownerId);
            return;
        }

        Wallet wallet = getOrCreateWallet(ownerType, ownerId);
        Order order = orderRepository.findById(orderId).orElse(null);

        wallet.setBalance(wallet.getBalance().add(amount));
        wallet.setTotalEarned(wallet.getTotalEarned().add(amount));
        walletRepository.save(wallet);

        WalletTransaction txn = WalletTransaction.builder()
                .wallet(wallet)
                .type(WalletTransaction.TransactionType.CREDIT)
                .reason(WalletTransaction.TransactionReason.ORDER_SETTLEMENT)
                .amount(amount)
                .balanceAfter(wallet.getBalance())
                .order(order)
                .notes(notes)
                .build();
        walletTransactionRepository.save(txn);
        log.info("Credited {} {} to {} wallet (ownerId={}) for order {}", amount, wallet.getCurrency(), ownerType, ownerId, orderId);
    }

    @Transactional(readOnly = true)
    public Page<WalletTransaction> getTransactions(Wallet.WalletOwnerType ownerType, Long ownerId, Pageable pageable) {
        Wallet wallet = getWallet(ownerType, ownerId);
        if (wallet.getId() == null) {
            return Page.empty(pageable);
        }
        return walletTransactionRepository.findByWallet_IdOrderByCreatedAtDesc(wallet.getId(), pageable);
    }

    /** Request a withdrawal of the full available balance, or a specific amount if given. */
    @Transactional
    public WalletWithdrawal requestWithdrawal(Wallet.WalletOwnerType ownerType, Long ownerId, BigDecimal amount) {
        Wallet wallet = getOrCreateWallet(ownerType, ownerId);

        BigDecimal requested = (amount != null) ? amount : wallet.getBalance();
        if (requested == null || requested.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Withdrawal amount must be greater than zero");
        }
        if (requested.compareTo(wallet.getBalance()) > 0) {
            throw new IllegalArgumentException("Withdrawal amount exceeds available balance");
        }
        if (walletWithdrawalRepository.existsByWallet_IdAndStatus(wallet.getId(), WalletWithdrawal.WithdrawalStatus.PENDING)) {
            throw new IllegalStateException("A withdrawal request is already pending for this wallet");
        }

        WalletWithdrawal withdrawal = WalletWithdrawal.builder()
                .wallet(wallet)
                .amount(requested)
                .status(WalletWithdrawal.WithdrawalStatus.PENDING)
                .build();
        withdrawal = walletWithdrawalRepository.save(withdrawal);

        // AUTOMATIC mode is the hook point for a real Razorpay Route / RazorpayX payout call
        // once that's set up on the Razorpay side — today it has nothing to call, so it logs
        // and leaves the request PENDING for manual processing rather than pretending to pay
        // it out. Never silently claim a payout happened when it didn't.
        if (isAutomatedPayoutMode()) {
            if (wallet.getRazorpayFundAccountId() == null || wallet.getRazorpayFundAccountId().isBlank()) {
                log.warn("Payout mode is AUTOMATIC but wallet {} (ownerType={}, ownerId={}) has no linked payout account yet — "
                        + "leaving withdrawal {} as PENDING for manual processing", wallet.getId(), ownerType, ownerId, withdrawal.getId());
            } else {
                log.warn("Payout mode is AUTOMATIC and wallet {} has a linked payout account, but no automated payout "
                        + "provider is wired up yet — leaving withdrawal {} as PENDING for manual processing", wallet.getId(), withdrawal.getId());
            }
        }

        return withdrawal;
    }

    /**
     * Admin marks a withdrawal as actually paid (manual bank transfer today; a RazorpayX
     * payout call plugs in here later without changing this method's contract). Only now
     * does the DEBIT ledger entry get written — a pending request never touches the balance
     * twice, since the debit happens exactly once, at the moment of this transition.
     */
    @Transactional
    public WalletWithdrawal markWithdrawalPaid(Long withdrawalId, String payoutReference, String processedBy) {
        WalletWithdrawal withdrawal = walletWithdrawalRepository.findById(withdrawalId)
                .orElseThrow(() -> new IllegalArgumentException("Withdrawal not found: " + withdrawalId));
        if (withdrawal.getStatus() != WalletWithdrawal.WithdrawalStatus.PENDING) {
            throw new IllegalStateException("Withdrawal is not pending (status=" + withdrawal.getStatus() + ")");
        }

        Wallet wallet = withdrawal.getWallet();
        if (withdrawal.getAmount().compareTo(wallet.getBalance()) > 0) {
            throw new IllegalStateException("Wallet balance is insufficient to cover this withdrawal — balance may have changed since it was requested");
        }

        wallet.setBalance(wallet.getBalance().subtract(withdrawal.getAmount()));
        wallet.setTotalWithdrawn(wallet.getTotalWithdrawn().add(withdrawal.getAmount()));
        walletRepository.save(wallet);

        withdrawal.setStatus(WalletWithdrawal.WithdrawalStatus.PAID);
        withdrawal.setPayoutReference(payoutReference);
        withdrawal.setProcessedAt(LocalDateTime.now());
        withdrawal.setProcessedBy(processedBy);
        WalletWithdrawal saved = walletWithdrawalRepository.save(withdrawal);

        walletTransactionRepository.save(WalletTransaction.builder()
                .wallet(wallet)
                .type(WalletTransaction.TransactionType.DEBIT)
                .reason(WalletTransaction.TransactionReason.WITHDRAWAL)
                .amount(withdrawal.getAmount())
                .balanceAfter(wallet.getBalance())
                .withdrawal(withdrawal)
                .notes(payoutReference)
                .build());

        log.info("Withdrawal {} marked PAID: {} {} to {} wallet (ownerId={}), ref={}",
                withdrawalId, withdrawal.getAmount(), wallet.getCurrency(), wallet.getOwnerType(), wallet.getOwnerId(), payoutReference);
        return saved;
    }

    @Transactional
    public WalletWithdrawal rejectWithdrawal(Long withdrawalId, String reason, String processedBy) {
        WalletWithdrawal withdrawal = walletWithdrawalRepository.findById(withdrawalId)
                .orElseThrow(() -> new IllegalArgumentException("Withdrawal not found: " + withdrawalId));
        if (withdrawal.getStatus() != WalletWithdrawal.WithdrawalStatus.PENDING) {
            throw new IllegalStateException("Withdrawal is not pending (status=" + withdrawal.getStatus() + ")");
        }
        withdrawal.setStatus(WalletWithdrawal.WithdrawalStatus.REJECTED);
        withdrawal.setNotes(reason);
        withdrawal.setProcessedAt(LocalDateTime.now());
        withdrawal.setProcessedBy(processedBy);
        return walletWithdrawalRepository.save(withdrawal);
    }

    @Transactional(readOnly = true)
    public Page<WalletWithdrawal> getPendingWithdrawals(Pageable pageable) {
        return walletWithdrawalRepository.findByStatusOrderByRequestedAtAsc(WalletWithdrawal.WithdrawalStatus.PENDING, pageable);
    }

    /**
     * Maps to plain data inside the transaction rather than returning entities - wallet
     * is a lazy @ManyToOne on WalletWithdrawal, same LazyInitializationException risk as
     * elsewhere in this app if it's serialized after the transaction closes. Also resolves
     * the owner's display name and payout details so the admin screen can show "who to pay
     * and where" without a second round trip per row.
     */
    @Transactional(readOnly = true)
    public Page<Map<String, Object>> getPendingWithdrawalsForAdmin(Pageable pageable) {
        return walletWithdrawalRepository.findByStatusOrderByRequestedAtAsc(WalletWithdrawal.WithdrawalStatus.PENDING, pageable)
                .map(withdrawal -> {
                    Wallet wallet = withdrawal.getWallet();
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", withdrawal.getId());
                    row.put("amount", withdrawal.getAmount());
                    row.put("status", withdrawal.getStatus().name());
                    row.put("requestedAt", withdrawal.getRequestedAt());
                    row.put("notes", withdrawal.getNotes());
                    row.put("ownerType", wallet.getOwnerType().name());
                    row.put("ownerId", wallet.getOwnerId());
                    row.put("ownerName", resolveOwnerName(wallet.getOwnerType(), wallet.getOwnerId()));
                    row.put("payoutMethod", wallet.getPayoutMethod() != null ? wallet.getPayoutMethod().name() : null);
                    row.put("upiId", wallet.getUpiId());
                    row.put("bankAccountHolderName", wallet.getBankAccountHolderName());
                    row.put("bankAccountNumber", wallet.getBankAccountNumber());
                    row.put("bankIfsc", wallet.getBankIfsc());
                    row.put("payoutDetailsVerified", wallet.getPayoutDetailsVerified());
                    return row;
                });
    }

    public String resolveOwnerName(Wallet.WalletOwnerType ownerType, Long ownerId) {
        if (ownerType == Wallet.WalletOwnerType.SHOP) {
            return shopRepository.findById(ownerId).map(Shop::getName).orElse("Shop #" + ownerId);
        }
        return userRepository.findById(ownerId)
                .map(u -> ((u.getFirstName() != null ? u.getFirstName() : "") + " " + (u.getLastName() != null ? u.getLastName() : "")).trim())
                .filter(name -> !name.isEmpty())
                .orElse("Partner #" + ownerId);
    }

    @Transactional(readOnly = true)
    public Page<Wallet> listWallets(Wallet.WalletOwnerType ownerType, Pageable pageable) {
        return walletRepository.findByOwnerTypeOrderByBalanceDesc(ownerType, pageable);
    }

    /**
     * Shop owner / delivery partner submits where their payout should go. Purely data
     * capture today — payoutDetailsVerified stays false until an admin (or a real Route/
     * RazorpayX linked-account creation, once wired up) confirms it.
     */
    @Transactional
    public Wallet updatePayoutDetails(Wallet.WalletOwnerType ownerType, Long ownerId, Wallet.PayoutMethod method,
                                       String accountHolderName, String accountNumber, String ifsc, String upiId) {
        Wallet wallet = getOrCreateWallet(ownerType, ownerId);

        if (method == Wallet.PayoutMethod.BANK_ACCOUNT) {
            if (accountHolderName == null || accountHolderName.isBlank()
                    || accountNumber == null || accountNumber.isBlank()
                    || ifsc == null || ifsc.isBlank()) {
                throw new IllegalArgumentException("Account holder name, account number, and IFSC are required for bank transfer");
            }
        } else if (method == Wallet.PayoutMethod.UPI) {
            if (upiId == null || upiId.isBlank()) {
                throw new IllegalArgumentException("UPI ID is required");
            }
        } else {
            throw new IllegalArgumentException("payoutMethod must be BANK_ACCOUNT or UPI");
        }

        wallet.setPayoutMethod(method);
        wallet.setBankAccountHolderName(method == Wallet.PayoutMethod.BANK_ACCOUNT ? accountHolderName : null);
        wallet.setBankAccountNumber(method == Wallet.PayoutMethod.BANK_ACCOUNT ? accountNumber : null);
        wallet.setBankIfsc(method == Wallet.PayoutMethod.BANK_ACCOUNT ? ifsc : null);
        wallet.setUpiId(method == Wallet.PayoutMethod.UPI ? upiId : null);
        // Changing payout details invalidates any prior verification — re-confirm before paying out.
        wallet.setPayoutDetailsVerified(false);

        return walletRepository.save(wallet);
    }
}
