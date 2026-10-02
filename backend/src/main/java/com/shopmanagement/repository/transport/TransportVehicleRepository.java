package com.shopmanagement.repository.transport;

import com.shopmanagement.entity.transport.TransportVehicle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface TransportVehicleRepository extends JpaRepository<TransportVehicle, Long> {
    List<TransportVehicle> findByTransporterIdAndStatusNotOrderByNameAsc(Long transporterId, TransportVehicle.Status status);
    List<TransportVehicle> findByDriverIdInAndStatus(Collection<Long> driverIds, TransportVehicle.Status status);
    List<TransportVehicle> findByIsPublicTrueAndStatusAndVehicleType(TransportVehicle.Status status, TransportVehicle.VehicleType type);
    long countByTransporterIdAndStatus(Long transporterId, TransportVehicle.Status status);
}
