package com.shopmanagement.marketing.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for marketing message requests
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MarketingMessageRequest {

    /**
     * Template name - must be one of the approved templates in MSG91
     * Valid values: "test", "marketingmsg"
     */
    @NotBlank(message = "Template name is required")
    @Pattern(regexp = "^(test|marketingmsg)$", message = "Template must be 'test' or 'marketingmsg'")
    private String templateName;

    /**
     * Message parameter to replace {{1}} placeholder in the template
     */
    @NotBlank(message = "Message parameter is required")
    private String messageParam;

    /**
     * Second message parameter to replace {{2}} placeholder (optional, used by some templates)
     */
    private String messageParam2;

    /**
     * Image URL for templates with image headers (optional, used by marketingmsg template)
     */
    private String imageUrl;

    /**
     * Target audience for the marketing message
     * Valid values: "ALL_CUSTOMERS" or comma-separated customer IDs
     */
    @NotBlank(message = "Target audience is required")
    private String targetAudience;
}
