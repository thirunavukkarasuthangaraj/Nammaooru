package com.shopmanagement.controller;

import com.shopmanagement.entity.Customer;
import com.shopmanagement.entity.SignupBonus;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.CustomerRepository;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.service.SignupBonusService;
import com.shopmanagement.common.util.ResponseUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Optional;

/**
 * Welcome-bonus queue for manual UPI payout to a customer's registered
 * mobile number - see SignupBonusService for why this is separate from the
 * shop/delivery-partner Wallet system.
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Slf4j
public class SignupBonusController {

    private final SignupBonusService signupBonusService;
    private final CustomerRepository customerRepository;
    private final UserRepository userRepository;

    /**
     * Read-only status check the Home screen calls once after registration to
     * decide whether to show the "You got a welcome bonus!" banner. The grant
     * itself always happens server-side at registration (CustomerService) -
     * this never creates a bonus, only reports one that already exists, so it
     * can't be abused by an existing customer to self-grant free money.
     */
    @GetMapping("/customer/signup-bonus/mine")
    public ResponseEntity<?> mine(Authentication authentication) {
        String mobileNumber = resolveMobileNumber(authentication);
        if (mobileNumber == null) {
            return ResponseUtil.badRequest("Could not resolve your mobile number");
        }
        return ResponseUtil.success(
                signupBonusService.findByMobileNumber(mobileNumber).orElse(null),
                "Welcome bonus status retrieved");
    }

    private String resolveMobileNumber(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) return null;
        String username = authentication.getName();

        Optional<Customer> customer = customerRepository.findByEmail(username);
        if (customer.isEmpty()) customer = customerRepository.findFirstByMobileNumberOrderByIdAsc(username);
        if (customer.isPresent() && customer.get().getMobileNumber() != null) {
            return customer.get().getMobileNumber();
        }

        Optional<User> user = userRepository.findByUsername(username);
        if (user.isEmpty()) user = userRepository.findByMobileNumber(username);
        return user.map(User::getMobileNumber).orElse(null);
    }

    @GetMapping("/admin/signup-bonuses")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<?> listUnpaid(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        Page<SignupBonus> bonuses = signupBonusService.listUnpaid(PageRequest.of(page, size));
        return ResponseUtil.success(bonuses, "Pending welcome bonuses retrieved");
    }

    @PostMapping("/admin/signup-bonuses/{id}/mark-paid")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<?> markPaid(
            @PathVariable Long id,
            @RequestBody MarkPaidRequest request,
            Authentication authentication) {
        SignupBonus bonus = signupBonusService.markPaid(id, request.payoutReference(), authentication.getName());
        return ResponseUtil.success(bonus, "Welcome bonus marked as paid");
    }

    @GetMapping("/admin/signup-bonuses/amount")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<?> getAmount() {
        return ResponseUtil.success(signupBonusService.getBonusAmount(), "Welcome bonus amount retrieved");
    }

    @PostMapping("/admin/signup-bonuses/amount")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<?> setAmount(@RequestBody AmountRequest request) {
        signupBonusService.setBonusAmount(request.amount());
        return ResponseUtil.success(request.amount(), "Welcome bonus amount updated");
    }

    @GetMapping("/admin/signup-bonuses/config")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<?> getConfig() {
        return ResponseUtil.success(new ConfigResponse(
                signupBonusService.isEnabled(),
                signupBonusService.getBonusAmount(),
                signupBonusService.getAdminReminderIntervalMinutes()
        ), "Welcome bonus config retrieved");
    }

    @PostMapping("/admin/signup-bonuses/enabled")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<?> setEnabled(@RequestBody EnabledRequest request) {
        signupBonusService.setEnabled(request.enabled());
        return ResponseUtil.success(request.enabled(), "Welcome bonus feature " + (request.enabled() ? "enabled" : "disabled"));
    }

    @PostMapping("/admin/signup-bonuses/reminder-interval")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<?> setReminderInterval(@RequestBody ReminderIntervalRequest request) {
        signupBonusService.setAdminReminderIntervalMinutes(request.minutes());
        return ResponseUtil.success(request.minutes(), "Admin reminder interval updated");
    }

    public record MarkPaidRequest(String payoutReference) {}
    public record AmountRequest(BigDecimal amount) {}
    public record EnabledRequest(boolean enabled) {}
    public record ReminderIntervalRequest(int minutes) {}
    public record ConfigResponse(boolean enabled, BigDecimal amount, int reminderIntervalMinutes) {}
}
