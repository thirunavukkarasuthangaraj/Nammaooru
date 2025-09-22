package com.shopmanagement.dto.fcm;

public class FcmTokenRequest {
    private String fcmToken;
    private String deviceType; // android, ios, web
    private String deviceId;

    public FcmTokenRequest() {}

    public FcmTokenRequest(String fcmToken, String deviceType, String deviceId) {
        this.fcmToken = fcmToken;
        this.deviceType = deviceType;
        this.deviceId = deviceId;
    }

    // Getters and Setters
    public String getFcmToken() {
        return fcmToken;
    }

    public void setFcmToken(String fcmToken) {
        this.fcmToken = fcmToken;
    }

    public String getDeviceType() {
        return deviceType;
    }

    public void setDeviceType(String deviceType) {
        this.deviceType = deviceType;
    }

    public String getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(String deviceId) {
        this.deviceId = deviceId;
    }
}