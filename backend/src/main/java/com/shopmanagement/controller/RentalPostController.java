package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.RentalPost;
import com.shopmanagement.service.RentalPostService;
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
@RequestMapping("/api/rentals")
@RequiredArgsConstructor
@Slf4j
public class RentalPostController {

    private final RentalPostService rentalPostService;

    @PostMapping(consumes = "multipart/form-data")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<RentalPost>> createPost(
            @RequestParam("title") String title,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "price", required = false) BigDecimal price,
            @RequestParam(value = "priceUnit", required = false) String priceUnit,
            @RequestParam("phone") String phone,
            @RequestParam(value = "category", required = false) String category,
            @RequestParam(value = "location", required = false) String location,
            @RequestParam(value = "images", required = false) List<MultipartFile> images,
            @RequestParam(value = "latitude", required = false) BigDecimal latitude,
            @RequestParam(value = "longitude", required = false) BigDecimal longitude,
            @RequestParam(value = "paidTokenId", required = false) Long paidTokenId,
            @RequestParam(value = "isBanner", defaultValue = "false") boolean isBanner) {
        try {
            String username = getCurrentUsername();
            RentalPost post = rentalPostService.createPost(
                    title, description, price, priceUnit, phone, category, location,
                    images, username, latitude, longitude, paidTokenId, isBanner);
            return ResponseUtil.created(post, "Rental post submitted for approval");
        } catch (Exception e) {
            log.error("Error creating rental post", e);
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
            Page<RentalPost> posts;
            if (search != null && !search.trim().isEmpty()) {
                posts = rentalPostService.searchByLocation(search.trim(), pageable);
            } else if (category != null && !category.isEmpty()) {
                posts = rentalPostService.getApprovedPostsByCategory(category, pageable, lat, lng, radius);
            } else {
                posts = rentalPostService.getApprovedPosts(pageable, lat, lng, radius);
            }
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching rental posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<RentalPost>> getPostById(@PathVariable Long id) {
        try {
            RentalPost post = rentalPostService.getPostById(id);
            return ResponseUtil.success(post, "Rental post retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching rental post", e);
            return ResponseUtil.notFound(e.getMessage());
        }
    }

    @GetMapping("/my")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<RentalPost>>> getMyPosts() {
        try {
            String username = getCurrentUsername();
            List<RentalPost> posts = rentalPostService.getMyPosts(username);
            return ResponseUtil.success(posts, "My rental posts retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching my rental posts", e);
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
            Page<RentalPost> posts = rentalPostService.getPendingPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching pending rental posts", e);
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
            Page<RentalPost> posts = rentalPostService.getReportedPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching reported rental posts", e);
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
            Page<RentalPost> posts = rentalPostService.getAllPostsForAdmin(pageable, search);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching all rental posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/approve")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<RentalPost>> approvePost(@PathVariable Long id) {
        try {
            RentalPost post = rentalPostService.approvePost(id);
            return ResponseUtil.success(post, "Rental post approved successfully");
        } catch (Exception e) {
            log.error("Error approving rental post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/reject")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<RentalPost>> rejectPost(@PathVariable Long id) {
        try {
            RentalPost post = rentalPostService.rejectPost(id);
            return ResponseUtil.success(post, "Rental post rejected");
        } catch (Exception e) {
            log.error("Error rejecting rental post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<RentalPost>> changePostStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        try {
            String status = body.get("status");
            if (status == null || status.isEmpty()) {
                return ResponseUtil.error("Status is required");
            }
            RentalPost post = rentalPostService.changePostStatus(id, status);
            return ResponseUtil.success(post, "Rental post status updated to " + status);
        } catch (Exception e) {
            log.error("Error changing rental post status", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/rented")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<RentalPost>> markAsRented(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            RentalPost post = rentalPostService.markAsRented(id, username);
            return ResponseUtil.success(post, "Rental post marked as rented");
        } catch (Exception e) {
            log.error("Error marking rental post as rented", e);
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
            rentalPostService.deletePost(id, username, isAdmin);
            return ResponseUtil.deleted();
        } catch (Exception e) {
            log.error("Error deleting rental post", e);
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
            rentalPostService.reportPost(id, reason, details, username);
            return ResponseUtil.success(null, "Rental post reported successfully. We will review it.");
        } catch (Exception e) {
            log.error("Error reporting rental post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/admin-update")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<RentalPost>> adminUpdatePost(
            @PathVariable Long id,
            @RequestBody Map<String, Object> updates) {
        try {
            RentalPost post = rentalPostService.adminUpdatePost(id, updates);
            return ResponseUtil.success(post, "Rental post updated successfully");
        } catch (Exception e) {
            log.error("Error admin-updating rental post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/featured")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<RentalPost>> toggleFeatured(@PathVariable Long id) {
        try {
            RentalPost post = rentalPostService.toggleFeatured(id);
            String msg = Boolean.TRUE.equals(post.getFeatured()) ? "Post marked as featured" : "Post removed from featured";
            return ResponseUtil.success(post, msg);
        } catch (Exception e) {
            log.error("Error toggling featured status for rental post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/renew")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<RentalPost>> renewPost(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            RentalPost post = rentalPostService.renewPost(id, username);
            return ResponseUtil.success(post, "Rental post renewed successfully");
        } catch (Exception e) {
            log.error("Error renewing rental post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/edit")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<RentalPost>> userEditPost(
            @PathVariable Long id,
            @RequestBody Map<String, Object> updates) {
        try {
            String username = getCurrentUsername();
            RentalPost post = rentalPostService.userEditPost(id, updates, username);
            return ResponseUtil.success(post, "Rental post updated successfully. It will be reviewed again.");
        } catch (Exception e) {
            log.error("Error editing rental post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication.getName();
    }
}
