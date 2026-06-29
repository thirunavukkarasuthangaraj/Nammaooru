package com.shopmanagement.label.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LabelTemplateResponse {

    private Long id;
    private String name;
    private Long shopId;
    private Double labelWidthMm;
    private Double labelHeightMm;
    private Boolean isDefault;
    private String design;
    private String createdBy;
    private String updatedBy;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
