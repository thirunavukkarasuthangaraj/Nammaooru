package com.shopmanagement.delivery.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "partner_availability")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PartnerAvailability {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partner_id", nullable = false)
    private DeliveryPartner deliveryPartner;

    @Column(name = "day_of_week")
    private Integer dayOfWeek;

    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    @Column(name = "is_available")
    @Builder.Default
    private Boolean isAvailable = true;

    @Column(name = "specific_date")
    private LocalDate specificDate;

    @Column(name = "is_special_schedule")
    @Builder.Default
    private Boolean isSpecialSchedule = false;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public boolean isActiveNow() {
        LocalTime now = LocalTime.now();
        return isAvailable && now.isAfter(startTime) && now.isBefore(endTime);
    }

    public boolean isWeeklySchedule() {
        return !isSpecialSchedule && dayOfWeek != null;
    }

    public boolean isSpecificDateSchedule() {
        return isSpecialSchedule && specificDate != null;
    }
}