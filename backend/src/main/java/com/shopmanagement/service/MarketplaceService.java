package com.shopmanagement.service;

import com.shopmanagement.entity.MarketplacePost;
import com.shopmanagement.entity.MarketplacePost.PostStatus;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.MarketplacePostRepository;
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
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class MarketplaceService {

    private final MarketplacePostRepository marketplacePostRepository;
    private final UserRepository userRepository;
    private final FileUploadService fileUploadService;

    @Transactional
    public MarketplacePost createPost(String title, String description, BigDecimal price,
                                       String phone, String category, String location,
                                       MultipartFile image, MultipartFile voice,
                                       String username) throws IOException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        String imageUrl = null;
        if (image != null && !image.isEmpty()) {
            imageUrl = fileUploadService.uploadFile(image, "marketplace");
        }

        String voiceUrl = null;
        if (voice != null && !voice.isEmpty()) {
            voiceUrl = fileUploadService.uploadVoiceFile(voice, "marketplace/voice");
        }

        MarketplacePost post = MarketplacePost.builder()
                .title(title)
                .description(description)
                .price(price)
                .imageUrl(imageUrl)
                .voiceUrl(voiceUrl)
                .sellerUserId(user.getId())
                .sellerName(user.getFullName())
                .sellerPhone(phone)
                .category(category)
                .location(location)
                .status(PostStatus.PENDING_APPROVAL)
                .build();

        MarketplacePost saved = marketplacePostRepository.save(post);
        log.info("Marketplace post created: id={}, title={}, seller={}", saved.getId(), title, username);
        return saved;
    }

    @Transactional(readOnly = true)
    public Page<MarketplacePost> getApprovedPosts(Pageable pageable) {
        return marketplacePostRepository.findByStatusOrderByCreatedAtDesc(PostStatus.APPROVED, pageable);
    }

    @Transactional(readOnly = true)
    public Page<MarketplacePost> getApprovedPostsByCategory(String category, Pageable pageable) {
        return marketplacePostRepository.findByStatusAndCategoryOrderByCreatedAtDesc(
                PostStatus.APPROVED, category, pageable);
    }

    @Transactional(readOnly = true)
    public List<MarketplacePost> getMyPosts(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return marketplacePostRepository.findBySellerUserIdOrderByCreatedAtDesc(user.getId());
    }

    @Transactional(readOnly = true)
    public Page<MarketplacePost> getPendingPosts(Pageable pageable) {
        return marketplacePostRepository.findByStatusOrderByCreatedAtDesc(PostStatus.PENDING_APPROVAL, pageable);
    }

    @Transactional(readOnly = true)
    public Page<MarketplacePost> getAllPostsForAdmin(Pageable pageable) {
        List<PostStatus> statuses = List.of(PostStatus.PENDING_APPROVAL, PostStatus.APPROVED, PostStatus.REJECTED, PostStatus.SOLD);
        return marketplacePostRepository.findByStatusInOrderByCreatedAtDesc(statuses, pageable);
    }

    @Transactional
    public MarketplacePost approvePost(Long id) {
        MarketplacePost post = marketplacePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.APPROVED);
        log.info("Marketplace post approved: id={}", id);
        return marketplacePostRepository.save(post);
    }

    @Transactional
    public MarketplacePost rejectPost(Long id) {
        MarketplacePost post = marketplacePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        post.setStatus(PostStatus.REJECTED);
        log.info("Marketplace post rejected: id={}", id);
        return marketplacePostRepository.save(post);
    }

    @Transactional
    public MarketplacePost markAsSold(Long id, String username) {
        MarketplacePost post = marketplacePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!post.getSellerUserId().equals(user.getId())) {
            throw new RuntimeException("Only the seller can mark a post as sold");
        }

        post.setStatus(PostStatus.SOLD);
        log.info("Marketplace post marked as sold: id={}", id);
        return marketplacePostRepository.save(post);
    }

    @Transactional
    public void deletePost(Long id, String username, boolean isAdmin) {
        MarketplacePost post = marketplacePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        if (!isAdmin) {
            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            if (!post.getSellerUserId().equals(user.getId())) {
                throw new RuntimeException("Only the seller or admin can delete a post");
            }
        }

        marketplacePostRepository.delete(post);
        log.info("Marketplace post deleted: id={}", id);
    }

    @Transactional(readOnly = true)
    public MarketplacePost getPostById(Long id) {
        return marketplacePostRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
    }

    // Report feature will be added later
    @Transactional
    public void reportPost(Long postId, String reason, String details, String username) {
        MarketplacePost post = marketplacePostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        // Simple report - just increment count (full report tracking will be added later)
        int newCount = (post.getReportCount() != null ? post.getReportCount() : 0) + 1;
        post.setReportCount(newCount);

        // Auto-flag if 3+ reports
        if (newCount >= 3 && post.getStatus() == PostStatus.APPROVED) {
            post.setStatus(PostStatus.FLAGGED);
            log.warn("Marketplace post auto-flagged due to {} reports: id={}, title={}", newCount, postId, post.getTitle());
        }

        marketplacePostRepository.save(post);
        log.info("Marketplace post reported: id={}, reason={}, reportCount={}", postId, reason, newCount);
    }
}
