package com.shopmanagement.repository;

import com.shopmanagement.entity.Village;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VillageRepository extends JpaRepository<Village, Long> {

    List<Village> findByIsActiveTrueOrderByDisplayOrderAscNameAsc();

    List<Village> findAllByOrderByDisplayOrderAscNameAsc();
}
