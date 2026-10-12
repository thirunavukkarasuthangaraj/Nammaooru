package com.shopmanagement.repository;

import com.shopmanagement.entity.DeliveryHours;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.DayOfWeek;
import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryHoursRepository extends JpaRepository<DeliveryHours, Long> {

    List<DeliveryHours> findByShopId(Long shopId);

    Optional<DeliveryHours> findByShopIdAndDayOfWeek(Long shopId, DayOfWeek dayOfWeek);

    void deleteByShopId(Long shopId);
}
