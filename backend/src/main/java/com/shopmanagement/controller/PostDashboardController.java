package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.service.PostDashboardService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/post-dashboard")
@RequiredArgsConstructor
@Slf4j
public class PostDashboardController {

    private final PostDashboardService postDashboardService;

    @GetMapping("/stats")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Map<String, Long>>>> getDashboardStats() {
        try {
            Map<String, Map<String, Long>> stats = postDashboardService.getDashboardStats();
            return ResponseUtil.success(stats, "Post dashboard stats retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching post dashboard stats", e);
            return ResponseUtil.error(e.getMessage());
        }
    }
}
