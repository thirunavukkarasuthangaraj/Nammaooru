package com.shopmanagement.repository;

import com.shopmanagement.entity.LabourPost;
import com.shopmanagement.entity.LabourPost.LabourCategory;
import com.shopmanagement.entity.LabourPost.PostStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface LabourPostRepository extends JpaRepository<LabourPost, Long> {

    Page<LabourPost> findByStatusOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    List<LabourPost> findBySellerUserIdOrderByCreatedAtDesc(Long sellerUserId);

    Page<LabourPost> findByStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    Page<LabourPost> findByStatusAndCategoryOrderByCreatedAtDesc(PostStatus status, LabourCategory category, Pageable pageable);

    Page<LabourPost> findByStatusInAndCategoryOrderByCreatedAtDesc(List<PostStatus> statuses, LabourCategory category, Pageable pageable);

    Page<LabourPost> findByReportCountGreaterThanOrderByReportCountDesc(int minReportCount, Pageable pageable);

    Page<LabourPost> findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, LocalDateTime after, Pageable pageable);

    Page<LabourPost> findByStatusInAndCategoryAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, LabourCategory category, LocalDateTime after, Pageable pageable);

    long countByStatus(PostStatus status);

    long countByReportCountGreaterThan(int count);
}
