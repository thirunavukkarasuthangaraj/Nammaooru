package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.RealEstatePost;
import com.shopmanagement.entity.RealEstatePost.ListingType;
import com.shopmanagement.entity.RealEstatePost.PropertyType;
import com.shopmanagement.service.RealEstateService;
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
@RequestMapping("/api/real-estate")
@RequiredArgsConstructor
@Slf4j
public class RealEstateController {

    private final RealEstateService realEstateService;

    @PostMapping(consumes = "multipart/form-data")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<RealEstatePost>> createPost(
            @RequestParam("title") String title,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam("propertyType") String propertyType,
            @RequestParam("listingType") String listingType,
            @RequestParam(value = "price", required = false) BigDecimal price,
            @RequestParam(value = "areaSqft", required = false) Integer areaSqft,
            @RequestParam(value = "bedrooms", required = false) Integer bedrooms,
            @RequestParam(value = "bathrooms", required = false) Integer bathrooms,
            @RequestParam(value = "location", required = false) String location,
            @RequestParam(value = "latitude", required = false) Double latitude,
            @RequestParam(value = "longitude", required = false) Double longitude,
            @RequestParam("phone") String phone,
            @RequestParam(value = "images", required = false) List<MultipartFile> images,
            @RequestParam(value = "video", required = false) MultipartFile video,
            @RequestParam(value = "paidTokenId", required = false) Long paidTokenId) {
        try {
            String username = getCurrentUsername();
            PropertyType propType = PropertyType.valueOf(propertyType.toUpperCase());
            ListingType listType = ListingType.valueOf(listingType.toUpperCase());

            RealEstatePost post = realEstateService.createPost(
                    title, description, propType, listType, price, areaSqft,
                    bedrooms, bathrooms, location, latitude, longitude, phone,
                    images, video, username, paidTokenId);
            return ResponseUtil.created(post, "Property listing submitted for approval");
        } catch (IllegalArgumentException e) {
            log.error("Invalid property/listing type", e);
            return ResponseUtil.badRequest("Invalid property type or listing type");
        } catch (Exception e) {
            log.error("Error creating real estate post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getApprovedPosts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String propertyType,
            @RequestParam(required = false) String listingType,
            @RequestParam(required = false) String location) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<RealEstatePost> posts;

            if (location != null && !location.isEmpty()) {
                posts = realEstateService.searchByLocation(location, pageable);
            } else {
                PropertyType propType = null;
                ListingType listType = null;

                if (propertyType != null && !propertyType.isEmpty()) {
                    try {
                        propType = PropertyType.valueOf(propertyType.toUpperCase());
                    } catch (IllegalArgumentException ignored) {}
                }

                if (listingType != null && !listingType.isEmpty()) {
                    try {
                        listType = ListingType.valueOf(listingType.toUpperCase());
                    } catch (IllegalArgumentException ignored) {}
                }

                posts = realEstateService.getApprovedPostsFiltered(propType, listType, pageable);
            }

            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching real estate posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/featured")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getFeaturedPosts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<RealEstatePost> posts = realEstateService.getFeaturedPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching featured posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<RealEstatePost>> getPostById(@PathVariable Long id) {
        try {
            RealEstatePost post = realEstateService.getPostById(id);
            // Increment view count
            realEstateService.incrementViews(id);
            return ResponseUtil.success(post, "Property retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching property", e);
            return ResponseUtil.notFound(e.getMessage());
        }
    }

    @GetMapping("/my")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<RealEstatePost>>> getMyPosts() {
        try {
            String username = getCurrentUsername();
            List<RealEstatePost> posts = realEstateService.getMyPosts(username);
            return ResponseUtil.success(posts, "My properties retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching my properties", e);
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
            Page<RealEstatePost> posts = realEstateService.getPendingPosts(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching pending properties", e);
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
            Page<RealEstatePost> posts = realEstateService.getAllPostsForAdmin(pageable);
            return ResponseUtil.paginated(posts);
        } catch (Exception e) {
            log.error("Error fetching all properties", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/approve")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<RealEstatePost>> approvePost(@PathVariable Long id) {
        try {
            RealEstatePost post = realEstateService.approvePost(id);
            return ResponseUtil.success(post, "Property approved successfully");
        } catch (Exception e) {
            log.error("Error approving property", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/reject")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<RealEstatePost>> rejectPost(@PathVariable Long id) {
        try {
            RealEstatePost post = realEstateService.rejectPost(id);
            return ResponseUtil.success(post, "Property rejected");
        } catch (Exception e) {
            log.error("Error rejecting property", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/sold")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<RealEstatePost>> markAsSold(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            RealEstatePost post = realEstateService.markAsSold(id, username);
            return ResponseUtil.success(post, "Property marked as sold");
        } catch (Exception e) {
            log.error("Error marking property as sold", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/rented")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<RealEstatePost>> markAsRented(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            RealEstatePost post = realEstateService.markAsRented(id, username);
            return ResponseUtil.success(post, "Property marked as rented");
        } catch (Exception e) {
            log.error("Error marking property as rented", e);
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
                    .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN") ||
                                   a.getAuthority().equals("ROLE_SUPER_ADMIN"));
            realEstateService.deletePost(id, username, isAdmin);
            return ResponseUtil.deleted();
        } catch (Exception e) {
            log.error("Error deleting property", e);
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
            realEstateService.reportPost(id, reason, details, username);
            return ResponseUtil.success(null, "Property reported successfully. We will review it.");
        } catch (Exception e) {
            log.error("Error reporting property", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/admin-update")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<RealEstatePost>> adminUpdatePost(
            @PathVariable Long id,
            @RequestBody Map<String, Object> updates) {
        try {
            RealEstatePost post = realEstateService.adminUpdatePost(id, updates);
            return ResponseUtil.success(post, "Property listing updated successfully");
        } catch (Exception e) {
            log.error("Error admin-updating real estate post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/featured")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<RealEstatePost>> toggleFeatured(@PathVariable Long id) {
        try {
            RealEstatePost post = realEstateService.toggleFeatured(id);
            String msg = Boolean.TRUE.equals(post.getIsFeatured()) ? "Post marked as featured" : "Post removed from featured";
            return ResponseUtil.success(post, msg);
        } catch (Exception e) {
            log.error("Error toggling featured status for real estate post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/renew")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<RealEstatePost>> renewPost(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            RealEstatePost post = realEstateService.renewPost(id, username);
            return ResponseUtil.success(post, "Property listing renewed successfully");
        } catch (Exception e) {
            log.error("Error renewing real estate post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PutMapping("/{id}/edit")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<RealEstatePost>> userEditPost(
            @PathVariable Long id,
            @RequestBody Map<String, Object> updates) {
        try {
            String username = getCurrentUsername();
            RealEstatePost post = realEstateService.userEditPost(id, updates, username);
            return ResponseUtil.success(post, "Post updated successfully. It will be reviewed again.");
        } catch (Exception e) {
            log.error("Error editing real estate post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication.getName();
    }
}
