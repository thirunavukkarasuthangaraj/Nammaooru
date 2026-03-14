package com.shopmanagement.repository;

import com.shopmanagement.entity.RealEstatePost;
import com.shopmanagement.entity.RealEstatePost.ListingType;
import com.shopmanagement.entity.RealEstatePost.PostStatus;
import com.shopmanagement.entity.RealEstatePost.PropertyType;
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
public interface RealEstatePostRepository extends JpaRepository<RealEstatePost, Long> {

    // Find all approved posts
    Page<RealEstatePost> findByStatusOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    // Find paid approved posts for banner
    Page<RealEstatePost> findByStatusAndIsPaidTrueOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    // Find by property type
    Page<RealEstatePost> findByStatusAndPropertyTypeOrderByCreatedAtDesc(
            PostStatus status, PropertyType propertyType, Pageable pageable);

    // Find by listing type
    Page<RealEstatePost> findByStatusAndListingTypeOrderByCreatedAtDesc(
            PostStatus status, ListingType listingType, Pageable pageable);

    // Find by property type and listing type
    Page<RealEstatePost> findByStatusAndPropertyTypeAndListingTypeOrderByCreatedAtDesc(
            PostStatus status, PropertyType propertyType, ListingType listingType, Pageable pageable);

    // Find by owner
    List<RealEstatePost> findByOwnerUserIdOrderByCreatedAtDesc(Long ownerUserId);

    // Find pending posts for admin
    Page<RealEstatePost> findByStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    // Search by location
    @Query("SELECT p FROM RealEstatePost p WHERE p.status = :status AND " +
           "LOWER(p.location) LIKE LOWER(CONCAT('%', :location, '%')) ORDER BY p.createdAt DESC")
    Page<RealEstatePost> findByStatusAndLocationContaining(
            @Param("status") PostStatus status, @Param("location") String location, Pageable pageable);

    // Haversine nearby queries - posts within radius of user location
    @Query(value =
           "SELECT * FROM real_estate_posts rp WHERE rp.status IN :statuses AND " +
           "rp.latitude IS NOT NULL AND rp.longitude IS NOT NULL AND " +
           "rp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "rp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(rp.latitude AS double precision))) * " +
           "cos(radians(CAST(rp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(rp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision) " +
           "ORDER BY rp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<RealEstatePost> findNearbyPosts(@Param("statuses") List<String> statuses,
                                         @Param("lat") double lat, @Param("lng") double lng,
                                         @Param("radiusKm") double radiusKm,
                                         @Param("limit") int limit, @Param("offset") int offset);

    @Query(value =
           "SELECT COUNT(*) FROM real_estate_posts rp WHERE rp.status IN :statuses AND " +
           "rp.latitude IS NOT NULL AND rp.longitude IS NOT NULL AND " +
           "rp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "rp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(rp.latitude AS double precision))) * " +
           "cos(radians(CAST(rp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(rp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision)",
           nativeQuery = true)
    long countNearbyPosts(@Param("statuses") List<String> statuses,
                          @Param("lat") double lat, @Param("lng") double lng,
                          @Param("radiusKm") double radiusKm);

    // Haversine nearby with property type filter
    @Query(value =
           "SELECT * FROM real_estate_posts rp WHERE rp.status IN :statuses AND rp.property_type = :propertyType AND " +
           "rp.latitude IS NOT NULL AND rp.longitude IS NOT NULL AND " +
           "rp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "rp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(rp.latitude AS double precision))) * " +
           "cos(radians(CAST(rp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(rp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision) " +
           "ORDER BY rp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<RealEstatePost> findNearbyPostsByPropertyType(@Param("statuses") List<String> statuses,
                                                       @Param("propertyType") String propertyType,
                                                       @Param("lat") double lat, @Param("lng") double lng,
                                                       @Param("radiusKm") double radiusKm,
                                                       @Param("limit") int limit, @Param("offset") int offset);

    @Query(value =
           "SELECT COUNT(*) FROM real_estate_posts rp WHERE rp.status IN :statuses AND rp.property_type = :propertyType AND " +
           "rp.latitude IS NOT NULL AND rp.longitude IS NOT NULL AND " +
           "rp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "rp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(rp.latitude AS double precision))) * " +
           "cos(radians(CAST(rp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(rp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision)",
           nativeQuery = true)
    long countNearbyPostsByPropertyType(@Param("statuses") List<String> statuses,
                                        @Param("propertyType") String propertyType,
                                        @Param("lat") double lat, @Param("lng") double lng,
                                        @Param("radiusKm") double radiusKm);

    // Find featured posts
    Page<RealEstatePost> findByStatusAndIsFeaturedTrueOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    // Count active posts by owner
    long countByOwnerUserIdAndStatusIn(Long ownerUserId, List<PostStatus> statuses);

    // Count by status
    long countByStatus(PostStatus status);

    long countByReportCountGreaterThan(int minReportCount);

    // Expiry reminder: posts expiring between now and reminderDate, not yet reminded, in active statuses
    List<RealEstatePost> findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(
            LocalDateTime from, LocalDateTime to, List<PostStatus> statuses);

    // Expired posts: valid_to before cutoff, in active statuses
    List<RealEstatePost> findByValidToBeforeAndStatusIn(LocalDateTime before, List<PostStatus> statuses);

    // Exclude deleted posts from "My Posts" listing
    List<RealEstatePost> findByOwnerUserIdAndStatusNotOrderByCreatedAtDesc(Long ownerUserId, PostStatus status);

    // Find most recently deleted post by user (for balance day inheritance)
    Optional<RealEstatePost> findTopByOwnerUserIdAndStatusOrderByUpdatedAtDesc(Long ownerUserId, PostStatus status);
}
