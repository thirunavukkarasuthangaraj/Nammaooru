package com.shopmanagement.delivery.repository;

import com.shopmanagement.delivery.entity.DeliveryPartnerDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryPartnerDocumentRepository extends JpaRepository<DeliveryPartnerDocument, Long> {

    List<DeliveryPartnerDocument> findByDeliveryPartnerIdOrderByCreatedAtDesc(Long partnerId);

    List<DeliveryPartnerDocument> findByDeliveryPartnerIdAndDocumentType(Long partnerId, DeliveryPartnerDocument.DocumentType documentType);

    Optional<DeliveryPartnerDocument> findByDeliveryPartnerIdAndDocumentTypeAndVerificationStatus(
            Long partnerId,
            DeliveryPartnerDocument.DocumentType documentType,
            DeliveryPartnerDocument.VerificationStatus verificationStatus);

    @Query("SELECT COUNT(d) FROM DeliveryPartnerDocument d WHERE d.deliveryPartner.id = :partnerId AND d.verificationStatus = 'VERIFIED'")
    Long countVerifiedDocumentsByPartnerId(@Param("partnerId") Long partnerId);

    @Query("SELECT COUNT(d) FROM DeliveryPartnerDocument d WHERE d.deliveryPartner.id = :partnerId AND d.isRequired = true")
    Long countRequiredDocumentsByPartnerId(@Param("partnerId") Long partnerId);

    @Query("SELECT COUNT(d) FROM DeliveryPartnerDocument d WHERE d.deliveryPartner.id = :partnerId AND d.isRequired = true AND d.verificationStatus = 'VERIFIED'")
    Long countVerifiedRequiredDocumentsByPartnerId(@Param("partnerId") Long partnerId);

    List<DeliveryPartnerDocument> findByVerificationStatusOrderByCreatedAtDesc(DeliveryPartnerDocument.VerificationStatus verificationStatus);

    boolean existsByDeliveryPartnerIdAndDocumentType(Long partnerId, DeliveryPartnerDocument.DocumentType documentType);

    @Query("SELECT d FROM DeliveryPartnerDocument d WHERE d.deliveryPartner.id = :partnerId AND d.documentType IN :documentTypes")
    List<DeliveryPartnerDocument> findByPartnerIdAndDocumentTypes(@Param("partnerId") Long partnerId, @Param("documentTypes") List<DeliveryPartnerDocument.DocumentType> documentTypes);

    // Find documents expiring soon
    @Query("SELECT d FROM DeliveryPartnerDocument d WHERE d.expiryDate IS NOT NULL AND d.expiryDate <= CURRENT_TIMESTAMP + :days DAY")
    List<DeliveryPartnerDocument> findDocumentsExpiringWithinDays(@Param("days") int days);
}