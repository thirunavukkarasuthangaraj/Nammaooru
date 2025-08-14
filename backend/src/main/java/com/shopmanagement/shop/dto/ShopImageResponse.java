package com.shopmanagement.shop.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ShopImageResponse {

    private Long id;
    private String imageUrl;
    private String imageType;
    private Boolean isPrimary;
    private LocalDateTime createdAt;
}