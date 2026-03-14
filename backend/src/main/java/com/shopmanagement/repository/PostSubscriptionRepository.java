package com.shopmanagement.repository;

import com.shopmanagement.entity.PostSubscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PostSubscriptionRepository extends JpaRepository<PostSubscription, Long> {

    Optional<PostSubscription> findByRazorpaySubscriptionId(String razorpaySubscriptionId);

    Optional<PostSubscription> findByPostId(Long postId);

    List<PostSubscription> findByUserId(Long userId);

    List<PostSubscription> findByUserIdOrderByCreatedAtDesc(Long userId);

    @Query("SELECT s FROM PostSubscription s WHERE s.userId = :userId AND (s.status = 'ACTIVE' OR s.status = 'AUTHENTICATED')")
    List<PostSubscription> findActiveByUserId(Long userId);

    @Query("SELECT COUNT(s) > 0 FROM PostSubscription s WHERE s.userId = :userId AND (s.status = 'ACTIVE' OR s.status = 'AUTHENTICATED')")
    boolean hasActiveSubscription(Long userId);

    @Query("SELECT COUNT(s) > 0 FROM PostSubscription s WHERE s.postId = :postId AND (s.status = 'ACTIVE' OR s.status = 'AUTHENTICATED')")
    boolean hasActiveSubscriptionForPost(Long postId);
}
