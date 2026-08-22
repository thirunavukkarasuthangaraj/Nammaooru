package com.shopmanagement.repository;

import com.shopmanagement.entity.WhatsAppIncomingMessage;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface WhatsAppIncomingMessageRepository extends JpaRepository<WhatsAppIncomingMessage, Long> {

    boolean existsByWaMessageId(String waMessageId);

    Page<WhatsAppIncomingMessage> findByStatusOrderByCreatedAtDesc(String status, Pageable pageable);

    Page<WhatsAppIncomingMessage> findAllByOrderByCreatedAtDesc(Pageable pageable);

    long countByStatus(String status);

    /** Only completed orders belong in the staff inbox; conversation/cart rows stay hidden. */
    Page<WhatsAppIncomingMessage> findByMessageTypeOrderByCreatedAtDesc(String messageType, Pageable pageable);

    Page<WhatsAppIncomingMessage> findByMessageTypeAndStatusOrderByCreatedAtDesc(
            String messageType, String status, Pageable pageable);

    long countByMessageTypeAndStatus(String messageType, String status);

    /** The order-bot cart: this customer's recent rows in a given status. */
    java.util.List<WhatsAppIncomingMessage> findByFromNumberAndStatusAndCreatedAtAfterOrderByCreatedAtAsc(
            String fromNumber, String status, java.time.LocalDateTime after);

    /** Temporary bot/cart rows associated with a recently completed order. */
    java.util.List<WhatsAppIncomingMessage> findByFromNumberAndMessageTypeNotAndCreatedAtAfter(
            String fromNumber, String messageType, java.time.LocalDateTime after);
}
