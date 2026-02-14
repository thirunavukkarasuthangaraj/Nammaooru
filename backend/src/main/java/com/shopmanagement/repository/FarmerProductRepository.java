package com.shopmanagement.repository;

import com.shopmanagement.entity.FarmerProduct;
import com.shopmanagement.entity.FarmerProduct.PostStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface FarmerProductRepository extends JpaRepository<FarmerProduct, Long> {

    Page<FarmerProduct> findByStatusOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    List<FarmerProduct> findBySellerUserIdOrderByCreatedAtDesc(Long sellerUserId);

    Page<FarmerProduct> findByStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    Page<FarmerProduct> findByStatusAndCategoryOrderByCreatedAtDesc(PostStatus status, String category, Pageable pageable);

    Page<FarmerProduct> findByReportCountGreaterThanOrderByReportCountDesc(int minReportCount, Pageable pageable);

    Page<FarmerProduct> findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, LocalDateTime after, Pageable pageable);

    Page<FarmerProduct> findByStatusInAndCategoryAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, String category, LocalDateTime after, Pageable pageable);
}
