package com.shopmanagement.delivery.repository;

import com.shopmanagement.delivery.entity.DeliveryPartner;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryPartnerRepository extends JpaRepository<DeliveryPartner, Long> {

    Optional<DeliveryPartner> findByPartnerId(String partnerId);
    
    Optional<DeliveryPartner> findByUserId(Long userId);
    
    Optional<DeliveryPartner> findByEmail(String email);
    
    Optional<DeliveryPartner> findByPhoneNumber(String phoneNumber);
    
    List<DeliveryPartner> findByStatus(DeliveryPartner.PartnerStatus status);
    
    List<DeliveryPartner> findByVerificationStatus(DeliveryPartner.VerificationStatus verificationStatus);
    
    @Query("SELECT dp FROM DeliveryPartner dp WHERE dp.isOnline = true AND dp.isAvailable = true")
    List<DeliveryPartner> findAvailablePartners();
    
    @Query("SELECT dp FROM DeliveryPartner dp WHERE dp.status = :status AND dp.verificationStatus = :verificationStatus")
    Page<DeliveryPartner> findByStatusAndVerificationStatus(
            @Param("status") DeliveryPartner.PartnerStatus status,
            @Param("verificationStatus") DeliveryPartner.VerificationStatus verificationStatus,
            Pageable pageable
    );
    
    @Query("""
        SELECT dp FROM DeliveryPartner dp 
        WHERE dp.isOnline = true 
        AND dp.isAvailable = true 
        AND dp.status = 'ACTIVE' 
        AND dp.verificationStatus = 'VERIFIED'
        AND (6371 * ACOS(COS(RADIANS(:latitude)) * COS(RADIANS(dp.currentLatitude)) * 
             COS(RADIANS(dp.currentLongitude) - RADIANS(:longitude)) + 
             SIN(RADIANS(:latitude)) * SIN(RADIANS(dp.currentLatitude)))) <= dp.maxDeliveryRadius
        ORDER BY 
        (6371 * ACOS(COS(RADIANS(:latitude)) * COS(RADIANS(dp.currentLatitude)) * 
         COS(RADIANS(dp.currentLongitude) - RADIANS(:longitude)) + 
         SIN(RADIANS(:latitude)) * SIN(RADIANS(dp.currentLatitude))))
    """)
    List<DeliveryPartner> findNearbyAvailablePartners(
            @Param("latitude") BigDecimal latitude,
            @Param("longitude") BigDecimal longitude
    );
    
    @Query("SELECT dp FROM DeliveryPartner dp WHERE dp.city = :city AND dp.status = 'ACTIVE'")
    List<DeliveryPartner> findByCityAndActive(@Param("city") String city);
    
    @Query("SELECT COUNT(dp) FROM DeliveryPartner dp WHERE dp.status = :status")
    Long countByStatus(@Param("status") DeliveryPartner.PartnerStatus status);
    
    @Query("SELECT dp FROM DeliveryPartner dp WHERE dp.rating >= :minRating ORDER BY dp.rating DESC")
    List<DeliveryPartner> findTopRatedPartners(@Param("minRating") BigDecimal minRating);
    
    @Query("""
        SELECT dp FROM DeliveryPartner dp 
        WHERE UPPER(dp.fullName) LIKE UPPER(CONCAT('%', :searchTerm, '%')) 
        OR UPPER(dp.email) LIKE UPPER(CONCAT('%', :searchTerm, '%'))
        OR dp.phoneNumber LIKE CONCAT('%', :searchTerm, '%')
        OR dp.partnerId LIKE CONCAT('%', :searchTerm, '%')
    """)
    Page<DeliveryPartner> searchPartners(@Param("searchTerm") String searchTerm, Pageable pageable);
    
    @Query("SELECT dp FROM DeliveryPartner dp WHERE dp.licenseExpiryDate <= :targetDate")
    List<DeliveryPartner> findPartnersWithExpiringLicenses(@Param("targetDate") java.time.LocalDate targetDate);
    
    Optional<DeliveryPartner> findByVehicleNumber(String vehicleNumber);
    
    Optional<DeliveryPartner> findByLicenseNumber(String licenseNumber);
    
    List<DeliveryPartner> findByLastSeenAfterAndStatus(LocalDateTime lastSeen, DeliveryPartner.PartnerStatus status);
}