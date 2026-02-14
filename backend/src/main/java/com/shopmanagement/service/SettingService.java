package com.shopmanagement.service;

import com.shopmanagement.dto.setting.SettingRequest;
import com.shopmanagement.dto.setting.SettingResponse;
import com.shopmanagement.entity.Setting;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.SettingRepository;
import com.shopmanagement.shop.repository.ShopRepository;
import com.shopmanagement.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class SettingService {
    
    private final SettingRepository settingRepository;
    private final ShopRepository shopRepository;
    private final UserRepository userRepository;
    
    @Transactional
    public SettingResponse createSetting(SettingRequest request) {
        log.info("Creating setting: {}", request.getSettingKey());
        
        // Check if setting key already exists
        if (settingRepository.existsBySettingKey(request.getSettingKey())) {
            throw new RuntimeException("Setting key already exists: " + request.getSettingKey());
        }
        
        // Validate scope-specific requirements
        validateScopeRequirements(request);
        
        Setting setting = Setting.builder()
                .settingKey(request.getSettingKey())
                .settingValue(request.getSettingValue())
                .description(request.getDescription())
                .category(request.getCategory())
                .settingType(request.getSettingType())
                .scope(request.getScope())
                .shopId(request.getShopId())
                .userId(request.getUserId())
                .isActive(request.getIsActive() != null ? request.getIsActive() : true)
                .isRequired(request.getIsRequired() != null ? request.getIsRequired() : false)
                .isReadOnly(request.getIsReadOnly() != null ? request.getIsReadOnly() : false)
                .defaultValue(request.getDefaultValue())
                .validationRules(request.getValidationRules())
                .displayOrder(request.getDisplayOrder())
                .createdBy(getCurrentUsername())
                .updatedBy(getCurrentUsername())
                .build();
        
        Setting savedSetting = settingRepository.save(setting);
        log.info("Setting created successfully: {}", savedSetting.getSettingKey());
        return mapToResponse(savedSetting);
    }
    
    public SettingResponse getSettingById(Long id) {
        Setting setting = settingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Setting not found with id: " + id));
        return mapToResponse(setting);
    }
    
    public SettingResponse getSettingByKey(String key) {
        Setting setting = settingRepository.findBySettingKey(key)
                .orElseThrow(() -> new RuntimeException("Setting not found with key: " + key));
        return mapToResponse(setting);
    }
    
    public String getSettingValue(String key) {
        Setting setting = settingRepository.findBySettingKey(key)
                .orElseThrow(() -> new RuntimeException("Setting not found with key: " + key));
        return setting.getSettingValue();
    }
    
    public String getSettingValue(String key, String defaultValue) {
        return settingRepository.findBySettingKey(key)
                .map(Setting::getSettingValue)
                .orElse(defaultValue);
    }
    
    @Transactional
    public SettingResponse updateSetting(Long id, SettingRequest request) {
        log.info("Updating setting: {}", id);
        
        Setting setting = settingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Setting not found with id: " + id));
        
        // Check if setting is read-only
        if (setting.getIsReadOnly()) {
            throw new RuntimeException("Cannot update read-only setting: " + setting.getSettingKey());
        }
        
        // Check if key is being changed and if new key already exists
        if (!setting.getSettingKey().equals(request.getSettingKey()) && 
            settingRepository.existsBySettingKey(request.getSettingKey())) {
            throw new RuntimeException("Setting key already exists: " + request.getSettingKey());
        }
        
        // Validate scope-specific requirements
        validateScopeRequirements(request);
        
        // Update setting fields
        setting.setSettingKey(request.getSettingKey());
        setting.setSettingValue(request.getSettingValue());
        setting.setDescription(request.getDescription());
        setting.setCategory(request.getCategory());
        setting.setSettingType(request.getSettingType());
        setting.setScope(request.getScope());
        setting.setShopId(request.getShopId());
        setting.setUserId(request.getUserId());
        if (request.getIsActive() != null) {
            setting.setIsActive(request.getIsActive());
        }
        if (request.getIsRequired() != null) {
            setting.setIsRequired(request.getIsRequired());
        }
        if (request.getIsReadOnly() != null) {
            setting.setIsReadOnly(request.getIsReadOnly());
        }
        setting.setDefaultValue(request.getDefaultValue());
        setting.setValidationRules(request.getValidationRules());
        setting.setDisplayOrder(request.getDisplayOrder());
        setting.setUpdatedBy(getCurrentUsername());
        
        Setting updatedSetting = settingRepository.save(setting);
        log.info("Setting updated successfully: {}", updatedSetting.getSettingKey());
        return mapToResponse(updatedSetting);
    }
    
    @Transactional
    public void deleteSetting(Long id) {
        log.info("Deleting setting: {}", id);
        
        Setting setting = settingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Setting not found with id: " + id));
        
        // Check if setting is required
        if (setting.getIsRequired()) {
            throw new RuntimeException("Cannot delete required setting: " + setting.getSettingKey());
        }
        
        settingRepository.delete(setting);
        log.info("Setting deleted successfully: {}", setting.getSettingKey());
    }
    
    @Transactional
    public SettingResponse updateSettingValue(String key, String value) {
        log.info("Updating setting value for key: {}", key);
        
        Setting setting = settingRepository.findBySettingKey(key)
                .orElseThrow(() -> new RuntimeException("Setting not found with key: " + key));
        
        if (setting.getIsReadOnly()) {
            throw new RuntimeException("Cannot update read-only setting: " + key);
        }
        
        setting.setSettingValue(value);
        setting.setUpdatedBy(getCurrentUsername());
        
        Setting updatedSetting = settingRepository.save(setting);
        log.info("Setting value updated successfully: {}", key);
        return mapToResponse(updatedSetting);
    }
    
    public Page<SettingResponse> getAllSettings(int page, int size, String sortBy, String sortDirection) {
        Sort.Direction direction = sortDirection.equalsIgnoreCase("desc") ? Sort.Direction.DESC : Sort.Direction.ASC;
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        
        Page<Setting> settings = settingRepository.findAll(pageable);
        return settings.map(this::mapToResponse);
    }
    
    public Page<SettingResponse> getSettingsByScope(Setting.SettingScope scope, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "category", "displayOrder", "settingKey"));
        Page<Setting> settings = settingRepository.findByScope(scope, pageable);
        return settings.map(this::mapToResponse);
    }
    
    public Page<SettingResponse> getSettingsByCategory(String category, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "displayOrder", "settingKey"));
        Page<Setting> settings = settingRepository.findByCategory(category, pageable);
        return settings.map(this::mapToResponse);
    }
    
    public List<SettingResponse> getGlobalSettings() {
        List<Setting> settings = settingRepository.findGlobalSettings();
        return settings.stream().map(this::mapToResponse).collect(Collectors.toList());
    }
    
    public List<SettingResponse> getShopSettings(Long shopId) {
        List<Setting> settings = settingRepository.findShopSettings(shopId);
        return settings.stream().map(this::mapToResponse).collect(Collectors.toList());
    }
    
    public List<SettingResponse> getUserSettings(Long userId) {
        List<Setting> settings = settingRepository.findUserSettings(userId);
        return settings.stream().map(this::mapToResponse).collect(Collectors.toList());
    }
    
    public Page<SettingResponse> searchSettings(String searchTerm, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "category", "settingKey"));
        Page<Setting> settings = settingRepository.searchSettings(searchTerm, pageable);
        return settings.map(this::mapToResponse);
    }
    
    public List<String> getAvailableCategories() {
        return settingRepository.findDistinctCategories();
    }
    
    public List<String> getCategoriesByScope(Setting.SettingScope scope) {
        return settingRepository.findCategoriesByScope(scope);
    }
    
    public Map<String, String> getSettingsAsMap(String category) {
        List<Setting> settings = settingRepository.findByCategory(category);
        return settings.stream()
                .collect(Collectors.toMap(Setting::getSettingKey, Setting::getSettingValue));
    }
    
    @Transactional
    public void resetToDefault(String key) {
        log.info("Resetting setting to default: {}", key);
        
        Setting setting = settingRepository.findBySettingKey(key)
                .orElseThrow(() -> new RuntimeException("Setting not found with key: " + key));
        
        if (setting.getDefaultValue() != null) {
            setting.setSettingValue(setting.getDefaultValue());
            setting.setUpdatedBy(getCurrentUsername());
            settingRepository.save(setting);
            log.info("Setting reset to default: {}", key);
        } else {
            throw new RuntimeException("No default value available for setting: " + key);
        }
    }
    
    @Transactional
    public void initializeDefaultSettings() {
        log.info("Initializing default system settings");
        
        createDefaultSettingIfNotExists("app.name", "NammaOoru Thiru Software", 
                "Application Name", "GENERAL", Setting.SettingType.STRING, Setting.SettingScope.GLOBAL);
        
        createDefaultSettingIfNotExists("app.version", "1.0.0", 
                "Application Version", "GENERAL", Setting.SettingType.STRING, Setting.SettingScope.GLOBAL);
        
        createDefaultSettingIfNotExists("app.maintenance.mode", "false", 
                "Maintenance Mode", "SYSTEM", Setting.SettingType.BOOLEAN, Setting.SettingScope.GLOBAL);
        
        createDefaultSettingIfNotExists("email.from", "noreply@nammaooru.com", 
                "Default From Email", "EMAIL", Setting.SettingType.EMAIL, Setting.SettingScope.GLOBAL);
        
        createDefaultSettingIfNotExists("order.auto.approve", "false", 
                "Auto Approve Orders", "ORDER", Setting.SettingType.BOOLEAN, Setting.SettingScope.GLOBAL);
        
        createDefaultSettingIfNotExists("shop.approval.required", "true",
                "Shop Approval Required", "SHOP", Setting.SettingType.BOOLEAN, Setting.SettingScope.GLOBAL);

        // Marketplace settings
        createDefaultSettingIfNotExists("marketplace.post.duration_days", "30",
                "How many days a post stays visible (0 = no expiry)", "MARKETPLACE", Setting.SettingType.INTEGER, Setting.SettingScope.GLOBAL);

        createDefaultSettingIfNotExists("marketplace.post.auto_approve", "false",
                "Auto-approve new marketplace posts (skip pending approval)", "MARKETPLACE", Setting.SettingType.BOOLEAN, Setting.SettingScope.GLOBAL);

        createDefaultSettingIfNotExists("marketplace.post.visible_statuses", "[\"APPROVED\"]",
                "Which post statuses are visible to the public", "MARKETPLACE", Setting.SettingType.JSON, Setting.SettingScope.GLOBAL);

        createDefaultSettingIfNotExists("marketplace.post.report_threshold", "3",
                "Number of reports needed before auto-flagging a post", "MARKETPLACE", Setting.SettingType.INTEGER, Setting.SettingScope.GLOBAL);

        // Farmer Products settings
        createDefaultSettingIfNotExists("farmer_products.post.duration_days", "30",
                "How many days a farmer product post stays visible (0 = no expiry)", "FARMER_PRODUCTS", Setting.SettingType.INTEGER, Setting.SettingScope.GLOBAL);

        createDefaultSettingIfNotExists("farmer_products.post.auto_approve", "false",
                "Auto-approve new farmer product posts (skip pending approval)", "FARMER_PRODUCTS", Setting.SettingType.BOOLEAN, Setting.SettingScope.GLOBAL);

        createDefaultSettingIfNotExists("farmer_products.post.visible_statuses", "[\"APPROVED\"]",
                "Which farmer product post statuses are visible to the public", "FARMER_PRODUCTS", Setting.SettingType.JSON, Setting.SettingScope.GLOBAL);

        createDefaultSettingIfNotExists("farmer_products.post.report_threshold", "3",
                "Number of reports needed before auto-flagging a farmer product post", "FARMER_PRODUCTS", Setting.SettingType.INTEGER, Setting.SettingScope.GLOBAL);

        log.info("Default settings initialization completed");
    }
    
    private void createDefaultSettingIfNotExists(String key, String value, String description, 
                                                String category, Setting.SettingType type, Setting.SettingScope scope) {
        if (!settingRepository.existsBySettingKey(key)) {
            Setting setting = Setting.builder()
                    .settingKey(key)
                    .settingValue(value)
                    .description(description)
                    .category(category)
                    .settingType(type)
                    .scope(scope)
                    .defaultValue(value)
                    .isActive(true)
                    .isRequired(true)
                    .createdBy("system")
                    .updatedBy("system")
                    .build();
            settingRepository.save(setting);
            log.debug("Created default setting: {}", key);
        }
    }
    
    private void validateScopeRequirements(SettingRequest request) {
        if (request.getScope() == Setting.SettingScope.SHOP && request.getShopId() == null) {
            throw new RuntimeException("Shop ID is required for shop-scoped settings");
        }
        
        if (request.getScope() == Setting.SettingScope.USER && request.getUserId() == null) {
            throw new RuntimeException("User ID is required for user-scoped settings");
        }
        
        if (request.getScope() == Setting.SettingScope.GLOBAL && 
            (request.getShopId() != null || request.getUserId() != null)) {
            throw new RuntimeException("Global settings cannot have shop or user associations");
        }
    }
    
    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null ? authentication.getName() : "system";
    }
    
    private SettingResponse mapToResponse(Setting setting) {
        String shopName = null;
        if (setting.getShopId() != null) {
            Shop shop = shopRepository.findById(setting.getShopId()).orElse(null);
            shopName = shop != null ? shop.getName() : null;
        }
        
        String userName = null;
        if (setting.getUserId() != null) {
            User user = userRepository.findById(setting.getUserId()).orElse(null);
            userName = user != null ? user.getFullName() : null;
        }
        
        String displayValue = setting.getSettingValue();
        if (setting.getSettingType() == Setting.SettingType.PASSWORD) {
            displayValue = "********";
        } else if (setting.getSettingType() == Setting.SettingType.BOOLEAN) {
            displayValue = Boolean.parseBoolean(setting.getSettingValue()) ? "Yes" : "No";
        }
        
        return SettingResponse.builder()
                .id(setting.getId())
                .settingKey(setting.getSettingKey())
                .settingValue(setting.getSettingValue())
                .description(setting.getDescription())
                .category(setting.getCategory())
                .settingType(setting.getSettingType())
                .scope(setting.getScope())
                .shopId(setting.getShopId())
                .shopName(shopName)
                .userId(setting.getUserId())
                .userName(userName)
                .isActive(setting.getIsActive())
                .isRequired(setting.getIsRequired())
                .isReadOnly(setting.getIsReadOnly())
                .defaultValue(setting.getDefaultValue())
                .validationRules(setting.getValidationRules())
                .displayOrder(setting.getDisplayOrder())
                .createdAt(setting.getCreatedAt())
                .updatedAt(setting.getUpdatedAt())
                .createdBy(setting.getCreatedBy())
                .updatedBy(setting.getUpdatedBy())
                .settingTypeLabel(setting.getSettingType().name())
                .scopeLabel(setting.getScope().name())
                .categoryLabel(setting.getCategory())
                .canEdit(!setting.getIsReadOnly())
                .canDelete(!setting.getIsRequired())
                .displayValue(displayValue)
                .build();
    }
}