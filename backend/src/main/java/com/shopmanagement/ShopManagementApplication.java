package com.shopmanagement;

import com.shopmanagement.entity.WomensCornerCategory;
import com.shopmanagement.repository.WomensCornerCategoryRepository;
import com.shopmanagement.service.SettingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

import javax.annotation.PostConstruct;
import java.util.TimeZone;

@SpringBootApplication
@EnableJpaAuditing
@EnableScheduling
@EnableAsync
@RequiredArgsConstructor
@Slf4j
public class ShopManagementApplication {

    private final SettingService settingService;
    private final WomensCornerCategoryRepository womensCornerCategoryRepository;

    @PostConstruct
    public void init() {
        // Set application timezone to Asia/Kolkata (Indian Standard Time)
        TimeZone.setDefault(TimeZone.getTimeZone("Asia/Kolkata"));
        System.out.println("🕐 Application timezone set to: " + TimeZone.getDefault().getID());
    }

    @EventListener(ApplicationReadyEvent.class)
    public void onApplicationReady() {
        try {
            settingService.initializeDefaultSettings();
            log.info("Default settings initialized on startup");
        } catch (Exception e) {
            log.warn("Could not initialize default settings on startup: {}", e.getMessage());
        }
        try {
            initializeWomensCornerCategories();
        } catch (Exception e) {
            log.warn("Could not initialize women's corner categories: {}", e.getMessage());
        }
    }

    private void initializeWomensCornerCategories() {
        if (womensCornerCategoryRepository.count() > 0) {
            log.debug("Women's corner categories already exist, skipping initialization");
            return;
        }
        String[][] defaults = {
            {"Tailoring", "\u0BA4\u0BC8\u0BAF\u0BB2\u0BCD", "#E91E63", "1"},
            {"Makeup Artist", "\u0B85\u0BB4\u0B95\u0BC1\u0B95\u0BCD\u0B95\u0BB2\u0BC8", "#9C27B0", "2"},
            {"Fashion & Dress", "\u0B86\u0B9F\u0BC8", "#FF5722", "3"},
            {"Beauty Parlour", "\u0B85\u0BB4\u0B95\u0BC1 \u0BA8\u0BBF\u0BB2\u0BC8\u0BAF\u0BAE\u0BCD", "#FF4081", "4"},
            {"Accessories", "\u0B85\u0BA3\u0BBF\u0B95\u0BB2\u0BA9\u0BCD", "#7C4DFF", "5"},
            {"Mehndi", "\u0BAE\u0BB0\u0BC1\u0BA4\u0BBE\u0BA3\u0BBF", "#4CAF50", "6"},
        };
        for (String[] cat : defaults) {
            WomensCornerCategory category = WomensCornerCategory.builder()
                    .name(cat[0])
                    .tamilName(cat[1])
                    .color(cat[2])
                    .displayOrder(Integer.parseInt(cat[3]))
                    .build();
            womensCornerCategoryRepository.save(category);
        }
        log.info("Initialized 6 default women's corner categories");
    }

    public static void main(String[] args) {
        SpringApplication.run(ShopManagementApplication.class, args);
    }
}