package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * When a shop can DELIVER, which is not the same question as when it is open.
 *
 * A shop open 9 to 9 may deliver only 10 to 7. Scheduled delivery windows are generated
 * from these rows, never from BusinessHours, so a window can only ever be offered for a
 * time the shop actually delivers.
 *
 * Mirrors BusinessHours on purpose, break windows included, so the shop owner screen and
 * the slot generator can handle both the same way.
 */
@Entity
@Table(name = "delivery_hours",
       uniqueConstraints = @UniqueConstraint(columnNames = {"shop_id", "day_of_week"}))
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeliveryHours {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "shop_id", nullable = false)
    private Long shopId;

    @Enumerated(EnumType.STRING)
    @Column(name = "day_of_week", nullable = false, length = 20)
    private DayOfWeek dayOfWeek;

    @Column(name = "open_time")
    private LocalTime openTime;

    @Column(name = "close_time")
    private LocalTime closeTime;

    @Column(name = "break_start_time")
    private LocalTime breakStartTime;

    @Column(name = "break_end_time")
    private LocalTime breakEndTime;

    @Builder.Default
    @Column(name = "is_open", nullable = false)
    private Boolean isOpen = true;

    @Builder.Default
    @Column(name = "is24hours", nullable = false)
    private Boolean is24Hours = false;

    @Column(name = "special_note")
    private String specialNote;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "created_by")
    private String createdBy;

    @Column(name = "updated_by")
    private String updatedBy;

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = createdAt;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
