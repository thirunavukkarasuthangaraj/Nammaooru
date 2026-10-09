package com.shopmanagement.service;

import com.shopmanagement.dto.notification.NotificationRequest;
import com.shopmanagement.entity.*;
import com.shopmanagement.entity.MarketplacePost.PostStatus;
import com.shopmanagement.entity.Notification;
import com.shopmanagement.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class PostExpirySchedulerService {

    private final LocalShopPostRepository localShopPostRepository;
    private final MarketplacePostRepository marketplacePostRepository;
    private final FarmerProductRepository farmerProductRepository;
    private final LabourPostRepository labourPostRepository;
    private final TravelPostRepository travelPostRepository;
    private final ParcelServicePostRepository parcelServicePostRepository;
    private final RealEstatePostRepository realEstatePostRepository;
    private final RentalPostRepository rentalPostRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final FileUploadService fileUploadService;
    private final SettingService settingService;

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd MMM yyyy");

    // Active statuses for each post type (statuses that should receive reminders / be cleaned up)
    private static final List<MarketplacePost.PostStatus> MP_ACTIVE = List.of(
            MarketplacePost.PostStatus.PENDING_APPROVAL, MarketplacePost.PostStatus.APPROVED);
    private static final List<FarmerProduct.PostStatus> FP_ACTIVE = List.of(
            FarmerProduct.PostStatus.PENDING_APPROVAL, FarmerProduct.PostStatus.APPROVED);
    private static final List<LabourPost.PostStatus> LP_ACTIVE = List.of(
            LabourPost.PostStatus.PENDING_APPROVAL, LabourPost.PostStatus.APPROVED);
    private static final List<TravelPost.PostStatus> TP_ACTIVE = List.of(
            TravelPost.PostStatus.PENDING_APPROVAL, TravelPost.PostStatus.APPROVED);
    private static final List<ParcelServicePost.PostStatus> PP_ACTIVE = List.of(
            ParcelServicePost.PostStatus.PENDING_APPROVAL, ParcelServicePost.PostStatus.APPROVED);
    private static final List<RealEstatePost.PostStatus> RE_ACTIVE = List.of(
            RealEstatePost.PostStatus.PENDING_APPROVAL, RealEstatePost.PostStatus.APPROVED);
    private static final List<RentalPost.PostStatus> RN_ACTIVE = List.of(
            RentalPost.PostStatus.PENDING_APPROVAL, RentalPost.PostStatus.APPROVED);
    private static final List<LocalShopPost.PostStatus> LS_ACTIVE = List.of(
            LocalShopPost.PostStatus.PENDING_APPROVAL, LocalShopPost.PostStatus.APPROVED);

    /**
     * Auto-renew is the "everything is free" mode: posts keep themselves alive instead of
     * expiring and asking the seller to pay. While it is on, the reminder and cleanup jobs
     * below stand down, because there is nothing for the seller to act on and deleting their
     * post would be pure data loss. Flip the setting to false to go back to paid renewals.
     */
    private boolean isAutoRenewEnabled() {
        return Boolean.parseBoolean(
                settingService.getSettingValue("post.auto_renew.enabled", "true"));
    }

    private int durationDaysFor(String settingKey) {
        try {
            return Integer.parseInt(settingService.getSettingValue(settingKey, "30"));
        } catch (NumberFormatException e) {
            log.warn("Invalid duration setting {}, falling back to 30 days", settingKey);
            return 30;
        }
    }

    /**
     * Daily at 2:30 AM, ahead of the 3 AM cleanup: extend every post that is expiring soon or
     * has already lapsed. A module configured with 0 duration means "never expires", so its
     * posts have their expiry cleared outright — that is also what rescues older posts which
     * were created back when that module still had a 30 day window.
     */
    @Scheduled(cron = "0 30 2 * * *")
    @Transactional
    public void autoRenewExpiringPosts() {
        if (!isAutoRenewEnabled()) {
            log.debug("Auto-renew is disabled; skipping auto-renew job");
            return;
        }
        try {
            int lookaheadDays = Integer.parseInt(
                    settingService.getSettingValue("post.expiry.reminder_days_before", "3"));
            LocalDateTime now = LocalDateTime.now();
            LocalDateTime horizon = now.plusDays(lookaheadDays);

            log.info("Running post auto-renew job: renewing posts with expiry before {}", horizon);

            int renewed = 0;

            int mpDays = durationDaysFor("marketplace.post.duration_days");
            for (MarketplacePost post : marketplacePostRepository.findByValidToBeforeAndStatusIn(horizon, MP_ACTIVE)) {
                post.setValidTo(mpDays > 0 ? now.plusDays(mpDays) : null);
                post.setExpiryReminderSent(false);
                marketplacePostRepository.save(post);
                renewed++;
            }

            int fpDays = durationDaysFor("farmer.post.duration_days");
            for (FarmerProduct post : farmerProductRepository.findByValidToBeforeAndStatusIn(horizon, FP_ACTIVE)) {
                post.setValidTo(fpDays > 0 ? now.plusDays(fpDays) : null);
                post.setExpiryReminderSent(false);
                farmerProductRepository.save(post);
                renewed++;
            }

            int lpDays = durationDaysFor("labour.post.duration_days");
            for (LabourPost post : labourPostRepository.findByValidToBeforeAndStatusIn(horizon, LP_ACTIVE)) {
                post.setValidTo(lpDays > 0 ? now.plusDays(lpDays) : null);
                post.setExpiryReminderSent(false);
                labourPostRepository.save(post);
                renewed++;
            }

            int tpDays = durationDaysFor("travel.post.duration_days");
            for (TravelPost post : travelPostRepository.findByValidToBeforeAndStatusIn(horizon, TP_ACTIVE)) {
                post.setValidTo(tpDays > 0 ? now.plusDays(tpDays) : null);
                post.setExpiryReminderSent(false);
                travelPostRepository.save(post);
                renewed++;
            }

            int ppDays = durationDaysFor("parcel.post.duration_days");
            for (ParcelServicePost post : parcelServicePostRepository.findByValidToBeforeAndStatusIn(horizon, PP_ACTIVE)) {
                post.setValidTo(ppDays > 0 ? now.plusDays(ppDays) : null);
                post.setExpiryReminderSent(false);
                parcelServicePostRepository.save(post);
                renewed++;
            }

            int reDays = durationDaysFor("realestate.post.duration_days");
            for (RealEstatePost post : realEstatePostRepository.findByValidToBeforeAndStatusIn(horizon, RE_ACTIVE)) {
                post.setValidTo(reDays > 0 ? now.plusDays(reDays) : null);
                post.setExpiryReminderSent(false);
                realEstatePostRepository.save(post);
                renewed++;
            }

            int rnDays = durationDaysFor("rental.post.duration_days");
            for (RentalPost post : rentalPostRepository.findByValidToBeforeAndStatusIn(horizon, RN_ACTIVE)) {
                post.setValidTo(rnDays > 0 ? now.plusDays(rnDays) : null);
                post.setExpiryReminderSent(false);
                rentalPostRepository.save(post);
                renewed++;
            }

            int lsDays = durationDaysFor("local_shops.post.duration_days");
            for (LocalShopPost post : localShopPostRepository.findByValidToBeforeAndStatusIn(horizon, LS_ACTIVE)) {
                post.setValidTo(lsDays > 0 ? now.plusDays(lsDays) : null);
                post.setExpiryReminderSent(false);
                localShopPostRepository.save(post);
                renewed++;
            }

            log.info("Post auto-renew job completed: {} posts renewed", renewed);
        } catch (Exception e) {
            log.error("Error in post auto-renew scheduler", e);
        }
    }

    /**
     * Daily at 9 AM: Send expiry reminders for posts expiring within N days
     */
    @Scheduled(cron = "0 0 9 * * *")
    @Transactional
    public void sendExpiryReminders() {
        if (isAutoRenewEnabled()) {
            log.debug("Auto-renew is enabled; skipping expiry reminders");
            return;
        }
        try {
            int reminderDays = Integer.parseInt(
                    settingService.getSettingValue("post.expiry.reminder_days_before", "3"));
            LocalDateTime now = LocalDateTime.now();
            LocalDateTime reminderCutoff = now.plusDays(reminderDays);

            log.info("Running post expiry reminder job: checking posts expiring between {} and {}", now, reminderCutoff);

            int count = 0;

            // Marketplace posts
            for (MarketplacePost post : marketplacePostRepository
                    .findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(now, reminderCutoff, MP_ACTIVE)) {
                sendReminderForPost(post.getSellerUserId(), post.getTitle(), "Marketplace", post.getId(), post.getValidTo());
                post.setExpiryReminderSent(true);
                marketplacePostRepository.save(post);
                count++;
            }

            // Farmer products
            for (FarmerProduct post : farmerProductRepository
                    .findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(now, reminderCutoff, FP_ACTIVE)) {
                sendReminderForPost(post.getSellerUserId(), post.getTitle(), "Farm Products", post.getId(), post.getValidTo());
                post.setExpiryReminderSent(true);
                farmerProductRepository.save(post);
                count++;
            }

            // Labour posts
            for (LabourPost post : labourPostRepository
                    .findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(now, reminderCutoff, LP_ACTIVE)) {
                sendReminderForPost(post.getSellerUserId(), post.getName(), "Labours", post.getId(), post.getValidTo());
                post.setExpiryReminderSent(true);
                labourPostRepository.save(post);
                count++;
            }

            // Travel posts
            for (TravelPost post : travelPostRepository
                    .findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(now, reminderCutoff, TP_ACTIVE)) {
                sendReminderForPost(post.getSellerUserId(), post.getTitle(), "Travels", post.getId(), post.getValidTo());
                post.setExpiryReminderSent(true);
                travelPostRepository.save(post);
                count++;
            }

            // Parcel service posts
            for (ParcelServicePost post : parcelServicePostRepository
                    .findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(now, reminderCutoff, PP_ACTIVE)) {
                sendReminderForPost(post.getSellerUserId(), post.getServiceName(), "Parcel Service", post.getId(), post.getValidTo());
                post.setExpiryReminderSent(true);
                parcelServicePostRepository.save(post);
                count++;
            }

            // Real estate posts
            for (RealEstatePost post : realEstatePostRepository
                    .findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(now, reminderCutoff, RE_ACTIVE)) {
                sendReminderForPost(post.getOwnerUserId(), post.getTitle(), "Real Estate", post.getId(), post.getValidTo());
                post.setExpiryReminderSent(true);
                realEstatePostRepository.save(post);
                count++;
            }

            // Rental posts
            for (RentalPost post : rentalPostRepository
                    .findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(now, reminderCutoff, RN_ACTIVE)) {
                sendReminderForPost(post.getSellerUserId(), post.getTitle(), "Rental", post.getId(), post.getValidTo());
                post.setExpiryReminderSent(true);
                rentalPostRepository.save(post);
                count++;
            }

            // Local shop posts
            for (LocalShopPost post : localShopPostRepository
                    .findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(now, reminderCutoff, LS_ACTIVE)) {
                sendReminderForPost(post.getSellerUserId(), post.getShopName(), "Local Shops", post.getId(), post.getValidTo());
                post.setExpiryReminderSent(true);
                localShopPostRepository.save(post);
                count++;
            }

            log.info("Post expiry reminder job completed: {} reminders sent", count);
        } catch (Exception e) {
            log.error("Error in post expiry reminder scheduler", e);
        }
    }

    /**
     * Daily at 3 AM: Delete expired posts past grace period + their images
     */
    @Scheduled(cron = "0 0 3 * * *")
    @Transactional
    public void cleanupExpiredPosts() {
        // This job hard-deletes posts AND their uploaded image files; there is no undo.
        // While posts renew themselves for free there is nothing a seller could have done to
        // save their listing, so deleting it would destroy their data for no reason.
        if (isAutoRenewEnabled()) {
            log.info("Auto-renew is enabled; skipping expired post cleanup (no posts will be deleted)");
            return;
        }
        try {
            int gracePeriodDays = Integer.parseInt(
                    settingService.getSettingValue("post.expiry.grace_period_days", "7"));
            LocalDateTime cutoff = LocalDateTime.now().minusDays(gracePeriodDays);

            log.info("Running expired post cleanup job: deleting posts expired before {}", cutoff);

            int deleted = 0;

            // Marketplace posts
            for (MarketplacePost post : marketplacePostRepository.findByValidToBeforeAndStatusIn(cutoff, MP_ACTIVE)) {
                deleteImage(post.getImageUrl());
                marketplacePostRepository.delete(post);
                deleted++;
                log.info("Deleted expired marketplace post: id={}, title={}", post.getId(), post.getTitle());
            }

            // Farmer products
            for (FarmerProduct post : farmerProductRepository.findByValidToBeforeAndStatusIn(cutoff, FP_ACTIVE)) {
                deleteImages(post.getImageUrls());
                farmerProductRepository.delete(post);
                deleted++;
                log.info("Deleted expired farmer product: id={}, title={}", post.getId(), post.getTitle());
            }

            // Labour posts
            for (LabourPost post : labourPostRepository.findByValidToBeforeAndStatusIn(cutoff, LP_ACTIVE)) {
                deleteImages(post.getImageUrls());
                labourPostRepository.delete(post);
                deleted++;
                log.info("Deleted expired labour post: id={}, name={}", post.getId(), post.getName());
            }

            // Travel posts
            for (TravelPost post : travelPostRepository.findByValidToBeforeAndStatusIn(cutoff, TP_ACTIVE)) {
                deleteImages(post.getImageUrls());
                travelPostRepository.delete(post);
                deleted++;
                log.info("Deleted expired travel post: id={}, title={}", post.getId(), post.getTitle());
            }

            // Parcel service posts
            for (ParcelServicePost post : parcelServicePostRepository.findByValidToBeforeAndStatusIn(cutoff, PP_ACTIVE)) {
                deleteImages(post.getImageUrls());
                parcelServicePostRepository.delete(post);
                deleted++;
                log.info("Deleted expired parcel service post: id={}, serviceName={}", post.getId(), post.getServiceName());
            }

            // Real estate posts
            for (RealEstatePost post : realEstatePostRepository.findByValidToBeforeAndStatusIn(cutoff, RE_ACTIVE)) {
                deleteImages(post.getImageUrls());
                deleteImage(post.getVideoUrl());
                realEstatePostRepository.delete(post);
                deleted++;
                log.info("Deleted expired real estate post: id={}, title={}", post.getId(), post.getTitle());
            }

            // Rental posts
            for (RentalPost post : rentalPostRepository.findByValidToBeforeAndStatusIn(cutoff, RN_ACTIVE)) {
                deleteImages(post.getImageUrls());
                rentalPostRepository.delete(post);
                deleted++;
                log.info("Deleted expired rental post: id={}, title={}", post.getId(), post.getTitle());
            }

            // Local shop posts
            for (LocalShopPost post : localShopPostRepository.findByValidToBeforeAndStatusIn(cutoff, LS_ACTIVE)) {
                deleteImages(post.getImageUrls());
                localShopPostRepository.delete(post);
                deleted++;
                log.info("Deleted expired local shop post: id={}, shopName={}", post.getId(), post.getShopName());
            }

            log.info("Expired post cleanup job completed: {} posts deleted", deleted);
        } catch (Exception e) {
            log.error("Error in expired post cleanup scheduler", e);
        }
    }

    // ---- Helper methods ----

    private void sendReminderForPost(Long userId, String postTitle, String category, Long postId, LocalDateTime validTo) {
        try {
            User user = userRepository.findById(userId).orElse(null);
            if (user == null) return;

            String expiryDate = validTo != null ? validTo.format(DATE_FMT) : "soon";

            // Push notification
            NotificationRequest request = NotificationRequest.builder()
                    .title("Post Expiring Soon")
                    .message("Your " + category + " post '" + postTitle + "' expires on " + expiryDate + ". Renew it to keep it visible.")
                    .type(Notification.NotificationType.WARNING)
                    .priority(Notification.NotificationPriority.HIGH)
                    .recipientId(userId)
                    .recipientType(Notification.RecipientType.USER)
                    .referenceId(postId)
                    .referenceType("POST_EXPIRY")
                    .actionText("Renew Post")
                    .icon("timer")
                    .category(category.toUpperCase().replace(" ", "_"))
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);

            // Email
            if (user.getEmail() != null) {
                emailService.sendPostExpiryReminderEmail(
                        user.getEmail(), user.getFullName(), postTitle, category, expiryDate);
            }
        } catch (Exception e) {
            log.error("Failed to send expiry reminder for post: id={}, title={}", postId, postTitle, e);
        }
    }

    private void deleteImage(String imageUrl) {
        if (imageUrl != null && !imageUrl.isBlank()) {
            fileUploadService.deleteFile(imageUrl);
        }
    }

    private void deleteImages(String imageUrls) {
        if (imageUrls != null && !imageUrls.isBlank()) {
            for (String url : imageUrls.split(",")) {
                String trimmed = url.trim();
                if (!trimmed.isEmpty()) {
                    fileUploadService.deleteFile(trimmed);
                }
            }
        }
    }
}
