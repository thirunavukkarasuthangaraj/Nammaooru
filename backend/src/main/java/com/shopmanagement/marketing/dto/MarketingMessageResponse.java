package com.shopmanagement.marketing.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for marketing message response with statistics
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MarketingMessageResponse {

    private boolean success;
    private String message;
    private int totalCustomers;
    private int successCount;
    private int failureCount;
    private String templateUsed;
    private String messageParam;
}
