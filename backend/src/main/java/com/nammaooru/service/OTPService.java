package com.nammaooru.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class OTPService {

    private final RedisTemplate<String, String> redisTemplate;
    private final EmailService emailService;
    
    // In-memory storage as fallback (for testing without Redis)
    private final Map<String, OTPData> otpStorage = new ConcurrentHashMap<>();
    
    private static final int OTP_LENGTH = 6;
    private static final Duration OTP_VALIDITY = Duration.ofMinutes(10);
    private static final SecureRandom random = new SecureRandom();

    // Generate 6-digit OTP
    public String generateOTP() {
        int otp = 100000 + random.nextInt(900000);
        return String.valueOf(otp);
    }

    // Send OTP for authentication
    public boolean sendOTP(String email, String purpose) {
        try {
            String otp = generateOTP();
            String key = getOTPKey(email, purpose);
            
            // Store in Redis with expiry
            try {
                redisTemplate.opsForValue().set(key, otp, OTP_VALIDITY);
            } catch (Exception e) {
                // Fallback to in-memory storage
                log.warn("Redis not available, using in-memory storage");
                otpStorage.put(key, new OTPData(otp, System.currentTimeMillis()));
            }
            
            // Send email
            emailService.sendOTPEmail(email, otp, purpose);
            
            log.info("OTP sent to {} for {}", email, purpose);
            return true;
        } catch (Exception e) {
            log.error("Failed to send OTP to {}: ", email, e);
            return false;
        }
    }

    // Verify OTP
    public boolean verifyOTP(String email, String otp, String purpose) {
        try {
            String key = getOTPKey(email, purpose);
            String storedOTP = null;
            
            // Get from Redis
            try {
                storedOTP = redisTemplate.opsForValue().get(key);
            } catch (Exception e) {
                // Fallback to in-memory storage
                OTPData data = otpStorage.get(key);
                if (data != null && !data.isExpired()) {
                    storedOTP = data.getOtp();
                }
            }
            
            if (storedOTP != null && storedOTP.equals(otp)) {
                // Delete OTP after successful verification
                try {
                    redisTemplate.delete(key);
                } catch (Exception e) {
                    otpStorage.remove(key);
                }
                
                log.info("OTP verified successfully for {}", email);
                return true;
            }
            
            log.warn("Invalid OTP for {}", email);
            return false;
        } catch (Exception e) {
            log.error("Error verifying OTP for {}: ", email, e);
            return false;
        }
    }

    // Store order OTPs
    public void storeOrderOTPs(Long orderId, String shopOTP, String customerOTP) {
        try {
            String shopKey = "order:otp:shop:" + orderId;
            String customerKey = "order:otp:customer:" + orderId;
            
            try {
                redisTemplate.opsForValue().set(shopKey, shopOTP, Duration.ofHours(24));
                redisTemplate.opsForValue().set(customerKey, customerOTP, Duration.ofHours(24));
            } catch (Exception e) {
                // Fallback to in-memory
                otpStorage.put(shopKey, new OTPData(shopOTP, System.currentTimeMillis()));
                otpStorage.put(customerKey, new OTPData(customerOTP, System.currentTimeMillis()));
            }
            
            log.info("Order OTPs stored for order {}", orderId);
        } catch (Exception e) {
            log.error("Failed to store order OTPs for order {}: ", orderId, e);
        }
    }

    // Update shop OTP
    public void updateShopOTP(Long orderId, String shopOTP) {
        try {
            String key = "order:otp:shop:" + orderId;
            
            try {
                redisTemplate.opsForValue().set(key, shopOTP, Duration.ofHours(24));
            } catch (Exception e) {
                otpStorage.put(key, new OTPData(shopOTP, System.currentTimeMillis()));
            }
            
            log.info("Shop OTP updated for order {}", orderId);
        } catch (Exception e) {
            log.error("Failed to update shop OTP for order {}: ", orderId, e);
        }
    }

    // Verify shop OTP
    public boolean verifyShopOTP(Long orderId, String otp) {
        try {
            String key = "order:otp:shop:" + orderId;
            String storedOTP = null;
            
            try {
                storedOTP = redisTemplate.opsForValue().get(key);
            } catch (Exception e) {
                OTPData data = otpStorage.get(key);
                if (data != null && !data.isExpired()) {
                    storedOTP = data.getOtp();
                }
            }
            
            boolean valid = storedOTP != null && storedOTP.equals(otp);
            if (valid) {
                log.info("Shop OTP verified for order {}", orderId);
            } else {
                log.warn("Invalid shop OTP for order {}", orderId);
            }
            
            return valid;
        } catch (Exception e) {
            log.error("Error verifying shop OTP for order {}: ", orderId, e);
            return false;
        }
    }

    // Verify customer OTP
    public boolean verifyCustomerOTP(Long orderId, String otp) {
        try {
            String key = "order:otp:customer:" + orderId;
            String storedOTP = null;
            
            try {
                storedOTP = redisTemplate.opsForValue().get(key);
            } catch (Exception e) {
                OTPData data = otpStorage.get(key);
                if (data != null && !data.isExpired()) {
                    storedOTP = data.getOtp();
                }
            }
            
            boolean valid = storedOTP != null && storedOTP.equals(otp);
            if (valid) {
                log.info("Customer OTP verified for order {}", orderId);
                // Delete OTP after successful delivery
                try {
                    redisTemplate.delete(key);
                } catch (Exception e) {
                    otpStorage.remove(key);
                }
            } else {
                log.warn("Invalid customer OTP for order {}", orderId);
            }
            
            return valid;
        } catch (Exception e) {
            log.error("Error verifying customer OTP for order {}: ", orderId, e);
            return false;
        }
    }

    // Get order OTPs (for testing/admin)
    public Map<String, String> getOrderOTPs(Long orderId) {
        Map<String, String> otps = new HashMap<>();
        
        try {
            String shopKey = "order:otp:shop:" + orderId;
            String customerKey = "order:otp:customer:" + orderId;
            
            try {
                otps.put("shopOTP", redisTemplate.opsForValue().get(shopKey));
                otps.put("customerOTP", redisTemplate.opsForValue().get(customerKey));
            } catch (Exception e) {
                OTPData shopData = otpStorage.get(shopKey);
                OTPData customerData = otpStorage.get(customerKey);
                
                if (shopData != null && !shopData.isExpired()) {
                    otps.put("shopOTP", shopData.getOtp());
                }
                if (customerData != null && !customerData.isExpired()) {
                    otps.put("customerOTP", customerData.getOtp());
                }
            }
        } catch (Exception e) {
            log.error("Error getting order OTPs for order {}: ", orderId, e);
        }
        
        return otps;
    }

    // Clean expired OTPs from in-memory storage
    public void cleanExpiredOTPs() {
        otpStorage.entrySet().removeIf(entry -> entry.getValue().isExpired());
    }

    private String getOTPKey(String email, String purpose) {
        return String.format("otp:%s:%s", purpose.toLowerCase(), email.toLowerCase());
    }

    // Inner class for in-memory OTP storage
    @lombok.Data
    @lombok.AllArgsConstructor
    private static class OTPData {
        private String otp;
        private long timestamp;
        
        public boolean isExpired() {
            return System.currentTimeMillis() - timestamp > OTP_VALIDITY.toMillis();
        }
    }
}