package com.shopmanagement.repository;

import com.shopmanagement.entity.HealthTipQueue;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface HealthTipQueueRepository extends JpaRepository<HealthTipQueue, Long> {

    // Find next approved tip to send (oldest approved first)
    Optional<HealthTipQueue> findFirstByStatusOrderByScheduledDateAscCreatedAtAsc(HealthTipQueue.TipStatus status);

    // Find all tips by status
    List<HealthTipQueue> findByStatusOrderByScheduledDateAsc(HealthTipQueue.TipStatus status);

    // Find all tips paginated, most recent first
    Page<HealthTipQueue> findAllByOrderByCreatedAtDesc(Pageable pageable);

    // Find pending tips for admin review
    List<HealthTipQueue> findByStatusOrderByCreatedAtAsc(HealthTipQueue.TipStatus status);

    // Count by status
    long countByStatus(HealthTipQueue.TipStatus status);
}
