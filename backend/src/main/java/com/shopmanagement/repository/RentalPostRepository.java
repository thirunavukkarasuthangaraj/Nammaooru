package com.shopmanagement.repository;

import com.shopmanagement.entity.RentalPost;
import com.shopmanagement.entity.RentalPost.PostStatus;
import com.shopmanagement.entity.RentalPost.RentalCategory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface RentalPostRepository extends JpaRepository<RentalPost, Long> {

    Page<RentalPost> findByStatusOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    List<RentalPost> findBySellerUserIdOrderByCreatedAtDesc(Long sellerUserId);

    Page<RentalPost> findByStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    Page<RentalPost> findByStatusAndCategoryOrderByCreatedAtDesc(PostStatus status, RentalCategory category, Pageable pageable);

    Page<RentalPost> findByReportCountGreaterThanOrderByReportCountDesc(int minReportCount, Pageable pageable);

    Page<RentalPost> findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, LocalDateTime after, Pageable pageable);

    Page<RentalPost> findByStatusInAndCategoryAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, RentalCategory category, LocalDateTime after, Pageable pageable);

    long countByStatus(PostStatus status);

    long countByReportCountGreaterThan(int minReportCount);

    long countBySellerUserIdAndStatusIn(Long sellerUserId, List<PostStatus> statuses);

    Page<RentalPost> findByStatusAndIsPaidTrueOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    // Haversine nearby queries - posts with NULL lat/lng are always included
    @Query(value = "SELECT * FROM rental_posts rp WHERE rp.status = ANY(CAST(:statuses AS text[])) AND (" +
           "rp.latitude IS NULL OR rp.longitude IS NULL OR (" +
           "rp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "rp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(rp.latitude AS double precision))) * " +
           "cos(radians(CAST(rp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(rp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ") ORDER BY rp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<RentalPost> findNearbyPosts(@Param("statuses") String[] statuses,
                                     @Param("lat") double lat,
                                     @Param("lng") double lng,
                                     @Param("radiusKm") double radiusKm,
                                     @Param("limit") int limit,
                                     @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM rental_posts rp WHERE rp.status = ANY(CAST(:statuses AS text[])) AND (" +
           "rp.latitude IS NULL OR rp.longitude IS NULL OR (" +
           "rp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "rp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(rp.latitude AS double precision))) * " +
           "cos(radians(CAST(rp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(rp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ")",
           nativeQuery = true)
    long countNearbyPosts(@Param("statuses") String[] statuses,
                          @Param("lat") double lat,
                          @Param("lng") double lng,
                          @Param("radiusKm") double radiusKm);

    @Query(value = "SELECT * FROM rental_posts rp WHERE rp.status = ANY(CAST(:statuses AS text[])) AND " +
           "rp.category = CAST(:category AS text) AND (" +
           "rp.latitude IS NULL OR rp.longitude IS NULL OR (" +
           "rp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "rp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(rp.latitude AS double precision))) * " +
           "cos(radians(CAST(rp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(rp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ") ORDER BY rp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<RentalPost> findNearbyPostsByCategory(@Param("statuses") String[] statuses,
                                               @Param("category") String category,
                                               @Param("lat") double lat,
                                               @Param("lng") double lng,
                                               @Param("radiusKm") double radiusKm,
                                               @Param("limit") int limit,
                                               @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM rental_posts rp WHERE rp.status = ANY(CAST(:statuses AS text[])) AND " +
           "rp.category = CAST(:category AS text) AND (" +
           "rp.latitude IS NULL OR rp.longitude IS NULL OR (" +
           "rp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "rp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(rp.latitude AS double precision))) * " +
           "cos(radians(CAST(rp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(rp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ")",
           nativeQuery = true)
    long countNearbyPostsByCategory(@Param("statuses") String[] statuses,
                                    @Param("category") String category,
                                    @Param("lat") double lat,
                                    @Param("lng") double lng,
                                    @Param("radiusKm") double radiusKm);

    // Expiry reminder: posts expiring between now and reminderDate, not yet reminded, in active statuses
    List<RentalPost> findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(
            LocalDateTime from, LocalDateTime to, List<PostStatus> statuses);

    // Expired posts: valid_to before cutoff, in active statuses
    List<RentalPost> findByValidToBeforeAndStatusIn(LocalDateTime before, List<PostStatus> statuses);

    // Exclude deleted posts from "My Posts" listing
    List<RentalPost> findBySellerUserIdAndStatusNotOrderByCreatedAtDesc(Long sellerUserId, PostStatus status);

    // Find most recently deleted post by user (for balance day inheritance)
    Optional<RentalPost> findTopBySellerUserIdAndStatusOrderByUpdatedAtDesc(Long sellerUserId, PostStatus status);
}
