package com.shopmanagement.shop.repository;

import com.shopmanagement.shop.entity.ShopDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ShopDocumentRepository extends JpaRepository<ShopDocument, Long> {

    List<ShopDocument> findByShopIdOrderByCreatedAtDesc(Long shopId);

    List<ShopDocument> findByShopIdAndDocumentType(Long shopId, ShopDocument.DocumentType documentType);

    Optional<ShopDocument> findByShopIdAndDocumentTypeAndVerificationStatus(
            Long shopId, 
            ShopDocument.DocumentType documentType, 
            ShopDocument.VerificationStatus verificationStatus);

    @Query("SELECT COUNT(d) FROM ShopDocument d WHERE d.shop.id = :shopId AND d.verificationStatus = 'VERIFIED'")
    Long countVerifiedDocumentsByShopId(@Param("shopId") Long shopId);

    @Query("SELECT COUNT(d) FROM ShopDocument d WHERE d.shop.id = :shopId AND d.isRequired = true")
    Long countRequiredDocumentsByShopId(@Param("shopId") Long shopId);

    @Query("SELECT COUNT(d) FROM ShopDocument d WHERE d.shop.id = :shopId AND d.isRequired = true AND d.verificationStatus = 'VERIFIED'")
    Long countVerifiedRequiredDocumentsByShopId(@Param("shopId") Long shopId);

    List<ShopDocument> findByVerificationStatusOrderByCreatedAtDesc(ShopDocument.VerificationStatus verificationStatus);

    boolean existsByShopIdAndDocumentType(Long shopId, ShopDocument.DocumentType documentType);
}