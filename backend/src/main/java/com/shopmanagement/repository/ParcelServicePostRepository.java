package com.shopmanagement.repository;

import com.shopmanagement.entity.ParcelServicePost;
import com.shopmanagement.entity.ParcelServicePost.ServiceType;
import com.shopmanagement.entity.ParcelServicePost.PostStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ParcelServicePostRepository extends JpaRepository<ParcelServicePost, Long> {

    Page<ParcelServicePost> findByStatusOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    List<ParcelServicePost> findBySellerUserIdOrderByCreatedAtDesc(Long sellerUserId);

    Page<ParcelServicePost> findByStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    Page<ParcelServicePost> findByStatusAndServiceTypeOrderByCreatedAtDesc(PostStatus status, ServiceType serviceType, Pageable pageable);

    Page<ParcelServicePost> findByStatusInAndServiceTypeOrderByCreatedAtDesc(List<PostStatus> statuses, ServiceType serviceType, Pageable pageable);

    Page<ParcelServicePost> findByReportCountGreaterThanOrderByReportCountDesc(int minReportCount, Pageable pageable);

    Page<ParcelServicePost> findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, LocalDateTime after, Pageable pageable);

    Page<ParcelServicePost> findByStatusInAndServiceTypeAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, ServiceType serviceType, LocalDateTime after, Pageable pageable);

    long countByStatus(PostStatus status);

    long countByReportCountGreaterThan(int count);
}
