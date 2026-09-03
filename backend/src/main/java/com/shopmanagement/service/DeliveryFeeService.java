package com.shopmanagement.service;

import com.shopmanagement.entity.DeliveryFeeRange;
import com.shopmanagement.repository.DeliveryFeeRangeRepository;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.repository.ShopRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class DeliveryFeeService {

    private final DeliveryFeeRangeRepository deliveryFeeRangeRepository;
    private final ShopRepository shopRepository;

    /**
     * A shop that delivers its own orders sets its own flat fee instead of the
     * platform's distance-based one — there's no delivery partner to pay a
     * commission to, so the platform rate doesn't apply.
     */
    public BigDecimal resolveDeliveryFee(Long shopId, Double distanceKm) {
        if (shopId != null) {
            Shop shop = shopRepository.findById(shopId).orElse(null);
            if (shop != null && Boolean.TRUE.equals(shop.getSelfDeliveryEnabled())
                    && shop.getSelfDeliveryFee() != null
                    && shop.getSelfDeliveryFee().compareTo(BigDecimal.ZERO) >= 0) {
                return shop.getSelfDeliveryFee();
            }
        }
        return calculateDeliveryFee(distanceKm);
    }

    public List<DeliveryFeeRange> getAllActiveRanges() {
        return deliveryFeeRangeRepository.findByIsActiveTrueOrderByMinDistanceKm();
    }

    public List<DeliveryFeeRange> getAllRanges() {
        return deliveryFeeRangeRepository.findAll();
    }

    public DeliveryFeeRange createRange(DeliveryFeeRange range) {
        return deliveryFeeRangeRepository.save(range);
    }

    public DeliveryFeeRange saveRange(DeliveryFeeRange range) {
        return deliveryFeeRangeRepository.save(range);
    }

    public DeliveryFeeRange updateRange(Long id, DeliveryFeeRange updatedRange) {
        DeliveryFeeRange existingRange = deliveryFeeRangeRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Delivery fee range not found: " + id));

        existingRange.setMinDistanceKm(updatedRange.getMinDistanceKm());
        existingRange.setMaxDistanceKm(updatedRange.getMaxDistanceKm());
        existingRange.setDeliveryFee(updatedRange.getDeliveryFee());
        existingRange.setPartnerCommission(updatedRange.getPartnerCommission());
        existingRange.setIsActive(updatedRange.getIsActive());

        return deliveryFeeRangeRepository.save(existingRange);
    }

    public void deleteRange(Long id) {
        deliveryFeeRangeRepository.deleteById(id);
    }

    public DeliveryFeeRange getRangeById(Long id) {
        return deliveryFeeRangeRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Delivery fee range not found: " + id));
    }

    public BigDecimal calculateDeliveryFee(Double distanceKm) {
        return deliveryFeeRangeRepository.findByDistanceRange(distanceKm)
            .map(DeliveryFeeRange::getDeliveryFee)
            .orElse(new BigDecimal("50.00")); // Default fallback
    }

    public BigDecimal calculatePartnerCommission(Double distanceKm) {
        return deliveryFeeRangeRepository.findByDistanceRange(distanceKm)
            .map(DeliveryFeeRange::getPartnerCommission)
            .orElse(new BigDecimal("35.00")); // Default fallback
    }

    public Double calculateDistance(Double lat1, Double lon1, Double lat2, Double lon2) {
        if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
            return 5.0; // Default 5km if coordinates missing
        }

        // Haversine formula for distance calculation
        double R = 6371; // Earth's radius in kilometers
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                Math.sin(dLon/2) * Math.sin(dLon/2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R * c;
    }
}