package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.MarketplacePost;
import com.shopmanagement.service.MarketplaceService;
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
@RequestMapping("/api/marketplace")
@RequiredArgsConstructor
@Slf4j
public class MarketplaceController {

    private final MarketplaceService marketplaceService;

    @PostMapping(consumes = "multipart/form-data")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<MarketplacePost>> createPost(
            @RequestParam("title") String title,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "price", required = false) BigDecimal price,
            @RequestParam("phone") String phone,
            @RequestParam(value = "category", required = false) String category,
            @RequestParam(value = "location", required = false) String location,
            @RequestParam(value = "image", required = false) MultipartFile image,
            @RequestParam(value = "voice", required = false) MultipartFile voice) {
        try {
            String username = getCurrentUsername();
            MarketplacePost post = marketplaceService.createPost(
                    title, description, price, phone, category, location, image, voice, username);
            return ResponseUtil.created(post, "Post submitted for approval");
        } catch (Exception e) {
            log.error("Error creating marketplace post", e);
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
            Page<MarketplacePost> posts;
            if (category != null && !category.isEmpty()) {
                posts = marketplaceService.getApprovedPostsByCategory(category, pageable);
            } else {
                posts = marketplaceService.getApprovedPosts(pageable);
            }
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching approved posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<MarketplacePost>> getPostById(@PathVariable Long id) {
        try {
            MarketplacePost post = marketplaceService.getPostById(id);
            return ResponseUtil.success(post, "Post retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching post", e);
            return ResponseUtil.notFound(e.getMessage());
        }
    }

    @GetMapping("/my")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<MarketplacePost>>> getMyPosts() {
        try {
            String username = getCurrentUsername();
            List<MarketplacePost> posts = marketplaceService.getMyPosts(username);
            return ResponseUtil.success(posts, "My posts retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching my posts", e);
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
            Page<MarketplacePost> posts = marketplaceService.getPendingPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching pending posts", e);
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
            Page<MarketplacePost> posts = marketplaceService.getReportedPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching reported posts", e);
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
            Page<MarketplacePost> posts = marketplaceService.getAllPostsForAdmin(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching all posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/approve")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<MarketplacePost>> approvePost(@PathVariable Long id) {
        try {
            MarketplacePost post = marketplaceService.approvePost(id);
            return ResponseUtil.success(post, "Post approved successfully");
        } catch (Exception e) {
            log.error("Error approving post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/reject")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<MarketplacePost>> rejectPost(@PathVariable Long id) {
        try {
            MarketplacePost post = marketplaceService.rejectPost(id);
            return ResponseUtil.success(post, "Post rejected");
        } catch (Exception e) {
            log.error("Error rejecting post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/sold")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<MarketplacePost>> markAsSold(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            MarketplacePost post = marketplaceService.markAsSold(id, username);
            return ResponseUtil.success(post, "Post marked as sold");
        } catch (Exception e) {
            log.error("Error marking post as sold", e);
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
            marketplaceService.deletePost(id, username, isAdmin);
            return ResponseUtil.deleted();
        } catch (Exception e) {
            log.error("Error deleting post", e);
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
            marketplaceService.reportPost(id, reason, details, username);
            return ResponseUtil.success(null, "Post reported successfully. We will review it.");
        } catch (Exception e) {
            log.error("Error reporting post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication.getName();
    }
}
