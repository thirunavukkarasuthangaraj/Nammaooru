package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.dto.ContactViewRequest;
import com.shopmanagement.entity.ContactView;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.service.ContactViewService;
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

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/contact-views")
@RequiredArgsConstructor
@Slf4j
public class ContactViewController {

    private final ContactViewService contactViewService;
    private final UserRepository userRepository;

    /**
     * POST /api/contact-views
     * Authenticated users log a contact view (they viewed a seller's phone number).
     */
    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<ContactView>> logView(@RequestBody ContactViewRequest request) {
        try {
            Long userId = getCurrentUserId();
            if (userId == null) {
                return ResponseUtil.error("Could not identify current user");
            }
            ContactView saved = contactViewService.logView(userId, request);
            return ResponseUtil.success(saved, "Contact view logged");
        } catch (Exception e) {
            log.error("Error logging contact view", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /**
     * GET /api/contact-views?page=0&size=20
     * Admin: paginated list of all contact views, newest first.
     */
    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<Page<ContactView>>> getAllViews(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<ContactView> result = contactViewService.getAll(pageable);
            return ResponseUtil.success(result, "Contact views fetched");
        } catch (Exception e) {
            log.error("Error fetching contact views", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /**
     * GET /api/contact-views/post/{postType}/{postId}
     * Admin: all views for a specific post.
     */
    @GetMapping("/post/{postType}/{postId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<List<ContactView>>> getByPost(
            @PathVariable String postType,
            @PathVariable Long postId) {
        try {
            List<ContactView> result = contactViewService.getByPost(postType, postId);
            return ResponseUtil.success(result, "Views for post fetched");
        } catch (Exception e) {
            log.error("Error fetching views for post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /**
     * GET /api/contact-views/my-post/{postType}/{postId}
     * Post owner: see who viewed their number on a specific post.
     */
    @GetMapping("/my-post/{postType}/{postId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<ContactView>>> getMyPostViews(
            @PathVariable String postType,
            @PathVariable Long postId) {
        try {
            List<ContactView> result = contactViewService.getByPost(postType, postId);
            return ResponseUtil.success(result, "Views fetched");
        } catch (Exception e) {
            log.error("Error fetching views for post", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /**
     * POST /api/contact-views/block/{userId}
     * Admin: suspend a user who is abusing contact view.
     */
    @PostMapping("/block/{userId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('SUPER_ADMIN')")
    public ResponseEntity<ApiResponse<String>> blockUser(@PathVariable Long userId) {
        try {
            contactViewService.blockUser(userId);
            return ResponseUtil.success("User " + userId + " has been blocked", "User blocked successfully");
        } catch (Exception e) {
            log.error("Error blocking user {}", userId, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }
        String username = authentication.getName();
        Optional<User> user = userRepository.findByUsername(username);
        return user.map(User::getId).orElse(null);
    }
}
