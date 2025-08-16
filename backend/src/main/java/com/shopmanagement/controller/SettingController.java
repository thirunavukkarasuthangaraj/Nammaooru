package com.shopmanagement.controller;

import com.shopmanagement.dto.setting.SettingRequest;
import com.shopmanagement.dto.setting.SettingResponse;
import com.shopmanagement.entity.Setting;
import com.shopmanagement.service.SettingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/settings")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(originPatterns = {"*"})
public class SettingController {
    
    private final SettingService settingService;
    
    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<SettingResponse> createSetting(@Valid @RequestBody SettingRequest request) {
        log.info("Creating setting: {}", request.getSettingKey());
        SettingResponse response = settingService.createSetting(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<SettingResponse> getSettingById(@PathVariable Long id) {
        log.info("Fetching setting with ID: {}", id);
        SettingResponse response = settingService.getSettingById(id);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/key/{key}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<SettingResponse> getSettingByKey(@PathVariable String key) {
        log.info("Fetching setting with key: {}", key);
        SettingResponse response = settingService.getSettingByKey(key);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/value/{key}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<String> getSettingValue(@PathVariable String key) {
        log.info("Fetching setting value for key: {}", key);
        String value = settingService.getSettingValue(key);
        return ResponseEntity.ok(value);
    }
    
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<SettingResponse> updateSetting(@PathVariable Long id, @Valid @RequestBody SettingRequest request) {
        log.info("Updating setting: {}", id);
        SettingResponse response = settingService.updateSetting(id, request);
        return ResponseEntity.ok(response);
    }
    
    @PutMapping("/value/{key}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<SettingResponse> updateSettingValue(@PathVariable String key, @RequestBody String value) {
        log.info("Updating setting value for key: {}", key);
        SettingResponse response = settingService.updateSettingValue(key, value);
        return ResponseEntity.ok(response);
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<Void> deleteSetting(@PathVariable Long id) {
        log.info("Deleting setting: {}", id);
        settingService.deleteSetting(id);
        return ResponseEntity.noContent().build();
    }
    
    @PostMapping("/reset/{key}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Void> resetToDefault(@PathVariable String key) {
        log.info("Resetting setting to default: {}", key);
        settingService.resetToDefault(key);
        return ResponseEntity.ok().build();
    }
    
    @PostMapping("/initialize")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<Void> initializeDefaultSettings() {
        log.info("Initializing default system settings");
        settingService.initializeDefaultSettings();
        return ResponseEntity.ok().build();
    }
    
    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Page<SettingResponse>> getAllSettings(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "category") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDirection) {
        log.info("Fetching all settings - page: {}, size: {}", page, size);
        Page<SettingResponse> response = settingService.getAllSettings(page, size, sortBy, sortDirection);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/scope/{scope}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Page<SettingResponse>> getSettingsByScope(
            @PathVariable String scope,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching settings by scope: {}", scope);
        Setting.SettingScope settingScope = Setting.SettingScope.valueOf(scope.toUpperCase());
        Page<SettingResponse> response = settingService.getSettingsByScope(settingScope, page, size);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/category/{category}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Page<SettingResponse>> getSettingsByCategory(
            @PathVariable String category,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Fetching settings by category: {}", category);
        Page<SettingResponse> response = settingService.getSettingsByCategory(category, page, size);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/global")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<List<SettingResponse>> getGlobalSettings() {
        log.info("Fetching global settings");
        List<SettingResponse> response = settingService.getGlobalSettings();
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/shop/{shopId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<List<SettingResponse>> getShopSettings(@PathVariable Long shopId) {
        log.info("Fetching shop settings for shop: {}", shopId);
        List<SettingResponse> response = settingService.getShopSettings(shopId);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/user/{userId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or #userId == authentication.principal.id")
    public ResponseEntity<List<SettingResponse>> getUserSettings(@PathVariable Long userId) {
        log.info("Fetching user settings for user: {}", userId);
        List<SettingResponse> response = settingService.getUserSettings(userId);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/search")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<Page<SettingResponse>> searchSettings(
            @RequestParam String searchTerm,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("Searching settings with term: {}", searchTerm);
        Page<SettingResponse> response = settingService.searchSettings(searchTerm, page, size);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/categories")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<List<String>> getAvailableCategories() {
        log.info("Fetching available setting categories");
        List<String> categories = settingService.getAvailableCategories();
        return ResponseEntity.ok(categories);
    }
    
    @GetMapping("/categories/scope/{scope}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<List<String>> getCategoriesByScope(@PathVariable String scope) {
        log.info("Fetching categories by scope: {}", scope);
        Setting.SettingScope settingScope = Setting.SettingScope.valueOf(scope.toUpperCase());
        List<String> categories = settingService.getCategoriesByScope(settingScope);
        return ResponseEntity.ok(categories);
    }
    
    @GetMapping("/map/{category}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN') or hasRole('SHOP_OWNER')")
    public ResponseEntity<Map<String, String>> getSettingsAsMap(@PathVariable String category) {
        log.info("Fetching settings as map for category: {}", category);
        Map<String, String> settings = settingService.getSettingsAsMap(category);
        return ResponseEntity.ok(settings);
    }
    
    @GetMapping("/enums")
    public ResponseEntity<Map<String, Object>> getSettingEnums() {
        return ResponseEntity.ok(Map.of(
                "settingTypes", Setting.SettingType.values(),
                "settingScopes", Setting.SettingScope.values()
        ));
    }
}