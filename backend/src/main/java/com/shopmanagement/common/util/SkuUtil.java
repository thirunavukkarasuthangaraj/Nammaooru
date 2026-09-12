package com.shopmanagement.common.util;

public final class SkuUtil {

    private SkuUtil() {
    }

    /**
     * Strip every trailing "-COPY" / "-COPY-n" suffix (including stacked
     * values like "123-COPY-COPY") so the real barcode/SKU remains.
     */
    public static String displaySku(String sku) {
        if (sku == null) {
            return null;
        }
        return sku.replaceAll("(?i)(-COPY(-\\d+)?)+$", "");
    }
}
