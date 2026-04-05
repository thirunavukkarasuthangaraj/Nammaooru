package com.shopmanagement.repository;

import com.shopmanagement.entity.LocalShopPost;
import com.shopmanagement.entity.LocalShopPost.ShopCategory;
import com.shopmanagement.entity.LocalShopPost.PostStatus;
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
public interface LocalShopPostRepository extends JpaRepository<LocalShopPost, Long> {

    Page<LocalShopPost> findByStatusOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    Page<LocalShopPost> findByStatusAndIsPaidTrueOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    List<LocalShopPost> findBySellerUserIdOrderByCreatedAtDesc(Long sellerUserId);

    Page<LocalShopPost> findByStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    Page<LocalShopPost> findByStatusInAndCategoryOrderByCreatedAtDesc(List<PostStatus> statuses, ShopCategory category, Pageable pageable);

    Page<LocalShopPost> findByReportCountGreaterThanOrderByReportCountDesc(int minReportCount, Pageable pageable);

    Page<LocalShopPost> findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, LocalDateTime after, Pageable pageable);

    Page<LocalShopPost> findByStatusInAndCategoryAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, ShopCategory category, LocalDateTime after, Pageable pageable);

    long countByStatus(PostStatus status);

    long countByReportCountGreaterThan(int count);

    long countBySellerUserIdAndStatusIn(Long sellerUserId, List<PostStatus> statuses);

    Page<LocalShopPost> findByStatusInAndAddressContainingIgnoreCaseOrderByCreatedAtDesc(
            List<PostStatus> statuses, String address, Pageable pageable);

    List<LocalShopPost> findBySellerUserIdAndStatusNotOrderByCreatedAtDesc(Long sellerUserId, PostStatus status);

    Optional<LocalShopPost> findTopBySellerUserIdAndStatusOrderByUpdatedAtDesc(Long sellerUserId, PostStatus status);

    List<LocalShopPost> findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(
            LocalDateTime from, LocalDateTime to, List<PostStatus> statuses);

    List<LocalShopPost> findByValidToBeforeAndStatusIn(LocalDateTime before, List<PostStatus> statuses);

    @Query(value = "SELECT * FROM local_shop_posts lp WHERE lp.status = ANY(CAST(:statuses AS text[])) AND " +
           "lp.latitude IS NOT NULL AND lp.longitude IS NOT NULL AND " +
           "lp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "lp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(lp.latitude AS double precision))) * " +
           "cos(radians(CAST(lp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(lp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision) " +
           "ORDER BY lp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<LocalShopPost> findNearbyPosts(@Param("statuses") String[] statuses,
                                        @Param("lat") double lat,
                                        @Param("lng") double lng,
                                        @Param("radiusKm") double radiusKm,
                                        @Param("limit") int limit,
                                        @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM local_shop_posts lp WHERE lp.status = ANY(CAST(:statuses AS text[])) AND " +
           "lp.latitude IS NOT NULL AND lp.longitude IS NOT NULL AND " +
           "lp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "lp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(lp.latitude AS double precision))) * " +
           "cos(radians(CAST(lp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(lp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision)",
           nativeQuery = true)
    long countNearbyPosts(@Param("statuses") String[] statuses,
                          @Param("lat") double lat,
                          @Param("lng") double lng,
                          @Param("radiusKm") double radiusKm);

    @Query(value = "SELECT * FROM local_shop_posts lp WHERE lp.status = ANY(CAST(:statuses AS text[])) AND " +
           "lp.category = CAST(:category AS text) AND " +
           "lp.latitude IS NOT NULL AND lp.longitude IS NOT NULL AND " +
           "lp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "lp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(lp.latitude AS double precision))) * " +
           "cos(radians(CAST(lp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(lp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision) " +
           "ORDER BY lp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<LocalShopPost> findNearbyPostsByCategory(@Param("statuses") String[] statuses,
                                                  @Param("category") String category,
                                                  @Param("lat") double lat,
                                                  @Param("lng") double lng,
                                                  @Param("radiusKm") double radiusKm,
                                                  @Param("limit") int limit,
                                                  @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM local_shop_posts lp WHERE lp.status = ANY(CAST(:statuses AS text[])) AND " +
           "lp.category = CAST(:category AS text) AND " +
           "lp.latitude IS NOT NULL AND lp.longitude IS NOT NULL AND " +
           "lp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "lp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(lp.latitude AS double precision))) * " +
           "cos(radians(CAST(lp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(lp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision)",
           nativeQuery = true)
    long countNearbyPostsByCategory(@Param("statuses") String[] statuses,
                                    @Param("category") String category,
                                    @Param("lat") double lat,
                                    @Param("lng") double lng,
                                    @Param("radiusKm") double radiusKm);
}
