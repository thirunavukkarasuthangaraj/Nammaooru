package com.shopmanagement.repository;

import com.shopmanagement.entity.ShopPaymentPrice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ShopPaymentPriceRepository extends JpaRepository<ShopPaymentPrice, Long> {

    Optional<ShopPaymentPrice> findByShopId(Long shopId);
}
