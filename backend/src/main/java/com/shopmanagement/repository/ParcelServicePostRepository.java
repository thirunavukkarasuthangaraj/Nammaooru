package com.shopmanagement.repository;

import com.shopmanagement.entity.ParcelServicePost;
import com.shopmanagement.entity.ParcelServicePost.ServiceType;
import com.shopmanagement.entity.ParcelServicePost.PostStatus;
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
public interface ParcelServicePostRepository extends JpaRepository<ParcelServicePost, Long> {

    Page<ParcelServicePost> findByStatusOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    Page<ParcelServicePost> findByStatusAndIsPaidTrueOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    List<ParcelServicePost> findBySellerUserIdOrderByCreatedAtDesc(Long sellerUserId);

    Page<ParcelServicePost> findByStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    Page<ParcelServicePost> findByStatusAndServiceTypeOrderByCreatedAtDesc(PostStatus status, ServiceType serviceType, Pageable pageable);

    Page<ParcelServicePost> findByStatusInAndServiceTypeOrderByCreatedAtDesc(List<PostStatus> statuses, ServiceType serviceType, Pageable pageable);

    Page<ParcelServicePost> findByReportCountGreaterThanOrderByReportCountDesc(int minReportCount, Pageable pageable);

    Page<ParcelServicePost> findByReportCountGreaterThanAndStatusNotInOrderByReportCountDesc(int minReportCount, List<PostStatus> excludedStatuses, Pageable pageable);

    Page<ParcelServicePost> findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, LocalDateTime after, Pageable pageable);

    Page<ParcelServicePost> findByStatusInAndServiceTypeAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, ServiceType serviceType, LocalDateTime after, Pageable pageable);

    long countByStatus(PostStatus status);

    long countByReportCountGreaterThan(int count);

    long countBySellerUserIdAndStatusIn(Long sellerUserId, List<PostStatus> statuses);

    long countByStatusIn(List<PostStatus> statuses);

    long countByStatusInAndServiceType(List<PostStatus> statuses, ServiceType serviceType);

    // "All" distance filter - no radius cap, so every approved post is shown.
    // Posts with saved coordinates are ordered nearest-first; posts without
    // coordinates (can't compute a distance) sort after all of those instead
    // of being excluded like the radius-bounded queries below.
    @Query(value = "SELECT * FROM parcel_service_posts pp WHERE pp.status = ANY(CAST(:statuses AS text[])) " +
           "ORDER BY (CASE WHEN pp.latitude IS NOT NULL AND pp.longitude IS NOT NULL THEN " +
           "6371 * acos(LEAST(1.0, GREATEST(-1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(pp.latitude AS double precision))) * " +
           "cos(radians(CAST(pp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(pp.latitude AS double precision)))))) ELSE NULL END) ASC NULLS LAST, " +
           "pp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<ParcelServicePost> findAllSortedByDistance(@Param("statuses") String[] statuses,
                                                    @Param("lat") double lat,
                                                    @Param("lng") double lng,
                                                    @Param("limit") int limit,
                                                    @Param("offset") int offset);

    @Query(value = "SELECT * FROM parcel_service_posts pp WHERE pp.status = ANY(CAST(:statuses AS text[])) AND " +
           "pp.service_type = CAST(:serviceType AS text) " +
           "ORDER BY (CASE WHEN pp.latitude IS NOT NULL AND pp.longitude IS NOT NULL THEN " +
           "6371 * acos(LEAST(1.0, GREATEST(-1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(pp.latitude AS double precision))) * " +
           "cos(radians(CAST(pp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(pp.latitude AS double precision)))))) ELSE NULL END) ASC NULLS LAST, " +
           "pp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<ParcelServicePost> findAllByServiceTypeSortedByDistance(@Param("statuses") String[] statuses,
                                                                  @Param("serviceType") String serviceType,
                                                                  @Param("lat") double lat,
                                                                  @Param("lng") double lng,
                                                                  @Param("limit") int limit,
                                                                  @Param("offset") int offset);

    // Haversine nearby queries - only posts with valid coordinates within radius
    @Query(value = "SELECT * FROM parcel_service_posts pp WHERE pp.status = ANY(CAST(:statuses AS text[])) AND " +
           "pp.latitude IS NOT NULL AND pp.longitude IS NOT NULL AND " +
           "pp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "pp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(pp.latitude AS double precision))) * " +
           "cos(radians(CAST(pp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(pp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision) " +
           "ORDER BY pp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<ParcelServicePost> findNearbyPosts(@Param("statuses") String[] statuses,
                                            @Param("lat") double lat,
                                            @Param("lng") double lng,
                                            @Param("radiusKm") double radiusKm,
                                            @Param("limit") int limit,
                                            @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM parcel_service_posts pp WHERE pp.status = ANY(CAST(:statuses AS text[])) AND " +
           "pp.latitude IS NOT NULL AND pp.longitude IS NOT NULL AND " +
           "pp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "pp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(pp.latitude AS double precision))) * " +
           "cos(radians(CAST(pp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(pp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision)",
           nativeQuery = true)
    long countNearbyPosts(@Param("statuses") String[] statuses,
                          @Param("lat") double lat,
                          @Param("lng") double lng,
                          @Param("radiusKm") double radiusKm);

    @Query(value = "SELECT * FROM parcel_service_posts pp WHERE pp.status = ANY(CAST(:statuses AS text[])) AND " +
           "pp.service_type = CAST(:serviceType AS text) AND " +
           "pp.latitude IS NOT NULL AND pp.longitude IS NOT NULL AND " +
           "pp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "pp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(pp.latitude AS double precision))) * " +
           "cos(radians(CAST(pp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(pp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision) " +
           "ORDER BY pp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<ParcelServicePost> findNearbyPostsByServiceType(@Param("statuses") String[] statuses,
                                                         @Param("serviceType") String serviceType,
                                                         @Param("lat") double lat,
                                                         @Param("lng") double lng,
                                                         @Param("radiusKm") double radiusKm,
                                                         @Param("limit") int limit,
                                                         @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM parcel_service_posts pp WHERE pp.status = ANY(CAST(:statuses AS text[])) AND " +
           "pp.service_type = CAST(:serviceType AS text) AND " +
           "pp.latitude IS NOT NULL AND pp.longitude IS NOT NULL AND " +
           "pp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "pp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(pp.latitude AS double precision))) * " +
           "cos(radians(CAST(pp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(pp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision)",
           nativeQuery = true)
    long countNearbyPostsByServiceType(@Param("statuses") String[] statuses,
                                       @Param("serviceType") String serviceType,
                                       @Param("lat") double lat,
                                       @Param("lng") double lng,
                                       @Param("radiusKm") double radiusKm);

    // Location text search (searches fromLocation OR toLocation)
    @Query("SELECT p FROM ParcelServicePost p WHERE p.status IN :statuses AND " +
           "(LOWER(p.fromLocation) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(p.toLocation) LIKE LOWER(CONCAT('%', :search, '%'))) " +
           "ORDER BY p.createdAt DESC")
    Page<ParcelServicePost> searchByLocation(@Param("statuses") List<PostStatus> statuses,
                                              @Param("search") String search,
                                              Pageable pageable);

    // Expiry reminder: posts expiring between now and reminderDate, not yet reminded, in active statuses
    List<ParcelServicePost> findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(
            LocalDateTime from, LocalDateTime to, List<ParcelServicePost.PostStatus> statuses);

    // Expired posts: valid_to before cutoff, in active statuses
    List<ParcelServicePost> findByValidToBeforeAndStatusIn(LocalDateTime before, List<ParcelServicePost.PostStatus> statuses);

    // Exclude deleted posts from "My Posts" listing
    List<ParcelServicePost> findBySellerUserIdAndStatusNotOrderByCreatedAtDesc(Long sellerUserId, PostStatus status);

    // Find most recently deleted post by user (for balance day inheritance)
    Optional<ParcelServicePost> findTopBySellerUserIdAndStatusOrderByUpdatedAtDesc(Long sellerUserId, PostStatus status);
}
