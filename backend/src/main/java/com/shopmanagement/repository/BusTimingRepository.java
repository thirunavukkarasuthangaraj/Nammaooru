package com.shopmanagement.repository;

import com.shopmanagement.entity.BusTiming;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BusTimingRepository extends JpaRepository<BusTiming, Long> {

    List<BusTiming> findByIsActiveTrueOrderByDepartureTime();

    @Query("SELECT bt FROM BusTiming bt WHERE bt.isActive = true AND LOWER(bt.locationArea) LIKE LOWER(CONCAT('%', :location, '%')) ORDER BY bt.departureTime")
    List<BusTiming> findByLocationArea(@Param("location") String location);

    @Query("SELECT bt FROM BusTiming bt WHERE bt.isActive = true AND " +
           "(LOWER(bt.routeFrom) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(bt.routeTo) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(bt.busName) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(bt.busNumber) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(bt.viaStops) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(bt.locationArea) LIKE LOWER(CONCAT('%', :search, '%'))) " +
           "ORDER BY bt.departureTime")
    List<BusTiming> searchBusTimings(@Param("search") String search);

    List<BusTiming> findAllByOrderByLocationAreaAscDepartureTimeAsc();
}
