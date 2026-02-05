package com.shopmanagement.service;

import com.shopmanagement.entity.RealEstatePost;
import com.shopmanagement.entity.RealEstatePost.ListingType;
import com.shopmanagement.entity.RealEstatePost.PostStatus;
import com.shopmanagement.entity.RealEstatePost.PropertyType;
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
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class RealEstateService {

    private final RealEstatePostRepository realEstatePostRepository;
    private final UserRepository userRepository;
    private final FileUploadService fileUploadService;

    @Transactional
    public RealEstatePost createPost(String title, String description, PropertyType propertyType,
                                      ListingType listingType, BigDecimal price, Integer areaSqft,
                                      Integer bedrooms, Integer bathrooms, String location,
                                      Double latitude, Double longitude, String phone,
                                      List<MultipartFile> images, MultipartFile video,
                                      String username) throws IOException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

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
                .status(PostStatus.PENDING_APPROVAL)
                .build();

        RealEstatePost saved = realEstatePostRepository.save(post);
        log.info("Real estate post created: id={}, title={}, type={}, owner={}",
                saved.getId(), title, propertyType, username);
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
        return realEstatePostRepository.findByOwnerUserIdOrderByCreatedAtDesc(user.getId());
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
        log.info("Real estate post approved: id={}", id);
        return realEstatePostRepository.save(post);
    }

    @Transactional
    public RealEstatePost rejectPost(Long id) {
        RealEstatePost post = realEstatePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.REJECTED);
        log.info("Real estate post rejected: id={}", id);
        return realEstatePostRepository.save(post);
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

        realEstatePostRepository.delete(post);
        log.info("Real estate post deleted: id={}", id);
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

        // Auto-flag if 3+ reports
        if (newCount >= 3 && post.getStatus() == PostStatus.APPROVED) {
            post.setStatus(PostStatus.FLAGGED);
            log.warn("Real estate post auto-flagged due to {} reports: id={}, title={}",
                    newCount, postId, post.getTitle());
        }

        realEstatePostRepository.save(post);
        log.info("Real estate post reported: id={}, reason={}, reportCount={}", postId, reason, newCount);
    }
}
