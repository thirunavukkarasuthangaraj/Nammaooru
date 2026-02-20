package com.shopmanagement.service;

import com.shopmanagement.dto.notification.NotificationRequest;
import com.shopmanagement.entity.LabourPost;
import com.shopmanagement.entity.LabourPost.LabourCategory;
import com.shopmanagement.entity.LabourPost.PostStatus;
import com.shopmanagement.entity.Notification;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.LabourPostRepository;
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
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

@Service
@RequiredArgsConstructor
@Slf4j
public class LabourPostService {

    private final LabourPostRepository labourPostRepository;
    private final UserRepository userRepository;
    private final FileUploadService fileUploadService;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final SettingService settingService;
    private final UserPostLimitService userPostLimitService;
    private final PostPaymentService postPaymentService;
    private final ObjectMapper objectMapper;

    @Transactional
    public LabourPost createPost(String name, String phone, String categoryStr,
                                  String experience, String location, String description,
                                  List<MultipartFile> images, String username,
                                  BigDecimal latitude, BigDecimal longitude) throws IOException {
        return createPost(name, phone, categoryStr, experience, location, description, images, username, latitude, longitude, null);
    }

    @Transactional
    public LabourPost createPost(String name, String phone, String categoryStr,
                                  String experience, String location, String description,
                                  List<MultipartFile> images, String username,
                                  BigDecimal latitude, BigDecimal longitude, Long paidTokenId) throws IOException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Check post limit (user-specific override > global FeatureConfig limit)
        int postLimit = userPostLimitService.getEffectiveLimit(user.getId(), "LABOURS");
        if (postLimit > 0) {
            List<PostStatus> activeStatuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED);
            long activeCount = labourPostRepository.countBySellerUserIdAndStatusIn(user.getId(), activeStatuses);
            if (activeCount >= postLimit) {
                if (paidTokenId == null) {
                    throw new RuntimeException("LIMIT_REACHED");
                }
                if (!postPaymentService.hasValidToken(paidTokenId, user.getId())) {
                    throw new RuntimeException("Invalid or expired payment token");
                }
            }
        }

        LabourCategory category;
        try {
            category = LabourCategory.valueOf(categoryStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid labour category: " + categoryStr);
        }

        String imageUrls = null;
        if (images != null && !images.isEmpty()) {
            List<String> uploadedUrls = new ArrayList<>();
            for (MultipartFile image : images) {
                if (image != null && !image.isEmpty()) {
                    uploadedUrls.add(fileUploadService.uploadFile(image, "labours"));
                }
            }
            if (!uploadedUrls.isEmpty()) {
                imageUrls = String.join(",", uploadedUrls);
            }
        }

        boolean autoApprove = Boolean.parseBoolean(
                settingService.getSettingValue("labours.post.auto_approve", "false"));

        LabourPost post = LabourPost.builder()
                .name(name)
                .phone(phone)
                .category(category)
                .experience(experience)
                .location(location)
                .description(description)
                .imageUrls(imageUrls)
                .latitude(latitude)
                .longitude(longitude)
                .sellerUserId(user.getId())
                .sellerName(user.getFullName())
                .status(autoApprove ? PostStatus.APPROVED : PostStatus.PENDING_APPROVAL)
                .isPaid(paidTokenId != null)
                .featured(paidTokenId != null)
                .build();

        // Set validity dates
        int durationDays = Integer.parseInt(
                settingService.getSettingValue("labours.post.duration_days", "60"));
        post.setValidFrom(LocalDateTime.now());
        if (durationDays > 0) {
            post.setValidTo(LocalDateTime.now().plusDays(durationDays));
        }

        // Balance day inheritance: free posts inherit remaining validity from most recently deleted post
        if (paidTokenId == null) {
            labourPostRepository.findTopBySellerUserIdAndStatusOrderByUpdatedAtDesc(
                    user.getId(), PostStatus.DELETED).ifPresent(deleted -> {
                if (deleted.getValidTo() != null && deleted.getValidTo().isAfter(LocalDateTime.now())) {
                    post.setValidTo(deleted.getValidTo());
                    log.info("Labour post inheriting balance days from deleted post id={}, validTo={}", deleted.getId(), deleted.getValidTo());
                }
            });
        }

        LabourPost saved = labourPostRepository.save(post);

        // Consume paid token if used
        if (paidTokenId != null) {
            postPaymentService.consumeToken(paidTokenId, user.getId(), saved.getId());
        }

        log.info("Labour post created: id={}, name={}, category={}, poster={}, autoApproved={}, paid={}, validTo={}",
                saved.getId(), name, category, username, autoApprove, paidTokenId != null, saved.getValidTo());

        if (autoApprove) {
            notifySellerPostStatus(saved, "Your labour listing for '" + saved.getName() + "' has been auto-approved and is now visible to others.");
            notifyCustomersNewPost(saved);
        } else {
            notifyAdminsNewPost(saved);
        }

        return saved;
    }

    @Transactional(readOnly = true)
    public Page<LabourPost> getApprovedPosts(Pageable pageable, Double lat, Double lng, Double radiusKm) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();

        if (lat != null && lng != null) {
            double radius = (radiusKm != null) ? radiusKm : 50.0;
            String[] statuses = visibleStatuses.stream().map(Enum::name).toArray(String[]::new);
            int limit = pageable.getPageSize();
            int offset = (int) pageable.getOffset();
            List<LabourPost> posts = labourPostRepository.findNearbyPosts(statuses, lat, lng, radius, limit, offset);
            long total = labourPostRepository.countNearbyPosts(statuses, lat, lng, radius);
            return new PageImpl<>(posts, pageable, total);
        }

        LocalDateTime cutoffDate = getCutoffDate();
        if (cutoffDate != null) {
            return labourPostRepository.findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, cutoffDate, pageable);
        }
        return labourPostRepository.findByStatusInOrderByCreatedAtDesc(visibleStatuses, pageable);
    }

    @Transactional(readOnly = true)
    public Page<LabourPost> getApprovedPostsByCategory(String categoryStr, Pageable pageable, Double lat, Double lng, Double radiusKm) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();

        LabourCategory category;
        try {
            category = LabourCategory.valueOf(categoryStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid labour category: " + categoryStr);
        }

        if (lat != null && lng != null) {
            double radius = (radiusKm != null) ? radiusKm : 50.0;
            String[] statuses = visibleStatuses.stream().map(Enum::name).toArray(String[]::new);
            int limit = pageable.getPageSize();
            int offset = (int) pageable.getOffset();
            List<LabourPost> posts = labourPostRepository.findNearbyPostsByCategory(statuses, category.name(), lat, lng, radius, limit, offset);
            long total = labourPostRepository.countNearbyPostsByCategory(statuses, category.name(), lat, lng, radius);
            return new PageImpl<>(posts, pageable, total);
        }

        LocalDateTime cutoffDate = getCutoffDate();
        if (cutoffDate != null) {
            return labourPostRepository.findByStatusInAndCategoryAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, category, cutoffDate, pageable);
        }
        return labourPostRepository.findByStatusInAndCategoryOrderByCreatedAtDesc(visibleStatuses, category, pageable);
    }

    @Transactional(readOnly = true)
    public List<LabourPost> getMyPosts(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return labourPostRepository.findBySellerUserIdAndStatusNotOrderByCreatedAtDesc(user.getId(), PostStatus.DELETED);
    }

    @Transactional(readOnly = true)
    public Page<LabourPost> getPendingPosts(Pageable pageable) {
        return labourPostRepository.findByStatusOrderByCreatedAtDesc(PostStatus.PENDING_APPROVAL, pageable);
    }

    @Transactional(readOnly = true)
    public Page<LabourPost> getReportedPosts(Pageable pageable) {
        return labourPostRepository.findByReportCountGreaterThanOrderByReportCountDesc(0, pageable);
    }

    @Transactional(readOnly = true)
    public Page<LabourPost> getAllPostsForAdmin(Pageable pageable) {
        List<PostStatus> statuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED, PostStatus.REJECTED, PostStatus.SOLD);
        return labourPostRepository.findByStatusInOrderByCreatedAtDesc(statuses, pageable);
    }

    @Transactional
    public LabourPost approvePost(Long id) {
        LabourPost post = labourPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.APPROVED);
        LabourPost saved = labourPostRepository.save(post);
        log.info("Labour post approved: id={}", id);

        notifySellerPostStatus(saved, "Your labour listing for '" + saved.getName() + "' has been approved and is now visible to others.");
        notifyCustomersNewPost(saved);

        return saved;
    }

    @Transactional
    public LabourPost rejectPost(Long id) {
        LabourPost post = labourPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.REJECTED);
        LabourPost saved = labourPostRepository.save(post);
        log.info("Labour post rejected: id={}", id);

        notifySellerPostStatus(saved, "Your labour listing for '" + saved.getName() + "' has been rejected by admin.");

        return saved;
    }

    @Transactional
    public LabourPost changePostStatus(Long id, String statusStr) {
        LabourPost post = labourPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        PostStatus newStatus;
        try {
            newStatus = PostStatus.valueOf(statusStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid status: " + statusStr);
        }

        PostStatus oldStatus = post.getStatus();
        post.setStatus(newStatus);
        LabourPost saved = labourPostRepository.save(post);
        log.info("Labour post status changed: id={}, {} -> {}", id, oldStatus, newStatus);

        String message = getStatusChangeMessage(saved, newStatus);
        if (message != null) {
            notifySellerPostStatus(saved, message);
        }

        return saved;
    }

    private String getStatusChangeMessage(LabourPost post, PostStatus status) {
        switch (status) {
            case APPROVED:
                return "Your labour listing for '" + post.getName() + "' has been approved and is now visible to others.";
            case REJECTED:
                return "Your labour listing for '" + post.getName() + "' has been rejected by admin.";
            case HOLD:
                return "Your labour listing for '" + post.getName() + "' has been put on hold by admin.";
            case HIDDEN:
                return "Your labour listing for '" + post.getName() + "' has been hidden by admin.";
            case CORRECTION_REQUIRED:
                return "Your labour listing for '" + post.getName() + "' needs correction. Please update and resubmit.";
            case REMOVED:
                return "Your labour listing for '" + post.getName() + "' has been removed by admin.";
            default:
                return null;
        }
    }

    @Transactional
    public LabourPost markAsUnavailable(Long id, String username) {
        LabourPost post = labourPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the poster can mark a listing as unavailable");
        }

        post.setStatus(PostStatus.SOLD);
        log.info("Labour post marked as unavailable: id={}", id);
        return labourPostRepository.save(post);
    }

    @Transactional
    public LabourPost markAsAvailable(Long id, String username) {
        LabourPost post = labourPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the poster can mark a listing as available");
        }

        post.setStatus(PostStatus.APPROVED);
        log.info("Labour post marked as available: id={}", id);
        return labourPostRepository.save(post);
    }

    @Transactional
    public void deletePost(Long id, String username, boolean isAdmin) {
        LabourPost post = labourPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        if (!isAdmin) {
            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            if (!post.getSellerUserId().equals(user.getId())) {
                throw new RuntimeException("Only the poster or admin can delete a listing");
            }
        }

        post.setStatus(PostStatus.DELETED);
        labourPostRepository.save(post);
        log.info("Labour post soft-deleted: id={}, validTo={}", id, post.getValidTo());
    }

    @Transactional(readOnly = true)
    public LabourPost getPostById(Long id) {
        return labourPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
    }

    @Transactional
    public void reportPost(Long postId, String reason, String details, String username) {
        LabourPost post = labourPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        int newCount = (post.getReportCount() != null ? post.getReportCount() : 0) + 1;
        post.setReportCount(newCount);

        int reportThreshold = Integer.parseInt(
                settingService.getSettingValue("labours.post.report_threshold", "3"));
        if (newCount >= reportThreshold && post.getStatus() == PostStatus.APPROVED) {
            post.setStatus(PostStatus.FLAGGED);
            log.warn("Labour post auto-flagged due to {} reports: id={}, name={}", newCount, postId, post.getName());
            notifyAdminsFlaggedPost(post, newCount);
        }

        labourPostRepository.save(post);
        log.info("Labour post reported: id={}, reason={}, reportCount={}", postId, reason, newCount);

        notifyOwnerPostReported(post, newCount);
    }

    @Transactional
    public LabourPost adminUpdatePost(Long id, Map<String, Object> updates) {
        LabourPost post = labourPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        if (updates.containsKey("name")) post.setName((String) updates.get("name"));
        if (updates.containsKey("phone")) post.setPhone((String) updates.get("phone"));
        if (updates.containsKey("category")) {
            try {
                post.setCategory(LabourCategory.valueOf(((String) updates.get("category")).toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid labour category: " + updates.get("category"));
            }
        }
        if (updates.containsKey("experience")) post.setExperience((String) updates.get("experience"));
        if (updates.containsKey("location")) post.setLocation((String) updates.get("location"));
        if (updates.containsKey("description")) post.setDescription((String) updates.get("description"));

        LabourPost saved = labourPostRepository.save(post);
        log.info("Labour post admin-updated: id={}", id);
        return saved;
    }

    @Transactional
    public LabourPost userEditPost(Long id, Map<String, Object> updates, String username) {
        LabourPost post = labourPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("You can only edit your own posts");
        }

        if (post.getStatus() != PostStatus.APPROVED && post.getStatus() != PostStatus.CORRECTION_REQUIRED) {
            throw new RuntimeException("Only approved or correction-required posts can be edited");
        }

        if (updates.containsKey("name")) post.setName((String) updates.get("name"));
        if (updates.containsKey("phone")) post.setPhone((String) updates.get("phone"));
        if (updates.containsKey("category")) {
            try {
                post.setCategory(LabourCategory.valueOf(((String) updates.get("category")).toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid labour category: " + updates.get("category"));
            }
        }
        if (updates.containsKey("experience")) post.setExperience((String) updates.get("experience"));
        if (updates.containsKey("location")) post.setLocation((String) updates.get("location"));
        if (updates.containsKey("description")) post.setDescription((String) updates.get("description"));

        post.setStatus(PostStatus.PENDING_APPROVAL);

        LabourPost saved = labourPostRepository.save(post);
        log.info("Labour post user-edited: id={}, userId={}", id, user.getId());
        return saved;
    }

    @Transactional
    public LabourPost renewPost(Long postId, Long paidTokenId, String username) {
        LabourPost post = labourPostRepository.findById(postId)
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
                settingService.getSettingValue("labours.post.duration_days", "60"));

        post.setValidFrom(LocalDateTime.now());
        if (durationDays > 0) {
            post.setValidTo(LocalDateTime.now().plusDays(durationDays));
        }
        post.setExpiryReminderSent(false);
        post.setStatus(PostStatus.APPROVED);

        LabourPost saved = labourPostRepository.save(post);
        log.info("Labour post renewed: id={}, newValidTo={}", postId, saved.getValidTo());
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

    private void notifyAdminsNewPost(LabourPost post) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("New Labour Listing")
                    .message("'" + post.getName() + "' (" + post.getCategory() + ") by " + post.getSellerName() + " is pending approval.")
                    .type(Notification.NotificationType.ANNOUNCEMENT)
                    .priority(Notification.NotificationPriority.HIGH)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("LABOUR_POST")
                    .actionUrl("/admin/labours")
                    .actionText("Review Listing")
                    .icon("construction")
                    .category("LABOURS")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for new labour post: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to send admin notification for labour post: {}", post.getId(), e);
        }
    }

    private void notifySellerPostStatus(LabourPost post, String message) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Labour Listing Update")
                    .message(message)
                    .type(Notification.NotificationType.INFO)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientId(post.getSellerUserId())
                    .recipientType(Notification.RecipientType.USER)
                    .referenceId(post.getId())
                    .referenceType("LABOUR_POST")
                    .actionUrl("/labours/my-posts")
                    .actionText("View Listing")
                    .icon("construction")
                    .category("LABOURS")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Seller notification sent for labour post: id={}, seller={}", post.getId(), post.getSellerUserId());
        } catch (Exception e) {
            log.error("Failed to send seller notification for labour post: {}", post.getId(), e);
        }
    }

    private List<PostStatus> getVisibleStatuses() {
        String json = settingService.getSettingValue("labours.post.visible_statuses", "[\"APPROVED\"]");
        try {
            List<String> statusStrings = objectMapper.readValue(json, new TypeReference<List<String>>() {});
            return statusStrings.stream()
                    .map(s -> PostStatus.valueOf(s.toUpperCase()))
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("Failed to parse labours visible_statuses setting, defaulting to APPROVED: {}", e.getMessage());
            return List.of(PostStatus.APPROVED);
        }
    }

    private LocalDateTime getCutoffDate() {
        int durationDays = Integer.parseInt(
                settingService.getSettingValue("labours.post.duration_days", "60"));
        if (durationDays <= 0) {
            return null;
        }
        return LocalDateTime.now().minusDays(durationDays);
    }

    private void notifyCustomersNewPost(LabourPost post) {
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
            if (lat == null || lng == null) {
                log.info("Skipping location-based notification for labour post {}: no location", post.getId());
                return;
            }

            double radiusKm = Double.parseDouble(
                    settingService.getSettingValue("notification.radius_km", "50"));

            List<User> nearbyCustomers = userRepository.findNearbyCustomers(lat, lng, radiusKm);
            if (nearbyCustomers.isEmpty()) return;

            List<Long> recipientIds = nearbyCustomers.stream()
                    .map(User::getId).collect(Collectors.toList());

            NotificationRequest request = NotificationRequest.builder()
                    .title("New Labour Service Available!")
                    .message(post.getName() + " - Check it out on NammaOoru")
                    .type(Notification.NotificationType.PROMOTION)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientType(Notification.RecipientType.ALL_CUSTOMERS)
                    .sendPush(true)
                    .sendEmail(false)
                    .build();

            notificationService.sendNotificationToUsers(request, recipientIds);
            log.info("New labour post notification sent to {} nearby customers", recipientIds.size());
        } catch (Exception e) {
            log.error("Failed to send new post notification for labour post: {}", post.getId(), e);
        }
    }

    private void notifyOwnerPostReported(LabourPost post, int reportCount) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Your post has been reported")
                    .message("Your listing \"" + post.getName() + "\" has received " + reportCount + " report(s). Please review it.")
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
                        post.getName(), "Labour", reportCount);
            }
            log.info("Post owner notified about report for labour post: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to notify post owner about report for labour post: {}", post.getId(), e);
        }
    }

    @Transactional
    public LabourPost toggleFeatured(Long postId) {
        LabourPost post = labourPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setFeatured(!Boolean.TRUE.equals(post.getFeatured()));
        LabourPost saved = labourPostRepository.save(post);
        log.info("Labour post featured toggled: id={}, featured={}", postId, saved.getFeatured());
        return saved;
    }

    private void notifyAdminsFlaggedPost(LabourPost post, int reportCount) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("Labour Listing Flagged")
                    .message("'" + post.getName() + "' has been auto-flagged with " + reportCount + " reports. Please review.")
                    .type(Notification.NotificationType.WARNING)
                    .priority(Notification.NotificationPriority.URGENT)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("LABOUR_POST")
                    .actionUrl("/admin/labours")
                    .actionText("Review Listing")
                    .icon("alert-triangle")
                    .category("LABOURS")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for flagged labour post: id={}, reports={}", post.getId(), reportCount);
        } catch (Exception e) {
            log.error("Failed to send admin notification for flagged labour post: {}", post.getId(), e);
        }
    }
}
