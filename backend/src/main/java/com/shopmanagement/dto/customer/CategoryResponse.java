package com.shopmanagement.dto.customer;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CategoryResponse {
    private String id;
    private String name;
    private String displayName; // For Tamil/English combined names
    private String description;
    private int productCount;
    private String icon;
    private String color;
    private String imageUrl; // Category image URL
}