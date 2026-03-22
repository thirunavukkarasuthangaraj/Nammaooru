package com.shopmanagement.repository;

import com.shopmanagement.entity.ContactRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ContactRequestRepository extends JpaRepository<ContactRequest, Long> {

    // Incoming requests for a post owner
    List<ContactRequest> findByPostOwnerUserIdOrderByCreatedAtDesc(Long postOwnerUserId);

    // Incoming pending requests for owner
    List<ContactRequest> findByPostOwnerUserIdAndStatusOrderByCreatedAtDesc(Long postOwnerUserId, String status);

    // Outgoing requests by requester
    List<ContactRequest> findByRequesterUserIdOrderByCreatedAtDesc(Long requesterUserId);

    // Check if requester already sent a request for this post
    Optional<ContactRequest> findByRequesterUserIdAndPostTypeAndPostId(Long requesterUserId, String postType, Long postId);

    // All requests for a specific post
    List<ContactRequest> findByPostTypeAndPostIdOrderByCreatedAtDesc(String postType, Long postId);

    // Count pending for owner
    long countByPostOwnerUserIdAndStatus(Long postOwnerUserId, String status);
}
