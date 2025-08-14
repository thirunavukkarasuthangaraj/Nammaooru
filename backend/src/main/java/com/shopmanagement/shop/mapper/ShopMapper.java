package com.shopmanagement.shop.mapper;

import com.shopmanagement.shop.dto.ShopCreateRequest;
import com.shopmanagement.shop.dto.ShopDocumentResponse;
import com.shopmanagement.shop.dto.ShopImageResponse;
import com.shopmanagement.shop.dto.ShopResponse;
import com.shopmanagement.shop.dto.ShopUpdateRequest;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.entity.ShopDocument;
import com.shopmanagement.shop.entity.ShopImage;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

import java.util.List;
import java.util.Set;

@Mapper(componentModel = "spring", nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
public interface ShopMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "shopId", ignore = true)
    @Mapping(target = "slug", ignore = true)
    @Mapping(target = "status", ignore = true)
    @Mapping(target = "isActive", ignore = true)
    @Mapping(target = "isVerified", ignore = true)
    @Mapping(target = "isFeatured", ignore = true)
    @Mapping(target = "rating", ignore = true)
    @Mapping(target = "totalOrders", ignore = true)
    @Mapping(target = "totalRevenue", ignore = true)
    @Mapping(target = "createdBy", ignore = true)
    @Mapping(target = "updatedBy", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "images", ignore = true)
    @Mapping(target = "documents", ignore = true)
    @Mapping(source = "businessType", target = "businessType")
    Shop toEntity(ShopCreateRequest request);

    @Mapping(source = "businessType", target = "businessType")
    @Mapping(source = "status", target = "status")
    @Mapping(source = "images", target = "images")
    @Mapping(source = "documents", target = "documents")
    ShopResponse toResponse(Shop shop);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "shopId", ignore = true)
    @Mapping(target = "slug", ignore = true)
    @Mapping(target = "createdBy", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "images", ignore = true)
    @Mapping(target = "documents", ignore = true)
    @Mapping(target = "rating", ignore = true)
    @Mapping(target = "totalOrders", ignore = true)
    @Mapping(target = "totalRevenue", ignore = true)
    @Mapping(target = "updatedBy", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(source = "businessType", target = "businessType")
    @Mapping(source = "status", target = "status")
    void updateEntityFromRequest(ShopUpdateRequest request, @MappingTarget Shop shop);

    ShopImageResponse toImageResponse(ShopImage shopImage);

    List<ShopImageResponse> toImageResponseList(List<ShopImage> shopImages);

    List<ShopImageResponse> toImageResponseSet(Set<ShopImage> shopImages);

    ShopDocumentResponse toDocumentResponse(ShopDocument shopDocument);

    List<ShopDocumentResponse> toDocumentResponseList(List<ShopDocument> shopDocuments);

    List<ShopDocumentResponse> toDocumentResponseSet(Set<ShopDocument> shopDocuments);

    default Shop.BusinessType mapBusinessType(String businessType) {
        return businessType != null ? Shop.BusinessType.valueOf(businessType) : null;
    }

    default String mapBusinessType(Shop.BusinessType businessType) {
        return businessType != null ? businessType.name() : null;
    }

    default Shop.ShopStatus mapShopStatus(String status) {
        return status != null ? Shop.ShopStatus.valueOf(status) : null;
    }

    default String mapShopStatus(Shop.ShopStatus status) {
        return status != null ? status.name() : null;
    }
}