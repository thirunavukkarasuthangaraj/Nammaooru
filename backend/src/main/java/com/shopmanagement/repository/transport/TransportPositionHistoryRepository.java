package com.shopmanagement.repository.transport;

import com.shopmanagement.entity.transport.TransportPositionHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface TransportPositionHistoryRepository extends JpaRepository<TransportPositionHistory, Long> {
    List<TransportPositionHistory> findByTripIdOrderByRecordedAtAsc(Long tripId);

    @Modifying
    @Query("DELETE FROM TransportPositionHistory h WHERE h.recordedAt < :before")
    int deleteOlderThan(@Param("before") LocalDateTime before);
}
