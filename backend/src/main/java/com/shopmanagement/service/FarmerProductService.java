package com.shopmanagement.service;

import com.shopmanagement.dto.notification.NotificationRequest;
import com.shopmanagement.entity.FarmerProduct;
import com.shopmanagement.entity.FarmerProduct.PostStatus;
import com.shopmanagement.entity.Notification;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.FarmerProductRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
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
public class FarmerProductService {

    private final FarmerProductRepository farmerProductRepository;
    private final UserRepository userRepository;
    private final FileUploadService fileUploadService;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final SettingService settingService;
    private final UserPostLimitService userPostLimitService;
    private final ObjectMapper objectMapper;

    @Transactional
    public FarmerProduct createPost(String title, String description, BigDecimal price,
                                     String phone, String category, String location,
                                     String unit, List<MultipartFile> images,
                                     String username) throws IOException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Check post limit (user-specific override > global FeatureConfig limit)
        int postLimit = userPostLimitService.getEffectiveLimit(user.getId(), "FARM_PRODUCTS");
        if (postLimit > 0) {
            List<FarmerProduct.PostStatus> activeStatuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED);
            long activeCount = farmerProductRepository.countBySellerUserIdAndStatusIn(user.getId(), activeStatuses);
            if (activeCount >= postLimit) {
                throw new RuntimeException("You have reached the maximum limit of " + postLimit + " active farmer product listings");
            }
        }

        // Upload images (up to 5)
        List<String> imageUrlList = new ArrayList<>();
        if (images != null && !images.isEmpty()) {
            int count = 0;
            for (MultipartFile image : images) {
                if (image != null && !image.isEmpty() && count < 5) {
                    String imageUrl = fileUploadService.uploadFile(image, "farmer-products");
                    imageUrlList.add(imageUrl);
                    count++;
                }
            }
        }
        String imageUrls = imageUrlList.isEmpty() ? null : String.join(",", imageUrlList);

        boolean autoApprove = Boolean.parseBoolean(
                settingService.getSettingValue("farmer_products.post.auto_approve", "false"));

        FarmerProduct post = FarmerProduct.builder()
                .title(title)
                .description(description)
                .price(price)
                .unit(unit)
                .imageUrls(imageUrls)
                .sellerUserId(user.getId())
                .sellerName(user.getFullName())
                .sellerPhone(phone)
                .category(category)
                .location(location)
                .status(autoApprove ? PostStatus.APPROVED : PostStatus.PENDING_APPROVAL)
                .build();

        FarmerProduct saved = farmerProductRepository.save(post);
        log.info("Farmer product created: id={}, title={}, seller={}, autoApproved={}", saved.getId(), title, username, autoApprove);

        if (autoApprove) {
            notifySellerPostStatus(saved, "Your farmer product '" + saved.getTitle() + "' has been auto-approved and is now visible to others.");
            notifyCustomersNewPost(saved);
        } else {
            notifyAdminsNewPost(saved);
        }

        return saved;
    }

    @Transactional(readOnly = true)
    public Page<FarmerProduct> getApprovedPosts(Pageable pageable) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();
        LocalDateTime cutoffDate = getCutoffDate();

        if (cutoffDate != null) {
            return farmerProductRepository.findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, cutoffDate, pageable);
        }
        return farmerProductRepository.findByStatusInOrderByCreatedAtDesc(visibleStatuses, pageable);
    }

    @Transactional(readOnly = true)
    public Page<FarmerProduct> getApprovedPostsByCategory(String category, Pageable pageable) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();
        LocalDateTime cutoffDate = getCutoffDate();

        if (cutoffDate != null) {
            return farmerProductRepository.findByStatusInAndCategoryAndCreatedAtAfterOrderByCreatedAtDesc(visibleStatuses, category, cutoffDate, pageable);
        }
        return farmerProductRepository.findByStatusAndCategoryOrderByCreatedAtDesc(
                PostStatus.APPROVED, category, pageable);
    }

    @Transactional(readOnly = true)
    public List<FarmerProduct> getMyPosts(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return farmerProductRepository.findBySellerUserIdOrderByCreatedAtDesc(user.getId());
    }

    @Transactional(readOnly = true)
    public Page<FarmerProduct> getPendingPosts(Pageable pageable) {
        return farmerProductRepository.findByStatusOrderByCreatedAtDesc(PostStatus.PENDING_APPROVAL, pageable);
    }

    @Transactional(readOnly = true)
    public Page<FarmerProduct> getReportedPosts(Pageable pageable) {
        return farmerProductRepository.findByReportCountGreaterThanOrderByReportCountDesc(0, pageable);
    }

    @Transactional(readOnly = true)
    public Page<FarmerProduct> getAllPostsForAdmin(Pageable pageable) {
        List<PostStatus> statuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED, PostStatus.REJECTED, PostStatus.SOLD);
        return farmerProductRepository.findByStatusInOrderByCreatedAtDesc(statuses, pageable);
    }

    @Transactional
    public FarmerProduct approvePost(Long id) {
        FarmerProduct post = farmerProductRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.APPROVED);
        FarmerProduct saved = farmerProductRepository.save(post);
        log.info("Farmer product approved: id={}", id);

        notifySellerPostStatus(saved, "Your farmer product '" + saved.getTitle() + "' has been approved and is now visible to others.");
        notifyCustomersNewPost(saved);

        return saved;
    }

    @Transactional
    public FarmerProduct rejectPost(Long id) {
        FarmerProduct post = farmerProductRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.REJECTED);
        FarmerProduct saved = farmerProductRepository.save(post);
        log.info("Farmer product rejected: id={}", id);

        notifySellerPostStatus(saved, "Your farmer product '" + saved.getTitle() + "' has been rejected by admin.");

        return saved;
    }

    @Transactional
    public FarmerProduct changePostStatus(Long id, String statusStr) {
        FarmerProduct post = farmerProductRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        PostStatus newStatus;
        try {
            newStatus = PostStatus.valueOf(statusStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid status: " + statusStr);
        }

        PostStatus oldStatus = post.getStatus();
        post.setStatus(newStatus);
        FarmerProduct saved = farmerProductRepository.save(post);
        log.info("Farmer product status changed: id={}, {} -> {}", id, oldStatus, newStatus);

        String message = getStatusChangeMessage(saved, newStatus);
        if (message != null) {
            notifySellerPostStatus(saved, message);
        }

        return saved;
    }

    private String getStatusChangeMessage(FarmerProduct post, PostStatus status) {
        switch (status) {
            case APPROVED:
                return "Your farmer product '" + post.getTitle() + "' has been approved and is now visible to others.";
            case REJECTED:
                return "Your farmer product '" + post.getTitle() + "' has been rejected by admin.";
            case HOLD:
                return "Your farmer product '" + post.getTitle() + "' has been put on hold by admin.";
            case HIDDEN:
                return "Your farmer product '" + post.getTitle() + "' has been hidden by admin.";
            case CORRECTION_REQUIRED:
                return "Your farmer product '" + post.getTitle() + "' needs correction. Please update and resubmit.";
            case REMOVED:
                return "Your farmer product '" + post.getTitle() + "' has been removed by admin.";
            default:
                return null;
        }
    }

    @Transactional
    public FarmerProduct markAsSold(Long id, String username) {
        FarmerProduct post = farmerProductRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the seller can mark a post as sold");
        }

        post.setStatus(PostStatus.SOLD);
        log.info("Farmer product marked as sold: id={}", id);
        return farmerProductRepository.save(post);
    }

    @Transactional
    public void deletePost(Long id, String username, boolean isAdmin) {
        FarmerProduct post = farmerProductRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        if (!isAdmin) {
            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            if (!post.getSellerUserId().equals(user.getId())) {
                throw new RuntimeException("Only the seller or admin can delete a post");
            }
        }

        farmerProductRepository.delete(post);
        log.info("Farmer product deleted: id={}", id);
    }

    @Transactional(readOnly = true)
    public FarmerProduct getPostById(Long id) {
        return farmerProductRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
    }

    @Transactional(readOnly = true)
    public Page<FarmerProduct> getFeaturedPosts(int page, int size) {
        List<PostStatus> visibleStatuses = getVisibleStatuses();
        Pageable pageable = PageRequest.of(page, size);
        return farmerProductRepository.findByFeaturedTrueAndStatusInOrderByCreatedAtDesc(visibleStatuses, pageable);
    }

    @Transactional
    public FarmerProduct toggleFeatured(Long postId) {
        FarmerProduct post = farmerProductRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setFeatured(!Boolean.TRUE.equals(post.getFeatured()));
        FarmerProduct saved = farmerProductRepository.save(post);
        log.info("Farmer product featured toggled: id={}, featured={}", postId, saved.getFeatured());
        return saved;
    }

    @Transactional
    public void reportPost(Long postId, String reason, String details, String username) {
        FarmerProduct post = farmerProductRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        int newCount = (post.getReportCount() != null ? post.getReportCount() : 0) + 1;
        post.setReportCount(newCount);

        int reportThreshold = Integer.parseInt(
                settingService.getSettingValue("farmer_products.post.report_threshold", "3"));
        if (newCount >= reportThreshold && post.getStatus() == PostStatus.APPROVED) {
            post.setStatus(PostStatus.FLAGGED);
            log.warn("Farmer product auto-flagged due to {} reports: id={}, title={}", newCount, postId, post.getTitle());
            notifyAdminsFlaggedPost(post, newCount);
        }

        farmerProductRepository.save(post);
        log.info("Farmer product reported: id={}, reason={}, reportCount={}", postId, reason, newCount);

        notifyOwnerPostReported(post, newCount);
    }

    @Transactional
    public FarmerProduct adminUpdatePost(Long id, Map<String, Object> updates) {
        FarmerProduct post = farmerProductRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        if (updates.containsKey("title")) post.setTitle((String) updates.get("title"));
        if (updates.containsKey("description")) post.setDescription((String) updates.get("description"));
        if (updates.containsKey("price")) post.setPrice(updates.get("price") != null ? new java.math.BigDecimal(updates.get("price").toString()) : null);
        if (updates.containsKey("unit")) post.setUnit((String) updates.get("unit"));
        if (updates.containsKey("category")) post.setCategory((String) updates.get("category"));
        if (updates.containsKey("location")) post.setLocation((String) updates.get("location"));

        FarmerProduct saved = farmerProductRepository.save(post);
        log.info("Farmer product admin-updated: id={}", id);
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

    private void notifyAdminsNewPost(FarmerProduct post) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("New Farmer Product")
                    .message("'" + post.getTitle() + "' by " + post.getSellerName() + " is pending approval.")
                    .type(Notification.NotificationType.ANNOUNCEMENT)
                    .priority(Notification.NotificationPriority.HIGH)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("FARMER_PRODUCT")
                    .actionUrl("/admin/farmer-products")
                    .actionText("Review Post")
                    .icon("leaf")
                    .category("FARMER_PRODUCTS")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for new farmer product: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to send admin notification for farmer product: {}", post.getId(), e);
        }
    }

    private void notifySellerPostStatus(FarmerProduct post, String message) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Farmer Product Update")
                    .message(message)
                    .type(Notification.NotificationType.INFO)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientId(post.getSellerUserId())
                    .recipientType(Notification.RecipientType.USER)
                    .referenceId(post.getId())
                    .referenceType("FARMER_PRODUCT")
                    .actionUrl("/farmer-products/my-posts")
                    .actionText("View Post")
                    .icon("leaf")
                    .category("FARMER_PRODUCTS")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Seller notification sent for farmer product: id={}, seller={}", post.getId(), post.getSellerUserId());
        } catch (Exception e) {
            log.error("Failed to send seller notification for farmer product: {}", post.getId(), e);
        }
    }

    private List<PostStatus> getVisibleStatuses() {
        String json = settingService.getSettingValue("farmer_products.post.visible_statuses", "[\"APPROVED\"]");
        try {
            List<String> statusStrings = objectMapper.readValue(json, new TypeReference<List<String>>() {});
            return statusStrings.stream()
                    .map(s -> PostStatus.valueOf(s.toUpperCase()))
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.warn("Failed to parse farmer_products visible_statuses setting, defaulting to APPROVED: {}", e.getMessage());
            return List.of(PostStatus.APPROVED);
        }
    }

    private LocalDateTime getCutoffDate() {
        int durationDays = Integer.parseInt(
                settingService.getSettingValue("farmer_products.post.duration_days", "30"));
        if (durationDays <= 0) {
            return null;
        }
        return LocalDateTime.now().minusDays(durationDays);
    }

    private void notifyCustomersNewPost(FarmerProduct post) {
        try {
            // Use seller's location (FarmerProduct has no lat/lng)
            User seller = userRepository.findById(post.getSellerUserId()).orElse(null);
            if (seller == null || seller.getCurrentLatitude() == null || seller.getCurrentLongitude() == null) {
                log.info("Skipping location-based notification for farmer product {}: no seller location", post.getId());
                return;
            }

            double radiusKm = Double.parseDouble(
                    settingService.getSettingValue("notification.radius_km", "50"));

            List<User> nearbyCustomers = userRepository.findNearbyCustomers(
                    seller.getCurrentLatitude(), seller.getCurrentLongitude(), radiusKm);
            if (nearbyCustomers.isEmpty()) return;

            List<Long> recipientIds = nearbyCustomers.stream()
                    .map(User::getId).collect(Collectors.toList());

            NotificationRequest request = NotificationRequest.builder()
                    .title("Fresh Farm Product Available!")
                    .message(post.getTitle() + " - Check it out on NammaOoru")
                    .type(Notification.NotificationType.PROMOTION)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientType(Notification.RecipientType.ALL_CUSTOMERS)
                    .sendPush(true)
                    .sendEmail(false)
                    .build();

            notificationService.sendNotificationToUsers(request, recipientIds);
            log.info("New farmer product notification sent to {} nearby customers", recipientIds.size());
        } catch (Exception e) {
            log.error("Failed to send new post notification for farmer product: {}", post.getId(), e);
        }
    }

    private void notifyOwnerPostReported(FarmerProduct post, int reportCount) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Your post has been reported")
                    .message("Your product \"" + post.getTitle() + "\" has received " + reportCount + " report(s). Please review it.")
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
                        post.getTitle(), "Farmer Product", reportCount);
            }
            log.info("Post owner notified about report for farmer product: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to notify post owner about report for farmer product: {}", post.getId(), e);
        }
    }

    private void notifyAdminsFlaggedPost(FarmerProduct post, int reportCount) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("Farmer Product Flagged")
                    .message("'" + post.getTitle() + "' has been auto-flagged with " + reportCount + " reports. Please review.")
                    .type(Notification.NotificationType.WARNING)
                    .priority(Notification.NotificationPriority.URGENT)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("FARMER_PRODUCT")
                    .actionUrl("/admin/farmer-products")
                    .actionText("Review Post")
                    .icon("alert-triangle")
                    .category("FARMER_PRODUCTS")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for flagged farmer product: id={}, reports={}", post.getId(), reportCount);
        } catch (Exception e) {
            log.error("Failed to send admin notification for flagged farmer product: {}", post.getId(), e);
        }
    }
}
