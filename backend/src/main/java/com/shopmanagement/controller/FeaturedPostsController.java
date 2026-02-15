package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.service.FeaturedPostsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/featured-posts")
@RequiredArgsConstructor
@Slf4j
public class FeaturedPostsController {

    private final FeaturedPostsService featuredPostsService;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getFeaturedPosts() {
        try {
            Map<String, Object> featured = featuredPostsService.getFeaturedPosts();
            return ResponseUtil.success(featured, "Featured posts retrieved successfully");
        } catch (Exception e) {
            log.error("Error fetching featured posts", e);
            return ResponseUtil.error(e.getMessage());
        }
    }
}
