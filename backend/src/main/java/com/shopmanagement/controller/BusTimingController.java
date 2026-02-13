package com.shopmanagement.controller;

import com.shopmanagement.entity.BusTiming;
import com.shopmanagement.service.BusTimingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/bus-timings")
@RequiredArgsConstructor
@Slf4j
public class BusTimingController {

    private final BusTimingService busTimingService;

    // Public: Get all active bus timings (for mobile app)
    @GetMapping
    public ResponseEntity<Map<String, Object>> getActiveBusTimings(
            @RequestParam(required = false) String location,
            @RequestParam(required = false) String search) {
        try {
            List<BusTiming> timings;

            if (search != null && !search.trim().isEmpty()) {
                timings = busTimingService.searchBusTimings(search.trim());
            } else if (location != null && !location.trim().isEmpty()) {
                timings = busTimingService.getBusTimingsByLocation(location.trim());
            } else {
                timings = busTimingService.getActiveBusTimings();
            }

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "0000");
            response.put("success", true);
            response.put("message", "Bus timings fetched successfully");
            response.put("data", timings);
            response.put("total", timings.size());

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error fetching bus timings: {}", e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "9999");
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }

    // Public: Get bus timing by ID
    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getBusTimingById(@PathVariable Long id) {
        try {
            BusTiming timing = busTimingService.getBusTimingById(id);

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "0000");
            response.put("success", true);
            response.put("message", "Bus timing fetched successfully");
            response.put("data", timing);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error fetching bus timing {}: {}", id, e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", "9999");
            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);
        }
    }
}
