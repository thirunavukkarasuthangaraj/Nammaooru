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
    private final SettingService settingService;
    private final ObjectMapper objectMapper;

    @Transactional
    public TravelPost createPost(String title, String phone, String vehicleTypeStr,
                                  String fromLocation, String toLocation, String price,
                                  Integer seatsAvailable, String description,
                                  List<MultipartFile> images, String username,
                                  BigDecimal latitude, BigDecimal longitude) throws IOException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Check post limit
        int postLimit = Integer.parseInt(
                settingService.getSettingValue("travels.post.user_limit", "0"));
        if (postLimit > 0) {
            List<PostStatus> activeStatuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED);
            long activeCount = travelPostRepository.countBySellerUserIdAndStatusIn(user.getId(), activeStatuses);
            if (activeCount >= postLimit) {
                throw new RuntimeException("You have reached the maximum limit of " + postLimit + " active travel listings");
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
                .status(autoApprove ? PostStatus.APPROVED : PostStatus.PENDING_APPROVAL)
                .build();

        TravelPost saved = travelPostRepository.save(post);
        log.info("Travel post created: id={}, title={}, vehicleType={}, poster={}, autoApproved={}",
                saved.getId(), title, vehicleType, username, autoApprove);

        if (autoApprove) {
            notifySellerPostStatus(saved, "Your travel listing for '" + saved.getTitle() + "' has been auto-approved and is now visible to others.");
        } else {
            notifyAdminsNewPost(saved);
        }

        return saved;
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
        return travelPostRepository.findBySellerUserIdOrderByCreatedAtDesc(user.getId());
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
    public Page<TravelPost> getAllPostsForAdmin(Pageable pageable) {
        List<PostStatus> statuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED, PostStatus.REJECTED, PostStatus.SOLD);
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

        travelPostRepository.delete(post);
        log.info("Travel post deleted: id={}", id);
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
