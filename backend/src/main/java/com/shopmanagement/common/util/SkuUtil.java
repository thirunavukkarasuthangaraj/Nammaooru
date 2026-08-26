package com.shopmanagement.common.util;

public final class SkuUtil {

    private SkuUtil() {
    }

    /**
     * Strip the internal "-COPY"/"-COPY-n" suffix that category-change clones
     * append to keep master_products.sku unique (the original product still owns
     * the plain code). Shop owners and customers should always see the original
     * product code, never the internal uniqueness suffix.
     */
    public static String displaySku(String sku) {
        if (sku == null) {
            return null;
        }
        return sku.replaceFirst("-COPY(-\\d+)?$", "");
    }
}
