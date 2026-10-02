package com.shopmanagement.repository.transport;

import com.shopmanagement.entity.transport.TransportDriver;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TransportDriverRepository extends JpaRepository<TransportDriver, Long> {
    List<TransportDriver> findByTransporterIdAndStatusOrderByNameAsc(Long transporterId, TransportDriver.Status status);
    List<TransportDriver> findByPhoneAndStatus(String phone, TransportDriver.Status status);
    Optional<TransportDriver> findFirstByTransporterIdAndPhoneAndStatus(Long transporterId, String phone, TransportDriver.Status status);
}
