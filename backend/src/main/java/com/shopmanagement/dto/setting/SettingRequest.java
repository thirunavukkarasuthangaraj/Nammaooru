package com.shopmanagement.dto.setting;

import com.shopmanagement.entity.Setting;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SettingRequest {
    
    @NotBlank(message = "Setting key is required")
    @Size(max = 100, message = "Setting key cannot exceed 100 characters")
    private String settingKey;
    
    @NotBlank(message = "Setting value is required")
    private String settingValue;
    
    @Size(max = 200, message = "Description cannot exceed 200 characters")
    private String description;
    
    @Size(max = 50, message = "Category cannot exceed 50 characters")
    private String category;
    
    @NotNull(message = "Setting type is required")
    private Setting.SettingType settingType;
    
    @NotNull(message = "Setting scope is required")
    private Setting.SettingScope scope;
    
    private Long shopId;
    
    private Long userId;
    
    private Boolean isActive;
    
    private Boolean isRequired;
    
    private Boolean isReadOnly;
    
    private String defaultValue;
    
    private String validationRules;
    
    private Integer displayOrder;
}