package com.shopmanagement.product.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CloneProductsRequest {

    @NotNull(message = "Source shop id is required")
    private Long sourceShopId;

    // If true, clone every product currently in the source shop and ignore
    // shopProductIds. Otherwise shopProductIds must be provided.
    private boolean cloneAll;

    private List<Long> shopProductIds;
}
