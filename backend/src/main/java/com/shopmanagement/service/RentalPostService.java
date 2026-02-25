package com.shopmanagement.service;

import com.shopmanagement.dto.notification.NotificationRequest;
import com.shopmanagement.entity.RentalPost;
import com.shopmanagement.entity.RentalPost.PostStatus;
import com.shopmanagement.entity.RentalPost.RentalCategory;
import com.shopmanagement.entity.Notification;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.RentalPostRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
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
public class RentalPostService {

    private final RentalPostRepository rentalPostRepository;
    private final UserRepository userRepository;
    private final FileUploadService fileUploadService;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final SettingService settingService;
    private final GlobalPostLimitService globalPostLimitService;
    private final UserPostLimitService userPostLimitService;
    private final PostPaymentService postPaymentService;
    private final ObjectMapper objectMapper;

    @Transactional
    public RentalPost createPost(String title, String description, BigDecimal price, String priceUnit,
                                  String phone, String category, String location,
                                  List<MultipartFile> images, String username,
                                  BigDecimal latitude, BigDecimal longitude, Long paidTokenId, boolean isBanner) throws IOException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Check global post limit (configurable free posts across all modules)
        globalPostLimitService.checkGlobalPostLimit(user.getId(), paidTokenId);

        // Check per-module post limit (user-specific override > global FeatureConfig limit)
        int postLimit = userPostLimitService.getEffectiveLimit(user.getId(), "RENTAL");
        if (postLimit > 0) {
            List<PostStatus> activeStatuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED);
            long activeCount = rentalPostRepository.countBySellerUserIdAndStatusIn(user.getId(), activeStatuses);
            if (activeCount >= postLimit) {
                if (paidTokenId == null) {
                    throw new RuntimeException("LIMIT_REACHED");
                }
                if (!postPaymentService.hasValidToken(paidTokenId, user.getId())) {
                    throw new RuntimeException("Invalid or expired payment token");
                }
            }
        }

        // Upload images
        List<String> imageUrlList = new ArrayList<>();
        if (images != null) {
            for (MultipartFile image : images) {
                if (image != null && !image.isEmpty()) {
                    String url = fileUploadService.uploadFile(image, "rentals");
                    imageUrlList.add(url);
                }
            }
        }

        boolean autoApprove = Boolean.parseBoolean(
                settingService.getSettingValue("rental.post.auto_approve", "false"));

        RentalCategory rentalCategory = null;
        if (category != null && !category.isEmpty()) {
            try {
                rentalCategory = RentalCategory.valueOf(category.toUpperCase());
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid rental category: " + category);
            }
        }

        RentalPost post = RentalPost.builder()
                .title(title)
                .description(description)
                .price(price)
                .priceUnit(priceUnit != null ? priceUnit : "per_month")
                .imageUrls(String.join(",", imageUrlList))
                .sellerUserId(user.getId())
                .sellerName(user.getFullName())
                .sellerPhone(phone)
                .category(rentalCategory)
                .location(location)
                .latitude(latitude)
                .longitude(longitude)
                .status((autoApprove || paidTokenId != null) ? PostStatus.APPROVED : PostStatus.PENDING_APPROVAL)
                .isPaid(paidTokenId != null)
                .featured(isBanner)
                .build();

        int durationDays = Integer.parseInt(
                settingService.getSettingValue("rental.post.duration_days", "30"));
        post.setValidFrom(LocalDateTime.now());
        if (durationDays > 0) {
            post.setValidTo(LocalDateTime.now().plusDays(durationDays));
        }

        // Balance day inheritance: free posts inherit remaining validity from most recently deleted post
        if (paidTokenId == null) {
            rentalPostRepository.findTopBySellerUserIdAndStatusOrderByUpdatedAtDesc(
                    user.getId(), PostStatus.DELETED).ifPresent(deleted -> {
                if (deleted.getValidTo() != null && deleted.getValidTo().isAfter(LocalDateTime.now())) {
                    post.setValidTo(deleted.getValidTo());
                    log.info("Rental post inheriting balance days from deleted post id={}, validTo={}", deleted.getId(), deleted.getValidTo());
                }
            });
        }

        RentalPost saved = rentalPostRepository.save(post);

        // Consume paid token if used
        if (paidTokenId != null) {
            postPaymentService.consumeToken(paidTokenId, user.getId(), saved.getId());
        }

        log.info("Rental post created: id={}, title={}, category={}, seller={}, autoApproved={}, paid={}",
                saved.getId(), title, category, username, autoApprove, paidTokenId != null);

        if (autoApprove) {
            notifySellerPostStatus(saved, "Your rental post '" + saved.getTitle() + "' has been auto-approved and is now visible to others.");
            notifyCustomersNewPost(saved);
        } else {
            notifyAdminsNewPost(saved);
        }

        return saved;
    }

    @Transactional(readOnly = true)
    public Page<RentalPost> searchByLocation(String search, Pageable pageable) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();
        return rentalPostRepository.findByStatusInAndLocationContainingIgnoreCaseOrderByCreatedAtDesc(
                visibleStatuses, search, pageable);
    }

    @Transactional(readOnly = true)
    public Page<RentalPost> getApprovedPosts(Pageable pageable, Double lat, Double lng, Double radiusKm) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();

        if (lat != null && lng != null) {
            double radius = (radiusKm != null) ? radiusKm : 50.0;
            String[] statuses = visibleStatuses.stream().map(Enum::name).toArray(String[]::new);
            int limit = pageable.getPageSize();
            int offset = (int) pageable.getOffset();
            List<RentalPost> posts = rentalPostRepository.findNearbyPosts(statuses, lat, lng, radius, limit, offset);
            long total = rentalPostRepository.countNearbyPosts(statuses, lat, lng, radius);
            return new PageImpl<>(posts, pageable, total);
        }

        LocalDateTime cutoffDate = getCutoffDate();
        if (cutoffDate != null) {
            return rentalPostRepository.findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, cutoffDate, pageable);
        }
        return rentalPostRepository.findByStatusInOrderByCreatedAtDesc(visibleStatuses, pageable);
    }

    @Transactional(readOnly = true)
    public Page<RentalPost> getApprovedPostsByCategory(String category, Pageable pageable, Double lat, Double lng, Double radiusKm) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();

        RentalCategory rentalCategory;
        try {
            rentalCategory = RentalCategory.valueOf(category.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid rental category: " + category);
        }

        if (lat != null && lng != null) {
            double radius = (radiusKm != null) ? radiusKm : 50.0;
            String[] statuses = visibleStatuses.stream().map(Enum::name).toArray(String[]::new);
            int limit = pageable.getPageSize();
            int offset = (int) pageable.getOffset();
            List<RentalPost> posts = rentalPostRepository.findNearbyPostsByCategory(statuses, category.toUpperCase(), lat, lng, radius, limit, offset);
            long total = rentalPostRepository.countNearbyPostsByCategory(statuses, category.toUpperCase(), lat, lng, radius);
            return new PageImpl<>(posts, pageable, total);
        }

        LocalDateTime cutoffDate = getCutoffDate();
        if (cutoffDate != null) {
            return rentalPostRepository.findByStatusInAndCategoryAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, rentalCategory, cutoffDate, pageable);
        }
        return rentalPostRepository.findByStatusAndCategoryOrderByCreatedAtDesc(
                PostStatus.APPROVED, rentalCategory, pageable);
    }

    @Transactional(readOnly = true)
    public List<RentalPost> getMyPosts(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return rentalPostRepository.findBySellerUserIdAndStatusNotOrderByCreatedAtDesc(user.getId(), PostStatus.DELETED);
    }

    @Transactional(readOnly = true)
    public RentalPost getPostById(Long id) {
        return rentalPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Rental post not found"));
    }

    @Transactional(readOnly = true)
    public Page<RentalPost> getPendingPosts(Pageable pageable) {
        return rentalPostRepository.findByStatusOrderByCreatedAtDesc(PostStatus.PENDING_APPROVAL, pageable);
    }

    @Transactional(readOnly = true)
    public Page<RentalPost> getReportedPosts(Pageable pageable) {
        return rentalPostRepository.findByReportCountGreaterThanOrderByReportCountDesc(0, pageable);
    }

    @Transactional(readOnly = true)
    public Page<RentalPost> getAllPostsForAdmin(Pageable pageable, String search) {
        List<PostStatus> statuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED, PostStatus.REJECTED, PostStatus.RENTED);
        if (search != null && !search.trim().isEmpty()) {
            return rentalPostRepository.findByStatusInAndLocationContainingIgnoreCaseOrderByCreatedAtDesc(statuses, search.trim(), pageable);
        }
        return rentalPostRepository.findByStatusInOrderByCreatedAtDesc(statuses, pageable);
    }

    @Transactional
    public RentalPost approvePost(Long id) {
        RentalPost post = rentalPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Rental post not found"));
        post.setStatus(PostStatus.APPROVED);
        RentalPost saved = rentalPostRepository.save(post);
        log.info("Rental post approved: id={}", id);

        notifySellerPostStatus(saved, "Your rental post '" + saved.getTitle() + "' has been approved and is now visible to others.");
        notifyCustomersNewPost(saved);

        return saved;
    }

    @Transactional
    public RentalPost rejectPost(Long id) {
        RentalPost post = rentalPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Rental post not found"));
        post.setStatus(PostStatus.REJECTED);
        RentalPost saved = rentalPostRepository.save(post);
        log.info("Rental post rejected: id={}", id);

        notifySellerPostStatus(saved, "Your rental post '" + saved.getTitle() + "' has been rejected by admin.");

        return saved;
    }

    @Transactional
    public RentalPost changePostStatus(Long id, String statusStr) {
        RentalPost post = rentalPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Rental post not found"));

        PostStatus newStatus;
        try {
            newStatus = PostStatus.valueOf(statusStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid status: " + statusStr);
        }

        PostStatus oldStatus = post.getStatus();
        post.setStatus(newStatus);
        RentalPost saved = rentalPostRepository.save(post);
        log.info("Rental post status changed: id={}, {} -> {}", id, oldStatus, newStatus);

        String message = getStatusChangeMessage(saved, newStatus);
        if (message != null) {
            notifySellerPostStatus(saved, message);
        }

        return saved;
    }

    private String getStatusChangeMessage(RentalPost post, PostStatus status) {
        switch (status) {
            case APPROVED:
                return "Your rental post '" + post.getTitle() + "' has been approved and is now visible to others.";
            case REJECTED:
                return "Your rental post '" + post.getTitle() + "' has been rejected by admin.";
            case HOLD:
                return "Your rental post '" + post.getTitle() + "' has been put on hold by admin.";
            case HIDDEN:
                return "Your rental post '" + post.getTitle() + "' has been hidden by admin.";
            case CORRECTION_REQUIRED:
                return "Your rental post '" + post.getTitle() + "' needs correction. Please update and resubmit.";
            case REMOVED:
                return "Your rental post '" + post.getTitle() + "' has been removed by admin.";
            default:
                return null;
        }
    }

    @Transactional
    public RentalPost markAsRented(Long id, String username) {
        RentalPost post = rentalPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Rental post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the owner can mark a post as rented");
        }

        post.setStatus(PostStatus.RENTED);
        log.info("Rental post marked as rented: id={}", id);
        return rentalPostRepository.save(post);
    }

    @Transactional
    public void deletePost(Long id, String username, boolean isAdmin) {
        RentalPost post = rentalPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Rental post not found"));

        if (!isAdmin) {
            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            if (!post.getSellerUserId().equals(user.getId())) {
                throw new RuntimeException("Only the owner or admin can delete a rental post");
            }
        }

        // Delete image files before soft-deleting
        if (post.getImageUrls() != null && !post.getImageUrls().isEmpty()) {
            for (String url : post.getImageUrls().split(",")) {
                if (!url.trim().isEmpty()) {
                    fileUploadService.deleteFile(url.trim());
                }
            }
        }

        post.setStatus(PostStatus.DELETED);
        rentalPostRepository.save(post);
        log.info("Rental post soft-deleted: id={}, validTo={}", id, post.getValidTo());
    }

    @Transactional
    public void reportPost(Long postId, String reason, String details, String username) {
        RentalPost post = rentalPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Rental post not found"));

        int newCount = (post.getReportCount() != null ? post.getReportCount() : 0) + 1;
        post.setReportCount(newCount);

        int reportThreshold = Integer.parseInt(
                settingService.getSettingValue("rental.post.report_threshold", "3"));
        if (newCount >= reportThreshold && post.getStatus() == PostStatus.APPROVED) {
            post.setStatus(PostStatus.FLAGGED);
            log.warn("Rental post auto-flagged due to {} reports: id={}, title={}", newCount, postId, post.getTitle());
            notifyAdminsFlaggedPost(post, newCount);
        }

        rentalPostRepository.save(post);
        log.info("Rental post reported: id={}, reason={}, reportCount={}", postId, reason, newCount);

        notifyOwnerPostReported(post, newCount);
    }

    @Transactional
    public RentalPost adminUpdatePost(Long id, Map<String, Object> updates) {
        RentalPost post = rentalPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Rental post not found"));

        if (updates.containsKey("title")) post.setTitle((String) updates.get("title"));
        if (updates.containsKey("description")) post.setDescription((String) updates.get("description"));
        if (updates.containsKey("price")) post.setPrice(updates.get("price") != null ? new BigDecimal(updates.get("price").toString()) : null);
        if (updates.containsKey("priceUnit")) post.setPriceUnit((String) updates.get("priceUnit"));
        if (updates.containsKey("category")) {
            try {
                post.setCategory(RentalCategory.valueOf(updates.get("category").toString().toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid rental category");
            }
        }
        if (updates.containsKey("location")) post.setLocation((String) updates.get("location"));

        RentalPost saved = rentalPostRepository.save(post);
        log.info("Rental post admin-updated: id={}", id);
        return saved;
    }

    @Transactional
    public RentalPost userEditPost(Long id, Map<String, Object> updates, String username) {
        RentalPost post = rentalPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Rental post not found"));

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
        if (updates.containsKey("price")) post.setPrice(updates.get("price") != null ? new BigDecimal(updates.get("price").toString()) : null);
        if (updates.containsKey("priceUnit")) post.setPriceUnit((String) updates.get("priceUnit"));
        if (updates.containsKey("phone")) post.setSellerPhone((String) updates.get("phone"));
        if (updates.containsKey("category")) {
            try {
                post.setCategory(RentalCategory.valueOf(updates.get("category").toString().toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid rental category");
            }
        }
        if (updates.containsKey("location")) post.setLocation((String) updates.get("location"));

        post.setStatus(PostStatus.PENDING_APPROVAL);

        RentalPost saved = rentalPostRepository.save(post);
        log.info("Rental post user-edited: id={}, userId={}", id, user.getId());
        return saved;
    }

    @Transactional
    public RentalPost toggleFeatured(Long postId) {
        RentalPost post = rentalPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Rental post not found"));
        post.setFeatured(!Boolean.TRUE.equals(post.getFeatured()));
        RentalPost saved = rentalPostRepository.save(post);
        log.info("Rental post featured toggled: id={}, featured={}", postId, saved.getFeatured());
        return saved;
    }

    @Transactional
    public RentalPost renewPost(Long postId, String username) {
        RentalPost post = rentalPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Rental post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the owner can renew a post");
        }

        int durationDays = Integer.parseInt(
                settingService.getSettingValue("rental.post.duration_days", "30"));

        post.setValidFrom(LocalDateTime.now());
        if (durationDays > 0) {
            post.setValidTo(LocalDateTime.now().plusDays(durationDays));
        }
        post.setExpiryReminderSent(false);
        post.setStatus(PostStatus.APPROVED);

        RentalPost saved = rentalPostRepository.save(post);
        log.info("Rental post renewed: id={}, newValidTo={}", postId, saved.getValidTo());
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

    private void notifyAdminsNewPost(RentalPost post) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("New Rental Post")
                    .message("'" + post.getTitle() + "' by " + post.getSellerName() + " is pending approval.")
                    .type(Notification.NotificationType.ANNOUNCEMENT)
                    .priority(Notification.NotificationPriority.HIGH)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("RENTAL_POST")
                    .actionUrl("/admin/rentals")
                    .actionText("Review Post")
                    .icon("vpn_key")
                    .category("RENTAL")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for new rental post: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to send admin notification for rental post: {}", post.getId(), e);
        }
    }

    private void notifySellerPostStatus(RentalPost post, String message) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Rental Post Update")
                    .message(message)
                    .type(Notification.NotificationType.INFO)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientId(post.getSellerUserId())
                    .recipientType(Notification.RecipientType.USER)
                    .referenceId(post.getId())
                    .referenceType("RENTAL_POST")
                    .actionUrl("/rentals/my-posts")
                    .actionText("View Post")
                    .icon("vpn_key")
                    .category("RENTAL")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Seller notification sent for rental post: id={}, seller={}", post.getId(), post.getSellerUserId());
        } catch (Exception e) {
            log.error("Failed to send seller notification for rental post: {}", post.getId(), e);
        }
    }

    private void notifyCustomersNewPost(RentalPost post) {
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
                log.info("Skipping location-based notification for rental post {}: no location", post.getId());
                return;
            }

            double radiusKm = Double.parseDouble(
                    settingService.getSettingValue("notification.radius_km", "50"));

            List<User> nearbyCustomers = userRepository.findNearbyCustomers(lat, lng, radiusKm);
            if (nearbyCustomers.isEmpty()) {
                log.info("No nearby customers found for rental post notification: id={}", post.getId());
                return;
            }

            List<Long> recipientIds = nearbyCustomers.stream()
                    .map(User::getId)
                    .collect(Collectors.toList());

            NotificationRequest request = NotificationRequest.builder()
                    .title("New Rental Listing!")
                    .message(post.getTitle() + " - Check it out on NammaOoru")
                    .type(Notification.NotificationType.PROMOTION)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientType(Notification.RecipientType.ALL_CUSTOMERS)
                    .sendPush(true)
                    .sendEmail(false)
                    .build();

            notificationService.sendNotificationToUsers(request, recipientIds);
            log.info("New rental post notification sent to {} nearby customers", recipientIds.size());
        } catch (Exception e) {
            log.error("Failed to send new post notification to customers for rental post: {}", post.getId(), e);
        }
    }

    private void notifyOwnerPostReported(RentalPost post, int reportCount) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Your rental post has been reported")
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
                        post.getTitle(), "Rental", reportCount);
            }

            log.info("Post owner notified about report for rental post: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to notify post owner about report for rental post: {}", post.getId(), e);
        }
    }

    private void notifyAdminsFlaggedPost(RentalPost post, int reportCount) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("Rental Post Flagged")
                    .message("'" + post.getTitle() + "' has been auto-flagged with " + reportCount + " reports. Please review.")
                    .type(Notification.NotificationType.WARNING)
                    .priority(Notification.NotificationPriority.URGENT)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("RENTAL_POST")
                    .actionUrl("/admin/rentals")
                    .actionText("Review Post")
                    .icon("alert-triangle")
                    .category("RENTAL")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for flagged rental post: id={}, reports={}", post.getId(), reportCount);
        } catch (Exception e) {
            log.error("Failed to send admin notification for flagged rental post: {}", post.getId(), e);
        }
    }

    private List<PostStatus> getVisibleStatuses() {
        String json = settingService.getSettingValue("rental.post.visible_statuses", "[\"APPROVED\"]");
        try {
            List<String> statusStrings = objectMapper.readValue(json, new TypeReference<List<String>>() {});
            return statusStrings.stream()
                    .map(s -> PostStatus.valueOf(s.toUpperCase()))
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("Failed to parse rental visible_statuses setting, defaulting to APPROVED: {}", e.getMessage());
            return List.of(PostStatus.APPROVED);
        }
    }

    private LocalDateTime getCutoffDate() {
        int durationDays = Integer.parseInt(
                settingService.getSettingValue("rental.post.duration_days", "30"));
        if (durationDays <= 0) {
            return null;
        }
        return LocalDateTime.now().minusDays(durationDays);
    }
}
