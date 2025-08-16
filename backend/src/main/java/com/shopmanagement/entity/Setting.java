package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "settings")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Setting {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(unique = true, nullable = false, length = 100)
    private String settingKey;
    
    @Column(nullable = false, columnDefinition = "TEXT")
    private String settingValue;
    
    @Column(length = 200)
    private String description;
    
    @Column(length = 50)
    private String category;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private SettingType settingType;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private SettingScope scope;
    
    @Column(name = "shop_id")
    private Long shopId;
    
    @Column(name = "user_id")
    private Long userId;
    
    @Builder.Default
    private Boolean isActive = true;
    
    @Builder.Default
    private Boolean isRequired = false;
    
    @Builder.Default
    private Boolean isReadOnly = false;
    
    @Column(name = "default_value", columnDefinition = "TEXT")
    private String defaultValue;
    
    @Column(name = "validation_rules", columnDefinition = "TEXT")
    private String validationRules;
    
    @Column(name = "display_order")
    private Integer displayOrder;
    
    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @Column(name = "created_by", length = 100)
    private String createdBy;
    
    @Column(name = "updated_by", length = 100)
    private String updatedBy;
    
    public enum SettingType {
        STRING, INTEGER, BOOLEAN, DECIMAL, JSON, EMAIL, URL, PASSWORD, FILE_PATH, COLOR, DATE, TIME, DATETIME
    }
    
    public enum SettingScope {
        GLOBAL, SHOP, USER
    }
}