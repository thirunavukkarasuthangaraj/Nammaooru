package com.shopmanagement.repository;

import com.shopmanagement.entity.FeatureConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FeatureConfigRepository extends JpaRepository<FeatureConfig, Long> {

    List<FeatureConfig> findAllByOrderByDisplayOrderAsc();

    Optional<FeatureConfig> findByFeatureName(String featureName);

    List<FeatureConfig> findByIsActiveTrueOrderByDisplayOrderAsc();

    @Query(value = "SELECT * FROM feature_configs f WHERE f.is_active = true AND (" +
           "f.latitude IS NULL OR f.longitude IS NULL OR " +
           "(6371 * acos(cos(radians(:lat)) * cos(radians(f.latitude)) * " +
           "cos(radians(f.longitude) - radians(:lng)) + sin(radians(:lat)) * " +
           "sin(radians(f.latitude)))) <= f.radius_km" +
           ") ORDER BY f.display_order ASC",
           nativeQuery = true)
    List<FeatureConfig> findVisibleFeaturesAtLocation(@Param("lat") double lat, @Param("lng") double lng);
}
