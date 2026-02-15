package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.TravelPost;
import com.shopmanagement.service.TravelPostService;
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

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/travels")
@RequiredArgsConstructor
@Slf4j
public class TravelPostController {

    private final TravelPostService travelPostService;

    @PostMapping(consumes = "multipart/form-data")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<TravelPost>> createPost(
            @RequestParam("title") String title,
            @RequestParam("phone") String phone,
            @RequestParam("vehicleType") String vehicleType,
            @RequestParam(value = "fromLocation", required = false) String fromLocation,
            @RequestParam(value = "toLocation", required = false) String toLocation,
            @RequestParam(value = "price", required = false) String price,
            @RequestParam(value = "seatsAvailable", required = false) Integer seatsAvailable,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "images", required = false) List<MultipartFile> images) {
        try {
            String username = getCurrentUsername();
            TravelPost post = travelPostService.createPost(
                    title, phone, vehicleType, fromLocation, toLocation, price,
                    seatsAvailable, description, images, username);
            return ResponseUtil.created(post, "Travel listing submitted successfully");
        } catch (Exception e) {
            log.error("Error creating travel post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getApprovedPosts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String vehicleType) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<TravelPost> posts;
            if (vehicleType != null && !vehicleType.isEmpty()) {
                posts = travelPostService.getApprovedPostsByVehicleType(vehicleType, pageable);
            } else {
                posts = travelPostService.getApprovedPosts(pageable);
            }
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching approved travel posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<TravelPost>> getPostById(@PathVariable Long id) {
        try {
            TravelPost post = travelPostService.getPostById(id);
            return ResponseUtil.success(post, "Travel post retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching travel post", e);
            return ResponseUtil.notFound(e.getMessage());
        }
    }

    @GetMapping("/my")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<TravelPost>>> getMyPosts() {
        try {
            String username = getCurrentUsername();
            List<TravelPost> posts = travelPostService.getMyPosts(username);
            return ResponseUtil.success(posts, "My travel listings retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching my travel posts", e);
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
            Page<TravelPost> posts = travelPostService.getPendingPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching pending travel posts", e);
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
            Page<TravelPost> posts = travelPostService.getReportedPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching reported travel posts", e);
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
            Page<TravelPost> posts = travelPostService.getAllPostsForAdmin(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching all travel posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/approve")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<TravelPost>> approvePost(@PathVariable Long id) {
        try {
            TravelPost post = travelPostService.approvePost(id);
            return ResponseUtil.success(post, "Travel listing approved successfully");
        } catch (Exception e) {
            log.error("Error approving travel post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/reject")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<TravelPost>> rejectPost(@PathVariable Long id) {
        try {
            TravelPost post = travelPostService.rejectPost(id);
            return ResponseUtil.success(post, "Travel listing rejected");
        } catch (Exception e) {
            log.error("Error rejecting travel post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<TravelPost>> changePostStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        try {
            String status = body.get("status");
            if (status == null || status.isEmpty()) {
                return ResponseUtil.error("Status is required");
            }
            TravelPost post = travelPostService.changePostStatus(id, status);
            return ResponseUtil.success(post, "Travel listing status updated to " + status);
        } catch (Exception e) {
            log.error("Error changing travel post status", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/unavailable")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<TravelPost>> markAsUnavailable(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            TravelPost post = travelPostService.markAsUnavailable(id, username);
            return ResponseUtil.success(post, "Travel listing marked as unavailable");
        } catch (Exception e) {
            log.error("Error marking travel post as unavailable", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/available")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<TravelPost>> markAsAvailable(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            TravelPost post = travelPostService.markAsAvailable(id, username);
            return ResponseUtil.success(post, "Travel listing marked as available");
        } catch (Exception e) {
            log.error("Error marking travel post as available", e);
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
            travelPostService.deletePost(id, username, isAdmin);
            return ResponseUtil.deleted();
        } catch (Exception e) {
            log.error("Error deleting travel post", e);
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
            travelPostService.reportPost(id, reason, details, username);
            return ResponseUtil.success(null, "Listing reported successfully. We will review it.");
        } catch (Exception e) {
            log.error("Error reporting travel post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication.getName();
    }
}
