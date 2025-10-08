package com.shopmanagement.repository;

import com.shopmanagement.entity.AppVersion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AppVersionRepository extends JpaRepository<AppVersion, Long> {
    Optional<AppVersion> findByAppNameAndPlatform(String appName, String platform);
}
