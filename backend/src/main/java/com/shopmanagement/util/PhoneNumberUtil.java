package com.shopmanagement.util;

import java.util.regex.Pattern;

public class PhoneNumberUtil {

    private static final Pattern INDIAN_MOBILE_PATTERN = Pattern.compile("^[6-9]\\d{9}$");
    private static final Pattern INTERNATIONAL_PATTERN = Pattern.compile("^\\+91[6-9]\\d{9}$");

    /**
     * Normalize Indian mobile number to 10-digit format
     */
    public static String normalize(String phoneNumber) {
        if (phoneNumber == null || phoneNumber.trim().isEmpty()) {
            throw new IllegalArgumentException("Phone number cannot be null or empty");
        }

        // Remove all non-digit characters
        String digits = phoneNumber.replaceAll("\\D", "");

        // Handle different formats
        if (digits.startsWith("91") && digits.length() == 12) {
            // Remove country code
            digits = digits.substring(2);
        } else if (digits.startsWith("0") && digits.length() == 11) {
            // Remove leading zero
            digits = digits.substring(1);
        }

        // Validate final format
        if (!INDIAN_MOBILE_PATTERN.matcher(digits).matches()) {
            throw new IllegalArgumentException("Invalid Indian mobile number format: " + phoneNumber);
        }

        return digits;
    }

    /**
     * Format phone number for display
     */
    public static String formatForDisplay(String phoneNumber) {
        String normalized = normalize(phoneNumber);
        return "+91 " + normalized.substring(0, 5) + " " + normalized.substring(5);
    }

    /**
     * Validate Indian mobile number
     */
    public static boolean isValid(String phoneNumber) {
        try {
            normalize(phoneNumber);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Convert to international format
     */
    public static String toInternationalFormat(String phoneNumber) {
        return "+91" + normalize(phoneNumber);
    }

    /**
     * Mask phone number for security (show only last 4 digits)
     */
    public static String mask(String phoneNumber) {
        try {
            String normalized = normalize(phoneNumber);
            return "XXXXXX" + normalized.substring(6);
        } catch (Exception e) {
            return "XXXXXXXXXX";
        }
    }
}