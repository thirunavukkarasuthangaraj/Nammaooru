package com.shopmanagement.marketing.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for template information
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TemplateInfo {

    private String templateName;
    private String displayName;
    private String description;
    private String parameterDescription;
}
