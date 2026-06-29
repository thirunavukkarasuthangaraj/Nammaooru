package com.shopmanagement.label.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LabelTemplateRequest {

    @NotBlank
    @Size(max = 150)
    private String name;

    private Long shopId;

    @NotNull
    @Positive
    private Double labelWidthMm;

    @NotNull
    @Positive
    private Double labelHeightMm;

    private Boolean isDefault;

    /** JSON design payload produced by the Angular designer. */
    private String design;
}
