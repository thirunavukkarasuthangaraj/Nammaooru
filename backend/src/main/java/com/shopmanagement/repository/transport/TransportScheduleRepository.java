package com.shopmanagement.repository.transport;

import com.shopmanagement.entity.transport.TransportSchedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface TransportScheduleRepository extends JpaRepository<TransportSchedule, Long> {
    List<TransportSchedule> findByTransporterIdOrderByVehicleIdAscDepartTimeAsc(Long transporterId);
    List<TransportSchedule> findByVehicleIdInAndIsActiveTrueOrderByDepartTimeAsc(Collection<Long> vehicleIds);
    List<TransportSchedule> findByVehicleIdOrderByDepartTimeAsc(Long vehicleId);
}
