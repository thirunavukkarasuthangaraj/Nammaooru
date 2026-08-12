package com.shopmanagement.repository;

import com.shopmanagement.entity.ShopPaymentCollection;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface ShopPaymentCollectionRepository extends JpaRepository<ShopPaymentCollection, Long> {

    Optional<ShopPaymentCollection> findByRazorpayOrderId(String razorpayOrderId);

    boolean existsByShopIdAndStatusAndValidUntilGreaterThanEqual(
            Long shopId, ShopPaymentCollection.CollectionStatus status, LocalDateTime now);

    boolean existsByShopIdAndStatus(Long shopId, ShopPaymentCollection.CollectionStatus status);

    Optional<ShopPaymentCollection> findFirstByShopIdAndStatusOrderByValidUntilDesc(
            Long shopId, ShopPaymentCollection.CollectionStatus status);

    Page<ShopPaymentCollection> findByShopIdOrderByCreatedAtDesc(Long shopId, Pageable pageable);

    List<ShopPaymentCollection> findByStatusAndRazorpayOrderIdStartingWith(
            ShopPaymentCollection.CollectionStatus status, String orderIdPrefix);
}
