package com.shopmanagement.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Set;

/**
 * Shared moderation rules for renewing and editing a post.
 *
 * Every post module declares its own PostStatus enum, so this works on the status name rather
 * than the enum type. The names are identical across all of them.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PostModerationPolicy {

    private final SettingService settingService;

    /**
     * Statuses that represent an administrator's decision to take a post down. A seller must not
     * be able to undo any of them from the app, which renewing a post used to do: renew set the
     * status straight back to APPROVED with no check, so a rejected or flagged listing could be
     * put back in front of customers by its own owner. Free renewal would have made that a
     * one-tap bypass of moderation.
     */
    private static final Set<String> NOT_RENEWABLE =
            Set.of("DELETED", "REMOVED", "REJECTED", "FLAGGED", "HOLD", "HIDDEN");

    public void assertRenewable(Enum<?> currentStatus) {
        if (currentStatus != null && NOT_RENEWABLE.contains(currentStatus.name())) {
            log.warn("Blocked renewal of a post in status {}", currentStatus.name());
            throw new RuntimeException(
                    "This post cannot be renewed because it was removed by an administrator. Please contact support.");
        }
    }

    private boolean isAutoApproved(String settingPrefix) {
        return Boolean.parseBoolean(
                settingService.getSettingValue(settingPrefix + ".post.auto_approve", "false"));
    }

    /**
     * After a renewal, may the post go straight back to APPROVED?
     * Yes when the module auto-approves anyway, or when the post was already approved and is
     * simply being extended. Anything else goes back through review.
     */
    public boolean renewToApproved(Enum<?> currentStatus, String settingPrefix) {
        return isAutoApproved(settingPrefix)
                || (currentStatus != null && "APPROVED".equals(currentStatus.name()));
    }

    /**
     * After the owner edits their own post, may it stay visible?
     * Only when the module auto-approves new posts, in which case it has already opted out of
     * review and forcing an edited post back to pending just contradicts that. When the module
     * does review posts, an edit still goes back to pending, which is what stops someone getting
     * a harmless post approved and then editing it into something else.
     */
    public boolean editKeepsApproval(String settingPrefix) {
        return isAutoApproved(settingPrefix);
    }
}
