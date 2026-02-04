package com.shopmanagement.shop.repository;

import com.shopmanagement.shop.entity.Shop;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ShopRepository extends JpaRepository<Shop, Long>, JpaSpecificationExecutor<Shop> {

    Optional<Shop> findByShopId(String shopId);

    Optional<Shop> findBySlug(String slug);

    boolean existsByShopId(String shopId);

    boolean existsBySlug(String slug);

    Page<Shop> findByIsActiveTrue(Pageable pageable);

    Page<Shop> findByStatus(Shop.ShopStatus status, Pageable pageable);

    Page<Shop> findByBusinessType(Shop.BusinessType businessType, Pageable pageable);

    Page<Shop> findByCityIgnoreCaseContaining(String city, Pageable pageable);

    Page<Shop> findByStateIgnoreCaseContaining(String state, Pageable pageable);

    @Query("SELECT s FROM Shop s WHERE " +
           "LOWER(s.name) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(s.description) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(s.ownerName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(s.businessName) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(s.city) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
    Page<Shop> searchShops(@Param("searchTerm") String searchTerm, Pageable pageable);

    @Query(value = "SELECT * FROM shops s WHERE s.latitude IS NOT NULL AND s.longitude IS NOT NULL " +
           "AND s.is_active = true AND s.status = 'APPROVED' " +
           "AND (6371 * acos(cos(radians(:lat)) * cos(radians(s.latitude)) * cos(radians(s.longitude) - radians(:lng)) + sin(radians(:lat)) * sin(radians(s.latitude)))) < :radiusInKm " +
           "ORDER BY (6371 * acos(cos(radians(:lat)) * cos(radians(s.latitude)) * cos(radians(s.longitude) - radians(:lng)) + sin(radians(:lat)) * sin(radians(s.latitude)))) ASC",
           nativeQuery = true)
    List<Shop> findShopsWithinRadius(@Param("lat") double latitude,
                                   @Param("lng") double longitude,
                                   @Param("radiusInKm") double radiusInKm);

    @Query("SELECT s FROM Shop s WHERE s.isActive = true AND s.status = 'APPROVED' ORDER BY s.rating DESC")
    List<Shop> findTopRatedShops(Pageable pageable);

    @Query("SELECT s FROM Shop s WHERE s.isFeatured = true AND s.isActive = true AND s.status = 'APPROVED'")
    List<Shop> findFeaturedShops();

    @Query("SELECT COUNT(s) FROM Shop s WHERE s.status = :status")
    long countByStatus(@Param("status") Shop.ShopStatus status);

    long countByIsActiveTrue();

    @Query("SELECT s.businessType, COUNT(s) FROM Shop s GROUP BY s.businessType")
    List<Object[]> getShopCountByBusinessType();

    @Query("SELECT DISTINCT s FROM Shop s LEFT JOIN FETCH s.images WHERE s.id IN :ids")
    List<Shop> findAllWithImagesByIds(@Param("ids") List<Long> ids);

    @Query("SELECT DISTINCT s FROM Shop s LEFT JOIN FETCH s.documents WHERE s.id IN :ids")
    List<Shop> findAllWithDocumentsByIds(@Param("ids") List<Long> ids);

    Optional<Shop> findByCreatedBy(String createdBy);
    
    Optional<Shop> findByOwnerEmail(String ownerEmail);
}