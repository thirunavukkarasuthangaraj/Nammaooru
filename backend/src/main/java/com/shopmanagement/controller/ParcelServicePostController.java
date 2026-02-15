package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.ParcelServicePost;
import com.shopmanagement.service.ParcelServicePostService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/parcels")
@RequiredArgsConstructor
@Slf4j
public class ParcelServicePostController {

    private final ParcelServicePostService parcelServicePostService;

    @PostMapping(consumes = "multipart/form-data")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<ParcelServicePost>> createPost(
            @RequestParam("serviceName") String serviceName,
            @RequestParam("phone") String phone,
            @RequestParam("serviceType") String serviceType,
            @RequestParam(value = "fromLocation", required = false) String fromLocation,
            @RequestParam(value = "toLocation", required = false) String toLocation,
            @RequestParam(value = "priceInfo", required = false) String priceInfo,
            @RequestParam(value = "address", required = false) String address,
            @RequestParam(value = "timings", required = false) String timings,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "images", required = false) List<MultipartFile> images,
            @RequestParam(value = "latitude", required = false) BigDecimal latitude,
            @RequestParam(value = "longitude", required = false) BigDecimal longitude) {
        try {
            String username = getCurrentUsername();
            ParcelServicePost post = parcelServicePostService.createPost(
                    serviceName, phone, serviceType, fromLocation, toLocation, priceInfo,
                    address, timings, description, images, username,
                    latitude, longitude);
            return ResponseUtil.created(post, "Parcel service listing submitted successfully");
        } catch (Exception e) {
            log.error("Error creating parcel service post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getApprovedPosts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String serviceType,
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng,
            @RequestParam(defaultValue = "50") double radius) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Double effectiveLat = lat;
            Double effectiveLng = lng;
            Double effectiveRadius = (lat != null && lng != null) ? radius : null;
            Page<ParcelServicePost> posts;
            if (serviceType != null && !serviceType.isEmpty()) {
                posts = parcelServicePostService.getApprovedPostsByServiceType(serviceType, pageable, effectiveLat, effectiveLng, effectiveRadius);
            } else {
                posts = parcelServicePostService.getApprovedPosts(pageable, effectiveLat, effectiveLng, effectiveRadius);
            }
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching approved parcel service posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ParcelServicePost>> getPostById(@PathVariable Long id) {
        try {
            ParcelServicePost post = parcelServicePostService.getPostById(id);
            return ResponseUtil.success(post, "Parcel service post retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching parcel service post", e);
            return ResponseUtil.notFound(e.getMessage());
        }
    }

    @GetMapping("/my")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<ParcelServicePost>>> getMyPosts() {
        try {
            String username = getCurrentUsername();
            List<ParcelServicePost> posts = parcelServicePostService.getMyPosts(username);
            return ResponseUtil.success(posts, "My parcel service listings retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching my parcel service posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/pending")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPendingPosts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<ParcelServicePost> posts = parcelServicePostService.getPendingPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching pending parcel service posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/admin/reported")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getReportedPosts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<ParcelServicePost> posts = parcelServicePostService.getReportedPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching reported parcel service posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/admin/all")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAllPostsForAdmin(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<ParcelServicePost> posts = parcelServicePostService.getAllPostsForAdmin(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching all parcel service posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/approve")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<ParcelServicePost>> approvePost(@PathVariable Long id) {
        try {
            ParcelServicePost post = parcelServicePostService.approvePost(id);
            return ResponseUtil.success(post, "Parcel service listing approved successfully");
        } catch (Exception e) {
            log.error("Error approving parcel service post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/reject")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<ParcelServicePost>> rejectPost(@PathVariable Long id) {
        try {
            ParcelServicePost post = parcelServicePostService.rejectPost(id);
            return ResponseUtil.success(post, "Parcel service listing rejected");
        } catch (Exception e) {
            log.error("Error rejecting parcel service post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<ParcelServicePost>> changePostStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        try {
            String status = body.get("status");
            if (status == null || status.isEmpty()) {
                return ResponseUtil.error("Status is required");
            }
            ParcelServicePost post = parcelServicePostService.changePostStatus(id, status);
            return ResponseUtil.success(post, "Parcel service listing status updated to " + status);
        } catch (Exception e) {
            log.error("Error changing parcel service post status", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/unavailable")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<ParcelServicePost>> markAsUnavailable(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            ParcelServicePost post = parcelServicePostService.markAsUnavailable(id, username);
            return ResponseUtil.success(post, "Parcel service listing marked as unavailable");
        } catch (Exception e) {
            log.error("Error marking parcel service post as unavailable", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/available")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<ParcelServicePost>> markAsAvailable(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            ParcelServicePost post = parcelServicePostService.markAsAvailable(id, username);
            return ResponseUtil.success(post, "Parcel service listing marked as available");
        } catch (Exception e) {
            log.error("Error marking parcel service post as available", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Void>> deletePost(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            boolean isAdmin = auth.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_SUPER_ADMIN"));
            parcelServicePostService.deletePost(id, username, isAdmin);
            return ResponseUtil.deleted();
        } catch (Exception e) {
            log.error("Error deleting parcel service post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping("/{id}/report")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Void>> reportPost(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        try {
            String username = getCurrentUsername();
            String reason = body.getOrDefault("reason", "Other");
            String details = body.get("details");
            parcelServicePostService.reportPost(id, reason, details, username);
            return ResponseUtil.success(null, "Listing reported successfully. We will review it.");
        } catch (Exception e) {
            log.error("Error reporting parcel service post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication.getName();
    }
}
