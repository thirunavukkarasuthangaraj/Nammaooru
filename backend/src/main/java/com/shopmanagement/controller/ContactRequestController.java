package com.shopmanagement.controller;

import com.shopmanagement.common.dto.ApiResponse;
import com.shopmanagement.common.util.ResponseUtil;
import com.shopmanagement.entity.ContactRequest;
import com.shopmanagement.entity.User;
import com.shopmanagement.repository.UserRepository;
import com.shopmanagement.service.ContactRequestService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/contact-requests")
@RequiredArgsConstructor
@Slf4j
public class ContactRequestController {

    private final ContactRequestService contactRequestService;
    private final UserRepository userRepository;

    /** POST /api/contact-requests — send a contact request to a post owner */
    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<ContactRequest>> sendRequest(@RequestBody Map<String, Object> body) {
        try {
            Long userId = getCurrentUserId();
            if (userId == null) return ResponseUtil.error("Not authenticated");

            String postType = (String) body.get("postType");
            Long postId = Long.parseLong(body.get("postId").toString());
            String postTitle = (String) body.getOrDefault("postTitle", "");
            Long postOwnerUserId = Long.parseLong(body.get("postOwnerUserId").toString());

            ContactRequest result = contactRequestService.sendRequest(userId, postType, postId, postTitle, postOwnerUserId);
            return ResponseUtil.success(result, "Contact request sent");
        } catch (Exception e) {
            log.error("Error sending contact request", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /** PUT /api/contact-requests/{id}/approve — owner approves request */
    @PutMapping("/{id}/approve")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<ContactRequest>> approve(@PathVariable Long id) {
        try {
            Long userId = getCurrentUserId();
            if (userId == null) return ResponseUtil.error("Not authenticated");
            ContactRequest result = contactRequestService.respond(id, userId, true);
            return ResponseUtil.success(result, "Request approved");
        } catch (Exception e) {
            log.error("Error approving contact request {}", id, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /** PUT /api/contact-requests/{id}/deny — owner denies request */
    @PutMapping("/{id}/deny")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<ContactRequest>> deny(@PathVariable Long id) {
        try {
            Long userId = getCurrentUserId();
            if (userId == null) return ResponseUtil.error("Not authenticated");
            ContactRequest result = contactRequestService.respond(id, userId, false);
            return ResponseUtil.success(result, "Request denied");
        } catch (Exception e) {
            log.error("Error denying contact request {}", id, e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /** GET /api/contact-requests/incoming — post owner sees all requests for their posts */
    @GetMapping("/incoming")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<ContactRequest>>> getIncoming() {
        try {
            Long userId = getCurrentUserId();
            if (userId == null) return ResponseUtil.error("Not authenticated");
            return ResponseUtil.success(contactRequestService.getIncomingRequests(userId), "Incoming requests fetched");
        } catch (Exception e) {
            log.error("Error fetching incoming requests", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /** GET /api/contact-requests/incoming/pending — post owner sees pending requests only */
    @GetMapping("/incoming/pending")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<ContactRequest>>> getPending() {
        try {
            Long userId = getCurrentUserId();
            if (userId == null) return ResponseUtil.error("Not authenticated");
            return ResponseUtil.success(contactRequestService.getPendingRequests(userId), "Pending requests fetched");
        } catch (Exception e) {
            log.error("Error fetching pending requests", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /** GET /api/contact-requests/my — requester sees their outgoing requests */
    @GetMapping("/my")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<ContactRequest>>> getMy() {
        try {
            Long userId = getCurrentUserId();
            if (userId == null) return ResponseUtil.error("Not authenticated");
            return ResponseUtil.success(contactRequestService.getMyOutgoingRequests(userId), "My requests fetched");
        } catch (Exception e) {
            log.error("Error fetching my requests", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /** GET /api/contact-requests/check?postType=X&postId=Y — check if I already requested for this post */
    @GetMapping("/check")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<ContactRequest>> checkStatus(
            @RequestParam String postType,
            @RequestParam Long postId) {
        try {
            Long userId = getCurrentUserId();
            if (userId == null) return ResponseUtil.error("Not authenticated");
            Optional<ContactRequest> req = contactRequestService.getMyRequestForPost(userId, postType, postId);
            return ResponseUtil.success(req.orElse(null), "Status fetched");
        } catch (Exception e) {
            log.error("Error checking request status", e);
            return ResponseUtil.error(e.getMessage());
        }
    }

    /** GET /api/contact-requests/pending-count — badge count for post owner */
    @GetMapping("/pending-count")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Long>> pendingCount() {
        try {
            Long userId = getCurrentUserId();
            if (userId == null) return ResponseUtil.error("Not authenticated");
            return ResponseUtil.success(contactRequestService.countPendingForOwner(userId), "Count fetched");
        } catch (Exception e) {
            return ResponseUtil.error(e.getMessage());
        }
    }

    private Long getCurrentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) return null;
        Optional<User> user = userRepository.findByUsername(auth.getName());
        return user.map(User::getId).orElse(null);
    }
}
