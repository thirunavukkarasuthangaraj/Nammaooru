package com.shopmanagement;

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
    }

    public static void main(String[] args) {
        SpringApplication.run(ShopManagementApplication.class, args);
    }
}