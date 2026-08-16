package com.shopmanagement.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shopmanagement.shop.exception.ShopNotFoundException;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.repository.ShopRepository;
import com.shopmanagement.shop.service.ShopService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class BillSettingsService {
    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {};
    private final ShopRepository shopRepository;
    private final ShopService shopService;
    private final ObjectMapper objectMapper;

    @Transactional(readOnly = true)
    public Map<String, Object> getForCurrentUser(Long shopId) {
        Shop shop = requireAccessibleShop(shopId);
        return settingsFor(shop);
    }

    @Transactional
    public Map<String, Object> saveForCurrentUser(Long shopId, Map<String, Object> requested) {
        Shop shop = requireAccessibleShop(shopId);
        Map<String, Object> settings = sanitise(requested);
        try {
            shop.setBillSettingsJson(objectMapper.writeValueAsString(settings));
            shopRepository.save(shop);
            return settings;
        } catch (Exception e) {
            throw new IllegalArgumentException("Bill settings could not be saved", e);
        }
    }

    public Map<String, Object> settingsFor(Shop shop) {
        Map<String, Object> settings = defaults(shop);
        if (shop == null || shop.getBillSettingsJson() == null || shop.getBillSettingsJson().isBlank()) return settings;
        try {
            settings.putAll(objectMapper.readValue(shop.getBillSettingsJson(), MAP_TYPE));
        } catch (Exception e) {
            log.warn("Ignoring invalid bill settings for shop {}", shop.getId());
        }
        return sanitise(settings);
    }

    private Shop requireAccessibleShop(Long shopId) {
        Shop requested = shopRepository.findById(shopId)
                .orElseThrow(() -> new ShopNotFoundException("Shop not found"));
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) throw new AccessDeniedException("Authentication required");
        boolean admin = auth.getAuthorities().stream().anyMatch(a ->
                "ROLE_ADMIN".equals(a.getAuthority()) || "ROLE_SUPER_ADMIN".equals(a.getAuthority()));
        if (!admin) {
            Shop owned = shopService.getShopByOwner(auth.getName());
            if (owned == null || !owned.getId().equals(requested.getId())) {
                throw new AccessDeniedException("You cannot change another shop's bill settings");
            }
        }
        return requested;
    }

    private Map<String, Object> sanitise(Map<String, Object> input) {
        Map<String, Object> out = new LinkedHashMap<>();
        if (input != null) out.putAll(input);
        limit(out, "shopName", 255); limit(out, "shopPhone", 30); limit(out, "shopAddress", 500);
        limit(out, "gstNumber", 30); limit(out, "fssaiNumber", 30); limit(out, "fssaiName", 150);
        limit(out, "billNumberPrefix", 20); limit(out, "upiId", 100);
        limit(out, "thankYouMessage", 300); limit(out, "footerNote", 300);
        Object fields = out.get("customFields");
        if (fields instanceof List<?> list && list.size() > 6) out.put("customFields", list.subList(0, 6));
        return out;
    }

    private void limit(Map<String, Object> map, String key, int max) {
        Object value = map.get(key);
        if (value instanceof String text && text.length() > max) map.put(key, text.substring(0, max));
    }

    private Map<String, Object> defaults(Shop shop) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("identityVisibilityVersion", 1); m.put("shopName", shop == null ? "" : shop.getName());
        m.put("shopPhone", shop == null ? "" : shop.getOwnerPhone());
        m.put("shopAddress", shop == null ? "" : join(shop.getAddressLine1(), shop.getCity(), shop.getPostalCode()));
        m.put("gstNumber", shop == null ? "" : shop.getGstNumber());
        m.put("fssaiNumber", shop == null ? "" : shop.getFssaiCertificateNumber()); m.put("fssaiName", "");
        m.put("dateFormat", "DD/MM/YYYY"); m.put("billNumberPrefix", ""); m.put("showBillNumber", true);
        m.put("paperWidth", "80mm"); m.put("templateStyle", "current"); m.put("accentColor", "#43d77d");
        m.put("headerFontSize", 16); m.put("bodyFontSize", 12); m.put("footerFontSize", 10);
        for (String key : List.of("showShopName","showShopPhone","showDateTime","showCustomerDetails","showThankYouMessage",
                "showItemMrp","showSellingPrice","showSubtotal","showTotalSavings","showPaymentMethod","showEnglish","showTamil",
                "showAppDownloadLink","showOrderDetailsLink")) m.put(key, true);
        for (String key : List.of("showShopAddress","showGstNumber","showFssaiInfo","showItemSku","showItemBarcode","showItemTax",
                "showItemDiscount","showTaxBreakdown","showUpiQrCode","autoSendWhatsAppOnPrint","autoSendEmailOnPrint")) m.put(key, false);
        m.put("thankYouMessage", "Thank you for your order!"); m.put("footerNote", ""); m.put("separatorStyle", "dashed");
        m.put("upiId", shop == null ? "" : shop.getUpiId()); m.put("customFields", List.of());
        m.put("sectionOrder", List.of("header","billInfo","items","summary","payment","qrCode","footer"));
        return m;
    }

    private String join(String... values) {
        return java.util.Arrays.stream(values).filter(v -> v != null && !v.isBlank()).reduce((a,b) -> a + ", " + b).orElse("");
    }
}
