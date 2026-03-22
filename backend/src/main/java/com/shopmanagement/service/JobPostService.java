package com.shopmanagement.service;

import com.shopmanagement.entity.JobPost;
import com.shopmanagement.entity.JobPost.JobCategory;
import com.shopmanagement.entity.JobPost.PostStatus;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.JobPostRepository;
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

@Service
@RequiredArgsConstructor
@Slf4j
public class JobPostService {

    private final JobPostRepository jobPostRepository;
    private final UserRepository userRepository;
    private final FileUploadService fileUploadService;
    private final NotificationService notificationService;
    private final SettingService settingService;
    private final GlobalPostLimitService globalPostLimitService;

    @Transactional
    public JobPost createPost(String jobTitle, String companyName, String phone,
                               String categoryStr, String jobType, String salary, String salaryType,
                               Integer vacancies, String location, String description, String requirements,
                               List<MultipartFile> images, String username,
                               BigDecimal latitude, BigDecimal longitude) throws IOException {

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        globalPostLimitService.checkGlobalPostLimit(user.getId(), null);

        int postLimit = Integer.parseInt(settingService.getSettingValue("jobs.free_post_limit", "3"));
        if (postLimit > 0) {
            List<PostStatus> activeStatuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED);
            long activeCount = jobPostRepository.countBySellerUserIdAndStatusIn(user.getId(), activeStatuses);
            if (activeCount >= postLimit) {
                throw new RuntimeException("LIMIT_REACHED");
            }
        }

        JobCategory category;
        try {
            category = JobCategory.valueOf(categoryStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            category = JobCategory.OTHER;
        }

        JobPost.JobType jobTypeEnum;
        try {
            jobTypeEnum = JobPost.JobType.valueOf(jobType != null ? jobType.toUpperCase() : "FULL_TIME");
        } catch (IllegalArgumentException e) {
            jobTypeEnum = JobPost.JobType.FULL_TIME;
        }

        // Upload images
        List<String> imageUrls = new ArrayList<>();
        if (images != null) {
            for (MultipartFile image : images) {
                if (image != null && !image.isEmpty()) {
                    String url = fileUploadService.uploadFile(image, "jobs");
                    imageUrls.add(url);
                }
            }
        }

        int expiryDays = Integer.parseInt(settingService.getSettingValue("jobs.expiry_days", "30"));

        JobPost post = JobPost.builder()
                .jobTitle(jobTitle)
                .companyName(companyName)
                .phone(phone)
                .category(category)
                .jobType(jobTypeEnum)
                .salary(salary)
                .salaryType(salaryType != null ? salaryType : "MONTHLY")
                .vacancies(vacancies)
                .location(location)
                .description(description)
                .requirements(requirements)
                .imageUrls(imageUrls.isEmpty() ? null : String.join(",", imageUrls))
                .latitude(latitude)
                .longitude(longitude)
                .sellerUserId(user.getId())
                .sellerName(user.getFullName() != null ? user.getFullName() : user.getUsername())
                .status(PostStatus.PENDING_APPROVAL)
                .validFrom(LocalDateTime.now())
                .validTo(LocalDateTime.now().plusDays(expiryDays))
                .build();

        post = jobPostRepository.save(post);
        log.info("Job post created: id={}, title={}, user={}", post.getId(), jobTitle, username);
        return post;
    }

    public Page<JobPost> getApprovedPosts(String category, Double lat, Double lng, Double radius,
                                           String search, Pageable pageable) {
        List<PostStatus> activeStatuses = List.of(PostStatus.APPROVED);

        if (search != null && !search.trim().isEmpty()) {
            return jobPostRepository.findByStatusInAndLocationContainingIgnoreCaseOrderByCreatedAtDesc(
                    activeStatuses, search.trim(), pageable);
        }

        if (lat != null && lng != null && radius != null) {
            double radiusKm = radius;
            int limit = pageable.getPageSize();
            int offset = (int) pageable.getOffset();
            String[] statuses = activeStatuses.stream().map(Enum::name).toArray(String[]::new);

            List<JobPost> posts;
            long total;
            if (category != null && !category.isEmpty()) {
                try {
                    JobCategory cat = JobCategory.valueOf(category.toUpperCase());
                    posts = jobPostRepository.findNearbyPosts(statuses, lat, lng, radiusKm, limit, offset);
                    posts = posts.stream().filter(p -> p.getCategory() == cat).toList();
                    total = posts.size();
                } catch (IllegalArgumentException e) {
                    posts = jobPostRepository.findNearbyPosts(statuses, lat, lng, radiusKm, limit, offset);
                    total = jobPostRepository.countNearbyPosts(statuses, lat, lng, radiusKm);
                }
            } else {
                posts = jobPostRepository.findNearbyPosts(statuses, lat, lng, radiusKm, limit, offset);
                total = jobPostRepository.countNearbyPosts(statuses, lat, lng, radiusKm);
            }
            return new PageImpl<>(posts, pageable, total);
        }

        if (category != null && !category.isEmpty()) {
            try {
                JobCategory cat = JobCategory.valueOf(category.toUpperCase());
                return jobPostRepository.findByStatusAndCategoryOrderByCreatedAtDesc(PostStatus.APPROVED, cat, pageable);
            } catch (IllegalArgumentException e) {
                // fall through
            }
        }

        return jobPostRepository.findByStatusOrderByCreatedAtDesc(PostStatus.APPROVED, pageable);
    }

    public List<JobPost> getMyPosts(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return jobPostRepository.findBySellerUserIdAndStatusNotOrderByCreatedAtDesc(
                user.getId(), PostStatus.DELETED);
    }

    @Transactional
    public JobPost approve(Long postId) {
        JobPost post = jobPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Job post not found"));
        post.setStatus(PostStatus.APPROVED);
        post.setValidFrom(LocalDateTime.now());
        int expiryDays = Integer.parseInt(settingService.getSettingValue("jobs.expiry_days", "30"));
        post.setValidTo(LocalDateTime.now().plusDays(expiryDays));
        return jobPostRepository.save(post);
    }

    @Transactional
    public JobPost reject(Long postId, String reason) {
        JobPost post = jobPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Job post not found"));
        post.setStatus(PostStatus.REJECTED);
        return jobPostRepository.save(post);
    }

    @Transactional
    public void delete(Long postId, String username) {
        JobPost post = jobPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Job post not found"));
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Not authorized to delete this post");
        }
        post.setStatus(PostStatus.DELETED);
        jobPostRepository.save(post);
    }

    @Transactional
    public void adminDelete(Long postId) {
        JobPost post = jobPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Job post not found"));
        post.setStatus(PostStatus.DELETED);
        jobPostRepository.save(post);
    }

    @Transactional
    public JobPost report(Long postId, String reason, String details) {
        JobPost post = jobPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Job post not found"));
        post.setReportCount(post.getReportCount() + 1);
        return jobPostRepository.save(post);
    }

    public Page<JobPost> getAllForAdmin(String status, Pageable pageable) {
        if (status != null && !status.isEmpty()) {
            try {
                PostStatus s = PostStatus.valueOf(status.toUpperCase());
                return jobPostRepository.findByStatusOrderByCreatedAtDesc(s, pageable);
            } catch (IllegalArgumentException e) {
                // fall through
            }
        }
        return jobPostRepository.findByStatusInOrderByCreatedAtDesc(
                List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED, PostStatus.REJECTED), pageable);
    }

    public Page<JobPost> getReportedPosts(Pageable pageable) {
        return jobPostRepository.findByReportCountGreaterThanOrderByReportCountDesc(0, pageable);
    }

    public Map<String, Long> getStats() {
        return Map.of(
                "total", jobPostRepository.count(),
                "pending", jobPostRepository.countByStatus(PostStatus.PENDING_APPROVAL),
                "approved", jobPostRepository.countByStatus(PostStatus.APPROVED),
                "rejected", jobPostRepository.countByStatus(PostStatus.REJECTED),
                "reported", jobPostRepository.countByReportCountGreaterThan(0)
        );
    }
}
