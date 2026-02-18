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

    long countBySellerUserIdAndStatusIn(Long sellerUserId, List<PostStatus> statuses);

    // Haversine nearby queries - posts with NULL lat/lng are always included
    @Query(value = "SELECT * FROM parcel_service_posts pp WHERE pp.status = ANY(CAST(:statuses AS text[])) AND (" +
           "pp.latitude IS NULL OR pp.longitude IS NULL OR (" +
           "pp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "pp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(pp.latitude AS double precision))) * " +
           "cos(radians(CAST(pp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(pp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ") ORDER BY pp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<ParcelServicePost> findNearbyPosts(@Param("statuses") String[] statuses,
                                            @Param("lat") double lat,
                                            @Param("lng") double lng,
                                            @Param("radiusKm") double radiusKm,
                                            @Param("limit") int limit,
                                            @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM parcel_service_posts pp WHERE pp.status = ANY(CAST(:statuses AS text[])) AND (" +
           "pp.latitude IS NULL OR pp.longitude IS NULL OR (" +
           "pp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "pp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(pp.latitude AS double precision))) * " +
           "cos(radians(CAST(pp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(pp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ")",
           nativeQuery = true)
    long countNearbyPosts(@Param("statuses") String[] statuses,
                          @Param("lat") double lat,
                          @Param("lng") double lng,
                          @Param("radiusKm") double radiusKm);

    @Query(value = "SELECT * FROM parcel_service_posts pp WHERE pp.status = ANY(CAST(:statuses AS text[])) AND " +
           "pp.service_type = CAST(:serviceType AS text) AND (" +
           "pp.latitude IS NULL OR pp.longitude IS NULL OR (" +
           "pp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "pp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(pp.latitude AS double precision))) * " +
           "cos(radians(CAST(pp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(pp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ") ORDER BY pp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<ParcelServicePost> findNearbyPostsByServiceType(@Param("statuses") String[] statuses,
                                                         @Param("serviceType") String serviceType,
                                                         @Param("lat") double lat,
                                                         @Param("lng") double lng,
                                                         @Param("radiusKm") double radiusKm,
                                                         @Param("limit") int limit,
                                                         @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM parcel_service_posts pp WHERE pp.status = ANY(CAST(:statuses AS text[])) AND " +
           "pp.service_type = CAST(:serviceType AS text) AND (" +
           "pp.latitude IS NULL OR pp.longitude IS NULL OR (" +
           "pp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "pp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(pp.latitude AS double precision))) * " +
           "cos(radians(CAST(pp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(pp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ")",
           nativeQuery = true)
    long countNearbyPostsByServiceType(@Param("statuses") String[] statuses,
                                       @Param("serviceType") String serviceType,
                                       @Param("lat") double lat,
                                       @Param("lng") double lng,
                                       @Param("radiusKm") double radiusKm);

    // Expiry reminder: posts expiring between now and reminderDate, not yet reminded, in active statuses
    List<ParcelServicePost> findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(
            LocalDateTime from, LocalDateTime to, List<ParcelServicePost.PostStatus> statuses);

    // Expired posts: valid_to before cutoff, in active statuses
    List<ParcelServicePost> findByValidToBeforeAndStatusIn(LocalDateTime before, List<ParcelServicePost.PostStatus> statuses);
}
