package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.WomensCornerPost;
import com.shopmanagement.service.WomensCornerPostService;
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
@RequestMapping("/api/womens-corner/posts")
@RequiredArgsConstructor
@Slf4j
public class WomensCornerPostController {

    private final WomensCornerPostService womensCornerPostService;

    @PostMapping(consumes = "multipart/form-data")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<WomensCornerPost>> createPost(
            @RequestParam("title") String title,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "price", required = false) BigDecimal price,
            @RequestParam("phone") String phone,
            @RequestParam(value = "category", required = false) String category,
            @RequestParam(value = "location", required = false) String location,
            @RequestParam(value = "images", required = false) List<MultipartFile> images,
            @RequestParam(value = "latitude", required = false) BigDecimal latitude,
            @RequestParam(value = "longitude", required = false) BigDecimal longitude,
            @RequestParam(value = "paidTokenId", required = false) Long paidTokenId) {
        try {
            String username = getCurrentUsername();
            WomensCornerPost post = womensCornerPostService.createPost(
                    title, description, price, phone, category, location, images, username, latitude, longitude, paidTokenId);
            return ResponseUtil.created(post, "Women's corner post submitted successfully");
        } catch (Exception e) {
            log.error("Error creating women's corner post", e);
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
            @RequestParam(defaultValue = "50") double radius,
            @RequestParam(required = false) String search) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<WomensCornerPost> posts;
            if (search != null && !search.trim().isEmpty()) {
                posts = womensCornerPostService.searchByLocation(search.trim(), pageable);
            } else if (category != null && !category.isEmpty()) {
                posts = womensCornerPostService.getApprovedPostsByCategory(category, pageable, lat, lng, radius);
            } else {
                posts = womensCornerPostService.getApprovedPosts(pageable, lat, lng, radius);
            }
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching approved women's corner posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/featured")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getFeaturedPosts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        try {
            Page<WomensCornerPost> posts = womensCornerPostService.getFeaturedPosts(page, size);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching featured women's corner posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<WomensCornerPost>> getPostById(@PathVariable Long id) {
        try {
            WomensCornerPost post = womensCornerPostService.getPostById(id);
            return ResponseUtil.success(post, "Post retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching women's corner post", e);
            return ResponseUtil.notFound(e.getMessage());
        }
    }

    @GetMapping("/my")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<WomensCornerPost>>> getMyPosts() {
        try {
            String username = getCurrentUsername();
            List<WomensCornerPost> posts = womensCornerPostService.getMyPosts(username);
            return ResponseUtil.success(posts, "My posts retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching my women's corner posts", e);
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
            Page<WomensCornerPost> posts = womensCornerPostService.getPendingPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching pending women's corner posts", e);
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
            Page<WomensCornerPost> posts = womensCornerPostService.getReportedPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching reported women's corner posts", e);
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
            Page<WomensCornerPost> posts = womensCornerPostService.getAllPostsForAdmin(pageable, search);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching all women's corner posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/approve")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<WomensCornerPost>> approvePost(@PathVariable Long id) {
        try {
            WomensCornerPost post = womensCornerPostService.approvePost(id);
            return ResponseUtil.success(post, "Post approved successfully");
        } catch (Exception e) {
            log.error("Error approving women's corner post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/reject")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<WomensCornerPost>> rejectPost(@PathVariable Long id) {
        try {
            WomensCornerPost post = womensCornerPostService.rejectPost(id);
            return ResponseUtil.success(post, "Post rejected");
        } catch (Exception e) {
            log.error("Error rejecting women's corner post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<WomensCornerPost>> changePostStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        try {
            String status = body.get("status");
            if (status == null || status.isEmpty()) {
                return ResponseUtil.error("Status is required");
            }
            WomensCornerPost post = womensCornerPostService.changePostStatus(id, status);
            return ResponseUtil.success(post, "Post status updated to " + status);
        } catch (Exception e) {
            log.error("Error changing women's corner post status", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/featured")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<WomensCornerPost>> toggleFeatured(@PathVariable Long id) {
        try {
            WomensCornerPost post = womensCornerPostService.toggleFeatured(id);
            String msg = Boolean.TRUE.equals(post.getFeatured()) ? "Post marked as featured" : "Post removed from featured";
            return ResponseUtil.success(post, msg);
        } catch (Exception e) {
            log.error("Error toggling featured status", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/sold")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<WomensCornerPost>> markAsSold(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            WomensCornerPost post = womensCornerPostService.markAsSold(id, username);
            return ResponseUtil.success(post, "Post marked as sold");
        } catch (Exception e) {
            log.error("Error marking women's corner post as sold", e);
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
            womensCornerPostService.deletePost(id, username, isAdmin);
            return ResponseUtil.deleted();
        } catch (Exception e) {
            log.error("Error deleting women's corner post", e);
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
            womensCornerPostService.reportPost(id, reason, details, username);
            return ResponseUtil.success(null, "Post reported successfully. We will review it.");
        } catch (Exception e) {
            log.error("Error reporting women's corner post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/admin-update")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<WomensCornerPost>> adminUpdatePost(
            @PathVariable Long id,
            @RequestBody Map<String, Object> updates) {
        try {
            WomensCornerPost post = womensCornerPostService.adminUpdatePost(id, updates);
            return ResponseUtil.success(post, "Post updated successfully");
        } catch (Exception e) {
            log.error("Error admin-updating women's corner post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/renew")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<WomensCornerPost>> renewPost(
            @PathVariable Long id,
            @RequestParam(value = "paidTokenId", required = false) Long paidTokenId) {
        try {
            String username = getCurrentUsername();
            WomensCornerPost post = womensCornerPostService.renewPost(id, paidTokenId, username);
            return ResponseUtil.success(post, "Post renewed successfully");
        } catch (Exception e) {
            log.error("Error renewing women's corner post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/edit")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<WomensCornerPost>> userEditPost(
            @PathVariable Long id,
            @RequestBody Map<String, Object> updates) {
        try {
            String username = getCurrentUsername();
            WomensCornerPost post = womensCornerPostService.userEditPost(id, updates, username);
            return ResponseUtil.success(post, "Post updated successfully. It will be reviewed again.");
        } catch (Exception e) {
            log.error("Error editing women's corner post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication.getName();
    }
}
