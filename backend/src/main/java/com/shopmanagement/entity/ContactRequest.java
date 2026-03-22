package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "contact_requests")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ContactRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "requester_user_id", nullable = false)
    private Long requesterUserId;

    @Column(name = "requester_name", length = 200)
    private String requesterName;

    @Column(name = "requester_phone", length = 20)
    private String requesterPhone;

    @Column(name = "post_type", nullable = false, length = 50)
    private String postType;

    @Column(name = "post_id", nullable = false)
    private Long postId;

    @Column(name = "post_title", length = 500)
    private String postTitle;

    @Column(name = "post_owner_user_id", nullable = false)
    private Long postOwnerUserId;

    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private String status = "PENDING"; // PENDING, APPROVED, DENIED

    @Column(name = "message", length = 500)
    private String message;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "responded_at")
    private LocalDateTime respondedAt;

    @PrePersist
    public void prePersist() {
        if (createdAt == null) createdAt = LocalDateTime.now();
    }
}
