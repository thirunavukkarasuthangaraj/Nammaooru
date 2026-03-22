package com.shopmanagement.userservice.repository;

import com.shopmanagement.userservice.entity.MobileOtp;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface MobileOtpRepository extends JpaRepository<MobileOtp, Long> {

    Optional<MobileOtp> findByMobileNumberAndOtpCodeAndPurposeAndIsActiveTrue(
        String mobileNumber, String otpCode, MobileOtp.OtpPurpose purpose);

    @Query("SELECT mo FROM MobileOtp mo WHERE mo.mobileNumber = :mobileNumber AND mo.purpose = :purpose " +
           "AND mo.isActive = true AND mo.isUsed = false AND mo.expiresAt > :currentTime")
    Optional<MobileOtp> findValidOtp(@Param("mobileNumber") String mobileNumber,
                                     @Param("purpose") MobileOtp.OtpPurpose purpose,
                                     @Param("currentTime") LocalDateTime currentTime);

    @Query("SELECT COUNT(mo) FROM MobileOtp mo WHERE mo.mobileNumber = :mobileNumber " +
           "AND mo.purpose = :purpose AND mo.createdAt > :fromTime")
    Long countOtpsSentInTimeFrame(@Param("mobileNumber") String mobileNumber,
                                  @Param("purpose") MobileOtp.OtpPurpose purpose,
                                  @Param("fromTime") LocalDateTime fromTime);

    @Query("SELECT COUNT(mo) FROM MobileOtp mo WHERE mo.deviceId = :deviceId AND mo.createdAt > :fromTime")
    Long countOtpsByDeviceInTimeFrame(@Param("deviceId") String deviceId, @Param("fromTime") LocalDateTime fromTime);

    @Modifying
    @Query("UPDATE MobileOtp mo SET mo.isActive = false WHERE mo.mobileNumber = :mobileNumber " +
           "AND mo.purpose = :purpose AND mo.isActive = true")
    void deactivatePreviousOtps(@Param("mobileNumber") String mobileNumber, @Param("purpose") MobileOtp.OtpPurpose purpose);

    @Modifying
    @Query("UPDATE MobileOtp mo SET mo.isActive = false WHERE mo.expiresAt < :currentTime AND mo.isActive = true")
    void deactivateExpiredOtps(@Param("currentTime") LocalDateTime currentTime);

    @Modifying
    @Query("DELETE FROM MobileOtp mo WHERE mo.createdAt < :cutoffTime")
    void deleteOldOtps(@Param("cutoffTime") LocalDateTime cutoffTime);

    @Query("SELECT COUNT(mo) FROM MobileOtp mo WHERE mo.purpose = :purpose AND mo.createdAt > :fromTime")
    Long countOtpsByPurposeInTimeFrame(@Param("purpose") MobileOtp.OtpPurpose purpose, @Param("fromTime") LocalDateTime fromTime);

    @Query("SELECT COUNT(mo) FROM MobileOtp mo WHERE mo.isUsed = true AND mo.createdAt > :fromTime")
    Long countVerifiedOtpsInTimeFrame(@Param("fromTime") LocalDateTime fromTime);

    Optional<MobileOtp> findTopByMobileNumberAndPurposeAndVerifiedAtNotNullOrderByVerifiedAtDesc(
        String mobileNumber, MobileOtp.OtpPurpose purpose);
}
