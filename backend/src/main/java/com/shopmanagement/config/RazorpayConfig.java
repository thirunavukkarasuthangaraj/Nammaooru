package com.shopmanagement.config;

import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@Slf4j
@Getter
public class RazorpayConfig {

    @Value("${razorpay.mode:test}")
    private String mode;

    @Value("${razorpay.test.key-id:}")
    private String testKeyId;

    @Value("${razorpay.test.key-secret:}")
    private String testKeySecret;

    @Value("${razorpay.live.key-id:}")
    private String liveKeyId;

    @Value("${razorpay.live.key-secret:}")
    private String liveKeySecret;

    public String getActiveKeyId() {
        return "live".equalsIgnoreCase(mode) ? liveKeyId : testKeyId;
    }

    public String getActiveKeySecret() {
        return "live".equalsIgnoreCase(mode) ? liveKeySecret : testKeySecret;
    }

    public boolean isTestMode() {
        return !"live".equalsIgnoreCase(mode);
    }

    @Bean
    public RazorpayClient razorpayClient() throws RazorpayException {
        String keyId = getActiveKeyId();
        String keySecret = getActiveKeySecret();

        if (keyId == null || keyId.isEmpty() || keySecret == null || keySecret.isEmpty()) {
            log.warn("Razorpay {} credentials not configured. Payment features will not work.", mode);
            return null;
        }

        log.info("Razorpay initialized in {} mode", mode.toUpperCase());
        return new RazorpayClient(keyId, keySecret);
    }
}
