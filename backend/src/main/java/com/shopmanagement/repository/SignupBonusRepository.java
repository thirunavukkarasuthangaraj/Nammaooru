package com.shopmanagement.repository;

import com.shopmanagement.entity.SignupBonus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SignupBonusRepository extends JpaRepository<SignupBonus, Long> {
    Optional<SignupBonus> findByMobileNumber(String mobileNumber);
    Page<SignupBonus> findByStatusOrderByCreatedAtAsc(SignupBonus.Status status, Pageable pageable);
}
