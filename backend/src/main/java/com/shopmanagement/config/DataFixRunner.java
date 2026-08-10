package com.shopmanagement.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Idempotent data/schema fixes that Flyway cannot apply on this database:
 * the schema history contains a date-style version (V20240109...), so
 * number-style migrations like V81/V82 are treated as out-of-order and
 * skipped. Hibernate ddl-auto creates missing columns but can neither
 * drop NOT NULL constraints nor run data updates. Each statement here is
 * safe to run on every startup.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DataFixRunner implements ApplicationRunner {

    private final JdbcTemplate jdbcTemplate;

    @Override
    public void run(ApplicationArguments args) {
        // V81: POS custom items have no catalog product
        try {
            jdbcTemplate.execute("ALTER TABLE order_items ALTER COLUMN shop_product_id DROP NOT NULL");
            log.info("DataFix: order_items.shop_product_id is nullable");
        } catch (Exception e) {
            log.warn("DataFix: could not relax order_items.shop_product_id: {}", e.getMessage());
        }

        // V82: bulk-imported categories belong to the importing shop owner,
        // not the BULK_IMPORT placeholder (fixes visibility + edit ownership)
        try {
            int updated = jdbcTemplate.update(
                    "UPDATE product_categories SET created_by = 'murugesan_79998', updated_by = 'murugesan_79998' " +
                    "WHERE created_by = 'BULK_IMPORT'");
            if (updated > 0) {
                log.info("DataFix: re-attributed {} BULK_IMPORT categories to murugesan_79998", updated);
            }
        } catch (Exception e) {
            log.warn("DataFix: could not re-attribute BULK_IMPORT categories: {}", e.getMessage());
        }
    }
}
