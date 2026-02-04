package com.shopmanagement.repository;

import com.shopmanagement.entity.DeliveryPartnerSettings;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryPartnerSettingsRepository extends JpaRepository<DeliveryPartnerSettings, Long> {

    /**
     * Find settings by delivery partner ID
     */
    @Query("SELECT s FROM DeliveryPartnerSettings s WHERE s.deliveryPartner.id = :partnerId")
    Optional<DeliveryPartnerSettings> findByPartnerId(@Param("partnerId") Long partnerId);

    /**
     * Find partners with auto-accept orders enabled and working now
     */
    @Query("SELECT s FROM DeliveryPartnerSettings s WHERE s.autoAcceptOrders = true " +
           "AND (s.workScheduleEnabled = false OR " +
           "(s.workStartTime IS NULL OR CURRENT_TIME >= s.workStartTime) AND " +
           "(s.workEndTime IS NULL OR CURRENT_TIME <= s.workEndTime))")
    List<DeliveryPartnerSettings> findPartnersWithAutoAcceptEnabled();

    /**
     * Find partners willing to accept orders (auto-accept enabled and available)
     */
    @Query("SELECT s FROM DeliveryPartnerSettings s " +
           "JOIN s.deliveryPartner dp " +
           "WHERE s.autoAcceptOrders = true " +
           "AND dp.isOnline = true " +
           "AND dp.isAvailable = true " +
           "AND (s.workScheduleEnabled = false OR " +
           "(s.workStartTime IS NULL OR CURRENT_TIME >= s.workStartTime) AND " +
           "(s.workEndTime IS NULL OR CURRENT_TIME <= s.workEndTime))")
    List<DeliveryPartnerSettings> findAvailablePartnersForAutoAssignment();

    /**
     * Find partners by maximum delivery radius
     */
    @Query("SELECT s FROM DeliveryPartnerSettings s WHERE s.maxDeliveryRadiusKm >= :minimumRadius " +
           "OR s.maxDeliveryRadiusKm IS NULL")
    List<DeliveryPartnerSettings> findPartnersByDeliveryRadius(@Param("minimumRadius") Integer minimumRadius);

    /**
     * Find partners with location sharing enabled
     */
    @Query("SELECT s FROM DeliveryPartnerSettings s WHERE s.locationSharingEnabled = true")
    List<DeliveryPartnerSettings> findPartnersWithLocationSharingEnabled();

    /**
     * Find partners by preferred language
     */
    @Query("SELECT s FROM DeliveryPartnerSettings s WHERE s.preferredLanguage = :language")
    List<DeliveryPartnerSettings> findPartnersByLanguage(
        @Param("language") DeliveryPartnerSettings.Language language
    );

    /**
     * Find partners with notifications enabled for specific type
     */
    @Query("SELECT s FROM DeliveryPartnerSettings s WHERE s.pushNotificationsEnabled = true " +
           "AND s.orderNotificationsEnabled = true")
    List<DeliveryPartnerSettings> findPartnersWithOrderNotificationsEnabled();

    /**
     * Find partners with earnings notifications enabled
     */
    @Query("SELECT s FROM DeliveryPartnerSettings s WHERE s.pushNotificationsEnabled = true " +
           "AND s.earningsNotificationsEnabled = true")
    List<DeliveryPartnerSettings> findPartnersWithEarningsNotificationsEnabled();

    /**
     * Find partners with promotional notifications enabled
     */
    @Query("SELECT s FROM DeliveryPartnerSettings s WHERE s.pushNotificationsEnabled = true " +
           "AND s.promotionalNotificationsEnabled = true")
    List<DeliveryPartnerSettings> findPartnersWithPromotionalNotificationsEnabled();

    /**
     * Get notification preferences summary
     */
    @Query("SELECT " +
           "SUM(CASE WHEN s.pushNotificationsEnabled = true THEN 1 ELSE 0 END) as pushEnabled, " +
           "SUM(CASE WHEN s.emailNotificationsEnabled = true THEN 1 ELSE 0 END) as emailEnabled, " +
           "SUM(CASE WHEN s.smsNotificationsEnabled = true THEN 1 ELSE 0 END) as smsEnabled, " +
           "SUM(CASE WHEN s.orderNotificationsEnabled = true THEN 1 ELSE 0 END) as orderEnabled, " +
           "SUM(CASE WHEN s.earningsNotificationsEnabled = true THEN 1 ELSE 0 END) as earningsEnabled " +
           "FROM DeliveryPartnerSettings s")
    Object[] getNotificationPreferencesSummary();

    /**
     * Find partners with work schedule enabled
     */
    @Query("SELECT s FROM DeliveryPartnerSettings s WHERE s.workScheduleEnabled = true " +
           "AND s.workStartTime IS NOT NULL AND s.workEndTime IS NOT NULL")
    List<DeliveryPartnerSettings> findPartnersWithWorkSchedule();

    /**
     * Find partners working on specific day of week
     */
    @Query("SELECT s FROM DeliveryPartnerSettings s WHERE s.workScheduleEnabled = true " +
           "AND (s.workDays IS NULL OR s.workDays LIKE CONCAT('%', :dayOfWeek, '%'))")
    List<DeliveryPartnerSettings> findPartnersWorkingOnDay(@Param("dayOfWeek") String dayOfWeek);

    /**
     * Find partners with auto-withdraw enabled
     */
    @Query("SELECT s FROM DeliveryPartnerSettings s WHERE s.autoWithdrawEnabled = true " +
           "AND s.autoWithdrawThreshold IS NOT NULL")
    List<DeliveryPartnerSettings> findPartnersWithAutoWithdrawEnabled();

    /**
     * Find partners with specific app theme preference
     */
    @Query("SELECT s FROM DeliveryPartnerSettings s WHERE s.appTheme = :theme")
    List<DeliveryPartnerSettings> findPartnersByAppTheme(
        @Param("theme") DeliveryPartnerSettings.AppTheme theme
    );

    /**
     * Count partners by language preference
     */
    @Query("SELECT s.preferredLanguage, COUNT(s) FROM DeliveryPartnerSettings s " +
           "GROUP BY s.preferredLanguage ORDER BY COUNT(s) DESC")
    List<Object[]> countPartnersByLanguage();

    /**
     * Count partners by app theme preference
     */
    @Query("SELECT s.appTheme, COUNT(s) FROM DeliveryPartnerSettings s " +
           "GROUP BY s.appTheme ORDER BY COUNT(s) DESC")
    List<Object[]> countPartnersByAppTheme();

    /**
     * Find partners with emergency contact information
     */
    @Query("SELECT s FROM DeliveryPartnerSettings s WHERE s.emergencyContactName IS NOT NULL " +
           "AND s.emergencyContactPhone IS NOT NULL")
    List<DeliveryPartnerSettings> findPartnersWithEmergencyContact();

    /**
     * Find partners who need to see tutorial
     */
    @Query("SELECT s FROM DeliveryPartnerSettings s WHERE s.showTutorial = true")
    List<DeliveryPartnerSettings> findPartnersNeedingTutorial();

    /**
     * Update auto-accept orders setting
     */
    @Query("UPDATE DeliveryPartnerSettings s SET s.autoAcceptOrders = :autoAccept, " +
           "s.updatedBy = :updatedBy WHERE s.deliveryPartner.id = :partnerId")
    void updateAutoAcceptOrders(
        @Param("partnerId") Long partnerId,
        @Param("autoAccept") Boolean autoAccept,
        @Param("updatedBy") String updatedBy
    );

    /**
     * Update notification preferences
     */
    @Query("UPDATE DeliveryPartnerSettings s SET " +
           "s.pushNotificationsEnabled = :pushEnabled, " +
           "s.emailNotificationsEnabled = :emailEnabled, " +
           "s.smsNotificationsEnabled = :smsEnabled, " +
           "s.orderNotificationsEnabled = :orderEnabled, " +
           "s.earningsNotificationsEnabled = :earningsEnabled, " +
           "s.promotionalNotificationsEnabled = :promotionalEnabled, " +
           "s.updatedBy = :updatedBy " +
           "WHERE s.deliveryPartner.id = :partnerId")
    void updateNotificationPreferences(
        @Param("partnerId") Long partnerId,
        @Param("pushEnabled") Boolean pushEnabled,
        @Param("emailEnabled") Boolean emailEnabled,
        @Param("smsEnabled") Boolean smsEnabled,
        @Param("orderEnabled") Boolean orderEnabled,
        @Param("earningsEnabled") Boolean earningsEnabled,
        @Param("promotionalEnabled") Boolean promotionalEnabled,
        @Param("updatedBy") String updatedBy
    );

    /**
     * Update location sharing settings
     */
    @Query("UPDATE DeliveryPartnerSettings s SET s.locationSharingEnabled = :enabled, " +
           "s.locationTrackingFrequencySeconds = :frequency, s.updatedBy = :updatedBy " +
           "WHERE s.deliveryPartner.id = :partnerId")
    void updateLocationSettings(
        @Param("partnerId") Long partnerId,
        @Param("enabled") Boolean enabled,
        @Param("frequency") Integer frequency,
        @Param("updatedBy") String updatedBy
    );

    /**
     * Update app preferences
     */
    @Query("UPDATE DeliveryPartnerSettings s SET s.preferredLanguage = :language, " +
           "s.appTheme = :theme, s.updatedBy = :updatedBy WHERE s.deliveryPartner.id = :partnerId")
    void updateAppPreferences(
        @Param("partnerId") Long partnerId,
        @Param("language") DeliveryPartnerSettings.Language language,
        @Param("theme") DeliveryPartnerSettings.AppTheme theme,
        @Param("updatedBy") String updatedBy
    );
}