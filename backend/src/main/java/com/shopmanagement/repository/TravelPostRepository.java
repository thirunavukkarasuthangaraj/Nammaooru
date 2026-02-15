package com.shopmanagement.repository;

import com.shopmanagement.entity.TravelPost;
import com.shopmanagement.entity.TravelPost.VehicleType;
import com.shopmanagement.entity.TravelPost.PostStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface TravelPostRepository extends JpaRepository<TravelPost, Long> {

    Page<TravelPost> findByStatusOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    List<TravelPost> findBySellerUserIdOrderByCreatedAtDesc(Long sellerUserId);

    Page<TravelPost> findByStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    Page<TravelPost> findByStatusAndVehicleTypeOrderByCreatedAtDesc(PostStatus status, VehicleType vehicleType, Pageable pageable);

    Page<TravelPost> findByStatusInAndVehicleTypeOrderByCreatedAtDesc(List<PostStatus> statuses, VehicleType vehicleType, Pageable pageable);

    Page<TravelPost> findByReportCountGreaterThanOrderByReportCountDesc(int minReportCount, Pageable pageable);

    Page<TravelPost> findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, LocalDateTime after, Pageable pageable);

    Page<TravelPost> findByStatusInAndVehicleTypeAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, VehicleType vehicleType, LocalDateTime after, Pageable pageable);

    long countByStatus(PostStatus status);

    long countByReportCountGreaterThan(int count);
}
