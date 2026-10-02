package com.shopmanagement.repository.transport;

import com.shopmanagement.entity.transport.TransportTrip;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TransportTripRepository extends JpaRepository<TransportTrip, Long> {
    List<TransportTrip> findByDriverIdAndStatus(Long driverId, TransportTrip.Status status);
    List<TransportTrip> findByVehicleIdAndStatus(Long vehicleId, TransportTrip.Status status);
    Page<TransportTrip> findByTransporterIdOrderByStartedAtDesc(Long transporterId, Pageable pageable);
    Page<TransportTrip> findByTransporterIdAndVehicleIdOrderByStartedAtDesc(Long transporterId, Long vehicleId, Pageable pageable);
}
