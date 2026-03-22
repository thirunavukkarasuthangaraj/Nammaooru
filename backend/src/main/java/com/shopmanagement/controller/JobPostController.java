package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.JobPost;
import com.shopmanagement.service.JobPostService;
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
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/jobs")
@RequiredArgsConstructor
@Slf4j
public class JobPostController {

    private final JobPostService jobPostService;

    @PostMapping(consumes = "multipart/form-data")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<JobPost>> createPost(
            @RequestParam("jobTitle") String jobTitle,
            @RequestParam("companyName") String companyName,
            @RequestParam("phone") String phone,
            @RequestParam("category") String category,
            @RequestParam(value = "jobType", defaultValue = "FULL_TIME") String jobType,
            @RequestParam(value = "salary", required = false) String salary,
            @RequestParam(value = "salaryType", defaultValue = "MONTHLY") String salaryType,
            @RequestParam(value = "vacancies", required = false) Integer vacancies,
            @RequestParam(value = "location", required = false) String location,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "requirements", required = false) String requirements,
            @RequestParam(value = "images", required = false) List<MultipartFile> images,
            @RequestParam(value = "latitude", required = false) BigDecimal latitude,
            @RequestParam(value = "longitude", required = false) BigDecimal longitude) {
        try {
            String username = getCurrentUsername();
            JobPost post = jobPostService.createPost(
                    jobTitle, companyName, phone, category, jobType, salary, salaryType,
                    vacancies, location, description, requirements, images, username, latitude, longitude);
            return ResponseUtil.created(post, "Job posted successfully. Awaiting approval.");
        } catch (Exception e) {
            log.error("Error creating job post", e);
            if ("LIMIT_REACHED".equals(e.getMessage())) {
                return ResponseUtil.error(HttpStatus.PAYMENT_REQUIRED, "LIMIT_REACHED", "Post limit reached.");
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
            Page<JobPost> posts = jobPostService.getApprovedPosts(category, lat, lng, radius, search, pageable);
            Map<String, Object> result = new HashMap<>();
            result.put("content", posts.getContent());
            result.put("hasNext", !posts.isLast());
            result.put("totalElements", posts.getTotalElements());
            result.put("totalPages", posts.getTotalPages());
            return ResponseUtil.success(result, "Job posts fetched");
        } catch (Exception e) {
            log.error("Error fetching job posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/my")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<JobPost>>> getMyPosts() {
        try {
            String username = getCurrentUsername();
            List<JobPost> posts = jobPostService.getMyPosts(username);
            return ResponseUtil.success(posts, "My job posts fetched");
        } catch (Exception e) {
            log.error("Error fetching my job posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Void>> deletePost(@PathVariable Long id) {
        try {
            String username = getCurrentUsername();
            jobPostService.delete(id, username);
            return ResponseUtil.deleted();
        } catch (Exception e) {
            log.error("Error deleting job post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping("/{id}/report")
    public ResponseEntity<ApiResponse<Void>> reportPost(
            @PathVariable Long id,
            @RequestBody(required = false) Map<String, String> body) {
        try {
            String reason = body != null ? body.getOrDefault("reason", "Inappropriate") : "Inappropriate";
            String details = body != null ? body.get("details") : null;
            jobPostService.report(id, reason, details);
            return ResponseUtil.deleted();
        } catch (Exception e) {
            log.error("Error reporting job post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private String getCurrentUsername() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth.getName();
    }
}
