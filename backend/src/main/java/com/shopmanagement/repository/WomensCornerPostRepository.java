package com.shopmanagement.repository;

import com.shopmanagement.entity.WomensCornerPost;
import com.shopmanagement.entity.WomensCornerPost.PostStatus;
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
public interface WomensCornerPostRepository extends JpaRepository<WomensCornerPost, Long> {

    Page<WomensCornerPost> findByStatusOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    Page<WomensCornerPost> findByStatusAndIsPaidTrueOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    List<WomensCornerPost> findBySellerUserIdOrderByCreatedAtDesc(Long sellerUserId);

    Page<WomensCornerPost> findByStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    Page<WomensCornerPost> findByStatusAndCategoryOrderByCreatedAtDesc(PostStatus status, String category, Pageable pageable);

    Page<WomensCornerPost> findByReportCountGreaterThanOrderByReportCountDesc(int minReportCount, Pageable pageable);

    Page<WomensCornerPost> findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, LocalDateTime after, Pageable pageable);

    Page<WomensCornerPost> findByStatusInAndCategoryAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, String category, LocalDateTime after, Pageable pageable);

    Page<WomensCornerPost> findByFeaturedTrueAndStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    long countByStatus(PostStatus status);

    long countByReportCountGreaterThan(int minReportCount);

    long countBySellerUserIdAndStatusIn(Long sellerUserId, List<PostStatus> statuses);

    // Haversine nearby queries - posts with NULL lat/lng are always included
    @Query(value = "SELECT * FROM womens_corner_posts fp WHERE fp.status = ANY(CAST(:statuses AS text[])) AND (" +
           "fp.latitude IS NULL OR fp.longitude IS NULL OR (" +
           "fp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "fp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(fp.latitude AS double precision))) * " +
           "cos(radians(CAST(fp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(fp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ") ORDER BY fp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<WomensCornerPost> findNearbyPosts(@Param("statuses") String[] statuses,
                                     @Param("lat") double lat,
                                     @Param("lng") double lng,
                                     @Param("radiusKm") double radiusKm,
                                     @Param("limit") int limit,
                                     @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM womens_corner_posts fp WHERE fp.status = ANY(CAST(:statuses AS text[])) AND (" +
           "fp.latitude IS NULL OR fp.longitude IS NULL OR (" +
           "fp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "fp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(fp.latitude AS double precision))) * " +
           "cos(radians(CAST(fp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(fp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ")",
           nativeQuery = true)
    long countNearbyPosts(@Param("statuses") String[] statuses,
                          @Param("lat") double lat,
                          @Param("lng") double lng,
                          @Param("radiusKm") double radiusKm);

    @Query(value = "SELECT * FROM womens_corner_posts fp WHERE fp.status = ANY(CAST(:statuses AS text[])) AND " +
           "fp.category = CAST(:category AS text) AND (" +
           "fp.latitude IS NULL OR fp.longitude IS NULL OR (" +
           "fp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "fp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(fp.latitude AS double precision))) * " +
           "cos(radians(CAST(fp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(fp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ") ORDER BY fp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<WomensCornerPost> findNearbyPostsByCategory(@Param("statuses") String[] statuses,
                                               @Param("category") String category,
                                               @Param("lat") double lat,
                                               @Param("lng") double lng,
                                               @Param("radiusKm") double radiusKm,
                                               @Param("limit") int limit,
                                               @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM womens_corner_posts fp WHERE fp.status = ANY(CAST(:statuses AS text[])) AND " +
           "fp.category = CAST(:category AS text) AND (" +
           "fp.latitude IS NULL OR fp.longitude IS NULL OR (" +
           "fp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "fp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(fp.latitude AS double precision))) * " +
           "cos(radians(CAST(fp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(fp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ")",
           nativeQuery = true)
    long countNearbyPostsByCategory(@Param("statuses") String[] statuses,
                                    @Param("category") String category,
                                    @Param("lat") double lat,
                                    @Param("lng") double lng,
                                    @Param("radiusKm") double radiusKm);

    // Location text search
    Page<WomensCornerPost> findByStatusInAndLocationContainingIgnoreCaseOrderByCreatedAtDesc(
            List<PostStatus> statuses, String location, Pageable pageable);

    // Expiry reminder
    List<WomensCornerPost> findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(
            LocalDateTime from, LocalDateTime to, List<PostStatus> statuses);

    // Expired posts
    List<WomensCornerPost> findByValidToBeforeAndStatusIn(LocalDateTime before, List<PostStatus> statuses);

    // Exclude deleted posts from "My Posts"
    List<WomensCornerPost> findBySellerUserIdAndStatusNotOrderByCreatedAtDesc(Long sellerUserId, PostStatus status);

    // Balance day inheritance
    Optional<WomensCornerPost> findTopBySellerUserIdAndStatusOrderByUpdatedAtDesc(Long sellerUserId, PostStatus status);
}
