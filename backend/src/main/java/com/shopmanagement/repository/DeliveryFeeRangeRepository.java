package com.shopmanagement.repository;

import com.shopmanagement.entity.DeliveryFeeRange;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryFeeRangeRepository extends JpaRepository<DeliveryFeeRange, Long> {

    List<DeliveryFeeRange> findByIsActiveTrueOrderByMinDistanceKm();

    @Query("SELECT dfr FROM DeliveryFeeRange dfr WHERE dfr.isActive = true AND dfr.minDistanceKm <= :distance AND dfr.maxDistanceKm >= :distance")
    Optional<DeliveryFeeRange> findByDistanceRange(@Param("distance") Double distance);

    @Query("SELECT dfr FROM DeliveryFeeRange dfr WHERE dfr.isActive = true AND dfr.minDistanceKm <= :distance ORDER BY dfr.maxDistanceKm DESC LIMIT 1")
    Optional<DeliveryFeeRange> findHighestRangeForDistance(@Param("distance") Double distance);
}