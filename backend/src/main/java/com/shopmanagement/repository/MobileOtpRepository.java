package com.shopmanagement.repository;

import com.shopmanagement.entity.MobileOtp;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface MobileOtpRepository extends JpaRepository<MobileOtp, Long> {
    
    // Find active OTP for mobile number and purpose
    Optional<MobileOtp> findByMobileNumberAndPurposeAndIsActiveTrue(String mobileNumber, MobileOtp.OtpPurpose purpose);
    
    // Find latest OTP for mobile number and purpose
    @Query("SELECT mo FROM MobileOtp mo WHERE mo.mobileNumber = :mobileNumber AND mo.purpose = :purpose ORDER BY mo.createdAt DESC")
    List<MobileOtp> findLatestOtpByMobileNumberAndPurpose(@Param("mobileNumber") String mobileNumber, 
                                                          @Param("purpose") MobileOtp.OtpPurpose purpose);
    
    // Find valid OTP (active, not used, not expired)
    @Query("SELECT mo FROM MobileOtp mo WHERE mo.mobileNumber = :mobileNumber AND mo.purpose = :purpose " +
           "AND mo.isActive = true AND mo.isUsed = false AND mo.expiresAt > :currentTime")
    Optional<MobileOtp> findValidOtp(@Param("mobileNumber") String mobileNumber, 
                                     @Param("purpose") MobileOtp.OtpPurpose purpose, 
                                     @Param("currentTime") LocalDateTime currentTime);
    
    // Find OTP by mobile number, code and purpose for verification
    Optional<MobileOtp> findByMobileNumberAndOtpCodeAndPurposeAndIsActiveTrue(String mobileNumber, String otpCode, MobileOtp.OtpPurpose purpose);
    
    // Count OTPs sent in the last N minutes for rate limiting
    @Query("SELECT COUNT(mo) FROM MobileOtp mo WHERE mo.mobileNumber = :mobileNumber " +
           "AND mo.purpose = :purpose AND mo.createdAt > :fromTime")
    Long countOtpsSentInTimeFrame(@Param("mobileNumber") String mobileNumber, 
                                  @Param("purpose") MobileOtp.OtpPurpose purpose, 
                                  @Param("fromTime") LocalDateTime fromTime);
    
    // Count OTPs sent from the same device/IP for fraud prevention
    @Query("SELECT COUNT(mo) FROM MobileOtp mo WHERE mo.deviceId = :deviceId " +
           "AND mo.createdAt > :fromTime")
    Long countOtpsByDeviceInTimeFrame(@Param("deviceId") String deviceId, 
                                      @Param("fromTime") LocalDateTime fromTime);
    
    @Query("SELECT COUNT(mo) FROM MobileOtp mo WHERE mo.ipAddress = :ipAddress " +
           "AND mo.createdAt > :fromTime")
    Long countOtpsByIpInTimeFrame(@Param("ipAddress") String ipAddress, 
                                  @Param("fromTime") LocalDateTime fromTime);
    
    // Deactivate all previous OTPs for mobile number and purpose
    @Modifying
    @Query("UPDATE MobileOtp mo SET mo.isActive = false WHERE mo.mobileNumber = :mobileNumber " +
           "AND mo.purpose = :purpose AND mo.isActive = true")
    void deactivatePreviousOtps(@Param("mobileNumber") String mobileNumber, 
                                @Param("purpose") MobileOtp.OtpPurpose purpose);
    
    // Clean up expired OTPs
    @Modifying
    @Query("UPDATE MobileOtp mo SET mo.isActive = false WHERE mo.expiresAt < :currentTime AND mo.isActive = true")
    void deactivateExpiredOtps(@Param("currentTime") LocalDateTime currentTime);
    
    // Find all active OTPs for a mobile number (for admin purposes)
    List<MobileOtp> findByMobileNumberAndIsActiveTrue(String mobileNumber);
    
    // Find OTPs by device ID for security analysis
    List<MobileOtp> findByDeviceIdOrderByCreatedAtDesc(String deviceId);
    
    // Find recent failed verification attempts
    @Query("SELECT mo FROM MobileOtp mo WHERE mo.mobileNumber = :mobileNumber " +
           "AND mo.attemptCount >= mo.maxAttempts AND mo.createdAt > :fromTime")
    List<MobileOtp> findFailedAttempts(@Param("mobileNumber") String mobileNumber, 
                                       @Param("fromTime") LocalDateTime fromTime);
    
    // Statistics queries
    @Query("SELECT COUNT(mo) FROM MobileOtp mo WHERE mo.purpose = :purpose AND mo.createdAt > :fromTime")
    Long countOtpsByPurposeInTimeFrame(@Param("purpose") MobileOtp.OtpPurpose purpose, 
                                       @Param("fromTime") LocalDateTime fromTime);
    
    @Query("SELECT COUNT(mo) FROM MobileOtp mo WHERE mo.isUsed = true AND mo.createdAt > :fromTime")
    Long countVerifiedOtpsInTimeFrame(@Param("fromTime") LocalDateTime fromTime);
    
    @Query("SELECT mo.purpose, COUNT(mo) FROM MobileOtp mo WHERE mo.createdAt > :fromTime GROUP BY mo.purpose")
    List<Object[]> getOtpStatsByPurpose(@Param("fromTime") LocalDateTime fromTime);
    
    // Delete old OTPs (for cleanup job)
    @Modifying
    @Query("DELETE FROM MobileOtp mo WHERE mo.createdAt < :cutoffTime")
    void deleteOldOtps(@Param("cutoffTime") LocalDateTime cutoffTime);
    
    // Find OTPs that need to be expired
    @Query("SELECT mo FROM MobileOtp mo WHERE mo.expiresAt < :currentTime AND mo.isActive = true")
    List<MobileOtp> findOtpsToExpire(@Param("currentTime") LocalDateTime currentTime);

    // Find most recent verified OTP for a mobile number and purpose
    Optional<MobileOtp> findTopByMobileNumberAndPurposeAndVerifiedAtNotNullOrderByVerifiedAtDesc(
        String mobileNumber,
        MobileOtp.OtpPurpose purpose
    );
}