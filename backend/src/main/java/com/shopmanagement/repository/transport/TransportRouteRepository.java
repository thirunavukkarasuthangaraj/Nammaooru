package com.shopmanagement.repository.transport;

import com.shopmanagement.entity.transport.TransportRoute;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface TransportRouteRepository extends JpaRepository<TransportRoute, Long> {
    List<TransportRoute> findByTransporterIdOrderByNameAsc(Long transporterId);
    List<TransportRoute> findByIdIn(Collection<Long> ids);
}
