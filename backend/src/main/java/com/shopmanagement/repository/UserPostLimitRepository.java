package com.shopmanagement.repository;

import com.shopmanagement.entity.UserPostLimit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserPostLimitRepository extends JpaRepository<UserPostLimit, Long> {

    Optional<UserPostLimit> findByUserIdAndFeatureName(Long userId, String featureName);

    List<UserPostLimit> findByUserId(Long userId);

    List<UserPostLimit> findByFeatureName(String featureName);
}
