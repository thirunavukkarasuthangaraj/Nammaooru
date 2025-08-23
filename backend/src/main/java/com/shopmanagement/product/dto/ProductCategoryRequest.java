package com.shopmanagement.product.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductCategoryRequest {

    @NotBlank(message = "Category name is required")
    @Size(max = 100, message = "Category name must be less than 100 characters")
    private String name;

    @Size(max = 500, message = "Description must be less than 500 characters")
    private String description;

    @Size(max = 100, message = "Slug must be less than 100 characters")
    private String slug;

    private Long parentId;

    @Builder.Default
    private Boolean isActive = true;

    private Integer sortOrder;

    @Size(max = 255, message = "Icon URL must be less than 255 characters")
    private String iconUrl;
}