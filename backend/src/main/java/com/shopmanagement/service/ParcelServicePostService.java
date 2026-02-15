package com.shopmanagement.service;

import com.shopmanagement.dto.notification.NotificationRequest;
import com.shopmanagement.entity.ParcelServicePost;
import com.shopmanagement.entity.ParcelServicePost.ServiceType;
import com.shopmanagement.entity.ParcelServicePost.PostStatus;
import com.shopmanagement.entity.Notification;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.ParcelServicePostRepository;
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
public class ParcelServicePostService {

    private final ParcelServicePostRepository parcelServicePostRepository;
    private final UserRepository userRepository;
    private final FileUploadService fileUploadService;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final SettingService settingService;
    private final UserPostLimitService userPostLimitService;
    private final ObjectMapper objectMapper;

    @Transactional
    public ParcelServicePost createPost(String serviceName, String phone, String serviceTypeStr,
                                         String fromLocation, String toLocation, String priceInfo,
                                         String address, String timings, String description,
                                         List<MultipartFile> images, String username,
                                         BigDecimal latitude, BigDecimal longitude) throws IOException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Check post limit (user-specific override > global FeatureConfig limit)
        int postLimit = userPostLimitService.getEffectiveLimit(user.getId(), "PARCEL_SERVICE");
        if (postLimit > 0) {
            List<PostStatus> activeStatuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED);
            long activeCount = parcelServicePostRepository.countBySellerUserIdAndStatusIn(user.getId(), activeStatuses);
            if (activeCount >= postLimit) {
                throw new RuntimeException("You have reached the maximum limit of " + postLimit + " active parcel service listings");
            }
        }

        ServiceType serviceType;
        try {
            serviceType = ServiceType.valueOf(serviceTypeStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid service type: " + serviceTypeStr);
        }

        String imageUrls = null;
        if (images != null && !images.isEmpty()) {
            List<String> uploadedUrls = new ArrayList<>();
            for (MultipartFile image : images) {
                if (image != null && !image.isEmpty()) {
                    uploadedUrls.add(fileUploadService.uploadFile(image, "parcels"));
                }
            }
            if (!uploadedUrls.isEmpty()) {
                imageUrls = String.join(",", uploadedUrls);
            }
        }

        boolean autoApprove = Boolean.parseBoolean(
                settingService.getSettingValue("parcels.post.auto_approve", "false"));

        ParcelServicePost post = ParcelServicePost.builder()
                .serviceName(serviceName)
                .phone(phone)
                .serviceType(serviceType)
                .fromLocation(fromLocation)
                .toLocation(toLocation)
                .priceInfo(priceInfo)
                .address(address)
                .timings(timings)
                .description(description)
                .imageUrls(imageUrls)
                .latitude(latitude)
                .longitude(longitude)
                .sellerUserId(user.getId())
                .sellerName(user.getFullName())
                .status(autoApprove ? PostStatus.APPROVED : PostStatus.PENDING_APPROVAL)
                .build();

        ParcelServicePost saved = parcelServicePostRepository.save(post);
        log.info("Parcel service post created: id={}, serviceName={}, serviceType={}, poster={}, autoApproved={}",
                saved.getId(), serviceName, serviceType, username, autoApprove);

        if (autoApprove) {
            notifySellerPostStatus(saved, "Your parcel service listing for '" + saved.getServiceName() + "' has been auto-approved and is now visible to others.");
            notifyCustomersNewPost(saved);
        } else {
            notifyAdminsNewPost(saved);
        }

        return saved;
    }

    @Transactional(readOnly = true)
    public Page<ParcelServicePost> getApprovedPosts(Pageable pageable, Double lat, Double lng, Double radiusKm) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();

        if (lat != null && lng != null) {
            double radius = (radiusKm != null) ? radiusKm : 50.0;
            String[] statuses = visibleStatuses.stream().map(Enum::name).toArray(String[]::new);
            int limit = pageable.getPageSize();
            int offset = (int) pageable.getOffset();
            List<ParcelServicePost> posts = parcelServicePostRepository.findNearbyPosts(statuses, lat, lng, radius, limit, offset);
            long total = parcelServicePostRepository.countNearbyPosts(statuses, lat, lng, radius);
            return new PageImpl<>(posts, pageable, total);
        }

        LocalDateTime cutoffDate = getCutoffDate();
        if (cutoffDate != null) {
            return parcelServicePostRepository.findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, cutoffDate, pageable);
        }
        return parcelServicePostRepository.findByStatusInOrderByCreatedAtDesc(visibleStatuses, pageable);
    }

    @Transactional(readOnly = true)
    public Page<ParcelServicePost> getApprovedPostsByServiceType(String serviceTypeStr, Pageable pageable, Double lat, Double lng, Double radiusKm) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();

        ServiceType serviceType;
        try {
            serviceType = ServiceType.valueOf(serviceTypeStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid service type: " + serviceTypeStr);
        }

        if (lat != null && lng != null) {
            double radius = (radiusKm != null) ? radiusKm : 50.0;
            String[] statuses = visibleStatuses.stream().map(Enum::name).toArray(String[]::new);
            int limit = pageable.getPageSize();
            int offset = (int) pageable.getOffset();
            List<ParcelServicePost> posts = parcelServicePostRepository.findNearbyPostsByServiceType(statuses, serviceType.name(), lat, lng, radius, limit, offset);
            long total = parcelServicePostRepository.countNearbyPostsByServiceType(statuses, serviceType.name(), lat, lng, radius);
            return new PageImpl<>(posts, pageable, total);
        }

        LocalDateTime cutoffDate = getCutoffDate();
        if (cutoffDate != null) {
            return parcelServicePostRepository.findByStatusInAndServiceTypeAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, serviceType, cutoffDate, pageable);
        }
        return parcelServicePostRepository.findByStatusInAndServiceTypeOrderByCreatedAtDesc(visibleStatuses, serviceType, pageable);
    }

    @Transactional(readOnly = true)
    public List<ParcelServicePost> getMyPosts(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return parcelServicePostRepository.findBySellerUserIdOrderByCreatedAtDesc(user.getId());
    }

    @Transactional(readOnly = true)
    public Page<ParcelServicePost> getPendingPosts(Pageable pageable) {
        return parcelServicePostRepository.findByStatusOrderByCreatedAtDesc(PostStatus.PENDING_APPROVAL, pageable);
    }

    @Transactional(readOnly = true)
    public Page<ParcelServicePost> getReportedPosts(Pageable pageable) {
        return parcelServicePostRepository.findByReportCountGreaterThanOrderByReportCountDesc(0, pageable);
    }

    @Transactional(readOnly = true)
    public Page<ParcelServicePost> getAllPostsForAdmin(Pageable pageable) {
        List<PostStatus> statuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED, PostStatus.REJECTED, PostStatus.SOLD);
        return parcelServicePostRepository.findByStatusInOrderByCreatedAtDesc(statuses, pageable);
    }

    @Transactional
    public ParcelServicePost approvePost(Long id) {
        ParcelServicePost post = parcelServicePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.APPROVED);
        ParcelServicePost saved = parcelServicePostRepository.save(post);
        log.info("Parcel service post approved: id={}", id);

        notifySellerPostStatus(saved, "Your parcel service listing for '" + saved.getServiceName() + "' has been approved and is now visible to others.");
        notifyCustomersNewPost(saved);

        return saved;
    }

    @Transactional
    public ParcelServicePost rejectPost(Long id) {
        ParcelServicePost post = parcelServicePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.REJECTED);
        ParcelServicePost saved = parcelServicePostRepository.save(post);
        log.info("Parcel service post rejected: id={}", id);

        notifySellerPostStatus(saved, "Your parcel service listing for '" + saved.getServiceName() + "' has been rejected by admin.");

        return saved;
    }

    @Transactional
    public ParcelServicePost changePostStatus(Long id, String statusStr) {
        ParcelServicePost post = parcelServicePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        PostStatus newStatus;
        try {
            newStatus = PostStatus.valueOf(statusStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid status: " + statusStr);
        }

        PostStatus oldStatus = post.getStatus();
        post.setStatus(newStatus);
        ParcelServicePost saved = parcelServicePostRepository.save(post);
        log.info("Parcel service post status changed: id={}, {} -> {}", id, oldStatus, newStatus);

        String message = getStatusChangeMessage(saved, newStatus);
        if (message != null) {
            notifySellerPostStatus(saved, message);
        }

        return saved;
    }

    private String getStatusChangeMessage(ParcelServicePost post, PostStatus status) {
        switch (status) {
            case APPROVED:
                return "Your parcel service listing for '" + post.getServiceName() + "' has been approved and is now visible to others.";
            case REJECTED:
                return "Your parcel service listing for '" + post.getServiceName() + "' has been rejected by admin.";
            case HOLD:
                return "Your parcel service listing for '" + post.getServiceName() + "' has been put on hold by admin.";
            case HIDDEN:
                return "Your parcel service listing for '" + post.getServiceName() + "' has been hidden by admin.";
            case CORRECTION_REQUIRED:
                return "Your parcel service listing for '" + post.getServiceName() + "' needs correction. Please update and resubmit.";
            case REMOVED:
                return "Your parcel service listing for '" + post.getServiceName() + "' has been removed by admin.";
            default:
                return null;
        }
    }

    @Transactional
    public ParcelServicePost markAsUnavailable(Long id, String username) {
        ParcelServicePost post = parcelServicePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the poster can mark a listing as unavailable");
        }

        post.setStatus(PostStatus.SOLD);
        log.info("Parcel service post marked as unavailable: id={}", id);
        return parcelServicePostRepository.save(post);
    }

    @Transactional
    public ParcelServicePost markAsAvailable(Long id, String username) {
        ParcelServicePost post = parcelServicePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the poster can mark a listing as available");
        }

        post.setStatus(PostStatus.APPROVED);
        log.info("Parcel service post marked as available: id={}", id);
        return parcelServicePostRepository.save(post);
    }

    @Transactional
    public void deletePost(Long id, String username, boolean isAdmin) {
        ParcelServicePost post = parcelServicePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        if (!isAdmin) {
            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            if (!post.getSellerUserId().equals(user.getId())) {
                throw new RuntimeException("Only the poster or admin can delete a listing");
            }
        }

        parcelServicePostRepository.delete(post);
        log.info("Parcel service post deleted: id={}", id);
    }

    @Transactional(readOnly = true)
    public ParcelServicePost getPostById(Long id) {
        return parcelServicePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
    }

    @Transactional
    public void reportPost(Long postId, String reason, String details, String username) {
        ParcelServicePost post = parcelServicePostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        int newCount = (post.getReportCount() != null ? post.getReportCount() : 0) + 1;
        post.setReportCount(newCount);

        int reportThreshold = Integer.parseInt(
                settingService.getSettingValue("parcels.post.report_threshold", "3"));
        if (newCount >= reportThreshold && post.getStatus() == PostStatus.APPROVED) {
            post.setStatus(PostStatus.FLAGGED);
            log.warn("Parcel service post auto-flagged due to {} reports: id={}, serviceName={}", newCount, postId, post.getServiceName());
            notifyAdminsFlaggedPost(post, newCount);
        }

        parcelServicePostRepository.save(post);
        log.info("Parcel service post reported: id={}, reason={}, reportCount={}", postId, reason, newCount);

        notifyOwnerPostReported(post, newCount);
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

    private void notifyAdminsNewPost(ParcelServicePost post) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("New Parcel Service Listing")
                    .message("'" + post.getServiceName() + "' (" + post.getServiceType() + ") by " + post.getSellerName() + " is pending approval.")
                    .type(Notification.NotificationType.ANNOUNCEMENT)
                    .priority(Notification.NotificationPriority.HIGH)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("PARCEL_SERVICE_POST")
                    .actionUrl("/admin/parcels")
                    .actionText("Review Listing")
                    .icon("local_shipping")
                    .category("PARCELS")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for new parcel service post: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to send admin notification for parcel service post: {}", post.getId(), e);
        }
    }

    private void notifySellerPostStatus(ParcelServicePost post, String message) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Parcel Service Listing Update")
                    .message(message)
                    .type(Notification.NotificationType.INFO)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientId(post.getSellerUserId())
                    .recipientType(Notification.RecipientType.USER)
                    .referenceId(post.getId())
                    .referenceType("PARCEL_SERVICE_POST")
                    .actionUrl("/parcels/my-posts")
                    .actionText("View Listing")
                    .icon("local_shipping")
                    .category("PARCELS")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Seller notification sent for parcel service post: id={}, seller={}", post.getId(), post.getSellerUserId());
        } catch (Exception e) {
            log.error("Failed to send seller notification for parcel service post: {}", post.getId(), e);
        }
    }

    private List<PostStatus> getVisibleStatuses() {
        String json = settingService.getSettingValue("parcels.post.visible_statuses", "[\"APPROVED\"]");
        try {
            List<String> statusStrings = objectMapper.readValue(json, new TypeReference<List<String>>() {});
            return statusStrings.stream()
                    .map(s -> PostStatus.valueOf(s.toUpperCase()))
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("Failed to parse parcels visible_statuses setting, defaulting to APPROVED: {}", e.getMessage());
            return List.of(PostStatus.APPROVED);
        }
    }

    private LocalDateTime getCutoffDate() {
        int durationDays = Integer.parseInt(
                settingService.getSettingValue("parcels.post.duration_days", "60"));
        if (durationDays <= 0) {
            return null;
        }
        return LocalDateTime.now().minusDays(durationDays);
    }

    private void notifyCustomersNewPost(ParcelServicePost post) {
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
                log.info("Skipping location-based notification for parcel post {}: no location", post.getId());
                return;
            }

            double radiusKm = Double.parseDouble(
                    settingService.getSettingValue("notification.radius_km", "50"));

            List<User> nearbyCustomers = userRepository.findNearbyCustomers(lat, lng, radiusKm);
            if (nearbyCustomers.isEmpty()) return;

            List<Long> recipientIds = nearbyCustomers.stream()
                    .map(User::getId).collect(Collectors.toList());

            NotificationRequest request = NotificationRequest.builder()
                    .title("New Parcel Service Available!")
                    .message(post.getServiceName() + " - Check it out on NammaOoru")
                    .type(Notification.NotificationType.PROMOTION)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientType(Notification.RecipientType.ALL_CUSTOMERS)
                    .sendPush(true)
                    .sendEmail(false)
                    .build();

            notificationService.sendNotificationToUsers(request, recipientIds);
            log.info("New parcel post notification sent to {} nearby customers", recipientIds.size());
        } catch (Exception e) {
            log.error("Failed to send new post notification for parcel post: {}", post.getId(), e);
        }
    }

    private void notifyOwnerPostReported(ParcelServicePost post, int reportCount) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Your post has been reported")
                    .message("Your listing \"" + post.getServiceName() + "\" has received " + reportCount + " report(s). Please review it.")
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
                        post.getServiceName(), "Parcel Service", reportCount);
            }
            log.info("Post owner notified about report for parcel post: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to notify post owner about report for parcel post: {}", post.getId(), e);
        }
    }

    private void notifyAdminsFlaggedPost(ParcelServicePost post, int reportCount) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("Parcel Service Listing Flagged")
                    .message("'" + post.getServiceName() + "' has been auto-flagged with " + reportCount + " reports. Please review.")
                    .type(Notification.NotificationType.WARNING)
                    .priority(Notification.NotificationPriority.URGENT)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("PARCEL_SERVICE_POST")
                    .actionUrl("/admin/parcels")
                    .actionText("Review Listing")
                    .icon("alert-triangle")
                    .category("PARCELS")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for flagged parcel service post: id={}, reports={}", post.getId(), reportCount);
        } catch (Exception e) {
            log.error("Failed to send admin notification for flagged parcel service post: {}", post.getId(), e);
        }
    }
}
