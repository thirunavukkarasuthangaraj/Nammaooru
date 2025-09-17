package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "delivery_partner_settings")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeliveryPartnerSettings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "delivery_partner_id", nullable = false, unique = true)
    private User deliveryPartner;

    // Notification Settings
    @Column(name = "push_notifications_enabled", nullable = false)
    @Builder.Default
    private Boolean pushNotificationsEnabled = true;

    @Column(name = "email_notifications_enabled", nullable = false)
    @Builder.Default
    private Boolean emailNotificationsEnabled = true;

    @Column(name = "sms_notifications_enabled", nullable = false)
    @Builder.Default
    private Boolean smsNotificationsEnabled = true;

    @Column(name = "order_notifications_enabled", nullable = false)
    @Builder.Default
    private Boolean orderNotificationsEnabled = true;

    @Column(name = "earnings_notifications_enabled", nullable = false)
    @Builder.Default
    private Boolean earningsNotificationsEnabled = true;

    @Column(name = "promotional_notifications_enabled", nullable = false)
    @Builder.Default
    private Boolean promotionalNotificationsEnabled = true;

    // Work Schedule Settings
    @Column(name = "work_schedule_enabled", nullable = false)
    @Builder.Default
    private Boolean workScheduleEnabled = false;

    @Column(name = "work_start_time")
    private LocalTime workStartTime;

    @Column(name = "work_end_time")
    private LocalTime workEndTime;

    @Column(name = "work_days", length = 20)
    @Builder.Default
    private String workDays = "1,2,3,4,5,6,7"; // 1=Monday, 7=Sunday

    @Column(name = "auto_accept_orders", nullable = false)
    @Builder.Default
    private Boolean autoAcceptOrders = false;

    @Column(name = "max_delivery_radius_km")
    private Integer maxDeliveryRadiusKm;

    // App Preferences
    @Enumerated(EnumType.STRING)
    @Column(name = "preferred_language", nullable = false)
    @Builder.Default
    private Language preferredLanguage = Language.ENGLISH;

    @Enumerated(EnumType.STRING)
    @Column(name = "app_theme", nullable = false)
    @Builder.Default
    private AppTheme appTheme = AppTheme.LIGHT;

    @Column(name = "location_sharing_enabled", nullable = false)
    @Builder.Default
    private Boolean locationSharingEnabled = true;

    @Column(name = "location_tracking_frequency_seconds", nullable = false)
    @Builder.Default
    private Integer locationTrackingFrequencySeconds = 30;

    // Privacy Settings
    @Column(name = "share_earnings_publicly", nullable = false)
    @Builder.Default
    private Boolean shareEarningsPublicly = false;

    @Column(name = "share_performance_publicly", nullable = false)
    @Builder.Default
    private Boolean sharePerformancePublicly = false;

    @Column(name = "allow_customer_feedback", nullable = false)
    @Builder.Default
    private Boolean allowCustomerFeedback = true;

    // Emergency Settings
    @Column(name = "emergency_contact_name", length = 100)
    private String emergencyContactName;

    @Column(name = "emergency_contact_phone", length = 15)
    private String emergencyContactPhone;

    @Column(name = "emergency_contact_relation", length = 50)
    private String emergencyContactRelation;

    // Banking Settings
    @Column(name = "preferred_payment_method", length = 50)
    @Builder.Default
    private String preferredPaymentMethod = "BANK_TRANSFER";

    @Column(name = "auto_withdraw_enabled", nullable = false)
    @Builder.Default
    private Boolean autoWithdrawEnabled = false;

    @Column(name = "auto_withdraw_threshold")
    private Integer autoWithdrawThreshold;

    @Column(name = "auto_withdraw_day_of_week")
    private Integer autoWithdrawDayOfWeek; // 1=Monday, 7=Sunday

    // App Behavior Settings
    @Column(name = "show_tutorial", nullable = false)
    @Builder.Default
    private Boolean showTutorial = true;

    @Column(name = "enable_sound_alerts", nullable = false)
    @Builder.Default
    private Boolean enableSoundAlerts = true;

    @Column(name = "enable_vibration_alerts", nullable = false)
    @Builder.Default
    private Boolean enableVibrationAlerts = true;

    @Column(name = "map_type", length = 20)
    @Builder.Default
    private String mapType = "NORMAL";

    @Column(name = "traffic_overlay_enabled", nullable = false)
    @Builder.Default
    private Boolean trafficOverlayEnabled = true;

    // Audit fields
    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @Column(name = "created_by", nullable = false, length = 100)
    @Builder.Default
    private String createdBy = "system";

    @Column(name = "updated_by", nullable = false, length = 100)
    @Builder.Default
    private String updatedBy = "system";

    public enum Language {
        ENGLISH,
        HINDI,
        TAMIL,
        TELUGU,
        KANNADA,
        MALAYALAM,
        BENGALI,
        GUJARATI,
        MARATHI,
        PUNJABI
    }

    public enum AppTheme {
        LIGHT,
        DARK,
        AUTO
    }

    // Helper methods
    public boolean isWorkingNow() {
        if (!workScheduleEnabled || workStartTime == null || workEndTime == null) {
            return true; // Always available if no schedule set
        }

        LocalTime now = LocalTime.now();
        return !now.isBefore(workStartTime) && !now.isAfter(workEndTime);
    }

    public boolean isWorkingDay(int dayOfWeek) {
        if (!workScheduleEnabled || workDays == null) {
            return true;
        }

        return workDays.contains(String.valueOf(dayOfWeek));
    }

    public boolean shouldAcceptOrdersAutomatically() {
        return autoAcceptOrders && isWorkingNow();
    }
}