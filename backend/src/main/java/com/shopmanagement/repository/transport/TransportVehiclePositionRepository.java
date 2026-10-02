package com.shopmanagement.repository.transport;

import com.shopmanagement.entity.transport.TransportVehiclePosition;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface TransportVehiclePositionRepository extends JpaRepository<TransportVehiclePosition, Long> {
    List<TransportVehiclePosition> findByVehicleIdIn(Collection<Long> vehicleIds);
}
