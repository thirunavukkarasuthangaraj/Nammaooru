package com.shopmanagement.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.attribute.FileTime;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.stream.Stream;

/**
 * Deletes generated POS bill files (JPEG + PDF in uploads/bills) older than the
 * retention window. Every send/share writes a fresh uniquely-named file and
 * nothing else removes them, so without this the disk slowly fills up.
 * WhatsApp downloads its own copy at send time, so old files are not needed
 * for already-delivered messages.
 */
@Service
@Slf4j
public class BillFileCleanupService {

    @Value("${app.upload.dir:./uploads}")
    private String uploadDir;

    @Value("${app.bills.retention-days:10}")
    private int retentionDays;

    @Scheduled(cron = "0 0 3 * * *")
    public void cleanupOldBillFiles() {
        Path billsDir = Paths.get(uploadDir, "bills");
        if (!Files.isDirectory(billsDir)) {
            return;
        }

        Instant cutoff = Instant.now().minus(retentionDays, ChronoUnit.DAYS);
        int deleted = 0;
        long freedBytes = 0;

        try (Stream<Path> files = Files.list(billsDir)) {
            for (Path file : (Iterable<Path>) files::iterator) {
                try {
                    if (!Files.isRegularFile(file)) {
                        continue;
                    }
                    FileTime modified = Files.getLastModifiedTime(file);
                    if (modified.toInstant().isBefore(cutoff)) {
                        long size = Files.size(file);
                        Files.delete(file);
                        deleted++;
                        freedBytes += size;
                    }
                } catch (IOException e) {
                    log.warn("Bill cleanup: could not delete {}", file, e);
                }
            }
        } catch (IOException e) {
            log.error("Bill cleanup: failed to list {}", billsDir, e);
            return;
        }

        if (deleted > 0) {
            log.info("Bill cleanup: deleted {} file(s) older than {} days, freed {} MB",
                    deleted, retentionDays, freedBytes / (1024 * 1024));
        }
    }
}
