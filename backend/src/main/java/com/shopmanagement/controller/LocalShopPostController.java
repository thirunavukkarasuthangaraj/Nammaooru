package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.LocalShopPost;
import com.shopmanagement.service.LocalShopPostService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
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
@RequestMapping("/api/local-shops")
@RequiredArgsConstructor
@Slf4j
public class LocalShopPostController {

    private final LocalShopPostService localShopPostService;

    @PostMapping(consumes = "multipart/form-data")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<LocalShopPost>> createPost(
            @RequestParam("shopName") String shopName,
            @RequestParam("phone") String phone,
            @RequestParam("category") String category,
            @RequestParam(value = "address", required = false) String address,
            @RequestParam(value = "timings", required = false) String timings,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "images", required = false) List<MultipartFile> images,
            @RequestParam(value = "latitude", required = false) BigDecimal latitude,
            @RequestParam(value = "longitude", required = false) BigDecimal longitude,
            @RequestParam(value = "paidTokenId", required = false) Long paidTokenId,
            @RequestParam(value = "isBanner", defaultValue = "false") boolean isBanner) {
        try {
            String username = getCurrentUsername();
            LocalShopPost post = localShopPostService.createPost(
                    shopName, phone, category, address, timings, description, images, username,
                    latitude, longitude, paidTokenId, isBanner);
            return ResponseUtil.created(post, "Shop listing submitted successfully");
        } catch (Exception e) {
            log.error("Error creating local shop post", e);
            if ("LIMIT_REACHED".equals(e.getMessage())) {
                return ResponseUtil.error(HttpStatus.PAYMENT_REQUIRED, "LIMIT_REACHED", "Post limit reached. Payment required to post.");
            }
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getApprovedPosts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng,
            @RequestParam(required = false) Double radius,
            @RequestParam(required = false) String search) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<LocalShopPost> posts;
            if (search != null && !search.trim().isEmpty()) {
                posts = localShopPostService.searchByAddress(search.trim(), pageable);
            } else {
                Double effectiveLat = lat;
                Double effectiveLng = lng;
                Double effectiveRadius = (lat != null && lng != null) ? radius : null;
                if (category != null && !category.isEmpty()) {
                    posts = localShopPostService.getApprovedPostsByCategory(category, pageable, effectiveLat, effectiveLng, effectiveRadius);
                } else {
                    posts = localShopPostService.getApprovedPosts(pageable, effectiveLat, effectiveLng, effectiveRadius);
                }
            }
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching local shop posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<LocalShopPost>> getPostById(@PathVariable Long id) {
        try {
            LocalShopPost post = localShopPostService.getPostById(id);
            return ResponseUtil.success(post, "Shop listing retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching local shop post", e);
            return ResponseUtil.notFound(e.getMessage());
        }
    }

    @GetMapping("/my")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<LocalShopPost>>> getMyPosts() {
        try {
            String username = getCurrentUsername();
            List<LocalShopPost> posts = localShopPostService.getMyPosts(username);
            return ResponseUtil.success(posts, "My shop listings retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching my local shop posts", e);
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
            Page<LocalShopPost> posts = localShopPostService.getPendingPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching pending local shop posts", e);
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
            Page<LocalShopPost> posts = localShopPostService.getReportedPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching reported local shop posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/admin/all")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAllPostsForAdmin(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String search) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<LocalShopPost> posts = localShopPostService.getAllPostsForAdmin(pageable, search);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching all local shop posts for admin", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/approve")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<LocalShopPost>> approvePost(@PathVariable Long id) {
        try {
            LocalShopPost post = localShopPostService.approvePost(id);
            return ResponseUtil.success(post, "Shop listing approved successfully");
        } catch (Exception e) {
            log.error("Error approving local shop post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/reject")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<LocalShopPost>> rejectPost(@PathVariable Long id) {
        try {
            LocalShopPost post = localShopPostService.rejectPost(id);
            return ResponseUtil.success(post, "Shop listing rejected");
        } catch (Exception e) {
            log.error("Error rejecting local shop post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<LocalShopPost>> changePostStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        try {
            String status = body.get("status");
            if (status == null || status.isEmpty()) {
                return ResponseUtil.error("Status is required");
            }
            LocalShopPost post = localShopPostService.changePostStatus(id, status);
            return ResponseUtil.success(post, "Shop listing status updated to " + status);
        } catch (Exception e) {
            log.error("Error changing local shop post status", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/unavailable")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<LocalShopPost>> markAsUnavailable(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            LocalShopPost post = localShopPostService.markAsUnavailable(id, username);
            return ResponseUtil.success(post, "Shop listing marked as closed");
        } catch (Exception e) {
            log.error("Error marking local shop post as unavailable", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/available")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<LocalShopPost>> markAsAvailable(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            LocalShopPost post = localShopPostService.markAsAvailable(id, username);
            return ResponseUtil.success(post, "Shop listing marked as open");
        } catch (Exception e) {
            log.error("Error marking local shop post as available", e);
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
            localShopPostService.deletePost(id, username, isAdmin);
            return ResponseUtil.deleted();
        } catch (Exception e) {
            log.error("Error deleting local shop post", e);
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
            localShopPostService.reportPost(id, reason, details, username);
            return ResponseUtil.success(null, "Listing reported successfully. We will review it.");
        } catch (Exception e) {
            log.error("Error reporting local shop post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/admin-update")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<LocalShopPost>> adminUpdatePost(
            @PathVariable Long id,
            @RequestBody Map<String, Object> updates) {
        try {
            LocalShopPost post = localShopPostService.adminUpdatePost(id, updates);
            return ResponseUtil.success(post, "Shop listing updated successfully");
        } catch (Exception e) {
            log.error("Error admin-updating local shop post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/featured")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<LocalShopPost>> toggleFeatured(@PathVariable Long id) {
        try {
            LocalShopPost post = localShopPostService.toggleFeatured(id);
            String msg = Boolean.TRUE.equals(post.getFeatured()) ? "Post marked as featured" : "Post removed from featured";
            return ResponseUtil.success(post, msg);
        } catch (Exception e) {
            log.error("Error toggling featured status for local shop post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/renew")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<LocalShopPost>> renewPost(
            @PathVariable Long id,
            @RequestParam(value = "paidTokenId", required = false) Long paidTokenId) {
        try {
            String username = getCurrentUsername();
            LocalShopPost post = localShopPostService.renewPost(id, paidTokenId, username);
            return ResponseUtil.success(post, "Post renewed successfully");
        } catch (Exception e) {
            log.error("Error renewing local shop post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/edit")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<LocalShopPost>> userEditPost(
            @PathVariable Long id,
            @RequestBody Map<String, Object> updates) {
        try {
            String username = getCurrentUsername();
            LocalShopPost post = localShopPostService.userEditPost(id, updates, username);
            return ResponseUtil.success(post, "Post updated successfully. It will be reviewed again.");
        } catch (Exception e) {
            log.error("Error editing local shop post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication.getName();
    }
}
