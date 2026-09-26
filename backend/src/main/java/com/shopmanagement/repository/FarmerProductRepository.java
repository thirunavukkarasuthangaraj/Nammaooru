package com.shopmanagement.repository;

import com.shopmanagement.entity.FarmerProduct;
import com.shopmanagement.entity.FarmerProduct.PostStatus;
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
public interface FarmerProductRepository extends JpaRepository<FarmerProduct, Long> {

    Page<FarmerProduct> findByStatusOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    Page<FarmerProduct> findByStatusAndIsPaidTrueOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    List<FarmerProduct> findBySellerUserIdOrderByCreatedAtDesc(Long sellerUserId);

    Page<FarmerProduct> findByStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    Page<FarmerProduct> findByStatusAndCategoryOrderByCreatedAtDesc(PostStatus status, String category, Pageable pageable);

    Page<FarmerProduct> findByReportCountGreaterThanOrderByReportCountDesc(int minReportCount, Pageable pageable);

    Page<FarmerProduct> findByReportCountGreaterThanAndStatusNotInOrderByReportCountDesc(int minReportCount, List<PostStatus> excludedStatuses, Pageable pageable);

    Page<FarmerProduct> findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, LocalDateTime after, Pageable pageable);

    Page<FarmerProduct> findByStatusInAndCategoryAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, String category, LocalDateTime after, Pageable pageable);

    Page<FarmerProduct> findByFeaturedTrueAndStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    long countByStatus(PostStatus status);

    long countByReportCountGreaterThan(int minReportCount);

    long countBySellerUserIdAndStatusIn(Long sellerUserId, List<PostStatus> statuses);

    long countByStatusIn(List<PostStatus> statuses);

    long countByStatusInAndCategory(List<PostStatus> statuses, String category);

    // "All" distance filter - no radius cap, so every approved post is shown.
    // Posts with saved coordinates are ordered nearest-first; posts without
    // coordinates (can't compute a distance) sort after all of those instead
    // of being excluded like the radius-bounded queries below.
    @Query(value = "SELECT * FROM farmer_products fp WHERE fp.status = ANY(CAST(:statuses AS text[])) " +
           "ORDER BY (CASE WHEN fp.latitude IS NOT NULL AND fp.longitude IS NOT NULL THEN " +
           "6371 * acos(LEAST(1.0, GREATEST(-1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(fp.latitude AS double precision))) * " +
           "cos(radians(CAST(fp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(fp.latitude AS double precision)))))) ELSE NULL END) ASC NULLS LAST, " +
           "fp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<FarmerProduct> findAllSortedByDistance(@Param("statuses") String[] statuses,
                                                @Param("lat") double lat,
                                                @Param("lng") double lng,
                                                @Param("limit") int limit,
                                                @Param("offset") int offset);

    @Query(value = "SELECT * FROM farmer_products fp WHERE fp.status = ANY(CAST(:statuses AS text[])) AND " +
           "fp.category = CAST(:category AS text) " +
           "ORDER BY (CASE WHEN fp.latitude IS NOT NULL AND fp.longitude IS NOT NULL THEN " +
           "6371 * acos(LEAST(1.0, GREATEST(-1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(fp.latitude AS double precision))) * " +
           "cos(radians(CAST(fp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(fp.latitude AS double precision)))))) ELSE NULL END) ASC NULLS LAST, " +
           "fp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<FarmerProduct> findAllByCategorySortedByDistance(@Param("statuses") String[] statuses,
                                                          @Param("category") String category,
                                                          @Param("lat") double lat,
                                                          @Param("lng") double lng,
                                                          @Param("limit") int limit,
                                                          @Param("offset") int offset);

    // Haversine nearby queries - only posts with valid coordinates within radius
    @Query(value = "SELECT * FROM farmer_products fp WHERE fp.status = ANY(CAST(:statuses AS text[])) AND " +
           "fp.latitude IS NOT NULL AND fp.longitude IS NOT NULL AND " +
           "fp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "fp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(fp.latitude AS double precision))) * " +
           "cos(radians(CAST(fp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(fp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision) " +
           "ORDER BY fp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<FarmerProduct> findNearbyPosts(@Param("statuses") String[] statuses,
                                     @Param("lat") double lat,
                                     @Param("lng") double lng,
                                     @Param("radiusKm") double radiusKm,
                                     @Param("limit") int limit,
                                     @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM farmer_products fp WHERE fp.status = ANY(CAST(:statuses AS text[])) AND " +
           "fp.latitude IS NOT NULL AND fp.longitude IS NOT NULL AND " +
           "fp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "fp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(fp.latitude AS double precision))) * " +
           "cos(radians(CAST(fp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(fp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision)",
           nativeQuery = true)
    long countNearbyPosts(@Param("statuses") String[] statuses,
                          @Param("lat") double lat,
                          @Param("lng") double lng,
                          @Param("radiusKm") double radiusKm);

    @Query(value = "SELECT * FROM farmer_products fp WHERE fp.status = ANY(CAST(:statuses AS text[])) AND " +
           "fp.category = CAST(:category AS text) AND " +
           "fp.latitude IS NOT NULL AND fp.longitude IS NOT NULL AND " +
           "fp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "fp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(fp.latitude AS double precision))) * " +
           "cos(radians(CAST(fp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(fp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision) " +
           "ORDER BY fp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<FarmerProduct> findNearbyPostsByCategory(@Param("statuses") String[] statuses,
                                               @Param("category") String category,
                                               @Param("lat") double lat,
                                               @Param("lng") double lng,
                                               @Param("radiusKm") double radiusKm,
                                               @Param("limit") int limit,
                                               @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM farmer_products fp WHERE fp.status = ANY(CAST(:statuses AS text[])) AND " +
           "fp.category = CAST(:category AS text) AND " +
           "fp.latitude IS NOT NULL AND fp.longitude IS NOT NULL AND " +
           "fp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "fp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(fp.latitude AS double precision))) * " +
           "cos(radians(CAST(fp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(fp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision)",
           nativeQuery = true)
    long countNearbyPostsByCategory(@Param("statuses") String[] statuses,
                                    @Param("category") String category,
                                    @Param("lat") double lat,
                                    @Param("lng") double lng,
                                    @Param("radiusKm") double radiusKm);

    // Location text search
    Page<FarmerProduct> findByStatusInAndLocationContainingIgnoreCaseOrderByCreatedAtDesc(
            List<PostStatus> statuses, String location, Pageable pageable);

    // Expiry reminder: posts expiring between now and reminderDate, not yet reminded, in active statuses
    List<FarmerProduct> findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(
            LocalDateTime from, LocalDateTime to, List<PostStatus> statuses);

    // Expired posts: valid_to before cutoff, in active statuses
    List<FarmerProduct> findByValidToBeforeAndStatusIn(LocalDateTime before, List<PostStatus> statuses);

    // Exclude deleted posts from "My Posts" listing
    List<FarmerProduct> findBySellerUserIdAndStatusNotOrderByCreatedAtDesc(Long sellerUserId, PostStatus status);

    // Find most recently deleted post by user (for balance day inheritance)
    Optional<FarmerProduct> findTopBySellerUserIdAndStatusOrderByUpdatedAtDesc(Long sellerUserId, PostStatus status);
}
