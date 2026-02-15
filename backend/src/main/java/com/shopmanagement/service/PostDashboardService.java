package com.shopmanagement.service;

import com.shopmanagement.entity.LabourPost;
import com.shopmanagement.entity.TravelPost;
import com.shopmanagement.entity.ParcelServicePost;
import com.shopmanagement.entity.MarketplacePost;
import com.shopmanagement.entity.FarmerProduct;
import com.shopmanagement.entity.RealEstatePost;
import com.shopmanagement.repository.LabourPostRepository;
import com.shopmanagement.repository.TravelPostRepository;
import com.shopmanagement.repository.ParcelServicePostRepository;
import com.shopmanagement.repository.MarketplacePostRepository;
import com.shopmanagement.repository.FarmerProductRepository;
import com.shopmanagement.repository.RealEstatePostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class PostDashboardService {

    private final LabourPostRepository labourPostRepository;
    private final TravelPostRepository travelPostRepository;
    private final ParcelServicePostRepository parcelServicePostRepository;
    private final MarketplacePostRepository marketplacePostRepository;
    private final FarmerProductRepository farmerProductRepository;
    private final RealEstatePostRepository realEstatePostRepository;

    public Map<String, Map<String, Long>> getDashboardStats() {
        Map<String, Map<String, Long>> stats = new HashMap<>();
        stats.put("labour", getLabourStats());
        stats.put("travel", getTravelStats());
        stats.put("parcel", getParcelStats());
        stats.put("marketplace", getMarketplaceStats());
        stats.put("farmer", getFarmerStats());
        stats.put("realEstate", getRealEstateStats());
        return stats;
    }

    private Map<String, Long> getLabourStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", labourPostRepository.count());
        stats.put("pending", labourPostRepository.countByStatus(LabourPost.PostStatus.PENDING_APPROVAL));
        stats.put("approved", labourPostRepository.countByStatus(LabourPost.PostStatus.APPROVED));
        stats.put("rejected", labourPostRepository.countByStatus(LabourPost.PostStatus.REJECTED));
        stats.put("reported", labourPostRepository.countByReportCountGreaterThan(0));
        return stats;
    }

    private Map<String, Long> getTravelStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", travelPostRepository.count());
        stats.put("pending", travelPostRepository.countByStatus(TravelPost.PostStatus.PENDING_APPROVAL));
        stats.put("approved", travelPostRepository.countByStatus(TravelPost.PostStatus.APPROVED));
        stats.put("rejected", travelPostRepository.countByStatus(TravelPost.PostStatus.REJECTED));
        stats.put("reported", travelPostRepository.countByReportCountGreaterThan(0));
        return stats;
    }

    private Map<String, Long> getParcelStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", parcelServicePostRepository.count());
        stats.put("pending", parcelServicePostRepository.countByStatus(ParcelServicePost.PostStatus.PENDING_APPROVAL));
        stats.put("approved", parcelServicePostRepository.countByStatus(ParcelServicePost.PostStatus.APPROVED));
        stats.put("rejected", parcelServicePostRepository.countByStatus(ParcelServicePost.PostStatus.REJECTED));
        stats.put("reported", parcelServicePostRepository.countByReportCountGreaterThan(0));
        return stats;
    }

    private Map<String, Long> getMarketplaceStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", marketplacePostRepository.count());
        stats.put("pending", marketplacePostRepository.countByStatus(MarketplacePost.PostStatus.PENDING_APPROVAL));
        stats.put("approved", marketplacePostRepository.countByStatus(MarketplacePost.PostStatus.APPROVED));
        stats.put("rejected", marketplacePostRepository.countByStatus(MarketplacePost.PostStatus.REJECTED));
        stats.put("reported", marketplacePostRepository.countByReportCountGreaterThan(0));
        return stats;
    }

    private Map<String, Long> getFarmerStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", farmerProductRepository.count());
        stats.put("pending", farmerProductRepository.countByStatus(FarmerProduct.PostStatus.PENDING_APPROVAL));
        stats.put("approved", farmerProductRepository.countByStatus(FarmerProduct.PostStatus.APPROVED));
        stats.put("rejected", farmerProductRepository.countByStatus(FarmerProduct.PostStatus.REJECTED));
        stats.put("reported", farmerProductRepository.countByReportCountGreaterThan(0));
        return stats;
    }

    private Map<String, Long> getRealEstateStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", realEstatePostRepository.count());
        stats.put("pending", realEstatePostRepository.countByStatus(RealEstatePost.PostStatus.PENDING_APPROVAL));
        stats.put("approved", realEstatePostRepository.countByStatus(RealEstatePost.PostStatus.APPROVED));
        stats.put("rejected", realEstatePostRepository.countByStatus(RealEstatePost.PostStatus.REJECTED));
        stats.put("reported", realEstatePostRepository.countByReportCountGreaterThan(0));
        return stats;
    }
}
