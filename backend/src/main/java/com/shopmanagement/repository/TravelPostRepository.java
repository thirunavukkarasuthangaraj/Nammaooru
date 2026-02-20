package com.shopmanagement.repository;

import com.shopmanagement.entity.TravelPost;
import com.shopmanagement.entity.TravelPost.VehicleType;
import com.shopmanagement.entity.TravelPost.PostStatus;
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
public interface TravelPostRepository extends JpaRepository<TravelPost, Long> {

    Page<TravelPost> findByStatusOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    Page<TravelPost> findByStatusAndIsPaidTrueOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    List<TravelPost> findBySellerUserIdOrderByCreatedAtDesc(Long sellerUserId);

    Page<TravelPost> findByStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    Page<TravelPost> findByStatusAndVehicleTypeOrderByCreatedAtDesc(PostStatus status, VehicleType vehicleType, Pageable pageable);

    Page<TravelPost> findByStatusInAndVehicleTypeOrderByCreatedAtDesc(List<PostStatus> statuses, VehicleType vehicleType, Pageable pageable);

    Page<TravelPost> findByReportCountGreaterThanOrderByReportCountDesc(int minReportCount, Pageable pageable);

    Page<TravelPost> findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, LocalDateTime after, Pageable pageable);

    Page<TravelPost> findByStatusInAndVehicleTypeAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, VehicleType vehicleType, LocalDateTime after, Pageable pageable);

    long countByStatus(PostStatus status);

    long countByReportCountGreaterThan(int count);

    long countBySellerUserIdAndStatusIn(Long sellerUserId, List<PostStatus> statuses);

    // Haversine nearby queries - posts with NULL lat/lng are always included
    @Query(value = "SELECT * FROM travel_posts tp WHERE tp.status = ANY(CAST(:statuses AS text[])) AND (" +
           "tp.latitude IS NULL OR tp.longitude IS NULL OR (" +
           "tp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "tp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(tp.latitude AS double precision))) * " +
           "cos(radians(CAST(tp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(tp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ") ORDER BY tp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<TravelPost> findNearbyPosts(@Param("statuses") String[] statuses,
                                     @Param("lat") double lat,
                                     @Param("lng") double lng,
                                     @Param("radiusKm") double radiusKm,
                                     @Param("limit") int limit,
                                     @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM travel_posts tp WHERE tp.status = ANY(CAST(:statuses AS text[])) AND (" +
           "tp.latitude IS NULL OR tp.longitude IS NULL OR (" +
           "tp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "tp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(tp.latitude AS double precision))) * " +
           "cos(radians(CAST(tp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(tp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ")",
           nativeQuery = true)
    long countNearbyPosts(@Param("statuses") String[] statuses,
                          @Param("lat") double lat,
                          @Param("lng") double lng,
                          @Param("radiusKm") double radiusKm);

    @Query(value = "SELECT * FROM travel_posts tp WHERE tp.status = ANY(CAST(:statuses AS text[])) AND " +
           "tp.vehicle_type = CAST(:vehicleType AS text) AND (" +
           "tp.latitude IS NULL OR tp.longitude IS NULL OR (" +
           "tp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "tp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(tp.latitude AS double precision))) * " +
           "cos(radians(CAST(tp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(tp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ") ORDER BY tp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<TravelPost> findNearbyPostsByVehicleType(@Param("statuses") String[] statuses,
                                                   @Param("vehicleType") String vehicleType,
                                                   @Param("lat") double lat,
                                                   @Param("lng") double lng,
                                                   @Param("radiusKm") double radiusKm,
                                                   @Param("limit") int limit,
                                                   @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM travel_posts tp WHERE tp.status = ANY(CAST(:statuses AS text[])) AND " +
           "tp.vehicle_type = CAST(:vehicleType AS text) AND (" +
           "tp.latitude IS NULL OR tp.longitude IS NULL OR (" +
           "tp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "tp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(tp.latitude AS double precision))) * " +
           "cos(radians(CAST(tp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(tp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ")",
           nativeQuery = true)
    long countNearbyPostsByVehicleType(@Param("statuses") String[] statuses,
                                       @Param("vehicleType") String vehicleType,
                                       @Param("lat") double lat,
                                       @Param("lng") double lng,
                                       @Param("radiusKm") double radiusKm);

    // Location text search (searches fromLocation OR toLocation)
    @Query("SELECT t FROM TravelPost t WHERE t.status IN :statuses AND " +
           "(LOWER(t.fromLocation) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(t.toLocation) LIKE LOWER(CONCAT('%', :search, '%'))) " +
           "ORDER BY t.createdAt DESC")
    Page<TravelPost> searchByLocation(@Param("statuses") List<PostStatus> statuses,
                                       @Param("search") String search,
                                       Pageable pageable);

    // Expiry reminder: posts expiring between now and reminderDate, not yet reminded, in active statuses
    List<TravelPost> findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(
            LocalDateTime from, LocalDateTime to, List<PostStatus> statuses);

    // Expired posts: valid_to before cutoff, in active statuses
    List<TravelPost> findByValidToBeforeAndStatusIn(LocalDateTime before, List<PostStatus> statuses);

    // Exclude deleted posts from "My Posts" listing
    List<TravelPost> findBySellerUserIdAndStatusNotOrderByCreatedAtDesc(Long sellerUserId, PostStatus status);

    // Find most recently deleted post by user (for balance day inheritance)
    Optional<TravelPost> findTopBySellerUserIdAndStatusOrderByUpdatedAtDesc(Long sellerUserId, PostStatus status);
}
