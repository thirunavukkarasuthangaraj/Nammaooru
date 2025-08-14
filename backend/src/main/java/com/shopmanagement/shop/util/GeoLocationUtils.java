package com.shopmanagement.shop.util;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;

@Component
public class GeoLocationUtils {

    private static final double EARTH_RADIUS_KM = 6371.0;

    public double calculateDistance(BigDecimal lat1, BigDecimal lon1, BigDecimal lat2, BigDecimal lon2) {
        if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
            return Double.MAX_VALUE;
        }
        
        double dLat = Math.toRadians(lat2.doubleValue() - lat1.doubleValue());
        double dLon = Math.toRadians(lon2.doubleValue() - lon1.doubleValue());
        
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                   Math.cos(Math.toRadians(lat1.doubleValue())) *
                   Math.cos(Math.toRadians(lat2.doubleValue())) *
                   Math.sin(dLon / 2) * Math.sin(dLon / 2);
        
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        
        return EARTH_RADIUS_KM * c;
    }

    public boolean isWithinRadius(BigDecimal lat1, BigDecimal lon1, BigDecimal lat2, BigDecimal lon2, double radiusKm) {
        double distance = calculateDistance(lat1, lon1, lat2, lon2);
        return distance <= radiusKm;
    }

    public double kmToMiles(double km) {
        return km * 0.621371;
    }

    public double milesToKm(double miles) {
        return miles * 1.60934;
    }
}