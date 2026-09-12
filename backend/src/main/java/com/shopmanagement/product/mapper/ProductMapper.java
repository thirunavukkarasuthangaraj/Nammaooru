package com.shopmanagement.product.mapper;

import com.shopmanagement.product.dto.*;
import com.shopmanagement.product.entity.*;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

import java.util.List;

@Mapper(componentModel = "spring", nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
public interface ProductMapper {

    // Master Product Mappings
    @Mapping(target = "primaryImageUrl", expression = "java(product.getPrimaryImageUrl())")
    @Mapping(target = "shopCount", ignore = true)
    @Mapping(target = "minPrice", ignore = true)
    @Mapping(target = "maxPrice", ignore = true)
    MasterProductResponse toResponse(MasterProduct product);

    List<MasterProductResponse> toMasterProductResponses(List<MasterProduct> products);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "images", ignore = true)
    @Mapping(target = "shopProducts", ignore = true)
    @Mapping(target = "category", ignore = true)
    MasterProduct toEntity(MasterProductRequest request);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "images", ignore = true)
    @Mapping(target = "shopProducts", ignore = true)
    @Mapping(target = "category", ignore = true)
    void updateEntity(MasterProductRequest request, @MappingTarget MasterProduct product);

    // Shop Product Mappings
    @Mapping(source = "shop.id", target = "shopId")
    @Mapping(source = "shop.name", target = "shopName")
    @Mapping(target = "displayName", expression = "java(shopProduct.getDisplayName())")
    @Mapping(target = "displayNameTamil", expression = "java(getDisplayNameTamil(shopProduct))")
    @Mapping(target = "nameTamil", expression = "java(getNameTamil(shopProduct))")
    @Mapping(target = "sku", expression = "java(getSku(shopProduct))")
    @Mapping(target = "barcode", expression = "java(getBarcode(shopProduct))")
    @Mapping(target = "tags", expression = "java(getTags(shopProduct))")
    @Mapping(target = "displayDescription", expression = "java(shopProduct.getDisplayDescription())")
    @Mapping(target = "primaryImageUrl", expression = "java(shopProduct.getPrimaryShopImageUrl())")
    @Mapping(target = "inStock", expression = "java(shopProduct.isInStock())")
    @Mapping(target = "lowStock", expression = "java(shopProduct.isLowStock())")
    @Mapping(target = "discountAmount", expression = "java(shopProduct.getDiscountAmount())")
    @Mapping(target = "discountPercentage", expression = "java(shopProduct.getDiscountPercentage())")
    @Mapping(target = "profitMargin", expression = "java(calculateProfitMargin(shopProduct))")
    ShopProductResponse toResponse(ShopProduct shopProduct);

    List<ShopProductResponse> toShopProductResponses(List<ShopProduct> shopProducts);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "shop", ignore = true)
    @Mapping(target = "masterProduct", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "shopImages", ignore = true)
    ShopProduct toEntity(ShopProductRequest request);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "shop", ignore = true)
    @Mapping(target = "masterProduct", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "shopImages", ignore = true)
    void updateEntity(ShopProductRequest request, @MappingTarget ShopProduct shopProduct);

    // Product Category Mappings
    @Mapping(source = "parent.id", target = "parentId")
    @Mapping(source = "parent.name", target = "parentName")
    @Mapping(target = "fullPath", expression = "java(category.getFullPath())")
    @Mapping(target = "hasSubcategories", expression = "java(category.hasSubcategories())")
    @Mapping(target = "isRootCategory", expression = "java(category.isRootCategory())")
    @Mapping(target = "productCount", expression = "java((long)category.getProducts().size())")
    @Mapping(target = "subcategoryCount", expression = "java((long)category.getSubcategories().size())")
    ProductCategoryResponse toResponse(ProductCategory category);

    List<ProductCategoryResponse> toCategoryResponses(List<ProductCategory> categories);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "parent", ignore = true)
    @Mapping(target = "subcategories", ignore = true)
    @Mapping(target = "products", ignore = true)
    ProductCategory toEntity(ProductCategoryRequest request);

    // Product Image Mappings
    @Mapping(target = "imageType", expression = "java(\"MASTER\")")
    @Mapping(source = "masterProduct.id", target = "productId")
    ProductImageResponse toResponse(MasterProductImage image);

    @Mapping(target = "imageType", expression = "java(\"SHOP\")")
    @Mapping(source = "shopProduct.id", target = "productId")
    ProductImageResponse toResponse(ShopProductImage image);

    List<ProductImageResponse> toImageResponses(List<MasterProductImage> images);

    // Helper methods
    default java.math.BigDecimal calculateProfitMargin(ShopProduct shopProduct) {
        if (shopProduct.getCostPrice() == null || shopProduct.getPrice() == null ||
            shopProduct.getCostPrice().compareTo(java.math.BigDecimal.ZERO) == 0) {
            return java.math.BigDecimal.ZERO;
        }
        return shopProduct.getPrice()
                .subtract(shopProduct.getCostPrice())
                .multiply(java.math.BigDecimal.valueOf(100))
                .divide(shopProduct.getCostPrice(), 2, java.math.BigDecimal.ROUND_HALF_UP);
    }

    /**
     * Get Tamil display name - custom Tamil name if set, otherwise master product Tamil name
     */
    default String getDisplayNameTamil(ShopProduct shopProduct) {
        if (shopProduct == null) return null;
        // For now, only master product has Tamil name
        // In future, shops can have customNameTamil
        if (shopProduct.getMasterProduct() != null) {
            return shopProduct.getMasterProduct().getNameTamil();
        }
        return null;
    }

    /**
     * Get Tamil name - convenience method that returns master product Tamil name
     */
    default String getNameTamil(ShopProduct shopProduct) {
        if (shopProduct == null) return null;
        if (shopProduct.getMasterProduct() != null) {
            return shopProduct.getMasterProduct().getNameTamil();
        }
        return null;
    }

    /**
     * Get SKU - convenience method that returns master product SKU
     */
    default String getSku(ShopProduct shopProduct) {
        if (shopProduct == null) return null;
        if (shopProduct.getMasterProduct() != null) {
            return shopProduct.getMasterProduct().getSku();
        }
        return null;
    }

    /**
     * Get barcode - convenience method that returns master product barcode
     */
    default String getBarcode(ShopProduct shopProduct) {
        if (shopProduct == null) return null;
        if (shopProduct.getMasterProduct() != null) {
            return shopProduct.getMasterProduct().getBarcode();
        }
        return null;
    }

    /**
     * Get tags - shop product tags if set, otherwise master product tags
     */
    default String getTags(ShopProduct shopProduct) {
        if (shopProduct == null) return null;
        // First check shop product tags
        if (shopProduct.getTags() != null && !shopProduct.getTags().isEmpty()) {
            return shopProduct.getTags();
        }
        // Fallback to master product tags
        if (shopProduct.getMasterProduct() != null) {
            return shopProduct.getMasterProduct().getTags();
        }
        return null;
    }
}