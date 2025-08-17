package com.shopmanagement.delivery.repository;

import com.shopmanagement.delivery.entity.DeliveryPartnerDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryPartnerDocumentRepository extends JpaRepository<DeliveryPartnerDocument, Long> {

    List<DeliveryPartnerDocument> findByDeliveryPartnerId(Long partnerId);
    
    List<DeliveryPartnerDocument> findByDocumentType(DeliveryPartnerDocument.DocumentType documentType);
    
    List<DeliveryPartnerDocument> findByVerificationStatus(DeliveryPartnerDocument.VerificationStatus verificationStatus);
    
    Optional<DeliveryPartnerDocument> findByDeliveryPartnerIdAndDocumentType(
            Long partnerId, 
            DeliveryPartnerDocument.DocumentType documentType
    );
    
    @Query("""
        SELECT dpd FROM DeliveryPartnerDocument dpd 
        WHERE dpd.deliveryPartner.id = :partnerId 
        AND dpd.verificationStatus = :status
    """)
    List<DeliveryPartnerDocument> findByPartnerIdAndVerificationStatus(
            @Param("partnerId") Long partnerId,
            @Param("status") DeliveryPartnerDocument.VerificationStatus status
    );
    
    @Query("SELECT dpd FROM DeliveryPartnerDocument dpd WHERE dpd.expiryDate IS NOT NULL AND dpd.expiryDate <= :date")
    List<DeliveryPartnerDocument> findExpiredDocuments(@Param("date") LocalDate date);
    
    @Query("SELECT dpd FROM DeliveryPartnerDocument dpd WHERE dpd.expiryDate IS NOT NULL AND dpd.expiryDate BETWEEN :startDate AND :endDate")
    List<DeliveryPartnerDocument> findDocumentsExpiringBetween(
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );
    
    @Query("SELECT COUNT(dpd) FROM DeliveryPartnerDocument dpd WHERE dpd.deliveryPartner.id = :partnerId AND dpd.verificationStatus = 'VERIFIED'")
    Long countVerifiedDocumentsByPartner(@Param("partnerId") Long partnerId);
    
    @Query("SELECT COUNT(dpd) FROM DeliveryPartnerDocument dpd WHERE dpd.deliveryPartner.id = :partnerId")
    Long countTotalDocumentsByPartner(@Param("partnerId") Long partnerId);
    
    boolean existsByDeliveryPartnerIdAndDocumentType(Long partnerId, DeliveryPartnerDocument.DocumentType documentType);
}