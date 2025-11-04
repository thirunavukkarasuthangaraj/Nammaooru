package com.shopmanagement.product.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BulkImportResponse {

    private int totalRows;
    private int successCount;
    private int failureCount;
    private List<ImportResult> results;
    private String message;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ImportResult {
        private Integer rowNumber;
        private String productName;
        private String status; // SUCCESS, FAILED, SKIPPED
        private String message;
        private Long productId;
        private String imageUploadStatus;
    }

    public void addResult(ImportResult result) {
        if (this.results == null) {
            this.results = new ArrayList<>();
        }
        this.results.add(result);
    }
}
