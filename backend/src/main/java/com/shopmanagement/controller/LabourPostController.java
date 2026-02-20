package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.LabourPost;
import com.shopmanagement.service.LabourPostService;
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
@RequestMapping("/api/labours")
@RequiredArgsConstructor
@Slf4j
public class LabourPostController {

    private final LabourPostService labourPostService;

    @PostMapping(consumes = "multipart/form-data")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<LabourPost>> createPost(
            @RequestParam("name") String name,
            @RequestParam("phone") String phone,
            @RequestParam("category") String category,
            @RequestParam(value = "experience", required = false) String experience,
            @RequestParam(value = "location", required = false) String location,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "images", required = false) List<MultipartFile> images,
            @RequestParam(value = "latitude", required = false) BigDecimal latitude,
            @RequestParam(value = "longitude", required = false) BigDecimal longitude,
            @RequestParam(value = "paidTokenId", required = false) Long paidTokenId) {
        try {
            String username = getCurrentUsername();
            LabourPost post = labourPostService.createPost(
                    name, phone, category, experience, location, description, images, username,
                    latitude, longitude, paidTokenId);
            return ResponseUtil.created(post, "Labour listing submitted successfully");
        } catch (Exception e) {
            log.error("Error creating labour post", e);
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
            Page<LabourPost> posts;
            if (search != null && !search.trim().isEmpty()) {
                posts = labourPostService.searchByLocation(search.trim(), pageable);
            } else {
                Double effectiveLat = lat;
                Double effectiveLng = lng;
                Double effectiveRadius = (lat != null && lng != null) ? radius : null;
                if (category != null && !category.isEmpty()) {
                    posts = labourPostService.getApprovedPostsByCategory(category, pageable, effectiveLat, effectiveLng, effectiveRadius);
                } else {
                    posts = labourPostService.getApprovedPosts(pageable, effectiveLat, effectiveLng, effectiveRadius);
                }
            }
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching approved labour posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<LabourPost>> getPostById(@PathVariable Long id) {
        try {
            LabourPost post = labourPostService.getPostById(id);
            return ResponseUtil.success(post, "Labour post retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching labour post", e);
            return ResponseUtil.notFound(e.getMessage());
        }
    }

    @GetMapping("/my")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<LabourPost>>> getMyPosts() {
        try {
            String username = getCurrentUsername();
            List<LabourPost> posts = labourPostService.getMyPosts(username);
            return ResponseUtil.success(posts, "My labour listings retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching my labour posts", e);
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
            Page<LabourPost> posts = labourPostService.getPendingPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching pending labour posts", e);
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
            Page<LabourPost> posts = labourPostService.getReportedPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching reported labour posts", e);
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
            Page<LabourPost> posts = labourPostService.getAllPostsForAdmin(pageable, search);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching all labour posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/approve")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<LabourPost>> approvePost(@PathVariable Long id) {
        try {
            LabourPost post = labourPostService.approvePost(id);
            return ResponseUtil.success(post, "Labour listing approved successfully");
        } catch (Exception e) {
            log.error("Error approving labour post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/reject")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<LabourPost>> rejectPost(@PathVariable Long id) {
        try {
            LabourPost post = labourPostService.rejectPost(id);
            return ResponseUtil.success(post, "Labour listing rejected");
        } catch (Exception e) {
            log.error("Error rejecting labour post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<LabourPost>> changePostStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        try {
            String status = body.get("status");
            if (status == null || status.isEmpty()) {
                return ResponseUtil.error("Status is required");
            }
            LabourPost post = labourPostService.changePostStatus(id, status);
            return ResponseUtil.success(post, "Labour listing status updated to " + status);
        } catch (Exception e) {
            log.error("Error changing labour post status", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/unavailable")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<LabourPost>> markAsUnavailable(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            LabourPost post = labourPostService.markAsUnavailable(id, username);
            return ResponseUtil.success(post, "Labour listing marked as unavailable");
        } catch (Exception e) {
            log.error("Error marking labour post as unavailable", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/available")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<LabourPost>> markAsAvailable(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            LabourPost post = labourPostService.markAsAvailable(id, username);
            return ResponseUtil.success(post, "Labour listing marked as available");
        } catch (Exception e) {
            log.error("Error marking labour post as available", e);
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
            labourPostService.deletePost(id, username, isAdmin);
            return ResponseUtil.deleted();
        } catch (Exception e) {
            log.error("Error deleting labour post", e);
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
            labourPostService.reportPost(id, reason, details, username);
            return ResponseUtil.success(null, "Listing reported successfully. We will review it.");
        } catch (Exception e) {
            log.error("Error reporting labour post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/admin-update")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<LabourPost>> adminUpdatePost(
            @PathVariable Long id,
            @RequestBody Map<String, Object> updates) {
        try {
            LabourPost post = labourPostService.adminUpdatePost(id, updates);
            return ResponseUtil.success(post, "Labour listing updated successfully");
        } catch (Exception e) {
            log.error("Error admin-updating labour post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/featured")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<LabourPost>> toggleFeatured(@PathVariable Long id) {
        try {
            LabourPost post = labourPostService.toggleFeatured(id);
            String msg = Boolean.TRUE.equals(post.getFeatured()) ? "Post marked as featured" : "Post removed from featured";
            return ResponseUtil.success(post, msg);
        } catch (Exception e) {
            log.error("Error toggling featured status for labour post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/renew")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<LabourPost>> renewPost(
            @PathVariable Long id,
            @RequestParam(value = "paidTokenId", required = false) Long paidTokenId) {
        try {
            String username = getCurrentUsername();
            LabourPost post = labourPostService.renewPost(id, paidTokenId, username);
            return ResponseUtil.success(post, "Post renewed successfully");
        } catch (Exception e) {
            log.error("Error renewing labour post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/edit")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<LabourPost>> userEditPost(
            @PathVariable Long id,
            @RequestBody Map<String, Object> updates) {
        try {
            String username = getCurrentUsername();
            LabourPost post = labourPostService.userEditPost(id, updates, username);
            return ResponseUtil.success(post, "Post updated successfully. It will be reviewed again.");
        } catch (Exception e) {
            log.error("Error editing labour post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication.getName();
    }
}
