package com.shopmanagement.service;

import com.shopmanagement.entity.User;
import com.shopmanagement.entity.DeliveryPartnerSettings;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.repository.DeliveryPartnerSettingsRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class SettingsManagementService {

    private final DeliveryPartnerSettingsRepository settingsRepository;
    private final UserRepository userRepository;

    /**
     * Get or create settings for delivery partner
     */
    public DeliveryPartnerSettings getOrCreateSettings(String partnerId) {
        return settingsRepository.findByPartnerId(partnerId)
            .orElseGet(() -> createDefaultSettings(partnerId));
    }

    /**
     * Create default settings for new delivery partner
     */
    @Transactional
    public DeliveryPartnerSettings createDefaultSettings(String partnerId) {
        log.info("Creating default settings for partner: {}", partnerId);

        User partner = userRepository.findById(Long.valueOf(partnerId))
            .orElseThrow(() -> new IllegalArgumentException("Delivery partner not found: " + partnerId));

        DeliveryPartnerSettings settings = DeliveryPartnerSettings.builder()
            .deliveryPartner(partner)
            .build(); // All default values are set in the entity using @Builder.Default

        DeliveryPartnerSettings savedSettings = settingsRepository.save(settings);
        log.info("Default settings created with ID: {}", savedSettings.getId());

        return savedSettings;
    }

    /**
     * Update notification preferences
     */
    @Transactional
    public DeliveryPartnerSettings updateNotificationPreferences(
            String partnerId,
            boolean pushEnabled,
            boolean emailEnabled,
            boolean smsEnabled,
            boolean orderEnabled,
            boolean earningsEnabled,
            boolean promotionalEnabled,
            String updatedBy) {

        log.info("Updating notification preferences for partner: {}", partnerId);

        settingsRepository.updateNotificationPreferences(
            partnerId, pushEnabled, emailEnabled, smsEnabled,
            orderEnabled, earningsEnabled, promotionalEnabled, updatedBy);

        return getOrCreateSettings(partnerId);
    }

    /**
     * Update work schedule settings
     */
    @Transactional
    public DeliveryPartnerSettings updateWorkSchedule(
            String partnerId,
            boolean scheduleEnabled,
            LocalTime startTime,
            LocalTime endTime,
            String workDays,
            String updatedBy) {

        log.info("Updating work schedule for partner: {}", partnerId);

        DeliveryPartnerSettings settings = getOrCreateSettings(partnerId);

        settings.setWorkScheduleEnabled(scheduleEnabled);
        settings.setWorkStartTime(startTime);
        settings.setWorkEndTime(endTime);
        settings.setWorkDays(workDays);
        settings.setUpdatedBy(updatedBy);

        return settingsRepository.save(settings);
    }

    /**
     * Update auto-accept orders setting
     */
    @Transactional
    public DeliveryPartnerSettings updateAutoAcceptOrders(
            String partnerId,
            boolean autoAccept,
            String updatedBy) {

        log.info("Updating auto-accept orders for partner: {} to {}", partnerId, autoAccept);

        settingsRepository.updateAutoAcceptOrders(partnerId, autoAccept, updatedBy);
        return getOrCreateSettings(partnerId);
    }

    /**
     * Update location sharing settings
     */
    @Transactional
    public DeliveryPartnerSettings updateLocationSettings(
            String partnerId,
            boolean locationSharingEnabled,
            int trackingFrequencySeconds,
            String updatedBy) {

        log.info("Updating location settings for partner: {}", partnerId);

        settingsRepository.updateLocationSettings(
            partnerId, locationSharingEnabled, trackingFrequencySeconds, updatedBy);

        return getOrCreateSettings(partnerId);
    }

    /**
     * Update app preferences (language and theme)
     */
    @Transactional
    public DeliveryPartnerSettings updateAppPreferences(
            String partnerId,
            DeliveryPartnerSettings.Language language,
            DeliveryPartnerSettings.AppTheme theme,
            String updatedBy) {

        log.info("Updating app preferences for partner: {}", partnerId);

        settingsRepository.updateAppPreferences(partnerId, language, theme, updatedBy);
        return getOrCreateSettings(partnerId);
    }

    /**
     * Update delivery preferences
     */
    @Transactional
    public DeliveryPartnerSettings updateDeliveryPreferences(
            String partnerId,
            Integer maxDeliveryRadiusKm,
            String updatedBy) {

        log.info("Updating delivery preferences for partner: {}", partnerId);

        DeliveryPartnerSettings settings = getOrCreateSettings(partnerId);
        settings.setMaxDeliveryRadiusKm(maxDeliveryRadiusKm);
        settings.setUpdatedBy(updatedBy);

        return settingsRepository.save(settings);
    }

    /**
     * Update emergency contact information
     */
    @Transactional
    public DeliveryPartnerSettings updateEmergencyContact(
            String partnerId,
            String contactName,
            String contactPhone,
            String contactRelation,
            String updatedBy) {

        log.info("Updating emergency contact for partner: {}", partnerId);

        DeliveryPartnerSettings settings = getOrCreateSettings(partnerId);
        settings.setEmergencyContactName(contactName);
        settings.setEmergencyContactPhone(contactPhone);
        settings.setEmergencyContactRelation(contactRelation);
        settings.setUpdatedBy(updatedBy);

        return settingsRepository.save(settings);
    }

    /**
     * Update banking preferences
     */
    @Transactional
    public DeliveryPartnerSettings updateBankingPreferences(
            String partnerId,
            String preferredPaymentMethod,
            boolean autoWithdrawEnabled,
            Integer autoWithdrawThreshold,
            Integer autoWithdrawDayOfWeek,
            String updatedBy) {

        log.info("Updating banking preferences for partner: {}", partnerId);

        DeliveryPartnerSettings settings = getOrCreateSettings(partnerId);
        settings.setPreferredPaymentMethod(preferredPaymentMethod);
        settings.setAutoWithdrawEnabled(autoWithdrawEnabled);
        settings.setAutoWithdrawThreshold(autoWithdrawThreshold);
        settings.setAutoWithdrawDayOfWeek(autoWithdrawDayOfWeek);
        settings.setUpdatedBy(updatedBy);

        return settingsRepository.save(settings);
    }

    /**
     * Update privacy settings
     */
    @Transactional
    public DeliveryPartnerSettings updatePrivacySettings(
            String partnerId,
            boolean shareEarningsPublicly,
            boolean sharePerformancePublicly,
            boolean allowCustomerFeedback,
            String updatedBy) {

        log.info("Updating privacy settings for partner: {}", partnerId);

        DeliveryPartnerSettings settings = getOrCreateSettings(partnerId);
        settings.setShareEarningsPublicly(shareEarningsPublicly);
        settings.setSharePerformancePublicly(sharePerformancePublicly);
        settings.setAllowCustomerFeedback(allowCustomerFeedback);
        settings.setUpdatedBy(updatedBy);

        return settingsRepository.save(settings);
    }

    /**
     * Update app behavior settings
     */
    @Transactional
    public DeliveryPartnerSettings updateAppBehaviorSettings(
            String partnerId,
            boolean showTutorial,
            boolean enableSoundAlerts,
            boolean enableVibrationAlerts,
            String mapType,
            boolean trafficOverlayEnabled,
            String updatedBy) {

        log.info("Updating app behavior settings for partner: {}", partnerId);

        DeliveryPartnerSettings settings = getOrCreateSettings(partnerId);
        settings.setShowTutorial(showTutorial);
        settings.setEnableSoundAlerts(enableSoundAlerts);
        settings.setEnableVibrationAlerts(enableVibrationAlerts);
        settings.setMapType(mapType);
        settings.setTrafficOverlayEnabled(trafficOverlayEnabled);
        settings.setUpdatedBy(updatedBy);

        return settingsRepository.save(settings);
    }

    /**
     * Get partners available for auto-assignment
     */
    public List<DeliveryPartnerSettings> getPartnersAvailableForAutoAssignment() {
        return settingsRepository.findAvailablePartnersForAutoAssignment();
    }

    /**
     * Get partners by delivery radius
     */
    public List<DeliveryPartnerSettings> getPartnersByDeliveryRadius(Integer minimumRadius) {
        return settingsRepository.findPartnersByDeliveryRadius(minimumRadius);
    }

    /**
     * Get partners with location sharing enabled
     */
    public List<DeliveryPartnerSettings> getPartnersWithLocationSharing() {
        return settingsRepository.findPartnersWithLocationSharingEnabled();
    }

    /**
     * Get notification preferences summary for admin
     */
    public Map<String, Object> getNotificationPreferencesSummary() {
        Object[] summary = settingsRepository.getNotificationPreferencesSummary();

        Map<String, Object> result = new HashMap<>();
        result.put("pushNotificationsEnabled", ((Number) summary[0]).longValue());
        result.put("emailNotificationsEnabled", ((Number) summary[1]).longValue());
        result.put("smsNotificationsEnabled", ((Number) summary[2]).longValue());
        result.put("orderNotificationsEnabled", ((Number) summary[3]).longValue());
        result.put("earningsNotificationsEnabled", ((Number) summary[4]).longValue());

        return result;
    }

    /**
     * Get language preferences distribution
     */
    public Map<String, Long> getLanguagePreferencesDistribution() {
        List<Object[]> data = settingsRepository.countPartnersByLanguage();
        return data.stream()
            .collect(Collectors.toMap(
                row -> row[0].toString(),
                row -> (Long) row[1]
            ));
    }

    /**
     * Get app theme preferences distribution
     */
    public Map<String, Long> getAppThemeDistribution() {
        List<Object[]> data = settingsRepository.countPartnersByAppTheme();
        return data.stream()
            .collect(Collectors.toMap(
                row -> row[0].toString(),
                row -> (Long) row[1]
            ));
    }

    /**
     * Get partners who need tutorial
     */
    public List<DeliveryPartnerSettings> getPartnersNeedingTutorial() {
        return settingsRepository.findPartnersNeedingTutorial();
    }

    /**
     * Mark tutorial as completed for partner
     */
    @Transactional
    public DeliveryPartnerSettings markTutorialCompleted(String partnerId, String updatedBy) {
        log.info("Marking tutorial as completed for partner: {}", partnerId);

        DeliveryPartnerSettings settings = getOrCreateSettings(partnerId);
        settings.setShowTutorial(false);
        settings.setUpdatedBy(updatedBy);

        return settingsRepository.save(settings);
    }

    /**
     * Get comprehensive settings summary for admin dashboard
     */
    public Map<String, Object> getSettingsSummary() {
        Map<String, Object> summary = new HashMap<>();

        // Notification preferences
        summary.put("notificationPreferences", getNotificationPreferencesSummary());

        // Language distribution
        summary.put("languageDistribution", getLanguagePreferencesDistribution());

        // Theme distribution
        summary.put("themeDistribution", getAppThemeDistribution());

        // Work schedule statistics
        List<DeliveryPartnerSettings> withSchedule = settingsRepository.findPartnersWithWorkSchedule();
        summary.put("partnersWithWorkSchedule", withSchedule.size());

        // Auto-accept statistics
        List<DeliveryPartnerSettings> autoAcceptEnabled = settingsRepository.findPartnersWithAutoAcceptEnabled();
        summary.put("partnersWithAutoAccept", autoAcceptEnabled.size());

        // Location sharing statistics
        List<DeliveryPartnerSettings> locationSharingEnabled = settingsRepository.findPartnersWithLocationSharingEnabled();
        summary.put("partnersWithLocationSharing", locationSharingEnabled.size());

        // Tutorial completion
        List<DeliveryPartnerSettings> needingTutorial = settingsRepository.findPartnersNeedingTutorial();
        summary.put("partnersNeedingTutorial", needingTutorial.size());

        return summary;
    }

    /**
     * Validate work schedule settings
     */
    public void validateWorkSchedule(LocalTime startTime, LocalTime endTime, String workDays) {
        if (startTime != null && endTime != null) {
            if (startTime.isAfter(endTime)) {
                throw new IllegalArgumentException("Start time cannot be after end time");
            }
        }

        if (workDays != null && !workDays.isEmpty()) {
            String[] days = workDays.split(",");
            for (String day : days) {
                try {
                    int dayNum = Integer.parseInt(day.trim());
                    if (dayNum < 1 || dayNum > 7) {
                        throw new IllegalArgumentException("Work days must be between 1 (Monday) and 7 (Sunday)");
                    }
                } catch (NumberFormatException e) {
                    throw new IllegalArgumentException("Invalid work day format: " + day);
                }
            }
        }
    }

    /**
     * Reset settings to default
     */
    @Transactional
    public DeliveryPartnerSettings resetToDefault(String partnerId, String updatedBy) {
        log.info("Resetting settings to default for partner: {}", partnerId);

        DeliveryPartnerSettings settings = getOrCreateSettings(partnerId);

        // Reset to default values
        settings.setPushNotificationsEnabled(true);
        settings.setEmailNotificationsEnabled(true);
        settings.setSmsNotificationsEnabled(true);
        settings.setOrderNotificationsEnabled(true);
        settings.setEarningsNotificationsEnabled(true);
        settings.setPromotionalNotificationsEnabled(true);
        settings.setWorkScheduleEnabled(false);
        settings.setWorkStartTime(null);
        settings.setWorkEndTime(null);
        settings.setWorkDays("1,2,3,4,5,6,7");
        settings.setAutoAcceptOrders(false);
        settings.setMaxDeliveryRadiusKm(null);
        settings.setPreferredLanguage(DeliveryPartnerSettings.Language.ENGLISH);
        settings.setAppTheme(DeliveryPartnerSettings.AppTheme.LIGHT);
        settings.setLocationSharingEnabled(true);
        settings.setLocationTrackingFrequencySeconds(30);
        settings.setShareEarningsPublicly(false);
        settings.setSharePerformancePublicly(false);
        settings.setAllowCustomerFeedback(true);
        settings.setShowTutorial(true);
        settings.setEnableSoundAlerts(true);
        settings.setEnableVibrationAlerts(true);
        settings.setMapType("NORMAL");
        settings.setTrafficOverlayEnabled(true);
        settings.setUpdatedBy(updatedBy);

        return settingsRepository.save(settings);
    }
}