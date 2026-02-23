package com.shopmanagement.service;

import com.shopmanagement.dto.notification.NotificationRequest;
import com.shopmanagement.entity.WomensCornerPost;
import com.shopmanagement.entity.WomensCornerPost.PostStatus;
import com.shopmanagement.entity.Notification;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.WomensCornerPostRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
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
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class WomensCornerPostService {

    private final WomensCornerPostRepository womensCornerPostRepository;
    private final UserRepository userRepository;
    private final FileUploadService fileUploadService;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final SettingService settingService;
    private final UserPostLimitService userPostLimitService;
    private final PostPaymentService postPaymentService;
    private final GlobalPostLimitService globalPostLimitService;
    private final ObjectMapper objectMapper;

    @Transactional
    public WomensCornerPost createPost(String title, String description, BigDecimal price,
                                     String phone, String category, String location,
                                     List<MultipartFile> images,
                                     String username, BigDecimal latitude, BigDecimal longitude) throws IOException {
        return createPost(title, description, price, phone, category, location, images, username, latitude, longitude, null);
    }

    @Transactional
    public WomensCornerPost createPost(String title, String description, BigDecimal price,
                                     String phone, String category, String location,
                                     List<MultipartFile> images,
                                     String username, BigDecimal latitude, BigDecimal longitude, Long paidTokenId) throws IOException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Check global post limit
        globalPostLimitService.checkGlobalPostLimit(user.getId(), paidTokenId);

        // Check post limit
        int postLimit = userPostLimitService.getEffectiveLimit(user.getId(), "WOMENS_CORNER");
        if (postLimit > 0) {
            List<PostStatus> activeStatuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED);
            long activeCount = womensCornerPostRepository.countBySellerUserIdAndStatusIn(user.getId(), activeStatuses);
            if (activeCount >= postLimit) {
                if (paidTokenId == null) {
                    throw new RuntimeException("LIMIT_REACHED");
                }
                if (!postPaymentService.hasValidToken(paidTokenId, user.getId())) {
                    throw new RuntimeException("Invalid or expired payment token");
                }
            }
        }

        // Upload images (up to 5)
        List<String> imageUrlList = new ArrayList<>();
        if (images != null && !images.isEmpty()) {
            int count = 0;
            for (MultipartFile image : images) {
                if (image != null && !image.isEmpty() && count < 5) {
                    String imageUrl = fileUploadService.uploadFile(image, "womens-corner");
                    imageUrlList.add(imageUrl);
                    count++;
                }
            }
        }
        String imageUrls = imageUrlList.isEmpty() ? null : String.join(",", imageUrlList);

        boolean autoApprove = Boolean.parseBoolean(
                settingService.getSettingValue("womens_corner.post.auto_approve", "true"));

        WomensCornerPost post = WomensCornerPost.builder()
                .title(title)
                .description(description)
                .price(price)
                .imageUrls(imageUrls)
                .sellerUserId(user.getId())
                .sellerName(user.getFullName())
                .sellerPhone(phone)
                .category(category)
                .location(location)
                .latitude(latitude)
                .longitude(longitude)
                .status(autoApprove ? PostStatus.APPROVED : PostStatus.PENDING_APPROVAL)
                .isPaid(paidTokenId != null)
                .featured(paidTokenId != null)
                .build();

        // Set validity dates
        int durationDays = Integer.parseInt(
                settingService.getSettingValue("womens_corner.post.duration_days", "30"));
        post.setValidFrom(LocalDateTime.now());
        if (durationDays > 0) {
            post.setValidTo(LocalDateTime.now().plusDays(durationDays));
        }

        // Balance day inheritance
        if (paidTokenId == null) {
            womensCornerPostRepository.findTopBySellerUserIdAndStatusOrderByUpdatedAtDesc(
                    user.getId(), PostStatus.DELETED).ifPresent(deleted -> {
                if (deleted.getValidTo() != null && deleted.getValidTo().isAfter(LocalDateTime.now())) {
                    post.setValidTo(deleted.getValidTo());
                    log.info("Women's corner post inheriting balance days from deleted post id={}, validTo={}", deleted.getId(), deleted.getValidTo());
                }
            });
        }

        WomensCornerPost saved = womensCornerPostRepository.save(post);

        // Consume paid token if used
        if (paidTokenId != null) {
            postPaymentService.consumeToken(paidTokenId, user.getId(), saved.getId());
        }

        log.info("Women's corner post created: id={}, title={}, seller={}, autoApproved={}, paid={}, validTo={}",
                saved.getId(), title, username, autoApprove, paidTokenId != null, saved.getValidTo());

        if (autoApprove) {
            notifySellerPostStatus(saved, "Your women's corner post '" + saved.getTitle() + "' has been auto-approved and is now visible to others.");
        } else {
            notifyAdminsNewPost(saved);
        }

        return saved;
    }

    @Transactional(readOnly = true)
    public Page<WomensCornerPost> searchByLocation(String search, Pageable pageable) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();
        return womensCornerPostRepository.findByStatusInAndLocationContainingIgnoreCaseOrderByCreatedAtDesc(
                visibleStatuses, search, pageable);
    }

    @Transactional(readOnly = true)
    public Page<WomensCornerPost> getApprovedPosts(Pageable pageable, Double lat, Double lng, Double radiusKm) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();

        if (lat != null && lng != null) {
            double radius = (radiusKm != null) ? radiusKm : 50.0;
            String[] statuses = visibleStatuses.stream().map(Enum::name).toArray(String[]::new);
            int limit = pageable.getPageSize();
            int offset = (int) pageable.getOffset();
            List<WomensCornerPost> posts = womensCornerPostRepository.findNearbyPosts(statuses, lat, lng, radius, limit, offset);
            long total = womensCornerPostRepository.countNearbyPosts(statuses, lat, lng, radius);
            return new PageImpl<>(posts, pageable, total);
        }

        LocalDateTime cutoffDate = getCutoffDate();
        if (cutoffDate != null) {
            return womensCornerPostRepository.findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, cutoffDate, pageable);
        }
        return womensCornerPostRepository.findByStatusInOrderByCreatedAtDesc(visibleStatuses, pageable);
    }

    @Transactional(readOnly = true)
    public Page<WomensCornerPost> getApprovedPostsByCategory(String category, Pageable pageable, Double lat, Double lng, Double radiusKm) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();

        if (lat != null && lng != null) {
            double radius = (radiusKm != null) ? radiusKm : 50.0;
            String[] statuses = visibleStatuses.stream().map(Enum::name).toArray(String[]::new);
            int limit = pageable.getPageSize();
            int offset = (int) pageable.getOffset();
            List<WomensCornerPost> posts = womensCornerPostRepository.findNearbyPostsByCategory(statuses, category, lat, lng, radius, limit, offset);
            long total = womensCornerPostRepository.countNearbyPostsByCategory(statuses, category, lat, lng, radius);
            return new PageImpl<>(posts, pageable, total);
        }

        LocalDateTime cutoffDate = getCutoffDate();
        if (cutoffDate != null) {
            return womensCornerPostRepository.findByStatusInAndCategoryAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, category, cutoffDate, pageable);
        }
        return womensCornerPostRepository.findByStatusAndCategoryOrderByCreatedAtDesc(
                PostStatus.APPROVED, category, pageable);
    }

    @Transactional(readOnly = true)
    public List<WomensCornerPost> getMyPosts(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return womensCornerPostRepository.findBySellerUserIdAndStatusNotOrderByCreatedAtDesc(user.getId(), PostStatus.DELETED);
    }

    @Transactional(readOnly = true)
    public Page<WomensCornerPost> getPendingPosts(Pageable pageable) {
        return womensCornerPostRepository.findByStatusOrderByCreatedAtDesc(PostStatus.PENDING_APPROVAL, pageable);
    }

    @Transactional(readOnly = true)
    public Page<WomensCornerPost> getReportedPosts(Pageable pageable) {
        return womensCornerPostRepository.findByReportCountGreaterThanOrderByReportCountDesc(0, pageable);
    }

    @Transactional(readOnly = true)
    public Page<WomensCornerPost> getAllPostsForAdmin(Pageable pageable, String search) {
        List<PostStatus> statuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED, PostStatus.REJECTED, PostStatus.SOLD);
        if (search != null && !search.trim().isEmpty()) {
            return womensCornerPostRepository.findByStatusInAndLocationContainingIgnoreCaseOrderByCreatedAtDesc(statuses, search.trim(), pageable);
        }
        return womensCornerPostRepository.findByStatusInOrderByCreatedAtDesc(statuses, pageable);
    }

    @Transactional
    public WomensCornerPost approvePost(Long id) {
        WomensCornerPost post = womensCornerPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.APPROVED);
        WomensCornerPost saved = womensCornerPostRepository.save(post);
        log.info("Women's corner post approved: id={}", id);

        notifySellerPostStatus(saved, "Your women's corner post '" + saved.getTitle() + "' has been approved and is now visible to others.");

        return saved;
    }

    @Transactional
    public WomensCornerPost rejectPost(Long id) {
        WomensCornerPost post = womensCornerPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.REJECTED);
        WomensCornerPost saved = womensCornerPostRepository.save(post);
        log.info("Women's corner post rejected: id={}", id);

        notifySellerPostStatus(saved, "Your women's corner post '" + saved.getTitle() + "' has been rejected by admin.");

        return saved;
    }

    @Transactional
    public WomensCornerPost changePostStatus(Long id, String statusStr) {
        WomensCornerPost post = womensCornerPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        PostStatus newStatus;
        try {
            newStatus = PostStatus.valueOf(statusStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid status: " + statusStr);
        }

        PostStatus oldStatus = post.getStatus();
        post.setStatus(newStatus);
        WomensCornerPost saved = womensCornerPostRepository.save(post);
        log.info("Women's corner post status changed: id={}, {} -> {}", id, oldStatus, newStatus);

        String message = getStatusChangeMessage(saved, newStatus);
        if (message != null) {
            notifySellerPostStatus(saved, message);
        }

        return saved;
    }

    private String getStatusChangeMessage(WomensCornerPost post, PostStatus status) {
        switch (status) {
            case APPROVED:
                return "Your women's corner post '" + post.getTitle() + "' has been approved and is now visible to others.";
            case REJECTED:
                return "Your women's corner post '" + post.getTitle() + "' has been rejected by admin.";
            case HOLD:
                return "Your women's corner post '" + post.getTitle() + "' has been put on hold by admin.";
            case HIDDEN:
                return "Your women's corner post '" + post.getTitle() + "' has been hidden by admin.";
            case CORRECTION_REQUIRED:
                return "Your women's corner post '" + post.getTitle() + "' needs correction. Please update and resubmit.";
            case REMOVED:
                return "Your women's corner post '" + post.getTitle() + "' has been removed by admin.";
            default:
                return null;
        }
    }

    @Transactional
    public WomensCornerPost markAsSold(Long id, String username) {
        WomensCornerPost post = womensCornerPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the seller can mark a post as sold");
        }

        post.setStatus(PostStatus.SOLD);
        log.info("Women's corner post marked as sold: id={}", id);
        return womensCornerPostRepository.save(post);
    }

    @Transactional
    public void deletePost(Long id, String username, boolean isAdmin) {
        WomensCornerPost post = womensCornerPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        if (!isAdmin) {
            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            if (!post.getSellerUserId().equals(user.getId())) {
                throw new RuntimeException("Only the seller or admin can delete a post");
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
        womensCornerPostRepository.save(post);
        log.info("Women's corner post soft-deleted: id={}, validTo={}", id, post.getValidTo());
    }

    @Transactional(readOnly = true)
    public WomensCornerPost getPostById(Long id) {
        return womensCornerPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
    }

    @Transactional(readOnly = true)
    public Page<WomensCornerPost> getFeaturedPosts(int page, int size) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();
        Pageable pageable = PageRequest.of(page, size);
        return womensCornerPostRepository.findByFeaturedTrueAndStatusInOrderByCreatedAtDesc(visibleStatuses, pageable);
    }

    @Transactional
    public WomensCornerPost toggleFeatured(Long postId) {
        WomensCornerPost post = womensCornerPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setFeatured(!Boolean.TRUE.equals(post.getFeatured()));
        WomensCornerPost saved = womensCornerPostRepository.save(post);
        log.info("Women's corner post featured toggled: id={}, featured={}", postId, saved.getFeatured());
        return saved;
    }

    @Transactional
    public void reportPost(Long postId, String reason, String details, String username) {
        WomensCornerPost post = womensCornerPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        int newCount = (post.getReportCount() != null ? post.getReportCount() : 0) + 1;
        post.setReportCount(newCount);

        int reportThreshold = Integer.parseInt(
                settingService.getSettingValue("womens_corner.post.report_threshold", "5"));
        if (newCount >= reportThreshold && post.getStatus() == PostStatus.APPROVED) {
            post.setStatus(PostStatus.FLAGGED);
            log.warn("Women's corner post auto-flagged due to {} reports: id={}, title={}", newCount, postId, post.getTitle());
            notifyAdminsFlaggedPost(post, newCount);
        }

        womensCornerPostRepository.save(post);
        log.info("Women's corner post reported: id={}, reason={}, reportCount={}", postId, reason, newCount);

        notifyOwnerPostReported(post, newCount);
    }

    @Transactional
    public WomensCornerPost adminUpdatePost(Long id, Map<String, Object> updates) {
        WomensCornerPost post = womensCornerPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        if (updates.containsKey("title")) post.setTitle((String) updates.get("title"));
        if (updates.containsKey("description")) post.setDescription((String) updates.get("description"));
        if (updates.containsKey("price")) post.setPrice(updates.get("price") != null ? new java.math.BigDecimal(updates.get("price").toString()) : null);
        if (updates.containsKey("category")) post.setCategory((String) updates.get("category"));
        if (updates.containsKey("location")) post.setLocation((String) updates.get("location"));

        WomensCornerPost saved = womensCornerPostRepository.save(post);
        log.info("Women's corner post admin-updated: id={}", id);
        return saved;
    }

    @Transactional
    public WomensCornerPost userEditPost(Long id, Map<String, Object> updates, String username) {
        WomensCornerPost post = womensCornerPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("You can only edit your own posts");
        }

        if (post.getStatus() == PostStatus.DELETED || post.getStatus() == PostStatus.REJECTED) {
            throw new RuntimeException("Deleted or rejected posts cannot be edited");
        }

        if (updates.containsKey("title")) post.setTitle((String) updates.get("title"));
        if (updates.containsKey("description")) post.setDescription((String) updates.get("description"));
        if (updates.containsKey("price")) post.setPrice(updates.get("price") != null ? new java.math.BigDecimal(updates.get("price").toString()) : null);
        if (updates.containsKey("phone")) post.setSellerPhone((String) updates.get("phone"));
        if (updates.containsKey("category")) post.setCategory((String) updates.get("category"));
        if (updates.containsKey("location")) post.setLocation((String) updates.get("location"));

        post.setStatus(PostStatus.PENDING_APPROVAL);

        WomensCornerPost saved = womensCornerPostRepository.save(post);
        log.info("Women's corner post user-edited: id={}, userId={}", id, user.getId());
        return saved;
    }

    @Transactional
    public WomensCornerPost renewPost(Long postId, Long paidTokenId, String username) {
        WomensCornerPost post = womensCornerPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the seller can renew a post");
        }

        if (paidTokenId != null) {
            if (!postPaymentService.hasValidToken(paidTokenId, user.getId())) {
                throw new RuntimeException("Invalid or expired payment token");
            }
            postPaymentService.consumeToken(paidTokenId, user.getId(), post.getId());
        }

        int durationDays = Integer.parseInt(
                settingService.getSettingValue("womens_corner.post.duration_days", "30"));

        post.setValidFrom(LocalDateTime.now());
        if (durationDays > 0) {
            post.setValidTo(LocalDateTime.now().plusDays(durationDays));
        }
        post.setExpiryReminderSent(false);
        post.setStatus(PostStatus.APPROVED);

        WomensCornerPost saved = womensCornerPostRepository.save(post);
        log.info("Women's corner post renewed: id={}, newValidTo={}", postId, saved.getValidTo());
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

    private void notifyAdminsNewPost(WomensCornerPost post) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("New Women's Corner Post")
                    .message("'" + post.getTitle() + "' by " + post.getSellerName() + " is pending approval.")
                    .type(Notification.NotificationType.ANNOUNCEMENT)
                    .priority(Notification.NotificationPriority.HIGH)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("WOMENS_CORNER_POST")
                    .actionUrl("/admin/womens-corner")
                    .actionText("Review Post")
                    .icon("sparkles")
                    .category("WOMENS_CORNER")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for new women's corner post: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to send admin notification for women's corner post: {}", post.getId(), e);
        }
    }

    private void notifySellerPostStatus(WomensCornerPost post, String message) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Women's Corner Update")
                    .message(message)
                    .type(Notification.NotificationType.INFO)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientId(post.getSellerUserId())
                    .recipientType(Notification.RecipientType.USER)
                    .referenceId(post.getId())
                    .referenceType("WOMENS_CORNER_POST")
                    .actionUrl("/womens-corner/my-posts")
                    .actionText("View Post")
                    .icon("sparkles")
                    .category("WOMENS_CORNER")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Seller notification sent for women's corner post: id={}, seller={}", post.getId(), post.getSellerUserId());
        } catch (Exception e) {
            log.error("Failed to send seller notification for women's corner post: {}", post.getId(), e);
        }
    }

    private List<PostStatus> getVisibleStatuses() {
        String json = settingService.getSettingValue("womens_corner.post.visible_statuses", "[\"APPROVED\"]");
        try {
            List<String> statusStrings = objectMapper.readValue(json, new TypeReference<List<String>>() {});
            return statusStrings.stream()
                    .map(s -> PostStatus.valueOf(s.toUpperCase()))
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("Failed to parse womens_corner visible_statuses setting, defaulting to APPROVED: {}", e.getMessage());
            return List.of(PostStatus.APPROVED);
        }
    }

    private LocalDateTime getCutoffDate() {
        int durationDays = Integer.parseInt(
                settingService.getSettingValue("womens_corner.post.duration_days", "30"));
        if (durationDays <= 0) {
            return null;
        }
        return LocalDateTime.now().minusDays(durationDays);
    }

    private void notifyOwnerPostReported(WomensCornerPost post, int reportCount) {
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

            User owner = userRepository.findById(post.getSellerUserId()).orElse(null);
            if (owner != null && owner.getEmail() != null) {
                emailService.sendPostReportedEmail(owner.getEmail(), owner.getFullName(),
                        post.getTitle(), "Women's Corner", reportCount);
            }
            log.info("Post owner notified about report for women's corner post: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to notify post owner about report for women's corner post: {}", post.getId(), e);
        }
    }

    private void notifyAdminsFlaggedPost(WomensCornerPost post, int reportCount) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("Women's Corner Post Flagged")
                    .message("'" + post.getTitle() + "' has been auto-flagged with " + reportCount + " reports. Please review.")
                    .type(Notification.NotificationType.WARNING)
                    .priority(Notification.NotificationPriority.URGENT)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("WOMENS_CORNER_POST")
                    .actionUrl("/admin/womens-corner")
                    .actionText("Review Post")
                    .icon("alert-triangle")
                    .category("WOMENS_CORNER")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for flagged women's corner post: id={}, reports={}", post.getId(), reportCount);
        } catch (Exception e) {
            log.error("Failed to send admin notification for flagged women's corner post: {}", post.getId(), e);
        }
    }
}
