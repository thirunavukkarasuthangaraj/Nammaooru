package com.shopmanagement.service;

import com.shopmanagement.dto.notification.NotificationRequest;
import com.shopmanagement.entity.RealEstatePost;
import com.shopmanagement.entity.RealEstatePost.ListingType;
import com.shopmanagement.entity.RealEstatePost.PostStatus;
import com.shopmanagement.entity.RealEstatePost.PropertyType;
import com.shopmanagement.entity.Notification;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.RealEstatePostRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
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
public class RealEstateService {

    private final RealEstatePostRepository realEstatePostRepository;
    private final UserRepository userRepository;
    private final FileUploadService fileUploadService;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final SettingService settingService;
    private final UserPostLimitService userPostLimitService;
    private final GlobalPostLimitService globalPostLimitService;

    @Transactional
    public RealEstatePost createPost(String title, String description, PropertyType propertyType,
                                      ListingType listingType, BigDecimal price, Integer areaSqft,
                                      Integer bedrooms, Integer bathrooms, String location,
                                      Double latitude, Double longitude, String phone,
                                      List<MultipartFile> images, MultipartFile video,
                                      String username) throws IOException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Check global post limit (1 free post across all modules)
        globalPostLimitService.checkGlobalPostLimit(user.getId(), null);

        // Check post limit (user-specific override > global FeatureConfig limit)
        int postLimit = userPostLimitService.getEffectiveLimit(user.getId(), "REAL_ESTATE");
        if (postLimit > 0) {
            List<PostStatus> activeStatuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED);
            long activeCount = realEstatePostRepository.countByOwnerUserIdAndStatusIn(user.getId(), activeStatuses);
            if (activeCount >= postLimit) {
                throw new RuntimeException("LIMIT_REACHED");
            }
        }

        // Upload images (up to 5)
        List<String> imageUrlList = new ArrayList<>();
        if (images != null && !images.isEmpty()) {
            int count = 0;
            for (MultipartFile image : images) {
                if (image != null && !image.isEmpty() && count < 5) {
                    String imageUrl = fileUploadService.uploadFile(image, "real-estate");
                    imageUrlList.add(imageUrl);
                    count++;
                }
            }
        }
        String imageUrls = imageUrlList.isEmpty() ? null : String.join(",", imageUrlList);

        // Upload video if provided
        String videoUrl = null;
        if (video != null && !video.isEmpty()) {
            videoUrl = fileUploadService.uploadFile(video, "real-estate/videos");
        }

        boolean autoApprove = Boolean.parseBoolean(
                settingService.getSettingValue("real_estate.post.auto_approve", "false"));

        RealEstatePost post = RealEstatePost.builder()
                .title(title)
                .description(description)
                .propertyType(propertyType)
                .listingType(listingType)
                .price(price)
                .areaSqft(areaSqft)
                .bedrooms(bedrooms)
                .bathrooms(bathrooms)
                .location(location)
                .latitude(latitude)
                .longitude(longitude)
                .imageUrls(imageUrls)
                .videoUrl(videoUrl)
                .ownerUserId(user.getId())
                .ownerName(user.getFullName())
                .ownerPhone(phone)
                .status(autoApprove ? PostStatus.APPROVED : PostStatus.PENDING_APPROVAL)
                .build();

        // Set validity dates
        int durationDays = Integer.parseInt(
                settingService.getSettingValue("real_estate.post.duration_days", "90"));
        post.setValidFrom(LocalDateTime.now());
        if (durationDays > 0) {
            post.setValidTo(LocalDateTime.now().plusDays(durationDays));
        }

        // Balance day inheritance: inherit remaining validity from most recently deleted post
        realEstatePostRepository.findTopByOwnerUserIdAndStatusOrderByUpdatedAtDesc(
                user.getId(), PostStatus.DELETED).ifPresent(deleted -> {
            if (deleted.getValidTo() != null && deleted.getValidTo().isAfter(LocalDateTime.now())) {
                post.setValidTo(deleted.getValidTo());
                log.info("Real estate post inheriting balance days from deleted post id={}, validTo={}", deleted.getId(), deleted.getValidTo());
            }
        });

        RealEstatePost saved = realEstatePostRepository.save(post);
        log.info("Real estate post created: id={}, title={}, type={}, owner={}, autoApproved={}, validTo={}",
                saved.getId(), title, propertyType, username, autoApprove, saved.getValidTo());

        if (autoApprove) {
            notifySellerPostStatus(saved, "Your property listing '" + saved.getTitle() + "' has been auto-approved and is now visible to others.");
            notifyCustomersNewPost(saved);
        } else {
            notifyAdminsNewPost(saved);
        }

        return saved;
    }

    @Transactional(readOnly = true)
    public Page<RealEstatePost> getApprovedPosts(Pageable pageable) {
        return realEstatePostRepository.findByStatusOrderByCreatedAtDesc(PostStatus.APPROVED, pageable);
    }

    @Transactional(readOnly = true)
    public Page<RealEstatePost> getApprovedPostsByPropertyType(PropertyType propertyType, Pageable pageable) {
        return realEstatePostRepository.findByStatusAndPropertyTypeOrderByCreatedAtDesc(
                PostStatus.APPROVED, propertyType, pageable);
    }

    @Transactional(readOnly = true)
    public Page<RealEstatePost> getApprovedPostsByListingType(ListingType listingType, Pageable pageable) {
        return realEstatePostRepository.findByStatusAndListingTypeOrderByCreatedAtDesc(
                PostStatus.APPROVED, listingType, pageable);
    }

    @Transactional(readOnly = true)
    public Page<RealEstatePost> getApprovedPostsFiltered(PropertyType propertyType,
                                                          ListingType listingType,
                                                          Pageable pageable) {
        if (propertyType != null && listingType != null) {
            return realEstatePostRepository.findByStatusAndPropertyTypeAndListingTypeOrderByCreatedAtDesc(
                    PostStatus.APPROVED, propertyType, listingType, pageable);
        } else if (propertyType != null) {
            return getApprovedPostsByPropertyType(propertyType, pageable);
        } else if (listingType != null) {
            return getApprovedPostsByListingType(listingType, pageable);
        }
        return getApprovedPosts(pageable);
    }

    @Transactional(readOnly = true)
    public Page<RealEstatePost> searchByLocation(String location, Pageable pageable) {
        return realEstatePostRepository.findByStatusAndLocationContaining(
                PostStatus.APPROVED, location, pageable);
    }

    @Transactional(readOnly = true)
    public Page<RealEstatePost> getFeaturedPosts(Pageable pageable) {
        return realEstatePostRepository.findByStatusAndIsFeaturedTrueOrderByCreatedAtDesc(
                PostStatus.APPROVED, pageable);
    }

    @Transactional(readOnly = true)
    public List<RealEstatePost> getMyPosts(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return realEstatePostRepository.findByOwnerUserIdAndStatusNotOrderByCreatedAtDesc(user.getId(), PostStatus.DELETED);
    }

    @Transactional(readOnly = true)
    public Page<RealEstatePost> getPendingPosts(Pageable pageable) {
        return realEstatePostRepository.findByStatusOrderByCreatedAtDesc(PostStatus.PENDING_APPROVAL, pageable);
    }

    @Transactional(readOnly = true)
    public Page<RealEstatePost> getAllPostsForAdmin(Pageable pageable) {
        List<PostStatus> statuses = List.of(
                PostStatus.PENDING_APPROVAL, PostStatus.APPROVED,
                PostStatus.REJECTED, PostStatus.SOLD, PostStatus.RENTED);
        return realEstatePostRepository.findByStatusInOrderByCreatedAtDesc(statuses, pageable);
    }

    @Transactional
    public RealEstatePost approvePost(Long id) {
        RealEstatePost post = realEstatePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.APPROVED);
        RealEstatePost saved = realEstatePostRepository.save(post);
        log.info("Real estate post approved: id={}", id);

        notifySellerPostStatus(saved, "Your property listing '" + saved.getTitle() + "' has been approved and is now visible to others.");
        notifyCustomersNewPost(saved);

        return saved;
    }

    @Transactional
    public RealEstatePost rejectPost(Long id) {
        RealEstatePost post = realEstatePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.REJECTED);
        RealEstatePost saved = realEstatePostRepository.save(post);
        log.info("Real estate post rejected: id={}", id);

        notifySellerPostStatus(saved, "Your property listing '" + saved.getTitle() + "' has been rejected by admin.");

        return saved;
    }

    @Transactional
    public RealEstatePost markAsSold(Long id, String username) {
        RealEstatePost post = realEstatePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getOwnerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the owner can mark a post as sold");
        }

        post.setStatus(PostStatus.SOLD);
        log.info("Real estate post marked as sold: id={}", id);
        return realEstatePostRepository.save(post);
    }

    @Transactional
    public RealEstatePost markAsRented(Long id, String username) {
        RealEstatePost post = realEstatePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getOwnerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the owner can mark a post as rented");
        }

        post.setStatus(PostStatus.RENTED);
        log.info("Real estate post marked as rented: id={}", id);
        return realEstatePostRepository.save(post);
    }

    @Transactional
    public void deletePost(Long id, String username, boolean isAdmin) {
        RealEstatePost post = realEstatePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        if (!isAdmin) {
            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            if (!post.getOwnerUserId().equals(user.getId())) {
                throw new RuntimeException("Only the owner or admin can delete a post");
            }
        }

        post.setStatus(PostStatus.DELETED);
        realEstatePostRepository.save(post);
        log.info("Real estate post soft-deleted: id={}, validTo={}", id, post.getValidTo());
    }

    @Transactional(readOnly = true)
    public RealEstatePost getPostById(Long id) {
        return realEstatePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
    }

    @Transactional
    public RealEstatePost incrementViews(Long id) {
        RealEstatePost post = realEstatePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setViewsCount((post.getViewsCount() != null ? post.getViewsCount() : 0) + 1);
        return realEstatePostRepository.save(post);
    }

    @Transactional
    public void reportPost(Long postId, String reason, String details, String username) {
        RealEstatePost post = realEstatePostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        int newCount = (post.getReportCount() != null ? post.getReportCount() : 0) + 1;
        post.setReportCount(newCount);

        int reportThreshold = Integer.parseInt(
                settingService.getSettingValue("real_estate.post.report_threshold", "3"));
        if (newCount >= reportThreshold && post.getStatus() == PostStatus.APPROVED) {
            post.setStatus(PostStatus.FLAGGED);
            log.warn("Real estate post auto-flagged due to {} reports: id={}, title={}",
                    newCount, postId, post.getTitle());
            notifyAdminsFlaggedPost(post, newCount);
        }

        realEstatePostRepository.save(post);
        log.info("Real estate post reported: id={}, reason={}, reportCount={}", postId, reason, newCount);

        notifyOwnerPostReported(post, newCount);
    }

    @Transactional
    public RealEstatePost adminUpdatePost(Long id, Map<String, Object> updates) {
        RealEstatePost post = realEstatePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        if (updates.containsKey("title")) post.setTitle((String) updates.get("title"));
        if (updates.containsKey("description")) post.setDescription((String) updates.get("description"));
        if (updates.containsKey("propertyType")) {
            try {
                post.setPropertyType(RealEstatePost.PropertyType.valueOf(((String) updates.get("propertyType")).toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid property type: " + updates.get("propertyType"));
            }
        }
        if (updates.containsKey("listingType")) {
            try {
                post.setListingType(RealEstatePost.ListingType.valueOf(((String) updates.get("listingType")).toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid listing type: " + updates.get("listingType"));
            }
        }
        if (updates.containsKey("price")) post.setPrice(updates.get("price") != null ? new java.math.BigDecimal(updates.get("price").toString()) : null);
        if (updates.containsKey("areaSqft")) post.setAreaSqft(updates.get("areaSqft") != null ? ((Number) updates.get("areaSqft")).intValue() : null);
        if (updates.containsKey("bedrooms")) post.setBedrooms(updates.get("bedrooms") != null ? ((Number) updates.get("bedrooms")).intValue() : null);
        if (updates.containsKey("bathrooms")) post.setBathrooms(updates.get("bathrooms") != null ? ((Number) updates.get("bathrooms")).intValue() : null);
        if (updates.containsKey("location")) post.setLocation((String) updates.get("location"));

        RealEstatePost saved = realEstatePostRepository.save(post);
        log.info("Real estate post admin-updated: id={}", id);
        return saved;
    }

    @Transactional
    public RealEstatePost userEditPost(Long id, Map<String, Object> updates, String username) {
        RealEstatePost post = realEstatePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getOwnerUserId().equals(user.getId())) {
            throw new RuntimeException("You can only edit your own posts");
        }

        if (post.getStatus() != PostStatus.APPROVED) {
            throw new RuntimeException("Only approved posts can be edited");
        }

        if (updates.containsKey("title")) post.setTitle((String) updates.get("title"));
        if (updates.containsKey("description")) post.setDescription((String) updates.get("description"));
        if (updates.containsKey("propertyType")) {
            try {
                post.setPropertyType(RealEstatePost.PropertyType.valueOf(((String) updates.get("propertyType")).toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid property type: " + updates.get("propertyType"));
            }
        }
        if (updates.containsKey("listingType")) {
            try {
                post.setListingType(RealEstatePost.ListingType.valueOf(((String) updates.get("listingType")).toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid listing type: " + updates.get("listingType"));
            }
        }
        if (updates.containsKey("price")) post.setPrice(updates.get("price") != null ? new java.math.BigDecimal(updates.get("price").toString()) : null);
        if (updates.containsKey("areaSqft")) post.setAreaSqft(updates.get("areaSqft") != null ? ((Number) updates.get("areaSqft")).intValue() : null);
        if (updates.containsKey("bedrooms")) post.setBedrooms(updates.get("bedrooms") != null ? ((Number) updates.get("bedrooms")).intValue() : null);
        if (updates.containsKey("bathrooms")) post.setBathrooms(updates.get("bathrooms") != null ? ((Number) updates.get("bathrooms")).intValue() : null);
        if (updates.containsKey("location")) post.setLocation((String) updates.get("location"));
        if (updates.containsKey("phone")) post.setOwnerPhone((String) updates.get("phone"));

        post.setStatus(PostStatus.PENDING_APPROVAL);

        RealEstatePost saved = realEstatePostRepository.save(post);
        log.info("Real estate post user-edited: id={}, userId={}", id, user.getId());
        return saved;
    }

    @Transactional
    public RealEstatePost renewPost(Long postId, String username) {
        RealEstatePost post = realEstatePostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getOwnerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the owner can renew a post");
        }

        int durationDays = Integer.parseInt(
                settingService.getSettingValue("real_estate.post.duration_days", "90"));

        post.setValidFrom(LocalDateTime.now());
        if (durationDays > 0) {
            post.setValidTo(LocalDateTime.now().plusDays(durationDays));
        }
        post.setExpiryReminderSent(false);
        post.setStatus(PostStatus.APPROVED);

        RealEstatePost saved = realEstatePostRepository.save(post);
        log.info("Real estate post renewed: id={}, newValidTo={}", postId, saved.getValidTo());
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

    private void notifyAdminsNewPost(RealEstatePost post) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("New Real Estate Listing")
                    .message("'" + post.getTitle() + "' (" + post.getPropertyType() + ") by " + post.getOwnerName() + " is pending approval.")
                    .type(Notification.NotificationType.ANNOUNCEMENT)
                    .priority(Notification.NotificationPriority.HIGH)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("REAL_ESTATE_POST")
                    .actionUrl("/admin/real-estate")
                    .actionText("Review Listing")
                    .icon("home")
                    .category("REAL_ESTATE")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for new real estate post: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to send admin notification for real estate post: {}", post.getId(), e);
        }
    }

    private void notifySellerPostStatus(RealEstatePost post, String message) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Real Estate Listing Update")
                    .message(message)
                    .type(Notification.NotificationType.INFO)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientId(post.getOwnerUserId())
                    .recipientType(Notification.RecipientType.USER)
                    .referenceId(post.getId())
                    .referenceType("REAL_ESTATE_POST")
                    .actionUrl("/real-estate/my-posts")
                    .actionText("View Listing")
                    .icon("home")
                    .category("REAL_ESTATE")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Owner notification sent for real estate post: id={}, owner={}", post.getId(), post.getOwnerUserId());
        } catch (Exception e) {
            log.error("Failed to send owner notification for real estate post: {}", post.getId(), e);
        }
    }

    private void notifyCustomersNewPost(RealEstatePost post) {
        try {
            Double lat = post.getLatitude();
            Double lng = post.getLongitude();
            if (lat == null || lng == null) {
                User owner = userRepository.findById(post.getOwnerUserId()).orElse(null);
                if (owner != null && owner.getCurrentLatitude() != null && owner.getCurrentLongitude() != null) {
                    lat = owner.getCurrentLatitude();
                    lng = owner.getCurrentLongitude();
                }
            }
            if (lat == null || lng == null) {
                log.info("Skipping location-based notification for real estate post {}: no location", post.getId());
                return;
            }

            double radiusKm = Double.parseDouble(
                    settingService.getSettingValue("notification.radius_km", "50"));

            List<User> nearbyCustomers = userRepository.findNearbyCustomers(lat, lng, radiusKm);
            if (nearbyCustomers.isEmpty()) return;

            List<Long> recipientIds = nearbyCustomers.stream()
                    .map(User::getId).collect(Collectors.toList());

            NotificationRequest request = NotificationRequest.builder()
                    .title("New Property Listed!")
                    .message(post.getTitle() + " - Check it out on NammaOoru")
                    .type(Notification.NotificationType.PROMOTION)
                    .priority(Notification.NotificationPriority.MEDIUM)
                    .recipientType(Notification.RecipientType.ALL_CUSTOMERS)
                    .sendPush(true)
                    .sendEmail(false)
                    .build();

            notificationService.sendNotificationToUsers(request, recipientIds);
            log.info("New real estate post notification sent to {} nearby customers", recipientIds.size());
        } catch (Exception e) {
            log.error("Failed to send new post notification for real estate post: {}", post.getId(), e);
        }
    }

    private void notifyOwnerPostReported(RealEstatePost post, int reportCount) {
        try {
            NotificationRequest request = NotificationRequest.builder()
                    .title("Your post has been reported")
                    .message("Your listing \"" + post.getTitle() + "\" has received " + reportCount + " report(s). Please review it.")
                    .type(Notification.NotificationType.WARNING)
                    .priority(Notification.NotificationPriority.HIGH)
                    .recipientId(post.getOwnerUserId())
                    .recipientType(Notification.RecipientType.USER)
                    .referenceId(post.getId())
                    .referenceType("POST_REPORT")
                    .sendPush(true)
                    .sendEmail(false)
                    .build();

            notificationService.createNotification(request);

            User owner = userRepository.findById(post.getOwnerUserId()).orElse(null);
            if (owner != null && owner.getEmail() != null) {
                emailService.sendPostReportedEmail(owner.getEmail(), owner.getFullName(),
                        post.getTitle(), "Real Estate", reportCount);
            }
            log.info("Post owner notified about report for real estate post: id={}", post.getId());
        } catch (Exception e) {
            log.error("Failed to notify post owner about report for real estate post: {}", post.getId(), e);
        }
    }

    @Transactional
    public RealEstatePost toggleFeatured(Long postId) {
        RealEstatePost post = realEstatePostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setIsFeatured(!Boolean.TRUE.equals(post.getIsFeatured()));
        RealEstatePost saved = realEstatePostRepository.save(post);
        log.info("Real estate post featured toggled: id={}, featured={}", postId, saved.getIsFeatured());
        return saved;
    }

    private void notifyAdminsFlaggedPost(RealEstatePost post, int reportCount) {
        try {
            List<Long> adminIds = getAdminUserIds();
            if (adminIds.isEmpty()) return;

            NotificationRequest request = NotificationRequest.builder()
                    .title("Real Estate Listing Flagged")
                    .message("'" + post.getTitle() + "' has been auto-flagged with " + reportCount + " reports. Please review.")
                    .type(Notification.NotificationType.WARNING)
                    .priority(Notification.NotificationPriority.URGENT)
                    .recipientIds(adminIds)
                    .recipientType(Notification.RecipientType.ADMIN)
                    .referenceId(post.getId())
                    .referenceType("REAL_ESTATE_POST")
                    .actionUrl("/admin/real-estate")
                    .actionText("Review Listing")
                    .icon("alert-triangle")
                    .category("REAL_ESTATE")
                    .sendPush(true)
                    .build();

            notificationService.createNotification(request);
            log.info("Admin notification sent for flagged real estate post: id={}, reports={}", post.getId(), reportCount);
        } catch (Exception e) {
            log.error("Failed to send admin notification for flagged real estate post: {}", post.getId(), e);
        }
    }
}
