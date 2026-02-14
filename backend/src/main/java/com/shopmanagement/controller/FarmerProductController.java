package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.FarmerProduct;
import com.shopmanagement.service.FarmerProductService;
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
@RequestMapping("/api/farmer-products")
@RequiredArgsConstructor
@Slf4j
public class FarmerProductController {

    private final FarmerProductService farmerProductService;

    @PostMapping(consumes = "multipart/form-data")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<FarmerProduct>> createPost(
            @RequestParam("title") String title,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "price", required = false) BigDecimal price,
            @RequestParam("phone") String phone,
            @RequestParam(value = "category", required = false) String category,
            @RequestParam(value = "location", required = false) String location,
            @RequestParam(value = "unit", required = false) String unit,
            @RequestParam(value = "image", required = false) MultipartFile image) {
        try {
            String username = getCurrentUsername();
            FarmerProduct post = farmerProductService.createPost(
                    title, description, price, phone, category, location, unit, image, username);
            return ResponseUtil.created(post, "Farmer product submitted for approval");
        } catch (Exception e) {
            log.error("Error creating farmer product post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getApprovedPosts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String category) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<FarmerProduct> posts;
            if (category != null && !category.isEmpty()) {
                posts = farmerProductService.getApprovedPostsByCategory(category, pageable);
            } else {
                posts = farmerProductService.getApprovedPosts(pageable);
            }
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching approved farmer products", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<FarmerProduct>> getPostById(@PathVariable Long id) {
        try {
            FarmerProduct post = farmerProductService.getPostById(id);
            return ResponseUtil.success(post, "Farmer product retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching farmer product", e);
            return ResponseUtil.notFound(e.getMessage());
        }
    }

    @GetMapping("/my")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<FarmerProduct>>> getMyPosts() {
        try {
            String username = getCurrentUsername();
            List<FarmerProduct> posts = farmerProductService.getMyPosts(username);
            return ResponseUtil.success(posts, "My farmer products retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching my farmer products", e);
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
            Page<FarmerProduct> posts = farmerProductService.getPendingPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching pending farmer products", e);
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
            Page<FarmerProduct> posts = farmerProductService.getReportedPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching reported farmer products", e);
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
            Page<FarmerProduct> posts = farmerProductService.getAllPostsForAdmin(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching all farmer products", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/approve")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<FarmerProduct>> approvePost(@PathVariable Long id) {
        try {
            FarmerProduct post = farmerProductService.approvePost(id);
            return ResponseUtil.success(post, "Farmer product approved successfully");
        } catch (Exception e) {
            log.error("Error approving farmer product", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/reject")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<FarmerProduct>> rejectPost(@PathVariable Long id) {
        try {
            FarmerProduct post = farmerProductService.rejectPost(id);
            return ResponseUtil.success(post, "Farmer product rejected");
        } catch (Exception e) {
            log.error("Error rejecting farmer product", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<FarmerProduct>> changePostStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        try {
            String status = body.get("status");
            if (status == null || status.isEmpty()) {
                return ResponseUtil.error("Status is required");
            }
            FarmerProduct post = farmerProductService.changePostStatus(id, status);
            return ResponseUtil.success(post, "Farmer product status updated to " + status);
        } catch (Exception e) {
            log.error("Error changing farmer product status", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/sold")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<FarmerProduct>> markAsSold(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            FarmerProduct post = farmerProductService.markAsSold(id, username);
            return ResponseUtil.success(post, "Farmer product marked as sold");
        } catch (Exception e) {
            log.error("Error marking farmer product as sold", e);
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
            farmerProductService.deletePost(id, username, isAdmin);
            return ResponseUtil.deleted();
        } catch (Exception e) {
            log.error("Error deleting farmer product", e);
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
            farmerProductService.reportPost(id, reason, details, username);
            return ResponseUtil.success(null, "Post reported successfully. We will review it.");
        } catch (Exception e) {
            log.error("Error reporting farmer product", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication.getName();
    }
}
