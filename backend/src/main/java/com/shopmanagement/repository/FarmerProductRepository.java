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

@Repository
public interface FarmerProductRepository extends JpaRepository<FarmerProduct, Long> {

    Page<FarmerProduct> findByStatusOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    List<FarmerProduct> findBySellerUserIdOrderByCreatedAtDesc(Long sellerUserId);

    Page<FarmerProduct> findByStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    Page<FarmerProduct> findByStatusAndCategoryOrderByCreatedAtDesc(PostStatus status, String category, Pageable pageable);

    Page<FarmerProduct> findByReportCountGreaterThanOrderByReportCountDesc(int minReportCount, Pageable pageable);

    Page<FarmerProduct> findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, LocalDateTime after, Pageable pageable);

    Page<FarmerProduct> findByStatusInAndCategoryAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, String category, LocalDateTime after, Pageable pageable);

    Page<FarmerProduct> findByFeaturedTrueAndStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    long countByStatus(PostStatus status);

    long countByReportCountGreaterThan(int minReportCount);

    long countBySellerUserIdAndStatusIn(Long sellerUserId, List<PostStatus> statuses);

    // Haversine nearby queries - posts with NULL lat/lng are always included
    @Query(value = "SELECT * FROM farmer_products fp WHERE fp.status = ANY(CAST(:statuses AS text[])) AND (" +
           "fp.latitude IS NULL OR fp.longitude IS NULL OR (" +
           "fp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "fp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(fp.latitude AS double precision))) * " +
           "cos(radians(CAST(fp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(fp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ") ORDER BY fp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<FarmerProduct> findNearbyPosts(@Param("statuses") String[] statuses,
                                     @Param("lat") double lat,
                                     @Param("lng") double lng,
                                     @Param("radiusKm") double radiusKm,
                                     @Param("limit") int limit,
                                     @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM farmer_products fp WHERE fp.status = ANY(CAST(:statuses AS text[])) AND (" +
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

    @Query(value = "SELECT * FROM farmer_products fp WHERE fp.status = ANY(CAST(:statuses AS text[])) AND " +
           "fp.category = CAST(:category AS text) AND (" +
           "fp.latitude IS NULL OR fp.longitude IS NULL OR (" +
           "fp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "fp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(fp.latitude AS double precision))) * " +
           "cos(radians(CAST(fp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(fp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision))" +
           ") ORDER BY fp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<FarmerProduct> findNearbyPostsByCategory(@Param("statuses") String[] statuses,
                                               @Param("category") String category,
                                               @Param("lat") double lat,
                                               @Param("lng") double lng,
                                               @Param("radiusKm") double radiusKm,
                                               @Param("limit") int limit,
                                               @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM farmer_products fp WHERE fp.status = ANY(CAST(:statuses AS text[])) AND " +
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
}
