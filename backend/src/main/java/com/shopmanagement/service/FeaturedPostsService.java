package com.shopmanagement.service;

import com.shopmanagement.entity.*;
import com.shopmanagement.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
@RequiredArgsConstructor
public class FeaturedPostsService {

    private final MarketplacePostRepository marketplacePostRepository;
    private final FarmerProductRepository farmerProductRepository;
    private final LabourPostRepository labourPostRepository;
    private final TravelPostRepository travelPostRepository;
    private final ParcelServicePostRepository parcelServicePostRepository;
    private final RealEstatePostRepository realEstatePostRepository;

    public Map<String, Object> getFeaturedPosts() {
        Map<String, Object> result = new LinkedHashMap<>();
        Pageable top2 = PageRequest.of(0, 2);

        // Marketplace - 2 recent approved posts
        try {
            var mpPosts = marketplacePostRepository.findByStatusOrderByCreatedAtDesc(
                    MarketplacePost.PostStatus.APPROVED, top2).getContent();
            result.put("marketplace", mpPosts.stream().map(this::mapMarketplace).toList());
        } catch (Exception e) {
            result.put("marketplace", List.of());
        }

        // Farmer Products - 2 recent approved
        try {
            var fpPosts = farmerProductRepository.findByStatusOrderByCreatedAtDesc(
                    FarmerProduct.PostStatus.APPROVED, top2).getContent();
            result.put("farmer", fpPosts.stream().map(this::mapFarmer).toList());
        } catch (Exception e) {
            result.put("farmer", List.of());
        }

        // Labour - 2 recent approved
        try {
            var lbPosts = labourPostRepository.findByStatusOrderByCreatedAtDesc(
                    LabourPost.PostStatus.APPROVED, top2).getContent();
            result.put("labour", lbPosts.stream().map(this::mapLabour).toList());
        } catch (Exception e) {
            result.put("labour", List.of());
        }

        // Travel - 2 recent approved
        try {
            var tvPosts = travelPostRepository.findByStatusOrderByCreatedAtDesc(
                    TravelPost.PostStatus.APPROVED, top2).getContent();
            result.put("travel", tvPosts.stream().map(this::mapTravel).toList());
        } catch (Exception e) {
            result.put("travel", List.of());
        }

        // Parcel - 2 recent approved
        try {
            var pcPosts = parcelServicePostRepository.findByStatusOrderByCreatedAtDesc(
                    ParcelServicePost.PostStatus.APPROVED, top2).getContent();
            result.put("parcel", pcPosts.stream().map(this::mapParcel).toList());
        } catch (Exception e) {
            result.put("parcel", List.of());
        }

        // Real Estate - 2 recent approved
        try {
            var rePosts = realEstatePostRepository.findByStatusOrderByCreatedAtDesc(
                    RealEstatePost.PostStatus.APPROVED, top2).getContent();
            result.put("realEstate", rePosts.stream().map(this::mapRealEstate).toList());
        } catch (Exception e) {
            result.put("realEstate", List.of());
        }

        return result;
    }

    private Map<String, Object> mapMarketplace(MarketplacePost p) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", p.getId());
        m.put("title", p.getTitle());
        m.put("description", p.getDescription());
        m.put("imageUrl", p.getImageUrl());
        m.put("price", p.getPrice());
        m.put("category", p.getCategory());
        m.put("location", p.getLocation());
        m.put("sellerName", p.getSellerName());
        return m;
    }

    private Map<String, Object> mapFarmer(FarmerProduct p) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", p.getId());
        m.put("title", p.getTitle());
        m.put("description", p.getDescription());
        m.put("imageUrls", p.getImageUrls());
        m.put("price", p.getPrice());
        m.put("unit", p.getUnit());
        m.put("category", p.getCategory());
        m.put("location", p.getLocation());
        m.put("sellerName", p.getSellerName());
        return m;
    }

    private Map<String, Object> mapLabour(LabourPost p) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", p.getId());
        m.put("name", p.getName());
        m.put("description", p.getDescription());
        m.put("imageUrls", p.getImageUrls());
        m.put("category", p.getCategory() != null ? p.getCategory().name() : null);
        m.put("location", p.getLocation());
        m.put("experience", p.getExperience());
        m.put("sellerName", p.getSellerName());
        return m;
    }

    private Map<String, Object> mapTravel(TravelPost p) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", p.getId());
        m.put("title", p.getTitle());
        m.put("description", p.getDescription());
        m.put("imageUrls", p.getImageUrls());
        m.put("vehicleType", p.getVehicleType() != null ? p.getVehicleType().name() : null);
        m.put("fromLocation", p.getFromLocation());
        m.put("toLocation", p.getToLocation());
        m.put("price", p.getPrice());
        m.put("sellerName", p.getSellerName());
        return m;
    }

    private Map<String, Object> mapParcel(ParcelServicePost p) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", p.getId());
        m.put("serviceName", p.getServiceName());
        m.put("description", p.getDescription());
        m.put("imageUrls", p.getImageUrls());
        m.put("serviceType", p.getServiceType() != null ? p.getServiceType().name() : null);
        m.put("fromLocation", p.getFromLocation());
        m.put("toLocation", p.getToLocation());
        m.put("priceInfo", p.getPriceInfo());
        m.put("sellerName", p.getSellerName());
        return m;
    }

    private Map<String, Object> mapRealEstate(RealEstatePost p) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", p.getId());
        m.put("title", p.getTitle());
        m.put("description", p.getDescription());
        m.put("imageUrls", p.getImageUrls());
        m.put("propertyType", p.getPropertyType() != null ? p.getPropertyType().name() : null);
        m.put("listingType", p.getListingType() != null ? p.getListingType().name() : null);
        m.put("price", p.getPrice());
        m.put("location", p.getLocation());
        m.put("ownerName", p.getOwnerName());
        return m;
    }
}
