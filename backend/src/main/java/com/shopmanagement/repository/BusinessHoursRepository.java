package com.shopmanagement.repository;

import com.shopmanagement.entity.BusinessHours;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.DayOfWeek;
import java.util.List;
import java.util.Optional;

@Repository
public interface BusinessHoursRepository extends JpaRepository<BusinessHours, Long> {
    
    List<BusinessHours> findByShopId(Long shopId);
    
    List<BusinessHours> findByShopIdOrderByDayOfWeek(Long shopId);
    
    Optional<BusinessHours> findByShopIdAndDayOfWeek(Long shopId, DayOfWeek dayOfWeek);
    
    @Query("SELECT bh FROM BusinessHours bh WHERE bh.shopId = :shopId AND bh.isOpen = true")
    List<BusinessHours> findOpenHoursByShopId(@Param("shopId") Long shopId);
    
    @Query("SELECT bh FROM BusinessHours bh WHERE bh.shopId = :shopId AND bh.dayOfWeek = :dayOfWeek AND bh.isOpen = true")
    Optional<BusinessHours> findOpenHoursByShopIdAndDay(@Param("shopId") Long shopId, @Param("dayOfWeek") DayOfWeek dayOfWeek);
    
    void deleteByShopId(Long shopId);
    
    boolean existsByShopIdAndDayOfWeek(Long shopId, DayOfWeek dayOfWeek);
}