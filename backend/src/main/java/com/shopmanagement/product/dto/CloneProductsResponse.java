package com.shopmanagement.product.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CloneProductsResponse {

    private int clonedCount;
    private int skippedCount;

    // e.g. "Amul Milk 500ml: already exists in target shop"
    private List<String> skippedReasons;
}
