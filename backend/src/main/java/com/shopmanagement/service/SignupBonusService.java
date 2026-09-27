package com.shopmanagement.service;

import com.shopmanagement.entity.SignupBonus;
import com.shopmanagement.entity.User;
import com.shopmanagement.entity.UserFcmToken;
import com.shopmanagement.repository.SignupBonusRepository;
import com.shopmanagement.repository.UserFcmTokenRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class SignupBonusService {

    private final SignupBonusRepository signupBonusRepository;
    private final SettingService settingService;
    private final UserRepository userRepository;
    private final UserFcmTokenRepository userFcmTokenRepository;
    private final FirebaseNotificationService firebaseNotificationService;

    private static final String ENABLED_KEY = "signup_bonus.enabled";
    private static final String AMOUNT_KEY = "signup_bonus.amount";
    private static final String REMINDER_INTERVAL_KEY = "signup_bonus.admin_reminder_interval_minutes";
    private static final String LAST_REMINDER_AT_KEY = "signup_bonus.last_admin_reminder_at";

    private static final String DEFAULT_AMOUNT = "10.00";
    private static final String DEFAULT_REMINDER_INTERVAL_MINUTES = "60";

    public boolean isEnabled() {
        return "true".equalsIgnoreCase(settingService.getSettingValue(ENABLED_KEY, "false"));
    }

    @Transactional
    public void setEnabled(boolean enabled) {
        settingService.saveSetting(ENABLED_KEY, String.valueOf(enabled),
                "Master switch for the customer registration welcome bonus. "
                + "true = new registrations are queued for a manual UPI payout. "
                + "false = the feature is completely off, nothing is granted.");
    }

    public BigDecimal getBonusAmount() {
        return new BigDecimal(settingService.getSettingValue(AMOUNT_KEY, DEFAULT_AMOUNT));
    }

    @Transactional
    public void setBonusAmount(BigDecimal amount) {
        if (amount == null || amount.signum() < 0) {
            throw new IllegalArgumentException("Bonus amount must be zero or positive");
        }
        settingService.saveSetting(AMOUNT_KEY, amount.toPlainString(),
                "Welcome bonus (INR) queued for manual UPI payout when a new customer registers.");
    }

    public int getAdminReminderIntervalMinutes() {
        return Integer.parseInt(settingService.getSettingValue(REMINDER_INTERVAL_KEY, DEFAULT_REMINDER_INTERVAL_MINUTES));
    }

    @Transactional
    public void setAdminReminderIntervalMinutes(int minutes) {
        if (minutes < 5) {
            throw new IllegalArgumentException("Reminder interval must be at least 5 minutes");
        }
        settingService.saveSetting(REMINDER_INTERVAL_KEY, String.valueOf(minutes),
                "How often (minutes) admins get a push reminder about pending welcome-bonus UPI payouts.");
    }

    /**
     * Grants the welcome bonus for a brand-new registration - called ONLY from the
     * server-side registration flow (CustomerService.registerMobileCustomer), never
     * from a customer-callable endpoint. That's deliberate: a client-triggerable
     * "claim" endpoint would let any already-registered customer call it directly
     * and collect free money with no actual new signup behind it. Idempotent per
     * mobile number (race-safe via the table's unique constraint) so a retried
     * registration call never grants twice.
     */
    @Transactional
    public void grantOnRegistration(String mobileNumber) {
        if (!isEnabled()) {
            return;
        }
        if (signupBonusRepository.findByMobileNumber(mobileNumber).isPresent()) {
            return; // already granted for this number (shouldn't happen for a genuinely new registration)
        }

        SignupBonus bonus = SignupBonus.builder()
                .mobileNumber(mobileNumber)
                .amount(getBonusAmount())
                .status(SignupBonus.Status.UNPAID)
                .build();

        try {
            bonus = signupBonusRepository.save(bonus);
        } catch (DataIntegrityViolationException e) {
            // Concurrent registration retry already inserted it - not an error.
            log.info("Signup bonus already exists for {} (concurrent insert)", mobileNumber);
            return;
        }

        log.info("Granted signup welcome bonus of {} to {}", bonus.getAmount(), mobileNumber);
        notifyCustomer(mobileNumber, bonus.getAmount());
    }

    private void notifyCustomer(String mobileNumber, BigDecimal amount) {
        try {
            Optional<User> user = userRepository.findByMobileNumber(mobileNumber);
            if (user.isEmpty()) return;
            List<UserFcmToken> tokens = userFcmTokenRepository.findActiveTokensByUserId(user.get().getId());
            for (UserFcmToken token : tokens) {
                firebaseNotificationService.sendPromotionalNotification(
                        "Welcome gift!",
                        "You've received Rs. " + amount.stripTrailingZeros().toPlainString()
                                + " as a welcome bonus. We'll send it to your registered mobile number via UPI shortly.",
                        token.getFcmToken());
            }
        } catch (Exception e) {
            // A missed push must never break registration or the bonus grant itself.
            log.warn("Failed to send signup-bonus push notification for {}: {}", mobileNumber, e.getMessage());
        }
    }

    public Optional<SignupBonus> findByMobileNumber(String mobileNumber) {
        return signupBonusRepository.findByMobileNumber(mobileNumber);
    }

    public Page<SignupBonus> listUnpaid(Pageable pageable) {
        return signupBonusRepository.findByStatusOrderByCreatedAtAsc(SignupBonus.Status.UNPAID, pageable);
    }

    @Transactional
    public SignupBonus markPaid(Long id, String payoutReference, String processedBy) {
        SignupBonus bonus = signupBonusRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Signup bonus not found: " + id));
        if (bonus.getStatus() != SignupBonus.Status.UNPAID) {
            throw new IllegalStateException("Signup bonus is not pending payout (status=" + bonus.getStatus() + ")");
        }
        bonus.setStatus(SignupBonus.Status.PAID);
        bonus.setPayoutReference(payoutReference);
        bonus.setProcessedBy(processedBy);
        bonus.setPaidAt(LocalDateTime.now());
        return signupBonusRepository.save(bonus);
    }

    /**
     * Ticks every 5 minutes but only actually sends a reminder once the admin-configured
     * interval (default 60 min) has elapsed since the last one - lets the interval be
     * changed at runtime via settings without touching the fixed Spring schedule itself.
     */
    @Scheduled(fixedRate = 5 * 60 * 1000)
    public void remindAdminsOfPendingPayouts() {
        if (!isEnabled()) return;

        long unpaidCount = signupBonusRepository.findByStatusOrderByCreatedAtAsc(
                SignupBonus.Status.UNPAID, org.springframework.data.domain.PageRequest.of(0, 1)).getTotalElements();
        if (unpaidCount == 0) return;

        String lastSentRaw = settingService.getSettingValue(LAST_REMINDER_AT_KEY, null);
        if (lastSentRaw != null) {
            LocalDateTime lastSent = LocalDateTime.parse(lastSentRaw, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
            if (Duration.between(lastSent, LocalDateTime.now()).toMinutes() < getAdminReminderIntervalMinutes()) {
                return;
            }
        }

        try {
            List<User> admins = userRepository.findByRole(User.UserRole.ADMIN);
            admins.addAll(userRepository.findByRole(User.UserRole.SUPER_ADMIN));
            for (User admin : admins) {
                List<UserFcmToken> tokens = userFcmTokenRepository.findActiveTokensByUserId(admin.getId());
                for (UserFcmToken token : tokens) {
                    firebaseNotificationService.sendPromotionalNotification(
                            "Welcome bonus payouts pending",
                            unpaidCount + " customer(s) are waiting for their welcome bonus UPI payout.",
                            token.getFcmToken());
                }
            }
            log.info("Sent admin reminder for {} pending signup bonus payouts", unpaidCount);
        } catch (Exception e) {
            log.warn("Failed to send admin signup-bonus reminder: {}", e.getMessage());
        } finally {
            settingService.saveSetting(LAST_REMINDER_AT_KEY,
                    LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME),
                    "Internal - last time the admin welcome-bonus payout reminder was sent.");
        }
    }
}
