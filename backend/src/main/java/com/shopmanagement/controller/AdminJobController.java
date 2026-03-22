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
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/jobs")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('ADMIN')")
public class AdminJobController {

    private final JobPostService jobPostService;

    @GetMapping
    public ResponseEntity<ApiResponse<Page<JobPost>>> getAllJobs(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String status) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<JobPost> posts = jobPostService.getAllForAdmin(status, pageable);
            return ResponseUtil.ok(posts, "Job posts fetched");
        } catch (Exception e) {
            log.error("Error fetching admin job posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping("/{id}/approve")
    public ResponseEntity<ApiResponse<JobPost>> approve(@PathVariable Long id) {
        try {
            JobPost post = jobPostService.approve(id);
            return ResponseUtil.ok(post, "Job post approved");
        } catch (Exception e) {
            return ResponseUtil.error(e.getMessage());
        }
    }

    @PostMapping("/{id}/reject")
    public ResponseEntity<ApiResponse<JobPost>> reject(
            @PathVariable Long id,
            @RequestBody(required = false) Map<String, String> body) {
        try {
            String reason = body != null ? body.getOrDefault("reason", "") : "";
            JobPost post = jobPostService.reject(id, reason);
            return ResponseUtil.ok(post, "Job post rejected");
        } catch (Exception e) {
            return ResponseUtil.error(e.getMessage());
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
        try {
            jobPostService.adminDelete(id);
            return ResponseUtil.ok(null, "Job post deleted");
        } catch (Exception e) {
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/reported")
    public ResponseEntity<ApiResponse<Page<JobPost>>> getReported(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<JobPost> posts = jobPostService.getReportedPosts(pageable);
            return ResponseUtil.ok(posts, "Reported job posts fetched");
        } catch (Exception e) {
            return ResponseUtil.error(e.getMessage());
        }
    }

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getStats() {
        try {
            return ResponseUtil.ok(jobPostService.getStats(), "Stats fetched");
        } catch (Exception e) {
            return ResponseUtil.error(e.getMessage());
        }
    }
}
