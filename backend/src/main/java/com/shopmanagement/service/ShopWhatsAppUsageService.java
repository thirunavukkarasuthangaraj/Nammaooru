package com.shopmanagement.service;

import com.shopmanagement.entity.ShopWhatsAppUsage;
import com.shopmanagement.repository.ShopWhatsAppUsageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Records WhatsApp messages sent on behalf of shops so they can be charged
 * on the next pay-and-use payment. Recording must never break the send path.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ShopWhatsAppUsageService {

    public static final String TYPE_BILL = "bill";
    public static final String TYPE_MARKETING = "marketing";

    private final ShopWhatsAppUsageRepository usageRepository;

    public void record(Long shopId, String messageType) {
        if (shopId == null) return;
        try {
            usageRepository.save(ShopWhatsAppUsage.builder()
                    .shopId(shopId)
                    .messageType(messageType)
                    .build());
        } catch (Exception e) {
            log.error("Failed to record WhatsApp usage for shop {} ({})", shopId, messageType, e);
        }
    }
}
