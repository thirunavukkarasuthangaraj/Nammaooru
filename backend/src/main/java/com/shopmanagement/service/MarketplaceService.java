package com.shopmanagement.service;

import com.shopmanagement.dto.notification.NotificationRequest;
import com.shopmanagement.entity.MarketplacePost;
import com.shopmanagement.entity.MarketplacePost.PostStatus;
import com.shopmanagement.entity.Notification;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.MarketplacePostRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class MarketplaceService {

    private final MarketplacePostRepository marketplacePostRepository;
    private final UserRepository userRepository;
    private final FileUploadService fileUploadService;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final SettingService settingService;
    private final UserPostLimitService userPostLimitService;
    private final ObjectMapper objectMapper;

    @Transactional
    public MarketplacePost createPost(String title, String description, BigDecimal price,
                                       String phone, String category, String location,
                                       MultipartFile image, MultipartFile voice,
                                       String username) throws IOException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Check post limit (user-specific override > global FeatureConfig limit)
        int postLimit = userPostLimitService.getEffectiveLimit(user.getId(), "MARKETPLACE");
        if (postLimit > 0) {
            List<MarketplacePost.PostStatus> activeStatuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED);
            long activeCount = marketplacePostRepository.countBySellerUserIdAndStatusIn(user.getId(), activeStatuses);
            if (activeCount >= postLimit) {
                throw new RuntimeException("You have reached the maximum limit of " + postLimit + " active marketplace listings");
            }
        }

        String imageUrl = null;
        if (image != null && !image.isEmpty()) {
            imageUrl = fileUploadService.uploadFile(image, "marketplace");
        }

        String voiceUrl = null;
        if (voice != null && !voice.isEmpty()) {
            voiceUrl = fileUploadService.uploadVoiceFile(voice, "marketplace/voice");
        }

        boolean autoApprove = Boolean.parseBoolean(
                settingService.getSettingValue("marketplace.post.auto_approve", "false"));

        MarketplacePost post = MarketplacePost.builder()
                .title(title)
                .description(description)
                .price(price)
                .imageUrl(imageUrl)
                .voiceUrl(voiceUrl)
                .sellerUserId(user.getId())
                .sellerName(user.getFullName())
                .sellerPhone(phone)
                .category(category)
                .location(location)
                .status(autoApprove ? PostStatus.APPROVED : PostStatus.PENDING_APPROVAL)
                .build();

        MarketplacePost saved = marketplacePostRepository.save(post);
        log.info("Marketplace post created: id={}, title={}, seller={}, autoApproved={}", saved.getId(), title, username, autoApprove);

        if (autoApprove) {
            notifySellerPostStatus(saved, "Your post '" + saved.getTitle() + "' has been auto-approved and is now visible to others.");
            notifyCustomersNewPost(saved);
        } else {
            // Notify admins about new post pending approval
            notifyAdminsNewPost(saved);
        }

        return saved;
    }

    @Transactional(readOnly = true)
    public Page<MarketplacePost> getApprovedPosts(Pageable pageable) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();
        LocalDateTime cutoffDate = getCutoffDate();

        if (cutoffDate != null) {
            return marketplacePostRepository.findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, cutoffDate, pageable);
        }
        return marketplacePostRepository.findByStatusInOrderByCreatedAtDesc(visibleStatuses, pageable);
    }

    @Transactional(readOnly = true)
    public Page<MarketplacePost> getApprovedPostsByCategory(String category, Pageable pageable) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();
        LocalDateTime cutoffDate = getCutoffDate();

        if (cutoffDate != null) {
            return marketplacePostRepository.findByStatusInAndCategoryAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, category, cutoffDate, pageable);
        }
        return marketplacePostRepository.findByStatusAndCategoryOrderByCreatedAtDesc(
                PostStatus.APPROVED, category, pageable);
    }

    @Transactional(readOnly = true)
    public List<MarketplacePost> getMyPosts(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return marketplacePostRepository.findBySellerUserIdOrderByCreatedAtDesc(user.getId());
    }

    @Transactional(readOnly = true)
    public Page<MarketplacePost> getPendingPosts(Pageable pageable) {
        return marketplacePostRepository.findByStatusOrderByCreatedAtDesc(PostStatus.PENDING_APPROVAL, pageable);
    }

    @Transactional(readOnly = true)
    public Page<MarketplacePost> getReportedPosts(Pageable pageable) {
        return marketplacePostRepository.findByReportCountGreaterThanOrderByReportCountDesc(0, pageable);
    }

    @Transactional(readOnly = true)
    public Page<MarketplacePost> getAllPostsForAdmin(Pageable pageable) {
        List<PostStatus> statuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED, PostStatus.REJECTED, PostStatus.SOLD);
        return marketplacePostRepository.findByStatusInOrderByCreatedAtDesc(statuses, pageable);
    }

    @Transactional
    public MarketplacePost approvePost(Long id) {
        MarketplacePost post = marketplacePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.APPROVED);
        MarketplacePost saved = marketplacePostRepository.save(post);
        log.info("Marketplace post approved: id={}", id);

        // Notify seller that their post is approved
        notifySellerPostStatus(saved, "Your post '" + saved.getTitle() + "' has been approved and is now visible to others.");
        notifyCustomersNewPost(saved);

        return saved;
    }

    @Transactional
    public MarketplacePost rejectPost(Long id) {
        MarketplacePost post = marketplacePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.REJECTED);
        MarketplacePost saved = marketplacePostRepository.save(post);
        log.info("Marketplace post rejected: id={}", id);

        // Notify seller that their post is rejected
        notifySellerPostStatus(saved, "Your post '" + saved.getTitle() + "' has been rejected by admin.");

        return saved;
    }

    @Transactional
    public MarketplacePost changePostStatus(Long id, String statusStr) {
        MarketplacePost post = marketplacePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        PostStatus newStatus;
        try {
            newStatus = PostStatus.valueOf(statusStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid status: " + statusStr);
        }

        PostStatus oldStatus = post.getStatus();
        post.setStatus(newStatus);
        MarketplacePost saved = marketplacePostRepository.save(post);
        log.info("Marketplace post status changed: id={}, {} -> {}", id, oldStatus, newStatus);

        // Notify seller about status change
        String message = getStatusChangeMessage(saved, newStatus);
        if (message != null) {
            notifySellerPostStatus(saved, message);
        }

        return saved;
    }

    private String getStatusChangeMessage(MarketplacePost post, PostStatus status) {
        switch (status) {
            case APPROVED:
                return "Your post '" + post.getTitle() + "' has been approved and is now visible to others.";
            case REJECTED:
                return "Your post '" + post.getTitle() + "' has been rejected by admin.";
            case HOLD:
                return "Your post '" + post.getTitle() + "' has been put on hold by admin.";
            case HIDDEN:
                return "Your post '" + post.getTitle() + "' has been hidden by admin.";
            case CORRECTION_REQUIRED:
                return "Your post '" + post.getTitle() + "' needs correction. Please update and resubmit.";
            case REMOVED:
                return "Your post '" + post.getTitle() + "' has been removed by admin.";
            default:
                return null;
        }
    }

    @Transactional
    public MarketplacePost markAsSold(Long id, String username) {
        MarketplacePost post = marketplacePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the seller can mark a post as sold");
        }

        post.setStatus(PostStatus.SOLD);
        log.info("Marketplace post marked as sold: id={}", id);
        return marketplacePostRepository.save(post);
    }

    @Transactional
    public void deletePost(Long id, String username, boolean isAdmin) {
        MarketplacePost post = marketplacePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        if (!isAdmin) {
            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            if (!post.getSellerUserId().equals(user.getId())) {
                throw new RuntimeException("Only the seller or admin can delete a post");
            }
        }

        marketplacePostRepository.delete(post);
        log.info("Marketplace post deleted: id={}", id);
    }

    @Transactional(readOnly = true)
    public MarketplacePost getPostById(Long id) {
        return marketplacePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
    }

    // Report feature will be added later
    @Transactional
    public void reportPost(Long postId, String reason, String details, String username) {
        MarketplacePost post = marketplacePostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        // Simple report - just increment count (full report tracking will be added later)
        int newCount = (post.getReportCount() != null ? post.getReportCount() : 0) + 1;
        post.setReportCount(newCount);

        // Auto-flag if reports reach configurable threshold
        int reportThreshold = Integer.parseInt(
                settingService.getSettingValue("marketplace.post.report_threshold", "3"));
        if (newCount >= reportThreshold && post.getStatus() == PostStatus.APPROVED) {
            post.setStatus(PostStatus.FLAGGED);
            log.warn("Marketplace post auto-flagged due to {} reports: id={}, title={}", newCount, postId, post.getTitle());

            // Notify admins about flagged post
            notifyAdminsFlaggedPost(post, newCount);
        }

        marketplacePostRepository.save(post);
        log.info("Marketplace post reported: id={}, reason={}, reportCount={}", postId, reason, newCount);

        notifyOwnerPostReported(post, newCount);
    }

    @Transactional
    public MarketplacePost adminUpdatePost(Long id, Map<String, Object> updates) {
        MarketplacePost post = marketplacePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        if (updates.containsKey("title")) post.setTitle((String) updates.get("title"));
        if (updates.containsKey("description")) post.setDescription((String) updates.get("description"));
        if (updates.containsKey("price")) post.setPrice(updates.get("price") != null ? new java.math.BigDecimal(updates.get("price").toString()) : null);
        if (updates.containsKey("category")) post.setCategory((String) updates.get("category"));
        if (updates.containsKey("location")) post.setLocation((String) updates.get("location"));

        MarketplacePost saved = marketplacePostRepository.save(post);
        log.info("Marketplace post admin-updated: id={}", id);
        return saved;
    }

    // ---- Notification helpers ----

    private List<Long> getAdminUserIds() {
        List<Long> adminIds = new ArrayList<>();
        userRepository.findByRole(User.UserRole.ADMIN)
                .forEach(u -> adminIds.add(u.getId()));
        userRepository.findByRole(User.UserRole.SUPER_ADMIN)
                .forEach(u -> adminIds.add(u.getId()));
        return adminIds;
    }

    private void notifyAdminsNewPost(MarketplacePost post) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("New Marketplace Post")
                    .message("'" + post.getTitle() + "' by " + post.getSellerName() + " is pending approval.")
                    .type(Notification.NotificationType.ANNOUNCEMENT)
                    .priority(Notification.NotificationPriority.HIGH)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("MARKETPLACE_POST")
                    .actionUrl("/admin/marketplace")
                    .actionText("Review Post")
                    .icon("shopping-bag")
                    .category("MARKETPLACE")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for new marketplace post: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to send admin notification for marketplace post: {}", post.getId(), e);
        }
    }

    private void notifySellerPostStatus(MarketplacePost post, String message) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Marketplace Post Update")
                    .message(message)
                    .type(Notification.NotificationType.INFO)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientId(post.getSellerUserId())
                    .recipientType(Notification.RecipientType.USER)
                    .referenceId(post.getId())
                    .referenceType("MARKETPLACE_POST")
                    .actionUrl("/marketplace/my-posts")
                    .actionText("View Post")
                    .icon("shopping-bag")
                    .category("MARKETPLACE")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Seller notification sent for marketplace post: id={}, seller={}", post.getId(), post.getSellerUserId());
        } catch (Exception e) {
            log.error("Failed to send seller notification for marketplace post: {}", post.getId(), e);
        }
    }

    private List<PostStatus> getVisibleStatuses() {
        String json = settingService.getSettingValue("marketplace.post.visible_statuses", "[\"APPROVED\"]");
        try {
            List<String> statusStrings = objectMapper.readValue(json, new TypeReference<List<String>>() {});
            return statusStrings.stream()
                    .map(s -> PostStatus.valueOf(s.toUpperCase()))
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("Failed to parse visible_statuses setting, defaulting to APPROVED: {}", e.getMessage());
            return List.of(PostStatus.APPROVED);
        }
    }

    private LocalDateTime getCutoffDate() {
        int durationDays = Integer.parseInt(
                settingService.getSettingValue("marketplace.post.duration_days", "30"));
        if (durationDays <= 0) {
            return null; // no expiry
        }
        return LocalDateTime.now().minusDays(durationDays);
    }

    private void notifyCustomersNewPost(MarketplacePost post) {
        try {
            // Use seller's location (MarketplacePost has no lat/lng)
            User seller = userRepository.findById(post.getSellerUserId()).orElse(null);
            if (seller == null || seller.getCurrentLatitude() == null || seller.getCurrentLongitude() == null) {
                log.info("Skipping location-based notification for marketplace post {}: no seller location", post.getId());
                return;
            }

            double radiusKm = Double.parseDouble(
                    settingService.getSettingValue("notification.radius_km", "50"));

            List<User> nearbyCustomers = userRepository.findNearbyCustomers(
                    seller.getCurrentLatitude(), seller.getCurrentLongitude(), radiusKm);
            if (nearbyCustomers.isEmpty()) {
                log.info("No nearby customers found for marketplace post notification: id={}", post.getId());
                return;
            }

            List<Long> recipientIds = nearbyCustomers.stream()
                    .map(User::getId)
                    .collect(Collectors.toList());

            NotificationRequest request = NotificationRequest.builder()
                    .title("New Marketplace Listing!")
                    .message(post.getTitle() + " - Check it out on NammaOoru")
                    .type(Notification.NotificationType.PROMOTION)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientType(Notification.RecipientType.ALL_CUSTOMERS)
                    .sendPush(true)
                    .sendEmail(false)
                    .build();

            notificationService.sendNotificationToUsers(request, recipientIds);
            log.info("New marketplace post notification sent to {} nearby customers", recipientIds.size());
        } catch (Exception e) {
            log.error("Failed to send new post notification to customers for marketplace post: {}", post.getId(), e);
        }
    }

    private void notifyOwnerPostReported(MarketplacePost post, int reportCount) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Your post has been reported")
                    .message("Your post \"" + post.getTitle() + "\" has received " + reportCount + " report(s). Please review it.")
                    .type(Notification.NotificationType.WARNING)
                    .priority(Notification.NotificationPriority.HIGH)
                    .recipientId(post.getSellerUserId())
                    .recipientType(Notification.RecipientType.USER)
                    .referenceId(post.getId())
                    .referenceType("POST_REPORT")
                    .sendPush(true)
                    .sendEmail(false)
                    .build();

            notificationService.createNotification(request);

            // Send email to post owner
            User owner = userRepository.findById(post.getSellerUserId()).orElse(null);
            if (owner != null && owner.getEmail() != null) {
                emailService.sendPostReportedEmail(owner.getEmail(), owner.getFullName(),
                        post.getTitle(), "Marketplace", reportCount);
            }

            log.info("Post owner notified about report for marketplace post: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to notify post owner about report for marketplace post: {}", post.getId(), e);
        }
    }

    @Transactional
    public MarketplacePost toggleFeatured(Long postId) {
        MarketplacePost post = marketplacePostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setFeatured(!Boolean.TRUE.equals(post.getFeatured()));
        MarketplacePost saved = marketplacePostRepository.save(post);
        log.info("Marketplace post featured toggled: id={}, featured={}", postId, saved.getFeatured());
        return saved;
    }

    private void notifyAdminsFlaggedPost(MarketplacePost post, int reportCount) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("Marketplace Post Flagged")
                    .message("'" + post.getTitle() + "' has been auto-flagged with " + reportCount + " reports. Please review.")
                    .type(Notification.NotificationType.WARNING)
                    .priority(Notification.NotificationPriority.URGENT)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("MARKETPLACE_POST")
                    .actionUrl("/admin/marketplace")
                    .actionText("Review Post")
                    .icon("alert-triangle")
                    .category("MARKETPLACE")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for flagged marketplace post: id={}, reports={}", post.getId(), reportCount);
        } catch (Exception e) {
            log.error("Failed to send admin notification for flagged post: {}", post.getId(), e);
        }
    }
}
