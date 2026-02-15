package com.shopmanagement.repository;

import com.shopmanagement.entity.MarketplacePost;
import com.shopmanagement.entity.MarketplacePost.PostStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface MarketplacePostRepository extends JpaRepository<MarketplacePost, Long> {

    Page<MarketplacePost> findByStatusOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    List<MarketplacePost> findBySellerUserIdOrderByCreatedAtDesc(Long sellerUserId);

    Page<MarketplacePost> findByStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    Page<MarketplacePost> findByStatusAndCategoryOrderByCreatedAtDesc(PostStatus status, String category, Pageable pageable);

    Page<MarketplacePost> findByReportCountGreaterThanOrderByReportCountDesc(int minReportCount, Pageable pageable);

    Page<MarketplacePost> findByStatusOrReportCountGreaterThanOrderByReportCountDesc(PostStatus status, int minReportCount, Pageable pageable);

    Page<MarketplacePost> findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, LocalDateTime after, Pageable pageable);

    Page<MarketplacePost> findByStatusInAndCategoryAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, String category, LocalDateTime after, Pageable pageable);

    long countByStatus(PostStatus status);

    long countByReportCountGreaterThan(int minReportCount);

    long countBySellerUserIdAndStatusIn(Long sellerUserId, List<PostStatus> statuses);
}
