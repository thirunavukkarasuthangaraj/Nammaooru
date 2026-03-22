package com.shopmanagement.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "contact_views")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ContactView {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "viewer_user_id", nullable = false)
    private Long viewerUserId;

    @Column(name = "viewer_name", length = 200)
    private String viewerName;

    @Column(name = "viewer_phone", length = 20)
    private String viewerPhone;

    @Column(name = "post_type", nullable = false, length = 50)
    private String postType;

    @Column(name = "post_id", nullable = false)
    private Long postId;

    @Column(name = "post_title", length = 500)
    private String postTitle;

    @Column(name = "seller_phone", length = 20)
    private String sellerPhone;

    @Column(name = "viewed_at", nullable = false)
    private LocalDateTime viewedAt;

    @PrePersist
    public void prePersist() {
        if (viewedAt == null) viewedAt = LocalDateTime.now();
    }
}
