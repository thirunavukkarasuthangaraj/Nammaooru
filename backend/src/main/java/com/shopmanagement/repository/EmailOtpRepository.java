package com.shopmanagement.repository;

import com.shopmanagement.entity.EmailOtp;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface EmailOtpRepository extends JpaRepository<EmailOtp, Long> {

    @Query("SELECT eo FROM EmailOtp eo WHERE eo.email = :email AND eo.purpose = :purpose AND eo.isActive = true AND eo.isUsed = false ORDER BY eo.createdAt DESC")
    Optional<EmailOtp> findLatestActiveOtpByEmailAndPurpose(@Param("email") String email, @Param("purpose") String purpose);

    @Query("SELECT eo FROM EmailOtp eo WHERE eo.email = :email AND eo.otpCode = :otpCode AND eo.purpose = :purpose AND eo.isActive = true AND eo.isUsed = false")
    Optional<EmailOtp> findByEmailAndOtpCodeAndPurpose(@Param("email") String email, @Param("otpCode") String otpCode, @Param("purpose") String purpose);

    @Modifying
    @Transactional
    @Query("UPDATE EmailOtp eo SET eo.isActive = false WHERE eo.email = :email AND eo.purpose = :purpose AND eo.isUsed = false")
    void deactivateAllActiveOtpsByEmailAndPurpose(@Param("email") String email, @Param("purpose") String purpose);

    @Modifying
    @Transactional
    @Query("DELETE FROM EmailOtp eo WHERE eo.expiresAt < :expiredBefore")
    void deleteExpiredOtps(@Param("expiredBefore") LocalDateTime expiredBefore);

    @Query("SELECT COUNT(eo) FROM EmailOtp eo WHERE eo.email = :email AND eo.purpose = :purpose AND eo.createdAt > :since")
    long countOtpAttemptsSince(@Param("email") String email, @Param("purpose") String purpose, @Param("since") LocalDateTime since);
}