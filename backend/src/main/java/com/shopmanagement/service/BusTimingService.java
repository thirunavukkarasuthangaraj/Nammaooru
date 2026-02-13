package com.shopmanagement.service;

import com.shopmanagement.entity.BusTiming;
import com.shopmanagement.repository.BusTimingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class BusTimingService {

    private final BusTimingRepository busTimingRepository;

    @Transactional(readOnly = true)
    public List<BusTiming> getAllBusTimings() {
        return busTimingRepository.findAllByOrderByLocationAreaAscDepartureTimeAsc();
    }

    @Transactional(readOnly = true)
    public List<BusTiming> getActiveBusTimings() {
        return busTimingRepository.findByIsActiveTrueOrderByDepartureTime();
    }

    @Transactional(readOnly = true)
    public List<BusTiming> getBusTimingsByLocation(String location) {
        return busTimingRepository.findByLocationArea(location);
    }

    @Transactional(readOnly = true)
    public List<BusTiming> searchBusTimings(String search) {
        return busTimingRepository.searchBusTimings(search);
    }

    @Transactional(readOnly = true)
    public BusTiming getBusTimingById(Long id) {
        return busTimingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Bus timing not found with id: " + id));
    }

    @Transactional
    public BusTiming createBusTiming(BusTiming busTiming) {
        log.info("Creating bus timing: {} ({} -> {})", busTiming.getBusNumber(), busTiming.getRouteFrom(), busTiming.getRouteTo());
        return busTimingRepository.save(busTiming);
    }

    @Transactional
    public BusTiming updateBusTiming(Long id, BusTiming updated) {
        BusTiming existing = getBusTimingById(id);

        existing.setBusNumber(updated.getBusNumber());
        existing.setBusName(updated.getBusName());
        existing.setRouteFrom(updated.getRouteFrom());
        existing.setRouteTo(updated.getRouteTo());
        existing.setViaStops(updated.getViaStops());
        existing.setDepartureTime(updated.getDepartureTime());
        existing.setArrivalTime(updated.getArrivalTime());
        existing.setBusType(updated.getBusType());
        existing.setOperatingDays(updated.getOperatingDays());
        existing.setFare(updated.getFare());
        existing.setLocationArea(updated.getLocationArea());
        existing.setIsActive(updated.getIsActive());

        log.info("Updating bus timing {}: {} ({} -> {})", id, existing.getBusNumber(), existing.getRouteFrom(), existing.getRouteTo());
        return busTimingRepository.save(existing);
    }

    @Transactional
    public void deleteBusTiming(Long id) {
        BusTiming existing = getBusTimingById(id);
        log.info("Deleting bus timing {}: {}", id, existing.getBusNumber());
        busTimingRepository.deleteById(id);
    }
}
