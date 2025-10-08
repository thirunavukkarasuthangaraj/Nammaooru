package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "app_version")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AppVersion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "app_name", nullable = false, length = 50)
    private String appName; // CUSTOMER_APP, SHOP_OWNER_APP, DELIVERY_PARTNER_APP

    @Column(name = "platform", nullable = false, length = 20)
    private String platform; // ANDROID, IOS

    @Column(name = "current_version", nullable = false, length = 20)
    private String currentVersion; // e.g., "1.0.0"

    @Column(name = "minimum_version", nullable = false, length = 20)
    private String minimumVersion; // Minimum required version

    @Column(name = "update_url", nullable = false, columnDefinition = "TEXT")
    private String updateUrl; // Play Store / App Store URL

    @Column(name = "is_mandatory")
    private Boolean isMandatory = false; // If true, force update

    @Column(name = "release_notes", columnDefinition = "TEXT")
    private String releaseNotes; // What's new in this version

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
