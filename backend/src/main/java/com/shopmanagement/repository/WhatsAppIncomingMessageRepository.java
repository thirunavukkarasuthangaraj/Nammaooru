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
}
