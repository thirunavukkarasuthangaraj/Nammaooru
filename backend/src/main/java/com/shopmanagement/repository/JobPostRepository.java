package com.shopmanagement.repository;

import com.shopmanagement.entity.JobPost;
import com.shopmanagement.entity.JobPost.JobCategory;
import com.shopmanagement.entity.JobPost.PostStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface JobPostRepository extends JpaRepository<JobPost, Long> {

    Page<JobPost> findByStatusOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    Page<JobPost> findByStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    Page<JobPost> findByStatusAndCategoryOrderByCreatedAtDesc(PostStatus status, JobCategory category, Pageable pageable);

    Page<JobPost> findByStatusInAndCategoryOrderByCreatedAtDesc(List<PostStatus> statuses, JobCategory category, Pageable pageable);

    List<JobPost> findBySellerUserIdAndStatusNotOrderByCreatedAtDesc(Long sellerUserId, PostStatus status);

    long countByStatus(PostStatus status);

    long countByReportCountGreaterThan(int count);

    long countBySellerUserIdAndStatusIn(Long sellerUserId, List<PostStatus> statuses);

    Page<JobPost> findByReportCountGreaterThanOrderByReportCountDesc(int minReportCount, Pageable pageable);

    Page<JobPost> findByStatusInAndLocationContainingIgnoreCaseOrderByCreatedAtDesc(
            List<PostStatus> statuses, String location, Pageable pageable);

    List<JobPost> findByValidToBeforeAndStatusIn(LocalDateTime before, List<PostStatus> statuses);

    @Query(value = "SELECT * FROM jobs j WHERE j.status = ANY(CAST(:statuses AS text[])) AND " +
           "j.latitude IS NOT NULL AND j.longitude IS NOT NULL AND " +
           "j.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "j.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(j.latitude AS double precision))) * " +
           "cos(radians(CAST(j.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(j.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision) " +
           "ORDER BY j.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<JobPost> findNearbyPosts(@Param("statuses") String[] statuses,
                                  @Param("lat") double lat,
                                  @Param("lng") double lng,
                                  @Param("radiusKm") double radiusKm,
                                  @Param("limit") int limit,
                                  @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM jobs j WHERE j.status = ANY(CAST(:statuses AS text[])) AND " +
           "j.latitude IS NOT NULL AND j.longitude IS NOT NULL AND " +
           "j.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "j.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(j.latitude AS double precision))) * " +
           "cos(radians(CAST(j.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(j.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision)",
           nativeQuery = true)
    long countNearbyPosts(@Param("statuses") String[] statuses,
                          @Param("lat") double lat,
                          @Param("lng") double lng,
                          @Param("radiusKm") double radiusKm);
}
