package com.shopmanagement.service;

import com.shopmanagement.dto.notification.NotificationRequest;
import com.shopmanagement.entity.TravelPost;
import com.shopmanagement.entity.TravelPost.VehicleType;
import com.shopmanagement.entity.TravelPost.PostStatus;
import com.shopmanagement.entity.Notification;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.TravelPostRepository;
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
public class TravelPostService {

    private final TravelPostRepository travelPostRepository;
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
    public TravelPost createPost(String title, String phone, String vehicleTypeStr,
                                  String fromLocation, String toLocation, String price,
                                  Integer seatsAvailable, String description,
                                  List<MultipartFile> images, String username,
                                  BigDecimal latitude, BigDecimal longitude) throws IOException {
        return createPost(title, phone, vehicleTypeStr, fromLocation, toLocation, price, seatsAvailable, description, images, username, latitude, longitude, null, false);
    }

    @Transactional
    public TravelPost createPost(String title, String phone, String vehicleTypeStr,
                                  String fromLocation, String toLocation, String price,
                                  Integer seatsAvailable, String description,
                                  List<MultipartFile> images, String username,
                                  BigDecimal latitude, BigDecimal longitude, Long paidTokenId, boolean isBanner) throws IOException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Check global post limit (1 free post across all modules)
        globalPostLimitService.checkGlobalPostLimit(user.getId(), paidTokenId);

        // Check post limit (user-specific override > global FeatureConfig limit)
        int postLimit = userPostLimitService.getEffectiveLimit(user.getId(), "TRAVELS");
        if (postLimit > 0) {
            List<PostStatus> activeStatuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED);
            long activeCount = travelPostRepository.countBySellerUserIdAndStatusIn(user.getId(), activeStatuses);
            if (activeCount >= postLimit) {
                if (paidTokenId == null) {
                    throw new RuntimeException("LIMIT_REACHED");
                }
                if (!postPaymentService.hasValidToken(paidTokenId, user.getId())) {
                    throw new RuntimeException("Invalid or expired payment token");
                }
            }
        }

        VehicleType vehicleType;
        try {
            vehicleType = VehicleType.valueOf(vehicleTypeStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid vehicle type: " + vehicleTypeStr);
        }

        String imageUrls = null;
        if (images != null && !images.isEmpty()) {
            List<String> uploadedUrls = new ArrayList<>();
            for (MultipartFile image : images) {
                if (image != null && !image.isEmpty()) {
                    uploadedUrls.add(fileUploadService.uploadFile(image, "travels"));
                }
            }
            if (!uploadedUrls.isEmpty()) {
                imageUrls = String.join(",", uploadedUrls);
            }
        }

        boolean autoApprove = Boolean.parseBoolean(
                settingService.getSettingValue("travels.post.auto_approve", "false"));

        TravelPost post = TravelPost.builder()
                .title(title)
                .phone(phone)
                .vehicleType(vehicleType)
                .fromLocation(fromLocation)
                .toLocation(toLocation)
                .price(price)
                .seatsAvailable(seatsAvailable)
                .description(description)
                .imageUrls(imageUrls)
                .latitude(latitude)
                .longitude(longitude)
                .sellerUserId(user.getId())
                .sellerName(user.getFullName())
                .status((autoApprove || paidTokenId != null) ? PostStatus.APPROVED : PostStatus.PENDING_APPROVAL)
                .isPaid(paidTokenId != null)
                .featured(isBanner)
                .build();

        // Set validity dates
        int durationDays = Integer.parseInt(
                settingService.getSettingValue("travels.post.duration_days", "30"));
        post.setValidFrom(LocalDateTime.now());
        if (durationDays > 0) {
            post.setValidTo(LocalDateTime.now().plusDays(durationDays));
        }

        // Balance day inheritance: free posts inherit remaining validity from most recently deleted post
        if (paidTokenId == null) {
            travelPostRepository.findTopBySellerUserIdAndStatusOrderByUpdatedAtDesc(
                    user.getId(), PostStatus.DELETED).ifPresent(deleted -> {
                if (deleted.getValidTo() != null && deleted.getValidTo().isAfter(LocalDateTime.now())) {
                    post.setValidTo(deleted.getValidTo());
                    log.info("Travel post inheriting balance days from deleted post id={}, validTo={}", deleted.getId(), deleted.getValidTo());
                }
            });
        }

        TravelPost saved = travelPostRepository.save(post);

        // Consume paid token if used
        if (paidTokenId != null) {
            postPaymentService.consumeToken(paidTokenId, user.getId(), saved.getId());
        }

        log.info("Travel post created: id={}, title={}, vehicleType={}, poster={}, autoApproved={}, paid={}, validTo={}",
                saved.getId(), title, vehicleType, username, autoApprove, paidTokenId != null, saved.getValidTo());

        if (autoApprove) {
            notifySellerPostStatus(saved, "Your travel listing for '" + saved.getTitle() + "' has been auto-approved and is now visible to others.");
            notifyCustomersNewPost(saved);
        } else {
            notifyAdminsNewPost(saved);
        }

        return saved;
    }

    @Transactional(readOnly = true)
    public Page<TravelPost> searchByLocation(String search, Pageable pageable) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();
        return travelPostRepository.searchByLocation(visibleStatuses, search, pageable);
    }

    @Transactional(readOnly = true)
    public Page<TravelPost> getApprovedPosts(Pageable pageable, Double lat, Double lng, Double radiusKm) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();

        if (lat != null && lng != null) {
            double radius = (radiusKm != null) ? radiusKm : 50.0;
            String[] statuses = visibleStatuses.stream().map(Enum::name).toArray(String[]::new);
            int limit = pageable.getPageSize();
            int offset = (int) pageable.getOffset();
            List<TravelPost> posts = travelPostRepository.findNearbyPosts(statuses, lat, lng, radius, limit, offset);
            long total = travelPostRepository.countNearbyPosts(statuses, lat, lng, radius);
            return new PageImpl<>(posts, pageable, total);
        }

        LocalDateTime cutoffDate = getCutoffDate();
        if (cutoffDate != null) {
            return travelPostRepository.findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, cutoffDate, pageable);
        }
        return travelPostRepository.findByStatusInOrderByCreatedAtDesc(visibleStatuses, pageable);
    }

    @Transactional(readOnly = true)
    public Page<TravelPost> getApprovedPostsByVehicleType(String vehicleTypeStr, Pageable pageable, Double lat, Double lng, Double radiusKm) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();

        VehicleType vehicleType;
        try {
            vehicleType = VehicleType.valueOf(vehicleTypeStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid vehicle type: " + vehicleTypeStr);
        }

        if (lat != null && lng != null) {
            double radius = (radiusKm != null) ? radiusKm : 50.0;
            String[] statuses = visibleStatuses.stream().map(Enum::name).toArray(String[]::new);
            int limit = pageable.getPageSize();
            int offset = (int) pageable.getOffset();
            List<TravelPost> posts = travelPostRepository.findNearbyPostsByVehicleType(statuses, vehicleType.name(), lat, lng, radius, limit, offset);
            long total = travelPostRepository.countNearbyPostsByVehicleType(statuses, vehicleType.name(), lat, lng, radius);
            return new PageImpl<>(posts, pageable, total);
        }

        LocalDateTime cutoffDate = getCutoffDate();
        if (cutoffDate != null) {
            return travelPostRepository.findByStatusInAndVehicleTypeAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, vehicleType, cutoffDate, pageable);
        }
        return travelPostRepository.findByStatusInAndVehicleTypeOrderByCreatedAtDesc(visibleStatuses, vehicleType, pageable);
    }

    @Transactional(readOnly = true)
    public List<TravelPost> getMyPosts(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return travelPostRepository.findBySellerUserIdAndStatusNotOrderByCreatedAtDesc(user.getId(), PostStatus.DELETED);
    }

    @Transactional(readOnly = true)
    public Page<TravelPost> getPendingPosts(Pageable pageable) {
        return travelPostRepository.findByStatusOrderByCreatedAtDesc(PostStatus.PENDING_APPROVAL, pageable);
    }

    @Transactional(readOnly = true)
    public Page<TravelPost> getReportedPosts(Pageable pageable) {
        return travelPostRepository.findByReportCountGreaterThanOrderByReportCountDesc(0, pageable);
    }

    @Transactional(readOnly = true)
    public Page<TravelPost> getAllPostsForAdmin(Pageable pageable, String search) {
        List<PostStatus> statuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED, PostStatus.REJECTED, PostStatus.SOLD);
        if (search != null && !search.trim().isEmpty()) {
            return travelPostRepository.searchByLocation(statuses, search.trim(), pageable);
        }
        return travelPostRepository.findByStatusInOrderByCreatedAtDesc(statuses, pageable);
    }

    @Transactional
    public TravelPost approvePost(Long id) {
        TravelPost post = travelPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.APPROVED);
        TravelPost saved = travelPostRepository.save(post);
        log.info("Travel post approved: id={}", id);

        notifySellerPostStatus(saved, "Your travel listing for '" + saved.getTitle() + "' has been approved and is now visible to others.");
        notifyCustomersNewPost(saved);

        return saved;
    }

    @Transactional
    public TravelPost rejectPost(Long id) {
        TravelPost post = travelPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.REJECTED);
        TravelPost saved = travelPostRepository.save(post);
        log.info("Travel post rejected: id={}", id);

        notifySellerPostStatus(saved, "Your travel listing for '" + saved.getTitle() + "' has been rejected by admin.");

        return saved;
    }

    @Transactional
    public TravelPost changePostStatus(Long id, String statusStr) {
        TravelPost post = travelPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        PostStatus newStatus;
        try {
            newStatus = PostStatus.valueOf(statusStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid status: " + statusStr);
        }

        PostStatus oldStatus = post.getStatus();
        post.setStatus(newStatus);
        TravelPost saved = travelPostRepository.save(post);
        log.info("Travel post status changed: id={}, {} -> {}", id, oldStatus, newStatus);

        String message = getStatusChangeMessage(saved, newStatus);
        if (message != null) {
            notifySellerPostStatus(saved, message);
        }

        return saved;
    }

    private String getStatusChangeMessage(TravelPost post, PostStatus status) {
        switch (status) {
            case APPROVED:
                return "Your travel listing for '" + post.getTitle() + "' has been approved and is now visible to others.";
            case REJECTED:
                return "Your travel listing for '" + post.getTitle() + "' has been rejected by admin.";
            case HOLD:
                return "Your travel listing for '" + post.getTitle() + "' has been put on hold by admin.";
            case HIDDEN:
                return "Your travel listing for '" + post.getTitle() + "' has been hidden by admin.";
            case CORRECTION_REQUIRED:
                return "Your travel listing for '" + post.getTitle() + "' needs correction. Please update and resubmit.";
            case REMOVED:
                return "Your travel listing for '" + post.getTitle() + "' has been removed by admin.";
            default:
                return null;
        }
    }

    @Transactional
    public TravelPost markAsUnavailable(Long id, String username) {
        TravelPost post = travelPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the poster can mark a listing as unavailable");
        }

        post.setStatus(PostStatus.SOLD);
        log.info("Travel post marked as unavailable: id={}", id);
        return travelPostRepository.save(post);
    }

    @Transactional
    public TravelPost markAsAvailable(Long id, String username) {
        TravelPost post = travelPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the poster can mark a listing as available");
        }

        post.setStatus(PostStatus.APPROVED);
        log.info("Travel post marked as available: id={}", id);
        return travelPostRepository.save(post);
    }

    @Transactional
    public void deletePost(Long id, String username, boolean isAdmin) {
        TravelPost post = travelPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        if (!isAdmin) {
            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            if (!post.getSellerUserId().equals(user.getId())) {
                throw new RuntimeException("Only the poster or admin can delete a listing");
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
        travelPostRepository.save(post);
        log.info("Travel post soft-deleted: id={}, validTo={}", id, post.getValidTo());
    }

    @Transactional(readOnly = true)
    public TravelPost getPostById(Long id) {
        return travelPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
    }

    @Transactional
    public void reportPost(Long postId, String reason, String details, String username) {
        TravelPost post = travelPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        int newCount = (post.getReportCount() != null ? post.getReportCount() : 0) + 1;
        post.setReportCount(newCount);

        int reportThreshold = Integer.parseInt(
                settingService.getSettingValue("travels.post.report_threshold", "3"));
        if (newCount >= reportThreshold && post.getStatus() == PostStatus.APPROVED) {
            post.setStatus(PostStatus.FLAGGED);
            log.warn("Travel post auto-flagged due to {} reports: id={}, title={}", newCount, postId, post.getTitle());
            notifyAdminsFlaggedPost(post, newCount);
        }

        travelPostRepository.save(post);
        log.info("Travel post reported: id={}, reason={}, reportCount={}", postId, reason, newCount);

        notifyOwnerPostReported(post, newCount);
    }

    @Transactional
    public TravelPost adminUpdatePost(Long id, Map<String, Object> updates) {
        TravelPost post = travelPostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        if (updates.containsKey("title")) post.setTitle((String) updates.get("title"));
        if (updates.containsKey("phone")) post.setPhone((String) updates.get("phone"));
        if (updates.containsKey("vehicleType")) {
            try {
                post.setVehicleType(TravelPost.VehicleType.valueOf(((String) updates.get("vehicleType")).toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid vehicle type: " + updates.get("vehicleType"));
            }
        }
        if (updates.containsKey("fromLocation")) post.setFromLocation((String) updates.get("fromLocation"));
        if (updates.containsKey("toLocation")) post.setToLocation((String) updates.get("toLocation"));
        if (updates.containsKey("price")) post.setPrice((String) updates.get("price"));
        if (updates.containsKey("seatsAvailable")) post.setSeatsAvailable(updates.get("seatsAvailable") != null ? ((Number) updates.get("seatsAvailable")).intValue() : null);
        if (updates.containsKey("description")) post.setDescription((String) updates.get("description"));

        TravelPost saved = travelPostRepository.save(post);
        log.info("Travel post admin-updated: id={}", id);
        return saved;
    }

    @Transactional
    public TravelPost userEditPost(Long id, Map<String, Object> updates, String username) {
        TravelPost post = travelPostRepository.findById(id)
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
        if (updates.containsKey("phone")) post.setPhone((String) updates.get("phone"));
        if (updates.containsKey("vehicleType")) {
            try {
                post.setVehicleType(TravelPost.VehicleType.valueOf(((String) updates.get("vehicleType")).toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid vehicle type: " + updates.get("vehicleType"));
            }
        }
        if (updates.containsKey("fromLocation")) post.setFromLocation((String) updates.get("fromLocation"));
        if (updates.containsKey("toLocation")) post.setToLocation((String) updates.get("toLocation"));
        if (updates.containsKey("price")) post.setPrice((String) updates.get("price"));
        if (updates.containsKey("seatsAvailable")) post.setSeatsAvailable(updates.get("seatsAvailable") != null ? ((Number) updates.get("seatsAvailable")).intValue() : null);
        if (updates.containsKey("description")) post.setDescription((String) updates.get("description"));

        post.setStatus(PostStatus.PENDING_APPROVAL);

        TravelPost saved = travelPostRepository.save(post);
        log.info("Travel post user-edited: id={}, userId={}", id, user.getId());
        return saved;
    }

    @Transactional
    public TravelPost renewPost(Long postId, Long paidTokenId, String username) {
        TravelPost post = travelPostRepository.findById(postId)
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
                settingService.getSettingValue("travels.post.duration_days", "30"));

        post.setValidFrom(LocalDateTime.now());
        if (durationDays > 0) {
            post.setValidTo(LocalDateTime.now().plusDays(durationDays));
        }
        post.setExpiryReminderSent(false);
        post.setStatus(PostStatus.APPROVED);

        TravelPost saved = travelPostRepository.save(post);
        log.info("Travel post renewed: id={}, newValidTo={}", postId, saved.getValidTo());
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

    private void notifyAdminsNewPost(TravelPost post) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("New Travel Listing")
                    .message("'" + post.getTitle() + "' (" + post.getVehicleType() + ") by " + post.getSellerName() + " is pending approval.")
                    .type(Notification.NotificationType.ANNOUNCEMENT)
                    .priority(Notification.NotificationPriority.HIGH)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("TRAVEL_POST")
                    .actionUrl("/admin/travels")
                    .actionText("Review Listing")
                    .icon("directions_car")
                    .category("TRAVELS")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for new travel post: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to send admin notification for travel post: {}", post.getId(), e);
        }
    }

    private void notifySellerPostStatus(TravelPost post, String message) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Travel Listing Update")
                    .message(message)
                    .type(Notification.NotificationType.INFO)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientId(post.getSellerUserId())
                    .recipientType(Notification.RecipientType.USER)
                    .referenceId(post.getId())
                    .referenceType("TRAVEL_POST")
                    .actionUrl("/travels/my-posts")
                    .actionText("View Listing")
                    .icon("directions_car")
                    .category("TRAVELS")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Seller notification sent for travel post: id={}, seller={}", post.getId(), post.getSellerUserId());
        } catch (Exception e) {
            log.error("Failed to send seller notification for travel post: {}", post.getId(), e);
        }
    }

    private List<PostStatus> getVisibleStatuses() {
        String json = settingService.getSettingValue("travels.post.visible_statuses", "[\"APPROVED\"]");
        try {
            List<String> statusStrings = objectMapper.readValue(json, new TypeReference<List<String>>() {});
            return statusStrings.stream()
                    .map(s -> PostStatus.valueOf(s.toUpperCase()))
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("Failed to parse travels visible_statuses setting, defaulting to APPROVED: {}", e.getMessage());
            return List.of(PostStatus.APPROVED);
        }
    }

    private LocalDateTime getCutoffDate() {
        int durationDays = Integer.parseInt(
                settingService.getSettingValue("travels.post.duration_days", "60"));
        if (durationDays <= 0) {
            return null;
        }
        return LocalDateTime.now().minusDays(durationDays);
    }

    private void notifyCustomersNewPost(TravelPost post) {
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
                log.info("Skipping location-based notification for travel post {}: no location", post.getId());
                return;
            }

            double radiusKm = Double.parseDouble(
                    settingService.getSettingValue("notification.radius_km", "50"));

            List<User> nearbyCustomers = userRepository.findNearbyCustomers(lat, lng, radiusKm);
            if (nearbyCustomers.isEmpty()) return;

            List<Long> recipientIds = nearbyCustomers.stream()
                    .map(User::getId).collect(Collectors.toList());

            NotificationRequest request = NotificationRequest.builder()
                    .title("New Travel Service Available!")
                    .message(post.getTitle() + " - Check it out on NammaOoru")
                    .type(Notification.NotificationType.PROMOTION)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientType(Notification.RecipientType.ALL_CUSTOMERS)
                    .sendPush(true)
                    .sendEmail(false)
                    .build();

            notificationService.sendNotificationToUsers(request, recipientIds);
            log.info("New travel post notification sent to {} nearby customers", recipientIds.size());
        } catch (Exception e) {
            log.error("Failed to send new post notification for travel post: {}", post.getId(), e);
        }
    }

    private void notifyOwnerPostReported(TravelPost post, int reportCount) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Your post has been reported")
                    .message("Your listing \"" + post.getTitle() + "\" has received " + reportCount + " report(s). Please review it.")
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
                        post.getTitle(), "Travel", reportCount);
            }
            log.info("Post owner notified about report for travel post: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to notify post owner about report for travel post: {}", post.getId(), e);
        }
    }

    @Transactional
    public TravelPost toggleFeatured(Long postId) {
        TravelPost post = travelPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setFeatured(!Boolean.TRUE.equals(post.getFeatured()));
        TravelPost saved = travelPostRepository.save(post);
        log.info("Travel post featured toggled: id={}, featured={}", postId, saved.getFeatured());
        return saved;
    }

    private void notifyAdminsFlaggedPost(TravelPost post, int reportCount) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("Travel Listing Flagged")
                    .message("'" + post.getTitle() + "' has been auto-flagged with " + reportCount + " reports. Please review.")
                    .type(Notification.NotificationType.WARNING)
                    .priority(Notification.NotificationPriority.URGENT)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("TRAVEL_POST")
                    .actionUrl("/admin/travels")
                    .actionText("Review Listing")
                    .icon("alert-triangle")
                    .category("TRAVELS")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for flagged travel post: id={}, reports={}", post.getId(), reportCount);
        } catch (Exception e) {
            log.error("Failed to send admin notification for flagged travel post: {}", post.getId(), e);
        }
    }
}
