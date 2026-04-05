package com.shopmanagement.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shopmanagement.dto.notification.NotificationRequest;
import com.shopmanagement.entity.LocalShopPost;
import com.shopmanagement.entity.LocalShopPost.ShopCategory;
import com.shopmanagement.entity.LocalShopPost.PostStatus;
import com.shopmanagement.entity.Notification;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.LocalShopPostRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class LocalShopPostService {

    private final LocalShopPostRepository localShopPostRepository;
    private final UserRepository userRepository;
    private final FileUploadService fileUploadService;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final SettingService settingService;
    private final UserPostLimitService userPostLimitService;
    private final PostPaymentService postPaymentService;
    private final GlobalPostLimitService globalPostLimitService;
    private final ObjectMapper objectMapper;
    private final PostSubscriptionService postSubscriptionService;

    @Transactional
    public LocalShopPost createPost(String shopName, String phone, String categoryStr,
                                    String address, String timings, String description,
                                    List<MultipartFile> images, String username,
                                    BigDecimal latitude, BigDecimal longitude,
                                    Long paidTokenId, boolean isBanner) throws IOException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        globalPostLimitService.checkGlobalPostLimit(user.getId(), paidTokenId);

        int postLimit = userPostLimitService.getEffectiveLimit(user.getId(), "LOCAL_SHOPS");
        if (postLimit > 0) {
            List<PostStatus> activeStatuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED);
            long activeCount = localShopPostRepository.countBySellerUserIdAndStatusIn(user.getId(), activeStatuses);
            if (activeCount >= postLimit) {
                if (paidTokenId == null) {
                    throw new RuntimeException("LIMIT_REACHED");
                }
                if (!postPaymentService.hasValidToken(paidTokenId, user.getId())) {
                    throw new RuntimeException("Invalid or expired payment token");
                }
            }
        }

        ShopCategory category;
        try {
            category = ShopCategory.valueOf(categoryStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid shop category: " + categoryStr);
        }

        String imageUrls = null;
        if (images != null && !images.isEmpty()) {
            List<String> uploadedUrls = new ArrayList<>();
            for (MultipartFile image : images) {
                if (image != null && !image.isEmpty()) {
                    uploadedUrls.add(fileUploadService.uploadFile(image, "local-shops"));
                }
            }
            if (!uploadedUrls.isEmpty()) {
                imageUrls = String.join(",", uploadedUrls);
            }
        }

        boolean autoApprove = Boolean.parseBoolean(
                settingService.getSettingValue("local_shops.post.auto_approve", "false"));

        LocalShopPost post = LocalShopPost.builder()
                .shopName(shopName)
                .phone(phone)
                .category(category)
                .address(address)
                .timings(timings)
                .description(description)
                .imageUrls(imageUrls)
                .latitude(latitude)
                .longitude(longitude)
                .sellerUserId(user.getId())
                .sellerName(user.getFullName())
                .status(autoApprove ? PostStatus.APPROVED : PostStatus.PENDING_APPROVAL)
                .isPaid(paidTokenId != null)
                .featured(isBanner)
                .build();

        int durationDays = Integer.parseInt(
                settingService.getSettingValue("local_shops.post.duration_days", "60"));
        post.setValidFrom(LocalDateTime.now());
        if (durationDays > 0) {
            post.setValidTo(LocalDateTime.now().plusDays(durationDays));
        }

        if (paidTokenId == null) {
            localShopPostRepository.findTopBySellerUserIdAndStatusOrderByUpdatedAtDesc(
                    user.getId(), PostStatus.DELETED).ifPresent(deleted -> {
                if (deleted.getValidTo() != null && deleted.getValidTo().isAfter(LocalDateTime.now())) {
                    post.setValidTo(deleted.getValidTo());
                }
            });
        }

        LocalShopPost saved = localShopPostRepository.save(post);

        if (paidTokenId != null) {
            postPaymentService.consumeToken(paidTokenId, user.getId(), saved.getId());
        }

        log.info("Local shop post created: id={}, name={}, category={}, poster={}, autoApproved={}, paid={}",
                saved.getId(), shopName, category, username, autoApprove, paidTokenId != null);

        if (autoApprove) {
            notifySellerPostStatus(saved, "Your shop listing for '" + saved.getShopName() + "' has been auto-approved and is now visible to others.");
            notifyCustomersNewPost(saved);
        } else {
            notifyAdminsNewPost(saved);
        }

        return saved;
    }

    @Transactional(readOnly = true)
    public Page<LocalShopPost> searchByAddress(String search, Pageable pageable) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();
        return localShopPostRepository.findByStatusInAndAddressContainingIgnoreCaseOrderByCreatedAtDesc(
                visibleStatuses, search, pageable);
    }

    @Transactional(readOnly = true)
    public Page<LocalShopPost> getApprovedPosts(Pageable pageable, Double lat, Double lng, Double radiusKm) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();

        if (lat != null && lng != null) {
            double radius = (radiusKm != null) ? radiusKm : Double.parseDouble(settingService.getSettingValue("post.default_radius_km", "10"));
            String[] statuses = visibleStatuses.stream().map(Enum::name).toArray(String[]::new);
            int limit = pageable.getPageSize();
            int offset = (int) pageable.getOffset();
            List<LocalShopPost> posts = localShopPostRepository.findNearbyPosts(statuses, lat, lng, radius, limit, offset);
            long total = localShopPostRepository.countNearbyPosts(statuses, lat, lng, radius);
            return new PageImpl<>(posts, pageable, total);
        }

        LocalDateTime cutoffDate = getCutoffDate();
        if (cutoffDate != null) {
            return localShopPostRepository.findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, cutoffDate, pageable);
        }
        return localShopPostRepository.findByStatusInOrderByCreatedAtDesc(visibleStatuses, pageable);
    }

    @Transactional(readOnly = true)
    public Page<LocalShopPost> getApprovedPostsByCategory(String categoryStr, Pageable pageable, Double lat, Double lng, Double radiusKm) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();

        ShopCategory category;
        try {
            category = ShopCategory.valueOf(categoryStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid shop category: " + categoryStr);
        }

        if (lat != null && lng != null) {
            double radius = (radiusKm != null) ? radiusKm : Double.parseDouble(settingService.getSettingValue("post.default_radius_km", "10"));
            String[] statuses = visibleStatuses.stream().map(Enum::name).toArray(String[]::new);
            int limit = pageable.getPageSize();
            int offset = (int) pageable.getOffset();
            List<LocalShopPost> posts = localShopPostRepository.findNearbyPostsByCategory(statuses, category.name(), lat, lng, radius, limit, offset);
            long total = localShopPostRepository.countNearbyPostsByCategory(statuses, category.name(), lat, lng, radius);
            return new PageImpl<>(posts, pageable, total);
        }

        LocalDateTime cutoffDate = getCutoffDate();
        if (cutoffDate != null) {
            return localShopPostRepository.findByStatusInAndCategoryAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, category, cutoffDate, pageable);
        }
        return localShopPostRepository.findByStatusInAndCategoryOrderByCreatedAtDesc(visibleStatuses, category, pageable);
    }

    @Transactional(readOnly = true)
    public List<LocalShopPost> getMyPosts(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return localShopPostRepository.findBySellerUserIdAndStatusNotOrderByCreatedAtDesc(user.getId(), PostStatus.DELETED);
    }

    @Transactional(readOnly = true)
    public Page<LocalShopPost> getPendingPosts(Pageable pageable) {
        return localShopPostRepository.findByStatusOrderByCreatedAtDesc(PostStatus.PENDING_APPROVAL, pageable);
    }

    @Transactional(readOnly = true)
    public Page<LocalShopPost> getReportedPosts(Pageable pageable) {
        return localShopPostRepository.findByReportCountGreaterThanOrderByReportCountDesc(0, pageable);
    }

    @Transactional(readOnly = true)
    public Page<LocalShopPost> getAllPostsForAdmin(Pageable pageable, String search) {
        List<PostStatus> statuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED, PostStatus.REJECTED, PostStatus.SOLD);
        if (search != null && !search.trim().isEmpty()) {
            return localShopPostRepository.findByStatusInAndAddressContainingIgnoreCaseOrderByCreatedAtDesc(statuses, search.trim(), pageable);
        }
        return localShopPostRepository.findByStatusInOrderByCreatedAtDesc(statuses, pageable);
    }

    @Transactional(readOnly = true)
    public LocalShopPost getPostById(Long id) {
        return localShopPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
    }

    @Transactional
    public LocalShopPost approvePost(Long id) {
        LocalShopPost post = localShopPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.APPROVED);
        LocalShopPost saved = localShopPostRepository.save(post);
        notifySellerPostStatus(saved, "Your shop listing for '" + saved.getShopName() + "' has been approved and is now visible to others.");
        notifyCustomersNewPost(saved);
        return saved;
    }

    @Transactional
    public LocalShopPost rejectPost(Long id) {
        LocalShopPost post = localShopPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.REJECTED);
        LocalShopPost saved = localShopPostRepository.save(post);
        notifySellerPostStatus(saved, "Your shop listing for '" + saved.getShopName() + "' has been rejected by admin.");
        return saved;
    }

    @Transactional
    public LocalShopPost changePostStatus(Long id, String statusStr) {
        LocalShopPost post = localShopPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        PostStatus newStatus;
        try {
            newStatus = PostStatus.valueOf(statusStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid status: " + statusStr);
        }
        post.setStatus(newStatus);
        LocalShopPost saved = localShopPostRepository.save(post);
        String message = getStatusChangeMessage(saved, newStatus);
        if (message != null) notifySellerPostStatus(saved, message);
        return saved;
    }

    private String getStatusChangeMessage(LocalShopPost post, PostStatus status) {
        switch (status) {
            case APPROVED: return "Your shop listing for '" + post.getShopName() + "' has been approved.";
            case REJECTED: return "Your shop listing for '" + post.getShopName() + "' has been rejected by admin.";
            case HOLD: return "Your shop listing for '" + post.getShopName() + "' has been put on hold by admin.";
            case HIDDEN: return "Your shop listing for '" + post.getShopName() + "' has been hidden by admin.";
            case CORRECTION_REQUIRED: return "Your shop listing for '" + post.getShopName() + "' needs correction. Please update and resubmit.";
            case REMOVED: return "Your shop listing for '" + post.getShopName() + "' has been removed by admin.";
            default: return null;
        }
    }

    @Transactional
    public LocalShopPost markAsUnavailable(Long id, String username) {
        LocalShopPost post = localShopPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the poster can mark a listing as closed");
        }
        post.setStatus(PostStatus.SOLD);
        return localShopPostRepository.save(post);
    }

    @Transactional
    public LocalShopPost markAsAvailable(Long id, String username) {
        LocalShopPost post = localShopPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the poster can mark a listing as open");
        }
        post.setStatus(PostStatus.APPROVED);
        return localShopPostRepository.save(post);
    }

    @Transactional
    public void deletePost(Long id, String username, boolean isAdmin) {
        LocalShopPost post = localShopPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        if (!isAdmin) {
            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            if (!post.getSellerUserId().equals(user.getId())) {
                throw new RuntimeException("Only the poster or admin can delete a listing");
            }
        }
        if (post.getImageUrls() != null && !post.getImageUrls().isEmpty()) {
            for (String url : post.getImageUrls().split(",")) {
                if (!url.trim().isEmpty()) {
                    fileUploadService.deleteFile(url.trim());
                }
            }
        }
        post.setStatus(PostStatus.DELETED);
        postSubscriptionService.cancelSubscriptionForPost(id);
        localShopPostRepository.save(post);
        log.info("Local shop post soft-deleted: id={}", id);
    }

    @Transactional
    public void reportPost(Long postId, String reason, String details, String username) {
        LocalShopPost post = localShopPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        int newCount = (post.getReportCount() != null ? post.getReportCount() : 0) + 1;
        post.setReportCount(newCount);

        int reportThreshold = Integer.parseInt(
                settingService.getSettingValue("local_shops.post.report_threshold", "3"));
        if (newCount >= reportThreshold && post.getStatus() == PostStatus.APPROVED) {
            post.setStatus(PostStatus.FLAGGED);
            notifyAdminsFlaggedPost(post, newCount);
        }
        localShopPostRepository.save(post);

        User owner = userRepository.findById(post.getSellerUserId()).orElse(null);
        if (owner != null && owner.getEmail() != null) {
            emailService.sendPostReportedEmail(owner.getEmail(), owner.getFullName(),
                    post.getShopName(), "Local Shop", newCount);
        }
    }

    @Transactional
    public LocalShopPost adminUpdatePost(Long id, Map<String, Object> updates) {
        LocalShopPost post = localShopPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        if (updates.containsKey("shopName")) post.setShopName((String) updates.get("shopName"));
        if (updates.containsKey("phone")) post.setPhone((String) updates.get("phone"));
        if (updates.containsKey("category")) {
            try {
                post.setCategory(ShopCategory.valueOf(((String) updates.get("category")).toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid shop category");
            }
        }
        if (updates.containsKey("address")) post.setAddress((String) updates.get("address"));
        if (updates.containsKey("timings")) post.setTimings((String) updates.get("timings"));
        if (updates.containsKey("description")) post.setDescription((String) updates.get("description"));
        return localShopPostRepository.save(post);
    }

    @Transactional
    public LocalShopPost userEditPost(Long id, Map<String, Object> updates, String username) {
        LocalShopPost post = localShopPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("You can only edit your own posts");
        }
        if (post.getStatus() == PostStatus.DELETED || post.getStatus() == PostStatus.REJECTED) {
            throw new RuntimeException("Deleted or rejected posts cannot be edited");
        }
        if (updates.containsKey("shopName")) post.setShopName((String) updates.get("shopName"));
        if (updates.containsKey("phone")) post.setPhone((String) updates.get("phone"));
        if (updates.containsKey("category")) {
            try {
                post.setCategory(ShopCategory.valueOf(((String) updates.get("category")).toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid shop category");
            }
        }
        if (updates.containsKey("address")) post.setAddress((String) updates.get("address"));
        if (updates.containsKey("timings")) post.setTimings((String) updates.get("timings"));
        if (updates.containsKey("description")) post.setDescription((String) updates.get("description"));
        post.setStatus(PostStatus.PENDING_APPROVAL);
        return localShopPostRepository.save(post);
    }

    @Transactional
    public LocalShopPost toggleFeatured(Long postId) {
        LocalShopPost post = localShopPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setFeatured(!Boolean.TRUE.equals(post.getFeatured()));
        return localShopPostRepository.save(post);
    }

    @Transactional
    public LocalShopPost renewPost(Long postId, Long paidTokenId, String username) {
        LocalShopPost post = localShopPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the poster can renew a listing");
        }
        if (paidTokenId != null) {
            if (!postPaymentService.hasValidToken(paidTokenId, user.getId())) {
                throw new RuntimeException("Invalid or expired payment token");
            }
            postPaymentService.consumeToken(paidTokenId, user.getId(), post.getId());
        }
        int durationDays = Integer.parseInt(
                settingService.getSettingValue("local_shops.post.duration_days", "60"));
        post.setValidFrom(LocalDateTime.now());
        if (durationDays > 0) {
            post.setValidTo(LocalDateTime.now().plusDays(durationDays));
        }
        post.setExpiryReminderSent(false);
        post.setStatus(PostStatus.APPROVED);
        return localShopPostRepository.save(post);
    }

    private List<PostStatus> getVisibleStatuses() {
        String json = settingService.getSettingValue("local_shops.post.visible_statuses", "[\"APPROVED\"]");
        try {
            List<String> statusStrings = objectMapper.readValue(json, new TypeReference<List<String>>() {});
            return statusStrings.stream()
                    .map(s -> PostStatus.valueOf(s.toUpperCase()))
                    .collect(Collectors.toList());
        } catch (Exception e) {
            return List.of(PostStatus.APPROVED);
        }
    }

    private LocalDateTime getCutoffDate() {
        int durationDays = Integer.parseInt(
                settingService.getSettingValue("local_shops.post.duration_days", "60"));
        if (durationDays <= 0) return null;
        return LocalDateTime.now().minusDays(durationDays);
    }

    private List<Long> getAdminUserIds() {
        List<Long> adminIds = new ArrayList<>();
        userRepository.findByRole(User.UserRole.ADMIN).forEach(u -> adminIds.add(u.getId()));
        userRepository.findByRole(User.UserRole.SUPER_ADMIN).forEach(u -> adminIds.add(u.getId()));
        return adminIds;
    }

    private void notifyAdminsNewPost(LocalShopPost post) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;
            NotificationRequest request = NotificationRequest.builder()
                    .title("New Shop Listing")
                    .message("'" + post.getShopName() + "' (" + post.getCategory() + ") by " + post.getSellerName() + " is pending approval.")
                    .type(Notification.NotificationType.ANNOUNCEMENT)
                    .priority(Notification.NotificationPriority.HIGH)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("LOCAL_SHOP_POST")
                    .actionUrl("/admin/local-shops")
                    .actionText("Review Listing")
                    .icon("store")
                    .category("LOCAL_SHOPS")
                    .sendPush(true)
                    .build();
            notificationService.createNotification(request);
        } catch (Exception e) {
            log.error("Failed to send admin notification for local shop post: {}", post.getId(), e);
        }
    }

    private void notifySellerPostStatus(LocalShopPost post, String message) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Shop Listing Update")
                    .message(message)
                    .type(Notification.NotificationType.INFO)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientId(post.getSellerUserId())
                    .recipientType(Notification.RecipientType.USER)
                    .referenceId(post.getId())
                    .referenceType("LOCAL_SHOP_POST")
                    .actionUrl("/local-shops/my-posts")
                    .actionText("View Listing")
                    .icon("store")
                    .category("LOCAL_SHOPS")
                    .sendPush(true)
                    .build();
            notificationService.createNotification(request);
        } catch (Exception e) {
            log.error("Failed to send seller notification for local shop post: {}", post.getId(), e);
        }
    }

    private void notifyCustomersNewPost(LocalShopPost post) {
        try {
            Double lat = null, lng = null;
            if (post.getLatitude() != null && post.getLongitude() != null) {
                lat = post.getLatitude().doubleValue();
                lng = post.getLongitude().doubleValue();
            } else {
                User seller = userRepository.findById(post.getSellerUserId()).orElse(null);
                if (seller != null && seller.getCurrentLatitude() != null && seller.getCurrentLongitude() != null) {
                    lat = seller.getCurrentLatitude();
                    lng = seller.getCurrentLongitude();
                }
            }
            if (lat == null || lng == null) return;

            double radiusKm = Double.parseDouble(settingService.getSettingValue("notification.radius_km", "50"));
            List<User> nearbyCustomers = userRepository.findNearbyCustomers(lat, lng, radiusKm);
            if (nearbyCustomers.isEmpty()) return;

            List<Long> recipientIds = nearbyCustomers.stream().map(User::getId).collect(Collectors.toList());
            NotificationRequest request = NotificationRequest.builder()
                    .title("New Shop Listed Near You!")
                    .message(post.getShopName() + " - Check it out on NammaOoru")
                    .type(Notification.NotificationType.PROMOTION)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientType(Notification.RecipientType.ALL_CUSTOMERS)
                    .sendPush(true)
                    .sendEmail(false)
                    .build();
            notificationService.sendNotificationToUsers(request, recipientIds);
        } catch (Exception e) {
            log.error("Failed to send new post notification for local shop post: {}", post.getId(), e);
        }
    }

    private void notifyAdminsFlaggedPost(LocalShopPost post, int reportCount) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;
            NotificationRequest request = NotificationRequest.builder()
                    .title("Shop Listing Flagged")
                    .message("'" + post.getShopName() + "' has been auto-flagged with " + reportCount + " reports.")
                    .type(Notification.NotificationType.WARNING)
                    .priority(Notification.NotificationPriority.URGENT)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("LOCAL_SHOP_POST")
                    .actionUrl("/admin/local-shops")
                    .actionText("Review Listing")
                    .icon("alert-triangle")
                    .category("LOCAL_SHOPS")
                    .sendPush(true)
                    .build();
            notificationService.createNotification(request);
        } catch (Exception e) {
            log.error("Failed to send admin flagged notification for local shop post: {}", post.getId(), e);
        }
    }
}
