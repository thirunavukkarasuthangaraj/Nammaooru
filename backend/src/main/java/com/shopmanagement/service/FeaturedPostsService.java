package com.shopmanagement.service;

import com.shopmanagement.entity.*;
import com.shopmanagement.repository.*;
import com.shopmanagement.shop.entity.Shop;
import com.shopmanagement.shop.repository.ShopRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
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
    private final ProductComboRepository productComboRepository;
    private final PromotionRepository promotionRepository;
    private final ShopRepository shopRepository;

    public Map<String, Object> getFeaturedPosts(Double lat, Double lng, Double radiusKm) {
        Map<String, Object> result = new LinkedHashMap<>();
        Pageable top10 = PageRequest.of(0, 10);
        boolean hasLocation = lat != null && lng != null;
        double radius = radiusKm != null ? radiusKm : 50.0;

        // Combos - active combos from all shops
        try {
            var combos = productComboRepository.findAllActiveCombos(LocalDate.now());
            var limitedCombos = combos.size() > 6 ? combos.subList(0, 6) : combos;
            result.put("combos", limitedCombos.stream().map(this::mapCombo).toList());
        } catch (Exception e) {
            result.put("combos", List.of());
        }

        // Shop Promotions/Offers - active public promotions
        try {
            var promos = promotionRepository.findAllPublicActive(LocalDateTime.now());
            var limitedPromos = promos.size() > 10 ? promos.subList(0, 10) : promos;
            result.put("promotions", limitedPromos.stream().map(this::mapPromotion).toList());
        } catch (Exception e) {
            result.put("promotions", List.of());
        }

        // Only PAID posts show in the banner (isPaid=true), ordered by date (newest first)
        // If lat/lng provided, filter by distance (posts without location are always included)
        String[] approvedStatus = new String[]{"APPROVED"};

        // Marketplace - paid approved posts, nearby if location provided
        try {
            if (hasLocation) {
                var mpPosts = marketplacePostRepository.findNearbyPosts(approvedStatus, lat, lng, radius, 10, 0);
                result.put("marketplace", mpPosts.stream()
                        .filter(p -> Boolean.TRUE.equals(p.getIsPaid()))
                        .map(this::mapMarketplace).toList());
            } else {
                var mpPosts = marketplacePostRepository.findByStatusAndIsPaidTrueOrderByCreatedAtDesc(
                        MarketplacePost.PostStatus.APPROVED, top10).getContent();
                result.put("marketplace", mpPosts.stream().map(this::mapMarketplace).toList());
            }
        } catch (Exception e) {
            result.put("marketplace", List.of());
        }

        // Farmer Products - paid approved, nearby if location provided
        try {
            if (hasLocation) {
                var fpPosts = farmerProductRepository.findNearbyPosts(approvedStatus, lat, lng, radius, 10, 0);
                result.put("farmer", fpPosts.stream()
                        .filter(p -> Boolean.TRUE.equals(p.getIsPaid()))
                        .map(this::mapFarmer).toList());
            } else {
                var fpPosts = farmerProductRepository.findByStatusAndIsPaidTrueOrderByCreatedAtDesc(
                        FarmerProduct.PostStatus.APPROVED, top10).getContent();
                result.put("farmer", fpPosts.stream().map(this::mapFarmer).toList());
            }
        } catch (Exception e) {
            result.put("farmer", List.of());
        }

        // Labour - paid approved, nearby if location provided
        try {
            if (hasLocation) {
                var lbPosts = labourPostRepository.findNearbyPosts(approvedStatus, lat, lng, radius, 10, 0);
                result.put("labour", lbPosts.stream()
                        .filter(p -> Boolean.TRUE.equals(p.getIsPaid()))
                        .map(this::mapLabour).toList());
            } else {
                var lbPosts = labourPostRepository.findByStatusAndIsPaidTrueOrderByCreatedAtDesc(
                        LabourPost.PostStatus.APPROVED, top10).getContent();
                result.put("labour", lbPosts.stream().map(this::mapLabour).toList());
            }
        } catch (Exception e) {
            result.put("labour", List.of());
        }

        // Travel - paid approved, nearby if location provided
        try {
            if (hasLocation) {
                var tvPosts = travelPostRepository.findNearbyPosts(approvedStatus, lat, lng, radius, 10, 0);
                result.put("travel", tvPosts.stream()
                        .filter(p -> Boolean.TRUE.equals(p.getIsPaid()))
                        .map(this::mapTravel).toList());
            } else {
                var tvPosts = travelPostRepository.findByStatusAndIsPaidTrueOrderByCreatedAtDesc(
                        TravelPost.PostStatus.APPROVED, top10).getContent();
                result.put("travel", tvPosts.stream().map(this::mapTravel).toList());
            }
        } catch (Exception e) {
            result.put("travel", List.of());
        }

        // Parcel - paid approved, nearby if location provided
        try {
            if (hasLocation) {
                var pcPosts = parcelServicePostRepository.findNearbyPosts(approvedStatus, lat, lng, radius, 10, 0);
                result.put("parcel", pcPosts.stream()
                        .filter(p -> Boolean.TRUE.equals(p.getIsPaid()))
                        .map(this::mapParcel).toList());
            } else {
                var pcPosts = parcelServicePostRepository.findByStatusAndIsPaidTrueOrderByCreatedAtDesc(
                        ParcelServicePost.PostStatus.APPROVED, top10).getContent();
                result.put("parcel", pcPosts.stream().map(this::mapParcel).toList());
            }
        } catch (Exception e) {
            result.put("parcel", List.of());
        }

        // Real Estate - paid approved only (no lat/lng on findNearbyPosts, use standard query)
        try {
            var rePosts = realEstatePostRepository.findByStatusAndIsPaidTrueOrderByCreatedAtDesc(
                    RealEstatePost.PostStatus.APPROVED, top10).getContent();
            if (hasLocation) {
                // Filter by distance in Java for real estate (has its own lat/lng fields)
                result.put("realEstate", rePosts.stream()
                        .filter(p -> p.getLatitude() == null || p.getLongitude() == null ||
                                haversineDistance(lat, lng, p.getLatitude(), p.getLongitude()) <= radius)
                        .map(this::mapRealEstate).toList());
            } else {
                result.put("realEstate", rePosts.stream().map(this::mapRealEstate).toList());
            }
        } catch (Exception e) {
            result.put("realEstate", List.of());
        }

        return result;
    }

    /**
     * Calculate Haversine distance between two points in km.
     */
    private double haversineDistance(double lat1, double lng1, double lat2, double lng2) {
        double R = 6371.0; // Earth radius in km
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                Math.sin(dLng / 2) * Math.sin(dLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
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

    private Map<String, Object> mapPromotion(Promotion p) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", p.getId());
        m.put("title", p.getTitle());
        m.put("description", p.getDescription());
        m.put("code", p.getCode());
        m.put("type", p.getType() != null ? p.getType().name() : null);
        m.put("discountValue", p.getDiscountValue());
        m.put("minimumOrderAmount", p.getMinimumOrderAmount());
        m.put("maximumDiscountAmount", p.getMaximumDiscountAmount());
        m.put("imageUrl", p.getImageUrl());
        m.put("bannerUrl", p.getBannerUrl());
        m.put("endDate", p.getEndDate() != null ? p.getEndDate().toString() : null);
        // Get shop name if shop-specific promotion
        if (p.getShopId() != null) {
            m.put("shopId", p.getShopId());
            try {
                shopRepository.findById(p.getShopId()).ifPresent(shop -> m.put("shopName", shop.getName()));
            } catch (Exception ignored) {}
        }
        return m;
    }

    private Map<String, Object> mapCombo(ProductCombo c) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", c.getId());
        m.put("name", c.getName());
        m.put("nameTamil", c.getNameTamil());
        m.put("description", c.getDescription());
        m.put("bannerImageUrl", c.getBannerImageUrl());
        m.put("comboPrice", c.getComboPrice());
        m.put("originalPrice", c.getOriginalPrice());
        m.put("discountPercentage", c.getDiscountPercentage());
        m.put("shopName", c.getShop() != null ? c.getShop().getName() : null);
        m.put("shopId", c.getShop() != null ? c.getShop().getId() : null);
        m.put("itemCount", c.getItemCount());
        m.put("endDate", c.getEndDate() != null ? c.getEndDate().toString() : null);
        return m;
    }
}
