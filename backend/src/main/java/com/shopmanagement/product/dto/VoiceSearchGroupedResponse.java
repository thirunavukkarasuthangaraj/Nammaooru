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
public class VoiceSearchGroupedResponse {
    private String keyword;
    private Integer count;
    private List<MasterProductResponse> products;
}
