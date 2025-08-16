package com.shopmanagement.dto.setting;

import com.shopmanagement.entity.Setting;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SettingResponse {
    
    private Long id;
    private String settingKey;
    private String settingValue;
    private String description;
    private String category;
    private Setting.SettingType settingType;
    private Setting.SettingScope scope;
    private Long shopId;
    private String shopName;
    private Long userId;
    private String userName;
    private Boolean isActive;
    private Boolean isRequired;
    private Boolean isReadOnly;
    private String defaultValue;
    private String validationRules;
    private Integer displayOrder;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String createdBy;
    private String updatedBy;
    
    // Helper fields
    private String settingTypeLabel;
    private String scopeLabel;
    private String categoryLabel;
    private Boolean canEdit;
    private Boolean canDelete;
    private String displayValue;
}