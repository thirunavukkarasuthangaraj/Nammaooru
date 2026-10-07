package com.shopmanagement.repository;

import com.shopmanagement.entity.LabourPost;
import com.shopmanagement.entity.LabourPost.LabourCategory;
import com.shopmanagement.entity.LabourPost.PostStatus;
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
public interface LabourPostRepository extends JpaRepository<LabourPost, Long> {

    Page<LabourPost> findByStatusOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    Page<LabourPost> findByStatusAndIsPaidTrueOrderByCreatedAtDesc(PostStatus status, Pageable pageable);

    List<LabourPost> findBySellerUserIdOrderByCreatedAtDesc(Long sellerUserId);

    Page<LabourPost> findByStatusInOrderByCreatedAtDesc(List<PostStatus> statuses, Pageable pageable);

    Page<LabourPost> findByStatusAndCategoryOrderByCreatedAtDesc(PostStatus status, LabourCategory category, Pageable pageable);

    Page<LabourPost> findByStatusInAndCategoryOrderByCreatedAtDesc(List<PostStatus> statuses, LabourCategory category, Pageable pageable);

    Page<LabourPost> findByReportCountGreaterThanOrderByReportCountDesc(int minReportCount, Pageable pageable);

    Page<LabourPost> findByReportCountGreaterThanAndStatusNotInOrderByReportCountDesc(int minReportCount, List<PostStatus> excludedStatuses, Pageable pageable);

    Page<LabourPost> findByStatusInAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, LocalDateTime after, Pageable pageable);

    Page<LabourPost> findByStatusInAndCategoryAndCreatedAtAfterOrderByCreatedAtDesc(List<PostStatus> statuses, LabourCategory category, LocalDateTime after, Pageable pageable);

    // Public listings: featured (banner) posts always come first, then newest.
    // CASE handles legacy rows where featured is NULL (treated as not featured).
    @Query("SELECT p FROM LabourPost p WHERE p.status IN :statuses " +
           "ORDER BY CASE WHEN p.featured = true THEN 0 ELSE 1 END, p.createdAt DESC")
    Page<LabourPost> findVisibleFeaturedFirst(@Param("statuses") List<PostStatus> statuses, Pageable pageable);

    @Query("SELECT p FROM LabourPost p WHERE p.status IN :statuses AND p.createdAt > :after " +
           "ORDER BY CASE WHEN p.featured = true THEN 0 ELSE 1 END, p.createdAt DESC")
    Page<LabourPost> findVisibleAfterFeaturedFirst(@Param("statuses") List<PostStatus> statuses,
                                                   @Param("after") LocalDateTime after, Pageable pageable);

    @Query("SELECT p FROM LabourPost p WHERE p.status IN :statuses AND p.category = :category " +
           "ORDER BY CASE WHEN p.featured = true THEN 0 ELSE 1 END, p.createdAt DESC")
    Page<LabourPost> findVisibleByCategoryFeaturedFirst(@Param("statuses") List<PostStatus> statuses,
                                                        @Param("category") LabourCategory category, Pageable pageable);

    @Query("SELECT p FROM LabourPost p WHERE p.status IN :statuses AND p.category = :category AND p.createdAt > :after " +
           "ORDER BY CASE WHEN p.featured = true THEN 0 ELSE 1 END, p.createdAt DESC")
    Page<LabourPost> findVisibleByCategoryAfterFeaturedFirst(@Param("statuses") List<PostStatus> statuses,
                                                             @Param("category") LabourCategory category,
                                                             @Param("after") LocalDateTime after, Pageable pageable);

    // Fuzzy place-name normaliser used by the public location search. Tamil town
    // names have no single English spelling - the same place is typed as
    // "Tirupattur", "TIRUPPATHUR", "Thirupathoor" - so a plain ILIKE on the raw
    // column misses posts the user can clearly see exist. NORM(x) lower-cases,
    // strips spaces/punctuation, folds the common transliteration pairs
    // (th->t, sh->s, oo->u, w->v, ...) and finally collapses doubled letters, so
    // every spelling above becomes "tirupatur". Both the stored location and each
    // search token go through the same expression, so the match is symmetric.
    String NORM_OPEN = "regexp_replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(" +
            "regexp_replace(lower(coalesce(";
    String NORM_CLOSE = ", '')), '[^a-z0-9]', '', 'g'), " +
            "'th','t'),'dh','d'),'bh','b'),'kh','k'),'gh','g'),'ph','p'),'sh','s'),'zh','l'),'oo','u'),'ee','i'),'w','v'), " +
            "'(.)\\1+', '\\1', 'g')";

    // Every search token (split on whitespace/punctuation by the service) must
    // appear in the normalised location, in any order, so "Ambur Krishnapuram"
    // still finds "krisnapuram, Ambur". A token with no Latin letters/digits
    // (e.g. typed in Tamil script) normalises to '' and would match everything,
    // so those fall back to a plain case-insensitive substring match on the raw
    // column. Category is optional (NULL = all).
    String LOCATION_SEARCH_WHERE =
            "WHERE lp.status = ANY(CAST(:statuses AS text[])) " +
            "AND (CAST(:category AS text) IS NULL OR lp.category = CAST(:category AS text)) " +
            "AND (SELECT bool_and(CASE WHEN " + NORM_OPEN + "t.tok" + NORM_CLOSE + " <> '' " +
            "THEN " + NORM_OPEN + "lp.location" + NORM_CLOSE + " LIKE '%' || " + NORM_OPEN + "t.tok" + NORM_CLOSE + " || '%' " +
            "ELSE lp.location ILIKE '%' || t.tok || '%' END) " +
            "FROM unnest(CAST(:tokens AS text[])) AS t(tok)) ";

    @Query(value = "SELECT * FROM labour_posts lp " + LOCATION_SEARCH_WHERE +
           "ORDER BY COALESCE(lp.featured, false) DESC, lp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<LabourPost> searchVisibleByLocation(@Param("statuses") String[] statuses,
                                             @Param("category") String category,
                                             @Param("tokens") String[] tokens,
                                             @Param("limit") int limit,
                                             @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM labour_posts lp " + LOCATION_SEARCH_WHERE, nativeQuery = true)
    long countVisibleByLocation(@Param("statuses") String[] statuses,
                                @Param("category") String category,
                                @Param("tokens") String[] tokens);

    long countByStatus(PostStatus status);

    long countByReportCountGreaterThan(int count);

    long countBySellerUserIdAndStatusIn(Long sellerUserId, List<PostStatus> statuses);

    long countByStatusIn(List<PostStatus> statuses);

    long countByStatusInAndCategory(List<PostStatus> statuses, LabourCategory category);

    // "All" distance filter - no radius cap, so every approved post is shown.
    // Posts with saved coordinates are ordered nearest-first; posts without
    // coordinates (can't compute a distance) sort after all of those instead
    // of being excluded like the radius-bounded queries below.
    @Query(value = "SELECT * FROM labour_posts lp WHERE lp.status = ANY(CAST(:statuses AS text[])) " +
           "ORDER BY COALESCE(lp.featured, false) DESC, (CASE WHEN lp.latitude IS NOT NULL AND lp.longitude IS NOT NULL THEN " +
           "6371 * acos(LEAST(1.0, GREATEST(-1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(lp.latitude AS double precision))) * " +
           "cos(radians(CAST(lp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(lp.latitude AS double precision)))))) ELSE NULL END) ASC NULLS LAST, " +
           "lp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<LabourPost> findAllSortedByDistance(@Param("statuses") String[] statuses,
                                             @Param("lat") double lat,
                                             @Param("lng") double lng,
                                             @Param("limit") int limit,
                                             @Param("offset") int offset);

    @Query(value = "SELECT * FROM labour_posts lp WHERE lp.status = ANY(CAST(:statuses AS text[])) AND " +
           "lp.category = CAST(:category AS text) " +
           "ORDER BY COALESCE(lp.featured, false) DESC, (CASE WHEN lp.latitude IS NOT NULL AND lp.longitude IS NOT NULL THEN " +
           "6371 * acos(LEAST(1.0, GREATEST(-1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(lp.latitude AS double precision))) * " +
           "cos(radians(CAST(lp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(lp.latitude AS double precision)))))) ELSE NULL END) ASC NULLS LAST, " +
           "lp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<LabourPost> findAllByCategorySortedByDistance(@Param("statuses") String[] statuses,
                                                        @Param("category") String category,
                                                        @Param("lat") double lat,
                                                        @Param("lng") double lng,
                                                        @Param("limit") int limit,
                                                        @Param("offset") int offset);

    // Haversine nearby queries - only posts with valid coordinates within radius
    @Query(value = "SELECT * FROM labour_posts lp WHERE lp.status = ANY(CAST(:statuses AS text[])) AND " +
           "lp.latitude IS NOT NULL AND lp.longitude IS NOT NULL AND " +
           "lp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "lp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(lp.latitude AS double precision))) * " +
           "cos(radians(CAST(lp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(lp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision) " +
           "ORDER BY COALESCE(lp.featured, false) DESC, lp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<LabourPost> findNearbyPosts(@Param("statuses") String[] statuses,
                                     @Param("lat") double lat,
                                     @Param("lng") double lng,
                                     @Param("radiusKm") double radiusKm,
                                     @Param("limit") int limit,
                                     @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM labour_posts lp WHERE lp.status = ANY(CAST(:statuses AS text[])) AND " +
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

    @Query(value = "SELECT * FROM labour_posts lp WHERE lp.status = ANY(CAST(:statuses AS text[])) AND " +
           "lp.category = CAST(:category AS text) AND " +
           "lp.latitude IS NOT NULL AND lp.longitude IS NOT NULL AND " +
           "lp.latitude BETWEEN CAST(:lat AS double precision) - (CAST(:radiusKm AS double precision) / 111.0) AND CAST(:lat AS double precision) + (CAST(:radiusKm AS double precision) / 111.0) AND " +
           "lp.longitude BETWEEN CAST(:lng AS double precision) - (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND CAST(:lng AS double precision) + (CAST(:radiusKm AS double precision) / (111.0 * cos(radians(CAST(:lat AS double precision))))) AND " +
           "(6371 * acos(LEAST(1.0, cos(radians(CAST(:lat AS double precision))) * cos(radians(CAST(lp.latitude AS double precision))) * " +
           "cos(radians(CAST(lp.longitude AS double precision)) - radians(CAST(:lng AS double precision))) + sin(radians(CAST(:lat AS double precision))) * " +
           "sin(radians(CAST(lp.latitude AS double precision)))))) <= CAST(:radiusKm AS double precision) " +
           "ORDER BY COALESCE(lp.featured, false) DESC, lp.created_at DESC LIMIT :limit OFFSET :offset",
           nativeQuery = true)
    List<LabourPost> findNearbyPostsByCategory(@Param("statuses") String[] statuses,
                                               @Param("category") String category,
                                               @Param("lat") double lat,
                                               @Param("lng") double lng,
                                               @Param("radiusKm") double radiusKm,
                                               @Param("limit") int limit,
                                               @Param("offset") int offset);

    @Query(value = "SELECT COUNT(*) FROM labour_posts lp WHERE lp.status = ANY(CAST(:statuses AS text[])) AND " +
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

    // Location text search
    Page<LabourPost> findByStatusInAndLocationContainingIgnoreCaseOrderByCreatedAtDesc(
            List<PostStatus> statuses, String location, Pageable pageable);

    // Expiry reminder: posts expiring between now and reminderDate, not yet reminded, in active statuses
    List<LabourPost> findByValidToBetweenAndExpiryReminderSentFalseAndStatusIn(
            LocalDateTime from, LocalDateTime to, List<PostStatus> statuses);

    // Expired posts: valid_to before cutoff, in active statuses
    List<LabourPost> findByValidToBeforeAndStatusIn(LocalDateTime before, List<PostStatus> statuses);

    // Exclude deleted posts from "My Posts" listing
    List<LabourPost> findBySellerUserIdAndStatusNotOrderByCreatedAtDesc(Long sellerUserId, PostStatus status);

    // Find most recently deleted post by user (for balance day inheritance)
    Optional<LabourPost> findTopBySellerUserIdAndStatusOrderByUpdatedAtDesc(Long sellerUserId, PostStatus status);
}
