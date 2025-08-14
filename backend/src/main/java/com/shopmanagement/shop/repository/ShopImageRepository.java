package com.shopmanagement.shop.repository;

import com.shopmanagement.shop.entity.ShopImage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ShopImageRepository extends JpaRepository<ShopImage, Long> {

    List<ShopImage> findByShopId(Long shopId);

    List<ShopImage> findByShopIdAndImageType(Long shopId, ShopImage.ImageType imageType);

    Optional<ShopImage> findByShopIdAndIsPrimaryTrue(Long shopId);

    void deleteByShopId(Long shopId);
}