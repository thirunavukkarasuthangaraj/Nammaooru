package com.shopmanagement.config;

import org.springframework.boot.autoconfigure.flyway.FlywayMigrationStrategy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Configuration
public class FlywayConfig {

    private static final Logger log = LoggerFactory.getLogger(FlywayConfig.class);

    /**
     * A migration that fails partway leaves a "failed" row in
     * flyway_schema_history - Flyway then refuses to run ANY further
     * migrations (including later, unrelated, already-fixed ones) until that
     * row is cleared. That blocked every deploy after V115 first failed
     * (2026-09-11), even once V115 itself was corrected, because the stale
     * failed record was still sitting in history. repair() removes failed
     * entries and realigns checksums before migrate() runs, so a bad
     * migration can be fixed forward by editing/replacing its file and
     * redeploying, without needing manual SSH/psql access to the database.
     */
    @Bean
    public FlywayMigrationStrategy repairBeforeMigrateStrategy() {
        return flyway -> {
            log.info("Running Flyway repair (clears any stuck failed-migration record) before migrate");
            flyway.repair();
            flyway.migrate();
        };
    }
}
