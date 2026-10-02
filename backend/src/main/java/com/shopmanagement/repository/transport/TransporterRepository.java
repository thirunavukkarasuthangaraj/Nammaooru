package com.shopmanagement.repository.transport;

import com.shopmanagement.entity.transport.Transporter;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TransporterRepository extends JpaRepository<Transporter, Long> {
    Optional<Transporter> findByUserId(Long userId);
    Page<Transporter> findByStatusOrderByCreatedAtDesc(Transporter.Status status, Pageable pageable);
    Page<Transporter> findAllByOrderByCreatedAtDesc(Pageable pageable);
    long countByStatus(Transporter.Status status);
}
